/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Settings page for Midi Controllers - Individual Device Display

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

QQC2.ScrollView {
    id: component
    property QtObject containingPage
    property QtObject _private
    clip: true
    contentWidth: availableWidth
    readonly property QtObject actionPicker: deviceActionPicker
    function cuiaCallback(cuia) {
        let result = false;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
                contentStack.pop();
                returnValue = true;
                break;
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
                if (component.currentRow.selectPressed) {
                    component.currentRow.selectPressed();
                }
                break;
            case "KNOB0_UP":
                if (component.currentRow.knob0up) {
                    component.currentRow.knob0up();
                }
                break;
            case "KNOB0_DOWN":
                if (component.currentRow.knob0down) {
                    component.currentRow.knob0down();
                }
                break;
            case "KNOB1_UP":
                if (component.currentRow.knob1up) {
                    component.currentRow.knob1up();
                }
                break;
            case "KNOB1_DOWN":
                if (component.currentRow.knob1down) {
                    component.currentRow.knob1down();
                }
                break;
            case "KNOB2_UP":
                if (component.currentRow.knob2up) {
                    component.currentRow.knob2up();
                }
                break;
            case "KNOB2_DOWN":
                if (component.currentRow.knob2down) {
                    component.currentRow.knob2down();
                }
                break;
            case "KNOB3_UP": {
                currentRow.goNext();
                let mappedY = component.currentRow.y;
                let theParent = component.currentRow.parent;
                while (theParent !== deviceComponentContent) {
                    mappedY = mappedY + theParent.y;
                    theParent = theParent.parent;
                }
                component.contentItem.contentY = (deviceComponentContent.height - component.height) * ((component.currentRow.height * (mappedY / deviceComponentContent.height)) + mappedY) / deviceComponentContent.height;
                returnValue = true;
                break;
            }
            case "KNOB3_DOWN": {
                currentRow.goPrevious();
                let mappedY = component.currentRow.y;
                let theParent = component.currentRow.parent;
                while (theParent !== deviceComponentContent) {
                    mappedY = mappedY + theParent.y;
                    theParent = theParent.parent;
                }
                component.contentItem.contentY = (deviceComponentContent.height - component.height) * ((component.currentRow.height * (mappedY / deviceComponentContent.height)) + mappedY) / deviceComponentContent.height;
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
        width: component.contentWidth - component.QQC2.ScrollBar.vertical.width
        Component {
            id: inputFilterComponent
            MidiControllerSettingsInputFilter {}
        }
        Component {
            id: outputFilterComponent
            MidiControllerSettingsOutputFilter {}
        }
        RowLayout {
            id: deviceComponentHeader
            function goNext() { component.currentRow = firstDeviceSettingsRow; }
            function goPrevious() {}
            Kirigami.Heading {
                Layout.fillWidth: true
                text: _private.selectedDeviceObject === null ? "" : qsTr("%1 Settings").arg(_private.selectedDeviceObject.humanReadableName)
            }
        }
        RowLayout {
            id: firstDeviceSettingsRow
            function goNext() { component.currentRow = secondDeviceSettingsRow; }
            function goPrevious() { component.currentRow = deviceComponentHeader; }
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
                text: _private.selectedDeviceObject === null
                    ? ""
                    : _private.selectedDeviceObject.noteSplitPoint < 127
                        ? qsTr("Device Master Channel:\nChannel %1").arg(_private.selectedDeviceObject.lowerMasterChannel + 1)
                        : qsTr("Lower Zone Master Channel:\nChannel %1").arg(_private.selectedDeviceObject.lowerMasterChannel + 1)
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
                    visible: component.currentRow === firstDeviceSettingsRow
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
                    visible: component.currentRow === firstDeviceSettingsRow
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                text: _private.selectedDeviceObject === null ? "" : _private.selectedDeviceObject.sendTimecode ? qsTr("Send MIDI Timecode:\nYes") : qsTr("Send MIDI Timecode:\nNo")
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
                    visible: component.currentRow === firstDeviceSettingsRow
                }
            }
        }
        RowLayout {
            id: secondDeviceSettingsRow
            function goNext() { component.currentRow = addNewInputFilterButton; }
            function goPrevious() { component.currentRow = firstDeviceSettingsRow; }
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
                    applicationWindow().pickNote(_private.selectedDeviceObject.noteSplitPoint, function(newNote) {
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
                    visible: component.currentRow === secondDeviceSettingsRow
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
                    visible: component.currentRow === secondDeviceSettingsRow
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                text: _private.selectedDeviceObject === null ? "" : _private.selectedDeviceObject.sendBeatClock ? qsTr("Send MIDI Beat Clock (24 PPQN):\nYes") : qsTr("Send MIDI Beat Clock (24 PPQN):\nNo")
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
                    visible: component.currentRow === secondDeviceSettingsRow
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
                        component.currentRow = pickTrackForAllChannelsButton;
                    } else {
                        component.currentRow = inputFiltersRepeater.itemAt(0);
                        inputFiltersRepeater.currentlySelectedFilter = component.currentRow.filterObject;
                    }
                }
                function goPrevious() { component.currentRow = secondDeviceSettingsRow; }
                function selectPressed() { onClicked(); }
                text: qsTr("Add new input filter")
                onClicked: {
                    let newEntry = _private.selectedDeviceObject.inputEventFilter.createEntry();
                    let newEntryIndex = _private.selectedDeviceObject.inputEventFilter.indexOf(newEntry);
                    _private.selectedInputFilterIndex = newEntryIndex;
                    contentStack.push(inputFilterComponent, { containingPage: component.containingPage, _private: component._private });
                }
                checked: component.currentRow === addNewInputFilterButton
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
                        component.currentRow = addNewInputFilterButton;
                        inputFiltersRepeater.currentlySelectedFilter = null;
                    } else {
                        component.currentRow = inputFiltersRepeater.itemAt(selectedIndex);
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
                        component.currentRow = pickTrackForAllChannelsButton;
                        inputFiltersRepeater.currentlySelectedFilter = null;
                    } else {
                        component.currentRow = inputFiltersRepeater.itemAt(model.index + 1);
                        inputFiltersRepeater.currentlySelectedFilter = modelData;
                    }
                }
                function goPrevious() {
                    if (model.index === 0) {
                        component.currentRow = addNewInputFilterButton;
                        inputFiltersRepeater.currentlySelectedFilter = null;
                    } else {
                        component.currentRow = inputFiltersRepeater.itemAt(model.index - 1);
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
                        contentStack.push(inputFilterComponent, { containingPage: component.containingPage, _private: component._private });
                }
                Layout.fillWidth: true
                QQC2.Button {
                    Layout.fillWidth: false
                    Layout.minimumWidth: height
                    Layout.maximumWidth: height
                    display: QQC2.AbstractButton.IconOnly
                    icon.name: "edit-delete"
                    onClicked: {
                        component.currentRow = parent;
                        inputFiltersRepeater.currentlySelectedFilter = modelData;
                        confirmer.confirmSomething(qsTr("Delete Input Filter?"), qsTr("Are you sure that you want to delete input filter %1:\n%2").arg(model.index + 1).arg(modelData.description), function() {
                            _private.selectedDeviceObject.inputEventFilter.deleteEntry(model.index);
                        });
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
                        component.currentRow = parent;
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
                        component.currentRow = parent;
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
                        visible: component.currentRow === inputFiltersRepeaterDelegate
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: false
                    Layout.minimumWidth: height
                    Layout.maximumWidth: height
                    display: QQC2.AbstractButton.IconOnly
                    icon.name: "document-edit"
                    onClicked: {
                        component.currentRow = parent;
                        inputFiltersRepeater.currentlySelectedFilter = modelData;
                        inputFiltersRepeaterDelegate.selectPressed();
                    }
                    checked: component.currentRow === inputFiltersRepeaterDelegate
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
                function goNext() {
                    if (_private.selectedDeviceObject.noteSplitPoint === 127) {
                        component.currentRow = midiChannelTargetTrackRepeater.itemAt(0);
                    } else {
                        component.currentRow = pickTrackForUpperZoneButton;
                    }
                }
                function goPrevious() {
                    if (inputFiltersRepeater.count === 0) {
                        component.currentRow = addNewInputFilterButton;
                    } else {
                        component.currentRow = inputFiltersRepeater.itemAt(inputFiltersRepeater.count - 1);
                            inputFiltersRepeater.currentlySelectedFilter = component.currentRow.filterObject;
                    }
                }
                function selectPressed() { onClicked(); }
                text: _private.selectedDeviceObject.noteSplitPoint === 127 ? qsTr("Pick track for all channels...") : qsTr("Pick track for lower zone...")
                onClicked: {
                    let currentBestGuess = _private.selectedDeviceObject.midiChannelTargetTracks[0];
                    let lastLowerZoneMemberChannel = _private.selectedDeviceObject.noteSplitPoint === 127 ? 16 : _private.selectedDeviceObject.lastLowerZoneMemberChannel + 1;
                    for (let midiChannel = 0; midiChannel < lastLowerZoneMemberChannel; ++midiChannel) {
                        if (currentBestGuess != _private.selectedDeviceObject.midiChannelTargetTracks[midiChannel]) {
                            // If we come across anything that doesn't match the rest, default to current track and bail out
                            currentBestGuess = Zynthbox.ZynthboxBasics.CurrentTrack;
                            break;
                        }
                    }
                    trackPicker.pickTrack(currentBestGuess, function(newTrack){
                        let lastLowerZoneMemberChannel = _private.selectedDeviceObject.noteSplitPoint === 127 ? 16 : _private.selectedDeviceObject.lastLowerZoneMemberChannel + 1;
                        for (let midiChannel = 0; midiChannel < lastLowerZoneMemberChannel; ++midiChannel) {
                            _private.selectedDeviceObject.setMidiChannelTargetTrack(midiChannel, newTrack);
                        }
                    });
                }
                checked: component.currentRow === pickTrackForAllChannelsButton
            }
            QQC2.Button {
                id: pickTrackForUpperZoneButton
                function goNext() { component.currentRow = midiChannelTargetTrackRepeater.itemAt(0); }
                function goPrevious() { component.currentRow = pickTrackForAllChannelsButton; }
                function selectPressed() { onClicked(); }
                visible: _private.selectedDeviceObject.noteSplitPoint < 127
                text: qsTr("Pick track for upper zone...")
                onClicked: {
                    if (_private.selectedDeviceObject.noteSplitPoint < 127) {
                        let currentBestGuess = _private.selectedDeviceObject.midiChannelTargetTracks[15];
                        for (let midiChannel = _private.selectedDeviceObject.lastLowerZoneMemberChannel + 1; midiChannel < 16; ++midiChannel) {
                            if (currentBestGuess != _private.selectedDeviceObject.midiChannelTargetTracks[midiChannel]) {
                                // If we come across anything that doesn't match the rest, default to current track and bail out
                                currentBestGuess = Zynthbox.ZynthboxBasics.CurrentTrack;
                                break;
                            }
                        }
                        trackPicker.pickTrack(currentBestGuess, function(newTrack){
                            for (let midiChannel = _private.selectedDeviceObject.lastLowerZoneMemberChannel + 1; midiChannel < 16; ++midiChannel) {
                                _private.selectedDeviceObject.setMidiChannelTargetTrack(midiChannel, newTrack);
                            }
                        });
                    }
                }
                checked: component.currentRow === pickTrackForUpperZoneButton
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
                            component.currentRow = addOutputFilterButton;
                        } else {
                            component.currentRow = midiChannelTargetTrackRepeater.itemAt(model.index + 1);
                        }
                    }
                    function goPrevious() {
                        if (model.index === 0) {
                            if (_private.selectedDeviceObject.noteSplitPoint === 127) {
                                component.currentRow = pickTrackForAllChannelsButton;
                            } else {
                                component.currentRow = pickTrackForUpperZoneButton;
                            }
                        } else {
                            component.currentRow = midiChannelTargetTrackRepeater.itemAt(model.index - 1);
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
                    checked: component.currentRow === midiChannelTargetTrackRepeaterDelegate
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
                        component.currentRow = enableAllOutputChannelsButton;
                    } else {
                        component.currentRow = outputFiltersRepeater.itemAt(0);
                        inputFiltersRepeater.currentlySelectedFilter = component.currentRow.filterObject;
                    }
                }
                function goPrevious() { component.currentRow = midiChannelTargetTrackRepeater.itemAt(15); }
                function selectPressed() { onClicked(); }
                text: qsTr("Add new output filter")
                onClicked: {
                    let newEntry = _private.selectedDeviceObject.outputEventFilter.createEntry();
                    let newEntryIndex = _private.selectedDeviceObject.outputEventFilter.indexOf(newEntry);
                    _private.selectedOutputFilterIndex = newEntryIndex;
                    contentStack.push(outputFilterComponent, { containingPage: component.containingPage, _private: component._private });
                }
                checked: component.currentRow === addOutputFilterButton
            }
        }
        Connections {
            target: _private.selectedDeviceObject ? _private.selectedDeviceObject.outputEventFilter : null
            onEntriesChanged: {
                if (outputFiltersRepeater.currentlySelectedFilter !== null) {
                    // This is only likely to happen when an output filter is added, removed, or moved
                    let selectedIndex = _private.selectedDeviceObject.outputEventFilter.entries.indexOf(outputFiltersRepeater.currentlySelectedFilter);
                    if (selectedIndex === -1) {
                        component.currentRow = addNewOutputFilterButton;
                        outputFiltersRepeater.currentlySelectedFilter = null;
                    } else {
                        component.currentRow = outputFiltersRepeater.itemAt(selectedIndex);
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
                        component.currentRow = enableAllOutputChannelsButton;
                        inputFiltersRepeater.currentlySelectedFilter = null;
                    } else {
                        component.currentRow = outputFiltersRepeater.itemAt(model.index + 1);
                        inputFiltersRepeater.currentlySelectedFilter = modelData;
                    }
                }
                function goPrevious() {
                    if (model.index === 0) {
                        component.currentRow = addOutputFilterButton;
                        inputFiltersRepeater.currentlySelectedFilter = null;
                    } else {
                        component.currentRow = outputFiltersRepeater.itemAt(model.index - 1);
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
                    contentStack.push(outputFilterComponent, { containingPage: component.containingPage, _private: component._private });
                }
                Layout.fillWidth: true
                QQC2.Button {
                    Layout.fillWidth: false
                    Layout.minimumWidth: height
                    Layout.maximumWidth: height
                    display: QQC2.AbstractButton.IconOnly
                    icon.name: "edit-delete"
                    onClicked: {
                        component.currentRow = parent;
                        outputFiltersRepeater.currentlySelectedFilter = modelData;
                        confirmer.confirmSomething(qsTr("Delete Output Filter?"), qsTr("Are you sure that you want to delete output filter %1:\n%2").arg(model.index + 1).arg(modelData.description), function() {
                            _private.selectedDeviceObject.outputEventFilter.deleteEntry(model.index);
                        });
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
                        visible: component.currentRow === outputFiltersRepeaterDelegate
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
                    checked: component.currentRow === outputFiltersRepeaterDelegate
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
                function goNext() { component.currentRow = disableAllOutputChannelsButton; }
                function goPrevious() {
                    if (outputFiltersRepeater.count === 0) {
                        component.currentRow = addOutputFilterButton;
                    } else {
                        component.currentRow = outputFiltersRepeater.itemAt(outputFiltersRepeater.count - 1);
                        outputFiltersRepeater.currentlySelectedFilter = component.currentRow.filterObject;
                    }
                }
                function selectPressed() { onClicked(); }
                text: qsTr("Enable All")
                onClicked: {
                    _private.selectedDeviceObject.setSendToChannels([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], true);
                }
                checked: component.currentRow === enableAllOutputChannelsButton
            }
            QQC2.Button {
                id: disableAllOutputChannelsButton
                function goNext() { component.currentRow = outputChannelTogglesRepeater.itemAt(0); }
                function goPrevious() { component.currentRow = enableAllOutputChannelsButton; }
                function selectPressed() { onClicked(); }
                text: qsTr("Disable All")
                onClicked: {
                    _private.selectedDeviceObject.setSendToChannels([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], false);
                }
                checked: component.currentRow === disableAllOutputChannelsButton
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
                            component.currentRow = outputChannelTogglesRepeater.itemAt(model.index + 1);
                        }
                    }
                    function goPrevious() {
                        if (model.index === 0) {
                            component.currentRow = disableAllOutputChannelsButton;
                        } else {
                            component.currentRow = outputChannelTogglesRepeater.itemAt(model.index - 1);
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
                        visible: component.currentRow === outputChannelTogglesRepeaterDelegate
                    }
                }
            }
        }
    }
    Zynthian.ActionPickerPopup {
        id: deviceActionPicker
        actions: [
            Kirigami.Action {
                text: qsTr("Load Device Settings...")
                onTriggered: {
                    deviceFilePickerDialog.pick(false);
                }
            },
            Kirigami.Action {
                text: qsTr("Save Device Settings...")
                onTriggered: {
                    deviceFilePickerDialog.pick(true);
                }
            },
            Kirigami.Action {
                text: qsTr("Send MPE Settings\nTo Device")
                onTriggered: {
                    component._private.selectedDeviceObject.sendMPESettingsToDevice();
                }
            }
        ]
    }
    Zynthian.FilePickerDialog {
        id: deviceFilePickerDialog

        function pick(save) {
            deviceFilePickerDialog.saveMode = save;
            deviceFilePickerDialog.folderModel.folder = "/zynthian/zynthian-my-data/device-settings/my-device-settings";
            deviceFilePickerDialog.open();
            if (save) {
                deviceFilePickerDialog.fileNameToSave = component._private.selectedDeviceObject.humanReadableName.replace(" ", "-");
            }
        }

        headerText: saveMode
            ? qsTr("Pick Save Location For The %1 Settings")
                .arg(component._private.selectedDeviceObject.humanReadableName)
            : qsTr("Pick Device Settings To Load For %1")
                .arg(component._private.selectedDeviceObject.humanReadableName)
        rootFolder: "/zynthian/zynthian-my-data/device-settings"
        folderModel {
            nameFilters: ["*.zynthbox.device"]
        }
        property QtObject clipToSave
        onAccepted: {
            if (deviceFilePickerDialog.saveMode === true) {
                let saveToPath = deviceFilePickerDialog.selectedFile.filePath;
                if (saveToPath.toLowerCase().endsWith(".zynthbox.device") === false) {
                    saveToPath = saveToPath + ".zynthbox.device";
                }
                if (component._private.selectedDeviceObject.saveDeviceSettings(saveToPath)) {
                    applicationWindow().showPassiveNotification(qsTr("Successfully saved settings"));
                } else {
                    applicationWindow().showPassiveNotification(qsTr("Failed to save settings - see logs for details"));
                }
            } else {
                if (component._private.selectedDeviceObject.loadDeviceSettings(deviceFilePickerDialog.selectedFile.filePath)) {
                    applicationWindow().showPassiveNotification(qsTr("Successfully loaded settings"));
                } else {
                    applicationWindow().showPassiveNotification(qsTr("Failed to load settings - see logs for details"));
                }
            }
        }
    }
}
