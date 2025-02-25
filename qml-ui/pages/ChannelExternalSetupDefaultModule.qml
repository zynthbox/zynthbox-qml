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
        property QtObject sketchpadTrackController: component.selectedChannel ? Zynthbox.MidiRouter.getSketchpadTrackControllerDevice(component.selectedChannel.id) : null
        function goUp() {
        }
        function goLeft() {
            _private.currentColumn = Math.max(0, _private.currentColumn - 1);
        }
        function goDown() {
        }
        function goRight() {
            _private.currentColumn = Math.min(3, _private.currentColumn + 1);
        }
        function knob0Up() {
            sendCCValueChange((currentColumn * 3), 1);
        }
        function knob0Down() {
            sendCCValueChange((currentColumn * 3), -1);
        }
        function knob1Up() {
            sendCCValueChange((currentColumn * 3) + 1, 1);
        }
        function knob1Down() {
            sendCCValueChange((currentColumn * 3) + 1, -1);
        }
        function knob2Up() {
            sendCCValueChange((currentColumn * 3) + 2, 1);
        }
        function knob2Down() {
            sendCCValueChange((currentColumn * 3) + 2, -1);
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

    Row {
        anchors.fill: parent
        Repeater {
            model: 4
            delegate: columnDelegateComponent
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
