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

import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import "private"

Item {
    id: root

    readonly property ControllerGroup controller: ControllerGroup {}

    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property string valueType: {
        //FIXME: Ugly heuristics
        if (!root.controller.ctrl) {
            return "int";
        }
        if (root.controller.ctrl.value_type === "int" && root.controller.ctrl.max_value - root.controller.ctrl.value0 === 1) {
            return "bool";
        }
        if (root.controller.ctrl.value_print === "on" || root.controller.ctrl.value_print === "off" ||
            root.controller.ctrl.value_print === "On" || root.controller.ctrl.value_print === "Off") {
            return "bool";
        }
        return root.controller.ctrl.value_type;
    }

    // Just a stand-in to point invisible controllers at
    readonly property ControllerGroup noController: ControllerGroup {}
    SwitchController {
        visible: root.valueType === "bool"
        anchors.fill: parent
        controller: visible ? root.controller : root.noController;
    }
    DialController {
        visible: root.valueType !== "bool"
        anchors.fill: parent
        controller: visible ? root.controller : root.noController;
    }
}
