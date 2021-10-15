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
    title: zynthian.control.selector_path_element

    screenId: "control"
    property var cuiaCallback: function(cuia) {
        if (!stack.currentItem
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
            id: viewAction
            text: qsTr("Switch View")
            enabled: zynthian.control.control_pages_model.count > 1
            onTriggered: {
                if (zynthian.control.control_pages_model.count == 2) {
                    if (zynthian.control.custom_control_page === zynthian.control.default_custom_control_page) {
                        zynthian.control.custom_control_page = "";
                    } else {
                        zynthian.control.custom_control_page = zynthian.control.default_custom_control_page;
                    }
                }
            }
            property QQC2.Menu menuDelegate: zynthian.control.control_pages_model.count > 2 ? customControlsMenu : null
        },
        Kirigami.Action {
            text: qsTr("Get New Views...")
            onTriggered: zynthian.show_modal("control_downloader")
        }
    ]

    QQC2.Menu {
        id: customControlsMenu
        y: -height
        Repeater {
            model: zynthian.control.control_pages_model
            delegate: QQC2.MenuItem {
                id: menuItem
                text: model.display
                checkable: true
                autoExclusive: true
                checked: model.path == ""
                    ? (zynthian.control.custom_control_page == "")
                    : (zynthian.control.custom_control_page.indexOf(model.path) == 0)

                onClicked: {
                    zynthian.control.custom_control_page = model.path
                }
            }
        }
    }

    Component.onCompleted: {
       // mainView.forceActiveFocus()
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
            if (zynthian.current_screen_id !== "control" && applicationWindow().pageStack.currentItem === root) {
                pageRemoveTimer.restart()
            }
        }
    }
    Timer {
        id: pageRemoveTimer
        interval: Kirigami.Units.longDuration
        onTriggered: {
            if (zynthian.current_screen_id !== "control" && applicationWindow().pageStack.currentItem === root) {
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
            id: defaultPage
            objectName: "defaultPage"
            function topLevelFocusItem(item) {
                if (!item) {
                    return null;
                }
                while (item.parent) {
                    switch (item) {
                    case mainView:
                    case control1:
                    case control2:
                    case control3:
                    case control4:
                        return item;
                    default:
                        break;
                    }
                    item = item.parent;
                }
                return mainView;
            }
            property var cuiaCallback: function(cuia) {
                if (!Window.activeFocusItem) {
                    return false;
                }
                let focusItem = topLevelFocusItem(Window.activeFocusItem);
                switch (cuia) {
                    case "SELECT_UP":
                        switch (focusItem) {
                        case control1:
                            return true;
                        case control2:
                            control1.item.forceActiveFocus();
                            return true;
                        case control3:
                            return true;
                        case control4:
                            control3.item.forceActiveFocus();
                            return true;
                        default:
                            return false;
                        }
                    case "SELECT_DOWN":
                        switch (focusItem) {
                        case control1:
                            control2.item.forceActiveFocus();
                            return true;
                        case control2:
                            return true;
                        case control3:
                            control4.item.forceActiveFocus();
                            return true;
                        case control4:
                            return true;
                        default:
                            return false;
                        }
                    case "NAVIGATE_LEFT":
                        switch (focusItem) {
                        case control1:
                        case control2:
                            return true;
                        case mainView:
                            control1.item.forceActiveFocus();
                            return true;
                        case control3:
                        case control4:
                            mainView.forceActiveFocus();
                            return true;
                        default:
                            return false;
                        }
                    case "NAVIGATE_RIGHT":
                        switch (focusItem) {
                        case control1:
                        case control2:
                            mainView.forceActiveFocus();
                            return true;
                        case mainView:
                            control3.item.forceActiveFocus();
                            return true;
                        case control3:
                        case control4:
                            return true;
                        default:
                            return false;
                        }
                    case "INCREASE":
                        if (Window.activeFocusItem && Window.activeFocusItem.increase) {
                            Window.activeFocusItem.increase();
                        } else if (Window.activeFocusItem && Window.activeFocusItem.toggle) {
                            Window.activeFocusItem.toggle()
                        }
                        return true;
                    case "DECREASE":
                        if (Window.activeFocusItem && Window.activeFocusItem.decrease) {
                            Window.activeFocusItem.decrease();
                        } else if (Window.activeFocusItem && Window.activeFocusItem.toggle) {
                            Window.activeFocusItem.toggle()
                        }
                        return true;
                    case "SWITCH_SELECT_SHORT":
                    case "SWITCH_SELECT_BOLD":
                    case "SWITCH_SELECT_LONG":
                        if (Window.activeFocusItem && Window.activeFocusItem.toggle) {
                            Window.activeFocusItem.toggle();
                            return true;
                        } else {
                            return true;
                        }
                    default:
                        return false;
                    }
            }
            ColumnLayout {
                Layout.maximumWidth: Math.floor(root.width / 4)
                Layout.minimumWidth: Layout.maximumWidth
                Layout.fillHeight: true
                Zynthian.ControllerLoader {
                    id: control1
                    Layout.preferredHeight: 1
                    // FIXME: this always assumes there are always exactly 4 controllers for the entire lifetime
                    controller.index: 0
                }
                Zynthian.ControllerLoader {
                    id: control2
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
                highlighted: defaultPage.topLevelFocusItem(Window.activeFocusItem) === mainView
            }
            ColumnLayout {
                Layout.maximumWidth: Math.floor(root.width / 4)
                Layout.minimumWidth: Layout.maximumWidth
                Layout.fillHeight: true
                Zynthian.ControllerLoader {
                    id: control3
                    Layout.preferredHeight: 1
                    controller.index: 2
                }
                Zynthian.ControllerLoader {
                    id: control4
                    Layout.preferredHeight: 1
                    controller.index: 3
                }
            }
        }
    }
}
