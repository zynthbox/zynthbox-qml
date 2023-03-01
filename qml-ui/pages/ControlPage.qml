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
    property bool isVisible:zynthian.current_screen_id === "control"
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
            text: qsTr("Select Mod")
            enabled: zynthian.control.control_pages_model.count > 1
            property QQC2.Menu menuDelegate: customControlsMenu
        },
        Kirigami.Action {
            visible: false
        },
        Kirigami.Action {
            text: qsTr("Get New Mods...")
            onTriggered: zynthian.control.single_effect_engine === "" ? zynthian.show_modal("control_downloader") : zynthian.show_modal("fx_control_downloader")
        }
    ]

    Connections {
        target: applicationWindow()
        onActiveFocusItemChanged: {
            var candidate = applicationWindow().activeFocusItem
            while(candidate) {
                if (candidate.hasOwnProperty("controller")) {
                    break;
                }
                candidate = candidate.parent
            }
            if (candidate) {
                zynthian.control.active_custom_controller = candidate.controller.ctrl
            } else {
                zynthian.control.active_custom_controller = null
            }
        }
    }
    Connections {
        target: applicationWindow()
        enabled: root.isVisible
        onSelectedChannelChanged: {
            if (applicationWindow().selectedChannel) {
                if (applicationWindow().selectedChannel.channelAudioType === "external") {
                    zynthian.callable_ui_action("SCREEN_EDIT_CONTEXTUAL");
                } else if (applicationWindow().selectedChannel.channelAudioType.startsWith("sample-")) {
                    zynthian.callable_ui_action("SCREEN_EDIT_CONTEXTUAL");
                }
            }
        }
    }
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
                    zynthian.control.refresh_values()
                    zynthian.control.custom_control_page = model.path
                }
            }
        }
    }

    Component.onCompleted: {
       // mainView.forceActiveFocus()
        //HACK
        if (!root.visible) {
            return;
        }
        if (zynthian.control.custom_control_page.length > 0) {
            stack.replace(zynthian.control.custom_control_page);
            root.currentControlPage = zynthian.control.custom_control_page;
        } else {
            stack.replace(defaultPage);
            root.currentControlPage = "defaultPage";
        }
    }

    onVisibleChanged: {
        if (zynthian.control.custom_control_page.length > 0) {
            if (root.currentControlPage !== zynthian.control.custom_control_page) {
                stack.replace(zynthian.control.custom_control_page);
                root.currentControlPage = zynthian.control.custom_control_page;
            }
        } else if (!stack.currentItem || stack.currentItem.objectName !== "defaultPage") {
            stack.replace(defaultPage);
            root.currentControlPage = "defaultPage";
        }
    }
    property string currentControlPage
    Connections {
        target: zynthian.control
        onCustom_control_pageChanged: {
            if (!root.visible) {
                return;
            }
            if (zynthian.control.custom_control_page.length > 0) {
                if (root.currentControlPage !== zynthian.control.custom_control_page) {
                    stack.replace(zynthian.control.custom_control_page);
                    root.currentControlPage = zynthian.control.custom_control_page;
                }
            } else if (!stack.currentItem || stack.currentItem.objectName !== "defaultPage") {
                stack.replace(defaultPage);
                root.currentControlPage = "defaultPage";
            }
        }
    }
    Connections {
        id: currentConnection
        target: zynthian
        onCurrent_screen_idChanged: {
            root.visible = zynthian.current_screen_id === "control";
        }
    }

    //onFocusChanged: {
        //if (focus) {
            //mainView.forceActiveFocus()
        //}
    //}

    bottomPadding: Kirigami.Units.gridUnit
    contentItem: Zynthian.Stack {
        id: stack
    }

    Component {
        id: defaultPage

        NewDefaultEditPage {
            id: defaultPageRoot
            objectName: "defaultPage"
        }
    }
}
