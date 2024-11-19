/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Settings page for Midi Controllers - Individual Filter Rule Display

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

ColumnLayout {
    id: component
    property QtObject containingPage
    property QtObject _private
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
                returnValue = true;
                break;
            }
            case "KNOB3_DOWN": {
                currentRow.goPrevious();
                returnValue = true;
                break;
            }
            default:
                break;
        }
        return result;
    }
    readonly property QtObject filterObject: _private.selectedDeviceObject && _private.selectedInputFilterIndex > -1
        ? _private.selectedDeviceObject.inputEventFilter.entries[_private.selectedInputFilterIndex]
        : null
    readonly property QtObject filterRuleObject: _private.selectedDeviceObject && _private.selectedInputFilterIndex > -1 && _private.selectedInputFilterRuleIndex > -1
        ? _private.selectedDeviceObject.inputEventFilter.entries[_private.selectedInputFilterIndex].rewriteRules[_private.selectedInputFilterRuleIndex]
        : null
    property QtObject currentRow: inputFilterRuleHeader
    Kirigami.Heading {
        id: inputFilterRuleHeader
        function goNext() { component.currentRow = inputFilterRuleTypeSettings; }
        function goPrevious() { }
        Layout.fillWidth: true
        text: component.filterRuleObject ? qsTr("Input Filter Rule %1").arg(_private.selectedInputFilterRuleIndex + 1) : ""
    }
    RowLayout {
        id: inputFilterRuleTypeSettings
        function goNext() { 
            if (component.filterRuleObject.type === Zynthbox.MidiRouterFilterEntryRewriter.TrackRule) {
                component.currentRow = inputFilterRuleOutputByteSize;
            } else if (component.filterRuleObject.type === Zynthbox.MidiRouterFilterEntryRewriter.UIRule) {
                component.currentRow = inputFilterRuleCUIAEventRow;
            } else {
                console.log("Something isn't working right, the message type", component.filterRuleObject.type, "was unknown");
            }
        }
        function goPrevious() { component.currentRow = inputFilterRuleHeader; }
        function selectPressed() { inputFilterRuleTypeSettingsButton.onClicked(); }
        Layout.fillWidth: true
        QQC2.Button {
            id: inputFilterRuleTypeSettingsButton
            Layout.fillWidth: true
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.type === Zynthbox.MidiRouterFilterEntryRewriter.TrackRule
                    ? qsTr("Output Type:\nMIDI Message")
                    : component.filterRuleObject.type === Zynthbox.MidiRouterFilterEntryRewriter.UIRule
                        ? qsTr("Output Type:\nInteraction Command")
                        : "(unknown rule type)"
            onClicked: {
                if (component.filterRuleObject.type === Zynthbox.MidiRouterFilterEntryRewriter.TrackRule) {
                    component.filterRuleObject.type = Zynthbox.MidiRouterFilterEntryRewriter.UIRule;
                } else if (component.filterRuleObject.type === Zynthbox.MidiRouterFilterEntryRewriter.UIRule) {
                    component.filterRuleObject.type = Zynthbox.MidiRouterFilterEntryRewriter.TrackRule;
                } else {
                    console.log("Something isn't working right, the message type", component.filterRuleObject.type, "was unknown");
                }
            }
            checked: component.currentRow === inputFilterRuleTypeSettings
        }
    }
    // BEGIN Track (MIDI) rule settings
    readonly property int effectiveByteSize: component.filterRuleObject === null
        ? 0
        : component.filterRuleObject.byteSize === Zynthbox.MidiRouterFilterEntryRewriter.EventSizeSame
            ? component.filterObject.requiredBytes
            : component.filterRuleObject.byteSize
    RowLayout {
        id: inputFilterRuleOutputByteSize
        function goNext() { component.currentRow = inputFilterRuleOutputByte1; }
        function goPrevious() { component.currentRow = inputFilterRuleTypeSettings; }
        function knob0up() {
            if (component.filterRuleObject.byteSize === Zynthbox.MidiRouterFilterEntryRewriter.EventSizeSame) {
                component.filterRuleObject.byteSize = Zynthbox.MidiRouterFilterEntryRewriter.EventSize1;
            } else {
                component.filterRuleObject.byteSize = Math.min(3, component.filterRuleObject.byteSize + 1);
            }
        }
        function knob0down() {
            if (component.filterRuleObject.byteSize === Zynthbox.MidiRouterFilterEntryRewriter.EventSizeSame) {
                // Do nothing
            } else if (component.filterRuleObject.byteSize === Zynthbox.MidiRouterFilterEntryRewriter.EventSize1) {
                component.filterRuleObject.byteSize = Zynthbox.MidiRouterFilterEntryRewriter.EventSizeSame;
            } else {
                component.filterRuleObject.byteSize = Math.max(1, component.filterRuleObject.byteSize - 1);
            }
        }
        Layout.fillWidth: true
        visible: component.filterRuleObject.type === Zynthbox.MidiRouterFilterEntryRewriter.TrackRule
        QQC2.Button {
            Layout.fillWidth: true
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.byteSize === Zynthbox.MidiRouterFilterEntryRewriter.EventSizeSame
                    ? qsTr("Output Message Size:\nSame as matched")
                    : qsTr("Output Message Size:\n%1").arg(component.filterRuleObject.byteSize)
            onClicked: {
                if (component.filterRuleObject.byteSize === Zynthbox.MidiRouterFilterEntryRewriter.EventSizeSame) {
                    component.filterRuleObject.byteSize = Zynthbox.MidiRouterFilterEntryRewriter.EventSize1;
                } else if (component.filterRuleObject.byteSize === Zynthbox.MidiRouterFilterEntryRewriter.EventSize1) {
                    component.filterRuleObject.byteSize = Zynthbox.MidiRouterFilterEntryRewriter.EventSize2;
                } else if (component.filterRuleObject.byteSize === Zynthbox.MidiRouterFilterEntryRewriter.EventSize2) {
                    component.filterRuleObject.byteSize = Zynthbox.MidiRouterFilterEntryRewriter.EventSize3;
                } else if (component.filterRuleObject.byteSize === Zynthbox.MidiRouterFilterEntryRewriter.EventSize3) {
                    component.filterRuleObject.byteSize = Zynthbox.MidiRouterFilterEntryRewriter.EventSizeSame;
                } else {
                    console.log("Something isn't working right, the byte size", component.filterRuleObject.byteSize, "was unknown");
                }
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
                visible: component.currentRow === inputFilterRuleOutputByteSize
            }
        }
    }
    RowLayout {
        id: inputFilterRuleOutputByte1
        function goNext() {
            if (component.effectiveByteSize > 1) {
                component.currentRow = inputFilterRuleOutputByte2;
            }
        }
        function goPrevious() { component.currentRow = inputFilterRuleOutputByteSize; }
        function knob0up() {
            component.filterRuleObject.byte1 = Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte1;
        }
        function knob0down() {
            component.filterRuleObject.byte1 = Zynthbox.MidiRouterFilterEntryRewriter.ExplicitByte0;
        }
        function knob1up() {
            if (component.filterRuleObject.byte1 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte1) {
                component.filterRuleObject.byte1 = Math.min(127, component.filterRuleObject.byte1 + 1);
            }
        }
        function knob1down() {
            if (component.filterRuleObject.byte1 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte1) {
                component.filterRuleObject.byte1 = Math.max(0, component.filterRuleObject.byte1 - 1);
            }
        }
        function knob2up() {
            component.filterRuleObject.byte1AddChannel = true;
        }
        function knob2down() {
            component.filterRuleObject.byte1AddChannel = false;
        }
        Layout.fillWidth: true
        visible: component.filterRuleObject.type === Zynthbox.MidiRouterFilterEntryRewriter.TrackRule
        QQC2.Button {
            id: inputFilterRuleOutputByte1UseOriginalByte
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.byte1 === Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte1
                    ? qsTr("Use Original Value:\nYes")
                    : qsTr("Use Original Value:\nNo")
            onClicked: {
                if (component.filterRuleObject.byte1 === Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte1) {
                    component.filterRuleObject.byte1 = Zynthbox.MidiRouterFilterEntryRewriter.ExplicitByte0;
                } else {
                    component.filterRuleObject.byte1 = Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte1;
                }
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
                visible: component.currentRow === inputFilterRuleOutputByte1
            }
        }
        QQC2.Button {
            id: inputFilterRuleOutputByte1Value
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            enabled: component.filterRuleObject.byte1 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte1
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.byte1 === Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte1
                    ? qsTr("Byte 1 Value:\n(original)")
                    : qsTr("Byte 1 Value:\n%1").arg(midiBytePicker.byteValueToMessageName(component.filterRuleObject.byte1 + 128))
            onClicked: {
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
                visible: component.currentRow === inputFilterRuleOutputByte1
            }
        }
        QQC2.Button {
            id: inputFilterRuleOutputByte1AddChannel
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            enabled: component.filterRuleObject.byte1 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte1
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.byte1AddChannel
                    ? qsTr("Add Message Channel Value:\nYes")
                    : qsTr("Add Message Channel Value:\nNo")
            onClicked: {
                component.filterRuleObject.byte1AddChannel = !component.filterRuleObject.byte1AddChannel;
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
                visible: component.currentRow === inputFilterRuleOutputByte1
            }
        }
    }
    RowLayout {
        id: inputFilterRuleOutputByte2
        function goNext() { 
            if (component.effectiveByteSize > 2) {
                component.currentRow = inputFilterRuleOutputByte3;
            }
        }
        function goPrevious() { component.currentRow = inputFilterRuleOutputByte1; }
        function knob0up() {
            component.filterRuleObject.byte2 = Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte2;
        }
        function knob0down() {
            component.filterRuleObject.byte2 = Zynthbox.MidiRouterFilterEntryRewriter.ExplicitByte0;
        }
        function knob1up() {
            if (component.filterRuleObject.byte2 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte2) {
                component.filterRuleObject.byte2 = Math.min(127, component.filterRuleObject.byte2 + 1);
            }
        }
        function knob1down() {
            if (component.filterRuleObject.byte2 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte2) {
                component.filterRuleObject.byte2 = Math.max(0, component.filterRuleObject.byte2 - 1);
            }
        }
        function knob2up() {
            component.filterRuleObject.byte2AddChannel = true;
        }
        function knob2down() {
            component.filterRuleObject.byte2AddChannel = false;
        }
        Layout.fillWidth: true
        visible: component.filterRuleObject.type === Zynthbox.MidiRouterFilterEntryRewriter.TrackRule && component.effectiveByteSize > 1
        QQC2.Button {
            id: inputFilterRuleOutputByte2UseOriginalByte
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.byte2 === Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte2
                    ? qsTr("Use Original Value:\nYes")
                    : qsTr("Use Original Value:\nNo")
            onClicked: {
                if (component.filterRuleObject.byte2 === Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte2) {
                    component.filterRuleObject.byte2 = Zynthbox.MidiRouterFilterEntryRewriter.ExplicitByte0;
                } else {
                    component.filterRuleObject.byte2 = Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte2;
                }
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
                visible: component.currentRow === inputFilterRuleOutputByte2
            }
        }
        QQC2.Button {
            id: inputFilterRuleOutputByte2Value
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            enabled: component.filterRuleObject.byte2 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte2
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.byte2 === Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte2
                    ? qsTr("Byte 2 Value:\n(original)")
                    : qsTr("Byte 2 Value:\n%1").arg(component.filterRuleObject.byte2)
            Zynthian.KnobIndicator {
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    margins: Kirigami.Units.smallSpacing
                }
                height: Kirigami.Units.iconSizes.smallMedium
                width: Kirigami.Units.iconSizes.smallMedium
                knobId: 1
                visible: component.currentRow === inputFilterRuleOutputByte2
            }
        }
        QQC2.Button {
            id: inputFilterRuleOutputByte2AddChannel
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            enabled: component.filterRuleObject.byte2 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte2
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.byte2AddChannel
                    ? qsTr("Add Message Channel Value:\nYes")
                    : qsTr("Add Message Channel Value:\nNo")
            onClicked: {
                component.filterRuleObject.byte2AddChannel = !component.filterRuleObject.byte2AddChannel;
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
                visible: component.currentRow === inputFilterRuleOutputByte2
            }
        }
    }
    RowLayout {
        id: inputFilterRuleOutputByte3
        function goNext() { }
        function goPrevious() { component.currentRow = inputFilterRuleOutputByte2; }
        function knob0up() {
            component.filterRuleObject.byte3 = Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte3;
        }
        function knob0down() {
            component.filterRuleObject.byte3 = Zynthbox.MidiRouterFilterEntryRewriter.ExplicitByte0;
        }
        function knob1up() {
            if (component.filterRuleObject.byte3 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte3) {
                component.filterRuleObject.byte3 = Math.min(127, component.filterRuleObject.byte3 + 1);
            }
        }
        function knob1down() {
            if (component.filterRuleObject.byte3 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte3) {
                component.filterRuleObject.byte3 = Math.max(0, component.filterRuleObject.byte3 - 1);
            }
        }
        function knob2up() {
            component.filterRuleObject.byte3AddChannel = true;
        }
        function knob2down() {
            component.filterRuleObject.byte3AddChannel = false;
        }
        Layout.fillWidth: true
        visible: component.filterRuleObject.type === Zynthbox.MidiRouterFilterEntryRewriter.TrackRule && component.effectiveByteSize > 2
        QQC2.Button {
            id: inputFilterRuleOutputByte3UseOriginalByte
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.byte3 === Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte3
                    ? qsTr("Use Original Value:\nYes")
                    : qsTr("Use Original Value:\nNo")
            onClicked: {
                if (component.filterRuleObject.byte3 === Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte3) {
                    component.filterRuleObject.byte3 = Zynthbox.MidiRouterFilterEntryRewriter.ExplicitByte0;
                } else {
                    component.filterRuleObject.byte3 = Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte3;
                }
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
                visible: component.currentRow === inputFilterRuleOutputByte3
            }
        }
        QQC2.Button {
            id: inputFilterRuleOutputByte3Value
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            enabled: component.filterRuleObject.byte3 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte3
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.byte3 === Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte3
                    ? qsTr("Byte 3 Value:\n(original)")
                    : qsTr("Byte 3 Value:\n%1").arg(component.filterRuleObject.byte3)
            Zynthian.KnobIndicator {
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    margins: Kirigami.Units.smallSpacing
                }
                height: Kirigami.Units.iconSizes.smallMedium
                width: Kirigami.Units.iconSizes.smallMedium
                knobId: 1
                visible: component.currentRow === inputFilterRuleOutputByte3
            }
        }
        QQC2.Button {
            id: inputFilterRuleOutputByte3AddChannel
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            enabled: component.filterRuleObject.byte3 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte3
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.byte3AddChannel
                    ? qsTr("Add Message Channel Value:\nYes")
                    : qsTr("Add Message Channel Value:\nNo")
            onClicked: {
                component.filterRuleObject.byte3AddChannel = !component.filterRuleObject.byte3AddChannel;
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
                visible: component.currentRow === inputFilterRuleOutputByte3
            }
        }
    }
    // END Track (MIDI) rule settings
    // BEGIN CUIA rule settings
    RowLayout {
        id: inputFilterRuleCUIAEventRow
        function goNext() {
            if (inputFilterRuleCUIAParametersRow.visible) {
                component.currentRow = inputFilterRuleCUIAParametersRow;
            }
        }
        function goPrevious() { component.currentRow = inputFilterRuleTypeSettings; }
        function selectPressed() { inputFilterRuleCUIAEventPicker.onClicked(); }
        Layout.fillWidth: true
        visible: component.filterRuleObject.type === Zynthbox.MidiRouterFilterEntryRewriter.UIRule
        QQC2.Button {
            id: inputFilterRuleCUIAEventPicker
            Layout.fillWidth: true
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : qsTr("UI Event:\n%1").arg(Zynthbox.CUIAHelper.cuiaTitle(component.filterRuleObject.cuiaEvent))
            onClicked: {
                cuiaEventPicker.pickEvent(component.filterRuleObject.cuiaEvent, function(newEvent) {
                    component.filterRuleObject.cuiaEvent = newEvent;
                });
            }
            checked: component.currentRow === inputFilterRuleCUIAEventRow
        }
    }
    RowLayout {
        id: inputFilterRuleCUIAParametersRow
        function goNext() {}
        function goPrevious() { component.currentRow = inputFilterRuleCUIAEventRow; }
        function knob0up() {
            if (Zynthbox.CUIAHelper.cuiaEventWantsATrack(component.filterRuleObject.cuiaEvent)) {
                component.filterRuleObject.cuiaTrack = Math.min(9, component.filterRuleObject.cuiaTrack + 1);
            }
        }
        function knob0down() {
            if (Zynthbox.CUIAHelper.cuiaEventWantsATrack(component.filterRuleObject.cuiaEvent)) {
                component.filterRuleObject.cuiaTrack = Math.max(-1, component.filterRuleObject.cuiaTrack - 1);
            }
        }
        function knob1up() {
            if (Zynthbox.CUIAHelper.cuiaEventWantsASlot(component.filterRuleObject.cuiaEvent)) {
                component.filterRuleObject.cuiaSlot = Math.min(4, component.filterRuleObject.cuiaSlot + 1);
            }
        }
        function knob1down() {
            if (Zynthbox.CUIAHelper.cuiaEventWantsASlot(component.filterRuleObject.cuiaEvent)) {
                component.filterRuleObject.cuiaSlot = Math.max(-1, component.filterRuleObject.cuiaSlot - 1);
            }
        }
        function knob2up() {
            if (Zynthbox.CUIAHelper.cuiaEventWantsAValue(component.filterRuleObject.cuiaEvent)) {
                component.filterRuleObject.cuiaValue = Math.min(127, component.filterRuleObject.cuiaValue + 1);
            }
        }
        function knob2down() {
            if (Zynthbox.CUIAHelper.cuiaEventWantsAValue(component.filterRuleObject.cuiaEvent)) {
                component.filterRuleObject.cuiaValue = Math.max(-4, component.filterRuleObject.cuiaValue - 1);
            }
        }
        Layout.fillWidth: true
        visible: component.filterRuleObject.type === Zynthbox.MidiRouterFilterEntryRewriter.UIRule && (Zynthbox.CUIAHelper.cuiaEventWantsATrack(component.filterRuleObject.cuiaEvent) || Zynthbox.CUIAHelper.cuiaEventWantsASlot(component.filterRuleObject.cuiaEvent) ||Zynthbox.CUIAHelper.cuiaEventWantsAValue(component.filterRuleObject.cuiaEvent))
        QQC2.Button {
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            enabled: Zynthbox.CUIAHelper.cuiaEventWantsATrack(component.filterRuleObject.cuiaEvent)
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : qsTr("Sketchpad Track:\n%1").arg(Zynthbox.ZynthboxBasics.trackLabelText(component.filterRuleObject.cuiaTrack))
            onClicked: {
                trackPicker.pickTrack(component.filterRuleObject.cuiaTrack, function(newTrack) {
                    component.filterRuleObject.cuiaTrack = newTrack;
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
                visible: component.currentRow === inputFilterRuleCUIAParametersRow && parent.enabled
            }
        }
        QQC2.Button {
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            enabled: Zynthbox.CUIAHelper.cuiaEventWantsASlot(component.filterRuleObject.cuiaEvent)
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : Zynthbox.CUIAHelper.cuiaEventWantsAClip(component.filterRuleObject.cuiaEvent)
                    ? qsTr("Sketchpad Clip:\n%1").arg(Zynthbox.ZynthboxBasics.clipLabelText(component.filterRuleObject.cuiaSlot))
                    : Zynthbox.CUIAHelper.cuiaEventWantsASlot(component.filterRuleObject.cuiaEvent)
                        ? qsTr("Sketchpad Sound Slot:\n%1").arg(Zynthbox.ZynthboxBasics.soundSlotLabelText(component.filterRuleObject.cuiaSlot))
                        : Zynthbox.CUIAHelper.cuiaEventWantsAnFxSlot(component.filterRuleObject.cuiaEvent)
                            ? qsTr("Sketchpad Fx Slot:\n%1").arg(Zynthbox.ZynthboxBasics.fxLabelText(component.filterRuleObject.cuiaSlot))
                            : qsTr("Sketchpad Slot:\n%1").arg(Zynthbox.ZynthboxBasics.slotLabelText(component.filterRuleObject.cuiaSlot))
            onClicked: {
                slotType = -1;
                if (Zynthbox.CUIAHelper.cuiaEventWantsAClip(component.filterRuleObject.cuiaEvent)) {
                    slotType = 0;
                } else if(Zynthbox.CUIAHelper.cuiaEventWantsASoundSlot(component.filterRuleObject.cuiaEvent)) {
                    slotType = 1;
                } else if(Zynthbox.CUIAHelper.cuiaEventWantsAnFxSlot(component.filterRuleObject.cuiaEvent)) {
                    slotType = 2;
                }
                slotPicker.pickSlot(component.filterRuleObject.cuiaSlot, slotType, function(newSlot) {
                    component.filterRuleObject.cuiaSlot = newSlot;
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
                visible: component.currentRow === inputFilterRuleCUIAParametersRow && parent.enabled
            }
        }
        QQC2.Button {
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            enabled: Zynthbox.CUIAHelper.cuiaEventWantsAValue(component.filterRuleObject.cuiaEvent)
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.cuiaValue === Zynthbox.MidiRouterFilterEntryRewriter.ValueEventChannel
                    ? qsTr("Matched MIDI message's event channel\n(where available, otherwise 0)")
                    : component.filterRuleObject.cuiaValue ===  Zynthbox.MidiRouterFilterEntryRewriter.ValueByte1
                        ? qsTr("Matched MIDI message's Byte 1 value\n(where available, otherwise 0)")
                        : component.filterRuleObject.cuiaValue ===  Zynthbox.MidiRouterFilterEntryRewriter.ValueByte2
                            ? qsTr("Matched MIDI message's Byte 2 value\n(where available, otherwise 0)")
                            : component.filterRuleObject.cuiaValue ===  Zynthbox.MidiRouterFilterEntryRewriter.ValueByte3
                                ? qsTr("Matched MIDI message's Byte 3 value\n(where available, otherwise 0)")
                                : qsTr("Value:\n%1").arg(component.filterRuleObject.cuiaValue)
            onClicked: {
                valueSpecifierPicker.pickValue(component.filterRuleObject.cuiaValue, function(newValue) {
                    component.filterRuleObject.cuiaValue = newValue;
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
                knobId: 2
                visible: component.currentRow === inputFilterRuleCUIAParametersRow && parent.enabled
            }
        }
    }
    // END CUIA rule settings
    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}
