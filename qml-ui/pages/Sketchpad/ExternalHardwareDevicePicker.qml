/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

External hardware device editor

Copyright (C) 2026 Dan Leinir Turthra Jensen <admin@leinir.dk>

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

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.7 as Kirigami

import io.zynthbox.ui 1.0 as ZUI
import io.zynthbox.components 1.0 as Zynthbox

ZUI.Popup {
    id: component
    function pickHardwareDevice(channel) {
        _private.selectedChannel = channel;
        deviceList.currentIndex = Zynthbox.MidiRouter.hardwareDevices.indexOf(channel.externalSettings.hardwareDevice);
        open();
    }
    signal requestDeviceEdit(QtObject device);

    parent: QQC2.Overlay.overlay
    y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
    x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
    width: Kirigami.Units.gridUnit * 50
    height: Kirigami.Units.gridUnit * 25
    closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

    property var cuiaCallback: function(cuia) {
        var returnValue = component.opened;
        switch (cuia) {
        case "SWITCH_BACK_RELEASED":
            component.close();
            returnValue = true;
            break;
        case "SWITCH_SELECT_RELEASED":
            // pick the currently selected channel and close
            component.close();
            returnValue = true;
            break;
        }
        return returnValue;
    }

    ColumnLayout {
        anchors.fill: parent
        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Kirigami.Units.gridUnit
            text: qsTr("Pick Hardware Device for Track %1").arg(_private.selectedChannel ? _private.selectedChannel.name : "")

            QtObject {
                id: _private
                property QtObject selectedChannel
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 1
            Layout.maximumHeight: 1
            color: Kirigami.Theme.textColor
            opacity: 0.5
        }
        ListView {
            id: deviceList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 22
            model: Zynthbox.MidiRouter.hardwareDevices
            delegate: ZUI.BasicDelegate {
                width: ListView.view.width
                height: Kirigami.Units.iconSizes.huge
                QQC2.Label {
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.smallSpacing
                    }
                    wrapMode: Text.Wrap
                    text: qsTr("Device name: %1\nBased on hardware ID: %2 which has known object: %3").arg(model.humanName).arg(model.hardwareId).arg(model.deviceObject)
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        _private.selectedChannel.externalSettings.hardwareDevice = model.deviceObject;
                        component.close();
                    }
                }
            }
            QQC2.Label {
                anchors.fill: parent
                visible: parent.count === 0
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("No Hardware Devices Yet\n\nCreate one below by selecting a known MIDI device\nin the drop-down and then clicking Create and Edit")
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            QQC2.Label {
                Layout.fillHeight: true
                text: qsTr("Select MIDI port for new device:")
            }
            ZUI.ComboBox {
                id: externalMidiOutPicker
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: true
                // function pickOutput(channel) {
                //     externalMidiOutPicker.channel = channel;
                //     for (let index = 0; index < Zynthbox.MidiRouter.model.midiOutSources.length; ++index) {
                //         let entry = Zynthbox.MidiRouter.model.midiOutSources[index];
                //         if (channel.externalSettings.midiOutDevice === "") {
                //             if (entry.value === "external:ttymidi:MIDI") {
                //                 externalMidiOutPicker.selectIndex(index);
                //                 break;
                //             }
                //         } else {
                //             if (entry.value === channel.externalSettings.midiOutDevice) {
                //                 externalMidiOutPicker.selectIndex(index);
                //                 break;
                //             }
                //         }
                //     }
                //     externalMidiOutPicker.onClicked();
                // }
                Component.onCompleted: {
                    // TODO Perhaps we should update the current selection here as we scroll through the list of existing devices...
                    externalMidiOutPicker.selectIndex(0);
                }
                model: Zynthbox.MidiRouter.model.midiOutSources
                textRole: "text"
            }
            QQC2.Button {
                Layout.fillHeight: true
                text: qsTr("Create and Edit")
                onClicked: {
                    let newDevice = Zynthbox.MidiRouter.hardwareDevices.createHardwareDeviceInstance(Zynthbox.MidiRouter.model.midiOutSources[externalMidiOutPicker.currentIndex].device);
                    _private.selectedChannel.externalSettings.hardwareDevice = newDevice;
                    component.close();
                    component.requestDeviceEdit(newDevice);
                }
            }
        }
    }
}
