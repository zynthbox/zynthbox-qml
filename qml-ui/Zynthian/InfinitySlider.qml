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
    property string valueString: "" // If this is set to anything other than an empty string, it will be used in place of the value and unit logic
    property string unitLabel: "" // If this is set to "%", value will be reinterpreted as a percentage (that is, 0 through 1 will become 0 through 100, and the decimals will be reduced by 2)
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
    property alias knobId: knobIndicator.knobId
    Component.onCompleted: {
        valueLabelThrottle.restart();
    }
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
    Kirigami.Heading {
        id: descriptionLabel
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Kirigami.Units.smallSpacing
        }
        height: contentHeight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignTop
        level: 2
        KnobIndicator {
            id: knobIndicator
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.horizontalCenter
                rightMargin: parent.paintedWidth / 2
            }
            width: Kirigami.Units.iconSizes.small
            visible: component.selected
            knobId: -1
        }
    }
    Item {
        anchors {
            top: descriptionLabel.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: Kirigami.Units.smallSpacing
        }
        QQC2.Button {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
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
            id: valueLabel
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            level: 3
            Timer {
                id: valueLabelThrottle
                interval: 0; running: false; repeat: false;
                onTriggered: {
                    if (component.valueString.length > 0) {
                        valueLabel.text = component.valueString;
                    } else if (component.unitLabel === "%") {
                        valueLabel.text = (100 *component.value).toFixed(Math.max(0, component.decimals - 2)) + component.unitLabel;
                    } else {
                        valueLabel.text = component.value.toFixed(component.decimals) + component.unitLabel;
                    }
                }
            }
            Connections {
                target: component
                onValueChanged: valueLabelThrottle.restart()
                onDecimalsChanged: valueLabelThrottle.restart()
                onUnitLabelChanged: valueLabelThrottle.restart()
                onValueStringChanged: valueLabelThrottle.restart()
            }
        }
        QQC2.Button {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            text: "-" + component.increment
            enabled: component.applyLowerBound === false || component.lowerBound < component.value
            onClicked: {
                if (component.applyLowerBound) {
                    component.value = Math.max(component.lowerBound, component.value - component.increment);
                } else {
                    component.value = component.value - component.increment;
                }
            }
        }
    }
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 2
        color: component.selected === true ? Kirigami.Theme.highlightedTextColor : "transparent"
    }
}
