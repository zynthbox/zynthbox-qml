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
import "../"

Card {
    id: root

    signal pressedChanged(bool pressed)
    signal clicked()
    signal doubleClicked()

    // instance of zynthian_gui_controller.py, TODO: should be registered in qml?
    property ControllerGroup controller: ControllerGroup {}
    // Those are automatically binded by default,
    property alias title: heading.text
    property alias heading: heading
    property alias legend: legend.text
    property alias control: contentItem.contentItem

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredWidth: 1
    Layout.preferredHeight: 1
    visible: controller.ctrl !== null
    contentItem: ColumnLayout {
        QQC2.Label {
            id: heading
            visible: text.length > 0
            text: root.controller.ctrl ? root.controller.ctrl.title : ""
            Layout.fillWidth: true
            Layout.minimumHeight: font.pixelSize
            Layout.maximumHeight: font.pixelSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.Fit
            font.pixelSize: root.height / 6
        }
        QQC2.Control {
            id: contentItem
            Layout.fillWidth: true
            Layout.fillHeight: true
            leftPadding: 0
            topPadding: 0
            rightPadding: 0
            bottomPadding: 0

            // Contents go here
        }

        QQC2.Label {
            id: legend
            visible: text.length > 0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.controller.ctrl ? root.controller.ctrl.midi_bind : ""
        }
    }
}
