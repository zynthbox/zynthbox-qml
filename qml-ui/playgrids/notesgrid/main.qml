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
    settings: notesGridSettings
    name:'Notes Grid'
    model: zynthian.playgrid.model

    function populateGrid(){
        
        var note_int_to_str_map = [
            "C",
            "C#",
            "D",
            "D#",
            "E",
            "F",
            "F#",
            "G",
            "G#",
            "A",
            "A#",
            "B",
        ]

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

        var col = zynthian.playgrid.startingNote;
        var scaleArray = scale_mode_map[zynthian.playgrid.scale];
        var scale_index = 0;

        component.model = zynthian.playgrid.createNotesModel();

        for (var row = 0; row < zynthian.playgrid.rows; ++row){

            var notes = [];
            
            for (var i = 0; i < zynthian.playgrid.columns; ++i) {

                var note = zynthian.playgrid.createNote(
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

            if (zynthian.playgrid.scale !== "chromatic"){ 
                col = zynthian.playgrid.startingNote + (zynthian.playgrid.columns * row);
                scale_index = 0;
                for (var x = 0; x < 3; ++x){

                    col += scaleArray[ scale_index % scaleArray.length ];
                    console.log(col, "++++ col ++++");
                    scale_index = (scale_index + 1) %  scaleArray.length;
                    console.log(scale_index," ++++ scale_index ++++");

                }

            }

            component.model.addRow(notes);
        }
    }

    Component.onCompleted: {
        populateGrid();
    }

    Component {
        id: notesGrid
        ColumnLayout {
            objectName: "notesGrid"
            spacing: 0
            anchors.margins: 5

            Repeater {
                model: component.model
                delegate: RowLayout {
                    property var row: index

                    Layout.margins: 2.5

                    Repeater {
                        model: component.model.columnCount(component.model.index(index, 0))
                        delegate: QQC2.Button {
                            id: playDelegate
                            property var column: index
                            property var note: component.model.data(component.model.index(row, column), component.model.roles['note'])

                            // Pitch is -8192 to 8191 inclusive
                            property int pitchValue: Math.max(-8192, Math.min(pitchModPoint.pitchModX * 8192 / width, 8191))
                            onPitchValueChanged: zynthian.playgrid.pitch = pitchValue
                            property int modulationValue: Math.max(-127, Math.min(pitchModPoint.pitchModY * 127 / width, 127))

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            background: Rectangle {
                                radius: 2
                                border {
                                    width: 1
                                    color: parent.focus ? Kirigami.Theme.highlightColor : "#e5e5e5"
                                }
                                color: {
                                    var color = "white";
                                    if (note) {
                                        if (note.isPlaying) {
                                            color = "#8bc34a";
                                        } else {
                                            if (zynthian.playgrid.scale !== "chromatic" &&
                                                note.name === component.currentNoteName
                                            ) {
                                                color = Kirigami.Theme.focusColor;
                                            } else {
                                                color = "white";
                                            }
                                        }
                                    }
                                    return color;
                                }

                                Text {
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: {
                                        var text = "";
                                        if (note && note.name != "") {
                                            if (zynthian.playgrid.scale == "major") {
                                                text = note.name
                                            } else {
                                                text = note.name + note.octave
                                            }
                                        }
                                        return text;
                                    }
                                }
                            }

                            MultiPointTouchArea {
                                anchors.fill: parent
                                touchPoints: [
                                    TouchPoint {
                                        id: pitchModPoint;
                                        property double pitchModX: x < 0 ? Math.floor(x) : (x > playDelegate.width ? x - playDelegate.width : 0)
                                        property double pitchModY: y < 0 ? -Math.floor(y) : (y > playDelegate.height ? -(y - playDelegate.height) : 0)
                                    }
                                ]
                                property var playingNote;
                                onPressed: {
                                    if (pitchModPoint.pressed) {
                                        var velocityValue = 64;
                                        if (zynthian.playgrid.positionalVelocity) {
                                            velocityValue = 127 - Math.floor(pitchModPoint.y * 127 / height);
                                        } else {
                                            // This seems slightly odd - but 1 is the very highest possible, and default is supposed to be a velocity of 64, so...
                                            velocityValue = pitchModPoint.pressure > 0.99999 ? 64 : Math.floor(pitchModPoint.pressure * 127);
                                        }
                                        parent.down = true;
                                        focus = true;
                                        playingNote = note;
                                        zynthian.playgrid.setNoteOn(playingNote, velocityValue);
                                    }
                                }
                                onReleased: {
                                    if (!pitchModPoint.pressed) {
                                        parent.down = false;
                                        focus = false;
                                        zynthian.playgrid.setNoteOff(playingNote);
                                        zynthian.playgrid.pitch = 0
                                    }
                                }
                            }
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
                model: scaleModel
                textRole: "text"
                displayText: currentText
                currentIndex: 1

                onActivated: {
                    zynthian.playgrid.startingNote = 36;
                    zynthian.playgrid.scale = scaleModel.get(currentIndex).scale
                }
            }
            QQC2.ComboBox {
                id: comboKey
                Layout.fillWidth: true
                Kirigami.FormData.label: "Key"
                visible: zynthian.playgrid.scale == "chromatic"
                model: keyModel
                textRole: "text"
                displayText: currentText
                currentIndex: 0

                onActivated: {
                    zynthian.playgrid.startingNote = keyModel.get(currentIndex).note;
                }
            }

            QQC2.Button {
                Layout.fillWidth: true
                Kirigami.FormData.label: "Transpose"
                visible: zynthian.playgrid.scale == "chromatic"
                text: "-"
                onClicked: {
                    if (zynthian.playgrid.startingNote - 1 > 0) {
                        zynthian.playgrid.startingNote--;
                    } else {
                        zynthian.playgrid.startingNote = 0;
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                visible: zynthian.playgrid.scale == "chromatic"
                text: "+"
                onClicked: {
                    zynthian.playgrid.startingNote++;
                }
            }

            QQC2.Button {
                Layout.fillWidth: true
                Kirigami.FormData.label: "Octave"
                visible: zynthian.playgrid.scale != "chromatic"
                text: "-"
                onClicked: {
                    if (zynthian.playgrid.startingNote - 12 > 0) {
                        zynthian.playgrid.startingNote = zynthian.playgrid.startingNote - 12;
                    } else {
                        zynthian.playgrid.startingNote = 0;
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                visible: zynthian.playgrid.scale != "chromatic"
                text: "+"
                onClicked: {
                    zynthian.playgrid.startingNote = zynthian.playgrid.startingNote + 12;
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
                        zynthian.playgrid.rows = customRows.currentText;
                        zynthian.playgrid.columns = customColumns.currentText;
                    } else {
                        zynthian.playgrid.rows = data.row;
                        zynthian.playgrid.columns = data.column;
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
                    zynthian.playgrid.rows = currentText;
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
                    zynthian.playgrid.columns = currentText;
                }
            }
            QQC2.Switch {
                Layout.fillWidth: true
                Kirigami.FormData.label: "Use Tap Position As Velocity"
                checked: zynthian.playgrid.positionalVelocity
                onClicked: {
                    zynthian.playgrid.positionalVelocity = !zynthian.playgrid.positionalVelocity
                }
            }
        }
    }

    Connections {
        target: zynthian.playgrid
        onScaleChanged: {
            component.populateGrid();
        }
    }
}