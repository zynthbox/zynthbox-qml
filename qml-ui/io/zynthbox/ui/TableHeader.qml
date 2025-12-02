/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>

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
import QtQml.Models 2.10
import org.kde.kirigami 2.4 as Kirigami

import io.zynthbox.ui 1.0 as ZUI


QQC2.AbstractButton {
    id: root

//    Layout.preferredWidth: privateProps.headerWidth
//    Layout.maximumWidth: privateProps.headerWidth
    Layout.fillHeight: true

    property alias subText: contents.text2
    property alias iconSource: icon.source
    property var color

    contentItem: Item {
        Kirigami.Icon {
            id: icon

            anchors.centerIn: parent
            width: 18
            height: 18
            color: "white"
        }

        TableHeaderLabel {
            id: contents
            anchors.centerIn: parent
            text: root.text
            text2: root.subText
        }
    }

    onPressed: root.forceActiveFocus();

    onActiveFocusChanged: {
        console.log("Item with active Focus :", activeFocus)
    }

    background: Rectangle { //TODO: plasma theming
        border.width: root.activeFocus ? 1 : 0
        border.color: Kirigami.Theme.highlightColor

        color: root.color ? root.color : Kirigami.Theme.backgroundColor
    }
}
