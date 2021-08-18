/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

Copyright (C) 2021 Marco Martin <mart@kde.org>

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

import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import "pages" as Pages

GridLayout {
    id: root
    rows: 2
    columns: 8
    property string currentNoteName: keyModel.getName(zynthian.miniplaygrid.startingNote)
    ListModel {
        id: keyModel
        function getName(note) {
            for(var i = 0; i < keyModel.rowCount(); ++i) {
                var le = keyModel.get(i);
                if (le.note = note) {
                    return le.text;
                }
            }
            return "C";
        }

        ListElement { note: 36; text: "C" }
        ListElement { note: 37; text: "C#" }
        ListElement { note: 38; text: "D" }
        ListElement { note: 39; text: "D#" }
        ListElement { note: 40; text: "E" }
        ListElement { note: 41; text: "F" }
        ListElement { note: 42; text: "F#" }
        ListElement { note: 43; text: "G" }
        ListElement { note: 44; text: "G#" }
        ListElement { note: 45; text: "A" }
        ListElement { note: 46; text: "A#" }
        ListElement { note: 47; text: "B" }
    }
    Repeater {
        model: zynthian.miniplaygrid.model
        Repeater {
            readonly property var row: index
            model: zynthian.miniplaygrid.model.columnCount(zynthian.miniplaygrid.model.index(index, 0))
            delegate: QQC2.Control {
                id: playDelegate
                readonly property var column: index
                readonly property var note: zynthian.miniplaygrid.model.data(zynthian.miniplaygrid.model.index(row, column), zynthian.miniplaygrid.model.roles['note'])

                // Pitch is -8192 to 8191 inclusive
                property int pitchValue: Math.max(-8192, Math.min(pitchModPoint.pitchModX * 8192 / width, 8191))
                onPitchValueChanged: zynthian.miniplaygrid.pitch = pitchValue
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
                                if (zynthian.miniplaygrid.scale !== "chromatic" &&
                                    note.name === root.currentNoteName
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
                                if (zynthian.miniplaygrid.scale == "major") {
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
                            if (zynthian.miniplaygrid.positionalVelocity) {
                                velocityValue = 127 - Math.floor(pitchModPoint.y * 127 / height);
                            } else {
                                // This seems slightly odd - but 1 is the very highest possible, and default is supposed to be a velocity of 64, so...
                                velocityValue = pitchModPoint.pressure > 0.99999 ? 64 : Math.floor(pitchModPoint.pressure * 127);
                            }
                            focus = true;
                            playingNote = note;
                            zynthian.miniplaygrid.setNoteOn(playingNote, velocityValue);
                        }
                    }
                    onReleased: {
                        if (!pitchModPoint.pressed) {
                            focus = false;
                            zynthian.miniplaygrid.setNoteOff(playingNote);
                            zynthian.miniplaygrid.pitch = 0
                        }
                    }
                    onCanceled: {
                        if (!pitchModPoint.pressed) {
                            focus = false;
                            zynthian.miniplaygrid.setNoteOff(playingNote);
                            zynthian.miniplaygrid.pitch = 0
                        }
                    }
                }
            }
        }
    }
}
