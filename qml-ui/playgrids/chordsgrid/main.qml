/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Base Chords Grid Component 

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
    grid: chordsGrid
    settings: chordsGridSettings
    name:'Chords Grid'
    // model: zynthian.playgrid.chordModel

    property QtObject settingsStore
    property int chordRows

    function populateGrid(){

        if (component.model){
            component.model.clear();
        } else {
            component.model = zynthian.playgrid.createNotesModel();
        }

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

        var chord_scales  = [
            "ionian",
            "dorian",
            "phrygian",
            "aeolian",
            "chromatic"
        ]

        var chord_scales_starts = [
            60,
            60,
            60,
            60,
            60
        ]

        var chord_rows = component.settingsStore.property("chordRows");
        var chord_notes = [];
        var diatonic_progressions = [0, 2, 4];

        for (var row = 0; row < chord_rows; ++row){

            var scale_index = 0;
            var row_data = [];
            var row_scale = scale_mode_map[chord_scales[row]]
            var col = chord_scales_starts[row];

            for (var i = 0; i < row_scale.length; ++i){

                var fake_midi_note = 0;
                var subnotes = [];
                for (var subnote_index = 0; subnote_index < diatonic_progressions.length; ++subnote_index){

                    var subnote_col = col;

                    for (var j = 0; j < diatonic_progressions[subnote_index]; ++j){

                        var subnote_scale_index = scale_index + j;
                        if (subnote_scale_index >= row_scale.length){
                            subnote_scale_index -= row_scale.length;
                        }
                        subnote_col += row_scale[subnote_scale_index]
                    }

                    var subnote = zynthian.playgrid.createNote(
                        note_int_to_str_map[subnote_col % 12],
                        scale_index,
                        Math.floor(subnote_col / 12),
                        subnote_col
                    );
                    subnotes.push(subnote);
                    fake_midi_note += (127 * subnote_index) + subnote_col

                }
                // Now create a Note object representing a music note for our current cell
                // This one's our container, and it will contain a series of subnotes which make up the scale
                var note = zynthian.playgrid.createNote(
                    note_int_to_str_map[col % 12],
                    scale_index,
                    Math.floor(col / 12),
                    fake_midi_note
                );

                note.subnotes = subnotes
                row_data.push(note)

                // Cycle scale index value to 0 if it reaches the end of scale mode map
                if (scale_index >=  row_scale.length) {
                    scale_index = 0
                }

                // Calculate the next note value using the scale mode map and scale index
                col += row_scale[scale_index]
                scale_index += 1
            }
            
            component.model.addRow(row_data);
        }
    }

    Component.onCompleted: {
        component.settingsStore = zynthian.playgrid.getSettingsStore("zynthian chordsgrid settings")
        component.settingsStore.setDefault("chordRows", 5);
        component.chordRows = component.settingsStore.property("chordRows");
        // component.settingsStore.setDefaultProperty("scale", zynthian.playgrid.scale);
        // component.settingsStore.setDefaultProperty("rows", zynthian.playgrid.rows);
        // component.settingsStore.setDefaultProperty("columns", zynthian.playgrid.columns);
        // component.settingsStore.setDefaultProperty("positionalVelocity", zynthian.playgrid.positionalVelocity);
        component.populateGrid();
    }

    Component {
        id: chordsGrid
        ColumnLayout {
            objectName: "chordsGrid"
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
                                    wrapMode: Text.Wrap
                                    text: {
                                        var text = "";
                                        if (note) {
                                            for (var i = 0; i < note.subnotes.length; ++i) {
                                                text += " " + note.subnotes[i].name + note.subnotes[i].octave
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
                                        id: chordSlidePoint;
                                        property double slideX: x < 0 ? Math.floor(x) : (x > playDelegate.width ? x - playDelegate.width : 0)
                                        property double slideY: y < 0 ? -Math.floor(y) : (y > playDelegate.height ? -(y - playDelegate.height) : 0)
                                    }
                                ]
                                property var playingNote;
                                onPressed: {
                                    if (chordSlidePoint.pressed) {
                                        var velocityValue = 64;
                                        if (zynthian.playgrid.positionalVelocity) {
                                            velocityValue = 127 - Math.floor(chordSlidePoint.y * 127 / height);
                                        } else {
                                            // This seems slightly odd - but 1 is the very highest possible, and default is supposed to be a velocity of 64, so...
                                            velocityValue = chordSlidePoint.pressure > 0.99999 ? 64 : Math.floor(chordSlidePoint.pressure * 127);
                                        }
                                        parent.down = true;
                                        focus = true;
                                        playingNote = note;
                                        zynthian.playgrid.setNoteOn(playingNote, velocityValue)
                                    }
                                }
                                onReleased: {
                                    if (!chordSlidePoint.pressed) {
                                        parent.down = false;
                                        focus = false;
                                        zynthian.playgrid.setNoteOff(playingNote)
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
        id: chordsGridSettings
        Kirigami.FormLayout {
            objectName: "chordsGridSettings"
            QQC2.ComboBox {
                Layout.fillWidth: true
                Kirigami.FormData.label: "Number Of Chord Rows"
                model: [3, 4, 5]
                currentIndex: {
                    for (var i = 0; i < count; ++i) {
                        if (component.chordRows === model[i]) {
                            return i;
                        }
                    }
                }
                onActivated: {
                    component.settingsStore.setProperty("chordRows",model[currentIndex])
                }
                // currentIndex: {
                //     for (var i = 0; i < count; ++i) {
                //         if (zynthian.playgrid.chordRows === model[i]) {
                //             return i;
                //         }
                //     }
                // }
                // onActivated: {
                //     zynthian.playgrid.chordRows = model[currentIndex];
                // }
            }
            Repeater {
                model: zynthian.playgrid.chordRows
                QQC2.ComboBox {
                    Layout.fillWidth: true
                    Kirigami.FormData.label: "Scale for row " + (index + 1)
                    property int repeaterIndex: index
                    model: scaleModel
                    textRole: "text"
                    displayText: currentText
                    currentIndex: {
                        var theScale = zynthian.playgrid.chordScales[repeaterIndex];
                        for (var i = 0; i < count; ++i) {
                            if (scaleModel.get(i).scale === theScale) {
                                return i;
                            }
                        }
                        return 0;
                    }
                    onActivated: {
                        zynthian.playgrid.setChordScale(repeaterIndex, scaleModel.get(currentIndex).scale);
                    }
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
        target: component.settingsStore
        onPropertyChanged: {
            if (component.settingsStore.mostRecentlyChanged() === "chordRows"){
                component.chordRows = component.settingsStore.property("chordRows");
            }
            populateGridTimer.start()
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
}