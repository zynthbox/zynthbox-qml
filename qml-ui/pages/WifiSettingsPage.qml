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

import io.zynthbox.ui 1.0 as ZUI
import io.zynthbox.ui2 1.0 as ZUI2

import "Sketchpad" as Sketchpad

ZUI2.ScreenPage {
    id: root

    signal openCaptivePortal(string url)

    function getWifiIconNameByQuality(quality) {
        let iconName = "network-wireless-signal-%1-symbolic"
        if (quality < 0) {
            iconName = "network-wireless-disconnected-symbolic"
        } else if (quality >= 0 && quality <= 20) {
            iconName = qsTr(iconName).arg("none")
        } else if (quality > 20 && quality <= 40) {
            iconName = qsTr(iconName).arg("weak")
        } else if (quality > 40 && quality <= 60) {
            iconName = qsTr(iconName).arg("ok")
        } else if (quality > 60 && quality <= 80) {
            iconName = qsTr(iconName).arg("good")
        } else if (quality > 80) {
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
        },
        Kirigami.Action {
            text: qsTr("Disconnect")
            visible: zynqtgui.wifi_settings.wifiMode == "on"
            onTriggered: {
                zynqtgui.wifi_settings.wifiMode = "off"
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
                zynqtgui.wifi_settings.reloadLists();
            }
        }
    }

    ZUI2.Dialog {
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
                    zynqtgui.wifi_settings.connectNewNetwork(connectDialog.ssid, passwordField.text)
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
                    Layout.fillWidth: false
                    Layout.fillHeight: false
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
                            return qsTr("Connected to %1").arg(zynqtgui.wifi_settings.connectedNetworkSsid)
                        } else if (zynqtgui.wifi_settings.wifiMode == "off") {
                            return qsTr("Disconnected")
                        } else {
                            return qsTr("Unknown")
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: false
                Layout.fillHeight: false
                Layout.preferredWidth: Kirigami.Units.gridUnit * 16

                QQC2.Label {
                    Layout.fillWidth: false
                    Layout.fillHeight: false
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    horizontalAlignment: Qt.AlignHCenter
                    text: qsTr("IP")
                }

                QQC2.TextField {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: Qt.AlignHCenter
                    readOnly: true
                    text: zynqtgui.wifi_settings.connectedNetworkIp
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                Layout.fillWidth: false
                Layout.fillHeight: false
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                horizontalAlignment: Qt.AlignHCenter
                text: qsTr("Country")
            }

            ZUI2.ComboBox {
                id: countryCodesCombo
                Layout.fillWidth: false
                Layout.fillHeight: false
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                Layout.alignment: Qt.AlignVCenter
                currentIndex: zynqtgui.wifi_settings.selectedCountryDetail.index
                model: zynqtgui.wifi_settings.countryDetailsModel
                textRole: "countryName"
                onActivated: {
                    zynqtgui.wifi_settings.selectedCountryDetail = countryCodesCombo.model[index]
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

            ZUI2.SelectorView {
                id: availableNetworksListView
                anchors.fill: parent
                qmlSelector: ZUI.SelectorWrapper {
                    selector_list: zynqtgui.wifi_settings.availableWifiNetworksModel
                    current_index: -1
                }
                delegate: QQC2.ItemDelegate {
                    id: availableNetworkDelegate
                    width: ListView.view.width - Kirigami.Units.largeSpacing
                    height: Kirigami.Units.gridUnit * 2
                    highlighted: false
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
                            source: root.getWifiIconNameByQuality(modelData.quality)
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
                                connectDialog.ssid = modelData.ssid
                                connectDialog.open()
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

            ZUI2.SelectorView {
                id: savedNetworksListView
                anchors.fill: parent
                qmlSelector: ZUI.SelectorWrapper {
                    selector_list: zynqtgui.wifi_settings.savedWifiNetworksModel
                    current_index: -1
                }
                delegate: QQC2.ItemDelegate {
                    id: savedNetworkDelegate
                    width: ListView.view.width - Kirigami.Units.largeSpacing
                    height: Kirigami.Units.gridUnit * 2
                    highlighted: false
                    contentItem: RowLayout {
                        QQC2.Label {
                            Layout.fillWidth: false
                            Layout.fillHeight: false
                            Layout.alignment: Qt.AlignCenter
                            opacity: modelData.quality < 0 ? 0.7 : 1
                            text: "%1 -".arg(index + 1)
                        }
                        Kirigami.Icon {
                            Layout.fillWidth: false
                            Layout.fillHeight: true
                            Layout.preferredWidth: height
                            Layout.leftMargin: 2
                            Layout.rightMargin: 2
                            opacity: modelData.quality < 0 ? 0.7 : 1
                            source: root.getWifiIconNameByQuality(modelData.quality)
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.alignment: Qt.AlignCenter
                            opacity: modelData.quality < 0 ? 0.7 : 1
                            text: modelData.ssid
                        }
                        QQC2.Button {
                            Layout.fillHeight: true
                            Layout.preferredWidth: height * 2
                            icon.name: "delete-symbolic"
                            onClicked: {
                                zynqtgui.wifi_settings.removeSavedNetwork(modelData.ssid)
                            }
                        }
                        QQC2.Button {
                            Layout.fillHeight: true
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                            text: zynqtgui.wifi_settings.wifiMode == "on" && zynqtgui.wifi_settings.connectedNetworkSsid == modelData.ssid ? qsTr("Disconnect") : qsTr("Connect")
                            onClicked: {
                                if (zynqtgui.wifi_settings.wifiMode == "on" && zynqtgui.wifi_settings.connectedNetworkSsid == modelData.ssid) {
                                    zynqtgui.wifi_settings.wifiMode = "off"
                                } else {
                                    zynqtgui.wifi_settings.connectSavedNetwork(modelData.ssid)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
