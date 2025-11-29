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

import QtQuick 2.15
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.4 as Kirigami

AbstractController {
    id: root

    property alias valueLabel: valueLabel.text
    property alias switchControl: switchControl

    control: MouseArea {
        anchors.fill: parent
        onClicked: root.controller.ctrl.value = root.controller.ctrl.value == root.controller.ctrl.value0 ? root.controller.ctrl.max_value : root.controller.ctrl.value0
        onPressedChanged: root.pressedChanged(pressed)

        QQC2.Switch {
            id: switchControl
            z: -1
            anchors {
                top: parent.top
                topMargin: Kirigami.Units.largeSpacing
                horizontalCenter: parent.horizontalCenter
            }
            width: Math.min(Math.round(parent.width / 4 * 3), Kirigami.Units.gridUnit * 3)
            height: Kirigami.Units.gridUnit * 3
            checked: root.controller.ctrl && root.controller.ctrl.value !== root.controller.ctrl.value0
            onToggled: root.controller.ctrl.value = checked ? root.controller.ctrl.max_value : root.controller.ctrl.value0
            // Explicitly set indicator implicitWidth otherwise the switch size is too small
            indicator.implicitWidth: width
        }
        Kirigami.Heading {
            id: valueLabel
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: Kirigami.Units.smallSpacing
            }
            level: 2
            text: root.controller.ctrl ? root.controller.ctrl.value_print : ""
        }
    }
}

