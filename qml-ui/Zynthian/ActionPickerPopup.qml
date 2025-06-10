/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Action Picker Popup, shows a list of actions in a finger-friendly manner

Copyright (C) 2023 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import Zynthian 1.0 as Zynthian

Zynthian.Popup {
    id: component

    property list<QQC2.Action> actions
    property int rows: 3
    property int columns: Math.ceil(component.actions.length / 3) // Auto calculate columns if not provided
    property alias currentIndex: _private.currentIndex

    property var cuiaCallback: function(cuia) {
        var result = component.opened;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
                component.close();
                result = true;
                break;
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
                let theIndex = _private.currentIndex;
                if (theIndex > -1 && component.actions[theIndex].enabled) {
                    component.close();
                    component.actions[theIndex].trigger();
                }
                result = true;
                break;
            case "SELECT_DOWN":
            case "KNOB3_UP":
                while (true) {
                    _private.currentIndex = (_private.currentIndex + 1 === component.actions.length) ? 0 : _private.currentIndex + 1;
                    if (component.actions[_private.currentIndex].enabled) {
                        break;
                    }
                }
                result = true;
                break;
            case "SELECT_UP":
            case "KNOB3_DOWN":
                while (true) {
                    _private.currentIndex = (_private.currentIndex === 0) ? component.actions.length - 1 : _private.currentIndex - 1;
                    if (component.actions[_private.currentIndex].enabled) {
                        break;
                    }
                }
                result = true;
                break;
            case "NAVIGATE_LEFT":
                // When navigating left, decrement by row number. If index goes negetive then deduct it from length to rollover to otherside
                _private.currentIndex = (_private.currentIndex - component.rows) < 0 ? component.actions.length + (_private.currentIndex - component.rows) : _private.currentIndex - component.rows
                result = true;
                break;
            case "NAVIGATE_RIGHT":
                // When navigating right, increment by row number. If index exceeds length then modulo it by length to rollover to other side
                _private.currentIndex = (_private.currentIndex + component.rows) % component.actions.length
                result = true;
                break;
            case "KNOB0_UP":
            case "KNOB0_DOWN":
            case "KNOB1_UP":
            case "KNOB1_DOWN":
            case "KNOB2_UP":
            case "KNOB2_DOWN":
            default:
                result = true;
                break;
        }
        return result;
    }

    parent: QQC2.Overlay.overlay
    y: parent !== null ? parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y : 0
    x: parent !== null ? parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x : 0
    width: mainLayout.implicitWidth + mainLayout.columnSpacing*2
    height: mainLayout.implicitHeight + mainLayout.rowSpacing*2

    Connections {
        target: component
        onOpenedChanged: {
            _private.currentIndex = -1;
        }
    }
    QtObject {
        id: _private
        property int currentIndex: -1
    }
    GridLayout {
        id: mainLayout
        anchors.fill: parent
        rowSpacing: Kirigami.Units.largeSpacing
        columnSpacing: Kirigami.Units.largeSpacing
        columns: component.columns
        rows: component.rows
        flow: GridLayout.TopToBottom
        Repeater {
            model: component.actions
            delegate: PlayGridButton {
                id: delegate
                Layout.minimumWidth: Kirigami.Units.gridUnit * 12
                Layout.minimumHeight: Kirigami.Units.gridUnit * 4
                Layout.maximumWidth: Kirigami.Units.gridUnit * 12
                Layout.maximumHeight: Kirigami.Units.gridUnit * 4
                Layout.alignment: Qt.AlignCenter
                text: modelData != null && modelData.hasOwnProperty("text") ? modelData.text : ""
                visible: modelData != null && modelData.hasOwnProperty("visible") ? modelData.visible : true
                enabled: modelData != null && modelData.hasOwnProperty("enabled") ? modelData.enabled : true
                invertBorderColor: true
                opacity: enabled ? 1 : 0.3
                onClicked: {
                    component.close();
                    modelData.trigger();
                }
                Rectangle {
                    anchors {
                        fill: parent
                        margins: -5
                    }
                    color: "transparent"
                    border {
                        width: 2
                        color: Kirigami.Theme.textColor
                    }
                    opacity: _private.currentIndex === index ? 0.7 : 0
                }
            }
        }
    }
}
