/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Default module for the External mode editor page

Copyright (C) 2022 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian

Zynthian.BaseExternalEditor {
    id: component

    cuiaCallback: function(cuia) {
        var returnValue = false;
        switch (cuia) {
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
                _private.selectPressed();
                returnValue = true;
                break;
            case "SELECT_UP":
                _private.goUp();
                returnValue = true;
                break;
            case "NAVIGATE_LEFT":
                _private.goLeft();
                returnValue = true;
                break;
            case "SELECT_DOWN":
                _private.goDown();
                returnValue = true;
                break;
            case "NAVIGATE_RIGHT":
                _private.goRight();
                returnValue = true;
                break;
            case "KNOB0_UP":
                _private.knob0Up();
                returnValue = true;
                break;
            case "KNOB0_DOWN":
                _private.knob0Down();
                returnValue = true;
                break;
            case "KNOB1_UP":
                _private.knob1Up();
                returnValue = true;
                break;
            case "KNOB1_DOWN":
                _private.knob1Down();
                returnValue = true;
                break;
            case "KNOB2_UP":
                _private.knob2Up();
                returnValue = true;
                break;
            case "KNOB2_DOWN":
                _private.knob2Down();
                returnValue = true;
                break;
            case "KNOB3_UP":
                _private.knob3Up();
                returnValue = true;
                break;
            case "KNOB3_DOWN":
                _private.knob3Down();
                returnValue = true;
                break;
        }
        return returnValue;
    }
    QtObject {
        id: _private
        property int currentColumn: 0
        property int currentPage: 0
        property QtObject sketchpadTrackController: component.selectedChannel ? Zynthbox.MidiRouter.getSketchpadTrackControllerDevice(component.selectedChannel.id) : null
        property QtObject sketchpadTrackExternalDevice: component.selectedChannel ? Zynthbox.MidiRouter.getSketchpadTrackExternalDevice(component.selectedChannel.id) : null
        function selectPressed() {
            if (_private.currentPage == 1) {
                requestIdentityButton.onClicked();
            }
        }
        function goUp() {
            _private.currentPage = Math.max(0, _private.currentPage - 1);
        }
        function goLeft() {
            _private.currentColumn = Math.max(0, _private.currentColumn - 1);
        }
        function goDown() {
            _private.currentPage = Math.min(1, _private.currentPage + 1);
        }
        function goRight() {
            _private.currentColumn = Math.min(3, _private.currentColumn + 1);
        }
        function knob0Up() {
            if (_private.currentPage == 0) {
                sendCCValueChange((currentColumn * 3), 1);
            } else {
                filterCutoffDial.value = Math.min(127, filterCutoffDial.value + 1);
                let theBytes = [0x3E, 0x0E, 0x7F, 0x20, waldorfLocationDial.value, 0x00, 0x3E, filterCutoffDial.value];
                let parameterChangeMessage = _private.sketchpadTrackExternalDevice.sysexHelper.createMessage(theBytes);
                _private.sketchpadTrackExternalDevice.sysexHelper.send(parameterChangeMessage);
            }
        }
        function knob0Down() {
            if (_private.currentPage == 0) {
                sendCCValueChange((currentColumn * 3), -1);
            } else {
                filterCutoffDial.value = Math.max(0, filterCutoffDial.value - 1);
                let theBytes = [0x3E, 0x0E, 0x7F, 0x20, waldorfLocationDial.value, 0x00, 0x3E, filterCutoffDial.value];
                let parameterChangeMessage = _private.sketchpadTrackExternalDevice.sysexHelper.createMessage(theBytes);
                _private.sketchpadTrackExternalDevice.sysexHelper.send(parameterChangeMessage);
            }
        }
        function knob1Up() {
            if (_private.currentPage == 0) {
                sendCCValueChange((currentColumn * 3), 1);
            } else {
                waldorfLocationDial.value = Math.min(7, waldorfLocationDial.value + 1);
            }
        }
        function knob1Down() {
            if (_private.currentPage == 0) {
                sendCCValueChange((currentColumn * 3), -1);
            } else {
                waldorfLocationDial.value = Math.max(0, waldorfLocationDial.value - 1);
            }
        }
        function knob2Up() {
            if (_private.currentPage == 0) {
                sendCCValueChange((currentColumn * 3) + 2, 1);
            } else {
                sendCCValueChange(filterControlDelegate.entryIndex, 1);
            }
        }
        function knob2Down() {
            if (_private.currentPage == 0) {
                sendCCValueChange((currentColumn * 3) + 2, -1);
            } else {
                sendCCValueChange(filterControlDelegate.entryIndex, -1);
            }
        }
        function knob3Up() {
            goRight();
        }
        function knob3Down() {
            goLeft();
        }
        function sendCCValueChange(entryIndex, changeAmount) {
            let midiChannel = component.externalSettings
                            ? component.externalSettings.keyValueStore["controls"][entryIndex]["midiChannel"] == -1
                                ? (component.externalSettings.midiChannel == -1 ? component.selectedChannel.id : component.externalSettings.midiChannel)
                                : component.externalSettings.keyValueStore["controls"][entryIndex]["midiChannel"]
                            : -1;
            let ccControl = component.externalSettings.keyValueStore["controls"][entryIndex]["ccControl"];
            let currentCCValue = sketchpadTrackController.ccValue(midiChannel, ccControl);
            Zynthbox.SyncTimer.sendCCMessageImmediately(midiChannel, ccControl, currentCCValue + changeAmount, component.selectedChannel.id);
        }
    }

    Column {
        id: pageSelectorColumn
        anchors {
            top: parent.top
            left: parent.left
            bottom: parent.bottom
        }
        width: component.width * 0.15
        Repeater {
            model: 2
            delegate: Rectangle {
                width: pageSelectorColumn.width
                height: pageSelectorColumn.height / 8
                color: "transparent"
                border.color: _private.currentPage === index ? "#88ffffff" : "transparent"
                border.width: 2
                radius: 2

                QQC2.Label {
                    anchors.centerIn: parent
                    text: qsTr("Page %1").arg(index+1)
                }

                Kirigami.Separator {
                    height: 1
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        _private.currentPage = index
                    }
                }
            }
        }
    }
    Row {
        visible: _private.currentPage === 0
        anchors {
            fill: parent
            leftMargin: component.width * 0.15 + Kirigami.Units.largeSpacing
        }
        Repeater {
            model: 4
            delegate: columnDelegateComponent
        }
    }
    Item {
        visible: _private.currentPage === 1
        anchors {
            fill: parent
            leftMargin: component.width * 0.15 + Kirigami.Units.largeSpacing
        }
        Row {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: component.height * 0.1
            QQC2.Label {
                height: parent.height
                width: parent.width * 0.8
                text: _private.sketchpadTrackExternalDevice
                    ? _private.sketchpadTrackExternalDevice.sysexHelper.identity
                        ? "Identity: %1".arg(_private.sketchpadTrackExternalDevice.sysexHelper.identity.description)
                        : "External Device identity unknown, click the button to try and get one..."
                    : "External Device missing - you likely need to plug it in"
            }
            QQC2.Button {
                id: requestIdentityButton
                height: parent.height
                width: parent.width * 0.2
                text: "Request Identity"
                enabled: _private.sketchpadTrackExternalDevice && _private.sketchpadTrackExternalDevice.sysexHelper
                onClicked: {
                    console.log("Identity", _private.sketchpadTrackExternalDevice.sysexHelper.identity, "on external device", _private.sketchpadTrackExternalDevice);
                    let identityRequestMessage = _private.sketchpadTrackExternalDevice.sysexHelper.createKnownMessage(Zynthbox.SysexHelper.IdentityRequestMessage);
                    identityRequestMessage.deleteOnSend = true;
                    _private.sketchpadTrackExternalDevice.sysexHelper.send(identityRequestMessage);
                }
            }
        }
        Row {
            anchors {
                fill: parent
                topMargin: component.height * 0.1 + Kirigami.Units.largeSpacing
            }
            // Sysex format for sound parameter changes for Waldorf Microwave 2 (does not require a checksum):
            // 0x3E (for Waldorf)
            // 0x0E (for Microwave 2)
            // 0x7F (for "broadcast")
            // 0x20 (for Sound Parameter Change
            // 0xLL (for Location - either 00 (for Sound Mode Edit Buffer), or 00 through 07 (for Multi Mode Instrument 1..8 sound buffer))
            // 0xHH (Parameter index high bit, for parameter indexes above 127 - meaning these two are functionally a (right-aligned) 14 bit number together)
            // 0xPP (Parameter index)
            // 0xXX (New parameter value - range dependent on parameter)
            // For the filter cutoff:
            // Parameter index 62 (0x00, 0x3E)
            // Range 0 through 127 (0x00 through 0x7F)
            Item {
                height: parent.height
                width: parent.width / 2
                QQC2.Dial {
                    id: filterCutoffDial
                    anchors.centerIn: parent
                    inputMode: QQC2.Dial.Circular
                    width: Math.min(parent.height, parent.width) - Kirigami.Units.largeSpacing * 2
                    height: Math.min(parent.height, parent.width) - Kirigami.Units.largeSpacing * 2
                    stepSize: 1
                    from: 0
                    to: 127
                    value: 127
                    onMoved: {
                        let theBytes = [0x3E, 0x0E, 0x7F, 0x20, waldorfLocationDial.value, 0x00, 0x3E, filterCutoffDial.value];
                        let parameterChangeMessage = _private.sketchpadTrackExternalDevice.sysexHelper.createMessage(theBytes);
                        _private.sketchpadTrackExternalDevice.sysexHelper.send(parameterChangeMessage);
                    }

                    QQC2.Label {
                        id: valueLabel
                        anchors {
                            fill: parent
                            margins: filterCutoffDial.handle.width / 2
                        }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        fontSizeMode: Text.Fit
                        minimumPointSize: 8
                        font.pointSize: 18
                        text: qsTr("Waldorf Microwave 2\nFilter Cutoff:\n%1").arg(filterCutoffDial.value)
                    }
                    Item {
                        anchors {
                            bottom: parent.bottom
                            right: parent.right
                        }
                        height: Kirigami.Units.iconSizes.small
                        width: Kirigami.Units.iconSizes.small
                        Zynthian.KnobIndicator {
                            anchors.centerIn: parent
                            height: Kirigami.Units.iconSizes.small
                            width: Kirigami.Units.iconSizes.small
                            knobId: 0
                        }
                    }
                }
                QQC2.Dial {
                    id: waldorfLocationDial
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                    }
                    inputMode: QQC2.Dial.Circular
                    width: parent.width * 0.2
                    height: width
                    stepSize: 1
                    from: 0
                    to: 7
                    value: 0

                    QQC2.Label {
                        anchors {
                            bottom: parent.top
                            left: parent.left
                        }
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.Bottom
                        font.pointSize: 10
                        text: "Location:"
                    }
                    QQC2.Label {
                        anchors {
                            fill: parent
                            margins: waldorfLocationDial.handle.width / 2
                        }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        fontSizeMode: Text.Fit
                        minimumPointSize: 8
                        font.pointSize: 18
                        text: qsTr("%1").arg(waldorfLocationDial.value)
                    }
                    Item {
                        anchors {
                            bottom: parent.bottom
                            right: parent.right
                        }
                        height: Kirigami.Units.iconSizes.medium
                        width: Kirigami.Units.iconSizes.medium
                        Zynthian.KnobIndicator {
                            anchors.centerIn: parent
                            height: Kirigami.Units.iconSizes.small
                            width: Kirigami.Units.iconSizes.small
                            knobId: 1
                        }
                    }
                }
            }
            Item {
                id: filterControlDelegate
                height: parent.height
                width: parent.width / 2
                readonly property int entryIndex: 0
                readonly property int midiChannel: component.externalSettings
                    ? component.externalSettings.keyValueStore["controls"][entryIndex]["midiChannel"] == -1
                        ? (component.externalSettings.midiChannel == -1 ? component.selectedChannel.id : component.externalSettings.midiChannel)
                        : component.externalSettings.keyValueStore["controls"][entryIndex]["midiChannel"]
                    : -1
                readonly property int ccControl: component.externalSettings ? component.externalSettings.keyValueStore["controls"][entryIndex]["ccControl"] : -1
                property int ccValue: 0
                Connections {
                    target: _private.sketchpadTrackController
                    function onCcValueChanged(midiChannel, ccControl, ccValue) {
                        if (midiChannel == filterControlDelegate.midiChannel && ccControl == filterControlDelegate.ccControl) {
                            filterControlDelegate.ccValue = ccValue;
                        }
                    }
                }
                Timer {
                    id: ccValueUpdater
                    interval: 1; running: false; repeat: false;
                    onTriggered: {
                        if (filterControlDelegate.midiChannel > -1 && filterControlDelegate.ccControl > -1) {
                            filterControlDelegate.ccValue = _private.sketchpadTrackController.ccValue(filterControlDelegate.midiChannel, filterControlDelegate.ccControl);
                        }
                    }
                }
                onMidiChannelChanged: ccValueUpdater.restart()
                onCcControlChanged: ccValueUpdater.restart()
                Component.onCompleted: ccValueUpdater.restart()
                Connections {
                    target: component
                    onSelectedChannelChanged: ccValueUpdater.restart()
                }
                QQC2.Dial {
                    id: filterControlDial
                    anchors.centerIn: parent
                    inputMode: QQC2.Dial.Circular
                    width: Math.min(parent.height, parent.width) - Kirigami.Units.largeSpacing * 2
                    height: Math.min(parent.height, parent.width) - Kirigami.Units.largeSpacing * 2
                    stepSize: 1
                    from: 0
                    to: 127

                    value: filterControlDelegate.ccValue

                    onMoved: {
                        Zynthbox.SyncTimer.sendCCMessageImmediately(filterControlDelegate.midiChannel, filterControlDelegate.ccControl, value, component.selectedChannel.id);
                    }

                    QQC2.Label {
                        anchors {
                            fill: parent
                            margins: filterControlDial.handle.width / 2
                        }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        fontSizeMode: Text.Fit
                        minimumPointSize: 8
                        font.pointSize: 18
                        text: qsTr("%1\n%2").arg(filterControlDelegate.ccControl > -1 ? applicationWindow().midiBytePicker.byteValueToCCShorthand(filterControlDelegate.ccControl) : "").arg(filterControlDial.value)
                    }
                }
                QQC2.ToolButton {
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                    }
                    height: Kirigami.Units.iconSizes.medium
                    width: Kirigami.Units.iconSizes.medium
                    icon.name: "overflow-menu"
                    onClicked: {
                        optionPickerPopup.pickOptions(filterControlDelegate.entryIndex);
                    }
                    QQC2.Label {
                        anchors {
                            top: parent.top
                            left: parent.left
                            topMargin: -Kirigami.Units.smallSpacing
                        }
                        transformOrigin: Item.TopLeft
                        rotation: -90
                        height: parent.height
                        text: filterControlDelegate.ccControl > -1 ? "ch%2/cc%1".arg(filterControlDelegate.ccControl + 1).arg(filterControlDelegate.midiChannel + 1) : ""
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: height * 0.5
                        opacity: 0.5
                    }
                }
                Item {
                    anchors {
                        bottom: parent.bottom
                        right: parent.right
                    }
                    height: Kirigami.Units.iconSizes.medium
                    width: Kirigami.Units.iconSizes.medium
                    Zynthian.KnobIndicator {
                        anchors.centerIn: parent
                        height: Kirigami.Units.iconSizes.small
                        width: Kirigami.Units.iconSizes.small
                        knobId: 3
                    }
                }
            }
        }
    }
    Component {
        id: columnDelegateComponent
        Item {
            id: columnDelegate
            height: parent.height
            width: parent.width / 4
            readonly property bool isCurrent: model.index === _private.currentColumn
            readonly property int columnIndex: model.index
            Rectangle {
                anchors {
                    fill: parent
                    margins: -Kirigami.Units.smallSpacing
                }
                radius: 4
                color: "transparent"
                border {
                    width: 1
                    color: columnDelegate.isCurrent ? Kirigami.Theme.textColor : "transparent"
                }
            }
            Column {
                anchors.fill: parent
                Repeater {
                    model: 3
                    delegate: ColumnLayout {
                        id: controlDelegate
                        width: parent.width
                        height: parent.height / 3
                        readonly property int knobId: columnDelegate.isCurrent ? model.index : -1
                        readonly property int entryIndex: (columnDelegate.columnIndex * 3) + model.index
                        readonly property int midiChannel: component.externalSettings
                            ? component.externalSettings.keyValueStore["controls"][entryIndex]["midiChannel"] == -1
                                ? (component.externalSettings.midiChannel == -1 ? component.selectedChannel.id : component.externalSettings.midiChannel)
                                : component.externalSettings.keyValueStore["controls"][entryIndex]["midiChannel"]
                            : -1
                        readonly property int ccControl: component.externalSettings ? component.externalSettings.keyValueStore["controls"][entryIndex]["ccControl"] : -1
                        property int ccValue: 0
                        Connections {
                            target: _private.sketchpadTrackController
                            function onCcValueChanged(midiChannel, ccControl, ccValue) {
                                if (midiChannel == controlDelegate.midiChannel && ccControl == controlDelegate.ccControl) {
                                    controlDelegate.ccValue = ccValue;
                                }
                            }
                        }
                        Timer {
                            id: ccValueUpdater
                            interval: 1; running: false; repeat: false;
                            onTriggered: {
                                if (controlDelegate.midiChannel > -1 && controlDelegate.ccControl > -1) {
                                    controlDelegate.ccValue = _private.sketchpadTrackController.ccValue(controlDelegate.midiChannel, controlDelegate.ccControl);
                                }
                            }
                        }
                        onMidiChannelChanged: ccValueUpdater.restart()
                        onCcControlChanged: ccValueUpdater.restart()
                        Component.onCompleted: ccValueUpdater.restart()
                        Connections {
                            target: component
                            onSelectedChannelChanged: ccValueUpdater.restart()
                        }
                        QQC2.Label {
                            text: controlDelegate.ccControl > -1 ? applicationWindow().midiBytePicker.byteValueToCCShorthand(controlDelegate.ccControl) : ""
                            Layout.fillWidth: true
                            Layout.minimumHeight: font.pixelSize
                            Layout.maximumHeight: font.pixelSize
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            fontSizeMode: Text.Fit
                            font.pixelSize: controlDelegate.height / 6
                        }
                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            QQC2.Dial {
                                id: dial
                                anchors.centerIn: parent
                                inputMode: QQC2.Dial.Vertical
                                width: Math.min(parent.height, parent.width)
                                height: Math.min(parent.height, parent.width)
                                stepSize: 1
                                from: 0
                                to: 127

                                value: controlDelegate.ccValue

                                onMoved: {
                                    _private.currentColumn = columnDelegate.columnIndex;
                                    Zynthbox.SyncTimer.sendCCMessageImmediately(controlDelegate.midiChannel, controlDelegate.ccControl, value, component.selectedChannel.id);
                                }

                                QQC2.Label {
                                    id: valueLabel
                                    anchors {
                                        fill: parent
                                        margins: dial.handle.width / 2
                                    }
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    fontSizeMode: Text.Fit
                                    minimumPointSize: 8
                                    font.pointSize: 18
                                    text: qsTr("%1").arg(dial.value + 1)
                                }
                            }
                            QQC2.ToolButton {
                                anchors {
                                    bottom: parent.bottom
                                    left: parent.left
                                }
                                height: Kirigami.Units.iconSizes.medium
                                width: Kirigami.Units.iconSizes.medium
                                icon.name: "overflow-menu"
                                onClicked: {
                                    optionPickerPopup.pickOptions(controlDelegate.entryIndex);
                                }
                                QQC2.Label {
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        topMargin: -Kirigami.Units.smallSpacing
                                    }
                                    transformOrigin: Item.TopLeft
                                    rotation: -90
                                    height: parent.height
                                    text: controlDelegate.ccControl > -1 ? "ch%2/cc%1".arg(controlDelegate.ccControl + 1).arg(controlDelegate.midiChannel + 1) : ""
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: height * 0.5
                                    opacity: 0.5
                                }
                            }
                            Item {
                                anchors {
                                    bottom: parent.bottom
                                    right: parent.right
                                }
                                height: Kirigami.Units.iconSizes.medium
                                width: Kirigami.Units.iconSizes.medium
                                Zynthian.KnobIndicator {
                                    anchors.centerIn: parent
                                    height: Kirigami.Units.iconSizes.small
                                    width: Kirigami.Units.iconSizes.small
                                    visible: controlDelegate.knobId > -1
                                    knobId: Math.max(0, Math.min(controlDelegate.knobId, 3))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Zynthian.ActionPickerPopup {
        id: optionPickerPopup
        // Pick options for this element (specifically: which CC value should this be, and what midi channel)
        function pickOptions(theEntryIndex) {
            entryIndex = theEntryIndex;
            optionPickerPopup.open();
        }
        property int entryIndex: 0
        actions: [
            Kirigami.Action {
                text: component.externalSettings
                    ? component.externalSettings.keyValueStore["controls"][optionPickerPopup.entryIndex]["midiChannel"] == -1
                        ? qsTr("Pick MIDI Channel...\nCurrent: Default")
                        : qsTr("Pick MIDI Channel...\nCurrently: %1").arg(component.externalSettings.keyValueStore["controls"][optionPickerPopup.entryIndex]["midiChannel"] + 1)
                    : ""
                onTriggered: {
                    midiChannelPicker.pickMidiChannel(component.externalSettings.keyValueStore["controls"][optionPickerPopup.entryIndex]["midiChannel"], function(newChannel) {
                        component.externalSettings.setSubIndexValue("controls", optionPickerPopup.entryIndex, "midiChannel", newChannel);
                    });
                }
            },
            Kirigami.Action {
                text: component.externalSettings
                    ? qsTr("Pick CC Control...\nCurrently: %1").arg(component.externalSettings.keyValueStore["controls"][optionPickerPopup.entryIndex]["ccControl"] + 1)
                    : ""
                onTriggered: {
                    applicationWindow().midiBytePicker.pickByte(component.externalSettings.keyValueStore["controls"][optionPickerPopup.entryIndex]["ccControl"], 2, function(newByte, messageSize) {
                        component.externalSettings.setSubIndexValue("controls", optionPickerPopup.entryIndex, "ccControl", newByte);
                    });
                }
            }
        ]
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
            ListElement { text: "Track External MIDI Channel (Default)"; value: -1 }
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
}
