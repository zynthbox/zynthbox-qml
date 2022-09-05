/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Settings panel for a single step in a pattern

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
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

RowLayout {
    id: component
    property QtObject model
    property int row
    property int column

    property int paramIndex
    property string paramName
    property string paramDefaultString
    property string paramValuePrefix
    property string paramValueSuffix
    property var paramDefault
    property int paramInterpretedDefault: parseInt(paramDefault)
    property int paramMin
    property int paramMax
    property int scrollWidth

    // Couple of things directly related to the knob indicator contained within
    property bool currentlySelected: false
    property int knobId: 0

    // Set to an ordered list of values, which the -/+ buttons should flick
    // through in place of just switching numbers (that is still possible using
    // the tap-and-slide functionality)
    property var paramList: []
    // Set to an object with properties where the name is a parameter value,
    // and the value is the human-friendly string representing that value (for
    // e.g. { 1: "1/32", 2: "1/16", 4: "1/8", 8: "1/4", 16: "1/2", 32: "1"}
    // for the sub-divisions of a quarter note)
    property var paramNames: undefined

    readonly property var paramValue: component.model && component.row > -1 && component.column > -1 && updateForcery > -1 ? component.model.subnoteMetadata(component.row, component.column, component.paramIndex, paramName) : undefined;
    readonly property bool preferInterpretedValue: component.paramValue === undefined || isNaN(parseInt(component.paramValue)) || parseInt(component.paramValue) === 0
    property int updateForcery: 0
    Connections {
        target: component.model
        onLastModifiedChanged: {
            component.updateForcery += 1;
        }
    }
    function setNewValue(newValue) {
        if (newValue === component.paramInterpretedDefault) {
            newValue = component.paramDefault;
        }
        component.model.setSubnoteMetadata(component.row, component.column, component.paramIndex, paramName, newValue);
    }
    Zynthian.PlayGridButton {
        text: "-"
        Layout.preferredWidth: Kirigami.Units.gridUnit
        enabled: (component.preferInterpretedValue && component.paramInterpretedDefault > component.paramMin) || parseInt(component.paramValue) > component.paramMin
        onClicked: {
            if (component.paramList.length > 0) {
                var value = component.preferInterpretedValue ? component.paramInterpretedDefault : parseInt(component.paramValue);
                var newValue = component.paramMin;
                for (var i = component.paramList.length - 1; i > -1 ; --i) {
                    if (parseInt(component.paramList[i]) < value) {
                        newValue = parseInt(component.paramList[i]);
                        break;
                    }
                }
                component.setNewValue(newValue);
            } else {
                if (component.preferInterpretedValue) {
                    component.setNewValue(Math.max(component.paramInterpretedDefault - 1, component.paramMin));
                } else {
                    component.setNewValue(component.paramValue - 1);
                }
            }
            component.updateForcery += 1;
        }
    }
    QQC2.Label {
        id: paramLabel
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: component.paramValue === undefined || component.paramValue === component.paramDefault
            ? component.paramDefaultString
            : component.paramNames !== undefined && component.paramNames.hasOwnProperty(component.paramValue)
                ? component.paramNames[component.paramValue]
                : component.paramValuePrefix + component.paramValue + component.paramValueSuffix
        MultiPointTouchArea {
            anchors.fill: parent
            touchPoints: [
                TouchPoint {
                    id: slidePoint;
                    property var currentValue: undefined
                    onPressedChanged: {
                        if (pressed) {
                            currentValue = component.preferInterpretedValue ? component.paramInterpretedDefault : parseInt(component.paramValue);
                        } else {
                            currentValue = undefined;
                        }
                    }
                    onXChanged: {
                        if (pressed && currentValue !== undefined) {
                            var delta = Math.round((slidePoint.x - slidePoint.startX) * (component.scrollWidth / paramLabel.width));
                            component.setNewValue(Math.min(Math.max(currentValue + delta, component.paramMin), component.paramMax));
                        }
                    }
                }
            ]
        }
        Item {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: Kirigami.Units.largeSpacing
            Rectangle {
                anchors {
                    fill: parent
                    rightMargin: parent.width * ((component.paramMax - (component.preferInterpretedValue ? component.paramInterpretedDefault : component.paramValue)) / component.paramMax)
                }
                color: Kirigami.Theme.textColor
            }
        }
        Zynthian.KnobIndicator {
            anchors {
                left: parent.horizontalCenter
                leftMargin: -(parent.paintedWidth / 2) - width - Kirigami.Units.smallSpacing
                verticalCenter: parent.verticalCenter
            }
            height: component.height / 2
            width: height
            visible: component.currentlySelected
            knobId: component.knobId
        }
    }
    Zynthian.PlayGridButton {
        text: "+"
        Layout.preferredWidth: Kirigami.Units.gridUnit
        enabled: (component.preferInterpretedValue && component.paramInterpretedDefault < component.paramMax) || parseInt(component.paramValue) < component.paramMax
        onClicked: {
            if (component.paramList.length > 0) {
                var value = component.preferInterpretedValue ? component.paramInterpretedDefault : parseInt(component.paramValue);
                var newValue = component.paramMax;
                for (var i = 0; i < component.paramList.length; ++i) {
                    if (parseInt(component.paramList[i]) > value) {
                        newValue = parseInt(component.paramList[i]);
                        break;
                    }
                }
                component.setNewValue(newValue);
            } else {
                if (component.preferInterpretedValue) {
                    component.setNewValue(Math.min(component.paramMax, component.paramInterpretedDefault + 1));
                } else {
                    component.setNewValue(component.paramValue + 1);
                }
            }
            component.updateForcery += 1;
        }
    }
}
