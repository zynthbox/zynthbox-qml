/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Download page for ZYnthian themes

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
import org.kde.newstuff 1.91 as NewStuff


import io.zynthbox.ui 1.0 as ZUI

ZUI.NewStuffPage {
    id: component
    screenId: "control_downloader"
    title: qsTr("Edit Pages Downloader")
    // The configFile entry is local-only and we need to strip the URL bits from the resolved version...
    configFile: Qt.resolvedUrl("zynthbox-engineeditpages.knsrc").toString().slice(7)

    showUseThis: true
    onUseThis: function(installedFiles) {
        // This needs a touch of clever going on, to detect whether we're attempting to use a mod-pack, or a mod
        console.log("Using a mod/modpack", installedFiles);
    }
    onItemInstalled: function(itemData) {
        // console.log("Installed item:", itemData[NewStuff.ItemsModel.InstalledFilesRole]);
        for (let installedFile of itemData[NewStuff.ItemsModel.InstalledFilesRole]) {
            zynqtgui.control.updateRegistryPartial(installedFile);
        }
    }
    onItemUninstalled: function(itemData) {
        // For some reason i don't quite understand, the uninstalled files role doesn't actually tell us what was removed,
        // and the installed files role retains its information... not sure what's up with that, but, it means we "simply"
        // need to use both when updating things.
        // console.log("Uninstalled item:", itemData[NewStuff.ItemsModel.UnInstalledFilesRole], itemData[NewStuff.ItemsModel.InstalledFilesRole]);
        for (let uninstalledFile of itemData[NewStuff.ItemsModel.UnInstalledFilesRole]) {
            zynqtgui.control.updateRegistryPartial(uninstalledFile);
        }
        for (let uninstalledFile of itemData[NewStuff.ItemsModel.InstalledFilesRole]) {
            zynqtgui.control.updateRegistryPartial(uninstalledFile);
        }
    }
    onItemUpdating: function(itemData) {
        // console.log("Updated item:", itemData[NewStuff.ItemsModel.InstalledFilesRole]);
        for (let updatedFile of itemData[NewStuff.ItemsModel.InstalledFilesRole]) {
            zynqtgui.control.updateRegistryPartial(updatedFile);
        }
    }
}
