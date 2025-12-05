/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

A row used for choosing between one of several actions, with checking abilities

Copyright (C) 2025 Dan Leinir Turthra Jensen <admin@leinir.dk>

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

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.7 as Kirigami

import "private"

RowLayout {
    id: component
    property list<QQC2.Action> actions

    spacing: 0
    Repeater {
        model: component.actions
        delegate: PlayGridButton {
            id: buttonDelegate
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            text: modelData != null && modelData.hasOwnProperty("text") ? modelData.text : ""
            visible: modelData != null && modelData.hasOwnProperty("visible") ? modelData.visible : true
            enabled: modelData != null && modelData.hasOwnProperty("enabled") ? modelData.enabled : true
            checked: modelData != null && modelData.hasOwnProperty("checked") ? modelData.checked : false
            onClicked: {
                modelData.trigger();
            }
        }
    }
}
