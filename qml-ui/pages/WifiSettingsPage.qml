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
import "Sketchpad" as Sketchpad

Zynthian.ScreenPage {
    id: root

    signal openCaptivePortal(string url)

    function getWifiIconNameBySignalStrength(signalStrength) {
        let iconName = "network-wireless-signal-%1-symbolic"
        if (signalStrength <= 20) {
            iconName = qsTr(iconName).arg("none")
        } else if (signalStrength > 20 && signalStrength <= 40) {
            iconName = qsTr(iconName).arg("weak")
        } else if (signalStrength > 40 && signalStrength <= 60) {
            iconName = qsTr(iconName).arg("ok")
        } else if (signalStrength > 60 && signalStrength <= 80) {
            iconName = qsTr(iconName).arg("good")
        } else if (signalStrength > 80) {
            iconName = qsTr(iconName).arg("excellent")
        } else {
            iconName = qsTr(iconName).arg("none")
        }
        return iconName;
    }

    title: qsTr("Wifi Settings")
    screenId: "wifi_settings"    
    contextualActions: [
        Kirigami.Action {
            text: qsTr("Refresh")
            onTriggered: {
                zynqtgui.wifi_settings.reloadLists()
            }
        }
    ]
    Component.onCompleted: {
        zynqtgui.wifi_settings.openCaptivePortal.connect(root.openCaptivePortal)
    }
    onOpenCaptivePortal: {
        console.log("### WifiCheck : opening captive portal")
        applicationWindow().showPassiveNotification("Opening Captive Portal")
    }

    Connections {
        target: zynqtgui
        onCurrent_screen_idChanged: {
            if (zynqtgui.current_screen_id === root.screenId) {
                // Reload wifi list
                zynqtgui.wifi_settings.reloadLists()
            }
        }
    }

    Zynthian.Dialog {
        id: connectDialog

        property string ssid

        x: root.width / 2 - width / 2
        y: root.height / 2 - height / 2
        dim: true
        modal: true
        width: Math.round(Math.max(implicitWidth, root.width * 0.4))
        height: Math.round(Math.max(implicitHeight, root.height * 0.4))
        closePolicy: QQC2.Popup.CloseOnPressOutside
        onClosed: {
            passwordField.text = ""
        }
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
                    zynqtgui.wifi_settings.connect(connectDialog.ssid, passwordField.text)
                    connectDialog.close()
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

//            RowLayout {
//                Layout.preferredHeight: Kirigami.Units.gridUnit*2.5

//                QQC2.Label {
//                    Layout.alignment: Qt.AlignVCenter
//                    Layout.preferredWidth: Kirigami.Units.gridUnit*8
//                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
//                    Layout.leftMargin: Kirigami.Units.gridUnit
//                    horizontalAlignment: TextInput.AlignLeft
//                    text: qsTr("Wifi")
//                }

//                QQC2.Switch {
//                    Layout.alignment: Qt.AlignVCenter
//                    Layout.preferredWidth: Kirigami.Units.gridUnit*4
//                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
//                    checked: zynqtgui.wifi_settings.wifiMode === "on"
//                    onToggled: {
//                        if (checked) {
//                            zynqtgui.wifi_settings.wifiMode = "on"
//                        } else {
//                            zynqtgui.wifi_settings.wifiMode = "off"
//                        }
//                    }
//                }
//            }

//            RowLayout {
//                Layout.preferredHeight: Kirigami.Units.gridUnit*2.5

//                QQC2.Label {
//                    Layout.alignment: Qt.AlignVCenter
//                    Layout.preferredWidth: Kirigami.Units.gridUnit*8
//                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
//                    Layout.leftMargin: Kirigami.Units.gridUnit
//                    horizontalAlignment: TextInput.AlignLeft
//                    text: qsTr("Wifi")
//                }

//                QQC2.ComboBox {
//                    id: wifiModeDropdown
//                    Layout.alignment: Qt.AlignVCenter
//                    Layout.preferredWidth: Kirigami.Units.gridUnit*12
//                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
//                    model: ["off", /*"hotspot",*/ "on"]
//                    currentIndex: find(zynqtgui.wifi_settings.wifiMode)
//                    onActivated: {
//                        zynqtgui.wifi_settings.wifiMode = wifiModeDropdown.model[wifiModeDropdown.currentIndex]
//                    }
//                }
//            }

//            RowLayout {
//                Layout.preferredHeight: Kirigami.Units.gridUnit*2.5

//                QQC2.Label {
//                    Layout.alignment: Qt.AlignVCenter
//                    Layout.preferredWidth: Kirigami.Units.gridUnit*8
//                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
//                    Layout.leftMargin: Kirigami.Units.gridUnit
//                    horizontalAlignment: TextInput.AlignLeft
//                    text: qsTr("Available Networks")
//                }

//                QQC2.ComboBox {
//                    id: availableNetworksDropdown
//                    Layout.alignment: Qt.AlignVCenter
//                    Layout.preferredWidth: Kirigami.Units.gridUnit*12
//                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
//                    model: zynqtgui.wifi_settings.availableWifiNetworks
//                    textRole: "ssid"
//                }

//                QQC2.Button {
//                    Layout.preferredWidth: Kirigami.Units.gridUnit*6
//                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
//                    text: qsTr("Connect")
//                    enabled: availableNetworksDropdown.currentText.trim().length > 0
//                    onClicked: {
//                        connectDialog.ssid = availableNetworksDropdown.currentText
//                        connectDialog.open()
//                    }
//                }
//            }

//            RowLayout {
//                Layout.preferredHeight: Kirigami.Units.gridUnit*2.5
//                visible: zynqtgui.wifi_settings.wifiMode === "on"

//                QQC2.Label {
//                    Layout.alignment: Qt.AlignVCenter
//                    Layout.preferredWidth: Kirigami.Units.gridUnit*8
//                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
//                    Layout.leftMargin: Kirigami.Units.gridUnit
//                    horizontalAlignment: TextInput.AlignLeft
//                    text: qsTr("Saved Networks")
//                }

//                QQC2.ComboBox {
//                    id: savedNetworksDropdown
//                    Layout.alignment: Qt.AlignVCenter
//                    Layout.preferredWidth: Kirigami.Units.gridUnit*12
//                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
//                    model: zynqtgui.wifi_settings.savedWifiNetworks
//                    textRole: "ssid"
//                }

//                QQC2.Button {
//                    Layout.preferredWidth: Kirigami.Units.gridUnit*6
//                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
//                    text: qsTr("Remove")
//                    visible: zynqtgui.wifi_settings.savedWifiNetworks.length > 0
//                    onClicked: {
//                        zynqtgui.wifi_settings.remove_network(savedNetworksDropdown.model[savedNetworksDropdown.currentIndex].ssid)
//                        zynqtgui.wifi_settings.reloadLists()
//                    }
//                }
//            }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false

                QQC2.Label {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    horizontalAlignment: Qt.AlignHCenter
                    text: qsTr("Status")
                }

                QQC2.TextField {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    Layout.alignment: Qt.AlignVCenter
                    readOnly: true
                    text: {
                        if (zynqtgui.wifi_settings.wifiMode == "on") {
                            return qsTr("Connected")
                        } else if (zynqtgui.wifi_settings.wifiMode == "off") {
                            return qsTr("Disconnected")
                        } else {
                            return qsTr("Unknown")
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false

                QQC2.Label {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    horizontalAlignment: Qt.AlignHCenter
                    text: qsTr("IP")
                }

                QQC2.TextField {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    Layout.alignment: Qt.AlignVCenter
                    readOnly: true
                    text: qsTr("192.168.0.0")
                }
            }
        }

        Item { // Spacer
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.preferredHeight: Kirigami.Units.largeSpacing
        }

        QQC2.Label {
            Layout.fillWidth: false
            Layout.fillHeight: false
            text: qsTr("Available Networks")
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 1
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Zynthian.SelectorView {
                id: availableNetworksListView
                anchors.fill: parent
                qmlSelector: Zynthian.SelectorWrapper {
                    selector_list: zynqtgui.wifi_settings.availableWifiNetworks
                }
                delegate: QQC2.ItemDelegate {
                    id: availableNetworkDelegate
                    width: ListView.view.width - Kirigami.Units.largeSpacing
                    height: Kirigami.Units.gridUnit * 2
                    contentItem: RowLayout {
                        QQC2.Label {
                            Layout.fillWidth: false
                            Layout.fillHeight: false
                            Layout.alignment: Qt.AlignCenter
                            text: "%1 -".arg(index + 1)
                        }
                        Kirigami.Icon {
                            Layout.fillWidth: false
                            Layout.fillHeight: true
                            Layout.preferredWidth: height
                            Layout.leftMargin: 2
                            Layout.rightMargin: 2
                            source: root.getWifiIconNameBySignalStrength(modelData.quality)
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.alignment: Qt.AlignCenter
                            text: modelData.ssid
                        }
                        QQC2.Button {
                            Layout.fillWidth: false
                            Layout.fillHeight: true
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                            text: qsTr("Connect")
                            onClicked: {
                                // TODO Connect to new available network
                            }
                        }
                    }
                }
            }
        }

        Item { // Spacer
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.preferredHeight: Kirigami.Units.largeSpacing
        }

        QQC2.Label {
            Layout.fillWidth: false
            Layout.fillHeight: false
            text: qsTr("Saved Networks")
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 1
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Zynthian.SelectorView {
                id: savedNetworksListView
                anchors.fill: parent
                qmlSelector: Zynthian.SelectorWrapper {
                    selector_list: zynqtgui.wifi_settings.savedWifiNetworks
                }
                delegate: QQC2.ItemDelegate {
                    id: savedNetworkDelegate
                    width: ListView.view.width - Kirigami.Units.largeSpacing
                    height: Kirigami.Units.gridUnit * 2
                    contentItem: RowLayout {
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.alignment: Qt.AlignCenter
                            text: qsTr("%1 - %2").arg(index + 1).arg(modelData.ssid)
                            elide: Text.ElideRight
                        }
                        QQC2.Button {
                            Layout.fillHeight: true
                            Layout.preferredWidth: height * 2
                            icon.name: "delete-symbolic"
                            onClicked: {
                                zynqtgui.wifi_settings.remove_network(modelData.ssid)
                            }
                        }
                        QQC2.Button {
                            Layout.fillHeight: true
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                            text: qsTr("Connect")
                            onClicked: {
                                // TODO Connect to saved network
                            }
                        }
                    }
                }
            }
        }
    }
}
