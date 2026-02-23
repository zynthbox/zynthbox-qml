/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

A per-note step-wise editor view for the sequencer, inspired by things like FLStudio's channel rack

Copyright (C) 2026 Dan Leinir Turthra Jensen <admin@leinir.dk>

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

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.7 as Kirigami

import io.zynthbox.ui 1.0 as ZUI
import io.zynthbox.components 1.0 as Zynthbox

Item {
    id: component
    property QtObject patternModel
    QtObject {
        id: _private
        function enableNoteForStep(midiNote, step) {
            let column = step % component.patternModel.width;
            let row = Math.floor(step / component.patternModel.width);
            let existingSubnoteIndex = component.patternModel.subnoteIndex(row, column, midiNote);
            if (existingSubnoteIndex == -1) {
                // The note doesn't exist, add it with the current velocity (or accents as per held down up/down arrows)
                let applyAccent = false;
                let applyGhost = false;
                if (zynqtgui.upButtonPressed) {
                    zynqtgui.ignoreNextUpButtonPress = true;
                    applyAccent = true;
                }
                if (zynqtgui.downButtonPressed) {
                    zynqtgui.ignoreNextDownButtonPress = true;
                    applyGhost = true;
                }
                let velocityAdjustment = applyAccent
                    ? applyGhost
                        ? 1 // Apply both, so we land back at 1.0 times velocity
                        : 1.5 // Apply only accent, making it 1.5 times velocity
                    : applyGhost
                        ? 0.5 // Apply only ghost, making it 0.5 times velocity
                        : 1 // Apply neither, leaving us at 1.0 times velocity
                let newSubnoteIndex = component.patternModel.insertSubnoteSorted(row, column, Zynthbox.PlayGridManager.getNote(midiNote, component.patternModel.sketchpadTrack));
                component.patternModel.setSubnoteMetadata(row, column, newSubnoteIndex, "velocity", ZUI.CommonUtils.clamp(Math.round(component.patternModel.defaultVelocity * velocityAdjustment), 1, 127));
                applicationWindow().globalSequencer.setHeardData(midiNote, component.patternModel.defaultVelocity);
            }
        }
        function disableNoteForStep(midiNote, step) {
            component.patternModel.removeSubnoteByNoteValue(midiNote, step, step);
            applicationWindow().globalSequencer.setHeardData(midiNote, component.patternModel.defaultVelocity);
        }
        function updateBarNotes() {
            barNotesUpdater.restart();
        }
    }
    Timer {
        id: barNotesUpdater
        interval: 1; running: false; repeat: false;
        onTriggered: {
            component.updateStepData();
        }
    }
    signal updateStepData();
    Connections {
        target: patternModel
        onLastModifiedChanged: _private.updateBarNotes()
    }
    onPatternModelChanged: _private.updateBarNotes()
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Repeater {
            model: Zynthbox.Plugin.sketchpadSlotCount * 2
            RowLayout {
                id: noteRow
                property int midiNote: component.patternModel ? component.patternModel.gridModelStartNote + index : 60
                readonly property QtObject note: component.patternModel ? Zynthbox.PlayGridManager.getNote(midiNote, component.patternModel.sketchpadTrack) : null
                spacing: 0
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                    QQC2.Label {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: noteRow.note ? noteRow.note.name + (noteRow.note.octave - 1) + " (slot gain, sample name)" : ""
                    }
                }
                Repeater {
                    model: 16 // This really should be patternModel's max width (underneath, we ensure only the delegates at lower than the pattern's width are visible)
                    Item {
                        id: stepDelegate
                        visible: component.patternModel && index < component.patternModel.width && stepIndex < component.patternModel.patternLength
                        readonly property int delegateIndex: index
                        readonly property int stepIndex: component.patternModel ? (component.patternModel.activeBar * component.patternModel.width) + index : 0
                        readonly property bool currentlyPlayingStep: component.patternModel && component.patternModel.isPlaying ? component.patternModel.playbackPosition === stepIndex : false
                        property QtObject stepNote: _private.barNotes.length > index ? _private.barNotes[index] : null
                        property bool stepEnabledForNote: subnoteIndex > -1
                        property int subnoteIndex: -1
                        Connections {
                            target: component
                            onUpdateStepData: {
                                if (component.patternModel) {
                                    stepDelegate.subnoteIndex = component.patternModel.subnoteIndex(component.patternModel.activeBar, stepDelegate.delegateIndex, noteRow.midiNote);
                                } else {
                                    stepDelegate.subnoteIndex = -1;
                                }
                            }
                        }
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit
                        Rectangle {
                            anchors.fill: parent
                            opacity: stepDelegate.currentlyPlayingStep ? 1 : 0
                            color: component.patternModel && component.patternModel.recordLive ? "red" : "yellow"
                        }
                        Rectangle {
                            anchors {
                                fill: parent
                                margins: Kirigami.Units.smallSpacing
                            }
                            color: stepDelegate.stepEnabledForNote ? "blue" : "grey"
                        }
                        MouseArea {
                            anchors.fill: parent
                            // TODO allow tap-drag to toggle a bunch of step in a range
                            onClicked: {
                                if (stepDelegate.stepEnabledForNote) {
                                    _private.disableNoteForStep(noteRow.midiNote, stepDelegate.stepIndex);
                                } else {
                                    _private.enableNoteForStep(noteRow.midiNote, stepDelegate.stepIndex);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
