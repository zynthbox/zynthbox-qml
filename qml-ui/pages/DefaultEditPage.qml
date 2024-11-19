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

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.7 as Kirigami

import Zynthian 1.0 as Zynthian

RowLayout {
    id: root

    property QtObject selectedChannel: applicationWindow().selectedChannel
    property QQC2.StackView stack
    property var cuiaCallback: function(cuia) {
        var columnIndex = zynqtgui.control.selectedColumn - zynqtgui.control.selectedPage * 4

        switch (cuia) {
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
                if (zynqtgui.control.selectedEngineBypassController) {
                    if (zynqtgui.control.selectedEngineBypassController.value === 0) {
                        zynqtgui.control.selectedEngineBypassController.value = 1;
                    } else {
                        zynqtgui.control.selectedEngineBypassController.value = 0;
                    }
                }
                return true;
                break;
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
            case "KNOB0_UP":
                applicationWindow().pageStack.getPage("control").updateControllerValue(columnsRepeater.itemAt(columnIndex).rowsRepeater.itemAt(0).controllerLoader.controller.ctrl, 1)
                return true;
            case "KNOB0_DOWN":
                applicationWindow().pageStack.getPage("control").updateControllerValue(columnsRepeater.itemAt(columnIndex).rowsRepeater.itemAt(0).controllerLoader.controller.ctrl, -1)
                return true;
            case "KNOB1_UP":
                applicationWindow().pageStack.getPage("control").updateControllerValue(columnsRepeater.itemAt(columnIndex).rowsRepeater.itemAt(1).controllerLoader.controller.ctrl, 1)
                return true;
            case "KNOB1_DOWN":
                applicationWindow().pageStack.getPage("control").updateControllerValue(columnsRepeater.itemAt(columnIndex).rowsRepeater.itemAt(1).controllerLoader.controller.ctrl, -1)
                return true;
            case "KNOB2_UP":
                applicationWindow().pageStack.getPage("control").updateControllerValue(columnsRepeater.itemAt(columnIndex).rowsRepeater.itemAt(2).controllerLoader.controller.ctrl, 1)
                return true;
            case "KNOB2_DOWN":
                applicationWindow().pageStack.getPage("control").updateControllerValue(columnsRepeater.itemAt(columnIndex).rowsRepeater.itemAt(2).controllerLoader.controller.ctrl, -1)
                return true;
            case "KNOB3_UP":
                zynqtgui.control.selectedColumn = Zynthian.CommonUtils.clamp(zynqtgui.control.selectedColumn + 1, 0, zynqtgui.control.totalColumns - 1)
                return true;
            case "KNOB3_DOWN":
                zynqtgui.control.selectedColumn = Zynthian.CommonUtils.clamp(zynqtgui.control.selectedColumn - 1, 0, zynqtgui.control.totalColumns - 1)
                return true;
        }

        return false;
    }

    spacing: 4

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        ListView {
            id: pageSelectorListview
            Layout.fillHeight: true
            Layout.fillWidth: true
            model: zynqtgui.current_screen_id === "control"
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
                height: ListView.view.height / 8
                color: "transparent"
                border.color: zynqtgui.control.selectedPage === index ? "#88ffffff" : "transparent"
                border.width: 2
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

                Zynthian.KnobIndicator {
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        margins: Kirigami.Units.smallSpacing
                    }
                    height: Kirigami.Units.iconSizes.small
                    width: Kirigami.Units.iconSizes.small
                    visible: zynqtgui.control.selectedPage === index
                    knobId: 3
                }
            }
        }
        QQC2.Button {
            Layout.fillWidth: true
            visible: zynqtgui.control.selectedEngineBypassController !== null
            QQC2.Switch {
                anchors {
                    fill: parent
                    leftMargin: Kirigami.Units.largeSpacing
                    rightMargin: Kirigami.Units.largeSpacing
                }
                text: qsTr("Bypass")
                checked: zynqtgui.control.selectedEngineBypassController ? zynqtgui.control.selectedEngineBypassController.value === zynqtgui.control.selectedEngineBypassController.value_default : false
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (zynqtgui.control.selectedEngineBypassController.value === zynqtgui.control.selectedEngineBypassController.value0) {
                        zynqtgui.control.selectedEngineBypassController.value = zynqtgui.control.selectedEngineBypassController.max_value;
                    } else {
                        zynqtgui.control.selectedEngineBypassController.value = zynqtgui.control.selectedEngineBypassController.value0;
                    }
                }
            }
        }
    }

    Repeater {
        id: columnsRepeater
        readonly property int columnCount: 4
        model: columnCount
        delegate: Rectangle {
            id: columnDelegate

            readonly property int columnIndex: index
            readonly property alias rowsRepeater: rowsRepeater
            readonly property bool isCurrentColumn: (zynqtgui.control.selectedColumn % 4) === index

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10

            color: "transparent"
            border {
                color: isCurrentColumn ? "#88ffffff" : "transparent"
                width: 2
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                Repeater {
                    id: rowsRepeater
                    model: 3
                    delegate: Item {
                        id: controlDelegate

                        readonly property int allControlsIndex: zynqtgui.control.selectedPage * 12 + columnDelegate.columnIndex * 3 + index
                        readonly property alias controllerLoader: controllerLoader
                        readonly property int rowIndex: model.index
                        property var control: null

                        Timer {
                            id: controlUpdater
                            interval: 0; repeat: false; running: false;
                            onTriggered: {
                                controlDelegate.control = Qt.binding(function() {
                                    // Do not use all_controls property here in js as it will slow things down if array is large enough
                                    // Instead fetch the required controls as required
                                    return zynqtgui.current_screen_id === "control"
                                        ? zynqtgui.control.getAllControlAt(controlDelegate.allControlsIndex)
                                        : null
                                })
                            }
                        }

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Component.onCompleted: controlUpdater.restart()

                        Connections {
                            target: zynqtgui.control
                            onAll_controlsChanged: controlUpdater.restart()
                        }

                        Zynthian.ControllerLoader {
                            id: controllerLoader
                            visible: controlDelegate.control != null
                            knobId: columnDelegate.isCurrentColumn ? controlDelegate.rowIndex : -1
                            anchors.fill: parent
                            controller {
                                ctrl: controlDelegate.control
                            }
                            onInteracted: {
                                zynqtgui.control.selectedColumn = (zynqtgui.control.selectedPage * columnsRepeater.columnCount) + columnDelegate.columnIndex;
                            }
                        }
                    }
                }
            }
        }
    }
}
