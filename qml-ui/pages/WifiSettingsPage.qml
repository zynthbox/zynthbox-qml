/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI
A Page for displaying and configuring wifi connections

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>

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

import Zynthian 1.0 as Zynthian
import "ZynthiLoops" as ZynthiLoops

Zynthian.ScreenPage {
    id: root
    title: qsTr("Wifi Settings")
    screenId: "wifi_settings"
    
    Connections {
        target: zynthian
        onCurrent_screen_idChanged: {
            if (zynthian.current_screen_id === root.screenId) {
                // Reload wifi list
                console.log("AVAILABLE WIFI NETWORKS", JSON.stringify(zynthian.wifi_settings.list_available_wifi_networks(), null, 2))
                console.log("SAVED WIFI NETWORKS", JSON.stringify(zynthian.wifi_settings.list_saved_wifi_networks(), null, 2))
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        radius: 2
    }
}
