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

import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

Item {
    id: multiSwitch

    activeFocusOnTab: true

    property alias text: valueLabel.text
    property alias multiSwitch: multiSwitch
    property QtObject controlObj
    property string controlProperty

    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1

    function increase() {
        multiSwitch.controlObj[multiSwitch.controlProperty] = Math.min(multiSwitch.to, Math.max(multiSwitch.from, multiSwitch.value + multiSwitch.stepSize));
    }
    function decrease() {
        multiSwitch.controlObj[multiSwitch.controlProperty] = Math.min(multiSwitch.to, Math.max(multiSwitch.from, multiSwitch.value - multiSwitch.stepSize));
    }

    Binding {
        target: multiSwitch
        property: "value"
        value: controlObj && controlObj.hasOwnProperty(multiSwitch.controlProperty) ? multiSwitch.controlObj[multiSwitch.controlProperty] : 1
    }

    Kirigami.Heading {
        id: valueLabel
        anchors.fill: parent
        text: multiSwitch.controlObj ? multiSwitch.controlObj[multiSwitch.controlProperty]:  ""
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    MouseArea {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.verticalCenter
        }
        onClicked: {
            multiSwitch.increase();
            multiSwitch.forceActiveFocus();
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            source: "arrow-up"
            isMask: true
            width: Kirigami.Units.iconSizes.smallMedium
            height: width
            opacity: parent.pressed ? 0.6 : (multiSwitch.value < multiSwitch.to ? 1 : 0.4)
        }
    }
    MouseArea {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.verticalCenter
            bottom: parent.bottom
        }
        onClicked: {
            multiSwitch.decrease();
            multiSwitch.forceActiveFocus();
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            source: "arrow-down"
            isMask: true
            width: Kirigami.Units.iconSizes.smallMedium
            height: width
            opacity: parent.pressed ? 0.6 : (multiSwitch.value > multiSwitch.from ? 1 : 0.4)
        }
    }
}

