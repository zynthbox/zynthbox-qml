/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Test Touchpoints Page 

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
import org.kde.kirigami 2.4 as Kirigami

import io.zynthbox.ui 1.0 as Zynthian

Zynthian.ScreenPage {
    screenId: "test_touchpoints"

    MultiPointTouchArea {
        anchors.fill: parent
        touchPoints: [
            TouchPoint { id: point0 },
            TouchPoint { id: point1 },
            TouchPoint { id: point2 },
            TouchPoint { id: point3 },
            TouchPoint { id: point4 }
        ]
    }

    Rectangle {
        width: 50
        height: 50
        x: point0.x
        y: point0.y

        border.width: 4
        border.color: "red"
    }
    Rectangle {
        width: 50
        height: 50
        x: point1.x
        y: point1.y

        border.width: 4
        border.color: "green"
    }
    Rectangle {
        width: 50
        height: 50
        x: point2.x
        y: point2.y

        border.width: 4
        border.color: "blue"
    }
    Rectangle {
        width: 50
        height: 50
        x: point3.x
        y: point3.y

        border.width: 4
        border.color: "yellow"
    }
    Rectangle {
        width: 50
        height: 50
        x: point4.x
        y: point4.y

        border.width: 4
        border.color: "orange"
    }
}
