/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

A ducky helper for wrapping non-python originated data in a selector

Copyright (C) 2025 Dan Leinir Turthra Jensen <admin@leinir.dk>

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

import QtQuick 2.15

// Use this in place of a python selector for wrapping data from elsewhere
Item {
    id: component
    property int current_index: -1
    property var selector_list: []
    readonly property int effective_count: selector_list
        ? typeof selector_list == "number"
            ? selector_list
            : selector_list.hasOwnProperty("length")
                ? selector_list.length
                : selector_list.hasOwnProperty("count")
                    ? selector_list.count
                    : 0
        : 0
    property bool autoActivateIndexOnChange: false
    signal itemActivated(string screenId, int index)
    function activate_index(index) {
        if (component.current_index != index) {
            component.current_index = index;
            component.itemActivated("", index);
        }
    }
    signal itemActivatedSecondary(string screenId, int index)
    function activate_index_secondary(index) {
        if (component.current_index != index) {
            component.current_index = index;
            component.itemActivatedSecondary("", index);
        }
    }
    function select_up(count = 1) {
        let newIndex = Math.max(0, component.current_index - count);
        if (component.current_index != newIndex) {
            component.current_index = newIndex;
            if (component.autoActivateIndexOnChange) {
                autoActivationTimer.restart();
            }
        }
    }
    function select_down(count = 1) {
        let newIndex = Math.min(component.effective_count - 1, component.current_index + count);
        if (component.current_index != newIndex) {
            component.current_index = newIndex;
            if (component.autoActivateIndexOnChange) {
                autoActivationTimer.restart();
            }
        }
    }
    Timer {
        id: autoActivationTimer
        property int last_auto_activated_index: -1
        interval: 50; running: false; repeat: false;
        onTriggered: {
            if (component.current_index != autoActivationTimer.last_auto_activated_index) {
                component.activate_index(component.current_index);
                autoActivationTimer.last_auto_activated_index = component.current_index;
            }
        }
    }
}
