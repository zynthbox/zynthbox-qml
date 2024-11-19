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
    readonly property QtObject filterObject: _private.selectedDeviceObject && _private.selectedOutputFilterIndex > -1
        ? _private.selectedDeviceObject.outputEventFilter.entries[_private.selectedOutputFilterIndex]
        : null
    readonly property QtObject filterRuleObject: _private.selectedDeviceObject && _private.selectedOutputFilterIndex > -1 && _private.selectedOutputFilterRuleIndex > -1
        ? _private.selectedDeviceObject.outputEventFilter.entries[_private.selectedOutputFilterIndex].rewriteRules[_private.selectedOutputFilterRuleIndex]
        : null
    property QtObject currentRow: outputFilterRuleHeader
    Kirigami.Heading {
        id: outputFilterRuleHeader
        function goNext() { component.currentRow = outputFilterRuleOutputByteSize; }
        function goPrevious() { }
        Layout.fillWidth: true
        text: component.filterRuleObject ? qsTr("Output Filter Rule %1").arg(_private.selectedOutputFilterRuleIndex + 1) : ""
    }
    readonly property int effectiveByteSize: component.filterRuleObject === null
        ? 0
        : component.filterRuleObject.byteSize === Zynthbox.MidiRouterFilterEntryRewriter.EventSizeSame
            ? component.filterObject.requiredBytes
            : component.filterRuleObject.byteSize
    RowLayout {
        id: outputFilterRuleOutputByteSize
        function goNext() { component.currentRow = outputFilterRuleOutputByte1; }
        function goPrevious() { component.currentRow = outputFilterRuleHeader; }
        function knob0up() {
            component.filterRuleObject.byteSize = Math.min(3, component.filterRuleObject.byteSize + 1);
        }
        function knob0down() {
            component.filterRuleObject.byteSize = Math.max(1, component.filterRuleObject.byteSize - 1);
        }
        Layout.fillWidth: true
        visible: component.filterRuleObject.type === Zynthbox.MidiRouterFilterEntryRewriter.TrackRule
        QQC2.Button {
            Layout.fillWidth: true
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : qsTr("Output Message Size:\n%1").arg(component.filterRuleObject.byteSize)
            onClicked: {
                if (component.filterRuleObject.byteSize === Zynthbox.MidiRouterFilterEntryRewriter.EventSize1) {
                    component.filterRuleObject.byteSize = Zynthbox.MidiRouterFilterEntryRewriter.EventSize2;
                } else if (component.filterRuleObject.byteSize === Zynthbox.MidiRouterFilterEntryRewriter.EventSize2) {
                    component.filterRuleObject.byteSize = Zynthbox.MidiRouterFilterEntryRewriter.EventSize3;
                } else if (component.filterRuleObject.byteSize === Zynthbox.MidiRouterFilterEntryRewriter.EventSize3) {
                    component.filterRuleObject.byteSize = Zynthbox.MidiRouterFilterEntryRewriter.EventSize1;
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
                visible: component.currentRow === outputFilterRuleOutputByteSize
            }
        }
    }
    RowLayout {
        id: outputFilterRuleOutputByte1
        function goNext() {
            if (component.effectiveByteSize > 1) {
                component.currentRow = outputFilterRuleOutputByte2;
            }
        }
        function goPrevious() { component.currentRow = outputFilterRuleOutputByteSize; }
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
            id: outputFilterRuleOutputByte1UseOriginalByte
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
                visible: component.currentRow === outputFilterRuleOutputByte1
            }
        }
        QQC2.Button {
            id: outputFilterRuleOutputByte1Value
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
                visible: component.currentRow === outputFilterRuleOutputByte1
            }
        }
        QQC2.Button {
            id: outputFilterRuleOutputByte1AddChannel
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            enabled: component.filterRuleObject.byte1 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte1
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.byte1AddChannel
                    ? qsTr("Add Event Track Value:\nYes")
                    : qsTr("Add Event Track Value:\nNo")
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
                visible: component.currentRow === outputFilterRuleOutputByte1
            }
        }
    }
    RowLayout {
        id: outputFilterRuleOutputByte2
        function goNext() { 
            if (component.effectiveByteSize > 2) {
                component.currentRow = outputFilterRuleOutputByte3;
            }
        }
        function goPrevious() { component.currentRow = outputFilterRuleOutputByte1; }
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
            id: outputFilterRuleOutputByte2UseOriginalByte
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
                visible: component.currentRow === outputFilterRuleOutputByte2
            }
        }
        QQC2.Button {
            id: outputFilterRuleOutputByte2Value
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
                visible: component.currentRow === outputFilterRuleOutputByte2
            }
        }
        QQC2.Button {
            id: outputFilterRuleOutputByte2AddChannel
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            enabled: component.filterRuleObject.byte2 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte2
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.byte2AddChannel
                    ? qsTr("Add Event Track Value:\nYes")
                    : qsTr("Add Event Track Value:\nNo")
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
                visible: component.currentRow === outputFilterRuleOutputByte2
            }
        }
    }
    RowLayout {
        id: outputFilterRuleOutputByte3
        function goNext() { }
        function goPrevious() { component.currentRow = outputFilterRuleOutputByte2; }
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
            id: outputFilterRuleOutputByte3UseOriginalByte
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
                visible: component.currentRow === outputFilterRuleOutputByte3
            }
        }
        QQC2.Button {
            id: outputFilterRuleOutputByte3Value
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
                visible: component.currentRow === outputFilterRuleOutputByte3
            }
        }
        QQC2.Button {
            id: outputFilterRuleOutputByte3AddChannel
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            enabled: component.filterRuleObject.byte3 !== Zynthbox.MidiRouterFilterEntryRewriter.OriginalByte3
            text: component.filterRuleObject === null
                ? "(no filter rule selected)"
                : component.filterRuleObject.byte3AddChannel
                    ? qsTr("Add Event Track Value:\nYes")
                    : qsTr("Add Event Track Value:\nNo")
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
                visible: component.currentRow === outputFilterRuleOutputByte3
            }
        }
    }
    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}
