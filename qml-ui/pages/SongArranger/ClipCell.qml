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

import Zynthian 1.0 as Zynthian


QQC2.AbstractButton {
    property bool highlighted: false
    property var zlClip

    id: root

    onPressed: forceActiveFocus()

    contentItem: Item {
        Zynthian.TableHeaderLabel {
            id: label
            text: zlClip ? zlClip.name : ""

            anchors.centerIn: parent
        }
    }

    background: Rectangle {
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)

        border.width: root.highlighted ? 1 : focus ? 1 : 0
        border.color: Kirigami.Theme.highlightColor
    }

    onActiveFocusChanged: {
        console.log("Item with active Focus :", activeFocus)
    }
}
