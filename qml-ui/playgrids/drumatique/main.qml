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

Zynthian.BasePlayGrid {
    id: component
    grid: drumsGrid
    settings: drumsGridSettings
    sidebar: drumsGridSidebar
    name:'Drumatique'
    useOctaves: true

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

        //property QtObject activeBarModel: ZynQuick.FilterProxy {
            //sourceModel: patternModel
            //filterRowStart: activeBar
            //filterRowEnd: activeBar
        //}

        onOctaveChanged: {
            populateGridTimer.restart();
        }

        onActiveBarChanged: {
            draftSaverThrottle.restart()
        }

        onAvailableBarsChanged:{
            draftSaverThrottle.restart()
        }

        onActivePatternChanged:{
            console.log('on active pattern changed', _private.activePattern)
        }

        onGridModelChanged: {
            if (gridModel && gridModel.rows === 0) {
                populateGridTimer.restart();
            }
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

    // on component completed
    onInitialize: {
        _private.sequence = ZynQuick.PlayGridManager.getSequenceModel("Global");
        component.dashboardModel = _private.sequence;
        if (_private.gridModel.rows === 0) {
            for (var i = 0; i < 5; ++i) {
                component.populateGrid(component.getModel("pattern grid model " + i), i);
            }
        }
    }
    Connections {
        target: ZynQuick.PlayGridManager
        onDashboardItemPicked: {
            if (component.dashboardModel === model) {
                _private.sequence.activePattern = index;
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
        ColumnLayout {
            id:gridColumnLayout
            objectName: "drumsGrid"
            spacing: 0
            anchors.margins: 5

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
                                                test += "octuple";
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
                                        (_private.activePattern + 1) + _private.bankName + "/" + (_private.activeBar + 1),
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
                                    text: "bank A"
                                    checked: _private.bankOffset === 0
                                    onClicked: {
                                        component.setPatternProperty("bankOffset", 0)
                                    }
                                }
                                Zynthian.PlayGridButton {
                                    text: "bank B"
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
                                playedBar: _private.activePatternModel ? _private.activePatternModel.playingRow - component.patternModel.bankOffset : 0
                                playgrid: component
                            }
                        }
                    }
                }
            }
        }
    }

    // Drums Grid Sidebar
    Component {
        id: drumsGridSidebar
        ColumnLayout {
            id: sidebarRoot

            function hideAllMenus() {
                patternsMenu.visible = false;
            }
            Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

            Zynthian.PlayGridButton {
                text: "Pattern:\n" + (_private.activePattern + 1) + _private.bankName;
                onClicked: {
                    hideAllMenus();
                    patternsMenu.visible = true;
                }
                Item {
                    id: patternsMenu
                    visible: false
                    anchors {
                        left: parent.right
                        leftMargin: Kirigami.Units.largeSpacing
                        top: parent.top
                        topMargin: - parent.width - Kirigami.Units.largeSpacing
                    }
                    width:600
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
                        onClicked: {
                            patternsMenu.visible = false;
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
                                property int selectedLayer: model.layer
                                property int activePattern: _private.activePattern
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                color: activePattern === index ? Kirigami.Theme.focusColor : Kirigami.Theme.backgroundColor
                                border.color: Kirigami.Theme.textColor
                                function pickThisPattern() {
                                    console.log(patternsMenuItem.thisPatternIndex, "index");
                                    _private.sequence.activePattern = patternsMenuItem.thisPatternIndex
                                    component.saveDraft();
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
                                            Layout.minimumWidth: (parent.width / 5) * 3;
                                            Layout.maximumWidth: (parent.width / 5) * 3;

                                            RowLayout {
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                QQC2.CheckBox {
                                                    Layout.fillHeight: true
                                                    Layout.preferredWidth: height
                                                    checked: patternsMenuItem.thisPattern.enabled
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: {
                                                            patternsMenuItem.thisPattern.enabled = !patternsMenuItem.thisPattern.enabled
                                                        }
                                                    }
                                                }
                                                Image {
                                                    Layout.fillHeight: true
                                                    Layout.fillWidth: true
                                                    source: "image://pattern/Global/" + patternsMenuItem.thisPatternIndex + "/" + patternsMenuItem.bankIndex + "?" + patternsMenuItem.thisPattern.lastModified
                                                    Rectangle {
                                                        anchors {
                                                            top: parent.top
                                                            bottom: parent.bottom
                                                        }
                                                        visible: _private.sequence.isPlaying && patternsMenuItem.thisPattern.enabled
                                                        color: Kirigami.Theme.highlightColor
                                                        width: widthFactor
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

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Layout.minimumHeight: parent.height / 2;
                                                Layout.maximumHeight: parent.height / 2;
                                                spacing:5

                                                QQC2.Label {
                                                    Layout.fillHeight: true
                                                    Layout.fillWidth: true
                                                    text: "Sound:"
                                                    font.pixelSize: 15
                                                    Kirigami.Theme.inherit: false
                                                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                                    color: Kirigami.Theme.textColor
                                                }
                                                QQC2.ComboBox {
                                                    id: layerCombo
                                                    Layout.fillHeight: true
                                                    Layout.fillWidth: true
                                                    model: zynthian.fixed_layers.selector_list
                                                    textRole: "display"
                                                    delegate: QQC2.ItemDelegate {
                                                        width: layerCombo.popup.width
                                                        highlighted: layerCombo.highlightedIndex === index
                                                        text: (model.metadata.midi_channel + 1) + ". " + model.display
                                                        height: visible ? Kirigami.Units.fontMetrics.height * 2 : 0
                                                        visible: index === 0 || index > 9
                                                    }
                                                    currentIndex: patternsMenuItem.selectedLayer;
                                                    Connections {
                                                        target: patternsMenuItem.thisPattern
                                                        onLayerChanged: {
                                                            var layerIndex = patternsMenuItem.thisPattern.layer;
                                                            if (layerCombo.currentIndex !== layerIndex) {
                                                                layerCombo.currentIndex = layerIndex;
                                                            }
                                                        }
                                                    }
                                                    onActivated: {
                                                        console.log(patternsMenuItem.thisPatternIndex, index, "on select layer")
                                                        component.setPatternProperty("layer", index, patternsMenuItem.thisPatternIndex)
                                                    }
                                                }
                                            }
                                        }
                                        ColumnLayout {
                                            Layout.fillHeight: true
                                            Zynthian.PlayGridButton {
                                                text: "bank A"
                                                checked: patternsMenuItem.thisPattern.bankOffset === 0
                                                onClicked: {
                                                    component.setPatternProperty("bankOffset", 0, patternsMenuItem.thisPatternIndex)
                                                }
                                            }
                                            Zynthian.PlayGridButton {
                                                text: "bank B"
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
                                                    (patternsMenuItem.thisPatternIndex + 1) + patternsMenuItem.thisPattern.bank,
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
            }

            Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

            Zynthian.PlayGridButton {
                icon.name: "arrow-up"
                onClicked: {
                    hideAllMenus();
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
                    hideAllMenus();
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
                text: _private.sequence.isPlaying ? "Pause" : "Play"
                onPressed: {
                    hideAllMenus();
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

            QQC2.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "Note"
            }
            Zynthian.PlayGridButton {
                Layout.fillHeight: false
                icon.name: component.mostRecentlyPlayedNote == undefined ? "" : "edit-clear-locationbar-ltr"
                text: component.mostRecentlyPlayedNote == undefined
                    ? "(all)"
                    : component.mostRecentlyPlayedNote.name + component.mostRecentlyPlayedNote.octave
                onClicked: {
                    hideAllMenus();
                    component.mostRecentlyPlayedNote = undefined;
                }
            }

            Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

            Zynthian.PlayGridButton {
                id:sequencerSettingsBtn
                icon.name: "configure"
                onClicked: {
                    hideAllMenus();
                    component.isEditSequencer = !component.isEditSequencer;
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
                Kirigami.FormData.label: "Use Tap Position As Velocity"
                checked: _private.positionalVelocity
                onClicked: {
                    _private.positionalVelocity = !_private.positionalVelocity;
                }
            }
        }
    }
}
