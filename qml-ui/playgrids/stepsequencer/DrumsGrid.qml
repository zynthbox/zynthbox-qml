/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Base Grid Component 

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
import io.zynthbox.components 1.0 as Zynthbox

ColumnLayout {
    id: component
    property QtObject model
    property bool positionalVelocity
    property bool showChosenPads: true
    property Item playgrid
    signal removeNote(QtObject note)
    signal notePressAndHold(QtObject note)

    property bool noteListeningStartedDuringPlayback: false
    property int noteListeningActivations: 0
    property var noteListeningNotes: []
    property var noteListeningVelocities: []
    function updateNoteListeningActivations() {
        updateNoteListeningActivationsTimer.restart();
    }
    Timer {
        id: updateNoteListeningActivationsTimer
        interval: 1; running: false; repeat: false;
        onTriggered: {
            if (component.noteListeningStartedDuringPlayback) {
                component.playgrid.heardNotes = component.noteListeningNotes;
                component.playgrid.heardVelocities = component.noteListeningVelocities;
                if (component.noteListeningActivations === 0) {
                    // Now, if we're back down to zero, then we've had all the notes released, and should assign all the heard notes to the heard notes thinger
                    component.noteListeningNotes = [];
                    component.noteListeningVelocities = [];
                    component.noteListeningStartedDuringPlayback = false;
                } else if (component.noteListeningActivations < 0) {
                    console.debug("stepsequencer drumsgrid: Problem, we've received too many off notes compared to on notes, this is bad and shouldn't really be happening.");
                    component.noteListeningActivations = 0;
                    component.noteListeningNotes = [];
                    component.noteListeningVelocities = [];
                    component.noteListeningStartedDuringPlayback = false;
                }
            }
        }
    }
    Repeater {
        model: visible ? component.model : null
        delegate: RowLayout {
            property var row: index
            Repeater {
                model: component.model.columnCount(component.model.index(index, 0))
                delegate: Zynthian.NotePad {
                    positionalVelocity: component.positionalVelocity
                    note: component.model.data(component.model.index(row, index), component.model.roles['note'])
                    property var metadata: component.model.data(component.model.index(row, index), component.model.roles['metadata'])
                    text: metadata != undefined && metadata["displayText"] != undefined ? metadata["displayText"] : ""
                    property color noteColor: note ? zynqtgui.theme_chooser.noteColors[note.midiNote] : ""
                    property color tintedNoteColor: Qt.lighter(noteColor, 1.2)
                    property bool weAreChosen: component.playgrid.heardNotes.indexOf(note) > -1
                        || (component.playgrid.heardNotes.length === 0 && component.playgrid.currentRowUniqueMidiNotes.indexOf(note.midiNote) > -1)
                    backgroundColor: component.showChosenPads && weAreChosen ? noteColor : Kirigami.Theme.textColor
                    playingBackgroundColor: component.showChosenPads && weAreChosen ? tintedNoteColor : noteColor
                    highlightOctaveStart: false
                    onNoteOn: {
                        if (Zynthbox.SyncTimer.timerRunning || component.noteListeningStartedDuringPlayback) {
                            component.noteListeningStartedDuringPlayback = true;
                            if (component.noteListeningActivations === 0) {
                                // Clear the current state, in case there's something there (otherwise things look a little weird)
                                component.playgrid.heardNotes = [];
                                component.playgrid.heardVelocities = [];
                            }
                            // Count up one tick for a note on message
                            component.noteListeningActivations = component.noteListeningActivations + 1;
                            var existingIndex = component.noteListeningNotes.indexOf(note);
                            if (existingIndex > -1) {
                                component.noteListeningNotes.splice(existingIndex, 1);
                                component.noteListeningVelocities.splice(existingIndex, 1);
                            }
                            component.noteListeningNotes.push(note);
                            component.noteListeningVelocities.push(velocity);
                            component.updateNoteListeningActivations();
                        }
                    }
                    onNoteOff: {
                        if (component.noteListeningStartedDuringPlayback) {
                            // Count down one for a note off message
                            component.noteListeningActivations = component.noteListeningActivations - 1;
                            component.updateNoteListeningActivations();
                        }
                    }
                    onNotePlayed: {
                        if (zynqtgui.backButtonPressed) {
                            component.removeNote(note);
                        }
                    }
                }
            }
        }
    }
}
