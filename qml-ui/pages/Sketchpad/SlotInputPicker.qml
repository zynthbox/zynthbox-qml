/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Slot Swapper, for swapping the slots (sound sources or fx) on a sketchpad track

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
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.DialogQuestion {
    id: component
    function pickSlotInputs(channel, slotType, slotIndex) {
        _private.slotIndex = slotIndex;
        _private.slotType = slotType;
        _private.selectedChannel = channel;
        _private.displayedSection = 0;
        component.open();
    }

    onAccepted: {
        _private.selectedChannel = null;
    }

    height: Kirigami.Units.gridUnit * 30
    width: Kirigami.Units.gridUnit * 35

    acceptText: qsTr("Close")
    rejectText: ""
    title: _private.engineData === null ? "" : qsTr("Select Inputs for %1").arg(_private.engineData.name)

    ColumnLayout {
        anchors {
            fill: parent
            margins: Kirigami.Units.largeSpacing
        }
        QtObject {
            id: _private
            property QtObject selectedChannel
            property string slotType
            property int slotIndex
            property int displayedSection: 0
            property QtObject engineData: selectedChannel === null
                ? null
                : slotType === "synth"
                    ? selectedChannel.synthRoutingData[slotIndex]
                    : slotType === "fx"
                        ? selectedChannel.fxRoutingData[slotIndex]
                        : null
        }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: _private.selectedChannel === null ? "" : qsTr("Use this dialog to override the default routing for this slot. If you leave this alone, the routing is defined by the Routing option on the Track view (which is currently set to %1 for Track %2). This is useful to be able to do for things like vocoders and other effects which modulate one sound with another.").arg(_private.selectedChannel.channelRoutingStyleName).arg(_private.selectedChannel.name)
        }
        RowLayout {
            Layout.fillWidth: true
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 15
                text: qsTr("Audio Inputs")
                checked: _private.displayedSection === 0
                visible: _private.engineData ? _private.engineData.audioInPorts.length > 0 : false
                MouseArea { anchors.fill: parent; onClicked: parent.onClicked(); }
                onClicked: {
                    _private.displayedSection = 0;
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 15
                text: qsTr("MIDI Inputs")
                checked: _private.displayedSection === 1
                visible: _private.engineData ? _private.engineData.midiInPorts.length > 0 : false
                MouseArea { anchors.fill: parent; onClicked: parent.onClicked(); }
                onClicked: {
                    _private.displayedSection = 1;
                }
            }
        }
        ColumnLayout {
            visible: _private.displayedSection === 0
            Layout.fillWidth: true
            Zynthian.ComboBox {
                id: sourceComboBox
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: false
                function pickSource(port, source) {
                    sourceComboBox.port = port;
                    sourceComboBox.source = source;
                    if (sourceComboBox.source) {
                        sourceComboBox.selectIndex(audioInSourceComboModel.indexOfValue(source.port));
                    } else {
                        sourceComboBox.selectIndex(-1);
                    }
                    sourceComboBox.onClicked();
                }
                textRole: "text"
                property QtObject port: null
                property QtObject source: null
                onActivated: {
                    let listElement = sourceComboBox.model.get(index);
                    if (sourceComboBox.source === null) {
                        sourceComboBox.port.addSource(listElement.value, listElement.text);
                    } else {
                        sourceComboBox.source.port = listElement.value;
                        sourceComboBox.source.name = listElement.text;
                    }
                    sourceComboBox.source = null;
                }
            }
            ListModel {
                id: audioInSourceComboModel
                function indexOfValue(value) {
                    for (let index = 0; index < count; ++index) {
                        let element = get(index);
                        if (element.value == value) {
                            return index;
                        }
                    }
                    return -1;
                }
                // standard routing input (the normal input)
                // system
                //  - microphone in
                // track
                //  - sound slot 1-5
                //  - fx slot 1-5
                // no input (literally just a "don't route sound to here" option
                ListElement { text: "Standard Routing - Left Channel"; value: "standard-routing:left" }
                ListElement { text: "Standard Routing - Right Channel"; value: "standard-routing:right" }
                ListElement { text: "Standard Routing - Both Channels"; value: "standard-routing:both" }
                ListElement { text: "No Audio Input"; value: "no-input" }
                ListElement { text: "Audio In - Left Channel"; value: "external:left" }
                ListElement { text: "Audio In - Right Channel"; value: "external:right" }
                ListElement { text: "Audio In - Both Channels"; value: "external:both" }
                ListElement { text: "Master Output - Left Channel"; value: "internal-master:left" }
                ListElement { text: "Master Output - Right Channel"; value: "internal-master:right" }
                ListElement { text: "Master Output - Both Channels"; value: "internal-master:both" }
            }
            Component.onCompleted: {
                let clients = ["sketchpadTrack", "fxSlot"]
                let clientNames = ["Track Sound", "Track FX"]
                let entries = [
                    ["dry0", "dry1", "dry2", "dry3", "dry4"],
                    ["dry0", "wet0", "dry1", "wet1", "dry2", "wet2", "dry3", "wet3", "dry4", "wet4"]
                    ];
                let entryNames = [
                    ["Output 1", "Output 2", "Output 3", "Output 4", "Output 5"],
                    ["Slot 1 (Dry)", "Slot 1 (Wet)", "Slot 2 (Dry)", "Slot 2 (Wet)", "Slot 3 (Dry)", "Slot 3 (Wet)", "Slot 4 (Dry)", "Slot 4 (Wet)", "Slot 5 (Dry)", "Slot 5 (Wet)"]
                    ];
                let channels = ["left", "right", "both"];
                let channelNames = ["Left", "Right", "Both"]
                for (let clientIndex = 0; clientIndex < 2; ++clientIndex) {
                    for (let trackIndex = 0; trackIndex < Zynthbox.Plugin.sketchpadTrackCount; ++trackIndex) {
                        for (let entryIndex = 0; entryIndex < entries[clientIndex].length; ++entryIndex) {
                            for (let channelIndex = 0; channelIndex < 3; ++channelIndex) {
                                audioInSourceComboModel.append({
                                    "text": qsTr("Track %1 %2 - %3 - %4 Channel").arg(clientNames[clientIndex]).arg(trackIndex + 1).arg(entryNames[clientIndex][entryIndex]).arg(channelNames[channelIndex]),
                                    "value": "%1:%2:%3:%4".arg(clients[clientIndex]).arg(trackIndex).arg(entries[clientIndex][entryIndex]).arg(channels[channelIndex])
                                });
                            }
                        }
                    }
                }
                sourceComboBox.model = audioInSourceComboModel;
            }
            Repeater {
                id: portRepeater
                model: _private.engineData === null ? 0 : _private.engineData.audioInPorts
                delegate: RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 10 // Just making these the same height, because that's kind of nice
                    ColumnLayout {
                        id: portDelegate
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 25
                        property QtObject port: modelData
                        property var sources: modelData.sources
                        Repeater {
                            id: sourceRepeater
                            model: 5 // let's not go wild, stop people adding more than five sources
                            delegate: RowLayout {
                                id: sourceDelegate
                                property QtObject source: portDelegate.sources.length > model.index ? portDelegate.sources[model.index] : null
                                Layout.fillWidth: true
                                visible: sourceDelegate.source !== null || model.index === portDelegate.sources.length
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: sourceDelegate.source === null
                                        ? qsTr("Tap to select a source")
                                        : sourceDelegate.source.name
                                    onClicked: {
                                        sourceComboBox.pickSource(portDelegate.port, sourceDelegate.source);
                                    }
                                }
                                QQC2.Button {
                                    Layout.fillHeight: true
                                    visible: sourceDelegate.source
                                    icon.name: "edit-clear-symbolic"
                                    onClicked: {
                                        portDelegate.port.removeSource(model.index);
                                    }
                                }
                                QQC2.Label {
                                    Layout.fillHeight: true
                                    text: "🡢"
                                }
                            }
                        }
                    }
                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        text: modelData.name
                        MouseArea { anchors.fill: parent; onClicked: {} }
                    }
                }
            }
        }
        ColumnLayout {
            visible: _private.displayedSection === 1
            Layout.fillWidth: true
            Zynthian.ComboBox {
                id: midiSourceComboBox
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: false
                function pickSource(port, source) {
                    midiSourceComboBox.port = port;
                    midiSourceComboBox.source = source;
                    if (midiSourceComboBox.source) {
                        midiSourceComboBox.selectIndex(midiSourcesModel.indexOfValue(source.port));
                    } else {
                        midiSourceComboBox.selectIndex(-1);
                    }
                    midiSourceComboBox.onClicked();
                }
                textRole: "text"
                property QtObject port: null
                property QtObject source: null
                onActivated: {
                    let listElement = midiSourceComboBox.model.get(index);
                    if (midiSourceComboBox.source === null) {
                        midiSourceComboBox.port.addSource(listElement.value, listElement.text);
                    } else {
                        midiSourceComboBox.source.port = listElement.value;
                        midiSourceComboBox.source.name = listElement.text;
                    }
                    midiSourceComboBox.source = null;
                }
            }
            ListModel {
                id: midiSourcesModel
                function indexOfValue(value) {
                    for (let index = 0; index < count; ++index) {
                        let element = get(index);
                        if (element.value == value) {
                            return index;
                        }
                    }
                    return -1;
                }
                ListElement { text: "Current Track"; value: "sketchpadTrack:-1" } // -1 is the internal shorthand used for the current track basically everywhere
                ListElement { text: "Track 1"; value: "sketchpadTrack:0"; hardwareRow: -1 }
                ListElement { text: "Track 2"; value: "sketchpadTrack:1"; hardwareRow: -1 }
                ListElement { text: "Track 3"; value: "sketchpadTrack:2"; hardwareRow: -1 }
                ListElement { text: "Track 4"; value: "sketchpadTrack:3"; hardwareRow: -1 }
                ListElement { text: "Track 5"; value: "sketchpadTrack:4"; hardwareRow: -1 }
                ListElement { text: "Track 6"; value: "sketchpadTrack:5"; hardwareRow: -1 }
                ListElement { text: "Track 7"; value: "sketchpadTrack:6"; hardwareRow: -1 }
                ListElement { text: "Track 8"; value: "sketchpadTrack:7"; hardwareRow: -1 }
                ListElement { text: "Track 9"; value: "sketchpadTrack:8"; hardwareRow: -1 }
                ListElement { text: "Track 10"; value: "sketchpadTrack:9"; hardwareRow: -1 }
                ListElement { text: "No Midi Input"; value: "no-input" }
            }
            Zynthbox.FilterProxy {
                id: hardwareInputDevices
                sourceModel: Zynthbox.MidiRouter.model
                filterRole: Zynthbox.MidiRouterDeviceModel.IsHardwareDeviceRole
                filterBoolean: true
            }
            Component.onCompleted: {
                for (let newRow = 0; newRow < hardwareInputDevices.count; ++newRow) {
                    midiSourcesModel.append({
                        "text": hardwareInputDevices.data(hardwareInputDevices.index(newRow, 0), Zynthbox.MidiRouterDeviceModel.HumanNameRole),
                        "value": "external:" + hardwareInputDevices.data(hardwareInputDevices.index(newRow, 0), Zynthbox.MidiRouterDeviceModel.HardwareIdRole),
                        "hardwareRow": newRow
                    });
                    // console.log("Adding device", hardwareInputDevices.data(hardwareInputDevices.index(newRow, 0), Zynthbox.MidiRouterDeviceModel.HumanNameRole), "for row", newRow);
                }
                midiSourceComboBox.model = midiSourcesModel;
            }
            Connections {
                target: hardwareInputDevices
                onRowsInserted: {
                    for (let newRow = first; newRow < last + 1; ++newRow) {
                        let addEntry = true;
                        for (let ourIndex = 0; ourIndex < midiSourcesModel.count; ++ourIndex) {
                            let ourEntry = midiSourcesModel.get(ourIndex);
                            if (ourEntry.hardwareRow === newRow) {
                                addEntry = false;
                                break;
                            }
                        }
                        if (addEntry) {
                            midiSourcesModel.append({
                                "text": hardwareInputDevices.data(hardwareInputDevices.index(newRow, 0), Zynthbox.MidiRouterDeviceModel.HumanNameRole),
                                "value": "external:" + hardwareInputDevices.data(hardwareInputDevices.index(newRow, 0), Zynthbox.MidiRouterDeviceModel.HardwareIdRole),
                                "hardwareRow": newRow
                            });
                            // console.log("Adding device", hardwareInputDevices.data(hardwareInputDevices.index(newRow, 0), Zynthbox.MidiRouterDeviceModel.HumanNameRole), "for row", newRow);
                        }
                    }
                }
                onRowsRemoved: {
                    for (let removedRow = first; removedRow < last + 1; ++removedRow) {
                        for (let ourIndex = 0; ourIndex < midiSourcesModel.count; ++ourIndex) {
                            let ourEntry = midiSourcesModel.get(ourIndex);
                            if (ourEntry.hardwareRow === removedRow) {
                                midiSourcesModel.remove(ourIndex);
                                break;
                            }
                        }
                    }
                }
                onDataChanged: {
                    for (let changedRow = topLeft.row; changedRow < bottomRight.row + 1; ++changedRow) {
                        for (let ourIndex = 0; ourIndex < midiSourcesModel.count; ++ourIndex) {
                            let ourEntry = midiSourcesModel.get(ourIndex);
                            if (ourEntry.hardwareRow === changedRow) {
                                midiSourcesModel.set(ourIndex, {
                                    "text": hardwareInputDevices.data(hardwareInputDevices.index(changedRow, 0), Zynthbox.MidiRouterDeviceModel.HumanNameRole),
                                    "value": "external:" + hardwareInputDevices.data(hardwareInputDevices.index(changedRow, 0), Zynthbox.MidiRouterDeviceModel.HardwareIdRole),
                                    "hardwareRow": changedRow
                                });
                                break;
                            }
                        }
                    }
                }
            }
            Repeater {
                id: midiPortRepeater
                model: _private.engineData === null ? 0 : _private.engineData.midiInPorts
                delegate: RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 10 // Just making these the same height, because that's kind of nice
                    ColumnLayout {
                        id: midiPortDelegate
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 25
                        property QtObject port: modelData
                        property var sources: port.sources
                        Repeater {
                            id: midiSourceRepeater
                            model: 5 // let's not go wild, stop people adding more than five sources
                            delegate: RowLayout {
                                id: midiSourceDelegate
                                property QtObject source: midiPortDelegate.sources.length > model.index ? midiPortDelegate.sources[model.index] : null
                                Layout.fillWidth: true
                                visible: midiSourceDelegate.source !== null || model.index === midiPortDelegate.sources.length
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: midiSourceDelegate.source === null
                                        ? qsTr("Tap to select a source")
                                        : midiSourceDelegate.source.name
                                    onClicked: {
                                        midiSourceComboBox.pickSource(midiPortDelegate.port, midiSourceDelegate.source);
                                    }
                                }
                                QQC2.Button {
                                    Layout.fillHeight: true
                                    visible: midiSourceDelegate.source && midiSourceDelegate.source.port.length > 0
                                    icon.name: "edit-clear-symbolic"
                                    onClicked: {
                                        midiPortDelegate.port.removeSource(model.index);
                                    }
                                }
                                QQC2.Label {
                                    Layout.fillHeight: true
                                    text: "🡢"
                                }
                            }
                        }
                    }
                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        text: modelData.name
                        MouseArea { anchors.fill: parent; onClicked: {} }
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
