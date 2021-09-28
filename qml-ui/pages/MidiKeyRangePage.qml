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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.10
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

Zynthian.ScreenPage {
    id: root
    title: zynthian.midi_key_range.selector_path

    screenId: "midi_key_range"
    property var cuiaCallback: function(cuia) {
        return false;
    }

    GridLayout {
        anchors.fill: parent
        columns: 3
        rowSpacing: Kirigami.Units.gridUnit

        Zynthian.MultiSwitchController {
            legend: ""
            controller.ctrl: zynthian.midi_key_range.octave_controller
            valueLabel: {
                let str = zynthian.midi_key_range.octave_controller.value_print;
                str = str.replace(".0", "");
                return str;
            }
            //stepSize: 1
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        Zynthian.MultiSwitchController {
            legend: ""
            controller.ctrl: zynthian.midi_key_range.get_halftone_controller
            stepSize: 1
            valueLabel: {
                let str = zynthian.midi_key_range.get_halftone_controller.value_print;
                str = str.replace(".0", "");
                return str;
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.columnSpan: 3
            implicitHeight: parent.height / 3
            RowLayout {
                id: keyboardLayout
                anchors {
                    fill: parent
                    bottomMargin: Kirigami.Units.gridUnit * 2
                }
                spacing: 0
                readonly property var colorPattern: [1,0,1,0,1,1,0,1,0,1,0,1]
                Repeater {
                    model: 128
                    delegate: Item {
                        property bool white: keyboardLayout.colorPattern[index % 12]
                        z: !white
                        Layout.fillWidth: white
                        implicitWidth: 0
                        Layout.fillHeight: true
                        opacity: index >= zynthian.midi_key_range.note_low_controller.value && index <= zynthian.midi_key_range.note_high_controller.value ? 1 : 0.5
                        Rectangle {
                            anchors {
                                fill: parent
                                margins: 1
                            }
                            color: "white"
                            visible: parent.white
                        }
                        Rectangle {
                            visible: !parent.white
                            x: -width / 2
                            width: keyboardLayout.width / 64 / 2
                            height: parent.height / 3 * 2
                            Layout.fillWidth: true
                            color: "black"
                        }
                    }
                }
            }
            Rectangle {
                id: fromHandle
                anchors {
                    top: keyboardLayout.top
                    bottom: keyboardLayout.bottom
                }
                width: Kirigami.Units.gridUnit / 2
                color: Kirigami.Theme.positiveTextColor
                MouseArea {
                    id: fromMouse
                    anchors {
                        fill:parent
                        leftMargin: -Kirigami.Units.gridUnit
                        rightMargin: -Kirigami.Units.gridUnit
                    }

                    Binding {
                        when: !fromMouse.pressed
                        target: fromHandle
                        property: "x"
                        value: keyboardLayout.width / 128 * zynthian.midi_key_range.note_low_controller.value
                    }
                    drag {
                        target: fromHandle
                        axis: Drag.XAxis
                        minimumX: 0
                        maximumX: keyboardLayout.width - width
                    }
                    onReleased: {
                        print(Math.round(mapToItem(keyboardLayout, mouse.x, 0).x / (keyboardLayout.width/128)))
                        zynthian.midi_key_range.note_low_controller.value = Math.round(mapToItem(keyboardLayout, mouse.x, 0).x / (keyboardLayout.width/128))
                    }
                }

                QQC2.Label {
                    anchors {
                        top: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                        topMargin: Kirigami.Units.smallSpacing
                    }
                    text: zynthian.midi_key_range.get_midi_note_name(Math.round(zynthian.midi_key_range.note_low_controller.value))
                }
            }

            Rectangle {
                id: toHandle
                anchors {
                    top: keyboardLayout.top
                    bottom: keyboardLayout.bottom
                }
                width: Kirigami.Units.gridUnit / 2
                color: Kirigami.Theme.neutralTextColor
                MouseArea {
                    id: toMouse
                    anchors {
                        fill:parent
                        leftMargin: -Kirigami.Units.gridUnit
                        rightMargin: -Kirigami.Units.gridUnit
                    }

                    Binding {
                        when: !toMouse.pressed
                        target: toHandle
                        property: "x"
                        value: keyboardLayout.width / 128 * zynthian.midi_key_range.note_high_controller.value
                    }
                    drag {
                        target: toHandle
                        axis: Drag.XAxis
                        minimumX: 0
                        maximumX: keyboardLayout.width - width
                    }
                    onReleased: {
                        print(Math.round(mapToItem(keyboardLayout, mouse.x, 0).x / (keyboardLayout.width/128)))
                        zynthian.midi_key_range.note_high_controller.value = Math.round(mapToItem(keyboardLayout, mouse.x, 0).x / (keyboardLayout.width/128))
                    }
                }

                QQC2.Label {
                    anchors {
                        top: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                        topMargin: Kirigami.Units.smallSpacing
                    }
                    text: zynthian.midi_key_range.get_midi_note_name(Math.round(zynthian.midi_key_range.note_high_controller.value))
                }
            }
        }
    }

}
