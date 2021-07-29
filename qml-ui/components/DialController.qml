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

AbstractController {
    id: root
    property alias valueLabel: valueLabel.text

    property alias value: dial.value
    property alias from: dial.from
    property alias to: dial.to
    property alias stepSize: dial.stepSize
    property alias snapMode: dial.snapMode
    property alias dial: dial

    control: QQC2.Dial {
        id: dial
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            margins: Kirigami.Units.largeSpacing
        }
        width: height
        stepSize: root.controller ? (root.controller.step_size === 0 ? 1 : root.controller.step_size) : 0
        value: root.controller ? root.controller.value : 0
        from: root.controller ? root.controller.value0 : 0
        to: root.controller ? root.controller.max_value : 0
        onMoved: root.controller.value = value


        // HACK for default style
        Binding {
            target: dial.background
            property: "color"
            value: Kirigami.Theme.highlightColor
        }
        Binding {
            target: dial.handle
            property: "color"
            value: Kirigami.Theme.highlightColor
        }
        Kirigami.Heading {
            id: valueLabel
            anchors.centerIn: parent
            text: root.controller ? root.controller.value_print :  ""
        }

        //TODO: with Qt >= 5.12 replace this with inputMode: Dial.Vertical
        MouseArea {
            id: dialMouse
            anchors.fill: parent
            preventStealing: true
            property real startY
            property real startValue
            onPressed: {
                startY = mouse.y;
                startValue = dial.value
            }
            onPositionChanged: {
                let delta = mouse.y - startY;
                let value = Math.max(dial.from, Math.min(dial.to, startValue - (dial.to / dial.stepSize) * (delta*dial.stepSize/(Kirigami.Units.gridUnit*10))));
                if (root.valueType === "int" || root.valueType === "bool") {
                    value = Math.round(value);
                }
                root.controller.value = value;
            }
        }
    }
}
