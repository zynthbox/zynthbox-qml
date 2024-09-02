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
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.ScreenPage {
    id: root
    screenId: "midicontroller_settings"
    property bool isVisible: ["midicontroller_settings"].indexOf(zynqtgui.current_screen_id) >= 0

    // We'll need store integration for this stuff at some point...
    // contextualActions: [
    //     Kirigami.Action {
    //         text: qsTr("Get More...")
    //         onTriggered: zynqtgui.show_modal("midicontroller_settings_downloader")
    //     }
    // ]

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
            selectedOutputFilterIndex = -1;
        }
        property int selectedInputFilterIndex: -1
        property int selectedOutputFilterIndex: -1
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
                    case "SWITCH_BACK_LONG":
                        zynqtgui.current_screen_id = "admin";
                        returnValue = true;
                        break;
                    case "SWITCH_SELECT_SHORT":
                    case "SWITCH_SELECT_BOLD":
                    case "SWITCH_SELECT_LONG":
                        if (_private.selectedDeviceIndex > -1) {
                            contentStack.push(deviceComponent);
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
                    sourceModel: Zynthbox.MidiRouter.model
                    filterBoolean: true
                    filterRole: Zynthbox.MidiRouterDeviceModel.IsHardwareDeviceRole
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
                            contentStack.push(deviceComponent);
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
        QQC2.ScrollView {
            id: deviceComponentScroller
            clip: true
            contentWidth: availableWidth
            function cuiaCallback(cuia) {
                let result = false;
                switch (cuia) {
                    case "SWITCH_BACK_SHORT":
                    case "SWITCH_BACK_BOLD":
                    case "SWITCH_BACK_LONG":
                        contentStack.pop();
                        returnValue = true;
                        break;
                    case "SWITCH_SELECT_SHORT":
                    case "SWITCH_SELECT_BOLD":
                    case "SWITCH_SELECT_LONG":
                        if (deviceComponentScroller.currentRow.selectPressed) {
                            deviceComponentScroller.currentRow.selectPressed();
                        }
                        break;
                    case "KNOB0_UP":
                        if (deviceComponentScroller.currentRow.knob0up) {
                            deviceComponentScroller.currentRow.knob0up();
                        }
                        break;
                    case "KNOB0_DOWN":
                        if (deviceComponentScroller.currentRow.knob0down) {
                            deviceComponentScroller.currentRow.knob0down();
                        }
                        break;
                    case "KNOB1_UP":
                        if (deviceComponentScroller.currentRow.knob1up) {
                            deviceComponentScroller.currentRow.knob1up();
                        }
                        break;
                    case "KNOB1_DOWN":
                        if (deviceComponentScroller.currentRow.knob1down) {
                            deviceComponentScroller.currentRow.knob1down();
                        }
                        break;
                    case "KNOB2_UP":
                        if (deviceComponentScroller.currentRow.knob2up) {
                            deviceComponentScroller.currentRow.knob2up();
                        }
                        break;
                    case "KNOB2_DOWN":
                        if (deviceComponentScroller.currentRow.knob2down) {
                            deviceComponentScroller.currentRow.knob2down();
                        }
                        break;
                    case "KNOB3_UP": {
                        currentRow.goNext();
                        let mappedY = deviceComponentScroller.currentRow.y;
                        let theParent = deviceComponentScroller.currentRow.parent;
                        while (theParent !== deviceComponentContent) {
                            mappedY = mappedY + theParent.y;
                            theParent = theParent.parent;
                        }
                        deviceComponentScroller.contentItem.contentY = (deviceComponentContent.height - deviceComponentScroller.height) * ((deviceComponentScroller.currentRow.height * (mappedY / deviceComponentContent.height)) + mappedY) / deviceComponentContent.height;
                        returnValue = true;
                        break;
                    }
                    case "KNOB3_DOWN": {
                        currentRow.goPrevious();
                        let mappedY = deviceComponentScroller.currentRow.y;
                        let theParent = deviceComponentScroller.currentRow.parent;
                        while (theParent !== deviceComponentContent) {
                            mappedY = mappedY + theParent.y;
                            theParent = theParent.parent;
                        }
                        deviceComponentScroller.contentItem.contentY = (deviceComponentContent.height - deviceComponentScroller.height) * ((deviceComponentScroller.currentRow.height * (mappedY / deviceComponentContent.height)) + mappedY) / deviceComponentContent.height;
                        returnValue = true;
                        break;
                    }
                    default:
                        break;
                }
                return result;
            }
            property QtObject currentRow: deviceComponentHeader
            ColumnLayout {
                id: deviceComponentContent
                width: deviceComponentScroller.contentWidth - deviceComponentScroller.QQC2.ScrollBar.vertical.width
                RowLayout {
                    id: deviceComponentHeader
                    function goNext() { deviceComponentScroller.currentRow = firstDeviceSettingsRow; }
                    function goPrevious() {}
                    Kirigami.Heading {
                        Layout.fillWidth: true
                        text: _private.selectedDeviceObject === null ? "" : qsTr("%1 Settings").arg(_private.selectedDeviceObject.humanReadableName)
                    }
                }
                RowLayout {
                    id: firstDeviceSettingsRow
                    function goNext() { deviceComponentScroller.currentRow = secondDeviceSettingsRow; }
                    function goPrevious() { deviceComponentScroller.currentRow = deviceComponentHeader; }
                    function knob0up() {
                        _private.selectedDeviceObject.lowerMasterChannel = Math.min(15, _private.selectedDeviceObject.lowerMasterChannel + 1);
                    }
                    function knob0down() {
                        _private.selectedDeviceObject.lowerMasterChannel = Math.max(0, _private.selectedDeviceObject.lowerMasterChannel - 1);
                    }
                    function knob1up() {
                        _private.selectedDeviceObject.upperMasterChannel = Math.min(15, _private.selectedDeviceObject.upperMasterChannel + 1);
                    }
                    function knob1down() {
                        _private.selectedDeviceObject.upperMasterChannel = Math.max(0, _private.selectedDeviceObject.upperMasterChannel - 1);
                    }
                    function knob2up() {
                        _private.selectedDeviceObject.sendTimecode = true;
                    }
                    function knob2down() {
                        _private.selectedDeviceObject.sendTimecode = false;
                    }
                    Layout.fillWidth: true
                    QQC2.Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        text: _private.selectedDeviceObject === null ? "" : qsTr("Lower Zone Master Channel:\nChannel %1").arg(_private.selectedDeviceObject.lowerMasterChannel + 1)
                        onClicked: {
                            midiChannelPicker.pickMidiChannel(_private.selectedDeviceObject.lowerMasterChannel, function(newChannel) {
                                _private.selectedDeviceObject.lowerMasterChannel = newChannel;
                            });
                        }
                        Zynthian.KnobIndicator {
                            anchors {
                                left: parent.left
                                bottom: parent.bottom
                                margins: Kirigami.Units.smallSpacing
                            }
                            height: Kirigami.Units.iconSizes.smallMedium
                            width: Kirigami.Units.iconSizes.smallMedium
                            knobId: 0
                            visible: deviceComponentScroller.currentRow === firstDeviceSettingsRow
                        }
                    }
                    QQC2.Button {
                        Layout.fillWidth: true
                        visible: _private.selectedDeviceObject && _private.selectedDeviceObject.noteSplitPoint < 127
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        text: _private.selectedDeviceObject === null ? "" : qsTr("Upper Zone Master Channel:\nChannel %1").arg(_private.selectedDeviceObject.upperMasterChannel + 1)
                        onClicked: {
                            midiChannelPicker.pickMidiChannel(_private.selectedDeviceObject.upperMasterChannel, function(newChannel) {
                                _private.selectedDeviceObject.upperMasterChannel = newChannel;
                            });
                        }
                        Zynthian.KnobIndicator {
                            anchors {
                                left: parent.left
                                bottom: parent.bottom
                                margins: Kirigami.Units.smallSpacing
                            }
                            height: Kirigami.Units.iconSizes.smallMedium
                            width: Kirigami.Units.iconSizes.smallMedium
                            knobId: 1
                            visible: deviceComponentScroller.currentRow === firstDeviceSettingsRow
                        }
                    }
                    QQC2.Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        text: _private.selectedDeviceObject === null ? "" : _private.selectedDeviceObject.sendTimecode ? qsTr("Send MIDI Timecode (24 PPQN):\nYes") : qsTr("Send MIDI Timecode (24 PPQN):\nNo")
                        onClicked: {
                            _private.selectedDeviceObject.sendTimecode = !_private.selectedDeviceObject.sendTimecode;
                        }
                        Zynthian.KnobIndicator {
                            anchors {
                                left: parent.left
                                bottom: parent.bottom
                                margins: Kirigami.Units.smallSpacing
                            }
                            height: Kirigami.Units.iconSizes.smallMedium
                            width: Kirigami.Units.iconSizes.smallMedium
                            knobId: 2
                            visible: deviceComponentScroller.currentRow === firstDeviceSettingsRow
                        }
                    }
                }
                RowLayout {
                    id: secondDeviceSettingsRow
                    function goNext() { deviceComponentScroller.currentRow = addNewInputFilterButton; }
                    function goPrevious() { deviceComponentScroller.currentRow = firstDeviceSettingsRow; }
                    function knob0up() {
                        _private.selectedDeviceObject.noteSplitPoint = Math.min(127, _private.selectedDeviceObject.noteSplitPoint + 1);
                        // when setting this, force the lower and upper zone master channels to 0 and 15 respectively, to match the standard mpe zone setup
                        _private.selectedDeviceObject.lowerMasterChannel = 0;
                        _private.selectedDeviceObject.upperMasterChannel = 15;
                    }
                    function knob0down() {
                        _private.selectedDeviceObject.noteSplitPoint = Math.max(0, _private.selectedDeviceObject.noteSplitPoint - 1);
                        // when setting this, force the lower and upper zone master channels to 0 and 15 respectively, to match the standard mpe zone setup
                        _private.selectedDeviceObject.lowerMasterChannel = 0;
                        _private.selectedDeviceObject.upperMasterChannel = 15;
                    }
                    function knob1up() {
                        if (_private.selectedDeviceObject.noteSplitPoint < 127) {
                            _private.selectedDeviceObject.lastLowerZoneMemberChannel = Math.min(15, _private.selectedDeviceObject.lastLowerZoneMemberChannel + 1);
                        }
                    }
                    function knob1down() {
                        if (_private.selectedDeviceObject.noteSplitPoint < 127) {
                            _private.selectedDeviceObject.lastLowerZoneMemberChannel = Math.max(0, _private.selectedDeviceObject.lastLowerZoneMemberChannel - 1);
                        }
                    }
                    function knob2up() {
                        _private.selectedDeviceObject.sendBeatClock = true;
                    }
                    function knob2down() {
                        _private.selectedDeviceObject.sendBeatClock = false;
                    }
                    Layout.fillWidth: true
                    QQC2.Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        text: _private.selectedDeviceObject === null ? "" : qsTr("Last Note In Lower Split:\n%1").arg(Zynthbox.KeyScales.midiNoteName(_private.selectedDeviceObject.noteSplitPoint))
                        onClicked: {
                            notePicker.pickNote(_private.selectedDeviceObject.noteSplitPoint, function(newNote) {
                                _private.selectedDeviceObject.noteSplitPoint = newNote;
                                // when setting this, force the lower and upper zone master channels to 0 and 15 respectively, to match the standard mpe zone setup
                                _private.selectedDeviceObject.lowerMasterChannel = 0;
                                _private.selectedDeviceObject.upperMasterChannel = 15;
                            });
                        }
                        Zynthian.KnobIndicator {
                            anchors {
                                left: parent.left
                                bottom: parent.bottom
                                margins: Kirigami.Units.smallSpacing
                            }
                            height: Kirigami.Units.iconSizes.smallMedium
                            width: Kirigami.Units.iconSizes.smallMedium
                            knobId: 0
                            visible: deviceComponentScroller.currentRow === secondDeviceSettingsRow
                        }
                    }
                    QQC2.Button {
                        Layout.fillWidth: true
                        visible: _private.selectedDeviceObject && _private.selectedDeviceObject.noteSplitPoint < 127
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        text: _private.selectedDeviceObject === null ? "" : qsTr("Lower Zone Last Member Channel:\nChannel %1").arg(_private.selectedDeviceObject.lastLowerZoneMemberChannel + 1)
                        onClicked: {
                            midiChannelPicker.pickMidiChannel(_private.selectedDeviceObject.lastLowerZoneMemberChannel, function(newChannel) {
                                _private.selectedDeviceObject.lastLowerZoneMemberChannel = newChannel;
                            });
                        }
                        Zynthian.KnobIndicator {
                            anchors {
                                left: parent.left
                                bottom: parent.bottom
                                margins: Kirigami.Units.smallSpacing
                            }
                            height: Kirigami.Units.iconSizes.smallMedium
                            width: Kirigami.Units.iconSizes.smallMedium
                            knobId: 1
                            visible: deviceComponentScroller.currentRow === secondDeviceSettingsRow
                        }
                    }
                    QQC2.Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        text: _private.selectedDeviceObject === null ? "" : _private.selectedDeviceObject.sendBeatClock ? qsTr("Send MIDI Beat Clock:\nYes") : qsTr("Send MIDI Beat Clock:\nNo")
                        onClicked: {
                            _private.selectedDeviceObject.sendBeatClock = !_private.selectedDeviceObject.sendBeatClock;
                        }
                        Zynthian.KnobIndicator {
                            anchors {
                                left: parent.left
                                bottom: parent.bottom
                                margins: Kirigami.Units.smallSpacing
                            }
                            height: Kirigami.Units.iconSizes.smallMedium
                            width: Kirigami.Units.iconSizes.smallMedium
                            knobId: 2
                            visible: deviceComponentScroller.currentRow === secondDeviceSettingsRow
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Kirigami.Heading {
                        Layout.fillWidth: true
                        level: 2
                        text: qsTr("Input Filters")
                    }
                    QQC2.Button {
                        id: addNewInputFilterButton
                        function goNext() {
                            if (inputFiltersRepeater.count === 0) {
                                deviceComponentScroller.currentRow = pickTrackForAllChannelsButton;
                            } else {
                                deviceComponentScroller.currentRow = inputFiltersRepeater.itemAt(0);
                                inputFiltersRepeater.currentlySelectedFilter = deviceComponentScroller.currentRow.filterObject;
                            }
                        }
                        function goPrevious() { deviceComponentScroller.currentRow = secondDeviceSettingsRow; }
                        function selectPressed() { onClicked(); }
                        text: qsTr("Add new input filter")
                        onClicked: {
                            let newEntry = _private.selectedDeviceObject.inputEventFilter.createEntry();
                            let newEntryIndex = _private.selectedDeviceObject.inputEventFilter.indexOf(newEntry);
                            _private.selectedInputFilterIndex = newEntryIndex;
                            contentStack.push(inputFilterComponent);
                        }
                        checked: deviceComponentScroller.currentRow === addNewInputFilterButton
                    }
                }
                Connections {
                    target: _private.selectedDeviceObject ? _private.selectedDeviceObject.inputEventFilter : null
                    onEntriesChanged: {
                        // console.log("Things match, currently selected filter is", inputFiltersRepeater.currentlySelectedFilter);
                        if (inputFiltersRepeater.currentlySelectedFilter !== null) {
                            // This is only likely to happen when an input filter is added, removed, or moved
                            let selectedIndex = _private.selectedDeviceObject.inputEventFilter.entries.indexOf(inputFiltersRepeater.currentlySelectedFilter);
                            // console.log(inputFiltersRepeater.currentlySelectedFilter, selectedIndex);
                            if (selectedIndex === -1) {
                                deviceComponentScroller.currentRow = addNewInputFilterButton;
                                inputFiltersRepeater.currentlySelectedFilter = null;
                            } else {
                                deviceComponentScroller.currentRow = inputFiltersRepeater.itemAt(selectedIndex);
                            }
                        }
                    }
                }
                Repeater {
                    id: inputFiltersRepeater
                    model: _private.selectedDeviceObject ? _private.selectedDeviceObject.inputEventFilter.entries : 0
                    property QtObject currentlySelectedFilter: null
                    delegate: RowLayout {
                        id: inputFiltersRepeaterDelegate
                        readonly property QtObject filterObject: modelData
                        function goNext() {
                            if (model.index === inputFiltersRepeater.count - 1) {
                                deviceComponentScroller.currentRow = pickTrackForAllChannelsButton;
                                inputFiltersRepeater.currentlySelectedFilter = null;
                            } else {
                                deviceComponentScroller.currentRow = inputFiltersRepeater.itemAt(model.index + 1);
                                inputFiltersRepeater.currentlySelectedFilter = modelData;
                            }
                        }
                        function goPrevious() {
                            if (model.index === 0) {
                                deviceComponentScroller.currentRow = addNewInputFilterButton;
                                inputFiltersRepeater.currentlySelectedFilter = null;
                            } else {
                                deviceComponentScroller.currentRow = inputFiltersRepeater.itemAt(model.index - 1);
                                inputFiltersRepeater.currentlySelectedFilter = modelData;
                            }
                        }
                        function knob0up() {
                            if (model.index < inputFiltersRepeater.count - 1) {
                                _private.selectedDeviceObject.inputEventFilter.swap(modelData, _private.selectedDeviceObject.inputEventFilter.entries[model.index + 1]);
                            }
                        }
                        function knob0down() {
                            if (model.index > 0) {
                                _private.selectedDeviceObject.inputEventFilter.swap(_private.selectedDeviceObject.inputEventFilter.entries[model.index - 1], modelData);
                            }
                        }
                        function selectPressed() {
                                _private.selectedInputFilterIndex = model.index;
                                contentStack.push(inputFilterComponent);
                        }
                        Layout.fillWidth: true
                        QQC2.Button {
                            Layout.fillWidth: false
                            Layout.minimumWidth: height
                            Layout.maximumWidth: height
                            display: QQC2.AbstractButton.IconOnly
                            icon.name: "edit-delete"
                            onClicked: {
                                deviceComponentScroller.currentRow = parent;
                                inputFiltersRepeater.currentlySelectedFilter = modelData;
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: "Filter %1:\n%2".arg(model.index + 1).arg(modelData.description)
                        }
                        QQC2.Button {
                            Layout.fillWidth: false
                            Layout.minimumWidth: height
                            Layout.maximumWidth: height
                            display: QQC2.AbstractButton.IconOnly
                            icon.name: "go-up"
                            enabled: model.index > 0
                            onClicked: {
                                deviceComponentScroller.currentRow = parent;
                                inputFiltersRepeater.currentlySelectedFilter = modelData;
                                inputFiltersRepeaterDelegate.knob0up();
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: false
                            Layout.minimumWidth: height
                            Layout.maximumWidth: height
                            display: QQC2.AbstractButton.IconOnly
                            icon.name: "go-down"
                            enabled: model.index < inputFiltersRepeater.count - 1
                            onClicked: {
                                deviceComponentScroller.currentRow = parent;
                                inputFiltersRepeater.currentlySelectedFilter = modelData;
                                inputFiltersRepeaterDelegate.knob0down();
                            }
                            Zynthian.KnobIndicator {
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    horizontalCenter: parent.left
                                    leftMargin: -inputFiltersRepeaterDelegate.spacing / 2
                                }
                                height: Kirigami.Units.iconSizes.smallMedium
                                width: Kirigami.Units.iconSizes.smallMedium
                                knobId: 0
                                visible: deviceComponentScroller.currentRow === inputFiltersRepeaterDelegate
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: false
                            Layout.minimumWidth: height
                            Layout.maximumWidth: height
                            display: QQC2.AbstractButton.IconOnly
                            icon.name: "document-edit"
                            onClicked: {
                                deviceComponentScroller.currentRow = parent;
                                inputFiltersRepeater.currentlySelectedFilter = modelData;
                                inputFiltersRepeaterDelegate.selectPressed();
                            }
                            checked: deviceComponentScroller.currentRow === inputFiltersRepeaterDelegate
                        }
                    }
                }
                RowLayout {
                    id: inputFiltersFallbackRow
                    Layout.fillWidth: true
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: qsTr("Send unfiltered events to:")
                    }
                    QQC2.Button {
                        id: pickTrackForAllChannelsButton
                        function goNext() { deviceComponentScroller.currentRow = midiChannelTargetTrackRepeater.itemAt(0); }
                        function goPrevious() {
                            if (inputFiltersRepeater.count === 0) {
                                deviceComponentScroller.currentRow = addNewInputFilterButton;
                            } else {
                                deviceComponentScroller.currentRow = inputFiltersRepeater.itemAt(inputFiltersRepeater.count - 1);
                                    inputFiltersRepeater.currentlySelectedFilter = deviceComponentScroller.currentRow.filterObject;
                            }
                        }
                        function selectPressed() { onClicked(); }
                        text: qsTr("Pick track for all channels...")
                        onClicked: {
                            trackPicker.pickTrack(Zynthbox.ZynthboxBasics.CurrentTrack, function(newTrack){
                                _private.selectedDeviceObject.setMidiChannelTargetTrack(-1, newTrack);
                            });
                        }
                        checked: deviceComponentScroller.currentRow === pickTrackForAllChannelsButton
                    }
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 8
                    Repeater {
                        id: midiChannelTargetTrackRepeater
                        model: 16
                        QQC2.Button {
                            id: midiChannelTargetTrackRepeaterDelegate
                            function goNext() {
                                if (model.index === 15) {
                                    deviceComponentScroller.currentRow = addOutputFilterButton;
                                } else {
                                    deviceComponentScroller.currentRow = midiChannelTargetTrackRepeater.itemAt(model.index + 1);
                                }
                            }
                            function goPrevious() {
                                if (model.index === 0) {
                                    deviceComponentScroller.currentRow = pickTrackForAllChannelsButton;
                                } else {
                                    deviceComponentScroller.currentRow = midiChannelTargetTrackRepeater.itemAt(model.index - 1);
                                }
                            }
                            function selectPressed() { onClicked(); }
                            Layout.preferredWidth: Kirigami.Units.gridUnit
                            Layout.fillWidth: true
                            text: _private.selectedDeviceObject === null
                                ? ""
                                : qsTr("Channel %1:\n%2").arg(model.index + 1).arg(Zynthbox.ZynthboxBasics.trackLabelText(_private.selectedDeviceObject.midiChannelTargetTracks[model.index]))
                            onClicked: {
                                trackPicker.pickTrack(_private.selectedDeviceObject.midiChannelTargetTracks[model.index], function(newTrack){
                                    _private.selectedDeviceObject.setMidiChannelTargetTrack(model.index, newTrack);
                                });
                            }
                            checked: deviceComponentScroller.currentRow === midiChannelTargetTrackRepeaterDelegate
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Kirigami.Heading {
                        Layout.fillWidth: true
                        level: 2
                        text: qsTr("Output Filters")
                    }
                    QQC2.Button {
                        id: addOutputFilterButton
                        function goNext() {
                            if (outputFiltersRepeater.count === 0) {
                                deviceComponentScroller.currentRow = enableAllOutputChannelsButton;
                            } else {
                                deviceComponentScroller.currentRow = outputFiltersRepeater.itemAt(0);
                                inputFiltersRepeater.currentlySelectedFilter = deviceComponentScroller.currentRow.filterObject;
                            }
                        }
                        function goPrevious() { deviceComponentScroller.currentRow = midiChannelTargetTrackRepeater.itemAt(15); }
                        function selectPressed() { onClicked(); }
                        text: qsTr("Add new output filter")
                        onClicked: {
                            let newEntry = _private.selectedDeviceObject.outputEventFilter.createEntry();
                            let newEntryIndex = _private.selectedDeviceObject.outputEventFilter.indexOf(newEntry);
                            _private.selectedOutputFilterIndex = newEntryIndex;
                            contentStack.push(outputFilterComponent);
                        }
                        checked: deviceComponentScroller.currentRow === addOutputFilterButton
                    }
                }
                Connections {
                    target: _private.selectedDeviceObject ? _private.selectedDeviceObject.outputEventFilter : null
                    onEntriesChanged: {
                        if (currentlySelectedFilter !== null) {
                            // This is only likely to happen when an output filter is added, removed, or moved
                            let selectedIndex = _private.selectedDeviceObject.outputEventFilter.entries.indexOf(currentlySelectedFilter);
                            if (selectedIndex === -1) {
                                deviceComponentScroller.currentRow = addNewOutputFilterButton;
                                outputFiltersRepeater.currentlySelectedFilter = null;
                            } else {
                                deviceComponentScroller.currentRow = outputFiltersRepeater.itemAt(selectedIndex);
                            }
                        }
                    }
                }
                Repeater {
                    id: outputFiltersRepeater
                    model: _private.selectedDeviceObject ? _private.selectedDeviceObject.outputEventFilter.entries : 0
                    property QtObject currentlySelectedFilter: null
                    delegate: RowLayout {
                        id: outputFiltersRepeaterDelegate
                        readonly property QtObject filterObject: modelData
                        function goNext() {
                            if (model.index === outputFiltersRepeater.count - 1) {
                                deviceComponentScroller.currentRow = enableAllOutputChannelsButton;
                                inputFiltersRepeater.currentlySelectedFilter = null;
                            } else {
                                deviceComponentScroller.currentRow = outputFiltersRepeater.itemAt(model.index + 1);
                                inputFiltersRepeater.currentlySelectedFilter = modelData;
                            }
                        }
                        function goPrevious() {
                            if (model.index === 0) {
                                deviceComponentScroller.currentRow = addOutputFilterButton;
                                inputFiltersRepeater.currentlySelectedFilter = null;
                            } else {
                                deviceComponentScroller.currentRow = outputFiltersRepeater.itemAt(model.index - 1);
                                inputFiltersRepeater.currentlySelectedFilter = modelData;
                            }
                        }
                        function knob0up() {
                            if (model.index < outputFiltersRepeater.count - 1) {
                                _private.selectedDeviceObject.outputEventFilter.swap(modelData, _private.selectedDeviceObject.outputEventFilter.entries[model.index + 1]);
                            }
                        }
                        function knob0down() {
                            if (model.index > 0) {
                                _private.selectedDeviceObject.outputEventFilter.swap(_private.selectedDeviceObject.outputEventFilter.entries[model.index - 1], modelData);
                            }
                        }
                        function selectPressed() {
                            _private.selectedOutputFilterIndex = model.index;
                            contentStack.push(outputFilterComponent);
                        }
                        Layout.fillWidth: true
                        QQC2.Button {
                            Layout.fillWidth: false
                            Layout.minimumWidth: height
                            Layout.maximumWidth: height
                            display: QQC2.AbstractButton.IconOnly
                            icon.name: "edit-delete"
                            onClicked: {
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: "Filter %1:\n%2".arg(model.index + 1).arg(modelData.description)
                        }
                        QQC2.Button {
                            Layout.fillWidth: false
                            Layout.minimumWidth: height
                            Layout.maximumWidth: height
                            display: QQC2.AbstractButton.IconOnly
                            icon.name: "go-up"
                            enabled: model.index > 0
                            onClicked: {
                                outputFiltersRepeaterDelegate.knob0up();
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: false
                            Layout.minimumWidth: height
                            Layout.maximumWidth: height
                            display: QQC2.AbstractButton.IconOnly
                            icon.name: "go-down"
                            enabled: model.index < outputFiltersRepeater.count - 1
                            onClicked: {
                                outputFiltersRepeaterDelegate.knob0down();
                            }
                            Zynthian.KnobIndicator {
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    horizontalCenter: parent.left
                                    leftMargin: -outputFiltersRepeaterDelegate.spacing / 2
                                }
                                height: Kirigami.Units.iconSizes.smallMedium
                                width: Kirigami.Units.iconSizes.smallMedium
                                knobId: 0
                                visible: deviceComponentScroller.currentRow === outputFiltersRepeaterDelegate
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: false
                            Layout.minimumWidth: height
                            Layout.maximumWidth: height
                            display: QQC2.AbstractButton.IconOnly
                            icon.name: "document-edit"
                            onClicked: {
                                outputFiltersRepeaterDelegate.selectPressed();
                            }
                            checked: deviceComponentScroller.currentRow === outputFiltersRepeaterDelegate
                        }
                    }
                }
                RowLayout {
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: qsTr("The device accepts events on channels:")
                    }
                    QQC2.Button {
                        id: enableAllOutputChannelsButton
                        function goNext() { deviceComponentScroller.currentRow = disableAllOutputChannelsButton; }
                        function goPrevious() {
                            if (outputFiltersRepeater.count === 0) {
                                deviceComponentScroller.currentRow = addOutputFilterButton;
                            } else {
                                deviceComponentScroller.currentRow = outputFiltersRepeater.itemAt(outputFiltersRepeater.count - 1);
                                outputFiltersRepeater.currentlySelectedFilter = deviceComponentScroller.currentRow.filterObject;
                            }
                        }
                        function selectPressed() { onClicked(); }
                        text: qsTr("Enable All")
                        onClicked: {
                            _private.selectedDeviceObject.setSendToChannels([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], true);
                        }
                        checked: deviceComponentScroller.currentRow === enableAllOutputChannelsButton
                    }
                    QQC2.Button {
                        id: disableAllOutputChannelsButton
                        function goNext() { deviceComponentScroller.currentRow = outputChannelTogglesRepeater.itemAt(0); }
                        function goPrevious() { deviceComponentScroller.currentRow = enableAllOutputChannelsButton; }
                        function selectPressed() { onClicked(); }
                        text: qsTr("Disable All")
                        onClicked: {
                            _private.selectedDeviceObject.setSendToChannels([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], false);
                        }
                        checked: deviceComponentScroller.currentRow === disableAllOutputChannelsButton
                    }
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 8
                    Repeater {
                        id: outputChannelTogglesRepeater
                        model: 16
                        QQC2.Button {
                            id: outputChannelTogglesRepeaterDelegate
                            function goNext() {
                                if (model.index < 15) {
                                    deviceComponentScroller.currentRow = outputChannelTogglesRepeater.itemAt(model.index + 1);
                                }
                            }
                            function goPrevious() {
                                if (model.index === 0) {
                                    deviceComponentScroller.currentRow = disableAllOutputChannelsButton;
                                } else {
                                    deviceComponentScroller.currentRow = outputChannelTogglesRepeater.itemAt(model.index - 1);
                                }
                            }
                            function selectPressed() { onClicked(); }
                            function knob0up() {
                                _private.selectedDeviceObject.setSendToChannels([model.index], true);
                            }
                            function knob0down() {
                                _private.selectedDeviceObject.setSendToChannels([model.index], false);
                            }
                            Layout.preferredWidth: Kirigami.Units.gridUnit
                            Layout.fillWidth: true
                            text: _private.selectedDeviceObject === null
                                ? ""
                                : _private.selectedDeviceObject.channelsToSendTo[model.index]
                                    ? qsTr("Channel %1:\nYes").arg(model.index + 1)
                                    : qsTr("Channel %1:\nNo").arg(model.index + 1)
                            onClicked: {
                                _private.selectedDeviceObject.setSendToChannels([model.index], !_private.selectedDeviceObject.channelsToSendTo[model.index]);
                            }
                            Zynthian.KnobIndicator {
                                anchors {
                                    left: parent.left
                                    bottom: parent.bottom
                                    margins: Kirigami.Units.smallSpacing
                                }
                                height: Kirigami.Units.iconSizes.smallMedium
                                width: Kirigami.Units.iconSizes.smallMedium
                                knobId: 0
                                visible: deviceComponentScroller.currentRow === outputChannelTogglesRepeaterDelegate
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: inputFilterComponent
        Item {
            function cuiaCallback(cuia) {
                let result = false;
                switch (cuia) {
                    case "SWITCH_BACK_SHORT":
                    case "SWITCH_BACK_BOLD":
                    case "SWITCH_BACK_LONG":
                        contentStack.pop();
                        returnValue = true;
                        break;
                    default:
                        break;
                }
                return result;
            }
        }
    }

    Component {
        id: inputFilterRuleComponent
        Item {
            function cuiaCallback(cuia) {
                let result = false;
                switch (cuia) {
                    case "SWITCH_BACK_SHORT":
                    case "SWITCH_BACK_BOLD":
                    case "SWITCH_BACK_LONG":
                        contentStack.pop();
                        returnValue = true;
                        break;
                    default:
                        break;
                }
                return result;
            }}
    }

    Component {
        id: outputFilterComponent
        Item {
            function cuiaCallback(cuia) {
                let result = false;
                switch (cuia) {
                    case "SWITCH_BACK_SHORT":
                    case "SWITCH_BACK_BOLD":
                    case "SWITCH_BACK_LONG":
                        contentStack.pop();
                        returnValue = true;
                        break;
                    default:
                        break;
                }
                return result;
            }}
    }

    Component {
        id: outputFilterRuleComponent
        Item {
            function cuiaCallback(cuia) {
                let result = false;
                switch (cuia) {
                    case "SWITCH_BACK_SHORT":
                    case "SWITCH_BACK_BOLD":
                    case "SWITCH_BACK_LONG":
                        contentStack.pop();
                        returnValue = true;
                        break;
                    default:
                        break;
                }
                return result;
            }}
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

    Zynthian.NotePickerPopup {
        id: notePicker
    }
}
