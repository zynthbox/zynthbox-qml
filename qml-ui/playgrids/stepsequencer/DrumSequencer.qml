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

import io.zynthbox.imp 1.0 as IMP
import io.zynthbox.ui 1.0 as ZUI
import io.zynthbox.components 1.0 as Zynthbox

Item {
    id: component
    property QtObject patternModel
    property QtObject sequencerPrivate
    property QtObject playGrid
    QtObject {
        id: _private
        readonly property int selectedStepGlobal: (sequencerPrivate.workingPatternModel.width * (sequencerPrivate.workingPatternModel.activeBar + sequencerPrivate.workingPatternModel.bankOffset)) + sequencerPrivate.selectedStep
        readonly property int currentRow: sequencerPrivate.workingPatternModel.activeBar + sequencerPrivate.workingPatternModel.bankOffset
        readonly property var noteColors: zynqtgui.theme_chooser.noteColors
        readonly property string trackType: applicationWindow().selectedChannel ? applicationWindow().selectedChannel.trackType : ""
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
                Layout.preferredHeight: Kirigami.Units.gridUnit
                spacing: 0
                property int midiNote: component.patternModel ? component.patternModel.gridModelStartNote + index : 60
                readonly property QtObject note: component.patternModel ? Zynthbox.PlayGridManager.getNote(midiNote, component.patternModel.sketchpadTrack) : null
                readonly property bool noteIsHeard: applicationWindow().globalSequencer.heardNotes.includes(noteRow.note)
                readonly property color noteColor: _private.noteColors[midiNote]
                readonly property bool hasClips: component.patternModel ? component.patternModel.clipNotesModel.data(component.patternModel.clipNotesModel.index(midiNote), component.patternModel.clipNotesModel.roles["hasClips"]) : false
                readonly property var clips: component.patternModel ? component.patternModel.clipNotesModel.data(component.patternModel.clipNotesModel.index(midiNote), component.patternModel.clipNotesModel.roles["clips"]) : []
                readonly property QtObject audioSource: clips.length === 1 ? clips[0] : null
                opacity: hasClips ? 1.0 : 0.5
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                    ZUI.NotePad {
                        id: noteRowPad
                        anchors {
                            top: parent.top
                            left: parent.left
                            bottom: parent.bottom
                            margins: Kirigami.Units.smallSpacing
                        }
                        width: height
                        note: noteRow.note
                        highlightOctaveStart: false
                    }
                    IMP.SampleVisualiser {
                        anchors {
                            top: parent.top
                            left: noteRowPad.right
                            right: parent.right
                            bottom: parent.bottom
                            margins: Kirigami.Units.smallSpacing
                        }
                        visible: noteRow.audioSource !== null
                        audioSource: noteRow.audioSource
                        trackType: _private.trackType
                        MultiPointTouchArea {
                            anchors.fill: parent
                            touchPoints: [
                                TouchPoint {
                                    id: slidePoint
                                    property var currentValue: undefined
                                    property var pressedTime: undefined
                                    onPressedChanged: {
                                        if (pressed) {
                                            pressedTime = Date.now();
                                            // currentValue = component.preferInterpretedValue ? component.paramInterpretedDefault : parseInt(component.paramValue);
                                            applicationWindow().globalSequencer.setHeardData(noteRow.midiNote, component.patternModel.defaultVelocity);
                                        } else {
                                            // Only reset if the timing was reasonably a tap (arbitrary number here, should be a global constant somewhere we can use for this)
                                            if (/*Math.abs(component.paramValue - currentValue) < 1 && */(Date.now() - pressedTime) < 300) {
                                                // component.setNewValue(component.paramDefault);
                                            }
                                            currentValue = undefined;
                                        }
                                    }
                                    onXChanged: {
                                        if (pressed && currentValue !== undefined) {
                                            // var delta = Math.round((slidePoint.x - slidePoint.startX) * (component.scrollWidth / paramLabel.width));
                                            // component.setNewValue(Math.min(Math.max(currentValue + delta, component.paramMin), component.paramMax));
                                        }
                                    }
                                }
                            ]
                        }
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
                        readonly property QtObject stepNote: _private.barNotes.length > index ? _private.barNotes[index] : null
                        property bool stepEnabledForNote: subnoteIndex > -1
                        property int velocity: 0
                        property int delay: 0
                        property int duration: 0
                        property int subnoteIndex: -1
                        Connections {
                            target: component
                            onUpdateStepData: {
                                if (component.patternModel) {
                                    stepDelegate.subnoteIndex = component.patternModel.subnoteIndex(_private.currentRow, stepDelegate.delegateIndex, noteRow.midiNote);
                                } else {
                                    stepDelegate.subnoteIndex = -1;
                                }
                                stepDelegate.velocity = stepDelegate.subnoteIndex > -1 ? component.patternModel.workingModel.subnoteMetadata(_private.currentRow, stepDelegate.delegateIndex, stepDelegate.subnoteIndex, "velocity") : 0;
                                let noteDuration = stepDelegate.subnoteIndex > -1 ? component.patternModel.workingModel.subnoteMetadata(_private.currentRow, stepDelegate.delegateIndex, stepDelegate.subnoteIndex, "duration") : 0;
                                if (!noteDuration) {
                                    noteDuration = 0;
                                }
                                stepDelegate.duration = noteDuration;
                                let noteDelay = stepDelegate.subnoteIndex > -1 ? component.patternModel.workingModel.subnoteMetadata(_private.currentRow, stepDelegate.delegateIndex, stepDelegate.subnoteIndex, "delay") : 0;
                                if (!noteDelay) {
                                    noteDelay = 0;
                                }
                                stepDelegate.delay = noteDelay;
                            }
                        }
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit
                        Rectangle {
                            id: focusRectangle
                            anchors.fill: parent
                            color: "transparent"
                            border {
                                width: 1
                                color: "white"
                            }
                            visible: applicationWindow().globalSequencer.mostRecentlyInteractedStep === stepDelegate.stepIndex && noteRow.noteIsHeard
                        }
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
                            color: "white"
                            Rectangle {
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                    margins: Kirigami.Units.smallSpacing
                                }
                                height: Kirigami.Units.largeSpacing
                                color: stepDelegate.stepEnabledForNote ? noteRow.noteColor : "grey"
                            }
                            Rectangle {
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    leftMargin: Kirigami.Units.smallSpacing
                                    topMargin: Kirigami.Units.smallSpacing * 2 + Kirigami.Units.largeSpacing
                                }
                                height: Kirigami.Units.smallSpacing
                                readonly property int maxWidth: parent.width - (Kirigami.Units.smallSpacing * 2)
                                width: maxWidth * (stepDelegate.velocity / 127)
                                color: "grey"
                                QQC2.Label {
                                    anchors {
                                        top: parent.bottom
                                        left: parent.left
                                    }
                                    visible: focusRectangle.visible && stepDelegate.stepEnabledForNote
                                    font {
                                        pointSize: undefined
                                        pixelSize: 7
                                    }
                                    color: "grey"
                                    text: qsTr("%1/127").arg(stepDelegate.velocity)
                                }
                            }
                            Rectangle {
                                visible: focusRectangle.visible && stepDelegate.stepEnabledForNote && (stepDelegate.delay !== 0 || stepDelegate.duration !== 0)
                                color: "blue"
                                anchors.top: parent.bottom
                                height: Kirigami.Units.smallSpacing - 1
                                width: parent.width * (actualDuration / component.sequencerPrivate.workingPatternModel.stepLength)
                                x: parent.width * (stepDelegate.delay / component.sequencerPrivate.workingPatternModel.stepLength)
                                readonly property int actualDuration: stepDelegate.duration === 0
                                    ? component.sequencerPrivate.workingPatternModel.stepLength
                                    : stepDelegate.duration < 0
                                        ? component.sequencerPrivate.workingPatternModel.defaultNoteDuration === 0
                                            ? component.sequencerPrivate.workingPatternModel.stepLength
                                            : component.sequencerPrivate.workingPatternModel.defaultNoteDuration
                                        : stepDelegate.duration
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            // TODO allow tap-drag to toggle a bunch of step in a range
                            onClicked: {
                                if (component.sequencerPrivate.toggleStepOnTouchSelect) {
                                    if (stepDelegate.stepEnabledForNote) {
                                        _private.disableNoteForStep(noteRow.midiNote, stepDelegate.stepIndex);
                                    } else {
                                        _private.enableNoteForStep(noteRow.midiNote, stepDelegate.stepIndex);
                                    }
                                }
                                applicationWindow().globalSequencer.setHeardData(noteRow.midiNote, component.patternModel.defaultVelocity);
                                applicationWindow().globalSequencer.setMostRecentlyInteractedStep(stepDelegate.stepIndex);
                            }
                        }
                    }
                }
            }
        }
        RowLayout {
            spacing: 0
            Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
            Layout.margins: Kirigami.Units.smallSpacing
            QQC2.Button {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                text: qsTr("Select Only")
                checked: component.sequencerPrivate.toggleStepOnTouchSelect === false
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        component.playGrid.setProperty("toggleStepOnTouchSelect", false);
                    }
                }
            }
            QQC2.Button {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                text: qsTr("Select & Toggle")
                checked: component.sequencerPrivate.toggleStepOnTouchSelect === true
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        component.playGrid.setProperty("toggleStepOnTouchSelect", true);
                    }
                }
            }
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
            }
            QQC2.Button {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                text: qsTr("General")
                checked: applicationWindow().globalSequencer.parameterPage === 0
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        applicationWindow().globalSequencer.setParameterPage(0);
                    }
                }
            }
            QQC2.Button {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                text: qsTr("Probability")
                checked: applicationWindow().globalSequencer.parameterPage === 1
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        applicationWindow().globalSequencer.setParameterPage(1);
                    }
                }
            }
            QQC2.Button {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                text: qsTr("Ratchet")
                checked: applicationWindow().globalSequencer.parameterPage === 2
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        applicationWindow().globalSequencer.setParameterPage(2);
                    }
                }
            }
        }
    }
}
