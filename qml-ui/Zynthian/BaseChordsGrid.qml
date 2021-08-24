/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Play Grid Page 

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

Item {
    id: root
    property QtObject chordsGrid: chordsGrid
    property QtObject chordsGridSettings: chordsGridSettings

    Component {
        id: chordsGrid
        ColumnLayout {
            objectName: "chordsGrid"
            spacing: 0
            anchors.margins: 5
            Repeater {
                model: zynthian.playgrid.chordModel
                delegate: RowLayout {
                    property var row: index
                    Layout.margins: 2.5
                    Repeater {
                        model: zynthian.playgrid.chordModel.columnCount(zynthian.playgrid.chordModel.index(index, 0))
                        delegate: QQC2.Button {
                            id: playDelegate
                            property var column: index
                            property var note: zynthian.playgrid.chordModel.data(zynthian.playgrid.chordModel.index(row, column), zynthian.playgrid.chordModel.roles['note'])
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
                        if (zynthian.playgrid.chordRows === model[i]) {
                            return i;
                        }
                    }
                }
                onActivated: {
                    zynthian.playgrid.chordRows = model[currentIndex];
                }
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
}
