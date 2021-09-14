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

Zynthian.BasePlayGrid {
    id: component
    grid: notesGrid
    miniGrid: notesMiniGrid
    settings: notesGridSettings
    name:'Notes Grid'
    octave: 3
    useOctaves: true

    property QtObject settingsStore
    property QtObject miniGridModel

    property int startingNote: component.octave * 12;
    property string scale: "ionian";
    property int rows: 5;
    property int columns: 8;
    property bool positionalVelocity: true;

    function fillModel(model, startingNote, scale, rows, columns, positionalVelocity) {
        console.log("Filling notes model " + model)
        var note_int_to_str_map = ["C", "C#","D","D#","E","F","F#","G","G#","A","A#","B"]

        var scale_mode_map = {
            "chromatic": [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
            "ionian": [2, 2, 1, 2, 2, 2, 1],
            "dorian": [2, 1, 2, 2, 2, 1, 2],
            "phrygian": [1, 2, 2, 2, 1, 2, 2],
            "lydian": [2, 2, 2, 1, 2, 2, 1],
            "mixolydian": [2, 2, 1, 2, 2, 1, 2],
            "aeolian": [2, 1, 2, 2, 1, 2, 2],
            "locrian": [1, 2, 2, 1, 2, 2, 2],
        }

        var col = startingNote;
        var scaleArray = scale_mode_map[scale];
        var scale_index = 0;

        model.clear();
        for (var row = 0; row < rows; ++row){

            var notes = [];
            
            for (var i = 0; i < columns; ++i) {

                var note = zynthian.playgrid.getNote(
                    ((0 <= col <= 127) ? note_int_to_str_map[col % 12] : ""),
                    scale_index,
                    Math.floor(col / 12),
                    col
                );
                if (scale_index >= scaleArray.length){
                    scale_index = 0;
                }
                col += scaleArray[scale_index];
                scale_index += 1;
                notes.push(note);

            }

            if (scale !== "chromatic"){ 
                col = notes[0].midiNote;
                scale_index = notes[0].scaleIndex;
                for (var x = 0; x < 3; ++x){
                    col += scaleArray[ scale_index % scaleArray.length ];
                    scale_index = (scale_index + 1) %  scaleArray.length;
                }
            }

            model.addRow(notes);
        }
    }

    function populateGrid(){
        fillModel(component.model, component.startingNote, component.scale, component.rows, component.columns, component.positionalVelocity)
        fillModel(component.miniGridModel, component.startingNote + 24, component.scale, 2, component.columns, component.positionalVelocity)
    }

    Component.onCompleted: {
        component.settingsStore = zynthian.playgrid.getSettingsStore("zynthian notesgrid settings")

        component.settingsStore.setDefault("startingNote", component.startingNote);
        component.settingsStore.setDefault("scale", component.scale);
        component.settingsStore.setDefault("rows", component.rows);
        component.settingsStore.setDefault("columns", component.columns);
        component.settingsStore.setDefault("positionalVelocity", component.positionalVelocity);

        component.startingNote = component.settingsStore.property("startingNote")
        component.scale = component.settingsStore.property("scale")
        component.rows = component.settingsStore.property("rows")
        component.columns = component.settingsStore.property("columns")
        component.positionalVelocity = component.settingsStore.property("positionalVelocity")

        component.model = zynthian.playgrid.getNotesModel("zynthian notesgrid main")
        component.miniGridModel = zynthian.playgrid.getNotesModel("zynthian notesgrid mini")
        if (component.model.rows == 0 || component.miniGridModel.rows == 0) {
            populateGridTimer.restart()
        }
    }

    Connections {
        target: component.settingsStore
        onPropertyChanged: {
            var mostRecentlyChanged = component.settingsStore.mostRecentlyChanged();
//             console.log("A property named " + mostRecentlyChanged + " has changed to " + component.settingsStore.property(mostRecentlyChanged));
            var changed = true;
            if (mostRecentlyChanged === "startingNote" && component.startingNote != component.settingsStore.property("startingNote")) {
                component.startingNote = component.settingsStore.property("startingNote");
            } else if (mostRecentlyChanged === "scale" && component.scale != component.settingsStore.property("scale")) {
                component.scale = component.settingsStore.property("scale");
            } else if (mostRecentlyChanged === "rows" && component.rows != component.settingsStore.property("rows")) {
                component.rows = component.settingsStore.property("rows");
            } else if (mostRecentlyChanged === "columns" && component.columns != component.settingsStore.property("columns")) {
                component.columns = component.settingsStore.property("columns");
            } else if (mostRecentlyChanged === "positionalVelocity" && component.positionalVelocity != component.settingsStore.property("positionalVelocity")) {
                component.positionalVelocity = component.settingsStore.property("positionalVelocity");
            } else {
                changed = false;
            }
            if (changed) {
                populateGridTimer.restart()
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
        component.settingsStore.setProperty("startingNote", component.octave * 12);
    }

    Component {
        id: notesGrid
        ColumnLayout {
            objectName: "notesGrid"
            spacing: 0
            anchors.margins: 5
            Repeater {
                model: component.model
                delegate: NotesGridDelegate {
                    model: component.model
                    settingsStore: component.settingsStore
                    currentNoteName: component.currentNoteName
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
                model: component.miniGridModel
                delegate: NotesGridDelegate {
                    model: component.miniGridModel
                    settingsStore: component.settingsStore
                    currentNoteName: component.currentNoteName
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
                model: scaleModel
                textRole: "text"
                displayText: currentText
                currentIndex: 1

                onActivated: {
                    component.settingsStore.setProperty("startingNote", 36);
                    component.settingsStore.setProperty("scale", scaleModel.get(currentIndex).scale);
                }
            }
            QQC2.ComboBox {
                id: comboKey
                Layout.fillWidth: true
                Kirigami.FormData.label: "Key"
                visible: component.settingsStore.property("scale") == "chromatic"
                model: keyModel
                textRole: "text"
                displayText: currentText
                currentIndex: 0

                onActivated: {
                    component.settingsStore.setProperty("startingNote", keyModel.get(currentIndex).note);
                }
            }

            QQC2.Button {
                Layout.fillWidth: true
                Kirigami.FormData.label: "Transpose"
                visible: component.settingsStore.property("scale") === "chromatic"
                text: "-"
                onClicked: {
                    var startingNote = component.settingsStore.property("startingNote")
                    if (startingNote - 1 > 0) {
                        component.settingsStore.setProperty("startingNote", startingNote - 1);
                    } else {
                        startingNote = 0;
                        component.settingsStore.setProperty("startingNote", 0);
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                visible: component.settingsStore.property("scale") === "chromatic"
                text: "+"
                onClicked: {
                    var startingNote = component.settingsStore.property("startingNote")
                    component.settingsStore.setProperty("startingNote", startingNote + 1);
                }
            }

            QQC2.Button {
                Layout.fillWidth: true
                Kirigami.FormData.label: "Octave"
                visible: component.settingsStore.property("scale") !== "chromatic"
                text: "-"
                onClicked: {
                    var startingNote = component.settingsStore.property("startingNote")
                    if (startingNote - 12 > 0) {
                        component.settingsStore.setProperty("startingNote", startingNote - 12);
                    } else {
                        component.settingsStore.setProperty("startingNote",0);
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                visible: component.settingsStore.property("scale") != "chromatic"
                text: "+"
                onClicked: {
                    var startingNote = component.settingsStore.property("startingNote")
                    if (startingNote + 12 < 127){
                        component.settingsStore.setProperty("startingNote", startingNote + 12);
                    } else {
                        component.settingsStore.setProperty("startingNote", 120);
                    }
                }
            }
            QQC2.ComboBox {
                id: optionGrid
                Layout.fillWidth: true
                Kirigami.FormData.label: "Grid"
                model: gridModel
                textRole: "text"
                displayText: currentText
                currentIndex: 3

                onActivated: {
                    var data = gridModel.get(currentIndex)
                    if (data.row === 0 && data.column === 0) {
                        component.settingsStore.setProperty("rows", customRows.currentText);
                        component.settingsStore.setProperty("columns", customColumns.currentText);
                    } else {
                        component.settingsStore.setProperty("rows", data.row);
                        component.settingsStore.setProperty("columns", data.column);
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
                    component.settingsStore.setProperty("rows", currentText);
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
                    component.settingsStore.setProperty("columns", currentText);
                }
            }
            QQC2.Switch {
                Layout.fillWidth: true
                Kirigami.FormData.label: "Use Tap Position As Velocity"
                checked: component.settingsStore.property("positionalVelocity")
                onClicked: {
                    var positionalVelocity = component.settingsStore.property("positionalVelocity")
                    component.settingsStore.setProperty("positionalVelocity", !positionalVelocity);
                }
            }
        }
    }
}
