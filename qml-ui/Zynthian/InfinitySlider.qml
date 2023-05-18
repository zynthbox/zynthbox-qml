/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

ADSR envelope editor for sketchpad clips

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
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

Item {
    id: component
    property alias text: descriptionLabel.text
    property double value: 0
    property string unitLabel: ""
    property double increment: 0.1
    property double slideIncrement: 0.01
    property bool applyLowerBound: false
    property double lowerBound: 0
    property bool applyUpperBound: false
    property double upperBound: 0
    property bool selected: false
    property int decimals: 2
    property bool resetOnTap: false
    property double resetValue: 0
    MultiPointTouchArea {
        anchors.fill: parent
        touchPoints: [
            TouchPoint {
                id: slidePoint;
                property var currentValue: undefined
                property var pressedTime: undefined
                onPressedChanged: {
                    if (pressed) {
                        pressedTime = Date.now();
                        currentValue = component.value;
                    } else {
                        // Only reset if we are asked to, have no meaningful changes to the value, and the timing was reasonably
                        // a tap (arbitrary number here, should be a global constant somewhere we can use for this)
                        if (component.resetOnTap && Math.abs(component.value - currentValue) < component.increment && (Date.now() - pressedTime) < 300) {
                            component.value = component.resetValue;
                        }
                        currentValue = undefined;
                    }
                }
                onYChanged: {
                    if (pressed && currentValue !== undefined) {
                        var delta = -(slidePoint.y - slidePoint.startY) * component.slideIncrement;
                        if (component.applyLowerBound) {
                            if (component.applyUpperBound) {
                                component.value = Math.min(Math.max(currentValue + delta, component.lowerBound), component.upperBound);
                            } else {
                                component.value = Math.max(currentValue + delta, component.lowerBound);
                            }
                        } else if (component.applyUpperBound) {
                                component.value = Math.min(currentValue + delta, component.upperBound);
                        } else {
                            component.value = currentValue + delta;
                        }
                    }
                }
            }
        ]
    }
    ColumnLayout {
        anchors.fill: parent
        Kirigami.Heading {
            id: descriptionLabel
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            level: 2
        }
        QQC2.Button {
            Layout.fillWidth: true
            text: "+" + component.increment
            enabled: component.applyUpperBound === false || component.upperBound > component.value
            onClicked: {
                if (component.applyUpperBound) {
                    component.value = Math.min(component.upperBound, component.value + component.increment);
                } else {
                    component.value = component.value + component.increment;
                }
            }
        }
        Kirigami.Heading {
            Layout.fillHeight: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            level: 3
            text: component.value.toFixed(component.decimals) + component.unitLabel
        }
        QQC2.Button {
            Layout.fillWidth: true
            text: "-" + component.increment
            enabled: component.applyLowerBound === false || component.lowerBound < component.value
            onClicked: {
                if (component.applyLowerBound) {
                    component.value = Math.min(component.lowerBound, component.value - component.increment);
                } else {
                    component.value = component.value - component.increment;
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 2
            Layout.maximumHeight: 2
            color: component.selected === true ? Kirigami.Theme.highlightedTextColor : "transparent"
        }
    }
}
