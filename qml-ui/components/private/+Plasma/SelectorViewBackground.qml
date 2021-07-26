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

PlasmaCore.FrameSvgItem {
    id: root
    property bool highlighted

    readonly property real leftPadding: margins.left
    readonly property real rightPadding: margins.right
    readonly property real topPadding: margins.top
    readonly property real bottomPadding: margins.bottom

    imagePath: "widgets/background"
    prefix: highlighted ? ["focus", ""] : ""
    //colorGroup: PlasmaCore.Theme.ViewColorGroup

    Timer { //HACK AND BUG WORKAROUND
        id: updateTimer
        interval: 200
        onTriggered: {
            root.imagePath = "invalid"
            root.imagePath = "widgets/background"
            root.margins.marginsChanged()
        }
    }
    Connections {
        target: theme
        onThemeChangedProxy: {
            updateTimer.restart()
        }
    }

    Rectangle {
        anchors {
            fill: parent
            leftMargin: parent.margins.left
            topMargin: parent.margins.top
            rightMargin: parent.margins.right
            bottomMargin: parent.margins.bottom
        }
        visible: parent.highlighted && parent.usedPrefix !== "focus"
        color: "transparent"
        border.color: Kirigami.Theme.highlightColor
        radius: Kirigami.Units.smallSpacing
    }
}

