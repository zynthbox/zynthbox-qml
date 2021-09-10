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

Zynthian.ScreenPage {
    screenId: "main"
    backAction.visible: false

    contentItem:GridView {

        property int gridWidth: screen.width - (Kirigami.Units.gridUnit * 2) - 4
        property int gridHeight: screen.height - (Kirigami.Units.gridUnit * 8) - 4

        property int iconWidth: (gridWidth / 6)
        property int iconHeight:  (gridHeight / 2)

        id:mainviewGridId
        width: gridWidth
        height: gridHeight
        Layout.fillWidth: true
        cellWidth:iconWidth
        cellHeight:iconHeight

        model:zynthian.main.selector_list
        delegate: HomeScreenIcon {                
            rectWidth: mainviewGridId.iconWidth
            rectHeight:  mainviewGridId.iconHeight
            imgSrc: model.icon
            onClicked: zynthian.main.activate_index(model.index)
            text: model.display
        }
    }

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Power")
            Kirigami.Action {
                text: qsTr("Restart UI")
                onTriggered: zynthian.main.restart_gui()
            }
            Kirigami.Action {
                text: qsTr("Reboot")
                onTriggered: zynthian.main.reboot()
            }
            Kirigami.Action {
                text: qsTr("Power Off")
                onTriggered: zynthian.main.power_off()
            }
        },
        Kirigami.Action {
            text: qsTr("Get New Modules")
            onTriggered: zynthian.show_modal("module_downloader")
        }
    ]
}
