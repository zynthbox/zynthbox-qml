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

import json
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
# The command handler supports two types of commands: Compact JSON strings,
# and raw /-separated command strings. They are both described in detail in the
# documentation for handleInput(inputData:str) below.
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
    # There are two versions of commands that are understood by the handler:
    # * compact json form
    # * / separated commands
    #
    # ### Compact JSON Form Commands ###
    #
    # A command in compact JSON form must be a single line (as any other command), and must furthermore
    # begin with open curly braces "{" to signify the start of a json object in compact string form. If
    # you send an ill-formed json string, it will simply be ignored (though feedback will be given).
    #
    # The format of the json commands will be (with added lines for ease of display, but you must make sure
    # to not send a json string with a newline in it):
    #
    # {
    #     "category": "the category of command",
    #     "command": "command identifier",
    #     /* Not required for all commands - required fields will be listed per command */
    #     "trackIndex": trackIndex,
    #     "slotType": "slot type name, either synth, sample, sketch, or fx",
    #     "slotIndex": slotIndex,
    #     "slotType2": "slot type name, either synth, sample, sketch, or fx",
    #     "slot2Index": slotIndex,
    #     "params": ["a", "list", "of", "arbitrary strings as supported", "by json", "but still no newlines"]
    # }
    #
    # Anything called an index is a number from 0 and up. For tracks, you have 10 tracks, meaning it can be
    # up to 9, and for slots, there are five slots of each type, meaning the index can be from 0 through 4.
    #
    # Upon completion of the handling of the command, you will be sent back the same data you sent, with the
    # addition of the field "messageType", which will be either "success" or "error" according to the result.
    # If the type is "error", there will also be a "description" field, which contains a human-readable
    # description of the error.
    #
    # ### Command Categories and Identifiers ###
    #
    # To ensure the simplest possible way to separate commands, we define a category, and a command in that
    # category. As mentioned above, not all commands require all fields, and for each command, we will list
    # what fields are required. The tree below has the category as the top level, and command as the second.
    # If any required field is not defined, or incorrectly set, we will not attempt to make guesses as to
    # what was intended, and instead we will do nothing, and also send a message back to webconf to say that
    # the command failed, with a useful message describing what went wrong.
    #
    # cuia
    #   any cuia command (see the callable_ui_action function to see what is available... TODO Not really, need to list everything here, with requirements)
    # sounds
    #   process
    #     required: params
    #     * params contains absolute paths to sound files that require processing
    # sketchpad
    #   new - creates a new sketchpad, optionally based on an existing one
    #     optional: params
    #     * if defined, params contains one entry, with an absolute path to the sketchpad json to base
    #       the new sketchpad on
    #   load - loads the given sketchpad as the new current sketchpad
    #     required: params
    #     * params contains one entry, with an absolute path to the sketchpad json to load
    #   saveCopy - saves the sketchpad into a new folder named as given
    #     required: params
    #     * params contains one entry, with the name of the sketchpad
    #     * to function as a "normal" save as function, once completed, call load on the new copy
    #   saveVersion - creates a "snapshot" of the current state of the sketchpad
    #     required: params
    #     * params contains one entry, with the name of the version to be saved
    # track
    #   loadSound
    #     required: trackIndex, and params
    #     * params contains one entry, with an absolute path to the sound file to load
    #   clearSlot - clears what is set on the specified slot
    #     required: track, slotType, slotIndex
    #   loadIntoSlot
    #     required: track, slotType, slotIndex, and params
    #     optional: slotType2, and slotIndex2
    #     * params contains the absolute path of a single file
    #     * if slotType2 and slotIndex2 are both set, and params contains a snd file or sketch.wav, we will
    #       load the data in that given slot in the file and set that on the specified slot. If the origin
    #       slot (that is, in the snd or sketch) is empty, the destination slot will be cleared.
    #     * if they are not set, we will attempt to load the given file into the specified slot
    #     * the type of the given file must (hopefully obviously) contain suitable data for the destination
    #
    # ### /-Separated Commands ###
    #
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
        if len(inputData) > 0:
            if inputData[0] == "{":
                # This is a command in compact json form
                jsonData = None
                try:
                    jsonData = json.loads(inputData)
                except Exception as e:
                    logging.error(f"Incorrectly formed json, error was {e}: {jsonData}")
                if jsonData is not None:
                    if "category" in jsonData and "command" in jsonData:
                        self.handleJsonInput(jsonData)
                    else:
                        logging.error("Incorrectly described command: there must be at least a category and command defined")
                        jsonData["messageType"] = "error"
                        jsonData["description"] = "Incorrectly described command: there must be at least a category and command defined"
                        self.send(json.dumps(jsonData, separators=(',', ':')))
                else:
                    logging.error(f"Failed to load json command from: {jsonData}")
                    self.send(json.dumps({ "messageType": "error", "description": "Failed to load json command from given json string", "data": "\"inputData\"" }, separators=(',', ':')))
            else:
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
                                                            synthFxSnapshot = sound.synthFxSnapshot()
                                                            sampleSnapshot = sound.sampleSnapshot()
                                                            if synthFxSnapshot and sampleSnapshot:
                                                                def task():
                                                                    track.setChannelSoundFromSnapshot(synthFxSnapshot)
                                                                    track.setChannelSamplesFromSnapshot(sampleSnapshot)
                                                                    self.core_gui.end_long_task()
                                                                self.core_gui.do_long_task(task, f"Loading snd file<br />{sound.name}")
                                                            else:
                                                                logging.error(f"We were asked to load an snd file which contains no snapshots: {sndFile}")
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
                                                        sound = Zynthbox.SndLibrary.instance().sourceModel().getSound(fileName)
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

    ### The specific handler for json data, which must already be sanitised and contain at least a category and command
    def handleJsonInput(self, jsonData):
        trackIndex = max(0, min(jsonData["trackIndex"], Zynthbox.Plugin.instance().sketchpadTrackCount())) if "trackIndex" in jsonData else -1
        slotType = jsonData["slotType"] if "slotType" in jsonData else ""
        slotIndex = max(0, min(jsonData["slotIndex"], Zynthbox.Plugin.instance().sketchpadSlotCount())) if "slotIndex" in jsonData else -1
        slotType2 = jsonData["slotType2"] if "slotType2" in jsonData else ""
        slotIndex2 = max(0, min(jsonData["slotIndex2"], Zynthbox.Plugin.instance().sketchpadSlotCount())) if "slotIndex2" in jsonData else -1
        params = jsonData["params"][0] if "params" in jsonData else [-1]
        match jsonData["category"]:
            case "cuia":
                self.core_gui.callable_ui_action(jsonData["command"].upper(), params, -1, trackIndex, slotIndex)
                jsonData["messageType"] = "success"
            case "sounds":
                match jsonData["command"]:
                    case "process":
                        if "params" in jsonData:
                            Zynthbox.SndLibrary.instance().processSndFiles(jsonData["params"])
                            jsonData["messageType"] = "success"
                        else:
                            logging.error(f"Missing params field for snd processing in {jsonData}")
                            jsonData["messageType"] = "error"
                            jsonData["description"] = "Missing params field for snd processing"
            case "sketchpad":
                match jsonData["command"]:
                    case "new":
                        def completionCallback():
                            jsonData["messageType"] = "success"
                            self.send(json.dumps(jsonData, separators=(',', ':')))
                        if "params" in jsonData and len(jsonData["params"]) == 1:
                            # If params does not point at an extant sketchpad file, we'll have to abort and report that back
                            sketchpadTemplate = jsonData["params"][0]
                            if os.path.exists(sketchpadTemplate):
                                # Clear out temp sketchpad, replace it with what's pointed to in params, and finally load that newly created temp sketchpad
                                self.core_gui.sketchpad.newSketchpad(base_sketchpad=sketchpadTemplate, force=True, cb=completionCallback)
                            else:
                                jsonData["messageType"] = "error"
                                jsonData["description"] = "Attempted to create a new sketchpad based on an existing one, but the existing one does not exist on the device"
                        elif "params" not in jsonData or len(jsonData["params"]) == 0:
                            # Either there's no template defined, or there's no params at all - create a new, empty sketchpad
                            self.core_gui.sketchpad.newSketchpad(force=True, cb=completionCallback)
                        else:
                            jsonData["messageType"] = "error"
                            jsonData["description"] = "Incorrectly defined attempt to create a new sketchpad (must have either precisely one entry in params to clone, or none)"
                    case "load":
                        if "params" in jsonData and len(jsonData["params"]) == 1:
                            sketchpadFile = jsonData["params"][0]
                            if os.path.exists(sketchpadFile):
                                # FIXME Do we *actually* want to load_autosave, or... have we picked a specific version to load? We have, haven't we?
                                self.core_gui.sketchpad.loadSketchpad(sketchpad=sketchpadFile, load_autosave=True, cb=completionCallback)
                            else:
                                jsonData["messageType"] = "error"
                                jsonData["description"] = "Attempted to load a sketchpad, but the file does not exist on the device"
                        else:
                            jsonData["messageType"] = "error"
                            jsonData["description"] = "Missing or incorrect params field for loading a sketchpad (the list should contain a single file path)"
                    case "saveCopy":
                        if "params" in jsonData and len(jsonData["params"]) == 1:
                            self.core_gui.sketchpad.saveCopy(jsonData["params"][0], cb=completionCallback)
                            jsonData["messageType"] = "success"
                        else:
                            jsonData["messageType"] = "error"
                            jsonData["description"] = "Missing or incorrect params field for saving a sketchpad (the list should contain a single string element, being the new name for the sketchpad)"
                    case "saveVersion":
                        if "params" in jsonData and len(jsonData["params"]) == 1:
                            self.core_gui.sketchpad.song.name = jsonData["params"][0]
                            self.core_gui.sketchpad.saveSketchpad(cb=completionCallback)
                            jsonData["messageType"] = "success"
                        else:
                            jsonData["messageType"] = "error"
                            jsonData["description"] = "Missing or incorrect params field for saving a sketchpad version (the list should contain a single string element, being the name for the new version)"
            case "track":
                if "trackIndex" in jsonData:
                    track = self.core_gui.sketchpad.song.channelsModel.getChannel(max(0, min(int(jsonData["trackIndex"]), Zynthbox.Plugin.instance().sketchpadTrackCount())))
                    match jsonData["command"]:
                        case "loadSound":
                            if "params" in jsonData and len(jsonData["params"]) == 1:
                                sndFile = jsonData["params"][0]
                                # Load .snd file (if it's an snd file and, you know, exists and stuff!)
                                sound = Zynthbox.SndLibrary.instance().sourceModel().getSound(sndFile)
                                if sound is not None:
                                    synthFxSnapshot = sound.synthFxSnapshot()
                                    sampleSnapshot = sound.sampleSnapshot()
                                    if synthFxSnapshot and sampleSnapshot:
                                        def task():
                                            track.setChannelSoundFromSnapshot(synthFxSnapshot)
                                            track.setChannelSamplesFromSnapshot(sampleSnapshot)
                                            jsonData["messageType"] = "success"
                                            self.send(json.dumps(jsonData, separators=(',', ':')))
                                            self.core_gui.end_long_task()
                                        self.core_gui.do_long_task(task, f"Loading snd file<br />{sound.name}")
                                    else:
                                        logging.error(f"We were asked to load an snd file that contains no snapshots: {sndFile}")
                                        jsonData["messageType"] = "error"
                                        jsonData["description"] = "Load Sound was asked to load an snd file that contains no snapshots"
                                else:
                                    logging.error(f"We were asked to load an snd file that seems to not exist: {sndFile}")
                                    jsonData["messageType"] = "error"
                                    jsonData["description"] = "Load Sound was asked to load an snd file that seems to not exist"
                            else:
                                logging.error("We were asked to load a sound, but not given a sound to load")
                                jsonData["messageType"] = "error"
                                jsonData["description"] = "Load Sound was not given a sound to load"
                        case "clearSlot":
                            if slotType != "" and slotIndex > -1:
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
                                jsonData["messageType"] = "success"
                            else:
                                jsonData["messageType"] = "error"
                                jsonData["description"] = "Clear Slot command missing slot type and/or index"
                        case "loadIntoSlot":
                            if slotType != "" and slotIndex > -1:
                                if "params" in jsonData and len(jsonData["params"]) == 1:
                                    fileName = jsonData["params"][0]
                                    if os.path.exist(fileName):
                                        if slotType2 != "" and slotIndex2 > -1:
                                            # TODO Implement handling pulling things from an snd file and inserting that into a specific slot on the given track
                                            jsonData["messageType"] = "success"
                                            pass
                                        else:
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
                                        jsonData["messageType"] = "success"
                                    else:
                                        logging.error(f"Asked to load a file into a slot, but the file does not seem to exist: {jsonData}")
                                        jsonData["messageType"] = "error"
                                        jsonData["description"] = "Load Into Slot command was given a file to load which doesn't exist on the device"
                                else:
                                    logging.error(f"Asked to load a file into a slot, but we were not given a filename to load: {jsonData}")
                                    jsonData["messageType"] = "error"
                                    jsonData["description"] = "Load Into Slot command is missing instructions for what file to load"
                            else:
                                logging.error(f"Asked to load a file into slot, but we lack instructions for what to load things into: {jsonData}")
                                jsonData["messageType"] = "error"
                                jsonData["description"] = "Load Into Slot command is missing instructions for which slot to load things into"
                else:
                    jsonData["messageType"] = "error"
                    jsonData["description"] = "Track command is missing a track index"
        if "messageType" in jsonData:
            self.send(json.dumps(jsonData, separators=(',', ':')))

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
