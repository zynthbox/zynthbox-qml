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
    contextualActions: [
        Kirigami.Action {
            text: qsTr("Synths")
            onTriggered: zynthian.layer.select_engine()
        },
        Kirigami.Action {
            text: qsTr("Audio-FX")
            onTriggered: {
                zynthian.layer_options.show(); //FIXME: that show() method should change name
                zynthian.current_screen_id = "layer_effects";
            }
        },
        Kirigami.Action {
            text: qsTr("Edit")
            onTriggered: zynthian.current_screen_id = "control"
        }
    ]

    screenIds: ["layer", "bank", "preset"]
    screenTitles: [qsTr("Layers (%1)").arg(zynthian.layer.effective_count || qsTr("None")), qsTr("Banks (%1)").arg(zynthian.bank.selector_list.count), qsTr("Presets (%1)").arg(zynthian.preset.selector_list.count)]
    previousScreen: "main"
    onCurrentScreenIdRequested: zynthian.current_screen_id = screenId

}


