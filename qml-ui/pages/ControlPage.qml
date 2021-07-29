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

import "../components" as ZComponents

ZComponents.ScreenPage {
    id: root
    title: zynthian.control.selector_path_element

    screenId: "control"

    backAction: Kirigami.Action {
        text: qsTr("Back")
        onTriggered: {
            if (stack.depth > 1) {
                stack.pop();
            } else {
                zynthian.go_back()
            }
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
    onFocusChanged: {
        if (focus) {
            mainView.forceActiveFocus()
        }
    }

    bottomPadding: Kirigami.Units.gridUnit
    contentItem: ZComponents.Stack {
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
                ZComponents.ControllerLoader {
                    Layout.preferredHeight: 1
                    // FIXME: this always assumes there are always exactly 4 controllers for the entire lifetime
                    controller.index: 0
                }
                ZComponents.ControllerLoader {
                    Layout.preferredHeight: 1
                    controller.index: 1
                }
            }
            ZComponents.SelectorView {
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
                ZComponents.ControllerLoader {
                    Layout.preferredHeight: 1
                    controller.index: 2
                }
                ZComponents.ControllerLoader {
                    Layout.preferredHeight: 1
                    controller.index: 3
                }
            }
        }
    }
}
