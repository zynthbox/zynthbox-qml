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
    id: root

    // Property to store reference to the selected textfield when VK opens.
    // This is to make sure we always have the reference to original textfield that was focused
    // as when VK opens, focus is moved to a temporary textfield
    property QtObject focusedTextField: null

    visible: Qt.inputMethod.visible

    Connections {
        target: Qt.inputMethod
        onVisibleChanged: {
            Qt.callLater(function() {
                if (visible && root.focusedTextField == null) {
                    // If VK is visible, store reference of original focus textfield on
                    // which VK will operate
                    root.focusedTextField = applicationWindow().activeFocusItem
                    textfield.text = root.focusedTextField.text ? root.focusedTextField.text : ""
                    textfield.forceActiveFocus()
                    textfield.selectAll()
                } else if (!visible) {
                    // If VK is not visible, delete reference of last focused textfield
                    root.focusedTextField = null
                    applicationWindow().forceActiveFocus()
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
                applicationWindow().forceActiveFocus()
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
        color: "#ee222222"

        // Hide VK when clicked outside textfield
        MouseArea {
            anchors.fill: parent
            onClicked: {
                Qt.inputMethod.hide()
                applicationWindow().forceActiveFocus()
            }
        }

        QQC2.TextField {
            id: textfield

            anchors.centerIn: parent
            width: parent.width * 0.4
            height: Kirigami.Units.gridUnit * 3
            horizontalAlignment: "AlignHCenter"
            verticalAlignment: "AlignVCenter"
            selectByMouse: true
            inputMethodHints: root.focusedTextField ? root.focusedTextField.inputMethodHints : 0
            onAccepted: {
                // When temporary textfield is accepted, set text property of original focused textfield to
                // this one and hide VK
                root.focusedTextField.text = textfield.text
                Qt.inputMethod.hide()
                applicationWindow().forceActiveFocus()
            }
        }
    }

    InputPanel {
        id: inputPanel
        active: Qt.inputMethod.visible
        visible: Qt.inputMethod.visible
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
