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
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

Zynthian.ScreenPage {
    id: root
    title: zynthian.control.selector_path_element

    screenId: "control"
    property var cuiaCallback: function(cuia) {
        if (!stack.currentItem || stack.currentItem.objectName === "defaultPage"
            || !stack.currentItem.hasOwnProperty("cuiaCallback")
            || !(stack.currentItem.cuiaCallback instanceof Function)) {
            return false;
        }

        //return false if the function returns anything not boolean
        if (stack.currentItem.cuiaCallback(cuia) === true) {
            return true;
        } else {
            return false;
        }
    }

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Switch View")
            visible: zynthian.control.custom_control_page.length > 0
            onTriggered: {
                if (!stack.currentItem || stack.currentItem.objectName !== "defaultPage") {
                    stack.replace(defaultPage);
                } else if (zynthian.control.custom_control_page.length > 0) {
                    stack.replace(zynthian.control.custom_control_page);
                }
            }
        }
    ]
    Component.onCompleted: {
        mainView.forceActiveFocus()
        zynthian.preset.next_screen = "control"
        //HACK
        if (zynthian.control.custom_control_page.length > 0) {
            stack.push(zynthian.control.custom_control_page);
        } else {
            stack.push(defaultPage);
        }
        zynthian.current_screen_id = "control"
    }
    Connections {
        target: zynthian.control
        onCustom_control_pageChanged: {
            print(zynthian.control.custom_control_page)
            if (zynthian.control.custom_control_page.length > 0) {
                stack.replace(zynthian.control.custom_control_page);
            } else if (!stack.currentItem || stack.currentItem.objectName !== "defaultPage") {
                stack.replace(defaultPage);
            }
        }
    }
    Connections {
        id: currentConnection
        target: zynthian
        onCurrent_screen_idChanged: {
            print(zynthian.current_screen_id +" "+ applicationWindow().pageStack.lastItem +" "+ root)
            if (zynthian.current_screen_id !== "control" && applicationWindow().pageStack.lastItem === root) {
                pageRemoveTimer.restart()
            }
        }
    }
    Timer {
        id: pageRemoveTimer
        interval: Kirigami.Units.longDuration
        onTriggered: {
            if (zynthian.current_screen_id !== "control" && applicationWindow().pageStack.lastItem === root) {
                applicationWindow().pageStack.pop();
            }
        }
    }
    onFocusChanged: {
        if (focus) {
            mainView.forceActiveFocus()
        }
    }

    bottomPadding: Kirigami.Units.gridUnit
    contentItem: Zynthian.Stack {
        id: stack
    }

    Component {
        id: defaultPage
        RowLayout {
            objectName: "defaultPage"
            ColumnLayout {
                Layout.maximumWidth: Math.floor(root.width / 4)
                Layout.minimumWidth: Layout.maximumWidth
                Layout.fillHeight: true
                Zynthian.ControllerLoader {
                    Layout.preferredHeight: 1
                    // FIXME: this always assumes there are always exactly 4 controllers for the entire lifetime
                    controller.index: 0
                }
                Zynthian.ControllerLoader {
                    Layout.preferredHeight: 1
                    controller.index: 1
                }
            }
            Zynthian.SelectorView {
                id: mainView
                screenId: root.screenId
                Layout.fillWidth: true
                Layout.fillHeight: true
                onCurrentScreenIdRequested: root.currentScreenIdRequested(root.screenId)
                onItemActivated: root.itemActivated(root.screenId, index)
            }
            ColumnLayout {
                Layout.maximumWidth: Math.floor(root.width / 4)
                Layout.minimumWidth: Layout.maximumWidth
                Layout.fillHeight: true
                Zynthian.ControllerLoader {
                    Layout.preferredHeight: 1
                    controller.index: 2
                }
                Zynthian.ControllerLoader {
                    Layout.preferredHeight: 1
                    controller.index: 3
                }
            }
        }
    }
}
