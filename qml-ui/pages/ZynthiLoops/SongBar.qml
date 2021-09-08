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

    Zynthian.ZynthiloopsDial {
        id: bpmDial
        text: qsTr("BPM")
        controlObj: root.bottomBar.controlObj
        controlProperty: "bpm"

        dial {
            stepSize: 1
            from: 50
            to: 200
        }
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
        Layout.leftMargin: 12
        visible: !root.bottomBar.controlObj.isTemp

        QQC2.Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Versions")
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 4
            border.color: Kirigami.Theme.highlightColor
            color: Kirigami.Theme.backgroundColor

            ListView {
                anchors.fill: parent
                model: root.bottomBar.controlObj.versions
                delegate: Kirigami.BasicListItem {
                    label: modelData
                    highlighted: root.bottomBar.controlObj.name === modelData
                    onClicked: {
                        zynthian.zynthiloops.loadSketchVersion(modelData)
                    }
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
    }
}

