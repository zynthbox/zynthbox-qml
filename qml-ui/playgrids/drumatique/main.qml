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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick
import "../../pages/SessionDashboard/" as SessionDashboard

Zynthian.BasePlayGrid {
    id: component
    grid: drumsGrid
    settings: drumsGridSettings
    sidebar: drumsGridSidebar
    name:'Drumatique'
    dashboardModel: _private.sequence
    useOctaves: true
    additionalActions: [
        Kirigami.Action {
            text: qsTr("Load Sequence or Pattern...")
            onTriggered: {
                sequenceLoader.loadSequenceFromFile();
            }
        },
        Kirigami.Action {
            text: qsTr("Export Sequence...")
            onTriggered: {
                sequenceLoader.saveSequenceToFile();
            }
        },
        Kirigami.Action {
           text: qsTr("Export Current Pattern...")
           onTriggered: {
               sequenceLoader.savePatternToFile();
           }
        },
        Kirigami.Action {
            text: qsTr("Get New Sequences...")
            onTriggered: {
                zynthian.show_modal("sequence_downloader")
            }
        }
    ]

    property bool ignoreNextBack: false
    cuiaCallback: function(cuia) {
        var backButtonClearPatternHelper = function(patternIndex) {
            if (zynthian.backButtonPressed) {
                component.ignoreNextBack = true;
                var pattern = _private.sequence.get(patternIndex);
                if (pattern) {
                    pattern.clear();
                }
                return true;
            }
            return false;
        }
        var returnValue = false;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                if (ignoreNextBack) {
                    // When back button's been used for interaction elsewhere, ignore it here...
                    // Remember to set this, or things will look a bit weird
                    ignoreNextBack = false;
                } else {
                    if (component.showPatternsMenu) {
                        component.showPatternsMenu = false;
                    } else if (_private.hasSelection) {
                        _private.deselectSelectedItem();
                    } else if (component.mostRecentlyPlayedNote) {
                        component.mostRecentlyPlayedNote = undefined;
                    } else if (component.heardNotes.length > 0) {
                        component.heardNotes = [];
                        component.heardVelocities = [];
                    }
                }
                returnValue = true;
                break;
            case "SELECT_UP":
                if (_private.sequence && _private.sequence.activePattern > 0) {
                    component.pickPattern(_private.sequence.activePattern - 1);
                    returnValue = true;
                }
                break;
            case "SELECT_DOWN":
                if (_private.sequence && _private.sequence.activePattern < _private.sequence.rowCount()) {
                    component.pickPattern(_private.sequence.activePattern + 1);
                    returnValue = true;
                }
                break;
            case "SELECT_LEFT":
            case "NAVIGATE_LEFT":
                _private.goLeft();
                returnValue = true;
                break;
            case "SELECT_RIGHT":
            case "NAVIGATE_RIGHT":
                _private.goRight();
                returnValue = true;
                break;
            case "SWITCH_SELECT_SHORT":
                _private.activateSelectedItem();
                returnValue = true;
                break;
            case "TRACK_1":
                returnValue = backButtonClearPatternHelper(0);
                break;
            case "TRACK_2":
                returnValue = backButtonClearPatternHelper(1);
                break;
            case "TRACK_3":
                returnValue = backButtonClearPatternHelper(2);
                break;
            case "TRACK_4":
                returnValue = backButtonClearPatternHelper(3);
                break;
            case "TRACK_5":
                returnValue = backButtonClearPatternHelper(4);
                break;
            case "TRACK_6":
                returnValue = backButtonClearPatternHelper(5);
                break;
            case "TRACK_7":
                returnValue = backButtonClearPatternHelper(6);
                break;
            case "TRACK_8":
                returnValue = backButtonClearPatternHelper(7);
                break;
            case "TRACK_9":
                returnValue = backButtonClearPatternHelper(8);
                break;
            case "TRACK_10":
                returnValue = backButtonClearPatternHelper(9);
                break;
            case "TRACK_11":
                returnValue = backButtonClearPatternHelper(10);
                break;
            case "TRACK_12":
                returnValue = backButtonClearPatternHelper(11);
                break;
            default:
                break;
        }
        return returnValue;
    }

    property bool showPatternsMenu: false
    property bool showPatternSettings: false

    property var mostRecentlyPlayedNote
    property var mostRecentNoteVelocity
    property bool listenForNotes: false
    property var heardNotes: []
    property var heardVelocities: []
    property var currentRowUniqueNotes: []

    function setActiveBar(activeBar) {
        _private.sequence.activePatternObject.activeBar = activeBar;
    }
    function setPatternProperty(property, value, patternIndex) {
        if (patternIndex === undefined) {
            patternIndex = _private.activePattern;
        }
        var pattern = _private.sequence.get(patternIndex);
        if (pattern) {
            var currentValue = pattern[property];
            //console.log("Attempting to change " + property + " from " + currentValue + " to " + value)
            if (currentValue != value) {
                _private.sequence.setPatternProperty(patternIndex, property, value);
                if (_private.activePattern == patternIndex) {
                    switch (property) {
                    case "noteLength":
                    case "availableBars":
                    case "activeBar":
                    case "layer":
                    case "mostRecentlyPlayedNote":
                    case "bankOffset":
                        // Just do nothing, we already updated the thing by setting the property
                        break;
                    default:
                        // Just in case we want this in the future...
                        refreshSteps();
                    }
                }
            }
        }
    }
    function refreshSteps() {
        // TODO If things keep working, then... this can go away :)
        //var activePattern = _private.sequence.activePattern;
        //if (_private.sequence.activePattern === 0) {
            //_private.sequence.activePattern = activePattern + 1;
        //} else {
            //_private.sequence.activePattern = activePattern - 1;
        //}
        //_private.sequence.activePattern = activePattern;
    }

    function pickPattern(patternIndex) {
        for(var i = 0; i < zynthian.zynthiloops.song.tracksModel.count; ++i) {
            var track = zynthian.zynthiloops.song.tracksModel.getTrack(i);
            if (track && track.connectedPattern === patternIndex) {
                zynthian.session_dashboard.selectedTrack = i;
                break;
            }
        }
        _private.sequence.activePattern = patternIndex
    }

    property var noteSpecificColor: {
        "C":"#f08080", 
        "C#":"#4b0082",
        "D":"#8a2be2",
        "D#":"#a52a2a" ,
        "E":"#deb887",
        "F":"#5f9ea0",
        "F#":"#7fff00",
        "G":"#d2691e",
        "G#":"#6495ed",
        "A":"#dc143c",
        "A#":"#008b8b",
        "B":"#b8860b"
    }

    function getNoteSpecificColor(name,number){
        var color = noteSpecificColor[name];
        var num = number * 3
        var finalColor = color.substring(0,3) + num + color.substring(3 + parseInt(num.toString().length));
        return finalColor;
    }

    QtObject {
        id:_private;
        // Yes, this is a hack - if we don't do this, we'll forever be rebuilding the patterns popup etc when the sequence and pattern changes, which is all manner of expensive
        property int sequencePatternCount: 10
        property int activeBarModelWidth: 16
        property QtObject sequence
        property int activePattern: sequence ? sequence.activePattern : -1
        property QtObject activePatternModel: sequence ? sequence.activePatternObject : null;
        property QtObject activeBarModel: activePatternModel && activeBar > -1 && activePatternModel.data(activePatternModel.index(activeBar + bankOffset, 0), activePatternModel.roles["rowModel"])
            ? activePatternModel.data(activePatternModel.index(activeBar + bankOffset, 0), activePatternModel.roles["rowModel"])
            : null;

        property bool patternHasUnsavedChanged: false
        property bool positionalVelocity: true
        property var bars: [0,1,2,3,4,5,6,7]
        // This is the top bank we have available in any pattern (that is, the upper limit for any pattern's bankOffset value)
        property int bankLimit: 1
        property var clipBoard
        property int octave: 4

        // Properties inherent to the active pattern (set these through component.setPatternProperty)
        property int noteLength: sequence && sequence.activePatternObject ? sequence.activePatternObject.noteLength : 0
        property int layer: sequence && sequence.activePatternObject ? sequence.activePatternObject.layer : 0
        property var availableBars: sequence && sequence.activePatternObject ? sequence.activePatternObject.availableBars : 0
        property var activeBar: sequence && sequence.activePatternObject ? sequence.activePatternObject.activeBar : -1
        property int bankOffset: sequence && sequence.activePatternObject ? sequence.activePatternObject.bankOffset : 0
        property string bankName: sequence && sequence.activePatternObject ? sequence.activePatternObject.bank : "?"
        property string sceneName: zynthian.zynthiloops.song.scenesModel.selectedSceneName
        property QtObject associatedTrack;
        property int associatedTrackIndex;

        function updateTrack() {
            trackUpdater.restart();
        }
        property QtObject trackUpdater: Timer {
            running: false;
            repeat: false;
            interval: 1;
            onTriggered: {
                var foundTrack = null;
                var foundIndex = -1;
                for(var i = 0; i < zynthian.zynthiloops.song.tracksModel.count; ++i) {
                    var track = zynthian.zynthiloops.song.tracksModel.getTrack(i);
                    if (track && track.connectedPattern === _private.activePattern) {
                        foundTrack = track;
                        foundIndex = i;
                        break;
                    }
                }
                _private.associatedTrack = foundTrack;
                _private.associatedTrackIndex = foundIndex;
            }
        }

        property QtObject currentTrack: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)
        property string currentSoundName: {
            var text = "(no sound)";
            if (_private.currentTrack) {
                for (var id in _private.currentTrack.chainedSounds) {
                    if (_private.currentTrack.chainedSounds[id] >= 0 &&
                        _private.currentTrack.checkIfLayerExists(_private.currentTrack.chainedSounds[id])) {
                        text = zynthian.fixed_layers.selector_list.getDisplayValue(_private.currentTrack.chainedSounds[id]);
                        break;
                    }
                }
            }
            return text;
        }
        //property QtObject activeBarModel: ZynQuick.FilterProxy {
            //sourceModel: patternModel
            //filterRowStart: activeBar
            //filterRowEnd: activeBar
        //}

        onOctaveChanged: {
            if (activePatternModel) {
                activePatternModel.gridModelStartNote = _private.octave * 12;
                activePatternModel.gridModelEndNote = activePatternModel.gridModelStartNote + 16;
            }
        }

        onActivePatternChanged:{
            updateTrack();
            while (hasSelection) {
                deselectSelectedItem();
            }
        }
        onActivePatternModelChanged: {
            if (activePatternModel) {
                _private.octave = activePatternModel.gridModelStartNote / 12;
            }
        }

        onLayerChanged: {
            updateTrack();
        }

        signal knob1Up();
        signal knob1Down();
        signal knob2Up();
        signal knob2Down();
        signal knob3Up();
        signal knob3Down();
        signal goLeft();
        signal goRight();
        signal deselectSelectedItem()
        signal activateSelectedItem()
        property bool hasSelection: false
        function previousBar() {
            if (sequence.activePatternObject.activeBar > -1) {
                sequence.activePatternObject.activeBar = sequence.activePatternObject.activeBar - 1;
            }
        }
        function nextBar() {
            if (sequence.activePatternObject.activeBar < sequence.activePatternObject.availableBars - 1) {
                _private.sequence.activePatternObject.activeBar = _private.sequence.activePatternObject.activeBar + 1;
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
            for (var row = startRow; row < endRow + 1; ++row) {
                for (var column = 0; column < model.width; ++column) {
                    var oldCompound = (noteIndex < _private.clipBoard.notes.length) ? _private.clipBoard.notes[noteIndex] : null;
                    var newSubnotes = [];
                    if (oldCompound) {
                        var oldSubnotes = oldCompound.subnotes;
                        if (oldSubnotes) {
                            for (var j = 0; j < oldSubnotes.length; ++j) {
                                newSubnotes.push(component.getNote(oldSubnotes[j].midiNote, model.midiChannel));
                            }
                        }
                    }
                    model.setNote(row, column, component.getCompoundNote(newSubnotes))
                    var newMetadata = (noteIndex < _private.clipBoard.velocities.length) ? _private.clipBoard.velocities[noteIndex] : [];
                    model.setMetadata(row, column, newMetadata)
                    ++noteIndex;
                }
            }
            component.refreshSteps();
        }
        function adoptSequence() {
            console.log("Adopting the scene sequence");
            var sequence = ZynQuick.PlayGridManager.getSequenceModel("Scene " + zynthian.zynthiloops.song.scenesModel.selectedSceneName);
            if (_private.sequence != sequence) {
                console.log("Scene has changed, switch places!");
                _private.sequence = sequence;
            }
        }
        function updateUniqueCurrentRowNotes() {
            component.currentRowUniqueNotes = activePatternModel.uniqueRowNotes(activeBar + bankOffset);
        }
    }
    Connections {
        target: zynthian.zynthiloops.song.tracksModel
        onConnectedSoundsCountChanged: _private.updateTrack()
        onConnectedPatternsCountChanged: _private.updateTrack()
    }
    Connections {
        target: _private.associatedTrack
        onConnectedPatternChanged: _private.updateTrack()
        onConnectedSoundChanged: _private.updateTrack()
    }
    Connections {
        target: zynthian.zynthiloops
        onSongChanged: {
            _private.adoptSequence();
            _private.updateTrack();
        }
    }
    Connections {
        target: zynthian.zynthiloops.song.scenesModel
        onSelectedSceneNameChanged: Qt.callLater(_private.adoptSequence) // Makes scene change look smoother
    }
    // on component completed
    onInitialize: {
        _private.adoptSequence();
    }
    Connections {
        target: ZynQuick.PlayGridManager
        onDashboardItemPicked: {
            adoptSequence(); // just to be safe...
            if (component.dashboardModel === model) {
                _private.sequence.activePattern = index;
                var foundIndex = -1;
                for(var i = 0; i < zynthian.zynthiloops.song.tracksModel.count; ++i) {
                    var track = zynthian.zynthiloops.song.tracksModel.getTrack(i);
                    if (track && track.connectedPattern === index) {
                        foundIndex = i;
                        break;
                    }
                }
                if (foundIndex > -1 && zynthian.session_dashboard.selectedTrack !== foundIndex) {
                    zynthian.session_dashboard.selectedTrack = foundIndex;
                }
            }
        }
        onMostRecentlyChangedNotesChanged: {
            if (component.listenForNotes && _private.activePatternModel) {
                var mostRecentNoteData = ZynQuick.PlayGridManager.mostRecentlyChangedNotes[ZynQuick.PlayGridManager.mostRecentlyChangedNotes.length - 1];
                if (mostRecentNoteData.channel == _private.activePatternModel.midiChannel) {
                    // Same channel, that makes us friends!
                    // Create a new note based on the new thing that just arrived, but only if it's an on note
                    if (mostRecentNoteData.type == "note_on") {
                        var newNote = component.getNote(mostRecentNoteData.note, mostRecentNoteData.channel);
                        var existingIndex = component.heardNotes.indexOf(newNote);
                        if (existingIndex > -1) {
                            component.heardNotes.splice(existingIndex, 1);
                            component.heardVelocities.splice(existingIndex, 1);
                        }
                        component.heardNotes.push(newNote);
                        component.heardVelocities.push(mostRecentNoteData.velocity);
                    }
                }
            }
        }
    }

    onMostRecentlyPlayedNoteChanged:{
        updateActivePatternMPN.restart();
    }
    Timer {
        id: updateActivePatternMPN
        repeat: false
        interval: 0
        onTriggered: {
            component.setPatternProperty("mostRecentlyPlayedNote", component.mostRecentlyPlayedNote);
        }
    }

    Zynthian.SequenceLoader {
        id: sequenceLoader
    }

    // Drum Grid Component
    Component {
        id: drumsGrid
        Item {
            anchors {
                margins: 5
                fill: parent;
            }
            objectName: "drumsGrid"
            ColumnLayout {
                id:gridColumnLayout
                spacing: 0
                anchors.fill: parent;

                DrumsGrid {
                    id: drumsGridItem
                    model: _private.activePatternModel ? (_private.activePatternModel.noteDestination === ZynQuick.PatternModel.SampleSlicedDestination ? _private.activePatternModel.clipSliceNotes : _private.activePatternModel.gridModel) : null
                    positionalVelocity: _private.positionalVelocity
                    playgrid: component
                    onRemoveNote: {
                        component.ignoreNextBack = true;
                        if (_private.activePatternModel) {
                            for (var row = _private.activePatternModel.bankOffset; row < _private.activePatternModel.bankOffset + _private.activePatternModel.bankLength; ++row) {
                                for (var column = 0; column < _private.activePatternModel.width; ++column) {
                                    var subNoteIndex = _private.activePatternModel.subnoteIndex(row, column, note.midiNote);
                                    if (subNoteIndex > -1) {
                                        if (row == _private.activePatternModel.activeBar + _private.activePatternModel.bankOffset && column == drumPadRepeater.selectedIndex) {
                                            var seqPad = drumPadRepeater.itemAt(column);
                                            if (seqPad.currentSubNote == subNoteIndex) {
                                                seqPad.currentSubNote = -1;
                                            }
                                        }
                                        _private.activePatternModel.removeSubnote(row, column, subNoteIndex);
                                    }
                                }
                            }
                        }
                    }
                }

                // drum pad & sequencer
                Rectangle {
                    id:drumPad
                    Layout.fillWidth: true; 
                    Layout.minimumHeight: parent.height / 5; 
                    Layout.maximumHeight: parent.height / 5;
                    color:"transparent"
                    Connections {
                        target: _private
                        onGoLeft: drumPadRepeater.goPrevious();
                        onGoRight: drumPadRepeater.goNext();
                        onDeselectSelectedItem: drumPadRepeater.deselectSelectedItem();
                        onActivateSelectedItem: drumPadRepeater.activateSelectedItem();
                        onKnob1Up: drumPadRepeater.velocityUp();
                        onKnob1Down: drumPadRepeater.velocityDown();
                        onKnob2Up: drumPadRepeater.durationUp();
                        onKnob2Down: drumPadRepeater.durationDown();
                    }

                    RowLayout {
                        anchors.fill:parent
                        anchors.margins: 5
                        Repeater {
                            id:drumPadRepeater
                            model: _private.activeBarModelWidth
                            property int selectedIndex: -1
                            onSelectedIndexChanged: {
                                _private.hasSelection = (drumPadRepeater.selectedIndex > -1);
                            }
                            function updateMostRecentFromSelection() {
                                var seqPad = drumPadRepeater.itemAt(selectedIndex);
                                var note = _private.activePatternModel.getNote(_private.activeBar + _private.bankOffset, selectedIndex);
                                var stepNotes = [];
                                var stepVelocities = [];
                                if (seqPad && seqPad.currentSubNote > -1) {
                                    if (note && seqPad.currentSubNote < note.subnotes.length) {
                                        stepVelocities.push(_private.activePatternModel.subnoteMetadata(_private.activeBar + _private.bankOffset, selectedIndex, seqPad.currentSubNote, "velocity"));
                                        stepNotes.push(note.subnotes[seqPad.currentSubNote]);
                                    }
                                } else if (note) {
                                    for (var i = 0; i < note.subnotes.length; ++i) {
                                        stepVelocities.push(_private.activePatternModel.subnoteMetadata(_private.activeBar + _private.bankOffset, selectedIndex, i, "velocity"));
                                        stepNotes.push(note.subnotes[i]);
                                    }
                                }
                                component.heardNotes = stepNotes;
                                component.heardVelocities = stepVelocities;
                                if (component.heardNotes.length === 1) {
                                    component.mostRecentlyPlayedNote = component.heardNotes[0];
                                    component.mostRecentNoteVelocity = component.heardVelocities[0];
                                    component.heardNotes = [];
                                    component.heardVelocities = [];
                                } else {
                                    component.mostRecentlyPlayedNote = undefined;
                                }
                            }
                            function goNext() {
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
                            function goPrevious() {
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
                            function deselectSelectedItem() {
                                if (stepSettingsPopup.visible) {
                                    stepSettingsPopup.close();
                                } else if (drumPadRepeater.selectedIndex > -1) {
                                    var seqPad = drumPadRepeater.itemAt(selectedIndex);
                                    if (seqPad.currentSubNote > -1) {
                                        seqPad.currentSubNote = -1;
                                    } else {
                                        drumPadRepeater.selectedIndex = -1;
                                    }
                                }
                            }
                            function activateSelectedItem() {
                                var seqPad = drumPadRepeater.itemAt(selectedIndex);
                                if (seqPad) {
                                    if (seqPad.currentSubNote === -1) {
                                        console.log("Activating position", selectedIndex, "on bar", _private.activeBar);
                                        // Then we're handling the position itself
                                        stepSettingsPopup.showStepSettings(_private.activePatternModel, _private.activeBar + _private.bankOffset, selectedIndex);
                                    } else {
                                        console.log("Activating subnote", seqPad.currentSubNote, "on position", selectedIndex, "on bar", _private.activeBar);
                                        // Then we're handling the specific subnote
                                        stepSettingsPopup.showStepSettings(_private.activePatternModel, _private.activeBar + _private.bankOffset, selectedIndex);
                                    }
                                }
                            }
                            function changeValue(valueName, howMuch, minValue, maxValue, defaultValue) {
                                if (drumPadRepeater.selectedIndex > -1) {
                                    var seqPad = drumPadRepeater.itemAt(selectedIndex);
                                    if (seqPad.currentSubNote > -1) {
                                        var currentValue = _private.activePatternModel.subnoteMetadata(_private.activeBar + _private.bankOffset, selectedIndex, seqPad.currentSubNote, valueName);
                                        if (currentValue === undefined) {
                                            currentValue = defaultValue;
                                        }
                                        //console.log("Current", valueName, currentValue);
                                        if (currentValue + howMuch >= minValue && currentValue + howMuch <= maxValue) {
                                            _private.activePatternModel.setSubnoteMetadata(_private.activeBar + _private.bankOffset, selectedIndex, seqPad.currentSubNote, valueName, currentValue + howMuch);
                                        }
                                    }
                                }
                            }
                            function velocityUp() {
                                changeValue("velocity", 1, 0, 127, 64);
                            }
                            function velocityDown() {
                                changeValue("velocity", -1, 0, 127, 64);
                            }
                            // An arbitrary upper value here (2^32) - technically it can be just any
                            // integer number, and we /could/ use Number.MAX_SAFE_INTEGER, but
                            // also... that's a very, very big number, and this is a number of 32th
                            // quarternotes, so even this "low" value is /really/ big... and input is
                            // an encoder, and it will take a really long time to reach that number.
                            // TODO Default value should probably be the current note duration... get that from PatternModel (which need it exposed)
                            function durationUp() {
                                changeValue("duration", 1, 0, 2147483647, 0);
                            }
                            function durationDown() {
                                changeValue("duration", -1, 0, 2147483647, 0);
                            }
                            PadNoteButton {
                                id: sequencerPad
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                // The indicator rect is 9 px tall, spaced by 1px, and we've got 5px margin, and so
                                // if we want 11px space between the bottom of this and the settings, 6px it is (which
                                // there's no reason to do arithmetics for, it's a fixed value anyway, but that's where
                                // this particular magic number comes from)
                                Layout.bottomMargin: component.showPatternSettings ? 6 : 0
                                playgrid: component
                                patternModel: _private.activePatternModel
                                activeBar:_private.activeBar
                                mostRecentlyPlayedNote: component.mostRecentlyPlayedNote
                                padNoteIndex: model.index
                                padNoteNumber: ((_private.activeBar + _private.bankOffset) * drumPadRepeater.count) + padNoteIndex
                                note: _private.activePatternModel ? _private.activePatternModel.getNote(_private.activeBar + _private.bankOffset, model.index) : null
                                isCurrent: model.index == drumPadRepeater.selectedIndex
                                onTapped: {
                                    if (drumPadRepeater.selectedIndex > -1) {
                                        var seqPad = drumPadRepeater.itemAt(drumPadRepeater.selectedIndex);
                                        seqPad.currentSubNote = -1;
                                    }
                                    drumPadRepeater.selectedIndex = model.index;
                                    sequencerPad.currentSubNote = subNoteIndex;
                                    drumPadRepeater.updateMostRecentFromSelection();
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
                                Timer {
                                    id: sequenderPadNoteApplicator
                                    repeat: false; running: false; interval: 0
                                    onTriggered: {
                                        sequencerPad.note = null;
                                        if (_private.activePatternModel) {
                                            sequencerPad.note = _private.activePatternModel.getNote(_private.activeBar + _private.bankOffset, model.index)
                                        }
                                        Qt.callLater(_private.updateUniqueCurrentRowNotes)
                                    }
                                }
                                Connections {
                                    target: _private
                                    onSequenceChanged: sequenderPadNoteApplicator.restart();
                                    onActivePatternChanged: sequenderPadNoteApplicator.restart();
                                    onActiveBarChanged: sequenderPadNoteApplicator.restart();
                                    onBankOffsetChanged: sequenderPadNoteApplicator.restart();
                                }
                                Connections {
                                    target: _private.sequence
                                    onModelReset: sequenderPadNoteApplicator.restart();
                                }
                                Connections {
                                    target: _private.activePatternModel
                                    onLastModifiedChanged: sequenderPadNoteApplicator.restart();
                                }
                                Connections {
                                    target: ZynQuick.PlayGridManager
                                    onCurrentMidiChannelChanged: sequenderPadNoteApplicator.restart();
                                }
                                Connections {
                                    target: zynthian.zynthiloops
                                    onSongChanged: sequenderPadNoteApplicator.restart();
                                }
                            }
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
                                    Layout.fillHeight: true
                                    Zynthian.PlayGridButton {
                                        text: "TRIG"
                                        checked: _private.activePatternModel && _private.activePatternModel.noteDestination === ZynQuick.PatternModel.SampleTriggerDestination
                                        onClicked: {
                                            component.setPatternProperty("noteDestination", ZynQuick.PatternModel.SampleTriggerDestination)
                                        }
                                    }
                                    Zynthian.PlayGridButton {
                                        text: "SYNTH"
                                        checked: _private.activePatternModel && _private.activePatternModel.noteDestination === ZynQuick.PatternModel.SynthDestination
                                        onClicked: {
                                            component.setPatternProperty("noteDestination", ZynQuick.PatternModel.SynthDestination)
                                        }
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillHeight: true
                                    Zynthian.PlayGridButton {
                                        text: "SLICE"
                                        checked: _private.activePatternModel && _private.activePatternModel.noteDestination === ZynQuick.PatternModel.SampleSlicedDestination
                                        onClicked: {
                                            component.setPatternProperty("noteDestination", ZynQuick.PatternModel.SampleSlicedDestination)
                                        }
                                    }
                                    Zynthian.PlayGridButton {
                                        text: "LOOP"
                                        checked: _private.activePatternModel && _private.activePatternModel.noteDestination === ZynQuick.PatternModel.SampleLoopedDestination
                                        onClicked: {
                                            component.setPatternProperty("noteDestination", ZynQuick.PatternModel.SampleLoopedDestination)
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Zynthian.PlayGridButton {
                                        text: "+"
                                        enabled: _private.noteLength < 6
                                        onClicked: {
                                            if (_private.noteLength < 6){
                                                component.setPatternProperty("noteLength", _private.noteLength + 1);
                                            }
                                        }
                                    }
                                    QQC2.Label {
                                        id:noteLengthLabel
                                        Layout.alignment: Qt.AlignHCenter
                                        text: {
                                            var text = "speed:\n"
                                            switch(_private.noteLength) {
                                                case 1:
                                                    text += "quarter";
                                                    break;
                                                case 2:
                                                    text += "half";
                                                    break;
                                                case 3:
                                                    text += "normal";
                                                    break;
                                                case 4:
                                                    text += "double";
                                                    break;
                                                case 5:
                                                    text += "quadruple";
                                                    break;
                                                case 6:
                                                    text += "octuple";
                                                    break;
                                            }
                                            return text
                                        }
                                    }

                                    Zynthian.PlayGridButton {
                                        text:"-"
                                        enabled: _private.noteLength > 1
                                        onClicked: {
                                            if (_private.noteLength > 1){
                                                component.setPatternProperty("noteLength", _private.noteLength - 1)
                                            }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Zynthian.PlayGridButton {
                                        text: "+"
                                        enabled: _private.availableBars > -1
                                        onClicked: {
                                            component.setPatternProperty("availableBars", _private.availableBars + 1)
                                        }
                                    }
                                    QQC2.Label {
                                        id:barsLabel
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredHeight: noteLengthLabel.height
                                        text: _private.availableBars + " Bars"
                                    }

                                    Zynthian.PlayGridButton {
                                        text:"-"
                                        enabled: _private.availableBars < 9
                                        onClicked: {
                                            component.setPatternProperty("availableBars", _private.availableBars - 1);
                                        }
                                    }
                                }

                                Zynthian.PlayGridButton {
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
                                    text: "paste\n" + (_private.clipBoard && _private.clipBoard.description !== "" ? _private.clipBoard.description : "")
                                    enabled: _private.clipBoard !== undefined
                                    onClicked: {
                                        _private.pasteInPlace(_private.activeBarModel.parentModel, _private.activeBar + _private.bankOffset, _private.activeBar + _private.bankOffset);
                                    }
                                }

                                Zynthian.PlayGridButton {
                                    text: "clear\n"
                                    onClicked: {
                                        _private.activeBarModel.parentModel.clearRow(_private.activeBar + _private.bankOffset);
                                        component.refreshSteps();
                                    }
                                }

                                //ColumnLayout {
                                    //Layout.fillHeight: true
                                    //Zynthian.PlayGridButton {
                                        //text: "part I"
                                        //checked: _private.bankOffset === 0
                                        //onClicked: {
                                            //component.setPatternProperty("bankOffset", 0)
                                        //}
                                    //}
                                    //Zynthian.PlayGridButton {
                                        //text: "part II"
                                        //checked: _private.bankOffset === 8
                                        //onClicked: {
                                            //component.setPatternProperty("bankOffset", 8)
                                        //}
                                    //}
                                //}
                            }
                        }

                        RowLayout {
                            Layout.preferredWidth: parent.width / 2
                            Layout.fillHeight: true
                            Repeater {
                                model: _private.bars
                                delegate: BarStep {
                                    availableBars: _private.availableBars
                                    activeBar: _private.activeBar
                                    playedBar: _private.activePatternModel ? _private.activePatternModel.playingRow - _private.activePatternModel.bankOffset : 0
                                    playgrid: component
                                }
                            }
                        }
                    }
                }
            }
            Item {
                id: patternsMenu
                visible: component.showPatternsMenu
                anchors {
                    fill: parent
                    leftMargin: -5
                    topMargin: Kirigami.Units.largeSpacing
                    bottomMargin: Kirigami.Units.largeSpacing
                    rightMargin: Kirigami.Units.largeSpacing * 2
                }
                Zynthian.Card {
                    anchors.fill: parent
                }
                MouseArea {
                    anchors {
                        fill: parent;
                        // Could use screen height, but also like... eh
                        margins: -2000
                    }
                    enabled: component.showPatternsMenu
                    onClicked: {
                        component.showPatternsMenu = false;
                    }
                }
                QQC2.ScrollView {
                    id:patternsMenuList
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.smallSpacing
                    }
                    QQC2.ScrollBar.horizontal.visible: false
                    QQC2.ScrollBar.vertical.x: patternsMenuListView.x + patternsMenuListView.width  - QQC2.ScrollBar.vertical.width// - root.rightPadding
                    contentItem: ListView {
                        id: patternsMenuListView
                        clip: true
                        cacheBuffer: height * 2 // a little brutish, but it means all our delegates always exist, which is what we're actually after here
                        model: _private.sequencePatternCount
                        Connections {
                            target: _private
                            onActivePatternChanged: {
                                patternsMenuListView.positionViewAtIndex(5 * Math.floor(_private.activePattern / 5), ListView.Beginning);
                            }
                        }

                        delegate: Rectangle {
                            id: patternsMenuItem
                            property QtObject thisPattern: _private.sequence ? _private.sequence.get(model.index) : null
                            property int thisPatternIndex: model.index
                            property int bankIndex: thisPattern ? thisPattern.bankOffset / 8 : 0
                            property int activePattern: _private.activePattern
                            property QtObject trackClipsModel: associatedTrack == null ? null : associatedTrack.clipsModel
                            property QtObject associatedTrack: null
                            property int associatedTrackIndex: -1
                            height: ListView.view.height * 0.2
                            width: ListView.view.width - patternsMenuList.QQC2.ScrollBar.vertical.width - Kirigami.Units.smallSpacing
                            Kirigami.Theme.inherit: false
                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                            color: activePattern === index ? Kirigami.Theme.focusColor : Kirigami.Theme.backgroundColor
                            border.color: Kirigami.Theme.textColor
                            function pickThisPattern() {
                                component.pickPattern(patternsMenuItem.thisPatternIndex)
                            }
                            function adoptTrackLayer() {
                                trackAdopterTimer.restart();
                            }
                            Timer {
                                id: trackAdopterTimer; interval: 1; repeat: false; running: false
                                onTriggered: {
                                    var foundTrack = null;
                                    var foundIndex = -1;
                                    for(var i = 0; i < zynthian.zynthiloops.song.tracksModel.count; ++i) {
                                        var track = zynthian.zynthiloops.song.tracksModel.getTrack(i);
                                        if (track && track.connectedPattern === patternsMenuItem.thisPatternIndex) {
                                            foundTrack = track;
                                            foundIndex = i;
                                            break;
                                        }
                                    }
                                    patternsMenuItem.associatedTrack = foundTrack;
                                    patternsMenuItem.associatedTrackIndex = foundIndex;
                                }
                            }
                            Connections {
                                target: patternsMenuItem.thisPattern
                                onLayerChanged: {
                                    patternsMenuItem.adoptTrackLayer();
                                }
                            }
                            Connections {
                                target: zynthian.zynthiloops.song.tracksModel
                                onConnectedSoundsCountChanged: patternsMenuItem.adoptTrackLayer()
                                onConnectedPatternsCountChanged: patternsMenuItem.adoptTrackLayer()
                            }
                            Connections {
                                target: zynthian.zynthiloops
                                onSongChanged: patternsMenuItem.adoptTrackLayer()
                            }
                            Connections {
                                target: patternsMenuItem.associatedTrack
                                onConnectedPatternChanged: patternsMenuItem.adoptTrackLayer()
                                onConnectedSoundChanged: patternsMenuItem.adoptTrackLayer()
                            }
                            Component.onCompleted: {
                                adoptTrackLayer();
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
                                                        patternsMenuItem.thisPattern.enabled = !patternsMenuItem.thisPattern.enabled
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
                                            text: "Track:"
                                            font.pixelSize: 15
                                            Kirigami.Theme.inherit: false
                                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                            color: Kirigami.Theme.textColor
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        Zynthian.PlayGridButton {
                                            Layout.fillHeight: true
                                            Layout.preferredHeight: patternsMenuItem.height / 2
                                            text: patternsMenuItem.associatedTrack ? patternsMenuItem.associatedTrack.name : "None Associated"
                                            enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                            onClicked: {
                                                trackPicker.pickTrack(patternsMenuItem.thisPatternIndex, patternsMenuItem.associatedTrackIndex);
                                            }
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillHeight: true
                                        Layout.minimumWidth: (parent.width / 8) * 3;
                                        Layout.maximumWidth: (parent.width / 8) * 3;

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: patternsMenuItem.height / 2
                                            Image {
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                source: _private.sequence ? "image://pattern/" + _private.sequence.objectName + "/" + patternsMenuItem.thisPatternIndex + "/" + patternsMenuItem.bankIndex + "?" + patternsMenuItem.thisPattern.lastModified : ""
                                                Rectangle {
                                                    anchors {
                                                        top: parent.top
                                                        bottom: parent.bottom
                                                    }
                                                    visible: patternsMenuItem.thisPattern ? patternsMenuItem.thisPattern.isPlaying : false
                                                    color: Kirigami.Theme.highlightColor
                                                    width: Math.max(1, Math.floor(widthFactor))
                                                    property double widthFactor: patternsMenuItem.thisPattern ? parent.width / (patternsMenuItem.thisPattern.width * patternsMenuItem.thisPattern.bankLength) : 1
                                                    x: patternsMenuItem.thisPattern ? patternsMenuItem.thisPattern.bankPlaybackPosition * widthFactor : 0
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

                                        Zynthian.PlayGridButton {
                                            id: soundButton
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: patternsMenuItem.height / 2
                                            enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex && patternsMenuItem.associatedTrack && patternsMenuItem.thisPattern.noteDestination === ZynQuick.PatternModel.SynthDestination
                                            opacity: enabled ? 1 : 0.7
                                            property string soundName
                                            Component.onCompleted: {
                                                updateSoundName();
                                            }
                                            Connections {
                                                target: patternsMenuItem
                                                onAssociatedTrackChanged: soundButton.updateSoundName();
                                            }
                                            Connections {
                                                target: zynthian.fixed_layers
                                                onList_updated: soundButton.updateSoundName();
                                            }
                                            Connections {
                                                target: patternsMenuItem.associatedTrack
                                                onChainedSoundsChanged: soundButton.updateSoundName();
                                                onConnectedSoundChanged: soundButton.updateSoundName();
                                            }
                                            function updateSoundName() {
                                                var text = "";

                                                if (patternsMenuItem.associatedTrack) {
                                                    for (var id in patternsMenuItem.associatedTrack.chainedSounds) {
                                                        if (patternsMenuItem.associatedTrack.chainedSounds[id] >= 0 &&
                                                            patternsMenuItem.associatedTrack.checkIfLayerExists(patternsMenuItem.associatedTrack.chainedSounds[id])) {
                                                            text = zynthian.fixed_layers.selector_list.getDisplayValue(patternsMenuItem.associatedTrack.chainedSounds[id]);
                                                            break;
                                                        }
                                                    }
                                                }

                                                soundName = text;
                                            }
                                            text: patternsMenuItem.thisPattern && patternsMenuItem.thisPattern.noteDestination === ZynQuick.PatternModel.SampleTriggerDestination
                                                ? "Sample Trigger Mode"
                                                : patternsMenuItem.thisPattern && patternsMenuItem.thisPattern.noteDestination === ZynQuick.PatternModel.SampleSlicedDestination
                                                    ? "Sample Slice Mode"
                                                    : patternsMenuItem.associatedTrack
                                                        ? patternsMenuItem.associatedTrack.connectedSound > -1 && soundName.length > 2
                                                            ? "Sound: " + soundName
                                                            : "No sound assigned - tap to select one"
                                                        : "Unassigned - playing to: " + _private.currentSoundName
                                            onClicked: {
                                                if (zynthian.session_dashboard.selectedTrack !== patternsMenuItem.associatedTrackIndex) {
                                                    zynthian.session_dashboard.selectedTrack = patternsMenuItem.associatedTrackIndex;
                                                }
                                                tracksViewDrawer.open();
                                            }
                                        }
                                    }
                                    //ColumnLayout {
                                        //Layout.fillHeight: true
                                        //Zynthian.PlayGridButton {
                                            //text: "part I"
                                            //enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                            //checked: patternsMenuItem.thisPattern.bankOffset === 0
                                            //onClicked: {
                                                //component.setPatternProperty("bankOffset", 0, patternsMenuItem.thisPatternIndex)
                                            //}
                                        //}
                                        //Zynthian.PlayGridButton {
                                            //text: "part II"
                                            //enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                            //checked: patternsMenuItem.thisPattern.bankOffset === 8
                                            //onClicked: {
                                                //component.setPatternProperty("bankOffset", 8, patternsMenuItem.thisPatternIndex)
                                            //}
                                        //}
                                    //}
                                    ColumnLayout {
                                        Layout.fillHeight: true
                                        Zynthian.PlayGridButton {
                                            text: "TRIG"
                                            enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                            checked: patternsMenuItem.thisPattern ? patternsMenuItem.thisPattern.noteDestination === ZynQuick.PatternModel.SampleTriggerDestination : false
                                            onClicked: {
                                                component.setPatternProperty("noteDestination", ZynQuick.PatternModel.SampleTriggerDestination, patternsMenuItem.thisPatternIndex)
                                            }
                                        }
                                        Zynthian.PlayGridButton {
                                            text: "SYNTH"
                                            enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                            checked: patternsMenuItem.thisPattern ? patternsMenuItem.thisPattern.noteDestination === ZynQuick.PatternModel.SynthDestination : false
                                            onClicked: {
                                                component.setPatternProperty("noteDestination", ZynQuick.PatternModel.SynthDestination, patternsMenuItem.thisPatternIndex)
                                            }
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillHeight: true
                                        Zynthian.PlayGridButton {
                                            text: "SLICE"
                                            enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                            checked: patternsMenuItem.thisPattern ? patternsMenuItem.thisPattern.noteDestination === ZynQuick.PatternModel.SampleSlicedDestination : false
                                            onClicked: {
                                                component.setPatternProperty("noteDestination", ZynQuick.PatternModel.SampleSlicedDestination, patternsMenuItem.thisPatternIndex)
                                            }
                                        }
                                        Zynthian.PlayGridButton {
                                            text: "LOOP"
                                            enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                            checked: patternsMenuItem.thisPattern ? patternsMenuItem.thisPattern.noteDestination === ZynQuick.PatternModel.SampleLoopedDestination : false
                                            onClicked: {
                                                component.setPatternProperty("noteDestination", ZynQuick.PatternModel.SampleLoopedDestination, patternsMenuItem.thisPatternIndex)
                                            }
                                        }
                                    }
                                    Zynthian.PlayGridButton {
                                        text: "copy\n"
                                        enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                        onClicked: {
                                            _private.copyRange(
                                                (patternsMenuItem.thisPatternIndex + 1) + " " + _private.sceneName,
                                                patternsMenuItem.thisPattern,
                                                patternsMenuItem.thisPattern.bankOffset,
                                                patternsMenuItem.thisPattern.bankOffset + patternsMenuItem.thisPattern.bankLength
                                            );
                                        }
                                    }
                                    Zynthian.PlayGridButton {
                                        text: "paste\n" + (_private.clipBoard && _private.clipBoard.description !== "" ? _private.clipBoard.description : "")
                                        enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex && _private.clipBoard !== undefined
                                        onClicked: {
                                            _private.pasteInPlace(patternsMenuItem.thisPattern, patternsMenuItem.thisPattern.bankOffset, _private.bankOffset + patternsMenuItem.thisPattern.bankLength);
                                            if (_private.activePatternModel == patternsMenuItem.thisPattern) {
                                                component.refreshSteps();
                                                component.setActiveBar(_private.activeBar)
                                            }
                                        }
                                    }
                                    Zynthian.PlayGridButton {
                                        text: "clear\n"
                                        enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                        onClicked: {
                                            patternsMenuItem.thisPattern.clear();
                                            patternsMenuItem.thisPattern.availableBars = 1;
                                            if (_private.activePatternModel == patternsMenuItem.thisPattern) {
                                                component.refreshSteps();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            QQC2.Popup {
                id: stepSettingsPopup
                y: drumPad.y - height - Kirigami.Units.largeSpacing
                x: Kirigami.Units.largeSpacing
                modal: true
                focus: true
                function showStepSettings(model, row, column) {
                    stepSettings.model = model;
                    stepSettings.row = row;
                    stepSettings.column = column;
                    stepSettingsPopup.open();
                }
                StepSettings {
                    id: stepSettings
                    anchors.fill: parent
                    implicitWidth: drumPad.width - Kirigami.Units.largeSpacing * 2
                }
            }
            QQC2.Drawer {
                id: tracksViewDrawer

                edge: Qt.BottomEdge
                modal: true

                width: parent.width
                height: Kirigami.Units.gridUnit * 15

                SessionDashboard.TracksViewSoundsBar {
                    anchors.fill: parent
                    property QtObject bottomDrawer: tracksViewDrawer
                }
            }
            QQC2.Popup {
                id: trackPicker
                function pickTrack(patternIndex, associatedTrackIndex) {
                    trackPicker.patternIndex = patternIndex;
                    trackPicker.associatedTrackIndex = associatedTrackIndex;
                    open();
                }
                modal: true
                x: Math.round(parent.width/2 - width/2)
                y: Math.round(parent.height/2 - height/2)
                width: parent.width * 0.9
                height: parent.height * 0.8
                property int patternIndex: -1
                property int associatedTrackIndex: -1
                ColumnLayout {
                    anchors.fill: parent
                    Kirigami.Heading {
                        Layout.fillWidth: true
                        text: qsTr("Move Pattern To Another Track")
                    }
                    GridLayout {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        columns: 4
                        Repeater {
                            model: zynthian.zynthiloops.song.tracksModel
                            delegate: Zynthian.PlayGridButton {
                                Layout.fillWidth: true
                                Layout.preferredWidth: trackPicker.width / 4
                                Layout.fillHeight: true
                                text: model.track.connectedPattern === trackPicker.patternIndex
                                    ? qsTr("Remove from:\nTrack %1").arg(model.id + 1)
                                    : qsTr("Move to:\nTrack %1").arg(model.id + 1)
                                onClicked: {
                                    if (model.track.connectedPattern === trackPicker.patternIndex) {
                                        // Remove the pattern from this track
                                        model.track.connectedPattern = -1;
                                    } else {
                                        // If we already were associated with a track, unassociate, otherwise it gets weird
                                        if (trackPicker.associatedTrackIndex > -1) {
                                            var oldTrack = zynthian.zynthiloops.song.tracksModel.getTrack(trackPicker.associatedTrackIndex);
                                            oldTrack.connectedPattern = -1;
                                        }
                                        // Add the pattern to this track
                                        model.track.connectedPattern = trackPicker.patternIndex;
                                    }
                                    trackPicker.close();
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
                                    trackPicker.close();
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

                function hideAllMenus() {
                    component.showPatternsMenu = false;
                }
                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                Zynthian.PlayGridButton {
                    text: _private.sequence && _private.sequence.soloPattern > -1
                        ? "Pattern:\n" + (_private.sequence.soloPattern + 1) + " " + _private.sceneName + "\nSOLO"
                        : "Pattern:\n" + (_private.activePattern + 1) + " " + _private.sceneName + "\n" + (_private.associatedTrack ? _private.associatedTrack.name : "(none)");
                    onClicked: {
                        sidebarRoot.hideAllMenus();
                        component.showPatternsMenu = !component.showPatternsMenu;
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                Zynthian.PlayGridButton {
                    icon.name: "arrow-up"
                    onClicked: {
                        sidebarRoot.hideAllMenus();
                        if (_private.octave + 1 < 11){
                            _private.octave =  _private.octave + 1;
                        } else {
                            _private.octave =  10;
                        }
                    }
                }

                QQC2.Label {
                    text: "Octave"
                    Layout.alignment: Qt.AlignHCenter
                }

                Zynthian.PlayGridButton {
                    icon.name: "arrow-down"
                    onClicked: {
                        sidebarRoot.hideAllMenus();
                        if (_private.octave - 1 > 0) {
                            _private.octave = _private.octave - 1;
                        } else {
                            _private.octave = 0;
                        }
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                Zynthian.PlayGridButton {
                    id:playPauseBtn
                    property var timeOnPressed
                    text: _private.sequence && _private.sequence.isPlaying ? "Pause" : "Play"
                    onPressed: {
                        sidebarRoot.hideAllMenus();
                        playPauseBtn.timeOnPressed = new Date();
                    }
                    onReleased: {
                        // pause
                        if (_private.sequence.isPlaying) {
                            _private.sequence.stopSequencePlayback();
                        }
                        // play
                        else {
                            var timeOnRelease = new Date();
                            if (timeOnRelease - playPauseBtn.timeOnPressed > 1500){
                                _private.sequence.resetSequence();
                            }
                            _private.sequence.startSequencePlayback();
                        }
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                Zynthian.PlayGridButton {
                    icon.name: component.listenForNotes
                        ? "dialog-ok"
                        : (component.mostRecentlyPlayedNote == undefined && component.heardNotes.length == 0) ? "" : "edit-clear-locationbar-ltr"
                    text: component.listenForNotes
                        ? "List-\nening"
                        : "Note:\n" + (component.heardNotes.length == 0
                            ? (component.mostRecentlyPlayedNote == undefined
                                ? "(all)"
                                : component.mostRecentlyPlayedNote.name + (component.mostRecentlyPlayedNote.octave - 1))
                            : component.heardNotes.length + " ♫")
                    visualPressAndHold: true
                    onClicked: {
                        sidebarRoot.hideAllMenus();
                        if (!pressingAndHolding) {
                            if (zynthian.backButtonPressed && _private.activePatternModel) {
                                component.ignoreNextBack = true;
                                _private.activePatternModel.clear();
                            } else {
                                if (component.listenForNotes) {
                                    component.listenForNotes = false;
                                    if (component.heardNotes.length === 1) {
                                        component.mostRecentlyPlayedNote = component.heardNotes[0];
                                        component.mostRecentNoteVelocity = component.heardVelocities[0];
                                        component.heardNotes = [];
                                        component.heardVelocities = [];
                                    } else {
                                        component.mostRecentlyPlayedNote = undefined;
                                    }
                                } else {
                                    component.mostRecentlyPlayedNote = undefined;
                                    component.heardNotes = [];
                                    component.heardVelocities = [];
                                }
                            }
                        }
                    }
                    onPressAndHold: {
                        // Clear the existing notes when starting listening
                        component.mostRecentlyPlayedNote = undefined;
                        component.heardNotes = [];
                        component.heardVelocities = [];
                        component.listenForNotes = true;
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                Zynthian.PlayGridButton {
                    id:sequencerSettingsBtn
                    icon.name: "configure"
                    onClicked: {
                        sidebarRoot.hideAllMenus();
                        component.showPatternSettings = !component.showPatternSettings;
                    }
                }
            }
            MouseArea {
                anchors {
                    fill: parent;
                    margins: -Kirigami.Units.largeSpacing
                }
                enabled: component.showPatternsMenu
                onClicked: {
                    component.showPatternsMenu = false;
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
                Layout.minimumWidth: Kirigami.Units.gridUnit * 5
                Kirigami.FormData.label: "Use Tap Position As Velocity"
                checked: _private.positionalVelocity
                onClicked: {
                    _private.positionalVelocity = !_private.positionalVelocity;
                }
                // TODO This wants to move to global when once the playground modules are created by pgm's instancing system
                Connections {
                    target: zynthian.playgrid
                    onBigKnobValueChanged: {
                        if (zynthian.playgrid.bigKnobValue < 0) {
                            for (var i = zynthian.playgrid.bigKnobValue; i < 0; ++i) {
                                _private.goLeft();
                            }
                        } else if (zynthian.playgrid.bigKnobValue > 0) {
                            for (var i = zynthian.playgrid.bigKnobValue; i > 0; --i) {
                                _private.goRight();
                            }
                        } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
                    }
                    onKnob1ValueChanged: {
                        if (zynthian.playgrid.knob1Value < 0) {
                            for (var i = zynthian.playgrid.knob1Value; i < 0; ++i) {
                                _private.knob1Down();
                            }
                        } else if (zynthian.playgrid.knob1Value > 0) {
                            for (var i = zynthian.playgrid.knob1Value; i > 0; --i) {
                                _private.knob1Up();
                            }
                        } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
                    }
                    onKnob2ValueChanged: {
                        if (zynthian.playgrid.knob2Value < 0) {
                            for (var i = zynthian.playgrid.knob2Value; i < 0; ++i) {
                                _private.knob2Down();
                            }
                        } else if (zynthian.playgrid.knob2Value > 0) {
                            for (var i = zynthian.playgrid.knob2Value; i > 0; --i) {
                                _private.knob2Up();
                            }
                        } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
                    }
                    onKnob3ValueChanged: {
                        if (zynthian.playgrid.knob3Value < 0) {
                            for (var i = zynthian.playgrid.knob3Value; i < 0; ++i) {
                                _private.knob3Down();
                            }
                        } else if (zynthian.playgrid.knob3Value > 0) {
                            for (var i = zynthian.playgrid.knob3Value; i > 0; --i) {
                                _private.knob3Up();
                            }
                        } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
                    }
                }
            }
        }
    }
}
