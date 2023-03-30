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
import QtQuick.Window 2.10
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

Zynthian.ScreenPage {
    id: root
    title: "Network Info"
    screenId: "network_info"

    property var networkInfo: ({})

    Connections {
        target: zynqtgui
        onCurrent_screen_idChanged: {
            if (zynqtgui.current_screen_id === root.screenId) {
                console.log(JSON.stringify(zynqtgui.network.getNetworkInfo(), null, 2))
                root.networkInfo = zynqtgui.network.getNetworkInfo()
                console.log(Object.keys(root.networkInfo))
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        radius: 2

        ColumnLayout {
            anchors.margins: Kirigami.Units.gridUnit
            RowLayout {
                Layout.preferredHeight: Kirigami.Units.gridUnit*2.5

                QQC2.Label {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit*8
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
                    Layout.leftMargin: Kirigami.Units.gridUnit
                    horizontalAlignment: TextInput.AlignLeft
                    text: qsTr("Hostname")
                }

                QQC2.TextField {
                    id: hostname
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit*12
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
                    horizontalAlignment: TextInput.AlignHCenter
                    text: zynqtgui.network.getHostname()
                }

                QQC2.Button {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit*4
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
                    enabled: hostname.text !== zynqtgui.network.getHostname()
                    text: qsTr("Update")
                    onClicked: {
                        zynqtgui.network.setHostname(hostname.text)
                        hostname.text = zynqtgui.network.getHostname()
                    }
                }
            }

            Repeater {
                model: Object.keys(root.networkInfo)
                delegate: RowLayout {
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2.5
                    visible: modelData !== "Link-Local Name"

                    QQC2.Label {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: Kirigami.Units.gridUnit*8
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        Layout.leftMargin: Kirigami.Units.gridUnit
                        horizontalAlignment: TextInput.AlignLeft
                        text: modelData
                    }

                    QQC2.TextField {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: Kirigami.Units.gridUnit*12
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        horizontalAlignment: TextInput.AlignHCenter
                        readOnly: true
                        text: root.networkInfo[modelData][0]
                    }
                }
            }
        }
    }
}
