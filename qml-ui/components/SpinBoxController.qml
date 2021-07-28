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

import "private"

AbstractController {
    id: root

    property alias spinBox: spinBox

    control: Item {

        QQC2.SpinBox {
            id: spinBox
            anchors.centerIn: parent
            width: Math.min(Kirigami.Units.gridUnit * 10, parent.width)
            height: width/3

            readonly property real realValue: value / 100
            stepSize: root.controller ? (root.controller.step_size === 0 ? 10 : root.controller.step_size * 10) : 0
            value: root.controller ? root.controller.value * 100 : 0
            from: root.controller ? root.controller.value0 * 100 : 0
            to: root.controller ? root.controller.max_value * 100 : 0
            onValueModified: root.controller.value = realValue
            font: heading.font
            contentItem: Kirigami.Heading {
                id: heading
                text: spinBox.textFromValue(spinBox.value, spinBox.locale)
                opacity: spinBox.enabled ? 1 : 0.6
                level: 2

                horizontalAlignment: Qt.AlignHCenter
            }
            validator: DoubleValidator {
                bottom: Math.min(spinBox.from, spinBox.to)
                top:  Math.max(spinBox.from, spinBox.to)
            }
        }
    }
}


