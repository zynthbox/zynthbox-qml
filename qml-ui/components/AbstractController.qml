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

    // instance of zynthian_gui_controller.py, TODO: should be registered in qml?
    property ControllerGroup controller: ControllerGroup {}

    // Those are automatically binded by default,
    property alias title: heading.text
    property alias legend: legend.text

    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: controller.ctrl !== null

    property alias control: contentItem.contentItem


    contentItem: ColumnLayout {
        Kirigami.Heading {
            id: heading
            text: root.controller.ctrl ? root.controller.ctrl.title : ""
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            level: 2
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
