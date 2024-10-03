/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Download page for Zynthbox Samples

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
    screenId: "sketch_downloader"
    title: qsTr("Sketch Downloader")
    // The configFile entry is local-only and we need to strip the URL bits from the resolved version...
    configFile: Qt.resolvedUrl("zynthbox-sketches.knsrc").toString().slice(7)

    showUseThis: true
    onUseThis: {
        let currentChannel = zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId);
        if (installedFiles.length > 0) {
            if (installedFiles.length > 4) {
                for (let fileIndex = 0; fileIndex < 5; ++fileIndex) {
                    if (currentChannel.trackType === "sample-loop") {
                        var clip = currentChannel.getClipsModelById(fileIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                        clip.path = installedFiles[fileIndex];
                        clip.enabled = true
                    } else {
                        currentChannel.set_sample(installedFiles[fileIndex], fileIndex);
                    }
                 }
            } else {
                if (currentChannel.trackType === "sample-loop") {
                    var clip = currentChannel.getClipsModelById(currentChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                    clip.path = installedFiles[0];
                    clip.enabled = true
                } else {
                    currentChannel.set_sample(installedFiles[0], currentChannel.selectedSlotRow);
                }
            }
            if (installedFiles.length !== 1 && installedFiles.length !== 5) {
                // maybe a warning that there's an unexpected amount of files and we can't really work out what to do with that other than "just use the first" or "use the first five"?
            }
        }
        zynqtgui.callable_ui_action_simple("SWITCH_BACK_SHORT")
    }
}
