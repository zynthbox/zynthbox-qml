/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Dialog component for asking binary (yes/no) questions in a globally consistent manner

Copyright (C) 2023 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian

Zynthian.Dialog {
    id: component

    /**
     * The body of the dialog (shown in a Qt Quick Components Label)
     */
    property string text
    /**
     * The string used for the accept button
     */
    property string acceptText: qsTr("Yes")
    /**
     * Whether or not the accept button is enabled
     */
    property alias acceptEnabled: acceptButton.enabled
    /**
     * The string used for the reject button
     */
    property string rejectText: qsTr("No")
    /**
     * Whether or not the reject button is enabled
     * @note You probably don't want to actually disable this, but the property is here for symmetry
     */
    property alias rejectEnabled: rejectButton.enabled

    x: Math.round(parent.width/2 - width/2)
    y: Math.round(parent.height/2 - height/2)
    width: Kirigami.Units.gridUnit * 20
    height: Kirigami.Units.gridUnit * 10
    parent: QQC2.Overlay.overlay

    property var selectedButton: rejectButton
    property var cuiaCallback: function(cuia) {
        var result = component.opened;
        switch (cuia) {
            case "KNOB3_DOWN":
            case "NAVIGATE_LEFT":
                component.selectedButton = rejectButton
                result = true;
                break;
            case "KNOB3_UP":
            case "NAVIGATE_RIGHT":
                component.selectedButton = acceptButton
                result = true;
                break;
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                component.reject();
                result = true;
                break;
            case "SWITCH_SELECT_SHORT":
                if (component.selectedButton.enabled) {
                    component.selectedButton.clicked();
                }
                result = true;
                break;
        }
        return result;
    }
    header: Kirigami.Heading {
        level: 2
        text: component.title
    }
    contentItem: QQC2.Label {
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: component.text
    }
    footer: RowLayout {
        PlayGridButton {
            id: rejectButton
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            text: component.rejectText
            visible: text !== ""
            invertBorderColor: true
            onClicked: {
                component.reject()
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: -5
                color: "transparent"
                border.width: 2
                border.color: Kirigami.Theme.textColor
                opacity: component.selectedButton === rejectButton ? 0.7 : 0
            }
        }
        PlayGridButton {
            id: acceptButton
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            text: component.acceptText
            visible: text !== ""
            invertBorderColor: true
            onClicked: {
                component.accept()
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: -5
                color: "transparent"
                border.width: 2
                border.color: Kirigami.Theme.textColor
                opacity: component.selectedButton === acceptButton ? 0.7 : 0
            }
        }
    }
}

