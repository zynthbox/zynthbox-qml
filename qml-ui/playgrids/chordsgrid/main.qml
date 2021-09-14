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
    miniGrid: chordsGridMini
    settings: chordsGridSettings
    name:'Chords Grid'
    octave: 5
    useOctaves: true

    property QtObject settingsStore
    property QtObject miniGridModel
    property int chordRows
    property var chordScales: ["ionian","dorian","phrygian","aeolian","chromatic"]
    property var miniChordScales: ["dorian","phrygian"]
    property bool positionalVelocity

    function fillModel(model, chord_rows, chord_scales) {
        console.log("Filling chords model " + model)
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

        var chord_scales_start = component.octave * 12;
        var chord_notes = [];
        var diatonic_progressions = [0, 2, 4];

        model.clear();
        for (var row = 0; row < chord_rows; ++row){

            var scale_index = 0;
            var row_data = [];
            var row_scale = scale_mode_map[chord_scales[row]]
            var col = chord_scales_start;

            for (var i = 0; i < row_scale.length; ++i){
                var subnotes = [];
                for (var subnote_index = 0; subnote_index < diatonic_progressions.length; ++subnote_index){

                    var subnote_col = col;

                    for (var j = 0; j < diatonic_progressions[subnote_index]; ++j){

                        var subnote_scale_index = scale_index + j;
                        if (subnote_scale_index >= row_scale.length){
                            subnote_scale_index -= row_scale.length;
                        }
                        subnote_col += row_scale[subnote_scale_index];
                    }

                    var subnote = zynthian.playgrid.getNote(
                        note_int_to_str_map[subnote_col % 12],
                        scale_index,
                        Math.floor(subnote_col / 12),
                        subnote_col
                    );
                    subnotes.push(subnote);

                }
                // Now create a compound note for the notes that make up our chord
                var note = zynthian.playgrid.getCompoundNote(subnotes);
                row_data.push(note)

                // Cycle scale index value to 0 if it reaches the end of scale mode map
                if (scale_index >=  row_scale.length) {
                    scale_index = 0
                }

                // Calculate the next note value using the scale mode map and scale index
                col += row_scale[scale_index]
                scale_index += 1
            }

            model.addRow(row_data);
        }
    }

    function populateGrid(){
        var chord_rows = component.settingsStore.property("chordRows");
        fillModel(component.model, chord_rows, component.settingsStore.property("chordScales"))
        fillModel(component.miniGridModel, 2, component.settingsStore.property("miniChordScales"))
    }

    onOctaveChanged: {
        component.settingsStore.setProperty("startingNote", component.octave * 12);
    }

    Component.onCompleted: {
        component.settingsStore = zynthian.playgrid.getSettingsStore("zynthian chordsgrid settings")

        component.settingsStore.setDefault("chordRows", 5);
        component.settingsStore.setDefault("startingNote", component.octave * 12);
        component.settingsStore.setDefault("chordScales", ["ionian","dorian","phrygian","aeolian","chromatic"])
        component.settingsStore.setDefault("miniChordScales", ["dorian","phrygian"])
        component.settingsStore.setDefault("positionalVelocity",true)

        component.chordRows = component.settingsStore.property("chordRows");
        component.chordScales = component.settingsStore.property("chordScales");
        component.miniChordScales = component.settingsStore.property("miniChordScales");
        component.positionalVelocity = component.settingsStore.property("positionalVelocity")

        component.model = zynthian.playgrid.getNotesModel("zynthian chordsgrid main")
        component.miniGridModel = zynthian.playgrid.getNotesModel("zynthian chordsgrid mini")
        if (component.model.rows == 0 || component.miniGridModel.rows == 0) {
            populateGridTimer.restart()
        }
    }

    Component {
        id: chordsGrid
        ChordsGrid {
            model: component.model
            settingsStore: component.settingsStore
            currentNoteName: component.currentNoteName
            chordRows: component.chordRows
            positionalVelocity: component.positionalVelocity
        }
    }

    Component {
        id: chordsGridMini
        ChordsGrid {
            model: component.miniGridModel
            settingsStore: component.settingsStore
            currentNoteName: component.currentNoteName
            chordRows: 2
            positionalVelocity: component.positionalVelocity
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
            }
            Repeater {
                model:  component.settingsStore.property("chordRows")
                QQC2.ComboBox {
                    Layout.fillWidth: true
                    Kirigami.FormData.label: "Scale for row " + (index + 1)
                    property int repeaterIndex: index
                    model: scaleModel
                    textRole: "text"
                    displayText: currentText
                    currentIndex: {
                        var theScale = component.chordScales[repeaterIndex];
                        for (var i = 0; i < count; ++i) {
                            if (scaleModel.get(i).scale === theScale) {
                                return i;
                            }
                        }
                        return 0;
                    }
                    onActivated: {
                        var chordScales = component.chordScales;
                        chordScales[repeaterIndex] =  scaleModel.get(currentIndex).scale;
                        component.settingsStore.setProperty("chordScales", chordScales)
                    }
                }
            }
            Repeater {
                model:  component.settingsStore.property("miniChordScales")
                QQC2.ComboBox {
                    Layout.fillWidth: true
                    Kirigami.FormData.label: "Scale for minigrid row " + (index + 1)
                    property int repeaterIndex: index
                    model: scaleModel
                    textRole: "text"
                    displayText: currentText
                    currentIndex: {
                        var theScale = component.miniChordScales[repeaterIndex];
                        for (var i = 0; i < count; ++i) {
                            if (scaleModel.get(i).scale === theScale) {
                                return i;
                            }
                        }
                        return 0;
                    }
                    onActivated: {
                        var miniChordScales = component.miniChordScales;
                        miniChordScales[repeaterIndex] =  scaleModel.get(currentIndex).scale;
                        component.settingsStore.setProperty("miniChordScales", miniChordScales)
                    }
                }
            }
            QQC2.Switch {
                Layout.fillWidth: true
                Kirigami.FormData.label: "Use Tap Position As Velocity"
                checked: component.positionalVelocity
                onClicked: {
                    component.settingsStore.setProperty("positionalVelocity", !component.positionalVelocity)
                }
            }
        }
    }

    function stringListsEqual(list1, list2) {
        var equal = true;
        if (list1.length === list2.length) {
            for (var i = 0; i < list1.length; ++i) {
                if (list1[i] !== list2[i]) {
                    equal = false;
                    break;
                }
            }
        } else {
            equal = false;
        }
        return equal;
    }
    Connections {
        target: component.settingsStore
        onPropertyChanged: {
            var mostRecentlyChanged = component.settingsStore.mostRecentlyChanged();
//             console.log("A property named " + mostRecentlyChanged + " has changed to " + component.settingsStore.property(mostRecentlyChanged))
            var changed = true;
            if (mostRecentlyChanged === "chordRows" && component.chordRows != component.settingsStore.property("chordRows")){
                component.chordRows = component.settingsStore.property("chordRows");
            } else if (mostRecentlyChanged === "chordScales" && !stringListsEqual(component.chordScales, component.settingsStore.property("chordScales"))){
                component.chordScales = component.settingsStore.property("chordScales");
            } else if (mostRecentlyChanged === "miniChordScales" && !stringListsEqual(component.miniChordScales, component.settingsStore.property("miniChordScales"))){
                component.miniChordScales = component.settingsStore.property("miniChordScales");
            } else if (mostRecentlyChanged === "positionalVelocity" && component.positionalVelocity != component.settingsStore.property("positionalVelocity")){
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

}
