/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Download page for Zynthbox Sound files (.snd, being the sound setup for a full track)

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

import QtQuick 2.10
import org.kde.newstuff 1.0 as NewStuff

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.NewStuffPage {
    id: component
    screenId: "sound_downloader"
    title: qsTr("Sound Downloader")
    // The configFile entry is local-only and we need to strip the URL bits from the resolved version...
    configFile: Qt.resolvedUrl("zynthbox-sounds.knsrc").toString().slice(7)

    QtObject {
        id: _private
        property var installedBeforeUpdate: []
    }
    onUseThis: function(installedFiles) {
        // We will need to ask a few questions about precisely *where* this sound wants to be used...
    }
    onItemInstalled: function(itemData) {
        // Once a new sound had been installed, we'll want to inform the library about that
        // Also, in case this is the result of an update action, we should make sure to also update the files we had prior to the update...
        let filesToUpdate = [itemData[NewStuff.ItemsModel.InstalledFilesRole]];
        for (let index = 0; index < _private.installedBeforeUpdate.length; ++index) {
            if (filesToUpdate.includes(_private.installedBeforeUpdate[index]) == false) {
                filesToUpdate.append(_private.installedBeforeUpdate[index]);
            }
        }
        // Now process the files
        Zynthbox.SndLibrary.processSndFiles(filesToUpdate);
        // And now we've handled them... clear out the pre-update list, so we only handle them once
        _private.installedBeforeUpdate = [];
    }
    onItemUninstalled: function(itemData) {
        // When uninstalling a sound, we'll want to inform the library about that
        Zynthbox.SndLibrary.processSndFiles([itemData[NewStuff.ItemsModel.UninstalledFilesRole]]);
    }
    onItemUpdating: function(itemData) {
        // Since we're updating one of our sounds, we will need to first remove
        // the old one (as it's about to be deleted anyway), and then once the
        // update is completed, itemInstalled gets fired and we can treat that
        // as a newly installed file.
        // TODO In the meantime, we will need to store what personal things our user
        // has done to it (specifically: keep track of what user categories the
        // sound had been added to)
        Zynthbox.SndLibrary.processSndFiles([itemData[NewStuff.ItemsModel.InstalledFilesRole]]);
    }
}
