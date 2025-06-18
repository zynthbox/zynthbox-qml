/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Play Grid Note Pad Component

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

import io.zynthbox.components 1.0 as Zynthbox

Item {
    id: component
    property bool positionalVelocity
    property var note
    property string text
    property bool highlightOctaveStart: true
    signal notePlayed(QtObject note, int velocity);
    signal noteOn(QtObject note, int velocity);
    signal noteOff(QtObject note);

    // Pitch is -8192 to 8191 inclusive
    property int pitchValue: Math.max(-8192, Math.min(slidePoint.slideX * 8192 / width, 8191))
    onPitchValueChanged: {
        if (slidePoint.playingNote) {
            slidePoint.playingNote.sendPitchChange(pitchValue);
        }
    }
    property int modulationValue: Math.max(-127, Math.min(slidePoint.slideY * 127 / width, 127))
    onModulationValueChanged: Zynthbox.PlayGridManager.modulation = modulationValue;

    // Whether or not pressing and holding the button should be visualised
    property bool visualPressAndHold: false
    // Whether or not we are currently holding the button down and are past the press and hold threshold
    property bool pressingAndHolding: false
    // Fired when the press and hold timeout is reached
    signal pressAndHold();

    Layout.fillWidth: true
    Layout.fillHeight: true
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    property color backgroundColor: component.visible ? (Kirigami.Theme.textColor) : ""
    property color playingBackgroundColor: component.visible ? ("#8bc34a") : ""
    readonly property color playingForegroundColor: component.visible ? (foregroundColor) : ""
    readonly property color firstNoteBackground: component.visible ? (component.highlightOctaveStart ? Kirigami.Theme.focusColor : backgroundColor) : ""
    readonly property color foregroundColor: component.visible ? (Kirigami.Theme.backgroundColor) : ""
    readonly property color borderColor: component.visible ? (foregroundColor) : ""

    readonly property QtObject currentSequence: zynqtgui.sketchpad.song != null ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName) : null
    RowLayout {
        id: subnoteLayout
        visible: typeof(component.note) !== "undefined" && component.note != null && component.note.subnotes.length > 0
        anchors.fill: parent
        spacing: 0
        Repeater {
            model: component.note ? component.note.subnotes : 0
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: component.visible && modelData.isPlaying ? component.playingBackgroundColor : (modelData.midiNote % 12 === 0 ? component.firstNoteBackground : component.backgroundColor)
                opacity: subnoteLayout.visible && component.currentSequence && component.currentSequence.activePatternObject
                    ? Zynthbox.KeyScales.midiNoteOnScale(modelData.midiNote, component.currentSequence.activePatternObject.scaleKey, component.currentSequence.activePatternObject.pitchKey, component.currentSequence.activePatternObject.octaveKey)
                        ? 1
                        : 0.3
                    : 1
            }
        }
    }
    Rectangle {
        visible: typeof(component.note) !== "undefined" && component.note != null && component.note.subnotes.length === 0
        anchors.fill: parent
        opacity: visible && component.currentSequence && component.currentSequence.activePatternObject
            ? Zynthbox.KeyScales.midiNoteOnScale(component.note.midiNote, component.currentSequence.activePatternObject.scaleKey, component.currentSequence.activePatternObject.pitchKey, component.currentSequence.activePatternObject.octaveKey)
                ? 1
                : 0.3
            : 1
        color: {
            var color = component.backgroundColor;
            if (component.visible && component.note) {
                if (component.note.isPlaying) {
                    color = component.playingBackgroundColor;
                } else {
                    if (component.scale !== "chromatic" &&
                        component.note.midiNote % 12 === 0
                    ) {
                        color = component.firstNoteBackground;
                    } else {
                        color = component.backgroundColor;
                    }
                }
            }
            return color;
        }
    }
    QQC2.Label {
        id: padLabel
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: component.foregroundColor
        text: {
            var text = "";
            if (component.text == "") {
                if (component.note) {
                    if (component.note.subnotes.length === 0) {
                        if (component.scale == "major") {
                            text = component.note.name;
                        } else {
                            text = component.note.name + (component.note.octave - 1);
                        }
                    } else {
                        text = Zynthbox.Chords.symbol(component.note.subnotes, component.currentSequence.activePatternObject.scaleKey, component.currentSequence.activePatternObject.pitchKey, component.currentSequence.activePatternObject.octaveKey);
                    }
                }
            } else {
                text = component.text;
            }
            return text;
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: 2
        border {
            width: 1
            color: parent.focus ? Kirigami.Theme.highlightColor : "#e5e5e5"
        }
        color: "transparent"
    }
    Rectangle {
        id: pressAndHoldVisualiser
        anchors {
            right: parent.right
            leftMargin: width / 2
            bottom: parent.bottom
        }
        width: Kirigami.Units.smallSpacing
        visible: component.visualPressAndHold
        color: component.borderColor
        height: 0
        opacity: 0
        states: [
            State {
                name: "held"; when: (component.visualPressAndHold && longPressTimer.running || component.pressingAndHolding);
                PropertyChanges { target: pressAndHoldVisualiser; height: component.height; opacity: 1 }
            }
        ]
        transitions: [
            Transition {
                from: ""; to: "held";
                NumberAnimation { property: "height"; duration: longPressTimer.interval; }
                NumberAnimation { property: "opacity"; duration: longPressTimer.interval; }
            }
        ]
        Timer {
            id: longPressTimer;
            interval: 3000; repeat: false; running: false
            property bool insideBounds: false;
            onTriggered: {
                if (insideBounds) {
                    component.pressAndHold();
                }
                component.pressingAndHolding = true;
            }
        }
    }

    MultiPointTouchArea {
        anchors.fill: parent
        touchPoints: [
            TouchPoint {
                id: slidePoint;
                property double slideX: x < 0 ? Math.floor(x) : (x > component.width ? x - component.width : 0)
                property double slideY: y < 0 ? -Math.floor(y) : (y > component.height ? -(y - component.height) : 0)
                property var playingNote;
                function updateInsideBounds() {
                    if (pressed) {
                        if (x > -1 && y > -1 && x < component.width && y < component.height) {
                            longPressTimer.insideBounds = true;
                        } else {
                            longPressTimer.insideBounds = false;
                        }
                    }
                }
                onXChanged: updateInsideBounds();
                onYChanged: updateInsideBounds();
                onPressedChanged: {
                    if (pressed) {
                        var velocityValue = 127;
                        if (component.positionalVelocity) {
                            velocityValue = 127 - Math.floor(slidePoint.y * 127 / height);
                        } else {
                            // This seems slightly odd - but 1 is the very highest possible, and default is supposed to be a velocity of 127, so...
                            velocityValue = slidePoint.pressure > 0.99999 ? 127 : Math.floor(slidePoint.pressure * 127);
                        }
                        slidePoint.playingNote = component.note;
                        slidePoint.playingNote.setOn(velocityValue);
                        component.notePlayed(slidePoint.playingNote, velocityValue);
                        component.noteOn(slidePoint.playingNote, velocityValue);
                        component.focus = true;
                        slidePoint.updateInsideBounds();
                        longPressTimer.restart();
                    } else {
                        // console.log("We've got a playing note set, turn that off");
                        slidePoint.playingNote.setOff();
                        component.noteOff(slidePoint.playingNote);
                        slidePoint.playingNote.sendPitchChange(0);
                        slidePoint.playingNote = undefined;
                        Zynthbox.PlayGridManager.modulation = 0;
                        component.pressingAndHolding = false;
                        longPressTimer.stop();
                    }
                }
            }
        ]
    }
}
