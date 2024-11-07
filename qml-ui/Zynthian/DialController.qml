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
        inputMode: QQC2.Dial.Vertical
        stepSize: root.controller.ctrl ? (root.controller.ctrl.step_size === 0 ? 1 : root.controller.ctrl.step_size) : 0
        from: root.controller.ctrl ? root.controller.ctrl.value0 : 0
        to: root.controller.ctrl ? root.controller.ctrl.max_value : 0

        property bool shouldClick: false
        property var mostRecentClickTime: 0
        onMoved: {
            shouldClick = false;
            if (root.controller && root.controller.ctrl) {
                root.controller.ctrl.value = value;
            }
        }
        onPressedChanged: {
            if (pressed) {
                shouldClick = true;
            } else {
                shouldClick = false;
                let thisClickTime = Date.now();
                if (thisClickTime - mostRecentClickTime < 300) {
                    if (root.controller && root.controller.ctrl) {
                        root.controller.ctrl.value = root.controller.ctrl.value_default;
                    }
                    root.doubleClicked();
                } else {
                    root.clicked();
                }
                mostRecentClickTime = thisClickTime;
            }
            root.pressedChanged(pressed);
        }

        QQC2.Label {
            id: valueLabel
            anchors {
                fill: parent
                margins: dial.handle.width / 2
            }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.Fit
            minimumPointSize: 8
            font.pointSize: 18
            text: {
                if (!root.controller.ctrl) {
                    return "";
                }
                // Heuristic: convert the values from 0-127 to 0-100
                if (root.controller.ctrl.value0 === 0 && root.controller.ctrl.max_value === 127) {
                    return Math.round(100 * (value / 127));
                }
                return root.controller.ctrl.value_print.trim();
            }
        }
    }

    Binding {
        target: dial
        property: "value"
        value: root.controller.ctrl ? root.controller.ctrl.value : 0
    }
}
