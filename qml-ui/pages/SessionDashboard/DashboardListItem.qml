/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Session Dashboard page for Zynthian GUI

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
import io.zynthbox.components 1.0 as Zynthbox

Kirigami.AbstractListItem {
    id: root
    property alias patternConnections: dragManager.patternConnections
    property alias secondColumn: dragManager.secondColumn
    separatorVisible: false
    property alias dragManager: dragManager
    signal requestConnect(Item child)
    topPadding: 0
    bottomPadding: 0
    property int row: index

    contentItem: QQC2.Label {
        id: label
        text: root.text
    }

    data: [
        ConnectionsDragManager {
            id: dragManager
            parent: root
            z: 99999
            anchors.fill: parent
            patternConnections: patternSoundsConnections
            secondColumn: layersView.contentItem
            onClicked: root.clicked()
            onRequestConnect: root.requestConnect(child)
        }
    ]
}


