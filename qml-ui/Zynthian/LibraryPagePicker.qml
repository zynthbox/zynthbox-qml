/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Hyper-specific component used by Library pages to display their section tabs

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

ActionRow {
    id: component
    property QtObject selectedChannel
    property string libraryName: ""
    actions: [
        Kirigami.Action {
            text: qsTr("Synths")
            visible: component.selectedChannel && component.selectedChannel.trackType !== "sample-loop"
            checked: component.libraryName === "synths"
            onTriggered: {
                if (zynqtgui.current_screen_id !== "preset") {
                    pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("synth", 0);
                    zynqtgui.show_screen("preset");
                }
            }
        }, Kirigami.Action {
            text: component.selectedChannel && component.selectedChannel.trackType === "sample-loop" ? qsTr("Loops") : qsTr("Samples")
            checked: component.libraryName === "samples"
            onTriggered: {
                if (zynqtgui.current_screen_id !== "sample_library") {
                    if (component.selectedChannel.trackType === "sample-loop") {
                        pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sketch", 0);
                    } else {
                        pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sample", 0);
                    }
                    zynqtgui.show_screen("sample_library");
                }
            }
        }, Kirigami.Action {
            text: qsTr("FX")
            visible: component.selectedChannel && component.selectedChannel.trackType !== "sample-loop"
            checked: component.libraryName === "fx"
            onTriggered: {
                if (zynqtgui.current_screen_id !== "effect_preset") {
                    pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("fx", 0);
                    zynqtgui.show_screen("effect_preset");
                }
            }
        }, Kirigami.Action {
            text: qsTr("FX")
            visible: component.selectedChannel && component.selectedChannel.trackType === "sample-loop"
            checked: component.libraryName === "sketchfx"
            onTriggered: {
                if (zynqtgui.current_screen_id !== "sketch_effect_preset") {
                    pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sketch-fx", 0);
                    zynqtgui.show_screen("sketch_effect_preset");
                }
            }
        }
    ]
}
