/* -*- coding: utf-8 -*-
 * *****************************************************************************
 * ZYNTHIAN PROJECT: Zynthian Qt GUI
 * 
 * New Default Edit Page
 * 
 * Copyright (C) 2022 Anupam Basak <anupam.basak27@gmail.com>
 * 
 ******************************************************************************
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * For a full copy of the GNU General Public License see the LICENSE.txt file.
 * 
 ******************************************************************************
 */

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.10
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

RowLayout {
    property QQC2.StackView stack

    spacing: 0

    Rectangle {
        Layout.fillWidth: false
        Layout.fillHeight: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        Layout.rightMargin: Kirigami.Units.smallSpacing
        color: Kirigami.Theme.backgroundColor

        ListView {
            anchors.fill: parent
            model: Math.max(1, Math.floor(zynthian.control.all_controls.length / 12))
            clip: true
            delegate: Kirigami.BasicListItem {
                label: qsTr("Page %1").arg(index+1)
                background: Rectangle {
                    color: "transparent"
                    border.color: "#88ffffff"
                    border.width: zynthian.control.selectedPage === index ? 2 : 0
                    radius: 2

                    Kirigami.Separator {
                        height: 1
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                    }
                }

                onClicked: {
                    zynthian.control.selectedPage = index
                }
            }
        }
    }

    Repeater {
        model: 4
        delegate: Rectangle {
            id: columnDelegate

            property int columnIndex: index

            Layout.fillWidth: true
            Layout.fillHeight: true

            color: "transparent"
            border.color: "#88ffffff"
            border.width: zynthian.control.selectedColumn === index ? 2 : 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: 3
                    delegate: Item {
                        id: controlDelegate

                        property int allControlsIndex: zynthian.control.selectedPage*12 + columnDelegate.columnIndex*3 + index
                        property var control: null
                        Binding {
                            target: controlDelegate
                            property: "control"
                            value: zynthian.control.all_controls[allControlsIndex] ? zynthian.control.all_controls[allControlsIndex] : null
                            delayed: true
                        }

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Zynthian.ControllerLoader {
                            anchors.fill: parent
                            controller {
                                category: controlDelegate.control["control_screen"]
                                index: controlDelegate.control["index"]
                            }
                        }
                    }
                }
            }
        }
    }
}
