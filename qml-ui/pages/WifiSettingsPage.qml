/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI
A Page for displaying and configuring wifi connections

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>

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
import "ZynthiLoops" as ZynthiLoops

Zynthian.ScreenPage {
    id: root
    title: qsTr("Wifi Settings")
    screenId: "wifi_settings"
    
    Connections {
        target: zynthian
        onCurrent_screen_idChanged: {
            if (zynthian.current_screen_id === root.screenId) {
                // Reload wifi list
                zynthian.wifi_settings.reloadLists()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        radius: 2

        QQC2.Dialog {
            id: connectDialog

            property string ssid

            x: root.width / 2 - width / 2
            y: root.height / 2 - height / 2
            dim: true
            modal: true
            width: Math.round(Math.max(implicitWidth, root.width * 0.4))
            height: Math.round(Math.max(implicitHeight, root.height * 0.4))
            closePolicy: QQC2.Popup.CloseOnPressOutside
            header: ColumnLayout {
                Kirigami.Heading {
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.gridUnit
                    text: qsTr("Connect to %1").arg(connectDialog.ssid)
                }
                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: 2
                }
            }
            footer: RowLayout {
                anchors.margins: Kirigami.Units.gridUnit
                spacing: Kirigami.Units.gridUnit

                QQC2.Button {
                    text: qsTr("Connect")
                    Layout.alignment: Qt.AlignRight
                    onClicked: {
                        zynthian.wifi_settings.connect(connectDialog.ssid, passwordField.text)
                    }
                }
            }
            contentItem: Item {
                QQC2.TextField {
                    id: passwordField

                    width: connectDialog.width * 0.7
                    height: Kirigami.Units.gridUnit * 2
                    anchors.centerIn: parent
                    placeholderText: "Password"
                    echoMode: "Password"
                }
            }
        }

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
                    text: qsTr("Wifi")
                }

                QQC2.Switch {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit*4
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
                    checked: zynthian.wifi_settings.wifiMode === "on"
                    onToggled: {
                        if (checked) {
                            zynthian.wifi_settings.wifiMode = "on"
                        } else {
                            zynthian.wifi_settings.wifiMode = "off"
                        }
                    }
                }
            }

            RowLayout {
                Layout.preferredHeight: Kirigami.Units.gridUnit*2.5

                QQC2.Label {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit*8
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
                    Layout.leftMargin: Kirigami.Units.gridUnit
                    horizontalAlignment: TextInput.AlignLeft
                    text: qsTr("Wifi Hotspot")
                }

                QQC2.Switch {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit*4
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
                    checked: zynthian.wifi_settings.wifiMode === "hotspot"
                    onToggled: {
                        if (checked) {
                            zynthian.wifi_settings.wifiMode = "hotspot"
                        } else {
                            zynthian.wifi_settings.wifiMode = "off"
                        }
                    }
                }
            }

            RowLayout {
                Layout.preferredHeight: Kirigami.Units.gridUnit*2.5

                QQC2.Label {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit*8
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
                    Layout.leftMargin: Kirigami.Units.gridUnit
                    horizontalAlignment: TextInput.AlignLeft
                    text: qsTr("Available Networks")
                }

                QQC2.ComboBox {
                    id: availableNetworksDropdown
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit*12
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
                    model: zynthian.wifi_settings.availableWifiNetworks
                    textRole: "ssid"
                }

                QQC2.Button {
                    Layout.preferredWidth: Kirigami.Units.gridUnit*6
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
                    text: qsTr("Connect")
                    enabled: availableNetworksDropdown.currentText.trim().length > 0
                    onClicked: {
                        connectDialog.ssid = availableNetworksDropdown.currentText
                        connectDialog.open()
                    }
                }
            }

            RowLayout {
                Layout.preferredHeight: Kirigami.Units.gridUnit*2.5
                visible: zynthian.wifi_settings.wifiMode === "on"

                QQC2.Label {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit*8
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
                    Layout.leftMargin: Kirigami.Units.gridUnit
                    horizontalAlignment: TextInput.AlignLeft
                    text: qsTr("Saved Networks")
                }

                QQC2.ComboBox {
                    id: savedNetworksDropdown
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit*12
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
                    model: zynthian.wifi_settings.savedWifiNetworks
                    textRole: "ssid"
                }
            }
        }
    }
}
