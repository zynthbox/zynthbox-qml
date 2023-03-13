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

    x: Math.round(parent.width/2 - width/2)
    y: Math.round(parent.height/2 - height/2)
    width: Kirigami.Units.gridUnit * 20
    height: Kirigami.Units.gridUnit * 10
    parent: QQC2.Overlay.overlay

    property var cuiaCallback: function(cuia) {
        result = false;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                component.reject();
                result = true;
                break;
            case "SWITCH_SELECT_SHORT":
                component.accept();
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
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            text: qsTr("No")
            onClicked: {
                component.reject();
            }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            text: qsTr("Yes")
            onClicked: {
                component.accept();
            }
        }
    }
}

