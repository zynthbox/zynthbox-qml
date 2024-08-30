/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Knob Indicator Component

Copyright (C) 2022 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.0 as Kirigami

/**
 * \brief Used to indicate whether a knob will control something, and passes information to the listener
 *
 * Use is deliberately simple. For example, the following code will write "down" and "up"
 * to the log when the component is visible and knob 2 (the third small knob) is twisted:
 * \code
KnobIndicator {
    knobId: 2
    onKnobUp: { console.log("up"); }
    onKnobDown: { console.log("down"); }
}
 * \endcode
 */
Item {
    id: component

    /*
     * By default, we bind enabled to visible, but the user can override this if needed
     */
    enabled: visible
    /**
     * \brief Which knob to operate on (from 0 through 3)
     * The large knob is id 3
     * The three smaller knobs, from top to bottom, are ID 0, 1, and 2
     * @default No knob is inspected
     */
    property int knobId: -1
    property int rotationFactor: 1
    signal knobUp()
    signal knobDown()

    onKnobUp: {
        //indicatorRect.movingDirection = 1;
        ridges.currentPointRotation = ridges.currentPointRotation + component.rotationFactor;
    }
    onKnobDown: {
        //indicatorRect.movingDirection = -1;
        ridges.currentPointRotation = ridges.currentPointRotation - component.rotationFactor;
    }
    Rectangle {
        id: indicatorRect
        anchors.centerIn: parent
        // This allows for the component to be positioned in all manner of fun places
        width: Math.min(component.width, component.height);
        height: width
        radius: width / 2
        color: Kirigami.Theme.buttonFocusColor
        border {
            width: 1
            color: Kirigami.Theme.buttonTextColor
        }
        //property int movingDirection: 0
        //onMovingDirectionChanged: {
            //if (indicatorRect.movingDirection !== 0) {
                //indicatorTimer.restart();
            //}
        //}
        //Timer {
            //id: indicatorTimer
            //interval: 333; running: false; repeat: false;
            //onTriggered: {
                //indicatorRect.movingDirection = 0;
            //}
        //}
        QQC2.Label {
            anchors.fill: parent
            font.pixelSize: height/2
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: {
                switch(component.knobId) {
                    case 0:
                        return "K1";
                    case 1:
                        return "K2";
                    case 2:
                        return "K3";
                    case 3:
                        return "BK";
                }
            }
            color: Kirigami.Theme.buttonTextColor
        }
        Item {
            id: ridges
            property real currentPointRotation
            anchors.fill: parent
            rotation: ridges.currentPointRotation
            Repeater {
                model: 4
                Item {
                    anchors.centerIn: parent
                    width: ridges.width
                    height: 5
                    rotation: 45 * index
                    Rectangle {
                        anchors {
                            left: parent.left
                            leftMargin: -1
                        }
                        height: parent.height
                        width: 3
                        color: Kirigami.Theme.buttonTextColor
                        radius: height
                    }
                    Rectangle {
                        anchors {
                            right: parent.right
                            rightMargin: -1
                        }
                        height: parent.height
                        width: 3
                        color: Kirigami.Theme.buttonTextColor
                        radius: height
                    }
                }
            }
        }
    }
    Connections {
        target: zynqtgui
        enabled: component.visible && component.enabled && component.knobId > -1 && component.knobId < 4
        function onKnobDeltaChanged(knobIndex, delta) {
            if (component.knobId === knobIndex) {
                for (var i=0; i<Math.abs(delta); i++) {
                    if (delta < 0) {
                        component.knobDown()
                    } else {
                        component.knobUp()
                    }
                }
            }
        }
    }
}
