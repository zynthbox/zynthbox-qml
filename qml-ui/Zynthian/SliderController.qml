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

AbstractController {
    id: root
    property alias valueLabel: valueLabel.text

    property alias value: slider.value
    property alias from: slider.from
    property alias to: slider.to
    property alias stepSize: slider.stepSize
    property alias snapMode: slider.snapMode
    property alias slider: slider
    highlighted: slider.activeFocus

    control: ColumnLayout {
        onActiveFocusChanged: {
            if (activeFocus) {
                slider.forceActiveFocus();
            }
        }

        QQC2.Slider {
            id: slider
            implicitWidth: 1
            implicitHeight: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: Qt.Vertical
            stepSize: root.controller.ctrl ? (root.controller.ctrl.step_size === 0 ? 1 : root.controller.ctrl.step_size) : 0
            value: root.controller.ctrl ? root.controller.ctrl.value : 0
            from: root.controller.ctrl ? root.controller.ctrl.value0 : 0
            to: root.controller.ctrl ? root.controller.ctrl.max_value : 0
            onMoved: root.controller.ctrl.value = value
        }
        Kirigami.Heading {
            id: valueLabel
            level: 2
            text: root.controller.ctrl ? root.controller.ctrl.value_print : ""
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
    }
}


