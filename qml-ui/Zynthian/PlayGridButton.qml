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
    // Whether or not pressing and holding the button should be visualised
    property bool visualPressAndHold: false
    // Whether or not we are currently holding the button down and are past the press and hold threshold
    property bool pressingAndHolding: false
    // Because otherwise we can't emit the signal, because the pressed property takes over...
    signal pressed();
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
            color: component.visible ? (component.down ? Kirigami.Theme.focusColor : Kirigami.Theme.textColor) : ""
        }
        color: component.visible ? (component.checked ? Kirigami.Theme.focusColor: Kirigami.Theme.backgroundColor) : ""
    }
    Rectangle {
        id: pressAndHoldVisualiser
        anchors {
            left: parent.right
            leftMargin: width / 2
            bottom: parent.bottom
        }
        width: Kirigami.Units.smallSpacing
        visible: component.visualPressAndHold
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Button
        color: visible ? Kirigami.Theme.focusColor : ""
        height: 0
        opacity: 0
        states: [
            State {
                name: "held"; when: (longPressTimer.running || component.pressingAndHolding);
                PropertyChanges { target: pressAndHoldVisualiser; height: component.height; opacity: 1 }
            }
        ]
        transitions: [
            Transition {
                from: ""; to: "held";
                NumberAnimation { property: "height"; duration: longPressTimer.interval; }
                NumberAnimation { property: "opacity"; duration: longPressTimer.interval; }
            }
        ]
        Timer {
            id: longPressTimer;
            interval: 1000; repeat: false; running: false
            property bool insideBounds: false;
            onTriggered: {
                if (insideBounds) {
                    component.pressAndHold();
                }
                component.pressingAndHolding = true;
            }
        }
    }
    MultiPointTouchArea {
        anchors.fill: parent
        touchPoints: [
            TouchPoint {
                function updateInsideBounds() {
                    if (pressed) {
                        if (x > -1 && y > -1 && x < component.width && y < component.height) {
                            longPressTimer.insideBounds = true;
                        } else {
                            longPressTimer.insideBounds = false;
                        }
                    }
                }
                onXChanged: updateInsideBounds();
                onYChanged: updateInsideBounds();
                onPressedChanged: {
                    if (pressed) {
                        component.pressed();
                        component.down = true;
                        component.focus = true;
                        updateInsideBounds();
                        longPressTimer.restart();
                    } else {
                        component.released();
                        component.down = false;
                        if (x > -1 && y > -1 && x < component.width && y < component.height) {
                            component.clicked();
                        }
                        component.pressingAndHolding = false;
                        longPressTimer.stop();
                    }
                }
            }
        ]
    }
}
