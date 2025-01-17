/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Settings page for Midi Controllers

Copyright (C) 2024 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import QtQml 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox
import "MidiControllerSettings"

Zynthian.ScreenPage {
    id: root
    screenId: "midicontroller_settings"
    property bool isVisible: ["midicontroller_settings"].indexOf(zynqtgui.current_screen_id) >= 0

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Actions...")
            enabled: contentStack.currentItem.hasOwnProperty("actionPicker")
            onTriggered: {
                contentStack.currentItem.actionPicker.open();
            }
        },
        Kirigami.Action {
        },
        Kirigami.Action {
            // We'll need store integration for this stuff at some point...
            // text: qsTr("Get More...")
            // onTriggered: zynqtgui.show_modal("midicontroller_settings_downloader")
        }
    ]

    backAction: Kirigami.Action {
        text: qsTr("Back")
        onTriggered: {
            if (contentStack.currentItem.objectName === "rootComponent") {
                zynqtgui.current_screen_id = "admin";
            } else {
                contentStack.pop();
            }
        }
    }
    cuiaCallback: function(cuia) {
        return contentStack.currentItem.cuiaCallback(cuia);
    }

    QtObject {
        id: _private
        property int selectedDeviceIndex: -1
        property QtObject selectedDeviceObject: null
        onSelectedDeviceObjectChanged: {
            selectedInputFilterIndex = -1;
            selectedInputFilterRuleIndex = -1;
            selectedOutputFilterIndex = -1;
            selectedOutputFilterRuleIndex = -1;
        }
        property int selectedInputFilterIndex: -1
        property int selectedInputFilterRuleIndex: -1
        property int selectedOutputFilterIndex: -1
        property int selectedOutputFilterRuleIndex: -1
    }

    Component {
        id: rootComponent
        ColumnLayout {
            objectName: "rootComponent"
            function cuiaCallback(cuia) {
                let result = false;
                switch (cuia) {
                    case "SWITCH_BACK_SHORT":
                    case "SWITCH_BACK_BOLD":
                        zynqtgui.current_screen_id = "admin";
                        returnValue = true;
                        break;
                    case "SWITCH_SELECT_SHORT":
                    case "SWITCH_SELECT_BOLD":
                        if (_private.selectedDeviceIndex > -1) {
                            contentStack.push(deviceComponent, { containingPage: root, _private: _private });
                        }
                        returnValue = true;
                        break;
                    case "KNOB3_UP":
                        if (_private.selectedDeviceIndex + 1 < devicesListView.count) {
                            _private.selectedDeviceIndex = _private.selectedDeviceIndex + 1;
                            _private.selectedDeviceObject = devicesListView.currentItem.midiRouterDevice;
                        }
                        returnValue = true;
                        break;
                    case "KNOB3_DOWN":
                        if (_private.selectedDeviceIndex > 0) {
                            _private.selectedDeviceIndex = _private.selectedDeviceIndex - 1;
                            _private.selectedDeviceObject = devicesListView.currentItem.midiRouterDevice;
                        }
                        returnValue = true;
                        break;
                    default:
                        break;
                }
                return result;
            }
            Kirigami.Heading {
                Layout.fillWidth: true
                text: qsTr("Midi Controller Settings")
            }
            ListView {
                id: devicesListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: Zynthbox.FilterProxy {
                    sourceModel: Zynthbox.FilterProxy {
                        sourceModel: Zynthbox.MidiRouter.model
                        filterBoolean: true
                        filterRole: Zynthbox.MidiRouterDeviceModel.IsHardwareDeviceRole
                    }
                    filterBoolean: true
                    filterRole: Zynthbox.MidiRouterDeviceModel.VisibleRole
                }
                currentIndex: _private.selectedDeviceIndex
                delegate: Item {
                    id: devicesListViewDelegate
                    width: ListView.view.width
                    height: Kirigami.Units.gridUnit * 3
                    property QtObject midiRouterDevice: model.deviceObject
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            _private.selectedDeviceIndex = model.index;
                            _private.selectedDeviceObject = model.deviceObject;
                            contentStack.push(deviceComponent, { containingPage: root, _private: _private });
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border {
                            width: 1
                            color: devicesListViewDelegate.ListView.isCurrentItem ? "white" : "transparent"
                        }
                    }
                    RowLayout {
                        anchors.fill: parent
                        Kirigami.Icon {
                            Layout.fillHeight: true
                            Layout.margins: Kirigami.Units.largeSpacing
                            source: model.hasInput
                                ? model.hasOutput
                                    ? "escape-direction-horizontal" // The device has both input and output
                                    : "escape-direction-left" // The device has only input
                                : model.hasOutput
                                    ? "escape-direction-right" // The device has only output
                                    : "escape-direction-vertical" // This one's unlikely to happen, as a midi device with neither input nor output is a bit... not right, but hey, fill it up, why not, might be useful for some debuggery
                        }
                        ColumnLayout {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: model.humanName
                                verticalAlignment: Text.AlignVCenter
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: "description goes here..."
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: deviceComponent
        MidiControllerSettingsDevice {}
    }

    Zynthian.DialogQuestion {
        id: confirmer
        function confirmSomething(title, description, callbackFunction) {
            confirmer.title = title;
            confirmer.text = description;
            confirmer.callbackFunction = callbackFunction;
            confirmer.open();
        }
        property var callbackFunction: null
        onAccepted: {
            if (confirmer.callbackFunction) {
                confirmer.callbackFunction();
            }
        }
    }

    QQC2.StackView {
        id: contentStack
        anchors.fill: parent
        initialItem: rootComponent
        popEnter: null
        popExit: null
        pushEnter: null
        pushExit: null
        replaceEnter: null
        replaceExit: null
    }

    Zynthian.ComboBox {
        id: trackPicker
        visible: false;
        property int trackValue: -1
        function pickTrack(currentTrack, callbackFunction) {
            for (let testIndex = 0; testIndex < model.count; ++testIndex) {
                let testElement = model.get(testIndex);
                if (testElement.value === currentTrack) {
                    trackPicker.currentIndex = testIndex;
                    break;
                }
            }
            trackPicker.callbackFunction = callbackFunction;
            trackPicker.onClicked();
        }
        property var callbackFunction: null
        model: ListModel {
            ListElement { text: "No Track"; value: -3 }
            ListElement { text: "Any Track"; value: -2 }
            ListElement { text: "Current Track"; value: -1 }
            ListElement { text: "Track 1"; value: 0 }
            ListElement { text: "Track 2"; value: 1 }
            ListElement { text: "Track 3"; value: 2 }
            ListElement { text: "Track 4"; value: 3 }
            ListElement { text: "Track 5"; value: 4 }
            ListElement { text: "Track 6"; value: 5 }
            ListElement { text: "Track 7"; value: 6 }
            ListElement { text: "Track 8"; value: 7 }
            ListElement { text: "Track 9"; value: 8 }
            ListElement { text: "Track 10"; value: 9 }
        }
        textRole: "text"
        onActivated: function(activatedIndex) {
            trackPicker.trackValue = trackPicker.model.get(activatedIndex).value;
            if (trackPicker.callbackFunction) {
                trackPicker.callbackFunction(trackPicker.trackValue);
            }
        }
    }

    Zynthian.ComboBox {
        id: slotPicker
        visible: false;
        property int slotValue: -1
        function pickSlot(currentSlot, slotType, callbackFunction) {
            for (let testIndex = 0; testIndex < model.count; ++testIndex) {
                let testElement = model.get(testIndex);
                if (testElement.value === currentSlot) {
                    slotPicker.currentIndex = testIndex;
                    break;
                }
            }
            slotPicker.slotType = slotType;
            slotPicker.callbackFunction = callbackFunction;
            slotPicker.onClicked();
        }
        property var callbackFunction: null
        property int slotType: -1
        model: ListModel {
            ListElement { text: "Current Slot"; clipSlotText: "Current Clip"; soundSlotText: "Current Sound Slot"; fxSlotText: "Current FX Slot"; value: -1 }
            ListElement { text: "Slot 1"; clipSlotText: "Clip 1"; soundSlotText: "Sound Slot 1"; fxSlotText: "FX Slot 1"; value: 0 }
            ListElement { text: "Slot 2"; clipSlotText: "Clip 2"; soundSlotText: "Sound Slot 2"; fxSlotText: "FX Slot 2"; value: 1 }
            ListElement { text: "Slot 3"; clipSlotText: "Clip 3"; soundSlotText: "Sound Slot 3"; fxSlotText: "FX Slot 3"; value: 2 }
            ListElement { text: "Slot 4"; clipSlotText: "Clip 4"; soundSlotText: "Sound Slot 4"; fxSlotText: "FX Slot 4"; value: 3 }
            ListElement { text: "Slot 5"; clipSlotText: "Clip 5"; soundSlotText: "Sound Slot 5"; fxSlotText: "FX Slot 5"; value: 4 }
        }
        textRole: slotType === 0
            ? "clipSlotText"
            : slotType === 1
                ? "soundSlotText"
                : slotType === 2
                    ? "fxSlotText"
                    : "text"
        onActivated: function(activatedIndex) {
            slotPicker.slotValue = slotPicker.model.get(activatedIndex).value;
            if (slotPicker.callbackFunction) {
                slotPicker.callbackFunction(slotPicker.slotValue);
            }
        }
    }

    Zynthian.ComboBox {
        id: midiChannelPicker
        visible: false;
        property int channelValue: -1
        function pickMidiChannel(currentChannel, callbackFunction) {
            for (let testIndex = 0; testIndex < model.count; ++testIndex) {
                let testElement = model.get(testIndex);
                if (testElement.value === currentChannel) {
                    trackPicker.currentIndex = testIndex;
                    break;
                }
            }
            trackPicker.callbackFunction = callbackFunction;
            trackPicker.onClicked();
        }
        property var callbackFunction: null
        model: ListModel {
            ListElement { text: "MIDI Channel 1"; value: 0 }
            ListElement { text: "MIDI Channel 2"; value: 1 }
            ListElement { text: "MIDI Channel 3"; value: 2 }
            ListElement { text: "MIDI Channel 4"; value: 3 }
            ListElement { text: "MIDI Channel 5"; value: 4 }
            ListElement { text: "MIDI Channel 6"; value: 5 }
            ListElement { text: "MIDI Channel 7"; value: 6 }
            ListElement { text: "MIDI Channel 8"; value: 7 }
            ListElement { text: "MIDI Channel 9"; value: 8 }
            ListElement { text: "MIDI Channel 10"; value: 9 }
            ListElement { text: "MIDI Channel 11"; value: 10 }
            ListElement { text: "MIDI Channel 12"; value: 11 }
            ListElement { text: "MIDI Channel 13"; value: 12 }
            ListElement { text: "MIDI Channel 14"; value: 13 }
            ListElement { text: "MIDI Channel 15"; value: 14 }
            ListElement { text: "MIDI Channel 16"; value: 15 }
        }
        textRole: "text"
        onActivated: function(activatedIndex) {
            trackPicker.channelValue = trackPicker.model.get(activatedIndex).value;
            if (trackPicker.callbackFunction) {
                trackPicker.callbackFunction(trackPicker.channelValue);
            }
        }
    }

    Zynthian.ComboBox {
        id: midiBytePicker
        visible: false;
        property int byteValue: -1
        property int messageSize: 0
        // byteType can be 0 for first byte, 1 for just picking a value, 2 for cc names
        function pickByte(byteValue, byteType, callbackFunction) {
            midiBytePicker.byteType = byteType;
            let testValue = byteType === 0 ? byteValue : byteValue + 128;
            for (let testIndex = 0; testIndex < model.count; ++testIndex) {
                let testElement = model.get(testIndex);
                if (testElement.value === testValue) {
                    midiBytePicker.currentIndex = testIndex;
                    break;
                }
            }
            midiBytePicker.callbackFunction = callbackFunction;
            midiBytePicker.onClicked();
        }
        property var callbackFunction: null
        property int byteType: 0
        function byteValueToMessageName(theByte) {
            for (let modelIndex = 0; modelIndex < model.count; ++modelIndex) {
                let entry = model.get(modelIndex);
                if (entry.value === theByte) {
                    // console.log("Found thing!", theByte, entry.byte0text);
                    return entry.byte0text;
                    break;
                }
            }
            // console.log("Oh no did not find thing", theByte);
            return "Unknown Byte Value: %1".arg(theByte);
        }
        function byteValueToMessageSize(theByte) {
            for (let modelIndex = 0; modelIndex < model.count; ++modelIndex) {
                let entry = model.get(modelIndex);
                if (entry.value === theByte) {
                    // console.log("Found thing!", theByte, entry.messageSize);
                    return entry.messageSize;
                    break;
                }
            }
            // console.log("Oh no did not find thing", theByte);
            return "Unknown Byte Value: %1".arg(theByte);
        }
        function byteValueToCCName(theByte) {
            let testValue = theByte + 128;
            for (let modelIndex = 0; modelIndex < model.count; ++modelIndex) {
                let entry = model.get(modelIndex);
                if (entry.value === testValue) {
                    // console.log("Found thing!", theByte, entry.ccNameText);
                    return entry.ccNameText;
                    break;
                }
            }
            // console.log("Oh no did not find thing", theByte);
            return "Unknown Byte Value: %1".arg(theByte);
        }
        model: ListModel {
            ListElement { byte0text: "Note Off - Channel 1"; byte1text: "0"; ccNameText: "Bank Select"; value: 0x80; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 2"; byte1text: "1"; ccNameText: "Modulation Wheel or Lever"; value: 0x81; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 3"; byte1text: "2"; ccNameText: "Breath Controller"; value: 0x82; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 4"; byte1text: "3"; ccNameText: "Undefined (0x03)"; value: 0x83; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 5"; byte1text: "4"; ccNameText: "Foot Controller"; value: 0x84; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 6"; byte1text: "5"; ccNameText: "Portamento Time"; value: 0x85; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 7"; byte1text: "6"; ccNameText: "Data Entry MSB"; value: 0x86; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 8"; byte1text: "7"; ccNameText: "Channel Volume"; value: 0x87; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 9"; byte1text: "8"; ccNameText: "Balance"; value: 0x88; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 10"; byte1text: "9"; ccNameText: "Undefined (0x09)"; value: 0x89; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 11"; byte1text: "10"; ccNameText: "Pan"; value: 0x8A; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 12"; byte1text: "11"; ccNameText: "Expression Controller"; value: 0x8B; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 13"; byte1text: "12"; ccNameText: "Effect Control 1"; value: 0x8C; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 14"; byte1text: "13"; ccNameText: "Effect Control 2"; value: 0x8D; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 15"; byte1text: "14"; ccNameText: "Undefined (0x0E)"; value: 0x8E; messageSize: 3 }
            ListElement { byte0text: "Note Off - Channel 16"; byte1text: "15"; ccNameText: "Undefined (0x0F)"; value: 0x8F; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 1"; byte1text: "16"; ccNameText: "General Purpose Controller 1"; value: 0x90; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 2"; byte1text: "17"; ccNameText: "General Purpose Controller 2"; value: 0x91; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 3"; byte1text: "18"; ccNameText: "General Purpose Controller 3"; value: 0x92; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 4"; byte1text: "19"; ccNameText: "General Purpose Controller 4"; value: 0x93; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 5"; byte1text: "20"; ccNameText: "Undefined (0x14)"; value: 0x94; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 6"; byte1text: "21"; ccNameText: "Undefined (0x15)"; value: 0x95; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 7"; byte1text: "22"; ccNameText: "Undefined (0x16)"; value: 0x96; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 8"; byte1text: "23"; ccNameText: "Undefined (0x17)"; value: 0x97; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 9"; byte1text: "24"; ccNameText: "Undefined (0x18)"; value: 0x98; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 10"; byte1text: "25"; ccNameText: "Undefined (0x19)"; value: 0x99; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 11"; byte1text: "26"; ccNameText: "Undefined (0x1A)"; value: 0x9A; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 12"; byte1text: "27"; ccNameText: "Undefined (0x1B)"; value: 0x9B; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 13"; byte1text: "28"; ccNameText: "Undefined (0x1C)"; value: 0x9C; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 14"; byte1text: "29"; ccNameText: "Undefined (0x1D)"; value: 0x9D; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 15"; byte1text: "30"; ccNameText: "Undefined (0x1E)"; value: 0x9E; messageSize: 3 }
            ListElement { byte0text: "Note On - Channel 16"; byte1text: "31"; ccNameText: "Undefined (0x1F)"; value: 0x9F; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 1"; byte1text: "32"; ccNameText: "LSB for Control 0 (Bank Select)"; value: 0xA0; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 2"; byte1text: "33"; ccNameText: "LSB for Control 1 (Modulation Wheel or Lever)"; value: 0xA1; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 3"; byte1text: "34"; ccNameText: "LSB for Control 2 (Breath Controller)"; value: 0xA2; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 4"; byte1text: "35"; ccNameText: "LSB for Control 3 (Undefined)"; value: 0xA3; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 5"; byte1text: "36"; ccNameText: "LSB for Control 4 (Foot Controller)"; value: 0xA4; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 6"; byte1text: "37"; ccNameText: "LSB for Control 5 (Portamento Time)"; value: 0xA5; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 7"; byte1text: "38"; ccNameText: "LSB for Control 6 (Data Entry)"; value: 0xA6; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 8"; byte1text: "39"; ccNameText: "LSB for Control 7 (Channel Volume)"; value: 0xA7; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 9"; byte1text: "40"; ccNameText: "LSB for Control 8 (Balance)"; value: 0xA8; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 10"; byte1text: "41"; ccNameText: "LSB for Control 9 (Undefined)"; value: 0xA9; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 11"; byte1text: "42"; ccNameText: "LSB for Control 10 (Pan)"; value: 0xAA; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 12"; byte1text: "43"; ccNameText: "LSB for Control 11 (Expression Controller)"; value: 0xAB; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 13"; byte1text: "44"; ccNameText: "LSB for Control 12 (Effect control 1)"; value: 0xAC; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 14"; byte1text: "45"; ccNameText: "LSB for Control 13 (Effect control 2)"; value: 0xAD; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 15"; byte1text: "46"; ccNameText: "LSB for Control 14 (Undefined)"; value: 0xAE; messageSize: 3 }
            ListElement { byte0text: "Polyphonic Aftertouch - Channel 16"; byte1text: "47"; ccNameText: "LSB for Control 15 (Undefined)"; value: 0xAF; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 1"; byte1text: "48"; ccNameText: "LSB for Control 16 (General Purpose Controller 1)"; value: 0xB0; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 2"; byte1text: "49"; ccNameText: "LSB for Control 17 (General Purpose Controller 2)"; value: 0xB1; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 3"; byte1text: "50"; ccNameText: "LSB for Control 18 (General Purpose Controller 3)"; value: 0xB2; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 4"; byte1text: "51"; ccNameText: "LSB for Control 19 (General Purpose Controller 4)"; value: 0xB3; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 5"; byte1text: "52"; ccNameText: "LSB for Control 20 (Undefined)"; value: 0xB4; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 6"; byte1text: "53"; ccNameText: "LSB for Control 21 (Undefined)"; value: 0xB5; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 7"; byte1text: "54"; ccNameText: "LSB for Control 22 (Undefined)"; value: 0xB6; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 8"; byte1text: "55"; ccNameText: "LSB for Control 23 (Undefined)"; value: 0xB7; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 9"; byte1text: "56"; ccNameText: "LSB for Control 24 (Undefined)"; value: 0xB8; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 10"; byte1text: "57"; ccNameText: "LSB for Control 25 (Undefined)"; value: 0xB9; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 11"; byte1text: "58"; ccNameText: "LSB for Control 26 (Undefined)"; value: 0xBA; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 12"; byte1text: "59"; ccNameText: "LSB for Control 27 (Undefined)"; value: 0xBB; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 13"; byte1text: "60"; ccNameText: "LSB for Control 28 (Undefined)"; value: 0xBC; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 14"; byte1text: "61"; ccNameText: "LSB for Control 29 (Undefined)"; value: 0xBD; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 15"; byte1text: "62"; ccNameText: "LSB for Control 30 (Undefined)"; value: 0xBE; messageSize: 3 }
            ListElement { byte0text: "Control/Mode Change - Channel 16"; byte1text: "63"; ccNameText: "LSB for Control 31 (Undefined)"; value: 0xBF; messageSize: 3 }
            ListElement { byte0text: "Program Change - Channel 1"; byte1text: "64"; ccNameText: "Damper Pedal on/off (Sustain)"; value: 0xC0; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 2"; byte1text: "65"; ccNameText: "Portamento On/Off"; value: 0xC1; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 3"; byte1text: "66"; ccNameText: "Sostenuto On/Off"; value: 0xC2; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 4"; byte1text: "67"; ccNameText: "Soft Pedal On/Off"; value: 0xC3; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 5"; byte1text: "68"; ccNameText: "Legato Footswitch"; value: 0xC4; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 6"; byte1text: "69"; ccNameText: "Hold 2"; value: 0xC5; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 7"; byte1text: "70"; ccNameText: "Sound Controller 1 (default: Sound Variation)"; value: 0xC6; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 8"; byte1text: "71"; ccNameText: "Sound Controller 2 (default: Timbre/Harmonic Intensity)"; value: 0xC7; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 9"; byte1text: "72"; ccNameText: "Sound Controller 3 (default: Release Time)"; value: 0xC8; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 10"; byte1text: "73"; ccNameText: "Sound Controller 4 (default: Attack Time)"; value: 0xC9; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 11"; byte1text: "74"; ccNameText: "Sound Controller 5 (default: Brightness)"; value: 0xCA; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 12"; byte1text: "75"; ccNameText: "Sound Controller 6 (default: Decay Time)"; value: 0xCB; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 13"; byte1text: "76"; ccNameText: "Sound Controller 7 (default: Vibrato Rate)"; value: 0xCC; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 14"; byte1text: "77"; ccNameText: "Sound Controller 8 (default: Vibrato Depth)"; value: 0xCD; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 15"; byte1text: "78"; ccNameText: "Sound Controller 9 (default: Vibrato Delay"; value: 0xCE; messageSize: 2 }
            ListElement { byte0text: "Program Change - Channel 16"; byte1text: "79"; ccNameText: "Sound Controller 10 (default undefined)"; value: 0xCF; messageSize: 2 }
            ListElement { byte0text: "Channel Aftertouch - Channel 1"; byte1text: "80"; ccNameText: "General Purpose Controller 5"; value: 0xD0; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 2"; byte1text: "81"; ccNameText: "General Purpose Controller 6"; value: 0xD1; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 3"; byte1text: "82"; ccNameText: "General Purpose Controller 7"; value: 0xD2; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 4"; byte1text: "83"; ccNameText: "General Purpose Controller 8"; value: 0xD3; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 5"; byte1text: "84"; ccNameText: "Portamento Control"; value: 0xD4; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 6"; byte1text: "85"; ccNameText: "Undefined (0x55)"; value: 0xD5; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 7"; byte1text: "86"; ccNameText: "Undefined (0x56)"; value: 0xD6; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 8"; byte1text: "87"; ccNameText: "Undefined (0x57)"; value: 0xD7; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 9"; byte1text: "88"; ccNameText: "High Resolution Velocity Prefix"; value: 0xD8; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 10"; byte1text: "89"; ccNameText: "Undefined (0x59)"; value: 0xD9; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 11"; byte1text: "90"; ccNameText: "Undefined (0x5A)"; value: 0xDA; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 12"; byte1text: "91"; ccNameText: "Effects 1 Depth (default: Reverb Send Level)"; value: 0xDB; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 13"; byte1text: "92"; ccNameText: "Effects 2 Depth (formerly Tremolo Depth)"; value: 0xDC; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 14"; byte1text: "93"; ccNameText: "Effects 3 Depth (default: Chorus Send Level)"; value: 0xDD; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 15"; byte1text: "94"; ccNameText: "Effects 4 Depth (formerly Celeste [Detune] Depth)"; value: 0xDE; messageSize: 3 }
            ListElement { byte0text: "Channel Aftertouch - Channel 16"; byte1text: "95"; ccNameText: "Effects 5 Depth (formerly Phaser Depth)"; value: 0xDF; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 1"; byte1text: "96"; ccNameText: "Data Increment (Data Entry +1)"; value: 0xE0; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 2"; byte1text: "97"; ccNameText: "Data Decrement (Data Entry -1)"; value: 0xE1; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 3"; byte1text: "98"; ccNameText: "Non-Registered Parameter Number (NRPN) – LSB"; value: 0xE2; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 4"; byte1text: "99"; ccNameText: "Non-Registered Parameter Number (NRPN) – MSB"; value: 0xE3; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 5"; byte1text: "100"; ccNameText: "Registered Parameter Number (RPN) – LSB"; value: 0xE4; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 6"; byte1text: "101"; ccNameText: "Registered Parameter Number (RPN) – MSB"; value: 0xE5; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 7"; byte1text: "102"; ccNameText: "Undefined (0x66)"; value: 0xE6; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 8"; byte1text: "103"; ccNameText: "Undefined (0x67)"; value: 0xE7; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 9"; byte1text: "104"; ccNameText: "Undefined (0x68)"; value: 0xE8; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 10"; byte1text: "105"; ccNameText: "Undefined (0x69)"; value: 0xE9; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 11"; byte1text: "106"; ccNameText: "Undefined (0x6A)"; value: 0xEA; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 12"; byte1text: "107"; ccNameText: "Undefined (0x6B)"; value: 0xEB; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 13"; byte1text: "108"; ccNameText: "Undefined (0x6C)"; value: 0xEC; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 14"; byte1text: "109"; ccNameText: "Undefined (0x6D)"; value: 0xED; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 15"; byte1text: "110"; ccNameText: "Undefined (0x6E)"; value: 0xEE; messageSize: 3 }
            ListElement { byte0text: "Pitch Wheel - Channel 16"; byte1text: "111"; ccNameText: "Undefined (0x6F)"; value: 0xEF; messageSize: 3 }
            ListElement { byte0text: "System Exclusive"; byte1text: "112"; ccNameText: "Undefined (0x70)"; value: 0xF0; messageSize: 1 }
            ListElement { byte0text: "MIDI Time Code Quarter Frame"; byte1text: "113"; ccNameText: "Undefined (0x71)"; value: 0xF1; messageSize: 3 }
            ListElement { byte0text: "Song Position Pointer"; byte1text: "114"; ccNameText: "Undefined (0x72)"; value: 0xF2; messageSize: 3 }
            ListElement { byte0text: "Song Select"; byte1text: "115"; ccNameText: "Undefined (0x73)"; value: 0xF3; messageSize: 2 }
            ListElement { byte0text: "Undefined (0xF3)"; byte1text: "116"; ccNameText: "Undefined (0x74)"; value: 0xF4; messageSize: 3 }
            ListElement { byte0text: "Undefined (0xF4)"; byte1text: "117"; ccNameText: "Undefined (0x75)"; value: 0xF5; messageSize: 3 }
            ListElement { byte0text: "Tune request"; byte1text: "118"; ccNameText: "Undefined (0x76)"; value: 0xF6; messageSize: 1 }
            ListElement { byte0text: "End of SysEx (EOX)"; byte1text: "119"; ccNameText: "Undefined (0x77)"; value: 0xF7; messageSize: 1 }
            ListElement { byte0text: "Timing Clock"; byte1text: "120"; ccNameText: "[Channel Mode Message] All Sound Off"; value: 0xF8; messageSize: 1 }
            ListElement { byte0text: "Undefined (0xF9)"; byte1text: "121"; ccNameText: "[Channel Mode Message] Reset All Controllers"; value: 0xF9; messageSize: 1 }
            ListElement { byte0text: "Start"; byte1text: "122"; ccNameText: "[Channel Mode Message] Local Control On/Off"; value: 0xFA; messageSize: 1 }
            ListElement { byte0text: "Continue"; byte1text: "123"; ccNameText: "[Channel Mode Message] All Notes Off"; value: 0xFB; messageSize: 1 }
            ListElement { byte0text: "Stop"; byte1text: "124"; ccNameText: "[Channel Mode Message] Omni Mode Off (+ all notes off)"; value: 0xFC; messageSize: 1 }
            ListElement { byte0text: "Undefined (0xFD)"; byte1text: "125"; ccNameText: "[Channel Mode Message] Omni Mode On (+ all notes off)"; value: 0xFD; messageSize: 1 }
            ListElement { byte0text: "Active Sensing"; byte1text: "126"; ccNameText: "[Channel Mode Message] Mono Mode On (+ poly off, + all notes off)"; value: 0xFE; messageSize: 1 }
            ListElement { byte0text: "System Reset"; byte1text: "127"; ccNameText: "[Channel Mode Message] Poly Mode On (+ mono off, +all notes off)"; value: 0xFF; messageSize: 1 }
        }
        textRole: byteType === 0
            ? "byte0text"
            : byteType === 1
                ? "byte1text"
                : byteType === 2
                    ? "ccNameText"
                    : "value"
        onActivated: function(activatedIndex) {
            let selectedElement = midiBytePicker.model.get(activatedIndex);
            if (midiBytePicker.byteType === 0) {
                midiBytePicker.byteValue = selectedElement.value;
            } else {
                midiBytePicker.byteValue = selectedElement.value - 128; // Also the index, but...
            }
            midiBytePicker.messageSize = selectedElement.messageSize;
            if (midiBytePicker.callbackFunction) {
                midiBytePicker.callbackFunction(midiBytePicker.byteValue, midiBytePicker.messageSize);
            }
        }
    }

    Zynthian.ComboBox {
        id: cuiaEventPicker
        visible: false;
        property int cuiaEvent: -1
        function pickEvent(cuiaEvent, callbackFunction) {
            for (let testIndex = 0; testIndex < model.count; ++testIndex) {
                let testElement = model.get(testIndex);
                if (testElement.value === cuiaEvent) {
                    cuiaEventPicker.currentIndex = testIndex;
                    break;
                }
            }
            cuiaEventPicker.callbackFunction = callbackFunction;
            cuiaEventPicker.onClicked();
        }
        property var callbackFunction: null
        Component.onCompleted: {
            for (let eventIndex = 0; eventIndex < 108; ++eventIndex) {
                model.append({ text: Zynthbox.CUIAHelper.cuiaTitle(eventIndex), value: eventIndex });
            }
        }
        model: ListModel {}
        textRole: "text"
        onActivated: function(activatedIndex) {
            cuiaEventPicker.cuiaEvent = cuiaEventPicker.model.get(activatedIndex).value;
            if (cuiaEventPicker.callbackFunction) {
                cuiaEventPicker.callbackFunction(cuiaEventPicker.cuiaEvent);
            }
        }
    }

    Zynthian.ComboBox {
        id: valueSpecifierPicker
        visible: false;
        property int valueSpecifier: -1
        function pickEvent(currentValueSpecifier, callbackFunction) {
            for (let testIndex = 0; testIndex < model.count; ++testIndex) {
                let testElement = model.get(testIndex);
                if (testElement.value === currentValueSpecifier) {
                    valueSpecifierPicker.currentIndex = testIndex;
                    break;
                }
            }
            valueSpecifierPicker.callbackFunction = callbackFunction;
            valueSpecifierPicker.onClicked();
        }
        property var callbackFunction: null
        Component.onCompleted: {
            for (let eventIndex = 0; eventIndex < 128; ++eventIndex) {
                model.append({ text: "%1".arg(eventIndex), value: eventIndex });
            }
        }
        model: ListModel {
            ListElement { text: "Matched MIDI message's Byte 1 value"; value: -1 }
            ListElement { text: "Matched MIDI message's Byte 2 value (where available, otherwise 0)"; value: -2 }
            ListElement { text: "Matched MIDI message's Byte 3 value (where available, otherwise 0)"; value: -3 }
            ListElement { text: "Matched MIDI message's event channel (where available, otherwise 0)"; value: -4 }
        }
        textRole: "text"
        onActivated: function(activatedIndex) {
            valueSpecifierPicker.valueSpecifier = valueSpecifierPicker.model.get(activatedIndex).value;
            if (valueSpecifierPicker.callbackFunction) {
                valueSpecifierPicker.callbackFunction(valueSpecifierPicker.valueSpecifier);
            }
        }
    }

    Zynthian.DialogQuestion {
        id: midiEventListener
        property var selectedEvent: []
        property string deviceId: ""
        readonly property QtObject deviceObject: deviceId === "" ? null : Zynthbox.MidiRouter.model.getDevice(deviceId)
        function listenForEvent(deviceId, callbackFunction) {
            midiEventListener.heardEvents = [];
            midiEventListener.selectedIndex = -1;
            midiEventListener.deviceId = deviceId;
            midiEventListener.selectedEvent = [];
            midiEventListener.callbackFunction = callbackFunction;
            midiEventListener.open();
        }
        cuiaCallback: function(cuia) {
            let result = false;
            switch (cuia) {
                case "SWITCH_BACK_SHORT":
                case "SWITCH_BACK_BOLD":
                    midiEventListener.reject();
                    returnValue = true;
                    break;
                case "SWITCH_SELECT_SHORT":
                case "SWITCH_SELECT_BOLD":
                    midiEventListener.accept();
                    returnValue = true;
                    break;
                case "KNOB3_UP":
                    midiEventListener.selectedIndex = Math.min(midiEventListener.heardEvents.length - 1, midiEventListener.selectedIndex + 1);
                    returnValue = true;
                    break;
                case "KNOB3_DOWN":
                    midiEventListener.selectedIndex = Math.max(0, midiEventListener.selectedIndex - 1);
                    returnValue = true;
                    break;
                default:
                    break;
            }
            return result;
        }
        property var callbackFunction: null
        onAccepted: {
            if (midiEventListener.selectedIndex > -1) {
                midiEventListener.selectedEvent = midiEventListener.heardEvents[midiEventListener.selectedIndex];
            } else {
                midiEventListener.selectedEvent = [];
            }
            if (midiEventListener.callbackFunction) {
                midiEventListener.callbackFunction(midiEventListener.selectedEvent);
            }
        }
        property int selectedIndex: -1
        onSelectedIndexChanged: {
            heardEventsList.positionViewAtIndex(selectedIndex, ListView.Center);
        }
        property var heardEvents: []
        title: qsTr("Listening for events...")
        rejectText: qsTr("Back")
        acceptText: selectedIndex === -1 ? qsTr("No Events Yet") : qsTr("Select Event %1").arg(selectedIndex + 1)
        acceptEnabled: selectedIndex > -1
        height: applicationWindow().height - Kirigami.Units.largeSpacing * 2
        width: applicationWindow().width - Kirigami.Units.largeSpacing * 2
        contentItem: ColumnLayout {
            QQC2.Label {
                Layout.fillWidth: true
                text: "Midi events sent from %1 will be displayed below, where you can pick from them.".arg(midiEventListener.deviceObject ? midiEventListener.deviceObject.humanReadableName : "")
                wrapMode: Text.Wrap
            }
            ListView {
                id: heardEventsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Kirigami.Units.largeSpacing
                clip: true
                model: midiEventListener.heardEvents
                delegate: RowLayout {
                    Layout.fillWidth: true
                    Item {
                        Layout.fillHeight: true
                        Layout.minimumWidth: height
                        Layout.maximumWidth: height
                        Rectangle {
                            anchors {
                                fill: parent
                                margins: Kirigami.Units.smallSpacing
                            }
                            radius: height / 2
                            border {
                                width: 1
                                color: Kirigami.Theme.textColor
                            }
                            color: midiEventListener.selectedIndex === model.index ? Kirigami.Theme.focusColor : "transparent"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { midiEventListener.selectedIndex = model.index; }
                        }
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: modelData.length === 1
                            ? midiBytePicker.byteValueToMessageName(modelData[0])
                            : modelData.length === 2
                                ? "%1 with value %2".arg(midiBytePicker.byteValueToMessageName(modelData[0])).arg(modelData[1])
                                : modelData.length === 3
                                    ? 127 < modelData[0] && modelData[0] < 160
                                        ? "%1 with note %2 and velocity %3".arg(midiBytePicker.byteValueToMessageName(modelData[0])).arg(Zynthbox.KeyScales.midiNoteName(modelData[1])).arg(modelData[2])
                                        : 159 < modelData[0] && modelData[0] < 176
                                            ? "%1 for note %2 with pressure %3".arg(midiBytePicker.byteValueToMessageName(modelData[0])).arg(Zynthbox.KeyScales.midiNoteName(modelData[1])).arg(modelData[2])
                                            : 175 < modelData[0] && modelData[0] < 192
                                                ? "%1 with function %2 and value %3".arg(midiBytePicker.byteValueToMessageName(modelData[0])).arg(midiBytePicker.byteValueToCCName(modelData[1])).arg(modelData[2])
                                                : 191 < modelData[0] && modelData[0] < 208
                                                    ? "%1 with program %2".arg(midiBytePicker.byteValueToMessageName(modelData[0])).arg(modelData[1])
                                                    : 207 < modelData[0] && modelData[0] < 224
                                                        ? "%1 with pressure %2".arg(midiBytePicker.byteValueToMessageName(modelData[0])).arg(modelData[1])
                                                        : "%1 with values %2 and %3".arg(midiBytePicker.byteValueToMessageName(modelData[0])).arg(modelData[1]).arg(modelData[2])
                                    : "(weird message with a length that isn't between 1 and 3" + modelData + ")"
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { midiEventListener.selectedIndex = model.index; }
                        }
                    }
                }
                QQC2.Label {
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.largeSpacing
                    }
                    opacity: parent.count === 0 ? 0.5 : 0
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Send some midi events from your device to show them here")
                }
            }
        }
        Connections {
            target: Zynthbox.MidiRouter
            enabled: midiEventListener.opened
            onMidiMessage: function(port, size, byte1, byte2, byte3, sketchpadTrack, fromInternal, hardwareDeviceId) {
                if ((port == Zynthbox.MidiRouter.HardwareInPassthroughPort || port == Zynthbox.MidiRouter.InternalControllerPassthroughPort) && (midiEventListener.deviceId.length === 0 || hardwareDeviceId === midiEventListener.deviceId)) {
                    let temporaryList = midiEventListener.heardEvents;
                    if (size === 1) {
                        temporaryList.push([byte1]);
                    } else if (size === 2) {
                        temporaryList.push([byte1,byte2]);
                    } else if (size === 3) {
                        temporaryList.push([byte1,byte2,byte3]);
                    } else {
                        // what in the world, this isn't right at all
                        console.log("Well, that's a bit weird");
                    }
                    midiEventListener.heardEvents = temporaryList;
                    if (midiEventListener.heardEvents.length === 1) {
                        midiEventListener.selectedIndex = 0;
                    }
                }
            }
        }
    }
}
