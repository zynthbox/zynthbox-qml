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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents

//NOTE: this is due to a bug in Kirigami.AbstractCard from Buster's version
Rectangle {
    id: root
    property bool open: zynqtgui.is_loading

    z: 999999
    color: Qt.rgba(0, 0,0, 0.8)

    PlasmaComponents.BusyIndicator {
        anchors.centerIn: parent
        visible: root.open
        width: Kirigami.Units.gridUnit * 3
        height: width
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {
            print("Overlay blocking clicks")
        }
    }

    states: [
        State {
            name: "visible"
            when: root.open
            PropertyChanges {
                target: root
                opacity: 1
                visible: true
            }
        },
        State {
            name: "hidden"
            when: !root.open
            PropertyChanges {
                target: root
                opacity: 0
            }
        }
    ]
    transitions: Transition {
        SequentialAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
            ScriptAction {
                script: root.visible = root.open
            }
        }
    }
}
