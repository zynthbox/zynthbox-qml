/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Marco MArtin <mart@kde.org>

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

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian

// GridLayout so TabbedControlView knows how to navigate it
GridLayout {
    id: root
    rows: 1
    Layout.fillWidth: true

    property QtObject bottomBar: null

    SidebarDial {
        id: startDial
        text: qsTr("Start (msecs)")
        controlObj: root.bottomBar.controlObj
        controlProperty: "startPosition"
        valueString: Math.round(dial.value * 1000)

        dial {
            stepSize: 0.001
            from: 0
            to: controlObj && controlObj.hasOwnProperty("duration") ? controlObj.duration : 0
        }
    }

    SidebarDial {
        id: lengthDial
        text: qsTr("Length (beats)")
        controlObj: root.bottomBar.controlObj
        controlProperty: "length"

        dial {
            stepSize: 1
            from: 1
            to: 16
        }
    }

    SidebarDial {
        id: pitchDial
        text: qsTr("Pitch")
        controlObj: root.bottomBar.controlObj
        controlProperty: "pitch"

        dial {
            stepSize: 1
            from: -12
            to: 12
        }
    }

    SidebarDial {
        id: timeDial
        text: qsTr("Time")
        controlObj: root.bottomBar.controlObj
        controlProperty: "time"

        dial {
            stepSize: 0.1
            from: 0.5
            to: 2
        }
    }

    Item {
        Layout.fillWidth: true
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignRight | Qt.AlignBottom
        QQC2.Label {
            Layout.alignment: Qt.AlignRight
            visible: root.bottomBar.controlType === BottomBar.ControlType.Clip && controlObj.path.length > 0
            text: qsTr("Duration: %1 secs").arg(controlObj && controlObj.duration ? controlObj.duration.toFixed(2) : 0.0)
        }
        QQC2.Label {
            Layout.alignment: Qt.AlignRight
            visible: root.bottomBar.controlType === BottomBar.ControlType.Clip
            text: {
                if (!controlObj || !controlObj.path) {
                    return qsTr("No File Loaded");
                }
                var arr = controlObj.path.split('/');
                return qsTr("File: %1").arg(arr[arr.length - 1]);
            }
        }
    }
}

