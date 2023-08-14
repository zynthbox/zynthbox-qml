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
    property var lastSelectedObj
    property var controlPageComponent: parent.parent
    property var cuiaCallback: function(cuia) {
        switch (cuia) {
            case "SELECT_UP":
            case "SELECT_DOWN":
                if (root.lastSelectedObj === control1) {
                    root.lastSelectedObj = control2
                } else if (root.lastSelectedObj === control2) {
                    root.lastSelectedObj = control1
                } else if (root.lastSelectedObj === control3) {
                    root.lastSelectedObj = control4
                } else if (root.lastSelectedObj === control4) {
                    root.lastSelectedObj = control3
                } else {
                    root.lastSelectedObj = control1
                }

                return true
            case "NAVIGATE_LEFT":
            case "NAVIGATE_RIGHT":
                if (root.lastSelectedObj === control1) {
                    root.lastSelectedObj = control3
                } else if (root.lastSelectedObj === control2) {
                    root.lastSelectedObj = control4
                } else if (root.lastSelectedObj === control3) {
                    root.lastSelectedObj = control1
                } else if (root.lastSelectedObj === control4) {
                    root.lastSelectedObj = control2
                } else {
                    root.lastSelectedObj = control1
                }
                return true
            case "KNOB0_UP":
            case "KNOB0_DOWN":
                if (root.lastSelectedObj === control1 ||
                        root.lastSelectedObj === control2 ||
                        root.lastSelectedObj === control3 ||
                        root.lastSelectedObj === control4) {
                    root.lastSelectedObj.cuiaCallback(cuia)
                } else {
                    applicationWindow().showMessageDialog(qsTr("Control not selected. Select a control by clicking or with Mode + Big Knob first"), 2000)
                }
                return true
            case "KNOB1_UP":
            case "KNOB1_DOWN":
            case "KNOB2_UP":
            case "KNOB2_DOWN":
                return true
            case "KNOB3_UP":
                if (zynqtgui.modeButtonPressed) {
                    zynqtgui.ignoreNextModeButtonPress = true
                    if (root.lastSelectedObj === control1) {
                        root.lastSelectedObj = control2
                    } else if (root.lastSelectedObj === control2) {
                        root.lastSelectedObj = control3
                    } else if (root.lastSelectedObj === control3) {
                        root.lastSelectedObj = control4
                    } else if (root.lastSelectedObj === control4) {
                        root.lastSelectedObj = control1
                    } else {
                        root.lastSelectedObj = control1
                    }
                } else {
                    mainView.cuiaCallback(cuia)
                }
                return true
            case "KNOB3_DOWN":
                if (zynqtgui.modeButtonPressed) {
                    zynqtgui.ignoreNextModeButtonPress = true
                    if (root.lastSelectedObj === control1) {
                        root.lastSelectedObj = control4
                    } else if (root.lastSelectedObj === control2) {
                        root.lastSelectedObj = control1
                    } else if (root.lastSelectedObj === control3) {
                        root.lastSelectedObj = control2
                    } else if (root.lastSelectedObj === control4) {
                        root.lastSelectedObj = control3
                    } else {
                        root.lastSelectedObj = control1
                    }
                } else {
                    mainView.cuiaCallback(cuia)
                }
                return true
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
            case "SWITCH_SELECT_LONG":
                return true
            default:
                return false;
        }
    }

    objectName: "zynthianControlPage"
    onVisibleChanged: {
        if (visible) {
            root.lastSelectedObj = control1
        }
    }

    ColumnLayout {
        Layout.maximumWidth: Math.floor(root.controlPageComponent.width / 4)
        Layout.minimumWidth: Layout.maximumWidth
        Layout.fillHeight: true
        Zynthian.ControllerLoader {
            id: control1
            Layout.preferredHeight: 1
            // FIXME: this always assumes there are always exactly 4 controllers for the entire lifetime
            controller.index: 0
            highlighted: root.lastSelectedObj === control1
            onPressedChanged: {
                if (pressed) {
                    root.lastSelectedObj = control1
                }
            }
        }
        Zynthian.ControllerLoader {
            id: control2
            Layout.preferredHeight: 1
            controller.index: 1
            highlighted: root.lastSelectedObj === control2
            onPressedChanged: {
                if (pressed) {
                    root.lastSelectedObj = control2
                }
            }
        }
    }
    Zynthian.SelectorView {
        id: mainView
        screenId: root.controlPageComponent.screenId
        Layout.fillWidth: true
        Layout.fillHeight: true
        onCurrentScreenIdRequested: root.controlPageComponent.currentScreenIdRequested(root.controlPageComponent.screenId)
        onItemActivated: root.controlPageComponent.itemActivated(root.controlPageComponent.screenId, index)
        highlighted: root.lastSelectedObj === mainView
        onCurrentIndexChanged: {
            if (visible) {
                Qt.callLater(function() {
                    zynqtgui.control.activate_index(currentIndex)
                })
            }
        }
    }
    ColumnLayout {
        Layout.maximumWidth: Math.floor(root.controlPageComponent.width / 4)
        Layout.minimumWidth: Layout.maximumWidth
        Layout.fillHeight: true
        Zynthian.ControllerLoader {
            id: control3
            Layout.preferredHeight: 1
            controller.index: 2
            highlighted: root.lastSelectedObj === control3
            onPressedChanged: {
                if (pressed) {
                    root.lastSelectedObj = control3
                }
            }
        }
        Zynthian.ControllerLoader {
            id: control4
            Layout.preferredHeight: 1
            controller.index: 3
            highlighted: root.lastSelectedObj === control4
            onPressedChanged: {
                if (pressed) {
                    root.lastSelectedObj = control4
                }
            }
        }
    }
}
