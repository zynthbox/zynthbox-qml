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
    useOctaves: true

    property bool showPatternsMenu: false;
    property int sequencerNotesCount: _private.activePatternModel ? _private.activePatternModel.columnCount(_private.activePatternModel.index(_private.activeBar + _private.bankOffset, 0)) : 0
    property QtObject sequencerNoteToTurnOff: null
    property var mostRecentlyPlayedNote
    property var mostRecentNoteVelocity

    property bool isEditSequencer: false

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
                _private.draftSaverThrottle.restart()
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
                if (property === "layer") {
                    var gridModel = component.getModel("pattern grid model " + patternIndex);
                    component.populateGrid(gridModel, patternIndex);
                }
            }
        }
    }
    function refreshSteps() {
        var activePattern = _private.sequence.activePattern;
        if (_private.sequence.activePattern === 0) {
            _private.sequence.activePattern = activePattern + 1;
        } else {
            _private.sequence.activePattern = activePattern - 1;
        }
        _private.sequence.activePattern = activePattern;
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
        property QtObject sequence
        property QtObject gridModel: sequence && activePattern > -1 ? component.getModel("pattern grid model " + activePattern) : null;
        property int activePattern: sequence ? sequence.activePattern : -1
        property QtObject activePatternModel: sequence ? sequence.activePatternObject : null;
        property QtObject activeBarModel:activePatternModel && activeBar > -1 ? activePatternModel.data(activePatternModel.index(activeBar + bankOffset, 0), activePatternModel.roles["rowModel"]) : null;

        property bool patternHasUnsavedChanged: false
        property bool positionalVelocity: true
        property var bars: [0,1,2,3,4,5,6,7]
        // This is the top bank we have available in any pattern (that is, the upper limit for any pattern's bankOffset value)
        property int bankLimit: 1
        property var clipBoard
        property int octave: 3

        // Properties inherent to the active pattern (set these through component.setPatternProperty)
        property int noteLength: sequence && sequence.activePatternObject ? sequence.activePatternObject.noteLength : 0
        property int layer: sequence && sequence.activePatternObject ? sequence.activePatternObject.layer : 0
        property var availableBars: sequence && sequence.activePatternObject ? sequence.activePatternObject.availableBars : 0
        property var activeBar: sequence && sequence.activePatternObject ? sequence.activePatternObject.activeBar : 0
        property int bankOffset: sequence && sequence.activePatternObject ? sequence.activePatternObject.bankOffset : 0
        property string bankName: sequence && sequence.activePatternObject ? sequence.activePatternObject.bank : "?"
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
                var theTrack = zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack);
                ZynQuick.PlayGridManager.currentMidiChannel = (theTrack != null) ? theTrack.connectedSound : -1;
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

        function updateCurrentGrid() {
            if (gridModel) {
                if (gridModel.rows === 0) {
                    populateGridTimer.restart();
                } else {
                    for (var i = 0; i < gridModel.rows; ++i) {
                        var row = gridModel.getRow(i);
                        for (var j = 0; j < row.length; ++j) {
                            var note = row[j];
                            if (note) {
                                if (note.midiChannel !== activePattern.midiChannel) {
                                    populateGridTimer.restart();
                                }
                                break;
                            }
                        }
                    }
                }
            }
        }

        onOctaveChanged: {
            updateCurrentGrid();
        }

        onActiveBarChanged: {
            draftSaverThrottle.restart()
        }

        onAvailableBarsChanged:{
            draftSaverThrottle.restart()
        }

        onActivePatternChanged:{
            updateTrack();
            console.log('on active pattern changed', _private.activePattern)
        }

        onLayerChanged: {
            updateTrack();
            updateCurrentGrid();
        }

        onGridModelChanged: {
            updateTrack();
            updateCurrentGrid();
        }

        property QtObject draftSaverThrottle: Timer {
            repeat: false
            running: false
            interval: 100
            onTriggered: {
                _private.sequence.save();
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
    }
    Connections {
        target: zynthian.zynthiloops.song.tracksModel
        onConnectedSoundsCountChanged: _private.updateTrack()
        onConnectedPatternsCountChanged: _private.updateTrack()
    }
    Connections {
        target: zynthian.zynthiloops
        onSongChanged: _private.updateTrack()
    }
    Connections {
        target: _private.associatedTrack
        onConnectedPatternChanged: _private.updateTrack()
        onConnectedSoundChanged: _private.updateTrack()
    }
    Connections {
        target: zynthian.session_dashboard
        onSelectedTrackChanged: {
            var theTrack = zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack);
            ZynQuick.PlayGridManager.currentMidiChannel = (theTrack != null) ? theTrack.connectedSound : -1;
        }
    }

    // on component completed
    onInitialize: {
        _private.sequence = ZynQuick.PlayGridManager.getSequenceModel("Global");
        // HACK ALERT this needs to be done somewhere more sensible
        //_private.sequence.song = zynthian.zynthiloops.song;
        component.dashboardModel = _private.sequence;
        if (_private.gridModel.rows === 0) {
            for (var i = 0; i < 5; ++i) {
                component.populateGrid(component.getModel("pattern grid model " + i), i);
            }
        }
        var theTrack = zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack);
        ZynQuick.PlayGridManager.currentMidiChannel = (theTrack != null) ? theTrack.connectedSound : -1;
    }
    Connections {
        target: ZynQuick.PlayGridManager
        onDashboardItemPicked: {
            if (component.dashboardModel === model) {
                _private.sequence.activePattern = index;
            }
        }
    }

    //Connections {
        //// HACK ALERT this needs to be done somewhere more sensible
        //target: zynthian.zynthiloops
        //onSongChanged: {
            //_private.sequence.song = zynthian.zynthiloops.song;
        //}
    //}

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

    Timer {
        id: populateGridTimer
        repeat: false
        interval: 1
        onTriggered: {
            component.populateGrid(_private.gridModel, _private.activePattern);
        }
    }

    // this is where we populate the grid using the component settingsStore rows / columns propterties
    function populateGrid(model, patternIndex){
        model.clear()

        var startingNote = _private.octave * 12;
        var rows = 4;
        var columns = 4;

        var midiChannel = _private.sequence.get(patternIndex).layer;
        console.log("Populating grid for pattern " + patternIndex + " which has midi channel " + midiChannel);
        for (var row = 0; row < rows; ++row){

            var rowStartingNote = startingNote + (row * columns);
            var rowEndingNote = rowStartingNote + columns;
            var notes = [];

            for(var col = rowStartingNote; col < rowEndingNote; ++col) {
                var note = component.getNote(col, midiChannel);
                notes.push(note);
            }

            model.addRow(notes);
        }
    }

    function saveDraft() {
        _private.draftSaverThrottle.restart();
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
                    model: _private.gridModel
                    positionalVelocity: _private.positionalVelocity
                    playgrid: component
                }

                // drum pad & sequencer
                Rectangle {
                    id:drumPad
                    Layout.fillWidth: true; 
                    Layout.minimumHeight: parent.height / 5; 
                    Layout.maximumHeight: parent.height / 5;
                    color:"transparent"

                    RowLayout {
                        anchors.fill:parent
                        anchors.margins: 5
                        Repeater {
                            id:drumPadRepeater
                            model: _private.activeBarModel
                            PadNoteButton {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                playgrid: component
                                patternModel: _private.activePatternModel
                                activeBar:_private.activeBar
                                mostRecentlyPlayedNote: component.mostRecentlyPlayedNote
                                padNoteIndex: model.index
                                note: _private.activePatternModel.getNote(_private.activeBar + _private.bankOffset, model.index)
                                padNoteNumber: ((_private.activeBar + _private.bankOffset) * drumPadRepeater.count) + padNoteIndex
                                onSaveDraft: {
                                    component.saveDraft();
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
                    visible: component.isEditSequencer
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

                                Zynthian.PlayGridButton {
                                    text: "copy\n"
                                    onClicked: {
                                        _private.copyRange(
                                            (_private.activePattern + 1) + " pt." + _private.bankName + "/" + (_private.activeBar + 1),
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

                                ColumnLayout {
                                    Layout.fillHeight: true
                                    Zynthian.PlayGridButton {
                                        text: "part I"
                                        checked: _private.bankOffset === 0
                                        onClicked: {
                                            component.setPatternProperty("bankOffset", 0)
                                        }
                                    }
                                    Zynthian.PlayGridButton {
                                        text: "part II"
                                        checked: _private.bankOffset === 8
                                        onClicked: {
                                            component.setPatternProperty("bankOffset", 8)
                                        }
                                    }
                                }
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
                                    playedBar: _private.activePatternModel && component.patternModel ? _private.activePatternModel.playingRow - component.patternModel.bankOffset : 0
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
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: -5
                }
                width:900
                height:450
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
                ColumnLayout {
                    id:patternsMenuList
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.smallSpacing
                    }
                    Repeater {
                        model: _private.sequence

                        delegate: Rectangle {
                            id:patternsMenuItem
                            property QtObject thisPattern: model.pattern
                            property int thisPatternIndex: model.index
                            property int bankIndex: thisPattern.bankOffset / 8;
                            property int activePattern: _private.activePattern
                            property QtObject trackClipsModel: associatedTrack == null ? null : associatedTrack.clipsModel
                            property QtObject associatedTrack: null
                            property int associatedTrackIndex: -1
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Kirigami.Theme.inherit: false
                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                            color: activePattern === index ? Kirigami.Theme.focusColor : Kirigami.Theme.backgroundColor
                            border.color: Kirigami.Theme.textColor
                            function pickThisPattern() {
                                console.log(patternsMenuItem.thisPatternIndex, "index");
                                for(var i = 0; i < zynthian.zynthiloops.song.tracksModel.count; ++i) {
                                    var track = zynthian.zynthiloops.song.tracksModel.getTrack(i);
                                    if (track && track.connectedPattern === patternsMenuItem.thisPatternIndex) {
                                        zynthian.session_dashboard.selectedTrack = i;
                                        break;
                                    }
                                }
                                _private.sequence.activePattern = patternsMenuItem.thisPatternIndex
                                component.saveDraft();
                            }
                            function adoptTrackLayer() {
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

                                if (patternsMenuItem.associatedTrackIndex > -1) {
                                    var connectedSound = patternsMenuItem.associatedTrack.connectedSound;
                                    if (connectedSound === -1) {
                                        // Channel 15 is interpreted as "no assigned sound, either use override or play nothing"
                                        component.setPatternProperty("layer", 15, patternsMenuItem.thisPatternIndex);
                                    } else if (connectedSound !== patternsMenuItem.thisPattern.layer) {
                                        component.setPatternProperty("layer", connectedSound, patternsMenuItem.thisPatternIndex);
                                    }
                                } else {
                                    // Channel 15 is interpreted as "no assigned sound, either use override or play nothing"
                                    component.setPatternProperty("layer", 15, patternsMenuItem.thisPatternIndex);
                                }
                                trackClipsRepeater.updateEnabledFromClips();
                            }
                            Connections {
                                target: patternsMenuItem.thisPattern
                                onLayerChanged: patternsMenuItem.adoptTrackLayer()
                                onEnabledChanged: component.saveDraft()
                                onBankOffsetChanged: component.saveDraft()
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
                            Repeater {
                                // TODO One of the many things which need to go into the looper logic
                                // directly, or into the components... At any rate, it should not live
                                // in a playgrid, because that is just kind of silly...
                                id: trackClipsRepeater
                                model: patternsMenuItem.trackClipsModel
                                function updateEnabledFromClips() {
                                    var enabledBank = -1;
                                    for(var i = 0; i < trackClipsModel.count; ++i) {
                                        var clipItem = trackClipsRepeater.itemAt(i);
                                        if (clipItem.clipInScene) {
                                            enabledBank = i;
                                            break;
                                        }
                                    }
                                    component.setPatternProperty("enabled", (enabledBank > -1), patternsMenuItem.thisPatternIndex);
                                    if (enabledBank > -1) {
                                        component.setPatternProperty("bankOffset", enabledBank * patternsMenuItem.thispattern.bankLength, patternsMenuItem.thisPatternIndex);
                                    }
                                }
                                delegate: Item {
                                    id: clipProxyDelegate
                                    property QtObject clip: model.clip
                                    property bool clipInScene: model.clip.inCurrentScene
                                    Connections {
                                        target: clipProxyDelegate.clip
                                        onInCurrentSceneChanged: {
                                            trackClipsRepeater.updateEnabledFromClips();
                                        }
                                    }
                                }
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
                                        Zynthian.PlayGridButton {
                                            Layout.fillHeight: true
                                            Layout.fillWidth: true
                                            Layout.margins: Kirigami.Units.largeSpacing
                                            opacity: _private.sequence.soloPattern === -1 ? 1 : 0.5
                                            icon.name: patternsMenuItem.thisPattern.enabled ? "player-volume" : ""
                                            onClicked: {
                                                if (_private.sequence.soloPattern === -1) {
                                                    patternsMenuItem.thisPattern.enabled = !patternsMenuItem.thisPattern.enabled
                                                }
                                            }
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillHeight: true
                                        Layout.minimumWidth: (parent.width / 7);
                                        Layout.maximumWidth: (parent.width / 7);

                                        QQC2.Label {
                                            Layout.fillHeight: true
                                            Layout.fillWidth: true
                                            text: "Track:"
                                            font.pixelSize: 15
                                            Kirigami.Theme.inherit: false
                                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                            color: Kirigami.Theme.textColor
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        QQC2.Label {
                                            Layout.fillHeight: true
                                            Layout.fillWidth: true
                                            text: patternsMenuItem.associatedTrack ? patternsMenuItem.associatedTrack.name : "None Associated"
                                            elide: Text.ElideRight
                                            font.pixelSize: 15
                                            Kirigami.Theme.inherit: false
                                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                            color: Kirigami.Theme.textColor
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillHeight: true
                                        Layout.minimumWidth: (parent.width / 7) * 3;
                                        Layout.maximumWidth: (parent.width / 7) * 3;

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: parent.height / 2
                                            Image {
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                source: "image://pattern/Global/" + patternsMenuItem.thisPatternIndex + "/" + patternsMenuItem.bankIndex + "?" + patternsMenuItem.thisPattern.lastModified
                                                Rectangle {
                                                    anchors {
                                                        top: parent.top
                                                        bottom: parent.bottom
                                                    }
                                                    visible: patternsMenuItem.thisPattern.isPlaying
                                                    color: Kirigami.Theme.highlightColor
                                                    width: Math.max(1, Math.floor(widthFactor))
                                                    property double widthFactor: parent.width / (patternsMenuItem.thisPattern.width * patternsMenuItem.thisPattern.bankLength)
                                                    x: patternsMenuItem.thisPattern.bankPlaybackPosition * widthFactor
                                                }
                                                Kirigami.Heading {
                                                    anchors {
                                                        fill: parent
                                                        margins: Kirigami.Units.smallSpacing
                                                    }
                                                    horizontalAlignment: Text.AlignRight
                                                    verticalAlignment: Text.AlignBottom
                                                    level: 4
                                                    text: model.name + (model.unsavedChanges === true ? " *" : "")
                                                }
                                            }
                                        }

                                        Zynthian.PlayGridButton {
                                            id: soundButton
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: parent.height / 2
                                            enabled: patternsMenuItem.associatedTrack
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
                                            text: patternsMenuItem.associatedTrack
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
                                    ColumnLayout {
                                        Layout.fillHeight: true
                                        Zynthian.PlayGridButton {
                                            text: "part I"
                                            checked: patternsMenuItem.thisPattern.bankOffset === 0
                                            onClicked: {
                                                component.setPatternProperty("bankOffset", 0, patternsMenuItem.thisPatternIndex)
                                            }
                                        }
                                        Zynthian.PlayGridButton {
                                            text: "part II"
                                            checked: patternsMenuItem.thisPattern.bankOffset === 8
                                            onClicked: {
                                                component.setPatternProperty("bankOffset", 8, patternsMenuItem.thisPatternIndex)
                                            }
                                        }
                                    }
                                    Zynthian.PlayGridButton {
                                        text: "copy\n"
                                        onClicked: {
                                            _private.copyRange(
                                                (patternsMenuItem.thisPatternIndex + 1) + " pt." + patternsMenuItem.thisPattern.bank,
                                                patternsMenuItem.thisPattern,
                                                patternsMenuItem.thisPattern.bankOffset,
                                                patternsMenuItem.thisPattern.bankOffset + patternsMenuItem.thisPattern.bankLength
                                            );
                                        }
                                    }
                                    Zynthian.PlayGridButton {
                                        text: "paste\n" + (_private.clipBoard && _private.clipBoard.description !== "" ? _private.clipBoard.description : "")
                                        enabled: _private.clipBoard !== undefined
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
                id: noFreeSlotsPopup
                x: Math.round(parent.width/2 - width/2)
                y: Math.round(parent.height/2 - height/2)
                width: Kirigami.Units.gridUnit*12
                height: Kirigami.Units.gridUnit*4
                modal: true

                QQC2.Label {
                    anchors.fill: parent
                    horizontalAlignment: "AlignHCenter"
                    verticalAlignment: "AlignVCenter"
                    text: qsTr("No free slots remaining")
                    font.italic: true
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
                        ? "Pattern:\n" + (_private.sequence.soloPattern + 1) + " pt." + _private.sequence.get(_private.sequence.soloPattern).bank + "\nSOLO"
                        : "Pattern:\n" + (_private.activePattern + 1) + " pt." + _private.bankName + "\n" + (_private.associatedTrack ? _private.associatedTrack.name : "(none)");
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
                    icon.name: component.mostRecentlyPlayedNote == undefined ? "" : "edit-clear-locationbar-ltr"
                    text: "Note:\n" + (component.mostRecentlyPlayedNote == undefined
                        ? "(all)"
                        : component.mostRecentlyPlayedNote.name + (component.mostRecentlyPlayedNote.octave - 1))
                    onClicked: {
                        sidebarRoot.hideAllMenus();
                        component.mostRecentlyPlayedNote = undefined;
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                Zynthian.PlayGridButton {
                    id:sequencerSettingsBtn
                    icon.name: "configure"
                    onClicked: {
                        sidebarRoot.hideAllMenus();
                        component.isEditSequencer = !component.isEditSequencer;
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
            }
        }
    }
}
