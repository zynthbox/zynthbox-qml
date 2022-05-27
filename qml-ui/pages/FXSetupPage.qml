/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

Copyright (C) 2021 Marco Martin <mart@kde.org>

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

Zynthian.MultiSelectorPage {
    id: root


    screenIds: ["layer_effects", "effect_types", "layer_effect_chooser"]
    screenTitles: [qsTr("Active FX (%1)").arg(zynthian.layer_effects.effective_count || qsTr("None")), qsTr("FX Type (%1)").arg(zynthian.effect_types.effective_count), qsTr("FX (%1)").arg(zynthian.layer_effect_chooser.effective_count)]

    previousScreen: "preset"

    backAction: Kirigami.Action {
        text: qsTr("Back")
        onTriggered: {
            if (zynthian.forced_screen_back !== "") {
                zynthian.current_screen_id = zynthian.forced_screen_back;
            } else {
                zynthian.current_screen_id = "preset"
            }
        }
    }
    contextualActions: [
        Kirigami.Action {
            visible: false
        },
        Kirigami.Action {
            visible: false
        },
        Kirigami.Action {
            text: qsTr("Edit")
            enabled: zynthian.layer_effects.current_effect_engine.length > 0
            onTriggered: {
                zynthian.control.single_effect_engine = zynthian.layer_effects.current_effect_engine;
                zynthian.current_screen_id = "control";
            }
        }
    ]
    onVisibleChanged: {
        if (visible) {
            zynthian.control.single_effect_engine = ""
        }
    }
    Connections {
        id: currentConnection
        target: zynthian
        onCurrent_screen_idChanged: {
            print(zynthian.current_screen_id +" "+ applicationWindow().pageStack.lastItem +" "+ root)
            if (zynthian.current_screen_id !== "layer_effects" && zynthian.current_screen_id !== "effect_types" && zynthian.current_screen_id !== "layer_effect_chooser" && applicationWindow().pageStack.lastItem === root) {
                pageRemoveTimer.restart()
            }
        }
    }
    Timer {
        id: pageRemoveTimer
        interval: Kirigami.Units.longDuration
        onTriggered: {
            if (zynthian.current_screen_id !== "layer_effects" && zynthian.current_screen_id !== "effect_types" && zynthian.current_screen_id !== "layer_effect_chooser" && applicationWindow().pageStack.lastItem === root) {
                applicationWindow().pageStack.pop();
            }
        }
    }
}


