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
            case "SWITCH_BACK_LONG":
                contentStack.pop();
                returnValue = true;
                break;
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
            case "SWITCH_SELECT_LONG":
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
    property QtObject currentRow: outputFilterHeader
    readonly property QtObject filterObject: _private.selectedDeviceObject && _private.selectedOutputFilterIndex > -1 ? _private.selectedDeviceObject.outputEventFilter.entries[_private.selectedOutputFilterIndex] : null
    ColumnLayout {
        width: component.contentWidth - component.QQC2.ScrollBar.vertical.width
        Component {
            id: outputFilterRuleComponent
            MidiControllerSettingsOutputFilterRule {}
        }
        Kirigami.Heading {
            id: outputFilterHeader
            function goNext() { component.currentRow = outputFilterCUIAEventRow; }
            function goPrevious() { }
            Layout.fillWidth: true
            text: component.filterObject ? qsTr("Output Filter %1").arg(_private.selectedOutputFilterIndex + 1) : ""
        }
        RowLayout {
            id: outputFilterCUIAEventRow
            function goNext() {
                if (outputFilterTrackPart.visible) {
                    component.currentRow = outputFilterTrackPart;
                } else if (outputFilterValuesRow.visible) {
                    component.currentRow = outputFilterValuesRow;
                } else {
                    component.currentRow = addOutputFilterRuleButton;
                }
            }
            function goPrevious() { component.currentRow = outputFilterHeader; }
            function selectPressed() { outputFilterCUIAEventPicker.onClicked(); }
            Layout.fillWidth: true
            QQC2.Button {
                id: outputFilterCUIAEventPicker
                Layout.fillWidth: true
                text: component.filterObject === null
                    ? "(no filter rule selected)"
                    : qsTr("UI Event:\n%1").arg(Zynthbox.CUIAHelper.cuiaTitle(component.filterObject.cuiaEvent))
                onClicked: {
                    cuiaEventPicker.pickEvent(component.filterObject.cuiaEvent, function(newEvent) {
                        component.filterObject.cuiaEvent = newEvent;
                    });
                }
                checked: component.currentRow === outputFilterCUIAEventRow
            }
        }
        RowLayout {
            id: outputFilterTrackPart
            function goNext() {
                if (outputFilterValuesRow.visible) {
                    component.currentRow = outputFilterValuesRow;
                } else {
                    component.currentRow = addOutputFilterRuleButton;
                }
            }
            function goPrevious() { component.currentRow = outputFilterCUIAEventRow; }
            function knob0up() {
                component.filterObject.originTrack = Math.min(Zynthbox.Plugin.sketchpadTrackCount - 1, component.filterObject.originTrack + 1);
            }
            function knob0down() {
                component.filterObject.originTrack = Math.max(-2, component.filterObject.originTrack - 1);
            }
            function knob1up() {
                component.filterObject.originPart = Math.min(Zynthbox.Plugin.sketchpadPartCount - 1, component.filterObject.originPart + 1);
            }
            function knob1down() {
                component.filterObject.originPart = Math.max(-2, component.filterObject.originPart - 1);
            }
            function selectPressed() {
                outputFilterListenForEvent.onClicked();
            }
            Layout.fillWidth: true
            visible: Zynthbox.CUIAHelper.cuiaEventWantsATrack(component.filterObject.cuiaEvent) || Zynthbox.CUIAHelper.cuiaEventWantsAPart(component.filterObject.cuiaEvent)
            QQC2.Button {
                id: outputFilterOriginTrack
                function selectPressed() { onClicked(); }
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                visible: Zynthbox.CUIAHelper.cuiaEventWantsATrack(component.filterObject.cuiaEvent)
                text: component.filterObject === null
                    ? ""
                    : qsTr("Track:\n%1").arg(Zynthbox.ZynthboxBasics.trackLabelText(component.filterObject.originTrack))
                onClicked: {
                    trackPicker.pickTrack(component.filterObject.originTrack, function(newTrack) {
                        component.filterObject.originTrack = newTrack;
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
                    visible: component.currentRow === outputFilterTrackPart
                }
            }
            QQC2.Button {
                id: outputFilterOriginPart
                function selectPressed() { onClicked(); }
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                visible: Zynthbox.CUIAHelper.cuiaEventWantsAPart(component.filterObject.cuiaEvent)
                text: component.filterObject === null
                    ? ""
                    : qsTr("Part:\n%1").arg(Zynthbox.ZynthboxBasics.partLabelText(component.filterObject.originPart))
                onClicked: {
                    partPicker.pickPart(component.filterObject.originPart, function(newPart) {
                        component.filterObject.originPart = newPart;
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
                    visible: component.currentRow === outputFilterTrackPart
                }
            }
        }
        RowLayout {
            id: outputFilterValuesRow
            function goNext() { component.currentRow = addOutputFilterRuleButton; }
            function goPrevious() {
                if (outputFilterTrackPart.visible) {
                    component.currentRow = outputFilterTrackPart;
                } else {
                    component.currentRow = outputFilterCUIAEventRow;
                }
            }
            function knob0up() {
                component.filterObject.valueMinimum = Math.min(127, component.filterObject.valueMinimum + 1);
            }
            function knob0down() {
                component.filterObject.valueMinimum = Math.max(0, component.filterObject.valueMinimum - 1);
            }
            function knob1up() {
                component.filterObject.valueMaximum = Math.min(127, component.filterObject.valueMaximum + 1);
            }
            function knob1down() {
                component.filterObject.valueMaximum = Math.max(0, component.filterObject.valueMaximum - 1);
            }
            Layout.fillWidth: true
            visible: Zynthbox.CUIAHelper.cuiaEventWantsAValue(component.filterObject.cuiaEvent)
            QQC2.Button {
                id: outputFilterValueMinimumPicker
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                text: component.filterObject === null
                    ? ""
                    : qsTr("Minimum Value:\n%1").arg(component.filterObject.valueMinimum)
                onClicked: {
                    midiBytePicker.pickByte(component.filterObject.valueMinimum, 1, function(newByte, messageSize) {
                        component.filterObject.valueMinimum = newByte;
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
                    visible: component.currentRow === outputFilterValuesRow
                }
            }
            QQC2.Button {
                id: outputFilterValueMaximumPicker
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                text: component.filterObject === null
                    ? ""
                    : qsTr("Maximum Value:\n%1").arg(component.filterObject.valueMaximum)
                onClicked: {
                    midiBytePicker.pickByte(component.filterObject.valueMaximum, 1, function(newByte, messageSize) {
                        component.filterObject.valueMaximum = newByte;
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
                    visible: component.currentRow === outputFilterValuesRow
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
                id: addOutputFilterRuleButton
                function goNext() {
                    if (outputFilterRewriteRulesRepeater.count > 0) {
                        component.currentRow = outputFilterRewriteRulesRepeater.itemAt(0);
                    }
                }
                function goPrevious() { 
                    if (outputFilterValuesRow.visible) {
                        component.currentRow = outputFilterValuesRow;
                    } else if (outputFilterTrackPart.visible) {
                        component.currentRow = outputFilterTrackPart;
                    } else {
                        component.currentRow = outputFilterCUIAEventRow;
                    }
                }
                function selectPressed() { onClicked(); }
                text: qsTr("Add new rewrite rule")
                onClicked: {
                    let newRule = component.filterObject.addRewriteRule();
                    newRule.byteSize = Zynthbox.MidiRouterFilterEntryRewriter.EventSize3;
                    newRule.byte1 = Zynthbox.MidiRouterFilterEntryRewriter.ExplicitByte16;
                    newRule.byte1AddChannel = true;
                    newRule.byte2 = Zynthbox.MidiRouterFilterEntryRewriter.ExplicitByte0;
                    newRule.byte3 = Zynthbox.MidiRouterFilterEntryRewriter.ExplicitByte127;
                    let newRuleIndex = component.filterObject.indexOf(newRule);
                    _private.selectedOutputFilterRuleIndex = newRuleIndex;
                    contentStack.push(outputFilterRuleComponent, { containingPage: component.containingPage, _private: component._private });
                }
                checked: component.currentRow === addOutputFilterRuleButton
            }
        }
        Repeater {
            id: outputFilterRewriteRulesRepeater
            model: component.filterObject ? component.filterObject.rewriteRules : 0
            property QtObject currentlySelectedRule: null
            delegate: RowLayout {
                id: outputFilterRulesRepeaterDelegate
                readonly property QtObject ruleObject: modelData
                function goNext() {
                    if (model.index === outputFilterRewriteRulesRepeater.count - 1) {
                        // Do nothing, there's nothing beyond this place...
                    } else {
                        component.currentRow = outputFilterRewriteRulesRepeater.itemAt(model.index + 1);
                        outputFilterRewriteRulesRepeater.currentlySelectedRule = modelData;
                    }
                }
                function goPrevious() {
                    if (model.index === 0) {
                        component.currentRow = addOutputFilterRuleButton;
                        outputFilterRewriteRulesRepeater.currentlySelectedRule = null;
                    } else {
                        component.currentRow = outputFilterRewriteRulesRepeater.itemAt(model.index - 1);
                        outputFilterRewriteRulesRepeater.currentlySelectedRule = modelData;
                    }
                }
                function knob0up() {
                    if (model.index < outputFilterRewriteRulesRepeater.count - 1) {
                        component.filterObject.swapRewriteRules(modelData, component.filterObject.rewriteRules[model.index + 1]);
                    }
                }
                function knob0down() {
                    if (model.index > 0) {
                        component.filterObject.swapRewriteRules(component.filterObject.rewriteRules[model.index - 1], modelData);
                    }
                }
                function selectPressed() {
                    _private.selectedOutputFilterRuleIndex = model.index;
                    contentStack.push(outputFilterRuleComponent, { containingPage: component.containingPage, _private: component._private });
                }
                Layout.fillWidth: true
                QQC2.Button {
                    Layout.fillWidth: false
                    Layout.minimumWidth: height
                    Layout.maximumWidth: height
                    display: QQC2.AbstractButton.IconOnly
                    icon.name: "edit-delete"
                    onClicked: {
                        component.currentRow = outputFilterRewriteRulesRepeater.itemAt(model.index);
                        outputFilterRewriteRulesRepeater.currentlySelectedRule = modelData;
                        confirmer.confirmSomething(qsTr("Delete Filter Rule?"), qsTr("Are you sure that you want to delete output filter rule %1:\n%2").arg(model.index + 1).arg(modelData.description), function() {
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
                        outputFilterRulesRepeaterDelegate.knob0up();
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: false
                    Layout.minimumWidth: height
                    Layout.maximumWidth: height
                    display: QQC2.AbstractButton.IconOnly
                    icon.name: "go-down"
                    enabled: model.index < outputFilterRewriteRulesRepeater.count - 1
                    onClicked: {
                        outputFilterRulesRepeaterDelegate.knob0down();
                    }
                    Zynthian.KnobIndicator {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            horizontalCenter: parent.left
                            leftMargin: -outputFilterRulesRepeaterDelegate.spacing / 2
                        }
                        height: Kirigami.Units.iconSizes.smallMedium
                        width: Kirigami.Units.iconSizes.smallMedium
                        knobId: 0
                        visible: component.currentRow === outputFilterRulesRepeaterDelegate
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: false
                    Layout.minimumWidth: height
                    Layout.maximumWidth: height
                    display: QQC2.AbstractButton.IconOnly
                    icon.name: "document-edit"
                    onClicked: {
                        outputFilterRulesRepeaterDelegate.selectPressed();
                    }
                    checked: component.currentRow === outputFilterRulesRepeaterDelegate
                }
            }
        }
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }
}
