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

import org.zynthian.quick 1.0 as ZynQuick

QQC2.Button {
    id: component
    property bool positionalVelocity
    property var note

    // Pitch is -8192 to 8191 inclusive
    property int pitchValue: Math.max(-8192, Math.min(slidePoint.slideX * 8192 / width, 8191))
    onPitchValueChanged: ZynQuick.PlayGridManager.pitch = pitchValue
    property int modulationValue: Math.max(-127, Math.min(slidePoint.slideY * 127 / width, 127))
    onModulationValueChanged: ZynQuick.PlayGridManager.modulation = modulationValue;

    Layout.fillWidth: true
    Layout.fillHeight: true
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    property color focusColor: Kirigami.Theme.focusColor
    property color foregroundColor: Kirigami.Theme.backgroundColor
    property color backgroundColor: Kirigami.Theme.textColor
    property color borderColor: foregroundColor
    property color playingBackgroundColor: "#8bc34a"
    property color playingForegroundColor: foregroundColor

    background: Item {
        RowLayout {
            visible: component.note.subnotes.length > 0
            anchors.fill: parent
            spacing: 0
            Repeater {
                model: component.note.subnotes
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: modelData.isPlaying ? component.playingBackgroundColor : (modelData.midiNote % 12 === 0 ? component.focusColor : component.backgroundColor)
                    QQC2.Label {
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        clip: true
                        color: component.foregroundColor
                        text: modelData.name + modelData.octave
                    }
                }
            }
        }
        Rectangle {
            visible: component.note.subnotes.length === 0
            anchors.fill: parent
            color: {
                var color = component.backgroundColor;
                if (component.note) {
                    if (component.note.isPlaying) {
                        color = component.playingBackgroundColor;
                    } else {
                        if (component.scale !== "chromatic" &&
                            component.note.midiNote % 12 === 0
                        ) {
                            color = component.focusColor;
                        } else {
                            color = component.backgroundColor;
                        }
                    }
                }
                return color;
            }
            QQC2.Label {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                clip: true
                color: component.foregroundColor
                text: {
                    var text = "";
                    if (component.note && component.note.name != "") {
                        if (component.scale == "major") {
                            text = component.note.name
                        } else {
                            text = component.note.name + component.note.octave
                        }
                    }
                    return text;
                }
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
    }

    MultiPointTouchArea {
        anchors.fill: parent
        touchPoints: [
            TouchPoint {
                id: slidePoint;
                property double slideX: x < 0 ? Math.floor(x) : (x > component.width ? x - component.width : 0)
                property double slideY: y < 0 ? -Math.floor(y) : (y > component.height ? -(y - component.height) : 0)
                property var playingNote;
                onPressedChanged: {
                    if (pressed) {
                        var velocityValue = 64;
                        if (component.positionalVelocity) {
                            velocityValue = 127 - Math.floor(slidePoint.y * 127 / height);
                        } else {
                            // This seems slightly odd - but 1 is the very highest possible, and default is supposed to be a velocity of 64, so...
                            velocityValue = slidePoint.pressure > 0.99999 ? 64 : Math.floor(slidePoint.pressure * 127);
                        }
                        component.down = true;
                        component.focus = true;
                        playingNote = component.note;
                        ZynQuick.PlayGridManager.setNoteOn(playingNote, velocityValue)
                    } else {
                        component.down = false;
                        component.focus = false;
                        ZynQuick.PlayGridManager.setNoteOff(playingNote)
                        ZynQuick.PlayGridManager.pitch = 0;
                        ZynQuick.PlayGridManager.modulation = 0;
                    }
                }
            }
        ]
    }
}
