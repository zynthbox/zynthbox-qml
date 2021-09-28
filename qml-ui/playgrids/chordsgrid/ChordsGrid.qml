/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Base Grid Component 

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

ColumnLayout {
    id: component
    property QtObject model
    property bool positionalVelocity
    property Item playgrid

    spacing: 0
    anchors.margins: 5
    Repeater {
        id: mainRepeater
        model: component.model
        delegate: RowLayout {
            id: rowDelegate
            property var row: index
            Layout.margins: 2.5
            Repeater {
                model: component.model.columnCount(component.model.index(rowDelegate.row, 0))
                delegate: QQC2.Button {
                    id: playDelegate
                    property var column: index
                    property var note: component.model.data(component.model.index(rowDelegate.row, playDelegate.column), component.model.roles['note'])

                    // Pitch is -8192 to 8191 inclusive
                    property int pitchValue: Math.max(-8192, Math.min(chordSlidePoint.slideX * 8192 / width, 8191))
                    onPitchValueChanged: component.playgrid.pitch = pitchValue
                    property int modulationValue: Math.max(-127, Math.min(chordSlidePoint.slideY * 127 / width, 127))
                    onModulationValueChanged: component.playgrid.modulation = modulationValue;

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    background: Item {
                        RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            Repeater {
                                model: playDelegate.note.subnotes
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: modelData.isPlaying ? "#8bc34a" : (modelData.midiNote % 12 === 0 ? Kirigami.Theme.focusColor : "white")
                                    Text {
                                        anchors.fill: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        clip: true
                                        text: modelData.name + modelData.octave
                                    }
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
                                id: chordSlidePoint;
                                property double slideX: x < 0 ? Math.floor(x) : (x > playDelegate.width ? x - playDelegate.width : 0)
                                property double slideY: y < 0 ? -Math.floor(y) : (y > playDelegate.height ? -(y - playDelegate.height) : 0)
                                property var playingNote;
                                onPressedChanged: {
                                    if (pressed) {
                                        var velocityValue = 64;
                                        if (component.positionalVelocity) {
                                            velocityValue = 127 - Math.floor(chordSlidePoint.y * 127 / height);
                                        } else {
                                            // This seems slightly odd - but 1 is the very highest possible, and default is supposed to be a velocity of 64, so...
                                            velocityValue = chordSlidePoint.pressure > 0.99999 ? 64 : Math.floor(chordSlidePoint.pressure * 127);
                                        }
                                        playDelegate.down = true;
                                        playDelegate.focus = true;
                                        playingNote = playDelegate.note;
                                        component.playgrid.setNoteOn(playingNote, velocityValue)
                                    } else {
                                        playDelegate.down = false;
                                        playDelegate.focus = false;
                                        component.playgrid.setNoteOff(playingNote)
                                        component.playgrid.pitch = 0;
                                        component.playgrid.modulation = 0;
                                    }
                                }
                            }
                        ]
                    }
                }
            }
        }
    }
}
