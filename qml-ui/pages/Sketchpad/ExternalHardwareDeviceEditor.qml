/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

External hardware device picker

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
import org.kde.kirigami 2.6 as Kirigami

import io.zynthbox.ui 1.0 as ZUI
import io.zynthbox.components 1.0 as Zynthbox

ZUI.DialogQuestion {
    id: component
    function editHardwareDevice(hardwareDevice) {
        _private.hardwareDevice = hardwareDevice;
        deviceNameField.text = hardwareDevice.name;
        deviceMidiChannelField.value = hardwareDevice.lowestMidiChannel;
        deviceBankMaxField.value = hardwareDevice.bankMax;
        deviceProgramMaxField.value = hardwareDevice.programMax;
        deviceValuesStartAtOneField.checked = hardwareDevice.valuesStartAtOne;
        open();
    }


    property var cuiaCallback: function(cuia) {
        var returnValue = root.opened;
        switch (cuia) {
        case "KNOB3_UP":
            returnValue = true;
            break;
        case "KNOB3_DOWN":
            returnValue = true;
            break;
        case "SWITCH_BACK_RELEASED":
            root.reject();
            returnValue = true;
            break;
        case "SWITCH_SELECT_RELEASED":
            root.accept();
            returnValue = true;
            break;
        }
        return returnValue;
    }
    rejectText: ""
    acceptText: qsTr("Close")
    title: qsTr("Editing Hardware Device %1").arg(_private.hardwareDevice ? _private.hardwareDevice.name : "(no device)")
    width: Kirigami.Units.gridUnit * 30
    height: Kirigami.Units.gridUnit * 30

    contentItem: Kirigami.FormLayout {
        QtObject {
            id: _private
            property QtObject hardwareDevice
        }
        QQC2.TextField {
            id: deviceNameField
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            Kirigami.FormData.label: qsTr("Device Name:")
            onTextChanged: {
                if (_private.hardwareDevice.name != deviceNameField.text) {
                    if (deviceNameField.text == "") {
                        // Don't allow people to set an empty device name, that's just silly
                        if (_private.hardwareDevice.midiRouterDevice) {
                            _private.hardwareDevice.name = _private.hardwareDevice.midiRouterDevice.humanReadableName;
                        } else {
                            _private.hardwareDevice.name = qsTr("Unnamed Device");
                        }
                        deviceNameField.text = _private.hardwareDevice.name;
                    } else {
                        _private.hardwareDevice.name = deviceNameField.text;
                    }
                }
            }
        }
        QQC2.Slider {
            // TODO We are basically prepared to support multiple channels for each hardware device, but... let's just roll with a single channel per each for now
            id: deviceMidiChannelField
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            implicitWidth: Kirigami.Units.gridUnit * 15
            Layout.minimumWidth: Kirigami.Units.gridUnit * 15
            Kirigami.FormData.label: qsTr("MIDI Channel: %1").arg(_private.hardwareDevice.lowestMidiChannel)
            from: 0
            to: 15
            stepSize: 1
            snapMode: QQC2.Slider.SnapAlways
            onValueChanged: {
                if (_private.hardwareDevice.lowestMidiChannel !== deviceMidiChannelField.value) {
                    _private.hardwareDevice.lowestMidiChannel = deviceMidiChannelField.value;
                }
                if (_private.hardwareDevice.highestMidiChannel !== deviceMidiChannelField.value) {
                    _private.hardwareDevice.highestMidiChannel = deviceMidiChannelField.value;
                }
            }
        }
        QQC2.Slider {
            id: deviceBankMaxField
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            implicitWidth: Kirigami.Units.gridUnit * 15
            Layout.minimumWidth: Kirigami.Units.gridUnit * 15
            Kirigami.FormData.label: qsTr("Highest Bank Value: %1").arg(_private.hardwareDevice.bankMax)
            from: 0
            to: 127
            stepSize: 1
            snapMode: QQC2.Slider.SnapAlways
            onValueChanged: {
                if (_private.hardwareDevice.bankMax !== deviceBankMaxField.value) {
                    _private.hardwareDevice.bankMax = deviceBankMaxField.value;
                }
            }
        }
        QQC2.Slider {
            id: deviceProgramMaxField
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            implicitWidth: Kirigami.Units.gridUnit * 15
            Layout.minimumWidth: Kirigami.Units.gridUnit * 15
            Kirigami.FormData.label: qsTr("Highest Bank Value: %1").arg(_private.hardwareDevice.programMax)
            from: 0
            to: 127
            stepSize: 1
            snapMode: QQC2.Slider.SnapAlways
            onValueChanged: {
                if (_private.hardwareDevice.programMax !== deviceProgramMaxField.value) {
                    _private.hardwareDevice.programMax = deviceProgramMaxField.value;
                }
            }
        }
        QQC2.Switch {
            id: deviceValuesStartAtOneField
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            implicitWidth: Kirigami.Units.gridUnit * 5
            Layout.minimumWidth: Kirigami.Units.gridUnit * 5
            Kirigami.FormData.label: qsTr("Display Values As 1 through 128:")
            onCheckedChanged: {
                if (_private.hardwareDevice.valuesStartAtOne !== deviceValuesStartAtOneField.checked) {
                    _private.hardwareDevice.valuesStartAtOne = deviceValuesStartAtOneField.checked;
                }
            }
        }
    }
}
