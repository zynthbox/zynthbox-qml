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

import org.kde.plasma.core 2.0 as PlasmaCore

QQC2.ToolButton {
    id: root
    Layout.fillHeight: true
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    leftPadding: rightPadding
    rightPadding: breadcrumbSeparator.width + Kirigami.Units.largeSpacing
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding + Kirigami.Units.gridUnit
    contentItem: QQC2.Label {
        text: root.text
    }
    background: Item {
        PlasmaCore.Svg {
            id: buttonSvg
            imagePath: Qt.resolvedUrl("../img/breadcrumb-background.svg")
        }

        PlasmaCore.SvgItem {
            anchors {
                right: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            svg: buttonSvg
            elementId: "left"
        }
        PlasmaCore.SvgItem {
            anchors {
                left: parent.left
                right: breadcrumbSeparator.left
                top: parent.top
                bottom: parent.bottom
            }
            svg: buttonSvg
            elementId: "center"
        }
        PlasmaCore.SvgItem {
            id: breadcrumbSeparator
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            svg: buttonSvg
            elementId: "right"
        }
    }
    opacity: checked ? 1 : 0.5
    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
}


