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

import QtQuick 2.6
import QtQuick.VirtualKeyboard 2.2

import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

Item {
    visible: Qt.inputMethod.visible

    Connections {
        target: Qt.inputMethod
        onVisibleChanged: {
            Qt.callLater(function() {
                if (active && applicationWindow().activeFocusItem.selectAll) {
                    applicationWindow().activeFocusItem.selectAll()
                }
            })
        }
    }

    property var cuiaCallback: function(cuia) {
        var result = false;

        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                Qt.inputMethod.hide();
                result = true;
                break;
            default:
                // Just do nothing
                break;
        }

        return result;
    }

    Rectangle {
        anchors.fill: parent
        color: "#cc222222"

        QQC2.TextField {
            anchors.centerIn: parent
            width: parent.width * 0.4
            height: Kirigami.Units.gridUnit * 2
            horizontalAlignment: "AlignHCenter"
            verticalAlignment: "AlignVCenter"
            text: applicationWindow().activeFocusItem.text ? applicationWindow().activeFocusItem.text : ""
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                Qt.inputMethod.hide()
            }
        }
    }

    InputPanel {
        id: inputPanel
        active: Qt.inputMethod.visible
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 250

        onHeightChanged: resizeKeyboard();
        onWidthChanged: resizeKeyboard();
        function resizeKeyboard() {
            keyboard.style.keyboardDesignWidth = width*3
            keyboard.style.keyboardDesignHeight = height*3
        }
        Component.onCompleted: resizeKeyboard()
    }
}
