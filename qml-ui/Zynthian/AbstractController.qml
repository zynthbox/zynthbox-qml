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
    property alias heading: heading
    property alias legend: legend.text
    property int encoderIndex: -1

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredWidth: 1
    Layout.preferredHeight: 1
    visible: controller.ctrl !== null

    onVisibleChanged: {
        if (controller.ctrl) {
            controller.ctrl.visible = visible;
        }
    }
    Component.onCompleted: {
        controller.ctrl.visible = root.visible
        if (root.encoderIndex < 0) {
            root.encoderIndex = controller.ctrl.encoder_index;
        } else {
            controller.ctrl.encoder_index = root.encoderIndex
        }
    }

    onEncoderIndexChanged: {
        if (_oldEncoderIndex != -1 && encoderIndex != _oldEncoderIndex) {
            controller.ctrl.encoder_index = encoderIndex;
        }

        _oldEncoderIndex = encoderIndex;
    }

    property alias control: contentItem.contentItem

    property int _oldEncoderIndex: -1
    onActiveFocusChanged: {
        if (activeFocus) {
            control.forceActiveFocus();
        }
    }


    contentItem: ColumnLayout {
        Kirigami.Heading {
            id: heading
            visible: text.length > 0
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
