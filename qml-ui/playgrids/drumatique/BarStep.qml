/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Base Grid Component 

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
    id:component
    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.bottomMargin: Kirigami.Units.smallSpacing
    property int availableBars
    property int activeBar
    property int playedBar
    property Item playgrid
    property int barStepIndex: index

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: barStepIndex === component.activeBar ? Kirigami.Theme.View : Kirigami.Theme.Button
    property color foregroundColor: Kirigami.Theme.backgroundColor
    property color backgroundColor: Kirigami.Theme.textColor
    property color borderColor: foregroundColor
    background: Rectangle {
        id:barStepRect
        anchors.fill:parent
        visible: component.barStepIndex < component.availableBars
        color: barStepIndex === component.activeBar ? Kirigami.Theme.focusColor: component.backgroundColor
        border {
            color: component.barStepIndex < component.availableBars ? component.borderColor : "transparent"
            width: 1
        }

        QQC2.Label {
            width:parent.width
            height:parent.height
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: component.barStepIndex + 1
            Kirigami.Theme.inherit: false
            color: component.foregroundColor
        }

        Rectangle {
            id:barStepIndicatorRect
            anchors {
                left: parent.left
                right: parent.right
                top: parent.bottom
                margins: 1
            }
            height:9
            color:  component.barStepIndex === component.playedBar ? "yellow" : "transparent"
        }
    }

    MultiPointTouchArea {
        anchors.fill: parent
        onPressed: {
            if (barStepIndex < component.availableBars){
                component.playgrid.setActiveBar(barStepIndex)
            }
        }
    }
}
