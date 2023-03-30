/* -*- coding: utf-8 -*-
 * *****************************************************************************
 * ZYNTHIAN PROJECT: Zynthian Qt GUI
 * 
 * Old Default Edit Page
 * 
 * Copyright (C) 2021 Marco Martin <mart@kde.org>
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
    onVisibleChanged: {
        if (visible) {
            // FIXME: why needed?
            zynqtgui.control.activate_index(zynqtgui.control.current_index)
        }
    }

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
