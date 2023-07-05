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
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox
import "../../pages/SessionDashboard/" as SessionDashboard

Zynthian.BasePlayGrid {
    id: component
    grid: drumsGrid
    settings: drumsGridSettings
    popup: drumsPopup
    sidebar: drumsGridSidebar
    name:'Stepsequencer'
    dashboardModel: _private.sequence
    isSequencer: true
    defaults: {
        "positionalVelocity": true
    }
    property bool isVisible: ["playgrid"].indexOf(zynqtgui.current_screen_id) >= 0
    persist: ["positionalVelocity"]
    additionalActions: [
        Kirigami.Action {
            text: qsTr("Load Sequence or Pattern...")
            onTriggered: {
                sequenceLoader.loadSequenceFromFile(_private.sequence.objectName);
            }
        },
        Kirigami.Action {
            text: qsTr("Export Sequence...")
            onTriggered: {
                sequenceLoader.saveSequenceToFile(_private.sequence.objectName);
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
                zynqtgui.show_modal("sequence_downloader")
            }
        }
    ]

    property bool ignoreNextBack: false
    cuiaCallback: function(cuia) {
        var backButtonClearPatternHelper = function(channelIndex) {
            if (zynqtgui.backButtonPressed) {
                component.ignoreNextBack = true;
                for (var partIndex = 0; partIndex < _private.partCount; ++partIndex) {
                    var pattern = _private.sequence.getByPart(channelIndex, partIndex);
                    if (pattern) {
                        pattern.clear();
                    }
                }
                return true;
            }
            return false;
        }
        var returnValue = false;

        if (sequenceLoader.opened) {
            returnValue = sequenceLoader.cuiaCallback(cuia);
        }

        if (returnValue === false) {
            var channelDelta = zynqtgui.channelsModActive ? 5 : 0

            switch (cuia) {
                case "START_RECORD":
                    if (_private.activePatternModel.recordLive) {
                        _private.activePatternModel.recordLive = false;
                        if (Zynthbox.PlayGridManager.metronomeActive) {
                            Zynthian.CommonUtils.stopMetronomeAndPlayback();
                        }
                    } else {
                        _private.activePatternModel.recordLive = true;
                        if (!Zynthbox.PlayGridManager.metronomeActive) {
                            Zynthian.CommonUtils.startMetronomeAndPlayback();
                        }
                    }
                    returnValue = true;
                    break;
                case "SWITCH_BACK_SHORT":
                case "SWITCH_BACK_BOLD":
                case "SWITCH_BACK_LONG":
                    if (ignoreNextBack) {
                        // When back button's been used for interaction elsewhere, ignore it here...
                        // Remember to set this, or things will look a bit weird
                        ignoreNextBack = false;
                    } else {
                        if (component.patternsMenuVisible) {
                            component.hidePatternsMenu();
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
                    if (zynqtgui.altButtonPressed) {
                        _private.octaveUp();
                    } else {
                        _private.nextBar();
                    }
                    break;
                case "SELECT_DOWN":
                    if (zynqtgui.altButtonPressed) {
                        _private.octaveDown();
                    } else {
                        _private.previousBar();
                    }
                    break;
                //case "SELECT_LEFT":
                    //returnValue = true;
                    //break;
                //case "SELECT_RIGHT":
                    //returnValue = true;
                    //break;
                case "NAVIGATE_LEFT":
                    if (zynqtgui.session_dashboard.selectedChannel > 0) {
                        zynqtgui.session_dashboard.selectedChannel = _private.activePatternModel.channelIndex - 1;
                    }
                    returnValue = true;
                    break;
                case "NAVIGATE_RIGHT":
                    if (zynqtgui.session_dashboard.selectedChannel < _private.channelCount) {
                        zynqtgui.session_dashboard.selectedChannel = _private.activePatternModel.channelIndex + 1;
                    }
                    returnValue = true;
                    break;
                case "SWITCH_SELECT_SHORT":
                    _private.activateSelectedItem();
                    returnValue = true;
                    break;
                case "CHANNEL_1":
                    returnValue = backButtonClearPatternHelper(0 + channelDelta);
                    break;
                case "CHANNEL_2":
                    returnValue = backButtonClearPatternHelper(1 + channelDelta);
                    break;
                case "CHANNEL_3":
                    returnValue = backButtonClearPatternHelper(2 + channelDelta);
                    break;
                case "CHANNEL_4":
                    returnValue = backButtonClearPatternHelper(3 + channelDelta);
                    break;
                case "CHANNEL_5":
                    returnValue = backButtonClearPatternHelper(4 + channelDelta);
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
                    _private.goRight();
                    returnValue = true;
                    break;
                case "KNOB3_DOWN":
                    _private.goLeft();
                    returnValue = true;
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
    signal showNoteSettingsPopup(QtObject patternModel, int firstBar, int lastBar, var midiNoteFilter);

    property var mostRecentlyPlayedNote
    property var mostRecentNoteVelocity
    property bool listenForNotes: false
    property var heardNotes: []
    property var heardVelocities: []
    property var currentRowUniqueNotes: []
    property var currentBarNotes: []
    property var currentBankNotes: []

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
        var patternObject = _private.sequence.get(patternIndex);
        if (patternObject.channelIndex > -1 && patternObject.partIndex > -1) {
            zynqtgui.session_dashboard.selectedChannel = patternObject.channelIndex;
            var channel = zynqtgui.sketchpad.song.channelsModel.getChannel(patternObject.channelIndex);
            channel.selectedPart = patternObject.partIndex;
        }
    }

    QtObject {
        id:_private;
        // Yes, this is a hack - if we don't do this, we'll forever be rebuilding the patterns popup etc when the sequence and pattern changes, which is all manner of expensive
        readonly property int channelCount: 10
        readonly property int partCount: 5
        readonly property int activeBarModelWidth: 16

        property QtObject sequence
        property int activePattern: sequence && !sequence.isLoading && sequence.count > 0 ? sequence.activePattern : -1
        property QtObject activePatternModel: sequence && !sequence.isLoading && sequence.count > 0 ? sequence.activePatternObject : null;
        property QtObject activeBarModel: activePatternModel && activeBar > -1 && activePatternModel.data(activePatternModel.index(activeBar + bankOffset, 0), activePatternModel.roles["rowModel"])
            ? activePatternModel.data(activePatternModel.index(activeBar + bankOffset, 0), activePatternModel.roles["rowModel"])
            : null;

        property bool patternHasUnsavedChanged: false
        property bool positionalVelocity: true
        property var bars: [0,1,2,3,4,5,6,7]
        // This is the top bank we have available in any pattern (that is, the upper limit for any pattern's bankOffset value)
        property int bankLimit: 1
        property var clipBoard
        property int gridStartNote: 48

        // Properties inherent to the active pattern (set these through component.setPatternProperty)
        property int noteLength: sequence && sequence.activePatternObject ? sequence.activePatternObject.noteLength : 0
        property int layer: sequence && sequence.activePatternObject ? sequence.activePatternObject.layer : 0
        property var availableBars: sequence && sequence.activePatternObject ? sequence.activePatternObject.availableBars : 0
        property var activeBar: sequence && sequence.activePatternObject ? sequence.activePatternObject.activeBar : -1
        property int bankOffset: sequence && sequence.activePatternObject ? sequence.activePatternObject.bankOffset : 0
        property string bankName: sequence && sequence.activePatternObject ? sequence.activePatternObject.bank : "?"
        property string sceneName: zynqtgui.sketchpad.song.scenesModel.selectedTrackName
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
                    _private.associatedChannel = zynqtgui.sketchpad.song.channelsModel.getChannel(_private.activePatternModel.channelIndex);
                    _private.associatedChannelIndex =  _private.activePatternModel.channelIndex;
                } else {
                    _private.updateChannel();
                }
                Qt.callLater(_private.updateUniqueCurrentRowNotes)
            }
        }

        property QtObject currentChannel: zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.session_dashboard.selectedChannel)
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

        onActivePatternChanged:{
            updateChannel();
            while (hasSelection) {
                deselectSelectedItem();
            }
        }

        onLayerChanged: {
            updateChannel();
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

        function octaveUp() {
            // Don't scroll past the end
            if (_private.activePatternModel.gridModelStartNote < 112) {
                // 4 being the width of the grid - heuristics are a go, but also the thing is 16 long so...
                _private.activePatternModel.gridModelStartNote = _private.activePatternModel.gridModelStartNote + 4;
                _private.activePatternModel.gridModelEndNote = _private.activePatternModel.gridModelStartNote + 16;
            }
        }
        function octaveDown() {
            // Don't scroll past the end
            if (_private.activePatternModel.gridModelStartNote > 0) {
                // 4 being the width of the grid - heuristics are a go, but also the thing is 16 long so...
                _private.activePatternModel.gridModelStartNote = _private.activePatternModel.gridModelStartNote - 4;
                _private.activePatternModel.gridModelEndNote = _private.activePatternModel.gridModelStartNote + 16;
            }
        }

        readonly property var noteLengthNames: {
            1: "1/4th",
            2: "1/8th",
            3: "1/16th",
            4: "1/32th",
            5: "1/64th",
            6: "1/128th"
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
            model.endLongOperation();
            component.refreshSteps();
        }
        function adoptSequence() {
            console.log("Adopting the scene sequence");
            var sequence = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName);
            if (_private.sequence != sequence) {
                console.log("Scene has changed, switch places!");
                _private.sequence = sequence;
            }
        }
        function updateUniqueCurrentRowNotes() {
            component.currentRowUniqueNotes = activePatternModel.uniqueRowNotes(activeBar + bankOffset);
            var currentBarNotes = [];
            var currentBankNotes = [];
            for (var bar = 0; bar < _private.activePatternModel.availableBars; ++bar) {
                var barNotes = _private.activePatternModel.getRow(_private.bankOffset + bar);
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
        target: zynqtgui.sketchpad.song.channelsModel
        onConnectedSoundsCountChanged: _private.updateChannel()
        onConnectedPatternsCountChanged: _private.updateChannel()
    }
    Connections {
        target: _private.associatedChannel
        onConnectedPatternChanged: _private.updateChannel()
        onConnectedSoundChanged: _private.updateChannel()
    }
    Connections {
        target: zynqtgui.sketchpad
        onSongChanged: {
            _private.adoptSequence();
            _private.updateChannel();
        }
    }
    Connections {
        target: zynqtgui.sketchpad.song.scenesModel
        onSelectedTrackNameChanged: Qt.callLater(_private.adoptSequence) // Makes scene change look smoother
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
        target: Zynthbox.PlayGridManager
        onDashboardItemPicked: {
            adoptSequence(); // just to be safe...
            if (component.dashboardModel === model) {
                _private.sequence.activePattern = index;
                var foundIndex = -1;
                for(var i = 0; i < zynqtgui.sketchpad.song.channelsModel.count; ++i) {
                    var channel = zynqtgui.sketchpad.song.channelsModel.getChannel(i);
                    if (channel && channel.connectedPattern === index) {
                        foundIndex = i;
                        break;
                    }
                }
                if (foundIndex > -1 && zynqtgui.session_dashboard.selectedChannel !== foundIndex) {
                    zynqtgui.session_dashboard.selectedChannel = foundIndex;
                }
            }
        }
        onMostRecentlyChangedNotesChanged: {
            if (component.listenForNotes && _private.activePatternModel) {
                var mostRecentNoteData = Zynthbox.PlayGridManager.mostRecentlyChangedNotes[Zynthbox.PlayGridManager.mostRecentlyChangedNotes.length - 1];
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
    Connections {
        target: Zynthbox.MidiRouter
        enabled: component.isVisible && !Zynthbox.PlayGridManager.metronomeActive
        onNoteChanged: {
            if (port == 0 && midiChannel === _private.activePatternModel.midiChannel) {
                if (setOn == true) {
                    // Count up one tick for a note on message
                    component.noteListeningActivations = component.noteListeningActivations + 1;
                    // Create a new note based on the new thing that just arrived, but only if it's an on note
                    var newNote = component.getNote(midiNote, midiChannel);
                    var existingIndex = component.heardNotes.indexOf(newNote);
                    if (existingIndex > -1) {
                        component.noteListeningNotes.splice(existingIndex, 1);
                        component.noteListeningVelocities.splice(existingIndex, 1);
                    }
                    component.noteListeningNotes.push(newNote);
                    component.noteListeningVelocities.push(velocity);
                } else if (setOn == false) {
                    // Count down one for a note off message
                    component.noteListeningActivations = component.noteListeningActivations - 1;
                }
                if (component.noteListeningActivations === 0) {
                    // Now, if we're back down to zero, then we've had all the notes released, and should assign all the heard notes to the heard notes thinger
                    component.heardNotes = component.noteListeningNotes;
                    component.heardVelocities = component.noteListeningVelocities;
                    component.mostRecentlyPlayedNote = undefined;
                    component.noteListeningNotes = [];
                    component.noteListeningVelocities = [];
                } else if (component.noteListeningActivations < 0) {
                    console.debug("stepsequencer: Problem, we've received too many off notes compared to on notes, this is bad and shouldn't really be happening.");
                    component.noteListeningActivations = 0;
                    component.noteListeningNotes = [];
                    component.noteListeningVelocities = [];
                    component.mostRecentlyPlayedNote = undefined;
                }
            }
        }
    }
    property int noteListeningActivations: 0
    property var noteListeningNotes: []
    property var noteListeningVelocities: []

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
            id: drumsGridContainer
            anchors.margins: 5
            objectName: "drumsGrid"
            ColumnLayout {
                id:gridColumnLayout
                spacing: 0
                anchors.fill: parent;

                DrumsGrid {
                    id: drumsGridItem
                    model: _private.activePatternModel ? (_private.activePatternModel.noteDestination === Zynthbox.PatternModel.SampleSlicedDestination ? _private.activePatternModel.clipSliceNotes : _private.activePatternModel.gridModel) : null
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
                    onNotePressAndHold: {
                        if (note) {
                            noteSettingsPopup.showSettings(_private.activePatternModel, _private.activePatternModel.activeBar + _private.activePatternModel.bankOffset, _private.activePatternModel.activeBar + _private.activePatternModel.bankOffset, [note.midiNote]);
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
                    Connections {
                        target: _private
                        onGoLeft: drumPadRepeater.goPrevious();
                        onGoRight: drumPadRepeater.goNext();
                        onDeselectSelectedItem: drumPadRepeater.deselectSelectedItem();
                        onActivateSelectedItem: drumPadRepeater.activateSelectedItem();
                        onKnob0Up: drumPadRepeater.velocityUp();
                        onKnob0Down: drumPadRepeater.velocityDown();
                        onKnob1Up: drumPadRepeater.durationUp();
                        onKnob1Down: drumPadRepeater.durationDown();
                        onKnob2Up: drumPadRepeater.delayUp();
                        onKnob2Down: drumPadRepeater.delayDown();
                    }
                    Connections {
                        target: stepSettings
                        onChangeSubnote: {
                            var seqPad = drumPadRepeater.itemAt(drumPadRepeater.selectedIndex);
                            if (seqPad) {
                                seqPad.currentSubNote = newSubnote;
                                Qt.callLater(drumPadRepeater.updateMostRecentFromSelection);
                            }
                        }
                    }
                    Connections {
                        target: noteSettings
                        onChangeStep: {
                            var drumPadStartStep = ((_private.activeBar + _private.bankOffset) * drumPadRepeater.count);
                            if (newStep === -1) {
                                var seqPad = drumPadRepeater.itemAt(drumPadRepeater.selectedIndex);
                                if (seqPad.currentSubNote > -1) {
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
                            noteLengthVisualiser.singleStepLength = noteLengthVisualiser.noteLengths[_private.activePatternModel.noteLength]
                            noteLengthVisualiser.totalStepLength = noteDuration / noteLengthVisualiser.singleStepLength;
                            noteLengthVisualiser.lastLoopIndex = (noteLengthVisualiser.totalStepLength + noteOffset) / 16;
                            noteLengthVisualiser.noteDuration = noteDuration;
                            noteLengthVisualiser.noteOffset = noteOffset;
                            noteLengthVisualiser.noteDelay = noteDelay;
                            if (noteDelay !== 0 && noteDuration === 0) {
                                // So we also visualise default-duration notes which have been moved around
                                noteLengthVisualiser.noteDuration = noteLengthVisualiser.singleStepLength;
                            }
                            noteLengthVisualiser.note = note;
                        }
                        property var noteLengths: {
                            1: 32,
                            2: 16,
                            3: 8,
                            4: 4,
                            5: 2,
                            6: 1
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
                            value: zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.session_dashboard.selectedChannel)
                            when: drumpadLoopVisualiser.visible
                            delayed: true
                        }
                        property QtObject sample: channel ? channel.getClipsModelByPart(channel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex) : null
                        Zynthian.SampleVisualiser {
                            anchors.fill: parent
                            sample: parent.visible ? drumpadLoopVisualiser.sample : null
                            channelAudioType: drumpadLoopVisualiser.channel === null ? "" : drumpadLoopVisualiser.channel.channelAudioType
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
                                stepSettings.currentSubNote = seqPad ? seqPad.currentSubNote : -1;
                                if (noteSettings.visible) {
                                    noteSettings.currentSubNote = seqPad ? seqPad.currentSubNote : -1;
                                }
                                if (seqPad && seqPad.currentSubNote > -1) {
                                    var noteLength = _private.activePatternModel.subnoteMetadata(_private.activeBar + _private.bankOffset, selectedIndex, seqPad.currentSubNote, "duration");
                                    if (!noteLength) {
                                        noteLength = 0;
                                    }
                                    var noteDelay = _private.activePatternModel.subnoteMetadata(_private.activeBar + _private.bankOffset, selectedIndex, seqPad.currentSubNote, "delay");
                                    if (!noteDelay) {
                                        noteDelay = 0;
                                    }
                                    noteLengthVisualiser.visualiseNote(note.subnotes[seqPad.currentSubNote], noteLength, noteDelay, selectedIndex % 16);
                                } else {
                                    noteLengthVisualiser.clearVisualisation();
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
                                    if (stepSettings.visible) {
                                        changeStep = false;
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
                                    if (stepSettings.visible) {
                                        changeStep = false;
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
                                } else if (stepSettingsPopup.visible) {
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
                                if (noteSettingsPopup.visible) {
                                    // do something? or no? probably no
                                } else {
                                    var seqPad = drumPadRepeater.itemAt(selectedIndex);
                                    if (seqPad) {
                                        if (seqPad.currentSubNote === -1) {
                                            console.log("Activating position", selectedIndex, "on bar", _private.activeBar);
                                            // Then we're handling the position itself
                                            if (stepSettingsPopup.visible) {
                                                stepSettingsPopup.close();
                                            } else {
                                                stepSettingsPopup.showStepSettings(_private.activePatternModel, _private.activeBar + _private.bankOffset, selectedIndex);
                                            }
                                        } else {
                                            console.log("Activating subnote", seqPad.currentSubNote, "on position", selectedIndex, "on bar", _private.activeBar);
                                            // Then we're handling the specific subnote
                                            if (stepSettingsPopup.visible) {
                                                stepSettingsPopup.close();
                                            } else {
                                                stepSettingsPopup.showStepSettings(_private.activePatternModel, _private.activeBar + _private.bankOffset, selectedIndex);
                                            }
                                        }
                                    }
                                }
                            }
                            function changeStepValue(barIndex, stepIndex, indicesToChange, valueName, howMuch, minValue, maxValue, defaultValue) {
                                for (var i = 0; i < indicesToChange.length; ++i) {
                                    var currentValue = _private.activePatternModel.subnoteMetadata(barIndex, stepIndex, indicesToChange[i], valueName);
                                    if (currentValue === undefined || currentValue === 0 || isNaN(currentValue)) {
                                        currentValue = defaultValue;
                                    }
                                    //console.log("Current", valueName, currentValue);
                                    if (currentValue + howMuch >= minValue && currentValue + howMuch <= maxValue) {
                                        _private.activePatternModel.setSubnoteMetadata(barIndex, stepIndex, indicesToChange[i], valueName, currentValue + howMuch);
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
                                        var noteLength = _private.activePatternModel.subnoteMetadata(_private.activeBar + _private.bankOffset, drumPadRepeater.selectedIndex, seqPad.currentSubNote, "duration");
                                        if (!noteLength) {
                                            noteLength = 0;
                                        }
                                        var noteDelay = _private.activePatternModel.subnoteMetadata(_private.activeBar + _private.bankOffset, drumPadRepeater.selectedIndex, seqPad.currentSubNote, "delay");
                                        if (!noteDelay) {
                                            noteDelay = 0;
                                        }
                                        noteLengthVisualiser.visualiseNote(seqPad.note.subnotes[seqPad.currentSubNote], noteLength, noteDelay, drumPadRepeater.selectedIndex % 16);
                                    }
                                } else if (noteSettings.visible) {
                                    // Only do the "change all the things" if note settings is visible... could otherwise, but confusion...
                                    var visibleStepIndices = noteSettings.visibleStepIndices();
                                    for (var barIndex in visibleStepIndices) {
                                        var barArray = visibleStepIndices[barIndex];
                                        for (var stepIndex in barArray) {
                                            var visibleSubNotes = barArray[stepIndex];
                                            if (visibleSubNotes && visibleSubNotes.length > 0) {
                                                changeStepValue(barIndex, stepIndex, visibleSubNotes, valueName, howMuch, minValue, maxValue, defaultValue);
                                            }
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
                            // TODO Default value should probably be the current note duration... get that from PatternModel (which need it exposed)
                            function durationUp() {
                                changeValue("duration", 1, 0, 1024, 0);
                            }
                            function durationDown() {
                                changeValue("duration", -1, 0, 1024, 0);
                            }
                            function delayUp() {
                                if (stepSettings.visible) {
                                    changeValue("delay", 1, -stepSettings.stepDuration + 1, stepSettings.stepDuration - 1, 0);
                                } else if (noteSettings.visible) {
                                    changeValue("delay", 1, -noteSettings.stepDuration + 1, -noteSettings.stepDuration - 1, 0);
                                } else {
                                    var seqPad = drumPadRepeater.itemAt(drumPadRepeater.selectedIndex);
                                    if (seqPad && seqPad.note && seqPad.currentSubNote > -1) {
                                        var stepDuration = noteLengthVisualiser.noteLengths[_private.activePatternModel.noteLength]
                                        changeValue("delay", 1, -stepDuration + 1, stepDuration - 1, 0);
                                    }
                                }
                            }
                            function delayDown() {
                                if (stepSettings.visible) {
                                    changeValue("delay", -1, -stepSettings.stepDuration + 1, stepSettings.stepDuration - 1, 0);
                                } else if (noteSettings.visible) {
                                    changeValue("delay", -1, -noteSettings.stepDuration + 1, noteSettings.stepDuration - 1, 0);
                                } else {
                                    var seqPad = drumPadRepeater.itemAt(drumPadRepeater.selectedIndex);
                                    if (seqPad && seqPad.note && seqPad.currentSubNote > -1) {
                                        var stepDuration = noteLengthVisualiser.noteLengths[_private.activePatternModel.noteLength]
                                        changeValue("delay", -1, -stepDuration + 1, stepDuration - 1, 0);
                                    }
                                }
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
                                patternModel: _private.activePatternModel
                                activeBar:_private.activeBar
                                mostRecentlyPlayedNote: component.mostRecentlyPlayedNote
                                padNoteIndex: model.index
                                padNoteNumber: ((_private.activeBar + _private.bankOffset) * drumPadRepeater.count) + padNoteIndex
                                note: visible && _private.activePatternModel ? _private.activePatternModel.getNote(_private.activeBar + _private.bankOffset, model.index) : null
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
                                    stepSettingsPopup.showStepSettings(_private.activePatternModel, _private.activeBar + _private.bankOffset, model.index);
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
                                    if (_private.activePatternModel) {
                                        sequencerPad.note = _private.activePatternModel.getNote(_private.activeBar + _private.bankOffset, model.index)
                                    }
                                    Qt.callLater(_private.updateUniqueCurrentRowNotes)
                                }
                                Timer {
                                    id: sequencerPadNoteApplicator
                                    repeat: false; running: false; interval: 1
                                    onTriggered: {
                                        if (root.visible) {
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
                                    target: _private
                                    onSequenceChanged: sequencerPadNoteApplicator.restart();
                                    onActivePatternChanged: sequencerPadNoteApplicator.restart();
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
                                    onCurrentMidiChannelChanged: sequencerPadNoteApplicator.restart();
                                }
                                Connections {
                                    target: zynqtgui.sketchpad
                                    onSongChanged: sequencerPadNoteApplicator.restart();
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

//                                 ColumnLayout {
//                                     Layout.fillHeight: true
//                                     Zynthian.PlayGridButton {
//                                         text: "TRIG"
//                                         checked: _private.activePatternModel && _private.activePatternModel.noteDestination === Zynthbox.PatternModel.SampleTriggerDestination
//                                         onClicked: {
//                                             if (checked) {
//                                                 _private.associatedChannel.channelAudioType = "external";
//                                             } else {
//                                                 _private.associatedChannel.channelAudioType = "sample-trig";
//                                             }
//                                         }
//                                     }
//                                     Zynthian.PlayGridButton {
//                                         text: "SYNTH"
//                                         checked: _private.activePatternModel && _private.activePatternModel.noteDestination === Zynthbox.PatternModel.SynthDestination
//                                         onClicked: {
//                                             if (checked) {
//                                                 _private.associatedChannel.channelAudioType = "external";
//                                             } else {
//                                                 _private.associatedChannel.channelAudioType = "synth";
//                                             }
//                                         }
//                                     }
//                                 }
//                                 ColumnLayout {
//                                     Layout.fillHeight: true
//                                     Zynthian.PlayGridButton {
//                                         text: "SLICE"
//                                         checked: _private.activePatternModel && _private.activePatternModel.noteDestination === Zynthbox.PatternModel.SampleSlicedDestination
//                                         onClicked: {
//                                             if (checked) {
//                                                 _private.associatedChannel.channelAudioType = "external";
//                                             } else {
//                                                 _private.associatedChannel.channelAudioType = "sample-slice";
//                                             }
//                                         }
//                                     }
//                                     Zynthian.PlayGridButton {
//                                         text: "LOOP"
//                                         checked: _private.activePatternModel && _private.activePatternModel.noteDestination === Zynthbox.PatternModel.SampleLoopedDestination
//                                         onClicked: {
//                                             if (checked) {
//                                                 _private.associatedChannel.channelAudioType = "external";
//                                             } else {
//                                                 _private.associatedChannel.channelAudioType = "sample-loop";
//                                             }
//                                         }
//                                     }
//                                 }

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
                                        enabled: _private.availableBars < 8
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
                                        enabled: _private.availableBars > 1
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
                            id: patternBarsLayout
                            Layout.preferredWidth: parent.width / 2
                            Layout.fillHeight: true
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
                                    playedBar: visible && _private.activePatternModel ? _private.activePatternModel.playingRow - _private.activePatternModel.bankOffset : 0
                                    playgrid: component
                                }
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
                    ColumnLayout {
                        anchors {
                            fill: parent
                            margins: Kirigami.Units.smallSpacing
                        }
                        QQC2.ScrollView {
                            id:patternsMenuList
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            QQC2.ScrollBar.horizontal.visible: false
                            QQC2.ScrollBar.vertical.x: patternsMenuListView.x + patternsMenuListView.width  - QQC2.ScrollBar.vertical.width// - root.rightPadding
                            contentItem: ListView {
                                id: patternsMenuListView
                                clip: true
                                cacheBuffer: height * 2 // a little brutish, but it means all our delegates always exist, which is what we're actually after here
                                model: _private.channelCount
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
                                            patternsMenuListView.positionViewAtIndex(5 * Math.floor(_private.activePatternModel.channelIndex / 5), ListView.Beginning);
                                        }
                                    }
                                }

                                delegate: Rectangle {
                                    id: patternsMenuItem
                                    property QtObject thisPattern: _private.sequence && associatedChannel ? _private.sequence.getByPart(model.index, associatedChannel.selectedPart) : null
                                    property int thisPatternIndex: _private.sequence ? _private.sequence.indexOf(thisPattern) : -1
                                    property int activePattern: _private.activePattern
                                    property QtObject channelClipsModel: associatedChannel == null ? null : associatedChannel.clipsModel
                                    property QtObject associatedChannel: zynqtgui.sketchpad.song && zynqtgui.sketchpad.song.channelsModel ? zynqtgui.sketchpad.song.channelsModel.getChannel(model.index) : null
                                    property int associatedChannelIndex: model.index
                                    height: ListView.view.height * 0.2
                                    width: ListView.view.width - patternsMenuList.QQC2.ScrollBar.vertical.width - Kirigami.Units.smallSpacing
                                    Kirigami.Theme.inherit: false
                                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                    color: _private.activePatternModel && _private.activePatternModel.channelIndex === index ? Kirigami.Theme.focusColor : Kirigami.Theme.backgroundColor
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
                                                                var associatedClip = patternsMenuItem.associatedChannel.getClipsModelByPart(patternsMenuItem.thisPattern.partIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex);
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
                                                    text: patternsMenuItem.thisPattern ? qsTr("Clip %1%2").arg(patternsMenuItem.associatedChannelIndex + 1).arg(patternsMenuItem.thisPattern.partName) : "(no part)"
                                                    enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                                    onClicked: {
                                                        partPicker.pickPart(patternsMenuItem.associatedChannelIndex);
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
                                                        property bool sampleVisible: parent.visible && (patternsMenuItem.thisPattern.noteDestination === Zynthbox.PatternModel.SampleTriggerDestination || patternsMenuItem.thisPattern.noteDestination === Zynthbox.PatternModel.SampleSlicedDestination)
                                                        property QtObject channel: null
                                                        Binding {
                                                            target: patternPopupSampleVisualiser
                                                            property: "channel"
                                                            value: patternsMenuItem.associatedChannel
                                                            when: patternPopupSampleVisualiser.sampleVisible
                                                            delayed: true
                                                        }
                                                        property QtObject sample: channel && channel.samples ? channel.samples[_private.activePattern] : null
                                                        Zynthian.SampleVisualiser {
                                                            anchors.fill: parent
                                                            opacity: 0.2
                                                            sample: parent.visible ? patternPopupSampleVisualiser.sample : null
                                                            channelAudioType: patternPopupSampleVisualiser.channel === null ? "" : patternPopupSampleVisualiser.channel.channelAudioType
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
                                                        onChainedSoundsChanged: updateSoundNameTimer.restart();
                                                        onConnectedSoundChanged: updateSoundNameTimer.restart();
                                                    }
                                                    function updateSoundName() {
                                                        var text = "";

                                                        if (patternsMenuItem.associatedChannel) {
                                                            for (var id in patternsMenuItem.associatedChannel.chainedSounds) {
                                                                if (patternsMenuItem.associatedChannel.chainedSounds[id] >= 0 &&
                                                                    patternsMenuItem.associatedChannel.checkIfLayerExists(patternsMenuItem.associatedChannel.chainedSounds[id])) {
                                                                    text = zynqtgui.fixed_layers.selector_list.getDisplayValue(patternsMenuItem.associatedChannel.chainedSounds[id]);
                                                                    break;
                                                                }
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
                                                            : patternsMenuItem.thisPattern && patternsMenuItem.thisPattern.noteDestination === Zynthbox.PatternModel.SampleSlicedDestination
                                                                ? "Sample Slice Mode"
                                                                : patternsMenuItem.thisPattern && patternsMenuItem.thisPattern.noteDestination === Zynthbox.PatternModel.ExternalDestination
                                                                    ? qsTr("External Midi Mode: Channel %1").arg(patternsMenuItem.thisPattern.externalMidiChannel > -1 ? patternsMenuItem.thisPattern.externalMidiChannel + 1 : patternsMenuItem.thisPattern.midiChannel + 1)
                                                                    : patternsMenuItem.associatedChannel
                                                                        ? patternsMenuItem.associatedChannel.connectedSound > -1 && soundName.length > 2
                                                                            ? "Sound: " + soundName
                                                                            : "No sound assigned - tap to select one"
                                                                : "Unassigned - playing to: " + _private.currentSoundName
                                                        : ""
                                                    onClicked: {
                                                        if (zynqtgui.session_dashboard.selectedChannel !== patternsMenuItem.associatedChannelIndex) {
                                                            zynqtgui.session_dashboard.selectedChannel = patternsMenuItem.associatedChannelIndex;
                                                        }
                                                        channelsViewDrawer.open();
                                                    }
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: patternsMenuItem.height / 2
                                                    Item {
                                                        id: patternPopupLoopVisualiser
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        visible: parent.visible && patternsMenuItem.thisPattern.noteDestination === Zynthbox.PatternModel.SampleLoopedDestination
                                                        property QtObject channel: null
                                                        Binding {
                                                            target: patternPopupLoopVisualiser
                                                            property: "channel"
                                                            value: patternsMenuItem.associatedChannel
                                                            when: patternPopupLoopVisualiser.visible
                                                            delayed: true
                                                        }
                                                        property QtObject sample: channel ? channel.getClipsModelByPart(channel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex) : null
                                                        Zynthian.SampleVisualiser {
                                                            anchors.fill: parent
                                                            sample: parent.visible ?  patternPopupLoopVisualiser.sample : null
                                                            channelAudioType: patternPopupLoopVisualiser.channel === null ? "" : patternPopupLoopVisualiser.channel.channelAudioType
                                                        }
                                                    }
                                                    Image {
                                                        Layout.fillHeight: true
                                                        Layout.fillWidth: true
                                                        visible: parent.visible && patternsMenuItem.thisPattern.noteDestination !== Zynthbox.PatternModel.SampleLoopedDestination
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
                                            //ColumnLayout {
                                                //Layout.fillHeight: true
                                                //Zynthian.PlayGridButton {
                                                    //text: "TRIG"
                                                    //enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                                    //checked: patternsMenuItem.thisPattern ? patternsMenuItem.thisPattern.noteDestination === Zynthbox.PatternModel.SampleTriggerDestination : false
                                                    //onClicked: {
                                                        //if (checked) {
                                                            //patternsMenuItem.associatedChannel.channelAudioType = "external";
                                                        //} else {
                                                            //patternsMenuItem.associatedChannel.channelAudioType = "sample-trig";
                                                        //}
                                                    //}
                                                //}
                                                //Zynthian.PlayGridButton {
                                                    //text: "SYNTH"
                                                    //enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                                    //checked: patternsMenuItem.thisPattern ? patternsMenuItem.thisPattern.noteDestination === Zynthbox.PatternModel.SynthDestination : false
                                                    //onClicked: {
                                                        //if (checked) {
                                                            //patternsMenuItem.associatedChannel.channelAudioType = "external";
                                                        //} else {
                                                            //patternsMenuItem.associatedChannel.channelAudioType = "synth";
                                                        //}
                                                    //}
                                                //}
                                            //}
                                            //ColumnLayout {
                                                //Layout.fillHeight: true
                                                //Zynthian.PlayGridButton {
                                                    //text: "SLICE"
                                                    //enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                                    //checked: patternsMenuItem.thisPattern ? patternsMenuItem.thisPattern.noteDestination === Zynthbox.PatternModel.SampleSlicedDestination : false
                                                    //onClicked: {
                                                        //if (checked) {
                                                            //patternsMenuItem.associatedChannel.channelAudioType = "external";
                                                        //} else {
                                                            //patternsMenuItem.associatedChannel.channelAudioType = "sample-slice";
                                                        //}
                                                    //}
                                                //}
                                                //Zynthian.PlayGridButton {
                                                    //text: "LOOP"
                                                    //enabled: patternsMenuItem.activePattern === patternsMenuItem.thisPatternIndex
                                                    //checked: patternsMenuItem.thisPattern ? patternsMenuItem.thisPattern.noteDestination === Zynthbox.PatternModel.SampleLoopedDestination : false
                                                    //onClicked: {
                                                        //if (checked) {
                                                            //patternsMenuItem.associatedChannel.channelAudioType = "external";
                                                        //} else {
                                                            //patternsMenuItem.associatedChannel.channelAudioType = "sample-loop";
                                                        //}
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
                                                    patternsMenuItem.thisPattern.availableBars = Math.floor(_private.clipBoard.notes.length / patternsMenuItem.thisPattern.width) - 1;
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
                        RowLayout {
                            Layout.fillWidth: true
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
                id: stepSettingsPopup
                parent: QQC2.Overlay.overlay
                y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
                x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
                closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
                function showStepSettings(model, row, column) {
                    stepSettings.model = model;
                    stepSettings.row = row;
                    stepSettings.column = column;
                    stepSettingsPopup.open();
                }
                property var cuiaCallback: function(cuia) {
                    // We're not handling any of the interaction in here
                    var result = false;
                    return result;
                }
                Connections {
                    target: component
                    onIsVisibleChanged: {
                        if (stepSettingsPopup.opened && component.isVisible === false) {
                            stepSettingsPopup.close();
                        }
                    }
                }
                onClosed: {
                    stepSettings.row = -1;
                    stepSettings.column = -1;
                }
                StepSettings {
                    id: stepSettings
                    anchors.fill: parent
                    implicitWidth: drumPad.width - Kirigami.Units.largeSpacing * 2
                    onClose: stepSettingsPopup.close();
                }
            }
            Zynthian.Popup {
                id: noteSettingsPopup
                parent: QQC2.Overlay.overlay
                y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
                x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
                closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
                function showSettings(patternModel, firstBar, lastBar, midiNoteFilter) {
                    noteSettings.midiNoteFilter = midiNoteFilter;
                    noteSettings.firstBar = firstBar;
                    noteSettings.lastBar = lastBar;
                    noteSettings.patternModel = patternModel;
                    noteSettingsPopup.open();
                }
                property var cuiaCallback: function(cuia) {
                    // We're not handling any of the interaction in here
                    var result = false;
                    return result;
                }
                Connections {
                    target: component
                    onIsVisibleChanged: {
                        if (noteSettingsPopup.opened && component.isVisible === false) {
                            noteSettingsPopup.close();
                        }
                    }
                    onShowNoteSettingsPopup: {
                        noteSettingsPopup.showSettings(patternModel, firstBar, lastBar, midiNoteFilter);
                    }
                }
                onClosed: {
                    noteSettings.patternModel = null;
                    noteSettings.firstBar = -1;
                    noteSettings.lastBar = -1;
                }
                NoteSettings {
                    id: noteSettings
                    anchors.fill: parent
                    implicitWidth: drumPad.width - Kirigami.Units.largeSpacing * 2
                    onClose: noteSettingsPopup.close();
                }
            }
            QQC2.Drawer {
                id: channelsViewDrawer

                edge: Qt.BottomEdge
                modal: true

                width: parent.width
                height: Kirigami.Units.gridUnit * 15

                property var cuiaCallback: function(cuia) {
                    if (cuia === "SWITCH_BACK_SHORT" || cuia === "SWITCH_BACK_BOLD" || cuia === "SWITCH_BACK_LONG") {
                        channelsViewDrawer.close();
                    }
                    return true;
                }
                onOpened: {
                    zynqtgui.pushDialog(channelsViewDrawer);
                }
                onClosed: {
                    zynqtgui.popDialog(channelsViewDrawer);
                }
                Connections {
                    target: component
                    onIsVisibleChanged: {
                        if (channelsViewDrawer.opened && component.isVisible === false) {
                            channelsViewDrawer.close();
                        }
                    }
                }
                SessionDashboard.ChannelsViewSoundsBar {
                    anchors.fill: parent
                    property QtObject bottomDrawer: channelsViewDrawer
                }
            }
            Zynthian.Popup {
                id: partPicker
                function pickPart(associatedChannelIndex) {
                    partPicker.associatedChannelIndex = associatedChannelIndex;
                    open();
                }
                Connections {
                    target: component
                    onIsVisibleChanged: {
                        if (partPicker.opened && component.isVisible === false) {
                            partPicker.close();
                        }
                    }
                }
                property var cuiaCallback: function(cuia) {
                    if (cuia === "SWITCH_BACK_SHORT" || cuia === "SWITCH_BACK_BOLD" || cuia === "SWITCH_BACK_LONG") {
                        partPicker.close();
                    }
                    return true;
                }
                onOpened: {
                    zynqtgui.pushDialog(partPicker);
                }
                onClosed: {
                    zynqtgui.popDialog(partPicker);
                    partPicker.associatedChannelIndex = -1;
                }
                parent: QQC2.Overlay.overlay
                x: Math.round(parent.width/2 - width/2)
                y: Math.round(parent.height/2 - height/2)
                property int associatedChannelIndex: -1
                property QtObject associatedChannel: zynqtgui.sketchpad.song.channelsModel.getChannel(partPicker.associatedChannelIndex)
                ColumnLayout {
                    anchors.fill: parent
                    implicitWidth: Kirigami.Units.gridUnit * 30
                    implicitHeight: Kirigami.Units.gridUnit * 40
                    Kirigami.Heading {
                        Layout.fillWidth: true
                        text: qsTr("Select Active Parts For Channel %1").arg(partPicker.associatedChannel ? partPicker.associatedChannel.name : "")
                    }
                    ColumnLayout {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.largeSpacing
                        Repeater {
                            model: partPicker.associatedChannel ? 5 : 0
                            delegate: RowLayout {
                                id: partDelegate
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: Kirigami.Units.smallSpacing
                                property QtObject pattern: _private.sequence.getByPart(partPicker.associatedChannelIndex, model.index)
                                Rectangle {
                                    Layout.fillHeight: true
                                    Layout.minimumWidth: Kirigami.Units.largeSpacing
                                    Layout.maximumWidth: Kirigami.Units.largeSpacing
                                    color: partPicker.associatedChannel.selectedPart === model.index ? Kirigami.Theme.highlightColor : "transparent"
                                }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                                    Zynthian.PlayGridButton {
                                        anchors.fill: parent
                                        opacity: partDelegate.pattern.sequence && partDelegate.pattern.sequence.soloPattern === -1 ? 1 : 0.5
                                        icon.name: "player-volume"
                                        onClicked: {
                                            if (partDelegate.pattern.sequence && partDelegate.pattern.sequence.soloPattern === -1) {
                                                var associatedClip = partPicker.associatedChannel.getClipsModelByPart(partDelegate.pattern.partIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex);
                                                // Seems slightly backwards, but tapping a bunch of times really super fast and you'd end up with something a bit odd and unexpected, so might as well not cause that
                                                associatedClip.enabled = !partDelegate.pattern.enabled
                                            }
                                        }
                                    }
                                    Rectangle {
                                        visible: partDelegate.pattern ? !partDelegate.pattern.enabled : false
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
                                    readonly property var partNames: ["a", "b", "c", "d", "e"]
                                    text: qsTr("Pick Part %1%2").arg(partPicker.associatedChannelIndex + 1).arg(partNames[model.index])
                                    onClicked: {
                                        var associatedClip = partPicker.associatedChannel.getClipsModelByPart(partDelegate.pattern.partIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex);
                                        if (associatedClip.enabled) {
                                            partPicker.associatedChannel.selectedPart = model.index;
                                        } else {
                                            associatedClip.enabled = true;
                                        }
                                        partPicker.close();
                                    }
                                }
                                Image {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                                    source: partDelegate.pattern.thumbnailUrl
                                    Rectangle {
                                        anchors {
                                            top: parent.top
                                            bottom: parent.bottom
                                        }
                                        visible: partDelegate.pattern ? partDelegate.pattern.isPlaying : false
                                        color: Kirigami.Theme.highlightColor
                                        width: Math.max(1, Math.floor(widthFactor))
                                        property double widthFactor: partDelegate.pattern ? parent.width / (partDelegate.pattern.width * partDelegate.pattern.bankLength) : 1
                                        x: partDelegate.pattern ? partDelegate.pattern.bankPlaybackPosition * widthFactor : 0
                                    }
                                    Kirigami.Heading {
                                        anchors {
                                            fill: parent
                                            margins: Kirigami.Units.smallSpacing
                                        }
                                        horizontalAlignment: Text.AlignRight
                                        verticalAlignment: Text.AlignBottom
                                        level: 4
                                        text: partDelegate.pattern.name
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
                                    partPicker.close();
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
                    text: _private.sequence
                        ? _private.sequence.soloPatternObject
                            ? "Chan" + (_private.sequence.soloPatternObject.channelIndex + 1) + "\n"
                                + "SOLO\n"
                                + (_private.sequence.soloPatternObject.channelIndex + 1) + _private.sequence.soloPatternObject.partName
                            : _private.activePatternModel
                                ? "Chan" + (_private.activePatternModel.channelIndex + 1) + "\n"
                                    + "Clip"
                                    + (_private.activePatternModel.channelIndex + 1) + _private.activePatternModel.partName
                                : "(no\npat\ntern)"
                        : "(no\nsequ\nence)"
                    onClicked: {
                        component.showPatternsMenu();
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                Zynthian.PlayGridButton {
                    icon.name: "arrow-up"
                    onClicked: {
                        _private.octaveUp();
                    }
                }

                QQC2.Label {
                    text: "Octave"
                    Layout.alignment: Qt.AlignHCenter
                }

                Zynthian.PlayGridButton {
                    icon.name: "arrow-down"
                    onClicked: {
                        _private.octaveDown();
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
                            : (component.heardNotes.length == 1
                                ? component.heardNotes[0].name + (component.heardNotes[0].octave - 1)
                                : component.heardNotes.length + " ♫"))
                    visualPressAndHold: true
                    onClicked: {
                        if (!pressingAndHolding) {
                            if (zynqtgui.backButtonPressed && _private.activePatternModel) {
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
                Zynthian.PlayGridButton {
                    id: defaultNoteSettingsButton
                    text: component.mostRecentlyPlayedNote === undefined && component.heardNotes.length === 0
                        ? (component.currentBarNotes.length === 0 ? "-" : component.currentBarNotes.length) + " in\nBar"
                        : "%1\n%2".arg(noteLength).arg(velocity)
                    // enabled: component.mostRecentlyPlayedNote !== undefined
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
                    property string noteLength:  _private.activePatternModel.defaultNoteDuration === 0
                        ? _private.noteLengthNames[_private.noteLength]
                        : defaultNoteSettingsButton.stepNames.hasOwnProperty(_private.activePatternModel.defaultNoteDuration)
                            ? defaultNoteSettingsButton.stepNames[_private.activePatternModel.defaultNoteDuration]
                            : _private.activePatternModel.defaultNoteDuration + "/128th"
                    property string velocity: component.mostRecentlyPlayedNote === undefined ? "" : "Vel " + component.mostRecentNoteVelocity
                    onClicked: {
                        if (component.heardNotes.length > 0) {
                            var filter = []
                            for (var i = 0; i < component.heardNotes.length; ++i) {
                                filter.push(component.heardNotes[i].midiNote);
                            }
                            component.showNoteSettingsPopup(_private.activePatternModel, _private.activePatternModel.activeBar + _private.activePatternModel.bankOffset, _private.activePatternModel.activeBar + _private.activePatternModel.bankOffset, filter);
                        } else if (component.mostRecentlyPlayedNote !== undefined) {
                            component.showNoteSettingsPopup(_private.activePatternModel, _private.activePatternModel.activeBar + _private.activePatternModel.bankOffset, _private.activePatternModel.activeBar + _private.activePatternModel.bankOffset, [component.mostRecentlyPlayedNote.midiNote]);
                        } else {
                            component.showNoteSettingsPopup(_private.activePatternModel, _private.activePatternModel.activeBar + _private.activePatternModel.bankOffset, _private.activePatternModel.activeBar + _private.activePatternModel.bankOffset, []);
                        }
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                Zynthian.PlayGridButton {
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
