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

        if not Path("/tmp/webconf-writes-to-this-fifo").exists():
            os.mkfifo("/tmp/webconf-writes-to-this-fifo")
            os.chmod("/tmp/webconf-writes-to-this-fifo", stat.S_IWGRP | stat.S_IRGRP | stat.S_IRUSR | stat.S_IWUSR | stat.S_IWOTH | stat.S_IROTH)
        if not Path("/tmp/webconf-reads-from-this-fifo").exists():
            os.mkfifo("/tmp/webconf-reads-from-this-fifo")

        self.fifoReader = Zynthbox.FifoHandler("/tmp/webconf-writes-to-this-fifo", Zynthbox.FifoHandler.ReadingDirection, self)
        self.fifoReader.received.connect(self.handleInput)
        self.fifoReader.start()
        self.fifoWriter = Zynthbox.FifoHandler("/tmp/webconf-reads-from-this-fifo", Zynthbox.FifoHandler.WritingDirection, self)

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
        self.fifoWriter.send(data)

    ### Handle the input as retrieved from Webconf
    # The layout of the string will depend on the specific type of command. The following
    # is an attempt at fully documenting the intent of the acceptable input. The text would
    # commonly be a /-separated string of commands and arguments. To include a / in a string,
    # simply escape that slash (by writing \/). You can use this when passing in files
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
    # sounds
    #   This section of commands will affect the sound library
    #   sounds/process/absolute\/file\/path.snd will process the snd file /absolute/file/path.snd
    #   sounds/process/absolute\/file\/path.snd/another\/absolute\/path.snd will process the two given snd files /absolute/file/path.snd and /another/absolute/path.snd
    # sketchpad
    #   This section of commands will affect the current sketchpad in various ways.
    #   sketchpad/track/3/loadSound/absolute\/file\/path.snd would instruct track 4 (index 3) to perform "loadSound" on the file /absolute/file/path.snd
    #   Track commands are:
    #     loadSound: Will load the given sound onto the track. If the snd file doesn't exist, the command will be ignored
    #     clearSlot: Will clear the data on the given slot and type. The format of the command is:
    #       sketchpad/track/trackindex/clearSlot/slottype/slotindex
    #       and the acceptable values for slottype are: synth, sample, fx, sketch
    #     loadIntoSlot: Will load the given data into the given slot. Same format and slot types as clearSlot, but with an additional element for a file path and optional subelements for that file
    #       sketchpad/track/trackindex/loadIntoSlot/slottype/slotindex/absolute\/file\/path\/to\/a\/file.wav
    #       This is currently only useful for wave files
    #       sketchpad/track/trackindex/loadIntoSlot/slottype/slotindex/absolute\/path.snd/slottype2/slotindex2
    #         This command will load the embedded element defined by slottype2 and slotindex2 into the given slottype and slotindex on the given track
    #         Note that the types must be compatible (which essentially means that they must match, unless you are loading a sketch from an snd file into a sample slot)
    #
    # NOTE: The separator should only exist between elements, and all elements must be filled, as any empty elements would be filtered out before handling
    # This means that technically, /cuia//switch_stop//// would be valid, as it would be interpreted as cuia/switch_stop, but you should endeavour to avoid this kind of thing.
    #
    # @param inputData The raw data as received from Webconf (a single line of text)
    @Slot(str)
    def handleInput(self, inputData):
        logging.error(f"Input retrieved from webconf fifo: {inputData}")
        # Tokenizing step (that is, a new element will be started by a / (except when the previous character was a \)
        def split_unescape(s, delim, escape='\\', unescape=True):
            # Helpful escape-capable split function by Taha Jahangir: https://stackoverflow.com/a/21882672/232739
            ret = []
            current = []
            itr = iter(s)
            for ch in itr:
                if ch == escape:
                    try:
                        # skip the next character; it has been escaped!
                        if not unescape:
                            current.append(escape)
                        current.append(next(itr))
                    except StopIteration:
                        if unescape:
                            current.append(escape)
                elif ch == delim:
                    # split! (add current to the list and reset it)
                    ret.append(''.join(current))
                    current = []
                else:
                    current.append(ch)
            ret.append(''.join(current))
            return ret
        splitData = split_unescape(inputData, "/")
        logging.error(f"The tokenized input data is {splitData}")
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
                case "sounds":
                    if splitDataLength > 1:
                        match splitData[1]:
                            case "process":
                                if splitDataLength > 2:
                                    # The "absolute" paths actually lack the slash at the front, so fix that real quick...
                                    Zynthbox.SndLibrary.instance().processSndFiles(["/" + entry for entry in splitData[2:]])
                                else:
                                    # Perhaps this should cause an "update everything" refresh type thing?
                                    pass
                            case "setCategory":
                                pass
                case "sketchpad":
                    if splitDataLength > 2:
                        match splitData[1]:
                            case "track":
                                if splitDataLength > 3:
                                    trackIndex = splitData[2]
                                    track = self.core_gui.sketchpad.song.channelsModel.getChannel(max(0, min(trackIndex, Zynthbox.Plugin.instance().sketchpadTrackCount())))
                                    match splitData[3]:
                                        case "loadSound":
                                            if splitDataLength == 5:
                                                sndFile = "/" + splitData[4]
                                                # Load .snd file (if it's an snd file and, you know, exists and stuff!)
                                                sound = Zynthbox.SndLibrary.instance().sourceModel().getSound(sndFile)
                                                if sound is not None:
                                                    def task():
                                                        track.setChannelSoundFromSnapshot(sound.synthFxSnapshot())
                                                        track.setChannelSamplesFromSnapshot(sound.sampleSnapshot())
                                                        self.zynqtgui.end_long_task()
                                                    self.core_gui.do_long_task(task, "Loading snd file")
                                                else:
                                                    logging.error(f"We were asked to load an snd file that seems to not exist: {sndFile}")
                                        case "clearSlot":
                                            if splitDataLength == 6:
                                                slotType = splitData[4]
                                                slotIndex = max(0, min(splitData[5], Zynthbox.Plugin.instance().sketchpadSlotCount()))
                                                match slotType:
                                                    case "synth":
                                                        if track.checkIfLayerExists(track.chainedSounds[slotIndex]):
                                                            track.remove_and_unchain_sound(track.chainedSounds[slotIndex])
                                                    case "sample":
                                                        sampleClip = track.samples[slotIndex]
                                                        sampleClip.clear()
                                                    case "sketch":
                                                        sketchClip = track.getClipsModelById(slotIndex).getClip(self.core_gui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                                                        sketchClip.clear()
                                                    case "fx":
                                                        track.removeFxFromChain(slotIndex)
                                        case "loadIntoSlot":
                                            if splitDataLength == 7:
                                                slotType = splitData[4]
                                                slotIndex = max(0, min(splitData[5], Zynthbox.Plugin.instance().sketchpadSlotCount()))
                                                fileName = "/" + splitData[6]
                                                match slotType:
                                                    case "synth":
                                                        pass
                                                    case "sample":
                                                        sampleClip = track.samples[slotIndex]
                                                        sampleClip.path = fileName
                                                        # sampleClip.enabled = True
                                                    case "sketch":
                                                        sketchClip = track.getClipsModelById(slotIndex).getClip(self.core_gui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                                                        sketchClip.path = fileName
                                                        # sketchClip.enabled = True
                                                    case "fx":
                                                        pass
                                            elif splitDataLength == 9:
                                                # In this case we are pulling something out of an .snd or .sketch.wav, for inserting into some slot
                                                slotType = splitData[4]
                                                slotIndex = max(0, min(splitData[5], Zynthbox.Plugin.instance().sketchpadSlotCount()))
                                                fileName = "/" + splitData[6]
                                                originType = splitData[7]
                                                originIndex = splitData[8]
                                                sound = Zynthbox.SndLibrary.instance().sourceModel().getSound(sndFile)
                                                if sound is not None:
                                                    match slotType:
                                                        case "synth":
                                                            pass
                                                        case "sample":
                                                            # sampleClip = track.samples[slotIndex]
                                                            # sampleClip.path = fileName
                                                            # sampleClip.enabled = True
                                                            pass
                                                        case "sketch":
                                                            # sketchClip = track.getClipsModelById(slotIndex).getClip(self.core_gui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                                                            # sketchClip.path = fileName
                                                            # sketchClip.enabled = True
                                                            pass
                                                        case "fx":
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
