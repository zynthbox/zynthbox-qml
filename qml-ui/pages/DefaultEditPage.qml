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
    id: root

    property QtObject selectedChannel: applicationWindow().selectedChannel
    property QQC2.StackView stack
    property var cuiaCallback: function(cuia) {
        switch (cuia) {
            case "SELECT_UP":
                zynqtgui.control.selectPrevPage()
                return true

            case "SELECT_DOWN":
                zynqtgui.control.selectNextPage()
                return true

            case "NAVIGATE_LEFT":
                zynqtgui.control.selectPrevColumn()
                return true

            case "NAVIGATE_RIGHT":
                zynqtgui.control.selectNextColumn()
                return true
        }

        return false;
    }

    spacing: 4

    Rectangle {
        Layout.fillWidth: false
        Layout.fillHeight: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        Layout.rightMargin: Kirigami.Units.smallSpacing
        color: Kirigami.Theme.backgroundColor

        ListView {
            id: pageSelectorListview
            anchors.fill: parent
            model: zynqtgui.current_screen_id === "control"
                   && root.selectedChannel.channelHasSynth
                    ? zynqtgui.control.totalPages
                    : 0
            clip: true
            currentIndex: zynqtgui.control.selectedPage
            highlightFollowsCurrentItem: true
            QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                width: Kirigami.Units.gridUnit * 0.3
                policy: QQC2.ScrollBar.AlwaysOn
                active: true
                contentItem: Rectangle {
                    radius: width/2
                    color: Kirigami.Theme.textColor
                    opacity: 0.3
                }
            }

            delegate: Rectangle {
                width: ListView.view.width
                height: ListView.view.height / 6
                color: "transparent"
                border.color: "#88ffffff"
                border.width: zynqtgui.control.selectedPage === index ? 2 : 0
                radius: 2

                QQC2.Label {
                    anchors.centerIn: parent
                    text: qsTr("Page %1").arg(index+1)
                }

                Kirigami.Separator {
                    height: 1
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        zynqtgui.control.selectedPage = index
                    }
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
            border.width: root.selectedChannel.channelHasSynth && (zynqtgui.control.selectedColumn % 4) === index ? 2 : 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                Repeater {
                    model: 3
                    delegate: Item {
                        id: controlDelegate

                        property int allControlsIndex: zynqtgui.control.selectedPage * 12 + columnDelegate.columnIndex * 3 + index
                        property var control: null

                        function updateControl() {
                            controlDelegate.control = Qt.binding(function() {
                                // Do not use all_controls property here in js as it will slow things down if array is large enough
                                // Instead fetch the required controls as required
                                return zynqtgui.current_screen_id === "control"
                                       && root.selectedChannel.channelHasSynth
                                        ? zynqtgui.control.getAllControlAt(controlDelegate.allControlsIndex)
                                        : null
                            })
                        }

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Component.onCompleted: controlDelegate.updateControl()

                        Connections {
                            target: zynqtgui.control
                            onAll_controlsChanged: controlDelegate.updateControl()
                        }

                        Zynthian.ControllerLoader {
                            visible: controlDelegate.control != null
                            anchors.fill: parent
                            controller {
                                category: controlDelegate.control ? controlDelegate.control["control_screen"] : ""
                                index: controlDelegate.control ? controlDelegate.control["index"] : -1
                            }
                        }
                    }
                }
            }
        }
    }
}