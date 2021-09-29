/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Button for Copier page 

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
import QtQuick.Shapes 1.0
import QtQuick.Controls 2.2 as QQC2
import QtQml.Models 2.10
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

QQC2.AbstractButton {
    id: root
    property bool highlighted: false
    property bool dummy: false
    property bool isCopySource: false
    property alias text2: label.text2

    onPressed: forceActiveFocus()

    contentItem: Item {
        Zynthian.TableHeaderLabel {
            id: label
            anchors.centerIn: parent
            text: root.text
        }
    }

    background: Rectangle {
        color: !root.dummy
                ? root.isCopySource
                   ? Qt.rgba(76, 175, 80, 0.4)
                   : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                : "transparent"

        border.color: root.isCopySource
                        ? "#4caf50"
                        : Kirigami.Theme.highlightColor
        border.width: root.highlighted || root.isCopySource ? 2 : 0
        radius: 4

        Shape {
            id: shape
            anchors.fill: parent
            visible: root.dummy

            ShapePath {
                strokeWidth: 2
                strokeColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                strokeStyle: ShapePath.DashLine
                fillColor: "transparent"

                startX: 0
                startY: 0

                PathLine { x: shape.width; y: 0 }
                PathLine { x: shape.width; y: shape.height }
                PathLine { x: 0; y: shape.height }
                PathLine { x: 0; y: 0 }
            }
        }
    }
}
