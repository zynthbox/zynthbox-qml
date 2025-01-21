/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Base Drums Grid Component 

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>
Copyright (C) 2021 David Nelvand <dnelband@gmail.com>

******************************************************************************

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of
the License, or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

For a full copy of the GNU General Public License see the LICENSE.txt file.

******************************************************************************
*/

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.BasePlayGrid {
    id: component
    grid: drumsGrid
    settings: drumsGridSettings
    popup: drumsPopup
    sidebar: drumsGridSidebar
    name:'Stepsequencer'
    isSequencer: true
    defaults: {
        "positionalVelocity": true
    }
    property bool isVisible: ["playgrid"].indexOf(zynqtgui.current_screen_id) >= 0
    persist: ["positionalVelocity"]
    // additionalActions: [
    //     Kirigami.Action {
    //         text: qsTr("Load Pattern...")
    //         onTriggered: {
    //             sequenceLoader.loadSequenceFromFile(_private.sequence.objectName);
    //         }
    //     },
    //     // Kirigami.Action {
    //     //     text: qsTr("Export Sequence...")
    //     //     onTriggered: {
    //     //         sequenceLoader.saveSequenceToFile(_private.sequence.objectName);
    //     //     }
    //     // },
    //     Kirigami.Action {
    //        text: qsTr("Export Current Pattern...")
    //        onTriggered: {
    //            sequenceLoader.savePatternToFile();
    //        }
    //     },
    //     Kirigami.Action {
    //         text: qsTr("Get New Patterns...")
    //         onTriggered: {
    //             zynqtgui.show_modal("sequence_downloader")
    //         }
    //     }
    // ]

    cuiaCallback: function(cuia) {
        var backButtonClearPatternHelper = function(channelIndex) {
            if (zynqtgui.backButtonPressed) {
                zynqtgui.ignoreNextBackButtonPress = true;
                for (var clipIndex = 0; clipIndex < Zynthbox.Plugin.sketchpadSlotCount; ++clipIndex) {
                    var pattern = _private.sequence.getByClipId(channelIndex, clipIndex);
                    if (pattern) {
                        pattern.clear();
                    }
                }
                return true;
            }
            return false;
        }
        var returnValue = false;

        // if (sequenceLoader.opened) {
        //     returnValue = sequenceLoader.cuiaCallback(cuia);
        // }

        if (returnValue === false) {
            var trackDelta = zynqtgui.tracksModActive ? 5 : 0

            switch (cuia) {
                case "SCREEN_PLAYGRID":
                    // If we're already shown, toggle note settings
                    if (component.noteSettingsPopupVisible) {
                        component.hideNoteSettingsPopup();
                    } else {
                        if (_private.selectedStep > -1) {
                            component.showNoteSettingsPopup(_private.workingPatternModel, _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset, _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset, [], _private.selectedStep, _private.selectedStep);
                        } else if (component.heardNotes.length > 0) {
                            var filter = []
                            for (var i = 0; i < component.heardNotes.length; ++i) {
                                filter.push(component.heardNotes[i].midiNote);
                            }
                            component.showNoteSettingsPopup(_private.workingPatternModel, _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset, _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset, filter, -1, -1);
                        } else {
                            component.showNoteSettingsPopup(_private.workingPatternModel, _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset, _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset, [], -1, -1);
                        }
                    }
                    break;
                case "SWITCH_BACK_SHORT":
                case "SWITCH_BACK_BOLD":
                    if (zynqtgui.altButtonPressed) {
                        _private.workingPatternModel.clear();
                    } else {
                        if (_private.activePatternModel.performanceActive) {
                            // Restart the performance
                            _private.activePatternModel.startPerformance();
                        } else if (component.patternsMenuVisible) {
                            component.hidePatternsMenu();
                        } else if (_private.hasSelection) {
                            _private.deselectSelectedItem();
                        } else if (component.heardNotes.length > 0) {
                            component.heardNotes = [];
                            component.heardVelocities = [];
                        }
                    }
                    returnValue = true;
                    break;
                case "SELECT_UP":
                    if (zynqtgui.altButtonPressed || zynqtgui.modeButtonPressed) {
                        _private.octaveUp();
                    } else {
                        _private.nextBar();
                    }
                    break;
                case "SELECT_DOWN":
                    if (zynqtgui.altButtonPressed || zynqtgui.modeButtonPressed) {
                        _private.octaveDown();
                    } else {
                        _private.previousBar();
                    }
                    break;
                case "NAVIGATE_LEFT":
                    if (zynqtgui.sketchpad.selectedTrackId > 0) {
                        zynqtgui.sketchpad.selectedTrackId = _private.activePatternModel.sketchpadTrack - 1;
                    }
                    returnValue = true;
                    break;
                case "NAVIGATE_RIGHT":
                    if (zynqtgui.sketchpad.selectedTrackId < Zynthbox.Plugin.sketchpadTrackCount) {
                        zynqtgui.sketchpad.selectedTrackId = _private.activePatternModel.sketchpadTrack + 1;
                    }
                    returnValue = true;
                    break;
                case "SWITCH_SELECT_SHORT":
                case "SWITCH_SELECT_BOLD":
                    _private.activateSelectedItem();
                    returnValue = true;
                    break;
                case "TRACK_1":
                    returnValue = backButtonClearPatternHelper(0 + trackDelta);
                    break;
                case "TRACK_2":
                    returnValue = backButtonClearPatternHelper(1 + trackDelta);
                    break;
                case "TRACK_3":
                    returnValue = backButtonClearPatternHelper(2 + trackDelta);
                    break;
                case "TRACK_4":
                    returnValue = backButtonClearPatternHelper(3 + trackDelta);
                    break;
                case "TRACK_5":
                    returnValue = backButtonClearPatternHelper(4 + trackDelta);
                    break;
                case "KNOB0_UP":
                    _private.knob0Up();
                    returnValue = true;
                    break;
                case "KNOB0_DOWN":
                    _private.knob0Down();
                    returnValue = true;
                    break;
                case "KNOB1_UP":
                    _private.knob1Up();
                    returnValue = true;
                    break;
                case "KNOB1_DOWN":
                    _private.knob1Down();
                    returnValue = true;
                    break;
                case "KNOB2_UP":
                    _private.knob2Up();
                    returnValue = true;
                    break;
                case "KNOB2_DOWN":
                    _private.knob2Down();
                    returnValue = true;
                    break;
                case "KNOB3_UP":
                    if (zynqtgui.modeButtonPressed) {
                        _private.nudgeRight();
                    } else {
                        _private.goRight();
                    }
                    returnValue = true;
                    break;
                case "KNOB3_DOWN":
                    if (zynqtgui.modeButtonPressed) {
                        _private.nudgeLeft();
                    } else {
                        _private.goLeft();
                    }
                    returnValue = true;
                    break;
                case "SWITCH_MODE_RELEASED":
                    if (_private.activePatternModel.performanceActive) {
                        _private.activePatternModel.applyPerformance();
                        _private.activePatternModel.stopPerformance();
                        returnValue = true;
                    }
                    break;
                default:
                    break;
            }
        }
        return returnValue;
    }

    property bool patternsMenuVisible: false
    signal hidePatternsMenu();
    signal showPatternsMenu();
    property bool showPatternSettings: false
    signal showNoteSettingsPopup(QtObject patternModel, int firstBar, int lastBar, var midiNoteFilter, int firstStep, int lastStep);
    signal hideNoteSettingsPopup();
    property bool noteSettingsPopupVisible: false

    property bool nudgeOverlayEnabled: false
    property bool nudgePerformed: false

    property var heardNotes: []
    property var heardVelocities: []
    property var currentRowUniqueNotes: []
    property var currentRowUniqueMidiNotes: []
    property var currentBarNotes: []
    property var currentBankNotes: []

    function setActiveBar(activeBar) {
        _private.activePatternModel.activeBar = activeBar;
    }

    function pickPattern(patternIndex) {
        var patternObject = _private.sequence.get(patternIndex);
        if (patternObject.sketchpadTrack > -1 && patternObject.clipIndex > -1) {
            zynqtgui.sketchpad.selectedTrackId = patternObject.sketchpadTrack;
            var channel = zynqtgui.sketchpad.song.channelsModel.getChannel(patternObject.sketchpadTrack);
            channel.selectedClip = patternObject.clipIndex;
        }
    }

    QtObject {
        id:_private;
        readonly property int activeBarModelWidth: 16

        property QtObject sequence
        property int activePattern: sequence && !sequence.isLoading && sequence.count > 0 ? sequence.activePattern : -1
        property QtObject activePatternModel: sequence && !sequence.isLoading && sequence.count > 0 ? sequence.activePatternObject : null;
        property QtObject workingPatternModel: activePatternModel ? activePatternModel.workingModel : null;
        property QtObject activeBarModel: workingPatternModel && activeBar > -1 && workingPatternModel.data(workingPatternModel.index(activeBar + bankOffset, 0), workingPatternModel.roles["rowModel"])
            ? workingPatternModel.data(workingPatternModel.index(activeBar + bankOffset, 0), workingPatternModel.roles["rowModel"])
            : null;

        property bool patternHasUnsavedChanged: false
        property bool positionalVelocity: true
        property var bars: [0,1,2,3,4,5,6,7]
        // This is the top bank we have available in any pattern (that is, the upper limit for any pattern's bankOffset value)
        property int bankLimit: 1
        property var clipBoard
        property int gridStartNote: 48

        // Properties inherent to the active pattern (set these through _private.sequence.setPatternProperty(_private.activePattern, ...))
        property int stepLength: sequence && sequence.activePatternObject ? sequence.activePatternObject.stepLength : 0
        property int swing: sequence && sequence.activePatternObject ? sequence.activePatternObject.swing : 0
        property var availableBars: sequence && sequence.activePatternObject ? sequence.activePatternObject.availableBars : 0
        property var activeBar: sequence && sequence.activePatternObject ? sequence.activePatternObject.activeBar : -1
        property int bankOffset: sequence && sequence.activePatternObject ? sequence.activePatternObject.bankOffset : 0
        property string bankName: sequence && sequence.activePatternObject ? sequence.activePatternObject.bank : "?"
        property string sceneName: zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongName
        property QtObject associatedChannel;
        property int associatedChannelIndex;

        function updateChannel() {
            channelUpdater.restart();
        }
        property QtObject channelUpdater: Timer {
            running: false;
            repeat: false;
            interval: 1;
            onTriggered: {
                if (_private.activePatternModel) {
                    _private.associatedChannel = zynqtgui.sketchpad.song.channelsModel.getChannel(_private.activePatternModel.sketchpadTrack);
                    _private.associatedChannelIndex =  _private.activePatternModel.sketchpadTrack;
                    Qt.callLater(_private.updateUniqueCurrentRowNotes)
                } else {
                    _private.updateChannel();
                }
            }
        }

        property QtObject currentChannel: zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId)
        property string currentSoundName: {
            var text = "(no sound)";
            if (_private.currentChannel) {
                for (var id in _private.currentChannel.chainedSounds) {
                    if (_private.currentChannel.chainedSounds[id] >= 0 &&
                        _private.currentChannel.checkIfLayerExists(_private.currentChannel.chainedSounds[id])) {
                        text = zynqtgui.fixed_layers.selector_list.getDisplayValue(_private.currentChannel.chainedSounds[id]);
                        break;
                    }
                }
            }
            return text;
        }
        //property QtObject activeBarModel: Zynthbox.FilterProxy {
            //sourceModel: patternModel
            //filterRowStart: activeBar
            //filterRowEnd: activeBar
        //}

        onActivePatternModelChanged:{
            updateChannel();
            while (hasSelection) {
                deselectSelectedItem();
            }
        }

        signal knob0Up();
        signal knob0Down();
        signal knob1Up();
        signal knob1Down();
        signal knob2Up();
        signal knob2Down();
        signal goLeft();
        signal goRight();
        signal deselectSelectedItem()
        signal activateSelectedItem()
        property bool hasSelection: false
        property int selectedStep: -1
        function previousBar() {
            if (sequence.activePatternObject.activeBar > 0) {
                sequence.activePatternObject.activeBar = sequence.activePatternObject.activeBar - 1;
            }
        }
        function nextBar() {
            if (sequence.activePatternObject.activeBar < sequence.activePatternObject.availableBars - 1) {
                _private.sequence.activePatternObject.activeBar = _private.sequence.activePatternObject.activeBar + 1;
            }
        }
        function nudgeLeft() {
            if (activePatternModel) {
                if (activePatternModel.performanceActive === false) {
                    activePatternModel.startPerformance();
                }
                let nudgeAmount = -1;
                let firstStep = (_private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset) * _private.workingPatternModel.width;
                let lastStep = Math.min(firstStep + _private.workingPatternModel.width, (_private.workingPatternModel.bankOffset * _private.workingPatternModel.width) + _private.workingPatternModel.patternLength) - 1;
                if (zynqtgui.altButtonPressed) {
                    firstStep = _private.workingPatternModel.bankOffset * _private.workingPatternModel.width;
                    lastStep = _private.workingPatternModel.patternLength - 1;
                }
                workingPatternModel.nudge(firstStep, lastStep, nudgeAmount, component.heardNotes);
            }
        }
        function nudgeRight() {
            if (activePatternModel) {
                if (activePatternModel.performanceActive === false) {
                    activePatternModel.startPerformance();
                }
                let nudgeAmount = 1;
                let firstStep = (_private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset) * _private.workingPatternModel.width;
                let lastStep = Math.min(firstStep + _private.workingPatternModel.width, (_private.workingPatternModel.bankOffset * _private.workingPatternModel.width) + _private.workingPatternModel.patternLength) - 1;
                if (zynqtgui.altButtonPressed) {
                    firstStep = _private.workingPatternModel.bankOffset * _private.workingPatternModel.width;
                    lastStep = _private.workingPatternModel.patternLength - 1;
                }
                workingPatternModel.nudge(firstStep, lastStep, nudgeAmount, component.heardNotes);
            }
        }

        function octaveUp() {
            let numberOfMoves = 1;
            if (zynqtgui.modeButtonPressed) {
                numberOfMoves = 3;
                zynqtgui.ignoreNextModeButtonPress = true;
            }
            for (let moveNumber = 0; moveNumber < numberOfMoves; ++moveNumber) {
                // Don't scroll past the end
                if (_private.workingPatternModel.gridModelStartNote < 112) {
                    // 4 being the width of the grid - heuristics are a go, but also the thing is 16 long so...
                    _private.workingPatternModel.gridModelStartNote = _private.workingPatternModel.gridModelStartNote + 4;
                    _private.workingPatternModel.gridModelEndNote = _private.workingPatternModel.gridModelStartNote + 16;
                }
            }
        }
        function octaveDown() {
            let numberOfMoves = 1;
            if (zynqtgui.modeButtonPressed) {
                numberOfMoves = 3;
                zynqtgui.ignoreNextModeButtonPress = true;
            }
            for (let moveNumber = 0; moveNumber < numberOfMoves; ++moveNumber) {
                // Don't scroll past the end
                if (_private.workingPatternModel.gridModelStartNote > 0) {
                    // 4 being the width of the grid - heuristics are a go, but also the thing is 16 long so...
                    _private.workingPatternModel.gridModelStartNote = _private.workingPatternModel.gridModelStartNote - 4;
                    _private.workingPatternModel.gridModelEndNote = _private.workingPatternModel.gridModelStartNote + 16;
                }
            }
        }

        property var availableNoteLengths: [384, 192, 96, 48, 24, 12, 6, 3]
        function stepLengthUp() {
            if (zynqtgui.modeButtonPressed) {
                zynqtgui.ignoreNextModeButtonPress = true;
                _private.sequence.setPatternProperty(_private.activePattern, "stepLength", _private.workingPatternModel.stepLength + 1);
            } else {
                _private.sequence.setPatternProperty(_private.activePattern, "stepLength", _private.workingPatternModel.nextStepLengthStep(_private.workingPatternModel.stepLength, 1));
            }
        }
        function stepLengthDown() {
            if (zynqtgui.modeButtonPressed) {
                zynqtgui.ignoreNextModeButtonPress = true;
                _private.sequence.setPatternProperty(_private.activePattern, "stepLength", _private.workingPatternModel.stepLength - 1);
            } else {
                _private.sequence.setPatternProperty(_private.activePattern, "stepLength", _private.workingPatternModel.nextStepLengthStep(_private.workingPatternModel.stepLength, -1));
            }
        }
        function swingUp() {
            if (_private.swing < 99) {
                _private.sequence.setPatternProperty(_private.activePattern, "swing", _private.swing + 1)
            }
        }
        function swingDown() {
            if (_private.swing > 1) {
                _private.sequence.setPatternProperty(_private.activePattern, "swing", _private.swing - 1);
            }
        }
        function patternLengthUp() {
            if (_private.workingPatternModel && _private.workingPatternModel.patternLength < (_private.workingPatternModel.bankLength * _private.workingPatternModel.width)) {
                if (zynqtgui.modeButtonPressed) {
                    zynqtgui.ignoreNextModeButtonPress = true;
                    _private.sequence.setPatternProperty(_private.activePattern, "patternLength", _private.workingPatternModel.patternLength + 1);
                } else {
                    if (_private.workingPatternModel.availableBars * _private.workingPatternModel.width === _private.workingPatternModel.patternLength) {
                        _private.sequence.setPatternProperty(_private.activePattern, "patternLength", _private.workingPatternModel.patternLength + _private.workingPatternModel.width);
                    } else {
                        _private.sequence.setPatternProperty(_private.activePattern, "patternLength", _private.workingPatternModel.availableBars * _private.workingPatternModel.width);
                    }
                }
            }
        }
        function patternLengthDown() {
            if (zynqtgui.modeButtonPressed) {
                zynqtgui.ignoreNextModeButtonPress = true;
                _private.sequence.setPatternProperty(_private.activePattern, "patternLength", _private.workingPatternModel.patternLength - 1);
            } else {
                if (_private.workingPatternModel && _private.workingPatternModel.patternLength > _private.workingPatternModel.width) {
                    if (_private.workingPatternModel.availableBars * _private.workingPatternModel.width === _private.workingPatternModel.patternLength) {
                        _private.sequence.setPatternProperty(_private.activePattern, "patternLength", _private.workingPatternModel.patternLength - _private.workingPatternModel.width);
                    } else {
                        _private.sequence.setPatternProperty(_private.activePattern, "patternLength", (_private.workingPatternModel.availableBars - 1) * _private.workingPatternModel.width);
                    }
                }
            }
        }

        /**
         * \brief Copy the range from startRow to endRow (inclusive) from model into the clipboard
         * @param model The model you wish to copy notes and metadata out of
         * @param startRow The first row you wish to operate on
         * @param endRow The last row you wish to operate on
         */
        function copyRange(description, model, startRow, endRow) {
            var newClipboardNotes = [];
            var newClipboardMetadata = []
            for (var row = startRow; row < endRow + 1; ++row) {
                newClipboardNotes = newClipboardNotes.concat(model.getRow(row));
                newClipboardMetadata = newClipboardMetadata.concat(model.getRowMetadata(row));
            }
            _private.clipBoard = {
                description: description,
                notes: newClipboardNotes,
                velocities: newClipboardMetadata
            }
        }
        /**
         * \brief Replace the contents of the range startRow to endRow (inclusive) in the given model with the clipboard data
         * @note The notes will be adjusted to operate on the model's assigned midi channel
         * @note This function will first clear the given rows, and then insert the data from the clipboard
         * If the clipboard is longer than the given range, it will stop inserting notes when endRow is reached. If the clipboard
         * is shorter, all rows in the given range will still be cleared.
         * @param model The model you wish to insert the clipboard data into
         * @param startRow The position of the first row you wish to replace with clipboard data
         * @param endRow The last row you wish to replace with clipboard data
         */
        function pasteInPlace(model, startRow, endRow) {
            var noteIndex = 0;
            model.startLongOperation();
            for (var row = startRow; row < endRow + 1; ++row) {
                for (var column = 0; column < model.width; ++column) {
                    var oldCompound = (noteIndex < _private.clipBoard.notes.length) ? _private.clipBoard.notes[noteIndex] : null;
                    var newSubnotes = [];
                    if (oldCompound) {
                        var oldSubnotes = oldCompound.subnotes;
                        if (oldSubnotes) {
                            for (var j = 0; j < oldSubnotes.length; ++j) {
                                newSubnotes.push(component.getNote(oldSubnotes[j].midiNote, model.sketchpadTrack));
                            }
                        }
                    }
                    model.setNote(row, column, component.getCompoundNote(newSubnotes))
                    var newMetadata = (noteIndex < _private.clipBoard.velocities.length) ? _private.clipBoard.velocities[noteIndex] : [];
                    model.setMetadata(row, column, newMetadata)
                    ++noteIndex;
                }
            }
            model.endLongOperation();
        }
        function adoptSequence() {
            if (zynqtgui.isBootingComplete) {
                console.log("Adopting the scene sequence");
                var sequence = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName);
                if (_private.sequence != sequence) {
                    console.log("Scene has changed, switch places!");
                    _private.sequence = sequence;
                }
            }
        }
        function updateUniqueCurrentRowNotes() {
            component.currentRowUniqueNotes = workingPatternModel.uniqueRowNotes(activeBar + bankOffset);
            let tempCurrentRowUniqueMidiNotes = [];
            for (var noteIndex = 0; noteIndex < component.currentRowUniqueNotes.length; ++noteIndex) {
                tempCurrentRowUniqueMidiNotes.push(component.currentRowUniqueNotes[noteIndex].midiNote);
            }
            component.currentRowUniqueMidiNotes = tempCurrentRowUniqueMidiNotes;
            var currentBarNotes = [];
            var currentBankNotes = [];
            for (var bar = 0; bar < _private.workingPatternModel.availableBars; ++bar) {
                var barNotes = _private.workingPatternModel.getRow(_private.bankOffset + bar);
                for (var positionIndex = 0; positionIndex < barNotes.length; ++positionIndex) {
                    var positionNote = barNotes[positionIndex];
                    if (positionNote) {
                        for (var subNoteIndex = 0; subNoteIndex < positionNote.subnotes.length; ++subNoteIndex) {
                            var subNote = positionNote.subnotes[subNoteIndex];
                            if (bar === _private.activeBar) {
                                currentBarNotes.push(subNote);
                            }
                            currentBankNotes.push(subNote);
                        }
                    }
                }
            }
            component.currentBarNotes = currentBarNotes;
            component.currentBankNotes = currentBankNotes;
        }
    }
    Connections {
        target: zynqtgui.isBootingComplete && zynqtgui.sketchpad && zynqtgui.sketchpad.song ? zynqtgui.sketchpad.song.channelsModel : null
        onConnectedSoundsCountChanged: _private.updateChannel()
        onConnectedPatternsCountChanged: _private.updateChannel()
    }
    Connections {
        target: _private.associatedChannel
        onConnectedPatternChanged: _private.updateChannel()
        onConnectedSoundChanged: _private.updateChannel()
    }
    Connections {
        target: zynqtgui.isBootingComplete && zynqtgui.sketchpad && zynqtgui.sketchpad.song ? zynqtgui.sketchpad : null
        onSongChanged: {
            _private.adoptSequence();
            _private.updateChannel();
        }
    }
    Connections {
        target: zynqtgui.isBootingComplete && zynqtgui.sketchpad && zynqtgui.sketchpad.song ? zynqtgui.sketchpad.song.scenesModel : null
        onSelectedSequenceNameChanged: Qt.callLater(_private.adoptSequence) // Makes scene change look smoother
    }
    Connections {
        target: zynqtgui
        onIsBootingCompleteChanged: {
            if (zynqtgui.isBootingComplete) {
                Qt.callLater(_private.adoptSequence)
            }
        }
    }
    // on component completed
    onInitialize: {
        _private.positionalVelocity = component.getProperty("positionalVelocity")
        _private.adoptSequence();
    }
    onPropertyChanged: {
        if (property === "positionalVelocity") {
            _private.positionalVelocity = value;
        }
    }
    Connections {
        target: Zynthbox.MidiRouter
        enabled: component.isVisible
        onMidiMessage: function(port, size, byte1, byte2, byte3, sketchpadTrack, fromInternal) {
            // console.log("Midi message of size", size, "received on port", port, "with bytes", byte1, byte2, byte3, "from track", sketchpadTrack, fromInternal, "current pattern's channel index", _private.activePatternModel.sketchpadTrack, "listening on port", listenToPort);
            if ((port == Zynthbox.MidiRouter.HardwareInPassthroughPort || port == Zynthbox.MidiRouter.InternalControllerPassthroughPort) && sketchpadTrack === _private.activePatternModel.sketchpadTrack && size === 3) {
                if (127 < byte1 && byte1 < 160) {
                    let setOn = true;
                    // By convention, an "off" note can be either a midi off message, or an on message with a velocity of 0
                    if (byte1 < 144 || byte3 === 0) {
                        setOn = false;
                    }
                    let midiNote = byte2;
                    let velocity = byte3;
                    if (setOn === true) {
                        if (component.noteListeningActivations === 0) {
                            // Clear the current state, in case there's something there (otherwise things look a little weird)
                            component.heardNotes = [];
                            component.heardVelocities = [];
                        }
                        // Count up one tick for a note on message
                        component.noteListeningActivations = component.noteListeningActivations + 1;
                        // Create a new note based on the new thing that just arrived, but only if it's an on note
                        var newNote = Zynthbox.PlayGridManager.getNote(midiNote, sketchpadTrack);
                        var existingIndex = component.noteListeningNotes.indexOf(newNote);
                        if (existingIndex > -1) {
                            component.noteListeningNotes.splice(existingIndex, 1);
                            component.noteListeningVelocities.splice(existingIndex, 1);
                        }
                        component.noteListeningNotes.push(newNote);
                        component.noteListeningVelocities.push(velocity);
                        // console.log("Registering note on , new activation count is", component.noteListeningActivations, component.noteListeningNotes);
                    } else if (setOn == false) {
                        // Count down one for a note off message
                        component.noteListeningActivations = component.noteListeningActivations - 1;
                        // console.log("Registering note off, new activation count is", component.noteListeningActivations, component.noteListeningNotes, component.noteListeningVelocities);
                    }
                    if (component.noteListeningActivations < 0) {
                        // this will generally happen after stopping playback (as the playback stops, then all off notes are sent out,
                        // and we'll end up receiving a bunch of them while not doing playback, without having received matching on notes)
                        // it might still happen at other times, so we might still need to do some testing later, but... this is the general case.
                        // console.debug("stepsequencer: Problem, we've received too many off notes compared to on notes, this is bad and shouldn't really be happening.");
                        component.noteListeningActivations = 0;
                        component.noteListeningNotes = [];
                        component.noteListeningVelocities = [];
                    }
                    if (component.noteListeningActivations > 0) {
                        // As we listen, assign all the heard notes to the heard notes thinger so we show things as we listen
                        component.heardNotes = component.noteListeningNotes;
                        component.heardVelocities = component.noteListeningVelocities;
                    }
                    if (component.noteListeningActivations === 0) {
                        // Now, if we're back down to zero, then we've had all the notes released, and we should clear our lists, ready for next go
                        component.noteListeningNotes = [];
                        component.noteListeningVelocities = [];
                    }
                } else if (175 < byte1 && byte1 < 192 && byte2 === 123) {
                    // console.log("Registering all-off, resetting to empty, bytes are", byte1, byte2, byte3);
                    component.noteListeningActivations = 0;
                    component.noteListeningNotes = [];
                    component.noteListeningVelocities = [];
                }
            }
        }
    }
    property int noteListeningActivations: 0
    property var noteListeningNotes: []
    property var noteListeningVelocities: []

    // Zynthian.SequenceLoader {
    //     id: sequenceLoader
    // }

    // Drum Grid Component
    Component {
        id: drumsGrid
        Item {
            id: drumsGridContainer
            anchors.margins: 5
            objectName: "drumsGrid"
            ColumnLayout {
                id:gridColumnLayout
                spacing: 0
                anchors.fill: parent;

                DrumsGrid {
                    id: drumsGridItem
                    // model: _private.activePatternModel ? (_private.activePatternModel.noteDestination === Zynthbox.PatternModel.SampleSlicedDestination ? _private.activePatternModel.clipSliceNotes : _private.activePatternModel.gridModel) : null
                    model: _private.activePatternModel ? _private.activePatternModel.gridModel : null
                    positionalVelocity: _private.positionalVelocity
                    showChosenPads: drumPad.channelIsLoopType === false
                    playgrid: component
                    onRemoveNote: {
                        zynqtgui.ignoreNextBackButtonPress = true;
                        if (_private.workingPatternModel) {
                            for (var row = _private.workingPatternModel.bankOffset; row < _private.workingPatternModel.bankOffset + _private.workingPatternModel.bankLength; ++row) {
                                for (var column = 0; column < _private.workingPatternModel.width; ++column) {
                                    var subNoteIndex = _private.workingPatternModel.subnoteIndex(row, column, note.midiNote);
                                    if (subNoteIndex > -1) {
                                        if (row == _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset && column == drumPadRepeater.selectedIndex) {
                                            var seqPad = drumPadRepeater.itemAt(column);
                                            if (seqPad.currentSubNote == subNoteIndex) {
                                                seqPad.currentSubNote = -1;
                                            }
                                        }
                                        _private.workingPatternModel.removeSubnote(row, column, subNoteIndex);
                                    }
                                }
                            }
                        }
                    }
                }

                // drum pad & sequencer
                Rectangle {
                    id:drumPad
                    property bool channelIsLoopType: _private.activePatternModel && _private.activePatternModel.noteDestination === Zynthbox.PatternModel.SampleLoopedDestination
                    Layout.fillWidth: true; 
                    Layout.minimumHeight: parent.height / 5; 
                    Layout.maximumHeight: parent.height / 5;
                    color:"transparent"
                    readonly property int parameterPageIndex: noteSettings.visible
                        ? noteSettings.currenParameterPageIndex
                        : 0
                    Connections {
                        target: _private
                        onGoLeft: drumPadRepeater.goPrevious();
                        onGoRight: drumPadRepeater.goNext();
                        onDeselectSelectedItem: drumPadRepeater.deselectSelectedItem();
                        onActivateSelectedItem: drumPadRepeater.activateSelectedItem();
                        onKnob0Up: {
                            if (component.showPatternSettings && noteSettingsPopup.visible === false) {
                                _private.stepLengthUp();
                            } else {
                                switch (drumPad.parameterPageIndex) {
                                    case 2:
                                        drumPadRepeater.ratchetStyleUp();
                                        break;
                                    case 1:
                                        drumPadRepeater.probabilityUp();
                                        break;
                                    case 0:
                                    default:
                                        drumPadRepeater.velocityUp();
                                        break;
                                }
                            }
                        }
                        onKnob0Down: {
                            if (component.showPatternSettings && noteSettingsPopup.visible === false) {
                                _private.stepLengthDown();
                            } else {
                                switch (drumPad.parameterPageIndex) {
                                    case 2:
                                        drumPadRepeater.ratchetStyleDown();
                                        break;
                                    case 1:
                                        drumPadRepeater.probabilityDown();
                                        break;
                                    case 0:
                                    default:
                                        drumPadRepeater.velocityDown();
                                        break;
                                }
                            }
                        }
                        onKnob1Up: {
                            if (component.showPatternSettings && noteSettingsPopup.visible === false) {
                                _private.swingUp();
                            } else {
                                switch (drumPad.parameterPageIndex) {
                                    case 2:
                                        drumPadRepeater.ratchetCountUp();
                                        break;
                                    case 1:
                                        // drumPadRepeater.
                                        break;
                                    case 0:
                                    default:
                                        drumPadRepeater.durationUp();
                                        break;
                                }
                            }
                        }
                        onKnob1Down: {
                            if (component.showPatternSettings && noteSettingsPopup.visible === false) {
                                _private.swingDown();
                            } else {
                                switch (drumPad.parameterPageIndex) {
                                    case 2:
                                        drumPadRepeater.ratchetCountDown();
                                        break;
                                    case 1:
                                        // drumPadRepeater.
                                        break;
                                    case 0:
                                    default:
                                        drumPadRepeater.durationDown();
                                        break;
                                }
                            }
                        }
                        onKnob2Up: {
                            if (component.showPatternSettings && noteSettingsPopup.visible === false) {
                                _private.patternLengthUp();
                            } else {
                                switch (drumPad.parameterPageIndex) {
                                    case 2:
                                        drumPadRepeater.ratchetProbabilityUp();
                                        break;
                                    case 1:
                                        drumPadRepeater.nextStepUp();
                                        break;
                                    case 0:
                                    default:
                                        drumPadRepeater.delayUp();
                                        break;
                                }
                            }
                        }
                        onKnob2Down: {
                            if (component.showPatternSettings && noteSettingsPopup.visible === false) {
                                _private.patternLengthDown();
                            } else {
                                switch (drumPad.parameterPageIndex) {
                                    case 2:
                                        drumPadRepeater.ratchetProbabilityDown();
                                        break;
                                    case 1:
                                        drumPadRepeater.nextStepDown();
                                        break;
                                    case 0:
                                    default:
                                        drumPadRepeater.delayDown();
                                        break;
                                }
                            }
                        }
                    }
                    Connections {
                        target: noteSettings
                        onChangeStep: {
                            var drumPadStartStep = ((_private.activeBar + _private.bankOffset) * drumPadRepeater.count);
                            if (newStep === -1) {
                                var seqPad = drumPadRepeater.itemAt(drumPadRepeater.selectedIndex);
                                if (seqPad && seqPad.currentSubNote > -1) {
                                    seqPad.currentSubNote = -1;
                                }
                                drumPadRepeater.selectedIndex = -1;
                            } else if (newStep >= drumPadStartStep && newStep < drumPadStartStep + drumPadRepeater.count) {
                                var seqPad = drumPadRepeater.itemAt(newStep - drumPadStartStep);
                                if (seqPad) {
                                    seqPad.setSelected(-1);
                                    Qt.callLater(drumPadRepeater.updateMostRecentFromSelection);
                                }
                            }
                        }
                        onChangeSubnote: {
                            var drumPadStartStep = ((_private.activeBar + _private.bankOffset) * drumPadRepeater.count);
                            var selectedStep = noteSettings.currentStep;
                            console.log("Subnote changed for selected step", selectedStep, "with drumpad start step", drumPadStartStep, "and new subnote", newSubNote);
                            if (selectedStep === -1 || (selectedStep >= drumPadStartStep && selectedStep < drumPadStartStep + drumPadRepeater.count)) {
                                var seqPad = drumPadRepeater.itemAt(selectedStep - drumPadStartStep);
                                if (seqPad) {
                                    seqPad.currentSubNote = newSubNote;
                                    Qt.callLater(drumPadRepeater.updateMostRecentFromSelection);
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        id: noteLengthVisualiser
                        function clearVisualisation() {
                            noteLengthVisualiser.note = null;
                            noteLengthVisualiser.lastLoopIndex = -1;
                        }
                        function visualiseNote(note, noteDuration, noteDelay, noteOffset) {
                            noteLengthVisualiser.singleStepLength =_private.workingPatternModel.stepLength;
                            noteLengthVisualiser.totalStepLength = noteDuration / noteLengthVisualiser.singleStepLength;
                            noteLengthVisualiser.lastLoopIndex = (noteLengthVisualiser.totalStepLength + noteOffset) / 16;
                            noteLengthVisualiser.noteDuration = noteDuration === 0 ? _private.workingPatternModel.stepLength : noteDuration;
                            noteLengthVisualiser.noteOffset = noteOffset;
                            noteLengthVisualiser.noteDelay = noteDelay;
                            if (noteDelay !== 0 && noteDuration === 0) {
                                // So we also visualise default-duration notes which have been moved around
                                noteLengthVisualiser.noteDuration = noteLengthVisualiser.singleStepLength;
                            }
                            if (note) {
                                noteLengthVisualiser.note = note;
                            } else {
                                noteLengthVisualiser.note = null;
                            }
                        }
                        property QtObject note: null
                        property int noteOffset: 0
                        property int noteDelay: 0
                        property int noteDuration: 0
                        property int lastLoopIndex: -1
                        property double totalStepLength: 0
                        property int singleStepLength: 0
                        property double dividedWidth: width / 16
                        anchors {
                            left: parent.left
                            leftMargin: 5
                            right: parent.right
                            rightMargin: 5
                            bottom: parent.top
                            bottomMargin: 1
                        }
                        height: drumsGridContainer.height
                        visible: note !== null
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        readonly property color focusColor: Kirigami.Theme.focusColor
                        spacing: 0
                        Item { Layout.fillHeight: true; Layout.fillWidth: true; }
                        Repeater {
                            model: 30
                            delegate: Item {
                                id: loopDelegate
                                Layout.fillWidth: true
                                Layout.minimumHeight: 3
                                property int loopIndex: 29 - model.index
                                Rectangle {
                                    anchors {
                                        left: parent.left
                                        leftMargin: loopDelegate.loopIndex === 0 ? 1 + noteLengthVisualiser.noteOffset * noteLengthVisualiser.dividedWidth + (noteLengthVisualiser.noteDelay / noteLengthVisualiser.singleStepLength * noteLengthVisualiser.dividedWidth) : 0
                                        verticalCenter: parent.verticalCenter
                                    }
                                    height: 2
                                    property int thisLoopOffset: loopDelegate.loopIndex === 0 ? noteLengthVisualiser.noteOffset : 0
                                    property double thisLoopDuration: {
                                        var thisDuration = 0;
                                        if (loopDelegate.loopIndex === 0) {
                                            // The first loop
                                            thisDuration = Math.min((noteLengthVisualiser.singleStepLength * 16) - (noteLengthVisualiser.noteOffset * noteLengthVisualiser.singleStepLength + noteLengthVisualiser.noteDelay), noteLengthVisualiser.noteDuration);
                                        } else if (loopDelegate.loopIndex === noteLengthVisualiser.lastLoopIndex) {
                                            // The last loop
                                            var firstLoopDuration = Math.min((noteLengthVisualiser.singleStepLength * 16) - (noteLengthVisualiser.noteOffset * noteLengthVisualiser.singleStepLength + noteLengthVisualiser.noteDelay), noteLengthVisualiser.noteDuration);
                                            thisDuration = (noteLengthVisualiser.noteDuration - firstLoopDuration) % (16 * noteLengthVisualiser.singleStepLength);
                                        } else if (loopDelegate.loopIndex < noteLengthVisualiser.lastLoopIndex) {
                                            // All the loops between the first and last (they're just full width)
                                            thisDuration = noteLengthVisualiser.singleStepLength * 16
                                        }
                                        return thisDuration;
                                    }
                                    width: thisLoopDuration * noteLengthVisualiser.dividedWidth / noteLengthVisualiser.singleStepLength;
                                    color: noteLengthVisualiser.focusColor
                                    Rectangle {
                                        anchors {
                                            top: parent.bottom
                                            left: parent.left
                                        }
                                        width: 2
                                        height: 4
                                        color: parent.color
                                        visible: parent.width > 0 && loopDelegate.loopIndex === 0
                                    }
                                    Rectangle {
                                        anchors {
                                            verticalCenter: parent.verticalCenter
                                            right: parent.right
                                        }
                                        width: 2
                                        height: 4
                                        color: parent.color
                                        visible: parent.width > 0 && loopDelegate.loopIndex === noteLengthVisualiser.lastLoopIndex
                                    }
                                }
                            }
                        }
                    }
                    Item {
                        id: drumpadLoopVisualiser
                        anchors.fill:parent
                        anchors.margins: 5
                        visible: parent.visible && drumPad.channelIsLoopType
                        property QtObject channel: null
                        Binding {
                            target: drumpadLoopVisualiser
                            property: "channel"
                            value: zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId)
                            when: drumpadLoopVisualiser.visible
                            delayed: true
                            restoreMode: Binding.RestoreBinding
                        }
                        property QtObject sample: channel ? channel.getClipsModelById(channel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex) : null
                        Zynthian.SampleVisualiser {
                            anchors.fill: parent
                            sample: parent.visible ? drumpadLoopVisualiser.sample : null
                            trackType: drumpadLoopVisualiser.channel === null ? "" : drumpadLoopVisualiser.channel.trackType
                        }
                    }
                    RowLayout {
                        anchors.fill:parent
                        anchors.margins: 5
                        spacing: 0
                        visible: !drumPad.channelIsLoopType
                        Repeater {
                            id:drumPadRepeater
                            model: _private.activeBarModelWidth
                            property int selectedIndex: -1
                            onSelectedIndexChanged: {
                                _private.hasSelection = (drumPadRepeater.selectedIndex > -1);
                                _private.selectedStep = drumPadRepeater.selectedIndex;
                            }
                            function updateMostRecentFromSelection() {
                                var seqPad = drumPadRepeater.itemAt(selectedIndex);
                                var note = _private.workingPatternModel.getNote(_private.activeBar + _private.bankOffset, selectedIndex);
                                if (note) {
                                    var stepNotes = [];
                                    var stepVelocities = [];
                                    if (seqPad && seqPad.currentSubNote > -1) {
                                        if (note && seqPad.currentSubNote < note.subnotes.length) {
                                            stepVelocities.push(_private.workingPatternModel.subnoteMetadata(_private.activeBar + _private.bankOffset, selectedIndex, seqPad.currentSubNote, "velocity"));
                                            stepNotes.push(note.subnotes[seqPad.currentSubNote]);
                                        }
                                    } else if (note) {
                                        for (var i = 0; i < note.subnotes.length; ++i) {
                                            stepVelocities.push(_private.workingPatternModel.subnoteMetadata(_private.activeBar + _private.bankOffset, selectedIndex, i, "velocity"));
                                            stepNotes.push(note.subnotes[i]);
                                        }
                                    }
                                    component.heardNotes = stepNotes;
                                    component.heardVelocities = stepVelocities;
                                    if (noteSettings.visible) {
                                        noteSettings.currentSubNote = seqPad ? seqPad.currentSubNote : -1;
                                    }
                                    if (seqPad && seqPad.currentSubNote > -1) {
                                        var noteLength = _private.workingPatternModel.subnoteMetadata(_private.activeBar + _private.bankOffset, selectedIndex, seqPad.currentSubNote, "duration");
                                        if (!noteLength) {
                                            noteLength = 0;
                                        }
                                        var noteDelay = _private.workingPatternModel.subnoteMetadata(_private.activeBar + _private.bankOffset, selectedIndex, seqPad.currentSubNote, "delay");
                                        if (!noteDelay) {
                                            noteDelay = 0;
                                        }
                                        noteLengthVisualiser.visualiseNote(note.subnotes[seqPad.currentSubNote], noteLength, noteDelay, selectedIndex % 16);
                                    } else {
                                        noteLengthVisualiser.clearVisualisation();
                                    }
                                } else {
                                    noteLengthVisualiser.clearVisualisation();
                                    Qt.callLater(updateMostRecentFromSelection);
                                }
                            }
                            function goNext() {
                                if (!noteSettings.visible) {
                                    var changeStep = true;
                                    if (selectedIndex > -1) {
                                        var seqPad = drumPadRepeater.itemAt(selectedIndex);
                                        if (seqPad.currentSubNote < seqPad.subNoteCount - 1) {
                                            seqPad.currentSubNote = seqPad.currentSubNote + 1;
                                            changeStep = false;
                                        } else {
                                            seqPad.currentSubNote = -1;
                                        }
                                    }
                                    if (changeStep) {
                                        if (selectedIndex < _private.activeBarModelWidth - 1) {
                                            selectedIndex = selectedIndex + 1;
                                        } else {
                                            // go next bar and reset - don't loop to the start, just block at the end
                                            if (_private.sequence.activePatternObject.activeBar < _private.sequence.activePatternObject.availableBars - 1) {
                                                _private.nextBar();
                                                selectedIndex = 0;
                                            }
                                        }
                                    }
                                    Qt.callLater(updateMostRecentFromSelection);
                                }
                            }
                            function goPrevious() {
                                if (!noteSettings.visible) {
                                    var changeStep = true;
                                    if (selectedIndex > -1) {
                                        var seqPad = drumPadRepeater.itemAt(selectedIndex);
                                        if (seqPad.currentSubNote > -1) {
                                            seqPad.currentSubNote = seqPad.currentSubNote - 1;
                                            if (seqPad.currentSubNote > -1) {
                                                changeStep = false;
                                            }
                                        } else if (seqPad.subNoteCount > 0 && seqPad.currentSubNote === -1) {
                                            seqPad.currentSubNote = seqPad.subNoteCount - 1;
                                            changeStep = false;
                                        }
                                    }
                                    if (changeStep) {
                                        if (selectedIndex > 0) {
                                            selectedIndex = selectedIndex - 1;
                                        } else {
                                            if (_private.sequence.activePatternObject.activeBar == 0) {
                                                // if first bar, reset to no selection
                                                selectedIndex = -1;
                                            } else {
                                                // otherwise go to the last step of the previous bar
                                                _private.previousBar();
                                                selectedIndex = _private.activeBarModelWidth - 1;
                                            }
                                        }
                                    }
                                    Qt.callLater(updateMostRecentFromSelection);
                                }
                            }
                            function deselectSelectedItem() {
                                if (noteSettingsPopup.visible) {
                                    noteSettingsPopup.close();
                                } else if (drumPadRepeater.selectedIndex > -1) {
                                    var seqPad = drumPadRepeater.itemAt(selectedIndex);
                                    if (seqPad.currentSubNote > -1) {
                                        seqPad.currentSubNote = -1;
                                    } else {
                                        drumPadRepeater.selectedIndex = -1;
                                    }
                                }
                                Qt.callLater(updateMostRecentFromSelection);
                            }
                            function activateSelectedItem() {
                                if (noteSettingsPopup.visible) {
                                    // do something? or no? probably no
                                } else {
                                    var seqPad = drumPadRepeater.itemAt(selectedIndex);
                                    if (seqPad) {
                                        if (seqPad.currentSubNote === -1) {
                                            // Then we're handling the position itself
                                            // console.log("Activating position", selectedIndex, "on bar", _private.activeBar);
                                            noteSettingsPopup.showSettings(_private.workingPatternModel, _private.activeBar + _private.bankOffset, _private.activeBar + _private.bankOffset, [], selectedIndex, selectedIndex);
                                        } else {
                                            // Then we're handling the specific subnote
                                            // console.log("Activating subnote", seqPad.currentSubNote, "on position", selectedIndex, "on bar", _private.activeBar);
                                            noteSettingsPopup.showSettings(_private.workingPatternModel, _private.activeBar + _private.bankOffset, _private.activeBar + _private.bankOffset, [], selectedIndex, selectedIndex);
                                        }
                                    } else {
                                        let filter = []
                                        if (component.heardNotes.length > 0) {
                                            for (var i = 0; i < component.heardNotes.length; ++i) {
                                                filter.push(component.heardNotes[i].midiNote);
                                            }
                                        }
                                        component.showNoteSettingsPopup(_private.workingPatternModel, _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset, _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset, filter, -1, -1);
                                    }
                                }
                            }
                            function changeStepValue(barIndex, stepIndex, indicesToChange, valueName, howMuch, minValue, maxValue, defaultValue) {
                                for (var i = 0; i < indicesToChange.length; ++i) {
                                    var currentValue = _private.workingPatternModel.subnoteMetadata(barIndex, stepIndex, indicesToChange[i], valueName);
                                    if (currentValue === undefined || currentValue === 0 || isNaN(currentValue)) {
                                        currentValue = defaultValue;
                                    }
                                    //console.log("Current", valueName, currentValue);
                                    if (currentValue + howMuch >= minValue && currentValue + howMuch <= maxValue) {
                                        _private.workingPatternModel.setSubnoteMetadata(barIndex, stepIndex, indicesToChange[i], valueName, currentValue + howMuch);
                                    }
                                }
                            }
                            function changeValue(valueName, howMuch, minValue, maxValue, defaultValue) {
                                if (drumPadRepeater.selectedIndex > -1) {
                                    var seqPad = drumPadRepeater.itemAt(selectedIndex);
                                    var indicesToChange = []
                                    if (seqPad.note && seqPad.currentSubNote === -1) {
                                        for (var i = 0; i < seqPad.note.subnotes.length; ++i) {
                                            indicesToChange.push(i);
                                        }
                                    } else {
                                        indicesToChange.push(seqPad.currentSubNote);
                                    }
                                    changeStepValue(_private.activeBar + _private.bankOffset, drumPadRepeater.selectedIndex, indicesToChange, valueName, howMuch, minValue, maxValue, defaultValue);
                                    if (seqPad.note && seqPad.currentSubNote > -1) {
                                        var noteLength = _private.workingPatternModel.subnoteMetadata(_private.activeBar + _private.bankOffset, drumPadRepeater.selectedIndex, seqPad.currentSubNote, "duration");
                                        if (!noteLength) {
                                            noteLength = 0;
                                        }
                                        var noteDelay = _private.workingPatternModel.subnoteMetadata(_private.activeBar + _private.bankOffset, drumPadRepeater.selectedIndex, seqPad.currentSubNote, "delay");
                                        if (!noteDelay) {
                                            noteDelay = 0;
                                        }
                                        noteLengthVisualiser.visualiseNote(seqPad.note.subnotes[seqPad.currentSubNote], noteLength, noteDelay, drumPadRepeater.selectedIndex % 16);
                                    }
                                } else if (noteSettings.visible) {
                                    // Only do the "change all the things" if note settings is visible... could otherwise, but confusion...
                                    if (noteSettings.currentIndex === -1) {
                                        for (let entryIndex = 0; entryIndex < noteSettings.listData.length; ++entryIndex) {
                                            let listEntry = noteSettings.listData[entryIndex];
                                            changeStepValue(listEntry["barIndex"], listEntry["stepIndex"], [listEntry["subnoteIndex"]], valueName, howMuch, minValue, maxValue, defaultValue);
                                        }
                                    } else {
                                        let listEntry = noteSettings.listData[noteSettings.currentIndex];
                                        changeStepValue(listEntry["barIndex"], listEntry["stepIndex"], [listEntry["subnoteIndex"]], valueName, howMuch, minValue, maxValue, defaultValue);
                                    }
                                }
                            }
                            function velocityUp() {
                                changeValue("velocity", 1, -1, 127, 0);
                            }
                            function velocityDown() {
                                changeValue("velocity", -1, -1, 127, 0);
                            }
                            // TODO Default value should probably be the current note duration... get that from PatternModel (which need it exposed)
                            function durationUp() {
                                changeValue("duration", 1, 0, 1024, 0);
                            }
                            function durationDown() {
                                changeValue("duration", -1, 0, 1024, 0);
                            }
                            function delayUp() {
                                if (noteSettings.visible) {
                                    changeValue("delay", 1, - noteSettings.stepDuration + 1, noteSettings.stepDuration - 1, 0);
                                } else {
                                    var seqPad = drumPadRepeater.itemAt(drumPadRepeater.selectedIndex);
                                    if (seqPad && seqPad.note && seqPad.currentSubNote > -1) {
                                        var stepDuration = _private.workingPatternModel.stepLength;
                                        changeValue("delay", 1, -stepDuration + 1, stepDuration - 1, 0);
                                    }
                                }
                            }
                            function delayDown() {
                                if (noteSettings.visible) {
                                    changeValue("delay", -1, - noteSettings.stepDuration + 1, noteSettings.stepDuration - 1, 0);
                                } else {
                                    var seqPad = drumPadRepeater.itemAt(drumPadRepeater.selectedIndex);
                                    if (seqPad && seqPad.note && seqPad.currentSubNote > -1) {
                                        var stepDuration = _private.workingPatternModel.stepLength;
                                        changeValue("delay", -1, -stepDuration + 1, stepDuration - 1, 0);
                                    }
                                }
                            }
                            function probabilityUp() {
                                changeValue("probability", 1, 0, 45, 0);
                            }
                            function probabilityDown() {
                                changeValue("probability", -1, 0, 45, 0);
                            }
                            function nextStepUp() {
                                changeValue("next-step", 1, 0, 128, 0);
                            }
                            function nextStepDown() {
                                changeValue("next-step", -1, 0, 128, 0);
                            }
                            function ratchetStyleUp() {
                                changeValue("ratchet-style", 1, 0, 3, 0);
                            }
                            function ratchetStyleDown() {
                                changeValue("ratchet-style", -1, 0, 3, 0);
                            }
                            function ratchetCountUp() {
                                changeValue("ratchet-count", 1, 0, 12, 0);
                            }
                            function ratchetCountDown() {
                                changeValue("ratchet-count", -1, 0, 12, 0);
                            }
                            function ratchetProbabilityUp() {
                                changeValue("ratchet-probability", 1, 0, 100, 100);
                            }
                            function ratchetProbabilityDown() {
                                changeValue("ratchet-probability", -1, 0, 100, 100);
                            }
                            PadNoteButton {
                                id: sequencerPad
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                Layout.rightMargin: 5
                                // The indicator rect is 9 px tall, spaced by 1px, and we've got 5px margin, and so
                                // if we want 11px space between the bottom of this and the settings, 6px it is (which
                                // there's no reason to do arithmetics for, it's a fixed value anyway, but that's where
                                // this particular magic number comes from)
                                Layout.bottomMargin: component.showPatternSettings ? 6 : 0
                                playgrid: component
                                patternModel: _private.workingPatternModel
                                activeBar:_private.activeBar
                                padNoteIndex: model.index
                                padNoteNumber: ((_private.activeBar + _private.bankOffset) * drumPadRepeater.count) + padNoteIndex
                                opacity: padNoteNumber < _private.workingPatternModel.patternLength ? 1 : 0.3
                                enabled: opacity === 1
                                note: visible && _private.workingPatternModel ? _private.workingPatternModel.getNote(_private.activeBar + _private.bankOffset, model.index) : null
                                isCurrent: visible && model.index == drumPadRepeater.selectedIndex
                                function setSelected(subNoteIndex) {
                                    if (drumPadRepeater.selectedIndex > -1) {
                                        var seqPad = drumPadRepeater.itemAt(drumPadRepeater.selectedIndex);
                                        seqPad.currentSubNote = -1;
                                    }
                                    drumPadRepeater.selectedIndex = model.index;
                                    sequencerPad.currentSubNote = subNoteIndex;
                                    drumPadRepeater.updateMostRecentFromSelection();
                                }
                                onTapped: {
                                    setSelected(subNoteIndex);
                                }
                                onPressAndHold: {
                                    setSelected(subNoteIndex);
                                    noteSettingsPopup.showSettings(_private.workingPatternModel, _private.activeBar + _private.bankOffset, _private.activeBar + _private.bankOffset, [], model.index, model.index);
                                }
                                onCurrentSubNoteChanged: {
                                    if (drumPadRepeater.selectedIndex != model.index) {
                                        if (drumPadRepeater.selectedIndex > -1) {
                                            var seqPad = drumPadRepeater.itemAt(drumPadRepeater.selectedIndex);
                                            seqPad.currentSubNote = -1;
                                        }
                                        drumPadRepeater.selectedIndex = model.index;
                                    }
                                }
                                property bool doUpdate: false
                                function updatePadNote() {
                                    sequencerPad.note = null;
                                    if (_private.workingPatternModel) {
                                        sequencerPad.note = _private.workingPatternModel.getNote(_private.activeBar + _private.bankOffset, model.index);
                                        _private.updateChannel();
                                        sequencerPad.doUpdate = false;
                                    } else {
                                        sequencerPad.doUpdate = true;
                                        sequencerPadNoteApplicator.restart();
                                    }
                                }
                                Timer {
                                    id: sequencerPadNoteApplicator
                                    repeat: false; running: false; interval: 1
                                    onTriggered: {
                                        if (component.isVisible) {
                                            sequencerPad.updatePadNote();
                                        } else {
                                            sequencerPad.doUpdate = true;
                                        }
                                    }
                                }
                                onVisibleChanged: {
                                    if (doUpdate) {
                                        sequencerPad.updatePadNote();
                                        sequencerPad.doUpdate = false;
                                    }
                                }
                                Connections {
                                    target: component
                                    onIsVisibleChanged: {
                                        if (component.isVisible) {
                                            sequencerPad.doUpdate = true;
                                            sequencerPadNoteApplicator.restart();
                                        }
                                    }
                                }
                                Connections {
                                    target: _private
                                    onSequenceChanged: sequencerPadNoteApplicator.restart();
                                    onActivePatternModelChanged: sequencerPadNoteApplicator.restart();
                                    onActiveBarChanged: sequencerPadNoteApplicator.restart();
                                    onBankOffsetChanged: sequencerPadNoteApplicator.restart();
                                }
                                Connections {
                                    target: _private.sequence
                                    onModelReset: sequencerPadNoteApplicator.restart();
                                }
                                Connections {
                                    target: _private.activePatternModel
                                    onLastModifiedChanged: sequencerPadNoteApplicator.restart();
                                }
                                Connections {
                                    target: Zynthbox.PlayGridManager
                                    onCurrentSketchpadTrackChanged: sequencerPadNoteApplicator.restart();
                                }
                                Connections {
                                    target: zynqtgui.sketchpad
                                    onSongChanged: sequencerPadNoteApplicator.restart();
                                }
                            }
                        }
                    }
                    Item {
                        id: nudgeOverlay
                        anchors.fill: parent
                        visible: component.nudgeOverlayEnabled
                        MultiPointTouchArea {
                            anchors.fill: parent
                            touchPoints: [
                                TouchPoint {
                                    id: nudgeTouchPoint
                                    property int nudgeInterval: _private.workingPatternModel ? nudgeOverlay.width / _private.workingPatternModel.width : nudgeOverlay.width
                                    property var mostRecentNudgePosition: undefined
                                    onPressedChanged: {
                                        if (pressed) {
                                            if (component.nudgePerformed === false) {
                                                component.nudgePerformed = true;
                                                _private.activePatternModel.startPerformance();
                                            }
                                            nudgeTouchPoint.mostRecentNudgePosition = nudgeTouchPoint.startX;
                                        } else {
                                            nudgeTouchPoint.mostRecentNudgePosition = undefined;
                                        }
                                    }
                                    onYChanged: {
                                        if (pressed && nudgeTouchPoint.mostRecentNudgePosition !== undefined) {
                                            var delta = nudgeTouchPoint.x - nudgeTouchPoint.mostRecentNudgePosition;
                                            if (Math.abs(delta) > nudgeInterval) {
                                                nudgeTouchPoint.mostRecentNudgePosition = nudgeTouchPoint.x;
                                                let nudgeAmount = -1;
                                                if (delta > 0) {
                                                    nudgeAmount = 1;
                                                }
                                                let firstStep = (_private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset) * _private.workingPatternModel.width;
                                                let lastStep = Math.min(firstStep + _private.workingPatternModel.width, (_private.workingPatternModel.bankOffset * _private.workingPatternModel.width) + _private.workingPatternModel.patternLength) - 1;
                                                if (zynqtgui.altButtonPressed) {
                                                    firstStep = _private.workingPatternModel.bankOffset * _private.workingPatternModel.width;
                                                    lastStep = _private.workingPatternModel.patternLength - 1;
                                                }
                                                _private.workingPatternModel.nudge(firstStep, lastStep, nudgeAmount, component.heardNotes);
                                            }
                                        }
                                    }
                                }
                            ]
                        }
                    }
                }

                // pad & sequencer settings
                Rectangle {
                    id:padSettings
                    Layout.fillWidth: true; 
                    Layout.minimumHeight: parent.height / 5; 
                    Layout.maximumHeight: parent.height / 5;
                    visible: component.showPatternSettings
                    color:"transparent"
                    RowLayout {
                        anchors.fill:parent

                        // controls
                        Rectangle {
                            id:padSettingsControls
                            Layout.preferredWidth: parent.width / 2
                            Layout.fillHeight: true
                            color:"transparent"

                            RowLayout {
                                anchors.fill: parent

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: parent.width / 5
                                    Layout.maximumWidth: Layout.minimumWidth
                                    Zynthian.PlayGridButton {
                                        text: "+"
                                        enabled: _private.workingPatternModel && _private.workingPatternModel.stepLength < _private.workingPatternModel.nextStepLengthStep(_private.workingPatternModel.stepLength, 1)
                                        onClicked: {
                                            _private.stepLengthUp();
                                        }
                                    }
                                    QQC2.Label {
                                        id:noteLengthLabel
                                        Layout.alignment: Qt.AlignHCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "step length:\n%1".arg(_private.workingPatternModel.stepLengthName(_private.stepLength))
                                    }

                                    Zynthian.PlayGridButton {
                                        text:"-"
                                        enabled: _private.workingPatternModel && _private.workingPatternModel.stepLength > _private.workingPatternModel.nextStepLengthStep(_private.workingPatternModel.stepLength, -1)
                                        onClicked: {
                                            _private.stepLengthDown();
                                        }
                                        Zynthian.KnobIndicator {
                                            anchors {
                                                left: parent.left
                                                bottom: parent.top
                                                margins: 2
                                            }
                                            height: parent.height * 0.7
                                            width: height
                                            knobId: 0
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: parent.width / 5
                                    Layout.maximumWidth: Layout.minimumWidth
                                    Zynthian.PlayGridButton {
                                        text: "+"
                                        enabled: _private.swing < 99
                                        onClicked: {
                                            _private.swingUp();
                                        }
                                    }
                                    QQC2.Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.preferredHeight: noteLengthLabel.height
                                        text: "swing:\n" + (_private.swing === 50 ? "none" : _private.swing)
                                        MultiPointTouchArea {
                                            anchors.fill: parent
                                            touchPoints: [
                                                TouchPoint {
                                                    id: swingSlidePoint;
                                                    property double increment: 1
                                                    property double slideIncrement: 0.2
                                                    property double upperBound: 99
                                                    property double lowerBound: 1
                                                    property int resetValue: 50
                                                    property var currentValue: undefined
                                                    property var pressedTime: undefined
                                                    onPressedChanged: {
                                                        if (pressed) {
                                                            pressedTime = Date.now();
                                                            currentValue = _private.swing;
                                                        } else {
                                                            // Only reset if we are asked to, have no meaningful changes to the value, and the timing was reasonably
                                                            // a tap (arbitrary number here, should be a global constant somewhere we can use for this)
                                                            if (Math.abs(_private.swing - currentValue) < swingSlidePoint.increment && (Date.now() - pressedTime) < 300) {
                                                                _private.sequence.setPatternProperty(_private.activePattern, "swing", swingSlidePoint.resetValue)
                                                            }
                                                            currentValue = undefined;
                                                        }
                                                    }
                                                    onYChanged: {
                                                        if (pressed && currentValue !== undefined) {
                                                            var delta = -(swingSlidePoint.y - swingSlidePoint.startY) * swingSlidePoint.slideIncrement;
                                                            _private.sequence.setPatternProperty(_private.activePattern, "swing", Math.min(Math.max(currentValue + delta, swingSlidePoint.lowerBound), swingSlidePoint.upperBound))
                                                        }
                                                    }
                                                }
                                            ]
                                        }
                                    }

                                    Zynthian.PlayGridButton {
                                        text:"-"
                                        enabled: _private.swing > 0
                                        onClicked: {
                                            _private.swingDown();
                                        }
                                        Zynthian.KnobIndicator {
                                            anchors {
                                                left: parent.left
                                                bottom: parent.top
                                                margins: 2
                                            }
                                            height: parent.height * 0.7
                                            width: height
                                            knobId: 1
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: parent.width / 5
                                    Layout.maximumWidth: Layout.minimumWidth
                                    Zynthian.PlayGridButton {
                                        text: "+"
                                        enabled: _private.workingPatternModel && _private.workingPatternModel.patternLength < (_private.workingPatternModel.bankLength * _private.workingPatternModel.width)
                                        onClicked: {
                                            _private.patternLengthUp();
                                        }
                                    }
                                    QQC2.Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredHeight: noteLengthLabel.height
                                        text: _private.workingPatternModel.availableBars * _private.workingPatternModel.width === _private.workingPatternModel.patternLength
                                            ? _private.workingPatternModel.availableBars + " Bars"
                                            : "%1.%2 Bars".arg(_private.workingPatternModel.availableBars - 1).arg(_private.workingPatternModel.patternLength - ((_private.workingPatternModel.availableBars - 1) * _private.workingPatternModel.width))
                                        MultiPointTouchArea {
                                            anchors.fill: parent
                                            touchPoints: [
                                                TouchPoint {
                                                    id: patternLengthSlidePoint;
                                                    property double increment: 1
                                                    property double slideIncrement: 0.2
                                                    property double upperBound: _private.workingPatternModel.bankLength * _private.workingPatternModel.width
                                                    property double lowerBound: 1
                                                    property var currentValue: undefined
                                                    onPressedChanged: {
                                                        if (pressed) {
                                                            currentValue = _private.workingPatternModel.patternLength;
                                                        }
                                                    }
                                                    onYChanged: {
                                                        if (pressed && currentValue !== undefined) {
                                                            var delta = -(patternLengthSlidePoint.y - patternLengthSlidePoint.startY) * patternLengthSlidePoint.slideIncrement;
                                                            _private.sequence.setPatternProperty(_private.activePattern, "patternLength", Math.min(Math.max(currentValue + delta, patternLengthSlidePoint.lowerBound), patternLengthSlidePoint.upperBound))
                                                        }
                                                    }
                                                }
                                            ]
                                        }
                                    }

                                    Zynthian.PlayGridButton {
                                        text:"-"
                                        enabled: _private.workingPatternModel && _private.workingPatternModel.patternLength > _private.workingPatternModel.width
                                        onClicked: {
                                            _private.patternLengthDown();
                                        }
                                        Zynthian.KnobIndicator {
                                            anchors {
                                                left: parent.left
                                                bottom: parent.top
                                                margins: 2
                                            }
                                            height: parent.height * 0.7
                                            width: height
                                            knobId: 2
                                        }
                                    }
                                }

                                Zynthian.PlayGridButton {
                                    Layout.fillWidth: true
                                    text: "copy\n"
                                    onClicked: {
                                        _private.copyRange(
                                            (_private.activePattern + 1) + " " + _private.sceneName + "/" + (_private.activeBar + 1),
                                            _private.activeBarModel.parentModel,
                                            _private.activeBar + _private.bankOffset,
                                            _private.activeBar + _private.bankOffset
                                        );
                                    }
                                }

                                Zynthian.PlayGridButton {
                                    Layout.fillWidth: true
                                    text: "paste\n" + (_private.clipBoard && _private.clipBoard.description !== "" ? _private.clipBoard.description : "")
                                    enabled: _private.clipBoard !== undefined
                                    onClicked: {
                                        _private.pasteInPlace(_private.activeBarModel.parentModel, _private.activeBar + _private.bankOffset, _private.activeBar + _private.bankOffset);
                                    }
                                }

                                Zynthian.PlayGridButton {
                                    Layout.fillWidth: true
                                    text: "clear\n"
                                    onClicked: {
                                        _private.activeBarModel.parentModel.clearRow(_private.activeBar + _private.bankOffset);
                                    }
                                }

                                //ColumnLayout {
                                    //Layout.fillHeight: true
                                    //Zynthian.PlayGridButton {
                                        //text: "bank I"
                                        //checked: _private.bankOffset === 0
                                        //onClicked: {
                                            //_private.sequence.setPatternProperty(_private.activePattern, "bankOffset", 0)
                                        //}
                                    //}
                                    //Zynthian.PlayGridButton {
                                        //text: "bank II"
                                        //checked: _private.bankOffset === 8
                                        //onClicked: {
                                            //_private.sequence.setPatternProperty(_private.activePattern, "bankOffset", 8)
                                        //}
                                    //}
                                //}
                            }
                        }

                        Item {
                            Layout.preferredWidth: parent.width / 2
                            Layout.fillHeight: true
                            Image {
                                id: patternBarsVisualiser
                                visible: !patternBarsLayout.channelIsLoopType
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.verticalCenter
                                    bottomMargin: Kirigami.Units.largeSpacing
                                }
                                source: _private.activePatternModel ? _private.activePatternModel.thumbnailUrl : ""
                                asynchronous: true
                                Rectangle {
                                    anchors {
                                        top: parent.top
                                        bottom: parent.bottom
                                    }
                                    visible: parent.visible && _private.activePatternModel ? _private.activePatternModel.isPlaying : false
                                    color: Kirigami.Theme.highlightColor
                                    width: Math.max(1, Math.floor(widthFactor))
                                    property double widthFactor: visible && _private.activePatternModel ? parent.width / (_private.activePatternModel.width * _private.activePatternModel.bankLength) : 1
                                    x: visible && _private.activePatternModel ? _private.activePatternModel.bankPlaybackPosition * widthFactor : 0
                                }
                            }
                            RowLayout {
                                id: patternBarsLayout
                                anchors {
                                    top: parent.verticalCenter
                                    topMargin: -Kirigami.Units.largeSpacing
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                property bool channelIsLoopType: _private.activePatternModel && _private.activePatternModel.noteDestination === Zynthbox.PatternModel.SampleLoopedDestination
                                Item {
                                    visible: padSettings.visible && patternBarsLayout.channelIsLoopType
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }
                                Repeater {
                                    model: patternBarsLayout.channelIsLoopType ? 0 : _private.bars
                                    delegate: BarStep {
                                        availableBars: _private.availableBars
                                        activeBar: _private.activeBar
                                        playedBar: visible && _private.activePatternModel ? _private.activePatternModel.playingRow - _private.workingPatternModel.bankOffset : 0
                                        playgrid: component
                                    }
                                }
                            }
                            MultiPointTouchArea {
                                anchors.fill: parent
                                touchPoints: [
                                    TouchPoint {
                                        id: patternsBarTouchPoint
                                        onPressedChanged: {
                                            if (patternsBarTouchPoint.pressed) {
                                                let barStepIndex = _private.activePatternModel.bankLength * (startX / patternBarsVisualiser.width);
                                                if (barStepIndex < _private.availableBars) {
                                                    _private.activePatternModel.activeBar = barStepIndex;
                                                }
                                            }
                                        }
                                        onXChanged: {
                                            let barStepIndex = _private.activePatternModel.bankLength * (x / patternBarsVisualiser.width);
                                            if (barStepIndex < _private.availableBars) {
                                                _private.activePatternModel.activeBar = barStepIndex;
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }
            }
            Zynthian.Popup {
                id: patternMenuPopup
                y: Kirigami.Units.largeSpacing
                x: -Kirigami.Units.largeSpacing * 2
                width: drumsGridContainer.width - Kirigami.Units.largeSpacing * 2
                height: drumsGridContainer.height - Kirigami.Units.largeSpacing * 3
                property var cuiaCallback: function(cuia) {
                    // We're not handling any of the interaction in here
                    var result = false;
                    return result;
                }
                Connections {
                    target: component
                    onShowPatternsMenu: {
                        patternMenuPopup.open();
                    }
                    onHidePatternsMenu: {
                        patternMenuPopup.close();
                    }
                    onIsVisibleChanged: {
                        if (patternMenuPopup.opened && component.isVisible === false) {
                            patternMenuPopup.close();
                        }
                    }
                }
                Binding {
                    target: component
                    property: "patternsMenuVisible"
                    value: patternMenuPopup.opened
                }
                Item {
                    id: patternsMenu
                    anchors.fill: parent;
                    Zynthian.Card {
                        anchors.fill: parent
                    }
                    Column {
                        anchors {
                            fill: parent
                            margins: Kirigami.Units.smallSpacing
                        }
                        spacing: Kirigami.Units.smallSpacing
                        QQC2.ScrollView {
                            id: patternsMenuList
                            width: parent.width
                            height: parent.height - (Kirigami.Units.gridUnit * 2) - Kirigami.Units.smallSpacing
                            QQC2.ScrollBar.horizontal.visible: false
                            QQC2.ScrollBar.vertical.x: patternsMenuListView.x + patternsMenuListView.width  - QQC2.ScrollBar.vertical.width// - root.rightPadding
                            contentItem: ListView {
                                id: patternsMenuListView
                                clip: true
                                cacheBuffer: height * 2 // a little brutish, but it means all our delegates always exist, which is what we're actually after here
                                model: Zynthbox.Plugin.sketchpadTrackCount
                                Connections {
                                    target: _private
                                    onActivePatternModelChanged: {
                                        patternsMenuRepositioner.restart();
                                    }
                                }
                                Connections {
                                    target: patternMenuPopup
                                    onOpenedChanged: {
                                        if (patternMenuPopup.opened) {
                                            patternsMenuRepositioner.restart();
                                        }
                                    }
                                }
                                Timer {
                                    id: patternsMenuRepositioner
                                    interval: 1; running: false; repeat: false;
                                    onTriggered: {
                                        if (_private.activePatternModel) {
                                            patternsMenuListView.positionViewAtIndex(5 * Math.floor(_private.activePatternModel.sketchpadTrack / Zynthbox.Plugin.sketchpadSlotCount), ListView.Beginning);
                                        }
                                    }
                                }

                                delegate: Rectangle {
                                    id: patternsMenuItem
                                    property QtObject thisPattern: _private.sequence && associatedChannel ? _private.sequence.getByClipId(model.index, associatedChannel.selectedClip) : null
                                    property int thisPatternIndex: _private.sequence ? _private.sequence.indexOf(thisPattern) : -1
                                    property int activePattern: _private.activePattern
                                    property QtObject channelClipsModel: associatedChannel == null ? null : associatedChannel.clipsModel
                                    property QtObject associatedChannel: zynqtgui.sketchpad.song && zynqtgui.sketchpad.song.channelsModel ? zynqtgui.sketchpad.song.channelsModel.getChannel(model.index) : null
                                    property int associatedChannelIndex: model.index
                                    height: ListView.view.height * 0.2
                                    width: ListView.view.width - patternsMenuList.QQC2.ScrollBar.vertical.width - Kirigami.Units.smallSpacing
                                    Kirigami.Theme.inherit: false
                                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                    color: _private.activePatternModel && _private.activePatternModel.sketchpadTrack === index ? Kirigami.Theme.focusColor : Kirigami.Theme.backgroundColor
                                    border.color: Kirigami.Theme.textColor
                                    function pickThisPattern() {
                                        component.pickPattern(patternsMenuItem.thisPatternIndex)
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: patternsMenuItem.pickThisPattern();
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 5
                                            spacing: 5

                                            ColumnLayout {
                                                Layout.fillHeight: true
                                                Layout.minimumWidth: height
                                                Layout.maximumWidth: height
                                                Zynthian.PlayGridButton {
                                                    Layout.fillHeight: true
                                                    Layout.fillWidth: true
                                                    Layout.margins: Kirigami.Units.largeSpacing
                                                    text: qsTr("Solo")
                                                    checked: _private.sequence && _private.sequence.soloPattern === patternsMenuItem.thisPatternIndex
                                                    onClicked: {
                                                        if (_private.sequence.soloPattern === patternsMenuItem.thisPatternIndex) {
                                                            _private.sequence.soloPattern = -1;
                                                        } else {
                                                            _private.sequence.soloPattern = patternsMenuItem.thisPatternIndex;
                                                        }
                                                    }
                                                }
                                            }
                                            ColumnLayout {
                                                Layout.fillHeight: true
                                                Layout.minimumWidth: height
                                                Layout.maximumWidth: height
                                                Item {
                                                    Layout.fillHeight: true
                                                    Layout.fillWidth: true
                                                    Layout.margins: Kirigami.Units.largeSpacing
                                                    Zynthian.PlayGridButton {
                                                        anchors.fill: parent
                                                        opacity: _private.sequence && _private.sequence.soloPattern === -1 ? 1 : 0.5
                                                        icon.name: "player-volume"
                                                        onClicked: {
                                                            if (_private.sequence && _private.sequence.soloPattern === -1) {
                                                                let associatedClip = patternsMenuItem.associatedChannel.getClipsModelById(patternsMenuItem.thisPattern.clipIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                                                                // Seems slightly backwards, but tapping a bunch of times really super fast and you'd end up with something a bit odd and unexpected, so might as well not cause that
                                                                associatedClip.enabled = !patternsMenuItem.thisPattern.enabled
                                                            }
                                                        }
                                                    }
                                                    Rectangle {
                                                        visible: patternsMenuItem.thisPattern ? !patternsMenuItem.thisPattern.enabled : false
                                                        anchors.centerIn: parent
                                                        rotation: 45
                                                        width: parent.width
                                                        height: Kirigami.Units.smallSpacing
                                                        color: "red"
                                                    }
                                                }
                                            }
                                            ColumnLayout {
                                                Layout.fillHeight: true
                                                Layout.minimumWidth: (parent.width / 7);
                                                Layout.maximumWidth: (parent.width / 7);
                                                QQC2.Label {
                                                    Layout.fillHeight: true
                                                    Layout.preferredHeight: patternsMenuItem.height / 2
                                                    Layout.fillWidth: true
                                                    text: patternsMenuItem.associatedChannel ? "Track " + patternsMenuItem.associatedChannel.name : "(no channel)"
                                                    font.pixelSize: 15
                                                    Kirigami.Theme.inherit: false
                                                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                                    color: Kirigami.Theme.textColor
                                                    horizontalAlignment: Text.AlignHCenter
                                                }
                                                Zynthian.PlayGridButton {
                                                    Layout.fillHeight: true
                                                    Layout.preferredHeight: patternsMenuItem.height / 2
                                                    text: patternsMenuItem.thisPattern ? qsTr("Clip %1%2").arg(patternsMenuItem.associatedChannelIndex + 1).arg(patternsMenuItem.thisPattern.clipName) : "(no clip)"
                                                    enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                                    onClicked: {
                                                        clipPicker.pickClip(patternsMenuItem.associatedChannelIndex);
                                                    }
                                                }
                                            }
                                            ColumnLayout {
                                                Layout.fillHeight: true
                                                Layout.minimumWidth: (parent.width / 8) * 3;
                                                Layout.maximumWidth: (parent.width / 8) * 3;

                                                Zynthian.PlayGridButton {
                                                    id: soundButton
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: patternsMenuItem.height / 2
                                                    enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex && patternsMenuItem.associatedChannel && patternsMenuItem.thisPattern && patternsMenuItem.thisPattern.noteDestination === Zynthbox.PatternModel.SynthDestination
                                                    opacity: enabled ? 1 : 0.7
                                                    property string soundName
                                                    background: Rectangle {
                                                        id: patternPopupSampleVisualiser
                                                        radius: 2
                                                        border {
                                                            width: 1
                                                            color: soundButton.borderColor
                                                        }
                                                        color: soundButton.backgroundColor
                                                        property bool sampleVisible: parent.visible && patternsMenuItem.thisPattern != null && patternsMenuItem.thisPattern.noteDestination === Zynthbox.PatternModel.SampleTriggerDestination
                                                        property QtObject channel: null
                                                        Binding {
                                                            target: patternPopupSampleVisualiser
                                                            property: "channel"
                                                            value: patternsMenuItem.associatedChannel
                                                            when: patternPopupSampleVisualiser.sampleVisible
                                                            delayed: true
                                                            restoreMode: Binding.RestoreBindingOrValue
                                                        }
                                                        property QtObject sample: channel && channel.samples ? channel.samples[patternsMenuItem.thisPattern.clipIndex] : null
                                                        Zynthian.SampleVisualiser {
                                                            anchors.fill: parent
                                                            opacity: 0.2
                                                            sample: parent.visible ? patternPopupSampleVisualiser.sample : null
                                                            trackType: patternPopupSampleVisualiser.channel === null ? "" : patternPopupSampleVisualiser.channel.trackType
                                                        }
                                                    }
                                                    Component.onCompleted: {
                                                        updateSoundNameTimer.restart();
                                                    }
                                                    Timer {
                                                        id: updateSoundNameTimer
                                                        interval: 100
                                                        repeat: false
                                                        onTriggered: soundButton.updateSoundName()
                                                    }
                                                    Connections {
                                                        target: patternsMenuItem
                                                        onAssociatedChannelChanged: updateSoundNameTimer.restart();
                                                    }
                                                    Connections {
                                                        target: zynqtgui.fixed_layers
                                                        onList_updated: updateSoundNameTimer.restart();
                                                    }
                                                    Connections {
                                                        target: patternsMenuItem.associatedChannel
                                                        onChainedSoundsNamesChanged: updateSoundNameTimer.restart();
                                                        onConnectedSoundChanged: updateSoundNameTimer.restart();
                                                    }
                                                    function updateSoundName() {
                                                        var text = "";

                                                        if (patternsMenuItem.associatedChannel) {
                                                            let soundNames = patternsMenuItem.associatedChannel.chainedSoundsNames;
                                                            let theNames = [];
                                                            for (let index = 0; index < soundNames.length; ++index) {
                                                                if (soundNames[index] !== "") {
                                                                    theNames.push(soundNames[index]);
                                                                }
                                                            }
                                                            if (theNames.length > 0) {
                                                                text = theNames.join(",");
                                                            }
                                                        }

                                                        soundName = text;
                                                    }
                                                    function clipShorthands(clipIds) {
                                                        var names = [];
                                                        if (patternsMenuItem.associatedChannel) {
                                                            for (var i = 0; i < patternsMenuItem.associatedChannel.samples.length; ++i) {
                                                                var sample = patternsMenuItem.associatedChannel.samples[i];
                                                                if (sample && clipIds.indexOf(sample.cppObjId) > -1) {
                                                                    names.push("S" + i);
                                                                }
                                                            }
                                                        }
                                                        if (names.length > 0) {
                                                            return names.join(",");
                                                        }
                                                        return "(no sample)";
                                                    }
                                                    text: visible
                                                        ? patternsMenuItem.thisPattern && patternsMenuItem.thisPattern.noteDestination === Zynthbox.PatternModel.SampleTriggerDestination
                                                            ? qsTr("Sample Trigger Mode: %1").arg(clipShorthands(patternsMenuItem.thisPattern.clipIds))
                                                            : patternsMenuItem.thisPattern && patternsMenuItem.thisPattern.noteDestination === Zynthbox.PatternModel.ExternalDestination
                                                                ? qsTr("External Midi Mode: Channel %1").arg(patternsMenuItem.thisPattern.externalMidiChannel > -1 ? patternsMenuItem.thisPattern.externalMidiChannel + 1 : patternsMenuItem.thisPattern.sketchpadTrack + 1)
                                                                : patternsMenuItem.associatedChannel
                                                                    ? patternsMenuItem.associatedChannel.connectedSound > -1 && soundName.length > 2
                                                                        ? "Sound: " + soundName
                                                                        : "No sound assigned - tap to select one"
                                                            : "Unassigned - playing to: " + _private.currentSoundName
                                                        : ""
                                                    onClicked: {
                                                        zynqtgui.current_screen_id = "sketchpad";
                                                    }
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: patternsMenuItem.height / 2
                                                    Item {
                                                        id: patternPopupLoopVisualiser
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        visible: parent.visible && patternsMenuItem.thisPattern != null && patternsMenuItem.thisPattern.noteDestination === Zynthbox.PatternModel.SampleLoopedDestination
                                                        property QtObject channel: null
                                                        Binding {
                                                            target: patternPopupLoopVisualiser
                                                            property: "channel"
                                                            value: patternsMenuItem.associatedChannel
                                                            when: patternPopupLoopVisualiser.visible
                                                            delayed: true
                                                            restoreMode: Binding.RestoreBinding
                                                        }
                                                        property QtObject sample: channel ? channel.getClipsModelById(channel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex) : null
                                                        Zynthian.SampleVisualiser {
                                                            anchors.fill: parent
                                                            sample: parent.visible ?  patternPopupLoopVisualiser.sample : null
                                                            trackType: patternPopupLoopVisualiser.channel === null ? "" : patternPopupLoopVisualiser.channel.trackType
                                                        }
                                                    }
                                                    Image {
                                                        Layout.fillHeight: true
                                                        Layout.fillWidth: true
                                                        visible: parent.visible && patternsMenuItem.thisPattern != null && patternsMenuItem.thisPattern.noteDestination !== Zynthbox.PatternModel.SampleLoopedDestination
                                                        asynchronous: true
                                                        source: patternsMenuItem.thisPattern ? patternsMenuItem.thisPattern.thumbnailUrl : ""
                                                        Rectangle {
                                                            anchors {
                                                                top: parent.top
                                                                bottom: parent.bottom
                                                            }
                                                            visible: parent.visible && patternsMenuItem.thisPattern ? patternsMenuItem.thisPattern.isPlaying : false
                                                            color: Kirigami.Theme.highlightColor
                                                            width: Math.max(1, Math.floor(widthFactor))
                                                            property double widthFactor: visible && patternsMenuItem.thisPattern ? parent.width / (patternsMenuItem.thisPattern.width * patternsMenuItem.thisPattern.bankLength) : 1
                                                            x: visible && patternsMenuItem.thisPattern ? patternsMenuItem.thisPattern.bankPlaybackPosition * widthFactor : 0
                                                        }
                                                        Kirigami.Heading {
                                                            anchors {
                                                                fill: parent
                                                                margins: Kirigami.Units.smallSpacing
                                                            }
                                                            horizontalAlignment: Text.AlignRight
                                                            verticalAlignment: Text.AlignBottom
                                                            level: 4
                                                            text: patternsMenuItem.thisPattern ? patternsMenuItem.thisPattern.name + (patternsMenuItem.thisPattern.unsavedChanges === true ? " *" : "") : ""
                                                        }
                                                    }
                                                }
                                            }
                                            //ColumnLayout {
                                                //Layout.fillHeight: true
                                                //Zynthian.PlayGridButton {
                                                    //text: "bank I"
                                                    //enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                                    //checked: patternsMenuItem.thisPattern.bankOffset === 0
                                                    //onClicked: {
                                                        //_private.sequence.setPatternProperty(_private.activePattern, "bankOffset", 0, patternsMenuItem.thisPatternIndex)
                                                    //}
                                                //}
                                                //Zynthian.PlayGridButton {
                                                    //text: "bank II"
                                                    //enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                                    //checked: patternsMenuItem.thisPattern.bankOffset === 8
                                                    //onClicked: {
                                                        //_private.sequence.setPatternProperty(_private.activePattern, "bankOffset", 8, patternsMenuItem.thisPatternIndex)
                                                    //}
                                                //}
                                            //}
                                            Zynthian.PlayGridButton {
                                                text: "copy\n"
                                                enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                                onClicked: {
                                                    _private.copyRange(
                                                        (patternsMenuItem.thisPatternIndex + 1) + " " + _private.sceneName,
                                                        patternsMenuItem.thisPattern,
                                                        patternsMenuItem.thisPattern.bankOffset,
                                                        patternsMenuItem.thisPattern.bankOffset + patternsMenuItem.thisPattern.availableBars
                                                    );
                                                }
                                            }
                                            Zynthian.PlayGridButton {
                                                text: "paste\n" + (_private.clipBoard && _private.clipBoard.description !== "" ? _private.clipBoard.description : "")
                                                enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex && _private.clipBoard !== undefined
                                                onClicked: {
                                                    // Resize the pattern's banks to match what we're pasting
                                                    patternsMenuItem.thisPattern.patternLength = patternsMenuItem.thisPattern.width * Math.floor(_private.clipBoard.notes.length / patternsMenuItem.thisPattern.width) - 1;
                                                    _private.pasteInPlace(patternsMenuItem.thisPattern, patternsMenuItem.thisPattern.bankOffset, _private.bankOffset + patternsMenuItem.thisPattern.bankLength);
                                                    if (_private.activePatternModel == patternsMenuItem.thisPattern) {
                                                        component.setActiveBar(_private.activeBar)
                                                    }
                                                }
                                            }
                                            Zynthian.PlayGridButton {
                                                text: "clear\n"
                                                enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                                onClicked: {
                                                    patternsMenuItem.thisPattern.clear();
                                                    patternsMenuItem.thisPattern.patternLength = patternsMenuItem.thisPattern.width;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            width: parent.width - patternsMenuList.QQC2.ScrollBar.vertical.width - Kirigami.Units.smallSpacing
                            height: Kirigami.Units.gridUnit * 2
                            Zynthian.PlayGridButton {
                                text: "Track 1-5"
                                onClicked: {
                                    patternsMenuListView.positionViewAtIndex(0, ListView.Beginning);
                                }
                                checked: patternsMenuList.QQC2.ScrollBar.vertical.position < 0.49
                            }
                            Zynthian.PlayGridButton {
                                text: "Track 6-10"
                                onClicked: {
                                    patternsMenuListView.positionViewAtIndex(5, ListView.Beginning);
                                }
                                checked: patternsMenuList.QQC2.ScrollBar.vertical.position > 0.49
                            }
                        }
                    }
                }
            }
            Zynthian.Popup {
                id: noteSettingsPopup
                parent: QQC2.Overlay.overlay
                y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
                x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
                height: applicationWindow().height
                width: applicationWindow().width
                closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
                onVisibleChanged: {
                    component.noteSettingsPopupVisible = noteSettingsPopup.visible;
                }
                function showSettings(patternModel, firstBar, lastBar, midiNoteFilter, firstStep = -1, lastStep = -1) {
                    let currentlySelectedBar = -1;
                    let currentSelectedStep = -1;
                    let currentlySelectedSubnoteIndex = -1;
                    if (drumPadRepeater.selectedIndex > -1) {
                        var seqPad = drumPadRepeater.itemAt(drumPadRepeater.selectedIndex);
                        currentlySelectedBar = _private.activeBar;
                        currentSelectedStep = seqPad.padNoteIndex;
                        currentlySelectedSubnoteIndex = seqPad.currentSubNote;
                        console.log("Showing selected things:", currentlySelectedBar, currentSelectedStep, currentlySelectedSubnoteIndex);
                    }
                    noteSettings.midiNoteFilter = midiNoteFilter;
                    noteSettings.firstBar = firstBar;
                    noteSettings.lastBar = lastBar;
                    noteSettings.firstStep = firstStep;
                    noteSettings.lastStep = lastStep;
                    noteSettings.patternModel = patternModel;
                    if (currentlySelectedSubnoteIndex > -1) {
                        noteSettings.selectBarStepAndSubnote(currentlySelectedBar, currentSelectedStep, currentlySelectedSubnoteIndex)
                    }
                    noteSettingsPopup.open();
                }
                property var cuiaCallback: function(cuia) {
                    return noteSettings.cuiaCallback(cuia);
                }
                Connections {
                    target: component
                    onIsVisibleChanged: {
                        if (noteSettingsPopup.opened && component.isVisible === false) {
                            noteSettingsPopup.close();
                        }
                    }
                    onShowNoteSettingsPopup: {
                        if (firstStep > -1 && lastStep > -1) {
                            noteSettingsPopup.showSettings(patternModel, firstBar, lastBar, midiNoteFilter, firstStep, lastStep);
                        } else {
                            noteSettingsPopup.showSettings(patternModel, firstBar, lastBar, midiNoteFilter);
                        }
                    }
                    onHideNoteSettingsPopup: {
                        noteSettingsPopup.hide();
                    }
                }
                NoteSettings {
                    id: noteSettings
                    anchors.fill: parent
                    onClose: noteSettingsPopup.close();
                    showCloseButton: true
                }
            }
            Zynthian.Popup {
                id: clipPicker
                function pickClip(associatedChannelIndex) {
                    clipPicker.associatedChannelIndex = associatedChannelIndex;
                    open();
                }
                Connections {
                    target: component
                    onIsVisibleChanged: {
                        if (clipPicker.opened && component.isVisible === false) {
                            clipPicker.close();
                        }
                    }
                }
                property var cuiaCallback: function(cuia) {
                    if (cuia === "SWITCH_BACK_SHORT" || cuia === "SWITCH_BACK_BOLD") {
                        clipPicker.close();
                    }
                    return true;
                }
                onOpened: {
                    zynqtgui.pushDialog(clipPicker);
                }
                onClosed: {
                    zynqtgui.popDialog(clipPicker);
                    clipPicker.associatedChannelIndex = -1;
                }
                parent: QQC2.Overlay.overlay
                x: Math.round(parent.width/2 - width/2)
                y: Math.round(parent.height/2 - height/2)
                property int associatedChannelIndex: -1
                property QtObject associatedChannel: zynqtgui.sketchpad.song.channelsModel.getChannel(clipPicker.associatedChannelIndex)
                ColumnLayout {
                    anchors.fill: parent
                    implicitWidth: Kirigami.Units.gridUnit * 30
                    implicitHeight: Kirigami.Units.gridUnit * 40
                    Kirigami.Heading {
                        Layout.fillWidth: true
                        text: qsTr("Select Active Clips For Channel %1").arg(clipPicker.associatedChannel ? clipPicker.associatedChannel.name : "")
                    }
                    ColumnLayout {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.largeSpacing
                        Repeater {
                            model: clipPicker.associatedChannel ? 5 : 0
                            delegate: RowLayout {
                                id: clipDelegate
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: Kirigami.Units.smallSpacing
                                property QtObject pattern: _private.sequence.getByClipId(clipPicker.associatedChannelIndex, model.index)
                                Rectangle {
                                    Layout.fillHeight: true
                                    Layout.minimumWidth: Kirigami.Units.largeSpacing
                                    Layout.maximumWidth: Kirigami.Units.largeSpacing
                                    color: clipPicker.associatedChannel.selectedClip === model.index ? Kirigami.Theme.highlightColor : "transparent"
                                }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                                    Zynthian.PlayGridButton {
                                        anchors.fill: parent
                                        opacity: clipDelegate.pattern.sequence && clipDelegate.pattern.sequence.soloPattern === -1 ? 1 : 0.5
                                        icon.name: "player-volume"
                                        onClicked: {
                                            if (clipDelegate.pattern.sequence && clipDelegate.pattern.sequence.soloPattern === -1) {
                                                var associatedClip = clipPicker.associatedChannel.getClipsModelById(clipDelegate.pattern.clipIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                                                // Seems slightly backwards, but tapping a bunch of times really super fast and you'd end up with something a bit odd and unexpected, so might as well not cause that
                                                associatedClip.enabled = !clipDelegate.pattern.enabled
                                            }
                                        }
                                    }
                                    Rectangle {
                                        visible: clipDelegate.pattern ? !clipDelegate.pattern.enabled : false
                                        anchors.centerIn: parent
                                        rotation: 45
                                        width: parent.height
                                        height: Kirigami.Units.smallSpacing
                                        color: "red"
                                    }
                                }
                                Zynthian.PlayGridButton {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                                    text: qsTr("Pick Clip %1%2").arg(clipPicker.associatedChannelIndex + 1).arg(clipDelegate.pattern.clipName)
                                    onClicked: {
                                        var associatedClip = clipPicker.associatedChannel.getClipsModelById(clipDelegate.pattern.clipIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                                        if (associatedClip.enabled) {
                                            clipPicker.associatedChannel.selectedClip = model.index;
                                        } else {
                                            associatedClip.enabled = true;
                                        }
                                        clipPicker.close();
                                    }
                                }
                                Image {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                                    source: clipDelegate.pattern.thumbnailUrl
                                    Rectangle {
                                        anchors {
                                            top: parent.top
                                            bottom: parent.bottom
                                        }
                                        visible: clipDelegate.pattern ? clipDelegate.pattern.isPlaying : false
                                        color: Kirigami.Theme.highlightColor
                                        width: Math.max(1, Math.floor(widthFactor))
                                        property double widthFactor: clipDelegate.pattern ? parent.width / (clipDelegate.pattern.width * clipDelegate.pattern.bankLength) : 1
                                        x: clipDelegate.pattern ? clipDelegate.pattern.bankPlaybackPosition * widthFactor : 0
                                    }
                                    Kirigami.Heading {
                                        anchors {
                                            fill: parent
                                            margins: Kirigami.Units.smallSpacing
                                        }
                                        horizontalAlignment: Text.AlignRight
                                        verticalAlignment: Text.AlignBottom
                                        level: 4
                                        text: clipDelegate.pattern.name
                                    }
                                }
                            }
                        }
                    }
                    Zynthian.ActionBar {
                        Layout.fillWidth: true
                        currentPage: Item {
                            property QtObject backAction: Kirigami.Action {
                                text: "Back"
                                onTriggered: {
                                    clipPicker.close();
                                }
                            }
                            property list<QtObject> contextualActions
                        }
                    }
                }
            }
        }
    }

    // Drums Grid Sidebar
    Component {
        id: drumsGridSidebar
        Item {
            ColumnLayout {
                id: sidebarRoot
                anchors.fill: parent
                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                Zynthian.PlayGridButton {
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    text: _private.sequence
                        ? _private.sequence.soloPatternObject
                            ? "Track" + (_private.sequence.soloPatternObject.sketchpadTrack + 1) + "\n"
                                + "SOLO\n"
                                + (_private.sequence.soloPatternObject.sketchpadTrack + 1) + _private.sequence.soloPatternObject.clipName
                            : _private.activePatternModel
                                ? "Track" + (_private.activePatternModel.sketchpadTrack + 1) + "\n"
                                    + "Clip"
                                    + (_private.activePatternModel.sketchpadTrack + 1) + _private.activePatternModel.clipName
                                : "(no\npat\ntern)"
                        : "(no\nsequ\nence)"
                    onClicked: {
                        component.showPatternsMenu();
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                Zynthian.PlayGridButton {
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                    icon.name: "arrow-up"
                    onClicked: {
                        _private.octaveUp();
                    }
                }

                QQC2.Label {
                    text: "Note Grid"
                    Layout.alignment: Qt.AlignHCenter
                }

                Zynthian.PlayGridButton {
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                    icon.name: "arrow-down"
                    onClicked: {
                        _private.octaveDown();
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                Zynthian.PlayGridButton {
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                    text: "Note:\n" + (component.heardNotes.length > 0
                        ? Zynthbox.Chords.symbol(component.heardNotes, _private.workingPatternModel.scaleKey, _private.workingPatternModel.pitchKey, _private.workingPatternModel.octaveKey, "\n—\n")
                        : "(all)")
                    onPressed: {
                        component.nudgeOverlayEnabled = true;
                    }
                    onReleased: {
                        component.nudgeOverlayEnabled = false;
                        if (component.nudgePerformed) {
                            component.nudgePerformed = false;
                            if (_private.activePatternModel.performanceActive) {
                                _private.activePatternModel.applyPerformance();
                                _private.activePatternModel.stopPerformance();
                            }
                        } else {
                            if (zynqtgui.backButtonPressed && _private.workingPatternModel) {
                                zynqtgui.ignoreNextBackButtonPress = true;
                                _private.workingPatternModel.clear();
                            } else {
                                if (_private.selectedStep > -1) {
                                    while (_private.hasSelection) {
                                        _private.deselectSelectedItem();
                                    }
                                }
                                component.heardNotes = [];
                                component.heardVelocities = [];
                            }
                        }
                    }
                    Kirigami.Icon {
                        anchors {
                            bottom: parent.bottom
                            right: parent.right
                            margins: Kirigami.Units.smallSpacing
                        }
                        height: parent.width * 0.3
                        width: height
                        visible: component.heardNotes.length > 0
                        source: "edit-clear-locationbar"
                    }
                }
                Zynthian.PlayGridButton {
                    id: defaultNoteSettingsButton
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    text: _private.selectedStep > -1
                        ? "Step\n%1".arg((_private.workingPatternModel.width * (_private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset)) + _private.selectedStep + 1)
                        : component.heardNotes.length > 0
                            ? "%1\n%2".arg(noteLength).arg(velocity)
                            : (component.currentBarNotes.length > 0 ? component.currentBarNotes.length : "-") + " in\nBar"
                    property var stepNames: {
                        0: component.stepDurationName,
                        1: "1/128th",
                        2: "1/64th",
                        4: "1/32nd",
                        8: "1/16th",
                        16: "1/8th",
                        32: "1/4th",
                        64: "1/2nd",
                        96: "3/4th",
                        128: "1",
                        256: "2",
                        384: "3",
                        512: "4",
                        640: "5",
                        768: "6",
                        896: "7",
                        1024: "8"
                    }
                    property string noteLength: _private.workingPatternModel
                        ? _private.workingPatternModel.defaultNoteDuration === 0
                            ? _private.workingPatternModel.stepLengthName(_private.workingPatternModel.stepLength)
                            : defaultNoteSettingsButton.stepNames.hasOwnProperty(_private.workingPatternModel.defaultNoteDuration)
                                ? defaultNoteSettingsButton.stepNames[_private.workingPatternModel.defaultNoteDuration]
                                : _private.workingPatternModel.defaultNoteDuration + "/128th"
                        : ""
                    property string velocity: component.heardVelocities.length === 0 ? "" : "Vel " + component.heardVelocities[0]
                    onClicked: {
                        if (_private.selectedStep > -1) {
                            component.showNoteSettingsPopup(_private.workingPatternModel, _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset, _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset, [], _private.selectedStep, _private.selectedStep);
                        } else if (component.heardNotes.length > 0) {
                            var filter = []
                            for (var i = 0; i < component.heardNotes.length; ++i) {
                                filter.push(component.heardNotes[i].midiNote);
                            }
                            component.showNoteSettingsPopup(_private.workingPatternModel, _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset, _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset, filter, -1, -1);
                        } else {
                            component.showNoteSettingsPopup(_private.workingPatternModel, _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset, _private.workingPatternModel.activeBar + _private.workingPatternModel.bankOffset, [], -1, -1);
                        }
                    }
                    Kirigami.Icon {
                        anchors {
                            bottom: parent.bottom
                            right: parent.right
                        }
                        height: parent.width * 0.3
                        width: height
                        source: "overflow-menu"
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                Zynthian.PlayGridButton {
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                    id:sequencerSettingsBtn
                    icon.name: "configure"
                    onClicked: {
                        component.showPatternSettings = !component.showPatternSettings;
                    }
                }
            }
        }
    }

    // Drums Grid Settings Component
    Component {
        id: drumsGridSettings
        Kirigami.FormLayout {
            objectName: "drumsGridSettings"
            Layout.fillWidth: true
            Layout.fillHeight: true

            QQC2.Switch {
                Layout.fillWidth: true
                implicitWidth: Kirigami.Units.gridUnit * 5
                Layout.minimumWidth: Kirigami.Units.gridUnit * 5
                Kirigami.FormData.label: "Use Tap Position As Velocity"
                checked: component.getProperty("positionalVelocity")
                onClicked: {
                    var positionalVelocity = component.getProperty("positionalVelocity")
                    component.setProperty("positionalVelocity", !positionalVelocity);
                }
            }
        }
    }
    Component {
        id: drumsPopup
        ColumnLayout {
            Kirigami.Heading {
                Layout.fillWidth: true;
                text: "Stepsequencer Quick Settings"
            }
            Kirigami.FormLayout {
                objectName: "drumsPopup"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Item { Layout.fillWidth: true; Layout.fillHeight: true }
                QQC2.Switch {
                    Layout.fillWidth: true
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 5
                    Layout.minimumHeight: Kirigami.Units.gridUnit * 2
                    implicitWidth: Kirigami.Units.gridUnit * 5
                    Kirigami.FormData.label: "Use Tap Position As Velocity"
                    checked: component.getProperty("positionalVelocity")
                    onClicked: {
                        var positionalVelocity = component.getProperty("positionalVelocity")
                        component.setProperty("positionalVelocity", !positionalVelocity);
                    }
                }
                Item { Layout.fillWidth: true; Layout.fillHeight: true }
            }
        }
    }
}
