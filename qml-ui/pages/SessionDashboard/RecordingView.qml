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
import org.zynthian.quick 1.0 as ZynQuick

RowLayout {
    id: root
    property int itemHeight: projectView.height / 15
    anchors {
        fill: parent
        topMargin: -Kirigami.Units.smallSpacing
        leftMargin: Kirigami.Units.gridUnit
    }

    spacing: 0
    ColumnLayout {
        spacing: 0
        Layout.fillHeight: true
        Layout.fillWidth: true

        Kirigami.Heading {
            level: 2
            text: qsTr("WIP Recording")
            MouseArea {
                anchors.fill: parent
                //onClicked: zynthian.current_modal_screen_id = "sketchpad_copier"
            }
        }
        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            ListView {
                id: projectView
            }
        }
    }
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}

