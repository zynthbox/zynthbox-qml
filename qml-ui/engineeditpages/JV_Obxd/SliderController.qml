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

import "../../components" as ZComponents


ZComponents.Card { //TODO: integrate into controller control
    id: root
    property QtObject controller
    property alias slider: slider

    implicitWidth: 1
    implicitHeight: 1
    Layout.fillWidth: true
    Layout.fillHeight: true

    contentItem: ColumnLayout {
        Kirigami.Heading {
            level: 2
            text: root.controller ? root.controller.title : ""
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
        QQC2.Slider {
            id: slider
            implicitWidth: 1
            implicitHeight: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: Qt.Vertical
            stepSize: root.controller ? (root.controller.step_size === 0 ? 1 : root.controller.step_size) : 0
            value: root.controller ? root.controller.value : 0
            from: root.controller ? root.controller.value0 : 0
            to: root.controller ? root.controller.max_value : 0
            onMoved: {
				root.controller.value = value
				canvas.requestPaint()
			}
        }
        Kirigami.Heading {
            level: 2
            text: root.controller ? root.controller.value_print : ""
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
    }
}


