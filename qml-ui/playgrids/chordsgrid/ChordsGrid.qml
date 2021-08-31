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
    property QtObject settingsStore
    property string currentNoteName
    property int chordRows
    property bool positionalVelocity

    spacing: 0
    anchors.margins: 5

    // Tiniest littlest hacky friend, or we end up with deleted notes and incorrect delegates...
    Connections {
        target: component.model
        onModelAboutToBeReset: {
            mainRepeater.model = 0;
        }
        onModelReset: {
            mainRepeater.model = component.chordRows < component.model.rows ? component.chordRows : component.model.rows;
        }
    }
    Repeater {
        id: mainRepeater
        model: component.chordRows < component.model.rows ? component.chordRows : component.model.rows;
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
                            if (playDelegate.note) {
                                if (playDelegate.note.isPlaying) {
                                    color = "#8bc34a";
                                } else {
                                    if (playDelegate.note.name === component.currentNoteName) {
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
                                if (playDelegate.note) {
                                    for (var i = 0; i < playDelegate.note.subnotes.length; ++i) {
                                        text += " " + playDelegate.note.subnotes[i].name + playDelegate.note.subnotes[i].octave
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
                                if (component.settingsStore.property("positionalVelocity")) {
                                    velocityValue = 127 - Math.floor(chordSlidePoint.y * 127 / height);
                                } else {
                                    // This seems slightly odd - but 1 is the very highest possible, and default is supposed to be a velocity of 64, so...
                                    velocityValue = chordSlidePoint.pressure > 0.99999 ? 64 : Math.floor(chordSlidePoint.pressure * 127);
                                }
                                parent.down = true;
                                focus = true;
                                playingNote = playDelegate.note;
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
