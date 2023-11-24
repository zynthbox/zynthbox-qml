/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Download page for Zynthbox Sketchpads

Copyright (C) 2022 Dan Leinir Turthra Jensen <admin@leinir.dk>

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

import Zynthian 1.0 as Zynthian

Zynthian.NewStuffPage {
    id: component
    screenId: "sketchpad_downloader"
    title: qsTr("Sketchpad Downloader")
    // The configFile entry is local-only and we need to strip the URL bits from the resolved version...
    configFile: Qt.resolvedUrl("zynthbox-sketchpads.knsrc").toString().slice(7)

    showUseThis: true
    useThisLabel: qsTr("Create New From This")
    onUseThis: {
        if (installedFiles.length === 1) {
            if (installedFiles[0].endsWith("*")) {
                // The way archives are listed means we get a single installed file entry, with a * at the end, so use that to do the "create a thing from a folder" trick
                let sketchpadFolder = installedFiles[0].slice(0, -1);
                zynqtgui.sketchpad.newSketchpadFromFolder(sketchpadFolder);
            } else {
                // Then this downloaded file was not a proper archive (which shouldn't really happen without also matching the previous check)
            }
        } else {
            // Then there's too many files, and we don't properly know what to do with that - warn the user somehow
        }
    }
}

