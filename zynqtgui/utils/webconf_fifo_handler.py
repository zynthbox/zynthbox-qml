#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHBOX PROJECT: Zynthbox GUI
#
# Handler for bi-directional communication with WebConf
#
# Copyright (C) 2025 Dan Leinir Turthra Jensen <admin@leinir.dk>
#
# ******************************************************************************
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# For a full copy of the GNU General Public License see the LICENSE.txt file.
#
# ******************************************************************************

import logging
import os
import queue
import stat
import time

from pathlib import Path
from threading import Thread
from PySide2.QtCore import QMetaObject, Qt, Property, QObject, QTimer, Signal, Slot
import Zynthbox

### Bi-directional communication channel between Webconf and Zynthbox QML
#
# Interacting with Webconf from within Zynthbox QML can be done by accessing
# the instance of this class on the core gui, called webconf, and using the
# various signals and slots to do the work.
#
# The class wraps a pair of fifo entries, which Webconf reads from and writes
# to, respectively named:
# /tmp/webconf-writes-to-this-fifo (which we read from)
# /tmp/webconf-reads-from-this-fifo (which we write to)
# The data is handled on a per-line basis, and the encoding must be UTF-8
#
# Sending to Webconf
# ==================
#
# To send a command, or other data, to Webconf: use the send(data:str) function.
#
# Any CUIA command issued to the system will automatically be returned to
# Webconf as feedback, using the same format used for those commands sent to
# Zynthbox QML from webconf (see formatting guidelines below).
#
# Progress information will be sent in the form of messages starting with task.
#
# Receiving from Webconf
# ======================
#
# Commands sent by Webconf will be in the form of a string with slashes as
# command delimiters. The format will depend on the individual command, and
# the following is a short list of some expected ones. For a complete list,
# please inspect the handle_input(inputData:str) function's documentation and
# implementation.
#
# cuia/switch_record - will simulate a push of the Record button
# cuia/set_slot_gain/1/3/127 - will request slot 4 on track 2 (that is, indices 3 and 1 respectively) to be set to 127 (the maximum value, from 0 through 127)
#
class webconf_fifo_handler(QObject):
    def __init__(self, parent=None):
        super(webconf_fifo_handler, self).__init__(parent)
        self.core_gui = parent
        self.core_gui.currentTaskMessageChanged.connect(self.handleCurrentTaskMessageChanged)
        self.core_gui.is_loading_changed.connect(self.handleIsLoadingChanged)
        self.data_for_webconf = queue.SimpleQueue()

        if not Path("/tmp/webconf-writes-to-this-fifo").exists():
            os.mkfifo("/tmp/webconf-writes-to-this-fifo")
            os.chmod("/tmp/webconf-writes-to-this-fifo", stat.S_IWGRP | stat.S_IRGRP | stat.S_IRUSR | stat.S_IWUSR | stat.S_IWOTH | stat.S_IROTH)
        if not Path("/tmp/webconf-reads-from-this-fifo").exists():
            os.mkfifo("/tmp/webconf-reads-from-this-fifo")

        self.fifo_reader_thread = Thread(target=self.fifo_reader, args=())
        self.fifo_reader_thread.daemon = True # thread will exit with the program
        self.fifo_reader_thread.start()
        self.fifo_writer_thread = Thread(target=self.fifo_writer, args=())
        self.fifo_writer_thread.daemon = True # thread will exit with the program
        self.fifo_writer_thread.start()

        Zynthbox.MidiRouter.instance().cuiaEventHandled.connect(self.handleMidiRouterCuiaEventHandled)
        Zynthbox.SndLibrary.instance().sndFileAdded.connect(self.handleSndFileAdded)

    ### Send the given string data to Webconf
    # CUIA feedback will happen automatically, and will have an identical layout to what Webconf would send us (see handle_input(inputData:str))
    #
    # Further strings would include:
    #
    # task/description/text
    #   A clear-text description of the currently on-going task (any line-breaks will be converted to xhtml style <br />)
    #   If there is an ongoing long-running task, update the description of that task to match what is received here
    #   If there is no ongoing long-running task, simply show a short-term auto-hide notification popup type thing
    # task/long/start
    #   A long-running task has been initiated (show an indication that something is going on, such as a spinner, and a short text to say "Working..." or similar)
    #   If this is received more than once, you can safely ignore the subsequent ones (that is, task/long/start and task/long/end should be considered an explicit toggle between two states)
    # task/long/end
    #   The long-runing task has ended (hide the progress/spinner)
    #   If this is received more than once, you can safely ignore the subsequent ones (that is, task/long/start and task/long/end should be considered an explicit toggle between two states)
    # task/long/progress/value
    #   If we know the current progress of the task, we will update this with a value from 1 through 100 to indicate some amount of percentile progress. If value is -1, return to the spinner-style progress indication described for task/long/start
    # sounds/added/pathname
    #   The pathname file was discovered by the system and added to the library
    #
    #   @param data The string to send to Webconf
    @Slot(str)
    def send(self, data:str):
        self.data_for_webconf.put(data)

    ### Handle the input as retrieved from Webconf
    # The layout of the string will depend on the specific type of command. The following
    # is an attempt at fully documenting the intent of the acceptable input. The text would
    # commonly be a /-separated string of commands and arguments.
    #
    # cuia/cuia_command/track/slot/value
    #   this will call the given CUIA command with the parameters of the command set to the
    #   given values, clamped to the correct range. Probably attempt to not go out of range,
    #   except in cases where the parameter is irrelevant, such as setting track volume, which
    #   doesn't require a slot, so you can pass -1 for the slot value, like so:
    #   cuia/SET_TRACK_VOLUME/9/-1/63 (which would set track 10 (index 9) to 50% volume (0 through 127)
    #   or if you wish to activate a track, you can safely pass any value to the slot and value parameters:
    #   cuia/ACTIVATE_TRACK/1/-1/0 (which activates track 1 (index 0))
    #   For commands which are singular (such as button presses), you don't have to pass track, slot, and value:
    #   cuia/switch_play (which will simulate pressing the play button)
    #
    # NOTE: The separator should only exist between elements, and all elements must be filled, as any empty elements would be filtered out before handling
    # This means that technically, /cuia//switch_stop//// would be valid, as it would be interpreted as cuia/switch_stop, but you should endeavour to avoid this kind of thing.
    #
    # @param inputData The raw data as received from Webconf (a single line of text)
    def handle_input(self, inputData):
        logging.error(f"Input retrieved from webconf fifo: {inputData}")
        splitData = list(filter(None, inputData.split("/"))) # Filter out any empty entries, as those aren't supposed to exist
        # On startup, webconf sends out a command to retrieve the current state, which we should then return
        splitDataLength = len(splitData)
        if splitDataLength > 0:
            match splitData[0]:
                case "cuia":
                    command = ""
                    track = -1
                    slot = -1
                    value = 0
                    if splitDataLength == 5:
                        command = splitData[1].upper()
                        track = max(-1, min(splitData[2], Zynthbox.Plugin.instance().sketchpadTrackCount()))
                        slot = max(-1, min(splitData[3], Zynthbox.Plugin.instance().sketchpadSlotCount()))
                        value = max(0, min(splitData[4], 127))
                    elif len(splitData) == 2:
                        command = splitData[1].upper()
                    else:
                        # This should really not happen (you either pass the command only, or you pass all the parameters, no in-between)
                        logging.error(f"Attempted to handle a cuia command which did not match the expected layout of either cuia/command or cuia/command/track/slot/value: {inputData}")
                    if command != "":
                        self.core_gui.callable_ui_action(command, [value], -1, track, slot)
                case "":
                    pass

    @Slot(str,int,int,int,int)
    def handleMidiRouterCuiaEventHandled(self, cuia, originId, track, slot, value):
        # logging.error(f"midi router cuia event: {cuia}, origin ID: {originId}, track: {track} aka {int(track)}, slot: {slot} aka {int(slot)}, value: {value}")
        if int(track) < 0:
            track = self.core_gui.sketchpad.selectedTrackId
        if int(slot) < 0:
            slot = 0 # FIXME This needs to also sniff the currently selected clip/sound/fx slot when valid
            # theTrack.selectedFxSlotRow - the property holding that information...
        self.send(f"cuia/{cuia}/{int(track)}/{int(slot)}/{int(value)}")

    @Slot(None)
    def handleCurrentTaskMessageChanged(self):
        message = self.core_gui.currentTaskMessage
        message.replace("\n", "<br />")
        self.send(f"task/description/{message}")

    @Slot(None)
    def handleIsLoadingChanged(self):
        if self.core_gui.is_loading:
            self.send("task/long/start");
        else:
            self.send("task/long/end");

    @Slot(str)
    def handleSndFileAdded(self, fileIdentifier):
        self.send(f"sound/added/{fileIdentifier}")

    def fifo_reader(self):
        input_fifo = None
        while not self.core_gui.exit_flag:
            # Do not refresh when booting is in progress
            if self.core_gui.isBootingComplete:
                try:
                    if input_fifo is None:
                        input_fifo = open("/tmp/webconf-writes-to-this-fifo", mode="r", encoding='utf8')

                    data = ""
                    while True:
                        data = input_fifo.readline()[:-1].strip()
                        if len(data) == 0:
                            break
                        else:
                            self.handle_input(data)

                except Exception as e:
                    logging.error(f"Error while attempting to read from the webconf input fifo: {e}")
            time.sleep(0.3)
        if input_fifo is not None:
            input_fifo.close()

    def fifo_writer(self):
        output_fifo = None
        while not self.core_gui.exit_flag:
            try:
                if output_fifo is None:
                    output_fifo = os.open("/tmp/webconf-reads-from-this-fifo", os.O_WRONLY)

                data = self.data_for_webconf.get()
                if len(data) > 0:
                    os.write(output_fifo, f"{data}\n".encode())
            except Exception as e:
                logging.error(f"Error while attempting to write to the webconf output fifo: {e}")
