/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Action Picker Popup, shows a list of actions in a finger-friendly manner

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
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami
import Zynthian 1.0 as Zynthian

Zynthian.Popup {
    id: component

    property list<QQC2.Action> actions
    property int rows: 3
    property int columns: Math.ceil(component.actions.length / 3) // Auto calculate columns if not provided

    parent: QQC2.Overlay.overlay
    y: parent !== null ? parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y : 0
    x: parent !== null ? parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x : 0
    width: mainLayout.implicitWidth + mainLayout.columnSpacing*2
    height: mainLayout.implicitHeight + mainLayout.rowSpacing*2

    Timer {
        id: popupCloser
        interval: 1; running: false; repeat: false;
        onTriggered: {
            component.close();
        }
    }
    GridLayout {
        id: mainLayout
        anchors.fill: parent
        rowSpacing: Kirigami.Units.largeSpacing
        columnSpacing: Kirigami.Units.largeSpacing
        columns: component.columns
        rows: component.rows
        flow: GridLayout.TopToBottom
        Repeater {
            model: component.actions
            delegate: PlayGridButton {
                id: delegate
                Layout.minimumWidth: Kirigami.Units.gridUnit * 12
                Layout.minimumHeight: Kirigami.Units.gridUnit * 4
                Layout.maximumWidth: Kirigami.Units.gridUnit * 12
                Layout.maximumHeight: Kirigami.Units.gridUnit * 4
                Layout.alignment: Qt.AlignCenter
                action: modelData
                visible: modelData != null && modelData.hasOwnProperty("visible") ? modelData.visible : true
                invertBorderColor: true
                onClicked: {
                    action.trigger();
                    component.close();
                }
            }
        }
    }
}
