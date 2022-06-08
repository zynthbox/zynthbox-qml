/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Base Notes Grid Component 

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
    grid: notesGrid
    miniGrid: notesMiniGrid
    settings: notesGridSettings
    name:'Notes Grid'
    octave: 3
    useOctaves: _private.alternativeModel === null

    defaults: {
        "startingNote": component.octave * 12,
        "scale": "ionian",
        "rows": 5,
        "columns": 8,
        "positionalVelocity": true
    }
    persist: ["scale", "rows", "columns", "positionalVelocity"]

    QtObject {
        id: _private
        property QtObject currentSequence: ZynQuick.PlayGridManager.getSequenceModel(zynthian.zynthiloops.song.scenesModel.selectedMixName)
        property QtObject alternativeModel: currentSequence && currentSequence.activePatternObject && currentSequence.activePatternObject.noteDestination == ZynQuick.PatternModel.SampleSlicedDestination
            ? currentSequence.activePatternObject.clipSliceNotes
            : null
        property QtObject model
        property QtObject miniGridModel
        property int channel: ZynQuick.PlayGridManager.currentMidiChannel
        property int startingNote: component.gridRowStartNotes[component.octave]
        property string scale
        property int rows
        property int columns
        property bool positionalVelocity
    }

    gridRowStartNotes: startNotes[_private.scale] !== undefined ? startNotes[_private.scale] : [0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120]
    onGridRowStartNotesChanged: {
        populateGridTimer.restart();
    }
    property var startNotes: ({
        "chromatic": [0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120],
        "ionian": [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100, 105, 110, 115],
        "dorian": [0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120],
        "phrygian": [0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120],
        "lydian": [0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120],
        "mixolydian": [0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120],
        "aeolian": [0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120],
        "aeolian": [0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120]
    })
    function fillModel(model, startingNote, scale, rows, columns, positionalVelocity) {
        console.log("Filling notes model " + model + " with notes on channel " + _private.channel)
        var note_int_to_str_map = ["C", "C#","D","D#","E","F","F#","G","G#","A","A#","B"]

        var scale_mode_map = {
            "chromatic": [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
            "ionian": [2, 2, 1, 2, 2, 2, 1],
            "dorian": [2, 1, 2, 2, 2, 1, 2],
            "phrygian": [1, 2, 2, 2, 1, 2, 2],
            "lydian": [2, 2, 2, 1, 2, 2, 1],
            "mixolydian": [2, 2, 1, 2, 2, 1, 2],
            "aeolian": [2, 1, 2, 2, 1, 2, 2],
            "aeolian": [1, 2, 2, 1, 2, 2, 2],
        }

        var col = startingNote;
        var scaleArray = scale_mode_map[scale];
        var scale_index = 0;

        model.clear();
        for (var row = 0; row < rows; ++row){

            var notes = [];
            
            for (var i = 0; i < columns; ++i) {

                var note = component.getNote(
                    col,
                    _private.channel
                );
                if (scale_index >= scaleArray.length){
                    scale_index = 0;
                }
                col += scaleArray[scale_index];
                scale_index += 1;
                notes.push(note);

            }

            if (scale !== "chromatic"){ 
                col = notes[0] ? notes[0].midiNote : -1;
                scale_index = notes[0] ? notes[0].scaleIndex : 0;
                for (var x = 0; x < 3; ++x){
                    col += scaleArray[ scale_index % scaleArray.length ];
                    scale_index = (scale_index + 1) %  scaleArray.length;
                }
            }

            model.addRow(notes);
        }
    }

    function populateGrid(){
        if (_private.model && _private.miniGridModel) {
            fillModel(_private.model, _private.startingNote, _private.scale, _private.rows, _private.columns, _private.positionalVelocity)
            fillModel(_private.miniGridModel, _private.startingNote, _private.scale, 4, _private.columns, _private.positionalVelocity)
        }
    }

    onInitialize: {
        _private.startingNote = component.getProperty("startingNote")
        _private.scale = component.getProperty("scale")
        _private.rows = component.getProperty("rows")
        _private.columns = component.getProperty("columns")
        _private.positionalVelocity = component.getProperty("positionalVelocity")

        _private.model = component.getModel("main")
        _private.miniGridModel = component.getModel("mini")
        if (_private.model.rows == 0 || _private.miniGridModel.rows == 0) {
            populateGridTimer.restart()
        }
    }

    onPropertyChanged: {
        //console.log("A property named " + property + " has changed to " + value);
        var gridContentsChanged = true;
        if (property === "startingNote") {
            _private.startingNote = value;
        } else if (property === "scale") {
            _private.scale = value;
        } else if (property === "rows") {
            _private.rows = value;
        } else if (property === "columns") {
            _private.columns = value;
        } else if (property === "positionalVelocity") {
            _private.positionalVelocity = value;
            gridContentsChanged = false;
        } else {
            gridContentsChanged = false;
        }
        if (gridContentsChanged) {
            populateGridTimer.restart()
        }
    }

    Connections {
        target: ZynQuick.PlayGridManager
        onCurrentMidiChannelChanged: {
            if (_private.model) {
                Qt.callLater(_private.model.changeMidiChannel, ZynQuick.PlayGridManager.currentMidiChannel);
            }
            if (_private.miniGridModel) {
                Qt.callLater(_private.miniGridModel.changeMidiChannel, ZynQuick.PlayGridManager.currentMidiChannel);
            }
        }
    }

    Timer {
        id: populateGridTimer
        interval: 1
        repeat: false
        onTriggered: {
            component.populateGrid();
        }
    }

    onOctaveChanged: {
        component.setProperty("startingNote", component.gridRowStartNotes[Math.min(Math.max(0, component.octave), component.gridRowStartNotes.length - 1)]);
    }

    Component {
        id: notesGrid
        ColumnLayout {
            objectName: "notesGrid"
            spacing: 0
            anchors.margins: 5
            Repeater {
                id: mainGridRepeater
                model: _private.alternativeModel ? _private.alternativeModel : _private.model
                delegate: NotesGridDelegate {
                    id: gridDelegate;
                    model: mainGridRepeater.model
                    scale: _private.scale
                    positionalVelocity: _private.positionalVelocity
                    playgrid: component
                    Connections {
                        target: mainGridRepeater.model;
                        onDataChanged: {
                            gridDelegate.refetchNote();
                        }
                        onModelReset: {
                            gridDelegate.refetchNote();
                        }
                        onRowsChanged: {
                            gridDelegate.refetchNote();
                        }
                    }
                }
            }
        }
    }
    Component {
        id: notesMiniGrid
        ColumnLayout {
            objectName: "notesMiniGrid"
            spacing: 0
            anchors.margins: 5
            Repeater {
                id: miniGridRepeater
                model:  _private.alternativeModel ? _private.alternativeModel : _private.miniGridModel
                delegate: NotesGridDelegate {
                    id: miniGridDelegate
                    model: miniGridRepeater.model
                    scale: _private.scale
                    positionalVelocity: _private.positionalVelocity
                    playgrid: component
                    Connections {
                        target: miniGridRepeater.model;
                        onDataChanged: {
                            miniGridDelegate.refetchNote();
                        }
                        onModelReset: {
                            miniGridDelegate.refetchNote();
                        }
                        onRowsChanged: {
                            miniGridDelegate.refetchNote();
                        }
                    }
                }
            }
        }
    }

    Component {
        id: notesGridSettings
        Kirigami.FormLayout {
            objectName: "notesGridSettings"
            Layout.fillWidth: true
            Layout.fillHeight: true

            QQC2.ComboBox {
                id: comboScale
                Kirigami.FormData.label: "Modes"
                Layout.fillWidth: true
                model: ListModel {
                    id: scaleModel
                    ListElement { scale: "chromatic"; text: "Chromatic" }
                    ListElement { scale: "ionian"; text: "Ionian (Major)" }
                    ListElement { scale: "dorian"; text: "Dorian" }
                    ListElement { scale: "phrygian"; text: "Phrygian" }
                    ListElement { scale: "lydian"; text: "Lydian" }
                    ListElement { scale: "mixolydian"; text: "Mixolydian" }
                    ListElement { scale: "aeolian"; text: "Aeolian (Natural Minor)" }
                    ListElement { scale: "locrian"; text: "Locrian" }
                }
                textRole: "text"
                displayText: currentText
                currentIndex: 1

                onActivated: {
                    component.setProperty("startingNote", 36);
                    component.setProperty("scale", scaleModel.get(currentIndex).scale);
                }
            }
            QQC2.ComboBox {
                id: comboKey
                Layout.fillWidth: true
                Kirigami.FormData.label: "Key"
                visible: component.getProperty("scale") == "chromatic"
                model: keyModel
                textRole: "text"
                displayText: currentText
                currentIndex: 0

                onActivated: {
                    component.setProperty("startingNote", keyModel.get(currentIndex).note);
                }
                ListModel {
                    id: keyModel
                    function getName(note) {
                        for(var i = 0; i < keyModel.rowCount(); ++i) {
                            var le = keyModel.get(i);
                            if (le.note = note) {
                                return le.text;
                            }
                        }
                        return "C";
                    }

                    ListElement { note: 36; text: "C" }
                    ListElement { note: 37; text: "C#" }
                    ListElement { note: 38; text: "D" }
                    ListElement { note: 39; text: "D#" }
                    ListElement { note: 40; text: "E" }
                    ListElement { note: 41; text: "F" }
                    ListElement { note: 42; text: "F#" }
                    ListElement { note: 43; text: "G" }
                    ListElement { note: 44; text: "G#" }
                    ListElement { note: 45; text: "A" }
                    ListElement { note: 46; text: "A#" }
                    ListElement { note: 47; text: "B" }
                }
            }

            QQC2.Button {
                Layout.fillWidth: true
                Kirigami.FormData.label: "Transpose"
                visible: component.getProperty("scale") === "chromatic"
                text: "-"
                onClicked: {
                    var startingNote = component.getProperty("startingNote")
                    if (startingNote - 1 > 0) {
                        component.setProperty("startingNote", startingNote - 1);
                    } else {
                        startingNote = 0;
                        component.setProperty("startingNote", 0);
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                visible: component.getProperty("scale") === "chromatic"
                text: "+"
                onClicked: {
                    var startingNote = component.getProperty("startingNote")
                    component.setProperty("startingNote", startingNote + 1);
                }
            }

            QQC2.Button {
                Layout.fillWidth: true
                Kirigami.FormData.label: "Octave"
                visible: component.getProperty("scale") !== "chromatic"
                text: "-"
                onClicked: {
                    var startingNote = component.getProperty("startingNote")
                    if (startingNote - 12 > 0) {
                        component.setProperty("startingNote", startingNote - 12);
                    } else {
                        component.setProperty("startingNote",0);
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                visible: component.getProperty("scale") != "chromatic"
                text: "+"
                onClicked: {
                    var startingNote = component.getProperty("startingNote")
                    if (startingNote + 12 < 127){
                        component.setProperty("startingNote", startingNote + 12);
                    } else {
                        component.setProperty("startingNote", 120);
                    }
                }
            }
            QQC2.ComboBox {
                id: optionGrid
                Layout.fillWidth: true
                Kirigami.FormData.label: "Grid"
                model: ListModel {
                    id: gridModel
                    ListElement { row: 0; column: 0; text: "Custom" }
                    ListElement { row: 3; column: 3; text: "3x3" }
                    ListElement { row: 4; column: 4; text: "4x4" }
                    ListElement { row: 5; column: 8; text: "5x8" }
                }
                textRole: "text"
                displayText: currentText
                currentIndex: 3

                onActivated: {
                    var data = gridModel.get(currentIndex)
                    if (data.row === 0 && data.column === 0) {
                        component.setProperty("rows", customRows.currentText);
                        component.setProperty("columns", customColumns.currentText);
                    } else {
                        component.setProperty("rows", data.row);
                        component.setProperty("columns", data.column);
                    }
                }
            }

            QQC2.ComboBox {
                id: customRows
                Layout.fillWidth: true
                visible: optionGrid.currentIndex === 0
                Kirigami.FormData.label: "Custom Grid Rows"
                model: [3,4,5,6,7,8,9]
                displayText: currentText
                currentIndex: 0
                onActivated: {
                    component.setProperty("rows", currentText);
                }
            }
            QQC2.ComboBox {
                id: customColumns
                Layout.fillWidth: true
                visible: optionGrid.currentIndex === 0
                Kirigami.FormData.label: "Custom Grid Columns"
                model: [3,4,5,6,7,8,9]
                displayText: currentText
                currentIndex: 0
                onActivated: {
                    component.setProperty("columns", currentText);
                }
            }
            QQC2.Switch {
                Layout.fillWidth: true
                Kirigami.FormData.label: "Use Tap Position As Velocity"
                checked: component.getProperty("positionalVelocity")
                onClicked: {
                    var positionalVelocity = component.getProperty("positionalVelocity")
                    component.setProperty("positionalVelocity", !positionalVelocity);
                }
            }
        }
    }
}
