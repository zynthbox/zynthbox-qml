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
    property QQC2.ItemDelegate delegate

    readonly property real leftPadding: Kirigami.Units.largeSpacing
    readonly property real rightPadding: Kirigami.Units.largeSpacing
    readonly property real topPadding: Kirigami.Units.largeSpacing
    readonly property real bottomPadding: Kirigami.Units.largeSpacing

//    color: !delegate.ListView.isCurrentItem && !delegate.pressed
//        ? "transparent"
//        : ((delegate.ListView.view.activeFocus && !delegate.pressed || !delegate.ListView.view.activeFocus && delegate.pressed)
//                ? Kirigami.Theme.highlightColor
//                : Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.4))

//    Behavior on color {
//        ColorAnimation {
//            duration: Kirigami.Units.shortDuration
//            easing.type: Easing.InOutQuad
//        }
//    }

    color: "transparent"
    border.width: delegate.ListView.isCurrentItem ? 1 : 0
    border.color: Qt.rgba(255, 255, 255, 0.8)
    radius: 4
}

