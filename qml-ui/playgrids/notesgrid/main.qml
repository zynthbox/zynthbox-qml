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
    octave: 8
    useOctaves: _private.alternativeModel === null

    defaults: {
        "scale": "ionian",
        "rows": 5,
        "columns": 8,
        "positionalVelocity": true,
        "transposeAmount": 0
    }
    persist: ["scale", "rows", "columns", "positionalVelocity", "transposeAmount"]

    QtObject {
        id: _private
        property QtObject currentSequence: ZynQuick.PlayGridManager.getSequenceModel("Scene "+zynthian.zynthiloops.song.scenesModel.selectedMixName)
        property QtObject alternativeModel: currentSequence && currentSequence.activePatternObject && currentSequence.activePatternObject.noteDestination == ZynQuick.PatternModel.SampleSlicedDestination
            ? currentSequence.activePatternObject.clipSliceNotes
            : null
        property QtObject model
        property QtObject miniGridModel
        property int channel: ZynQuick.PlayGridManager.currentMidiChannel
        property int startingNote: component.gridRowStartNotes[Math.min(Math.max(0, component.octave), component.gridRowStartNotes.length - 1)]
        property int transposeAmount: 0
        property string scale: "ionian"
        property int rows: 5
        property int columns: 8
        property bool positionalVelocity: true
        property var startNotes: ({ "chromatic": [0], "ionian": [0], "dorian": [0], "phrygian": [0], "lydian": [0], "mixolydian": [0], "aeolian": [0], "locrian": [0] })
        property var startIndices: ({ "chromatic": [0], "ionian": [0], "dorian": [0], "phrygian": [0], "lydian": [0], "mixolydian": [0], "aeolian": [0], "locrian": [0] })
        property var scale_mode_map: ({
            "chromatic": [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
            "ionian": [2, 2, 1, 2, 2, 2, 1],
            "dorian": [2, 1, 2, 2, 2, 1, 2],
            "phrygian": [1, 2, 2, 2, 1, 2, 2],
            "lydian": [2, 2, 2, 1, 2, 2, 1],
            "mixolydian": [2, 2, 1, 2, 2, 1, 2],
            "aeolian": [2, 1, 2, 2, 1, 2, 2],
            "locrian": [1, 2, 2, 1, 2, 2, 2],
        })

        onStartingNoteChanged: {
            populateGridTimer.restart();
        }
    }

    gridRowStartNotes: typeof _private.startNotes[_private.scale] === "undefined" ? [0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120] : _private.startNotes[_private.scale]
    function fillModel(model, startingNote, scale, rows, columns, positionalVelocity) {
        console.log("Filling notes model " + model + " with notes on channel " + _private.channel)
        var col = startingNote;
        var scaleArray = _private.scale_mode_map[scale];
        // Octave is not the correct term here, rather it's the position in the start note
        // array - but the variable is called octave, at least at the moment
        var scale_index = ((component.octave * 4) % scaleArray.length);
        var row_first_scale_index = 0;
        var row_first_note = 0;

        model.clear();
        for (var row = 0; row < rows; ++row){
            var notes = [];
            scale_index = _private.startIndices[_private.scale][component.octave + row];
            col = _private.startNotes[_private.scale][component.octave + row];
            // Minor hack here, but as we want the rows to be filled, this wants to be a thing
            if (typeof(col) === "undefined") {
                for (var i = 0; i < columns; ++i) {
                    notes.push(null);
                }
            } else {
                for (var i = 0; i < columns; ++i) {
                    var note = component.getNote(col, _private.channel);
                    notes.push(note);
                    col += scaleArray[scale_index];
                    scale_index = (scale_index + 1) % scaleArray.length;
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

    function populateStartNotes() {
        var startNotes = [];
        var startIndices = [];
        for (var scale in _private.scale_mode_map) {
            var scaleStartNotes = [];
            var scaleStartIndices = [];
            var scale_index = 0;
            var col = _private.transposeAmount;
            var scaleArray = _private.scale_mode_map[scale];
            if (scale === "chromatic") {
                // chromatic's a bit of a special case, that one just keeps going, so might as well just do that simple:
                var i = 0;
                while (col < 128) {
                    scaleStartNotes.push(col);
                    scaleStartIndices.push(i);
                    col += (_private.columns > 0 ? _private.columns : 8);
                    i = (i + 1) % 12;
                }
            } else {
                while (col < 128) {
                    // Each row progresses by four positions in the scale (except chromatic, handled separately above)
                    scaleStartNotes.push(col);
                    scaleStartIndices.push(scale_index);
                    for (var x = 0; x < 3; ++x){
                        col += scaleArray[scale_index];
                        scale_index = (scale_index + 1) %  scaleArray.length;
                    }
                }
            }
            startNotes[scale] = scaleStartNotes;
            startIndices[scale] = scaleStartIndices;
        }
        _private.startNotes = startNotes;
        _private.startIndices = startIndices;
    }

    onInitialize: {
        _private.transposeAmount = component.getProperty("transposeAmount")
        _private.scale = component.getProperty("scale")
        _private.rows = component.getProperty("rows")
        _private.columns = component.getProperty("columns")
        _private.positionalVelocity = component.getProperty("positionalVelocity")

        _private.model = component.getModel("main")
        _private.miniGridModel = component.getModel("mini")
        if (_private.model.rows == 0 || _private.miniGridModel.rows == 0) {
            populateStartNotesTimer.restart()
            populateGridTimer.restart()
        }
    }

    onPropertyChanged: {
        console.log("A property named " + property + " has changed to " + value);
        var gridContentsChanged = true;
        if (property === "transposeAmount") {
            _private.transposeAmount = value;
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
            populateStartNotesTimer.restart();
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
        id: populateStartNotesTimer
        interval: 1; repeat: false; running: false;
        onTriggered: {
            component.populateStartNotes();
        }
    }
    Timer {
        id: populateGridTimer
        interval: 1; repeat: false; running: false;
        onTriggered: {
            component.populateGrid();
        }
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
                    var scale = scaleModel.get(currentIndex).scale;
                    component.setProperty("scale", scale);
                    component.octave = (scale === "chromatic") ? 4 : 7
                }
            }

            QQC2.Button {
                Layout.fillWidth: true
                Kirigami.FormData.label: "Transpose"
                text: "-"
                enabled: _private.transposeAmount > 0
                onClicked: {
                    var transposeAmount = component.getProperty("transposeAmount")
                    if (transposeAmount > 0) {
                        component.setProperty("transposeAmount", transposeAmount - 1);
                    }
                }
            }
            QQC2.Button {
                Kirigami.FormData.label: _private.transposeAmount
                Layout.fillWidth: true
                text: "+"
                enabled: _private.transposeAmount < 11
                onClicked: {
                    var transposeAmount = component.getProperty("transposeAmount")
                    if (transposeAmount < 11) {
                        component.setProperty("transposeAmount", transposeAmount + 1);
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
