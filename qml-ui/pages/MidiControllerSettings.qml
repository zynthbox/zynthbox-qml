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
                    midiChannelPicker.currentIndex = testIndex;
                    break;
                }
            }
            midiChannelPicker.callbackFunction = callbackFunction;
            midiChannelPicker.onClicked();
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
            midiChannelPicker.channelValue = midiChannelPicker.model.get(activatedIndex).value;
            if (midiChannelPicker.callbackFunction) {
                midiChannelPicker.callbackFunction(midiChannelPicker.channelValue);
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
                            ? applicationWindow().midiBytePicker.byteValueToMessageName(modelData[0])
                            : modelData.length === 2
                                ? "%1 with value %2".arg(applicationWindow().midiBytePicker.byteValueToMessageName(modelData[0])).arg(modelData[1])
                                : modelData.length === 3
                                    ? 127 < modelData[0] && modelData[0] < 160
                                        ? "%1 with note %2 and velocity %3".arg(applicationWindow().midiBytePicker.byteValueToMessageName(modelData[0])).arg(Zynthbox.KeyScales.midiNoteName(modelData[1])).arg(modelData[2])
                                        : 159 < modelData[0] && modelData[0] < 176
                                            ? "%1 for note %2 with pressure %3".arg(applicationWindow().midiBytePicker.byteValueToMessageName(modelData[0])).arg(Zynthbox.KeyScales.midiNoteName(modelData[1])).arg(modelData[2])
                                            : 175 < modelData[0] && modelData[0] < 192
                                                ? "%1 with function %2 and value %3".arg(applicationWindow().midiBytePicker.byteValueToMessageName(modelData[0])).arg(applicationWindow().midiBytePicker.byteValueToCCName(modelData[1])).arg(modelData[2])
                                                : 191 < modelData[0] && modelData[0] < 208
                                                    ? "%1 with program %2".arg(applicationWindow().midiBytePicker.byteValueToMessageName(modelData[0])).arg(modelData[1])
                                                    : 207 < modelData[0] && modelData[0] < 224
                                                        ? "%1 with pressure %2".arg(applicationWindow().midiBytePicker.byteValueToMessageName(modelData[0])).arg(modelData[1])
                                                        : "%1 with values %2 and %3".arg(applicationWindow().midiBytePicker.byteValueToMessageName(modelData[0])).arg(modelData[1]).arg(modelData[2])
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
