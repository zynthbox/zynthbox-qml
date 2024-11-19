/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Settings page for Midi Controllers - Individual Filter Display

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
    property QtObject currentRow: inputFilterHeader
    readonly property QtObject filterObject: _private.selectedDeviceObject && _private.selectedInputFilterIndex > -1 ? _private.selectedDeviceObject.inputEventFilter.entries[_private.selectedInputFilterIndex] : null
    ColumnLayout {
        width: component.contentWidth - component.QQC2.ScrollBar.vertical.width
        Component {
            id: inputFilterRuleComponent
            MidiControllerSettingsInputFilterRule {}
        }
        Kirigami.Heading {
            id: inputFilterHeader
            function goNext() { component.currentRow = inputFilterFirstSettings; }
            function goPrevious() { }
            Layout.fillWidth: true
            text: component.filterObject ? qsTr("Input Filter %1").arg(_private.selectedInputFilterIndex + 1) : ""
        }
        RowLayout {
            id: inputFilterFirstSettings
            function goNext() { component.currentRow = inputFilterMinimumRow; }
            function goPrevious() { component.currentRow = inputFilterHeader; }
            function knob0up() {
                component.filterObject.targetTrack = Math.min(Zynthbox.Plugin.sketchpadTrackCount - 1, component.filterObject.targetTrack + 1);
            }
            function knob0down() {
                component.filterObject.targetTrack = Math.max(-1, component.filterObject.targetTrack - 1);
            }
            function knob1up() {
                component.filterObject.requireRange = true;
            }
            function knob1down() {
                component.filterObject.requireRange = false;
            }
            function selectPressed() {
                inputFilterListenForEvent.onClicked();
            }
            Layout.fillWidth: true
            QQC2.Button {
                id: inputFilterTargetTrack
                function selectPressed() { onClicked(); }
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                text: component.filterObject === null
                    ? ""
                    : qsTr("Send Matched Midi Event To:\n%1").arg(Zynthbox.ZynthboxBasics.trackLabelText(component.filterObject.targetTrack))
                onClicked: {
                    trackPicker.pickTrack(component.filterObject.targetTrack, function(newTrack) {
                        component.filterObject.targetTrack = newTrack;
                    });
                    // FIXME This is... not actually a thing, right? To send the event forward untouched, we'll just need a rule that does that (current-track target, all bytes untouched)
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
                    visible: component.currentRow === inputFilterFirstSettings
                }
            }
            QQC2.Button {
                id: inputFilterRequireRange
                function selectPressed() { onClicked(); }
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                text: component.filterObject === null
                    ? ""
                    : component.filterObject.requireRange
                        ? qsTr("Match Range:\nYes")
                        : qsTr("Match Range:\nNo")
                onClicked: {
                    component.filterObject.requireRange = !component.filterObject.requireRange;
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
                    visible: component.currentRow === inputFilterFirstSettings
                }
            }
            QQC2.Button {
                id: inputFilterListenForEvent
                function selectPressed() { onClicked(); }
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                text: qsTr("Listen For\nIncoming Event...")
                onClicked: {
                    midiEventListener.listenForEvent(_private.selectedDeviceObject.hardwareId, function(selectedEventBytes) {
                        component.filterObject.requireRange = false;
                        if (selectedEventBytes.length === 1) {
                            component.filterObject.requiredBytes = 1;
                            component.filterObject.byte1Minimum = selectedEventBytes[0];
                        } else if (selectedEventBytes.length === 2) {
                            component.filterObject.requiredBytes = 2;
                            component.filterObject.byte1Minimum = selectedEventBytes[0];
                            component.filterObject.byte2Minimum = selectedEventBytes[1];
                        } else if (selectedEventBytes.length === 3) {
                            component.filterObject.requiredBytes = 3;
                            component.filterObject.byte1Minimum = selectedEventBytes[0];
                            component.filterObject.byte2Minimum = selectedEventBytes[1];
                            component.filterObject.byte3Minimum = selectedEventBytes[2];
                        } else {
                            console.log("We've ended up selecting something super weird, and have an event that's not between 1 and 3 bytes long:", selectedEventBytes);
                        }
                    });
                }
                checked: component.currentRow === inputFilterFirstSettings
            }
        }
        RowLayout {
            id: inputFilterMinimumRow
            function goNext() {
                if (component.filterObject.requireRange) {
                    component.currentRow = inputFilterMaximumRow;
                } else {
                    component.currentRow = addInputFilterRuleButton;
                }
            }
            function goPrevious() { component.currentRow = inputFilterFirstSettings; }
            function knob0up() {
                component.filterObject.byte1Minimum = Math.min(255, component.filterObject.byte1Minimum + 1);
                component.filterObject.requiredBytes = midiBytePicker.byteValueToMessageSize(component.filterObject.byte1Minimum);
                if (component.filterObject.requireRange === false) {
                    component.filterObject.byte1Maximum = component.filterObject.byte1Minimum;
                }
            }
            function knob0down() {
                component.filterObject.byte1Minimum = Math.max(128, component.filterObject.byte1Minimum - 1);
                component.filterObject.requiredBytes = midiBytePicker.byteValueToMessageSize(component.filterObject.byte1Minimum);
                if (component.filterObject.requireRange === false) {
                    component.filterObject.byte1Maximum = component.filterObject.byte1Minimum;
                }
            }
            function knob1up() {
                component.filterObject.byte2Minimum = Math.min(127, component.filterObject.byte2Minimum + 1);
                if (component.filterObject.requireRange === false) {
                    component.filterObject.byte2Maximum = component.filterObject.byte2Minimum;
                }
            }
            function knob1down() {
                component.filterObject.byte2Minimum = Math.max(0, component.filterObject.byte2Minimum - 1);
                if (component.filterObject.requireRange === false) {
                    component.filterObject.byte2Maximum = component.filterObject.byte2Minimum;
                }
            }
            function knob2up() {
                component.filterObject.byte3Minimum = Math.min(127, component.filterObject.byte3Minimum + 1);
                if (component.filterObject.requireRange === false) {
                    component.filterObject.byte3Maximum = component.filterObject.byte3Minimum;
                }
            }
            function knob2down() {
                component.filterObject.byte3Minimum = Math.max(0, component.filterObject.byte3Minimum - 1);
                if (component.filterObject.requireRange === false) {
                    component.filterObject.byte3Maximum = component.filterObject.byte3Minimum;
                }
            }
            Layout.fillWidth: true
            QQC2.Button {
                id: inputFilterByte1MinimumPicker
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                text: component.filterObject === null
                    ? ""
                    : component.filterObject.requireRange
                        ? qsTr("Message Type Minimum:\n%1").arg(midiBytePicker.byteValueToMessageName(component.filterObject.byte1Minimum))
                        : qsTr("Message Type:\n%1").arg(midiBytePicker.byteValueToMessageName(component.filterObject.byte1Minimum))
                onClicked: {
                    midiBytePicker.pickByte(component.filterObject.byte1Minimum, 0, function(newByte, messageSize) {
                        // Picking byte value resets the message size to match
                        component.filterObject.requiredBytes = messageSize;
                        component.filterObject.byte1Minimum = newByte;
                        if (component.filterObject.requireRange === false) {
                            component.filterObject.byte1Maximum = newByte;
                        }
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
                    visible: component.currentRow === inputFilterMinimumRow
                }
            }
            QQC2.Button {
                id: inputFilterByte2MinimumPicker
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                enabled: component.filterObject && component.filterObject.requiredBytes > 1
                text: component.filterObject === null
                    ? ""
                    : (127 < component.filterObject.byte1Minimum && component.filterObject.byte1Minimum < 176)
                        ? component.filterObject.requireRange
                            ? qsTr("First Note:\n%1").arg(Zynthbox.KeyScales.midiNoteName(component.filterObject.byte2Minimum))
                            : qsTr("Note:\n%1").arg(Zynthbox.KeyScales.midiNoteName(component.filterObject.byte2Minimum))
                        : (175 < component.filterObject.byte1Minimum && component.filterObject.byte1Minimum < 192)
                            ? component.filterObject.requireRange
                                ? qsTr("First CC Function:\n%1").arg(midiBytePicker.byteValueToCCName(component.filterObject.byte2Minimum))
                                : qsTr("CC Function:\n%1").arg(midiBytePicker.byteValueToCCName(component.filterObject.byte2Minimum))
                            : component.filterObject.requireRange
                                ? qsTr("Byte 2 Minimum:\n%1").arg(component.filterObject.byte2Minimum)
                                : qsTr("Byte 2:\n%1").arg(component.filterObject.byte2Minimum)
                onClicked: {
                    if (127 < component.filterObject.byte1Minimum && component.filterObject.byte1Minimum < 176) {
                        // Then it's a note on/off message, and we should be picking a note for this value
                        notePicker.pickNote(component.filterObject.byte2Minimum, function(newNote) {
                            component.filterObject.byte2Minimum = newNote;
                            if (component.filterObject.requireRange === false) {
                                component.filterObject.byte2Maximum = newByte;
                            }
                        });
                    } else if (175 < component.filterObject.byte1Minimum && component.filterObject.byte1Minimum < 192) {
                        midiBytePicker.pickByte(component.filterObject.byte2Minimum, 2, function(newByte, messageSize) {
                            component.filterObject.byte2Minimum = newByte;
                            if (component.filterObject.requireRange === false) {
                                component.filterObject.byte2Maximum = newByte;
                            }
                        });
                    } else {
                        midiBytePicker.pickByte(component.filterObject.byte2Minimum, 1, function(newByte, messageSize) {
                            component.filterObject.byte2Minimum = newByte;
                            if (component.filterObject.requireRange === false) {
                                component.filterObject.byte2Maximum = newByte;
                            }
                        });
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
                    knobId: 1
                    visible: component.currentRow === inputFilterMinimumRow && parent.enabled
                }
            }
            QQC2.Button {
                id: inputFilterByte3MinimumPicker
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                enabled: component.filterObject && component.filterObject.requiredBytes > 2
                text: component.filterObject === null
                    ? ""
                    : (127 < component.filterObject.byte1Minimum && component.filterObject.byte1Minimum < 160)
                        ? component.filterObject.requireRange
                            ? qsTr("Lowest Velocity:\n%1").arg(component.filterObject.byte3Minimum)
                            : qsTr("Velocity:\n%1").arg(component.filterObject.byte3Minimum)
                        : (159 < component.filterObject.byte1Minimum && component.filterObject.byte1Minimum < 176)
                            ? component.filterObject.requireRange
                                ? qsTr("Minimum Pressure:\n%1").arg(component.filterObject.byte3Minimum)
                                : qsTr("Pressure:\n%1").arg(component.filterObject.byte3Minimum)
                            : (175 < component.filterObject.byte1Minimum && component.filterObject.byte1Minimum < 192)
                                ? component.filterObject.requireRange
                                    ? qsTr("CC Value Minimum:\n%1").arg(component.filterObject.byte3Minimum)
                                    : qsTr("CC Value:\n%1").arg(component.filterObject.byte3Minimum)
                                : (191 < component.filterObject.byte1Minimum && component.filterObject.byte1Minimum < 208)
                                        ? component.filterObject.requireRange
                                            ? qsTr("First Program:\n%1").arg(component.filterObject.byte3Minimum)
                                            : qsTr("Program:\n%1").arg(component.filterObject.byte3Minimum)
                                        : (207 < component.filterObject.byte1Minimum && component.filterObject.byte1Minimum < 224)
                                            ? component.filterObject.requireRange
                                                ? qsTr("Minimum Pressure:\n%1").arg(component.filterObject.byte3Minimum)
                                                : qsTr("Pressure:\n%1").arg(component.filterObject.byte3Minimum)
                                            : component.filterObject.requireRange
                                                ? qsTr("Byte 3 Minimum:\n%1").arg(component.filterObject.byte3Minimum)
                                                : qsTr("Byte 3:\n%1").arg(component.filterObject.byte3Minimum)
                onClicked: {
                    midiBytePicker.pickByte(component.filterObject.byte3Minimum, 1, function(newByte, messageSize) {
                        component.filterObject.byte3Minimum = newByte;
                        if (component.filterObject.requireRange === false) {
                            component.filterObject.byte3Maximum = newByte;
                        }
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
                    visible: component.currentRow === inputFilterMinimumRow && parent.enabled
                }
            }
        }
        RowLayout {
            id: inputFilterMaximumRow
            function goNext() { component.currentRow = addInputFilterRuleButton; }
            function goPrevious() { component.currentRow = inputFilterMinimumRow; }
            function knob0up() {
                component.filterObject.byte1Maximum = Math.min(255, component.filterObject.byte1Maximum + 1);
                component.filterObject.requiredBytes = midiBytePicker.byteValueToMessageSize(component.filterObject.byte1Maximum);
            }
            function knob0down() {
                component.filterObject.byte1Maximum = Math.max(128, component.filterObject.byte1Maximum - 1);
                component.filterObject.requiredBytes = midiBytePicker.byteValueToMessageSize(component.filterObject.byte1Maximum);
            }
            function knob1up() {
                component.filterObject.byte2Maximum = Math.min(127, component.filterObject.byte2Maximum + 1);
            }
            function knob1down() {
                component.filterObject.byte2Maximum = Math.max(0, component.filterObject.byte2Maximum - 1);
            }
            function knob2up() {
                component.filterObject.byte3Maximum = Math.min(127, component.filterObject.byte3Maximum + 1);
            }
            function knob2down() {
                component.filterObject.byte3Maximum = Math.max(0, component.filterObject.byte3Maximum - 1);
            }
            visible: component.filterObject !== null && component.filterObject.requireRange
            Layout.fillWidth: true
            QQC2.Button {
                id: inputFilterByte1MaximumPicker
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                text: component.filterObject === null
                    ? ""
                    : component.filterObject.requireRange
                        ? qsTr("Message Type Maximum:\n%1").arg(midiBytePicker.byteValueToMessageName(component.filterObject.byte1Maximum))
                        : qsTr("Message Type:\n%1").arg(midiBytePicker.byteValueToMessageName(component.filterObject.byte1Maximum))
                onClicked: {
                    midiBytePicker.pickByte(component.filterObject.byte1Maximum, 0, function(newByte, messageSize) {
                        // Picking byte value resets the message size to match
                        component.filterObject.requiredBytes = messageSize;
                        component.filterObject.byte1Maximum = newByte;
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
                    visible: component.currentRow === inputFilterMaximumRow
                }
            }
            QQC2.Button {
                id: inputFilterByte2MaximumPicker
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                enabled: component.filterObject && component.filterObject.requiredBytes > 1
                text: component.filterObject === null
                    ? ""
                    : 127 < component.filterObject.byte1Maximum && component.filterObject.byte1Maximum < 176
                        ? qsTr("Last Note:\n%1").arg(Zynthbox.KeyScales.midiNoteName(component.filterObject.byte2Maximum))
                        : (175 < component.filterObject.byte1Minimum && component.filterObject.byte1Minimum < 192)
                             ? qsTr("Last CC Function:\n%1").arg(midiBytePicker.byteValueToCCName(component.filterObject.byte2Maximum))
                             : (191 < component.filterObject.byte1Minimum && component.filterObject.byte1Minimum < 208)
                                ? qsTr("Last Program:\n%1").arg(component.filterObject.byte2Maximum)
                                : (207 < component.filterObject.byte1Minimum && component.filterObject.byte1Minimum < 224)
                                    ? qsTr("Maximum Pressure:\n%1").arg(component.filterObject.byte2Maximum)
                                    : qsTr("Byte 2 Maximum:\n%1").arg(component.filterObject.byte2Maximum)
                onClicked: {
                    if (127 < component.filterObject.byte1Maximum && component.filterObject.byte1Maximum < 176) {
                        // Then it's a note on/off message, and we should be picking a note for this value
                        notePicker.pickNote(component.filterObject.byte2Maximum, function(newNote) {
                            component.filterObject.byte2Maximum = newNote;
                        });
                    } else if (175 < component.filterObject.byte1Minimum && component.filterObject.byte1Minimum < 192) {
                        midiBytePicker.pickByte(component.filterObject.byte2Maximum, 2, function(newByte, messageSize) {
                            component.filterObject.byte2Maximum = newByte;
                        });
                    } else {
                        midiBytePicker.pickByte(component.filterObject.byte2Maximum, 1, function(newByte, messageSize) {
                            component.filterObject.byte2Maximum = newByte;
                        });
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
                    knobId: 1
                    visible: component.currentRow === inputFilterMaximumRow && parent.enabled
                }
            }
            QQC2.Button {
                id: inputFilterByte3MaximumPicker
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                enabled: component.filterObject && component.filterObject.requiredBytes > 2
                text: component.filterObject === null
                    ? ""
                    : (127 < component.filterObject.byte1Maximum && component.filterObject.byte1Maximum < 160)
                        ? qsTr("Highest Velocity:\n%1").arg(component.filterObject.byte3Maximum)
                        : (159 < component.filterObject.byte1Maximum && component.filterObject.byte1Maximum < 176)
                            ? qsTr("Maximum Pressure:\n%1").arg(component.filterObject.byte3Maximum)
                            : (175 < component.filterObject.byte1Minimum && component.filterObject.byte1Minimum < 192)
                                ? qsTr("CC Value Maximum:\n%1").arg(component.filterObject.byte3Maximum)
                                : qsTr("Byte 3 Maximum:\n%1").arg(component.filterObject.byte3Maximum)
                onClicked: {
                    midiBytePicker.pickByte(component.filterObject.byte3Maximum, 2, function(newByte, messageSize) {
                        component.filterObject.byte3Maximum = newByte;
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
                    visible: component.currentRow === inputFilterMaximumRow && parent.enabled
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Kirigami.Heading {
                level: 2
                Layout.fillWidth: true
                text: qsTr("Rewrite Rules")
            }
            QQC2.Button {
                id: addInputFilterRuleButton
                function goNext() {
                    if (inputFilterRewriteRulesRepeater.count > 0) {
                        component.currentRow = inputFilterRewriteRulesRepeater.itemAt(0);
                    }
                }
                function goPrevious() { 
                    if (component.filterObject.requireRange) {
                        component.currentRow = inputFilterMaximumRow;
                    } else {
                        component.currentRow = inputFilterMinimumRow;
                    }
                }
                function selectPressed() { onClicked(); }
                text: qsTr("Add new rewrite rule")
                onClicked: {
                    let newRule = component.filterObject.addRewriteRule();
                    let newRuleIndex = component.filterObject.indexOf(newRule);
                    _private.selectedInputFilterRuleIndex = newRuleIndex;
                    contentStack.push(inputFilterRuleComponent, { containingPage: component.containingPage, _private: component._private });
                }
                checked: component.currentRow === addInputFilterRuleButton
            }
        }
        Repeater {
            id: inputFilterRewriteRulesRepeater
            model: component.filterObject ? component.filterObject.rewriteRules : 0
            property QtObject currentlySelectedRule: null
            delegate: RowLayout {
                id: inputFilterRulesRepeaterDelegate
                function goNext() {
                    if (model.index === inputFilterRewriteRulesRepeater.count - 1) {
                        // Do nothing, there's nothing beyond this place...
                    } else {
                        component.currentRow = inputFilterRewriteRulesRepeater.itemAt(model.index + 1);
                        inputFilterRewriteRulesRepeater.currentlySelectedRule = modelData;
                    }
                }
                function goPrevious() {
                    if (model.index === 0) {
                        component.currentRow = addInputFilterRuleButton;
                        inputFilterRewriteRulesRepeater.currentlySelectedRule = null;
                    } else {
                        component.currentRow = inputFilterRewriteRulesRepeater.itemAt(model.index - 1);
                        inputFilterRewriteRulesRepeater.currentlySelectedRule = modelData;
                    }
                }
                function knob0up() {
                    if (model.index < inputFilterRewriteRulesRepeater.count - 1) {
                        component.filterObject.swapRewriteRules(modelData, component.filterObject.rewriteRules[model.index + 1]);
                    }
                }
                function knob0down() {
                    if (model.index > 0) {
                        component.filterObject.swapRewriteRules(component.filterObject.rewriteRules[model.index - 1], modelData);
                    }
                }
                function selectPressed() {
                    _private.selectedInputFilterRuleIndex = model.index;
                    contentStack.push(inputFilterRuleComponent, { containingPage: component.containingPage, _private: component._private });
                }
                Layout.fillWidth: true
                QQC2.Button {
                    Layout.fillWidth: false
                    Layout.minimumWidth: height
                    Layout.maximumWidth: height
                    display: QQC2.AbstractButton.IconOnly
                    icon.name: "edit-delete"
                    onClicked: {
                        component.currentRow = inputFilterRewriteRulesRepeater.itemAt(model.index);
                        inputFilterRewriteRulesRepeater.currentlySelectedRule = modelData;
                        confirmer.confirmSomething(qsTr("Delete Filter Rule?"), qsTr("Are you sure that you want to delete input filter rule %1:\n%2").arg(model.index + 1).arg(modelData.description), function() {
                            component.filterObject.deleteRewriteRule(model.index);
                        });
                    }
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    text: "Rule %1:\n%2".arg(model.index + 1).arg(modelData.description)
                }
                QQC2.Button {
                    Layout.fillWidth: false
                    Layout.minimumWidth: height
                    Layout.maximumWidth: height
                    display: QQC2.AbstractButton.IconOnly
                    icon.name: "go-up"
                    enabled: model.index > 0
                    onClicked: {
                        inputFilterRulesRepeaterDelegate.knob0up();
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: false
                    Layout.minimumWidth: height
                    Layout.maximumWidth: height
                    display: QQC2.AbstractButton.IconOnly
                    icon.name: "go-down"
                    enabled: model.index < inputFilterRewriteRulesRepeater.count - 1
                    onClicked: {
                        inputFilterRulesRepeaterDelegate.knob0down();
                    }
                    Zynthian.KnobIndicator {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            horizontalCenter: parent.left
                            leftMargin: -inputFilterRulesRepeaterDelegate.spacing / 2
                        }
                        height: Kirigami.Units.iconSizes.smallMedium
                        width: Kirigami.Units.iconSizes.smallMedium
                        knobId: 0
                        visible: component.currentRow === inputFilterRulesRepeaterDelegate
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: false
                    Layout.minimumWidth: height
                    Layout.maximumWidth: height
                    display: QQC2.AbstractButton.IconOnly
                    icon.name: "document-edit"
                    onClicked: {
                        inputFilterRulesRepeaterDelegate.selectPressed();
                    }
                    checked: component.currentRow === inputFilterRulesRepeaterDelegate
                }
            }
        }
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }
}
