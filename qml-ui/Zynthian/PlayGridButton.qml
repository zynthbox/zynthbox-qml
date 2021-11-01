/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Base Drums Grid Component 

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>
Copyright (C) 2021 David Nelvand <dnelband@gmail.com>

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

QQC2.Button {
    id: component
    // Because otherwise we can't emit the signal, because the pressed property takes over...
    signal pressed();
    // Because we no longer have a pressed property... (yeah, this is kind of a mess, but there's not a whole lot we can do about it)
    property bool isPressed: false;
    Layout.fillWidth: true
    Layout.fillHeight: true
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    background: Rectangle {
        radius: 2
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Button
        border {
            width: 1
            color: component.isPressed ? Kirigami.Theme.focusColor : Kirigami.Theme.textColor
        }
        color: component.checked ? Kirigami.Theme.focusColor: Kirigami.Theme.backgroundColor
    }
    MultiPointTouchArea {
        anchors.fill: parent
        touchPoints: [
            TouchPoint {
                onPressedChanged: {
                    if (pressed) {
                        component.pressed();
                        component.isPressed = true;
                        component.focus = true;
                    } else {
                        component.released();
                        component.isPressed = false;
                        if (x > -1 && y > -1 && x < component.width && y < component.height) {
                            component.clicked();
                        }
                    }
                }
            }
        ]
    }
}
