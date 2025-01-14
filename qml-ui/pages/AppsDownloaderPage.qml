/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Download page for Modules (software packages)

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

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.NewStuffPage {
    id: component
    screenId: "apps_downloader"
    title: qsTr("Apps Downloader")
    // The configFile entry is local-only and we need to strip the URL bits from the resolved version...
    configFile: Qt.resolvedUrl("zynthbox-apps.knsrc").toString().slice(7)
    onItemInstalled: {
        Zynthbox.AppImageHelper.registerAppImage(itemData[NewStuff.ItemsModel.InstalledFilesRole][0])
    }
    onItemUninstalled: {
        Zynthbox.AppImageHelper.unregisterAppImage(itemData[NewStuff.ItemsModel.UnInstalledFilesRole][0])
    }
    Connections {
        target: component.backAction
        onTriggered: {
            // or whatever this function would be called
            zynqtgui.main.refresh();
        }
    }
}
