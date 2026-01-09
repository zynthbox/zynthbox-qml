/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>

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

import io.zynthbox.ui 1.0 as ZUI
import io.zynthbox.ui2 1.0 as ZUI2

ZUI2.ScreenPage {
    screenId: "norns_shield"
    contextualActions: [
        Kirigami.Action {
            text: qsTr("Control Norns")
            Kirigami.Action {
                text: qsTr("Start Norns")
                enabled: shieldLoader.item && !shieldLoader.item.fatesRunning
            }
            Kirigami.Action {
                text: qsTr("Stop Norns")
                enabled: shieldLoader.item && shieldLoader.item.fatesRunning
            }
        }
    ]
    contentItem: Item {
        Loader {
            id: shieldLoader
            anchors.fill: parent
            source: "NornsPageProxy.qml"
        }
        QQC2.Label {
            anchors.fill: parent
            visible: shieldLoader.status == Loader.Error
            text: "Error occurred during loading of the Norns component."
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }
}
