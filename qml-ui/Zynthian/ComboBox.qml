/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

ComboBox like touch friendly component based on Popup

Copyright (C) 2023 Anupam Basak <anupam.basak27@gmail.com>

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
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import Zynthian 1.0 as Zynthian

QQC2.Button {
    id: root

    property alias model: popupRepeater.model
    property string textRole: ""
    property int currentIndex: -1
    property QtObject currentItem: null

    signal activated(int index)

    contentItem: QQC2.Label {
        horizontalAlignment: QQC2.Label.AlignLeft
        verticalAlignment: QQC2.Label.AlignVCenter
        text: root.model.get(root.currentIndex) && root.model.get(root.currentIndex)[root.textRole]
                ? root.model.get(root.currentIndex)[root.textRole]
                : ""
        color: Kirigami.Theme.textColor
    }
    onCurrentIndexChanged: {
        root.currentItem = popupRepeater.itemAt(root.currentIndex)
    }
    onClicked: {
        comboBoxPopup.open()
    }

    Zynthian.Popup {
        id: comboBoxPopup
        parent: QQC2.Overlay.overlay
        x: parent.width/2 - width/2
        y: parent.height/2 - height/2
        width: Kirigami.Units.gridUnit * 20

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Repeater {
                id: popupRepeater
                delegate: Kirigami.BasicListItem {
                    id: delegate
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                    reserveSpaceForIcon: false
                    highlighted: root.currentIndex === index
                    label: model[root.textRole]
                    onClicked: {
                        root.currentIndex = index
                        root.activated(index)
                        comboBoxPopup.close()
                    }
                }
            }
        }
    }
}
