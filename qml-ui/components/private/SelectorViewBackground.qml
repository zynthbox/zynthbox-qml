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

Rectangle {
    property bool highlighted

    readonly property real leftPadding: 1
    readonly property real rightPadding: 1
    readonly property real topPadding: Kirigami.Units.gridUnit/2
    readonly property real bottomPadding: Kirigami.Units.gridUnit/2

    color: Kirigami.Theme.backgroundColor
    border.color: highlighted
            ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.5)
            : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3)
    radius: Kirigami.Units.gridUnit/2

    Kirigami.Separator {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: parent.radius
        }
        color: Kirigami.Theme.textColor
        opacity: 0.4
        visible: !view.atYBeginning
    }
    Kirigami.Separator {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: parent.radius
        }
        color: Kirigami.Theme.textColor
        opacity: 0.4
        visible: !view.atYEnd
    }
}

