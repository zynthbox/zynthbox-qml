/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Component used for managing bluetooth audio connections

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
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import org.kde.bluezqt 1.0 as BluezQt

Item {
    id: component
    readonly property QtObject connectedDevice: _private.connectedDevice
    function show() {
        component.visible = true;
    }
    function hide() {
        component.visible = false;
    }
    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
    }
    MouseArea {
        anchors.fill: parent
        onClicked: { /* swallow tappy stuff to stop people tapping what's underneath */ }
    }
    QtObject {
        id: _private
        property QtObject manager: BluezQt.Manager
        property QtObject usableAdapter: _private.manager.usableAdapter
        property QtObject connectedDevice: null
    }
    Connections {
        target: _private.manager
        onInitFinished: {
            // If we've got any devices connected at startup, let's make sure we also connect it to our ports
            var devices = _private.manager.devices;
            for (var i = 0; i < devices.length; ++i) {
                var device = devices[i];
                if (device.connected) {
                    _private.connectedDevice = device;
                    zynthian.bluetooth_config.connectBluetoothPorts();
                    break;
                }
            }
        }
    }
    Connections {
        target: _private.connectedDevice
        onConnectedChanged: {
            if (_private.connectedDevice.connected === false) {
                _private.connectedDevice = null;
            }
        }
    }
    onVisibleChanged: {
        if (component.visible && _private.usableAdapter !== null && deviceList.count === 0) {
            _private.usableAdapter.startDiscovery();
        }
    }

    ColumnLayout {
        anchors.fill: parent;
        RowLayout {
            Layout.fillWidth: true
            QQC2.Button {
                Layout.fillWidth: true
                icon.name: "draw-arrow-back"
                onClicked: {
                    component.visible = false;
                }
            }
            Kirigami.Heading {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: qsTr("Pick A Bluetooth Device")
            }
        }
        ListView {
            id: deviceList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: BluezQt.DevicesModel { }
            delegate: QQC2.ItemDelegate {
                id: btDeviceDelegate
                width: ListView.view.width
                height: Kirigami.Units.gridUnit * 2
                property QtObject device: _private.manager.deviceForUbi(model.Ubi);
                Connections {
                    target: btDeviceDelegate.device
                    onConnectedChanged: {
                        if (btDeviceDelegate.device.connected) {
                            _private.connectedDevice = btDeviceDelegate.device;
                            zynthian.bluetooth_config.connectBluetoothPorts();
                        }
                    }
                }
                property QtObject pendingCall: null
                Connections {
                    target: btDeviceDelegate.pendingCall
                    onFinished: {
                        if (pendingCall === btDeviceDelegate.pendingCall) {
                            btDeviceDelegate.pendingCall = null;
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        deviceList.currentIndex = model.index
                    }
                }
                RowLayout {
                    anchors {
                        fill: parent;
                        margins: 2;
                    }
                    Kirigami.Icon {
                        Layout.fillHeight: true
                        Layout.minimumWidth: height
                        Layout.maximumWidth: height
                        source: model.Icon
                        Kirigami.Icon {
                            anchors {
                                top: parent.top
                                right: parent.right
                            }
                            width: parent.width / 3
                            height: width
                            source: "emblem-checked"
                            visible: model.Connected
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: model.Name
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: model.Address
                            font.pointSize: 6
                        }
                    }
                }
                QQC2.Button {
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        margins: 2
                    }
                    visible: btDeviceDelegate.ListView.isCurrentItem
                    enabled: btDeviceDelegate.pendingCall === null
                    text: btDeviceDelegate.pendingCall === null
                        ? (model.Connected ? qsTr("Disconnect") : qsTr("Connect"))
                        : qsTr("Working...")
                    onClicked: {
                        if (_private.usableAdapter.discovering) {
                            _private.usableAdapter.stopDiscovery();
                        }
                        if (btDeviceDelegate.device.connected) {
                            btDeviceDelegate.pendingCall = btDeviceDelegate.device.disconnectFromDevice();
                        } else {
                            if (!btDeviceDelegate.device.paired) {
                                console.log("Device not paired. Pairing first and then connecting.")
                                var pairPendingCall = btDeviceDelegate.device.pair()
                                pairPendingCall.finished.connect(function() {
                                    console.log("Pair pending call finished :", pairPendingCall.errorText)
                                    btDeviceDelegate.pendingCall = btDeviceDelegate.device.connectToDevice();
                                })
                            } else {
                                console.log("Device already paired. Connecting.")
                                btDeviceDelegate.pendingCall = btDeviceDelegate.device.connectToDevice();
                            }
                        }
                    }
                    QQC2.BusyIndicator {
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            right: parent.left
                            rightMargin: Kirigami.Units.smallSpacing
                        }
                        width: height
                        visible: btDeviceDelegate.pendingCall !== null
                        running: visible
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: btDeviceDelegate.ListView.isCurrentItem ? Qt.rgba(255, 255, 255, 0.8) : "transparent"
                    radius: 4
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            QQC2.Button {
                text: _private.usableAdapter && _private.usableAdapter.discovering ? qsTr("Stop Scan") : qsTr("Start Scan")
                enabled: _private.manager.bluetoothOperational
                Timer {
                    id: btScanTimeout
                    interval: 30000; running: false; repeat: false;
                    onTriggered: {
                        if (_private.usableAdapter.discovering) {
                            _private.usableAdapter.stopDiscovery();
                        }
                    }
                }
                Connections {
                    target: _private.usableAdapter
                    onDiscoveringChanged: {
                        if (_private.usableAdapter.discovering) {
                            btScanTimeout.restart();
                        } else {
                            btScanTimeout.stop();
                        }
                    }
                }
                onClicked: {
                    if (_private.usableAdapter.discovering) {
                        _private.usableAdapter.stopDiscovery();
                    } else {
                        _private.usableAdapter.startDiscovery();
                    }
                }
            }
            QQC2.BusyIndicator {
                running: _private.manager.bluetoothOperational ? _private.usableAdapter.discovering : false
            }
        }
    }
}
