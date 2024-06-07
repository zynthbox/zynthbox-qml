/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Equalizer settings panel for an individual synth or fx slot

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
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.DialogQuestion {
    id: component
    function showEqualizer(channel, slotType, slotIndex) {
        _private.slotIndex = slotIndex;
        _private.slotType = slotType;
        _private.selectedChannel = channel;
        component.open();
    }

    onAccepted: {
        _private.selectedChannel = null;
    }

    height: Kirigami.Units.gridUnit * 30
    width: Kirigami.Units.gridUnit * 50

    acceptText: qsTr("Close")
    rejectText: ""
    title: _private.engineData === null ? "" : qsTr("%1 Equalizer").arg(_private.engineData.name)

    cuiaCallback: function(cuia) {
        let returnValue = false;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                component.reject();
                returnValue = true;
                break;
            case "NAVIGATE_LEFT":
            case "SELECT_DOWN":
                _private.goLeft();
                returnValue = true;
                break;
            case "NAVIGATE_RIGHT":
            case "SELECT_UP":
                _private.goRight();
                returnValue = true;
                break;
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
            case "SWITCH_SELECT_LONG":
                _private.select();
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
                _private.goRight();
                returnValue = true;
                break;
            case "KNOB3_DOWN":
                _private.goLeft();
                returnValue = true;
                break;
            case "KNOB0_TOUCHED":
            case "KNOB0_RELEASED":
            case "KNOB1_TOUCHED":
            case "KNOB1_RELEASED":
            case "KNOB2_TOUCHED":
            case "KNOB2_RELEASED":
            case "KNOB3_TOUCHED":
            case "KNOB3_RELEASED":
                returnValue = true;
                break;
        }
        return returnValue;
    }

    contentItem: ColumnLayout {
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 8
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
                property QtObject slotPassthroughClient: selectedChannel === null
                    ? null
                    : slotType === "synth"
                        ? Zynthbox.Plugin.synthPassthroughClients[selectedChannel.chainedSounds[slotIndex]]
                        : slotType === "fx"
                            ? Zynthbox.Plugin.fxPassthroughClients[selectedChannel.id][slotIndex]
                            : null
                function getCurrent() {
                    let currentObject = null;
                    for (let slotIndex = 0; slotIndex < _private.slotPassthroughClient.equaliserSettings.length; ++slotIndex) {
                        if (_private.slotPassthroughClient.equaliserSettings[slotIndex].selected) {
                            currentObject = _private.slotPassthroughClient.equaliserSettings[slotIndex];
                            break;
                        }
                    }
                    if (currentObject === null) {
                        currentObject = _private.slotPassthroughClient.equaliserSettings[0]
                        currentObject.selected = true;
                    }
                    return currentObject;
                }
                function goLeft() {
                    let currentObject = getCurrent();
                    if (currentObject.previous) {
                        currentObject.previous.selected = true;
                    }
                }
                function goRight() {
                    let currentObject = getCurrent();
                    if (currentObject.next) {
                        currentObject.next.selected = true;
                    }
                }
                function select() {
                    let currentObject = getCurrent();
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        currentObject.soloed = !currentObject.soloed;
                    } else {
                        currentObject.active = !currentObject.active;
                    }
                }
                function knob0Up() {
                    let currentObject = getCurrent();
                    currentObject.quality = currentObject.quality + 0.1;
                }
                function knob0Down() {
                    let currentObject = getCurrent();
                    currentObject.quality = currentObject.quality - 0.1;
                }
                function knob1Up() {
                    let currentObject = getCurrent();
                    currentObject.gain = currentObject.gain + 0.01;
                }
                function knob1Down() {
                    let currentObject = getCurrent();
                    currentObject.gain = currentObject.gain - 0.01;
                }
                function knob2Up() {
                    let currentObject = getCurrent();
                    currentObject.frequency = currentObject.frequency + 1;
                }
                function knob2Down() {
                    let currentObject = getCurrent();
                    currentObject.frequency = currentObject.frequency - 1;
                }
                function knob3Up() {
                    goRight();
                }
                function knob3Down() {
                    goLeft();
                }
            }
            QQC2.Label {
                anchors.centerIn: parent
                text: "(visualisation of equaliser bands goes here)"
                opacity: 0.3
            }
            QQC2.Button {
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                }
                text: _private.slotPassthroughClient ? _private.slotPassthroughClient.equaliserEnabled ? qsTr("Equalizer Enabled") :  qsTr("Equalizer Disabled") : ""
                onClicked: {
                    _private.slotPassthroughClient.equaliserEnabled = !_private.slotPassthroughClient.equaliserEnabled;
                }
            }
            QQC2.Button {
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                }
                text: _private.slotPassthroughClient ? _private.slotPassthroughClient.compressorEnabled ? qsTr("Compressor Enabled") :  qsTr("Compressor Disabled") : ""
                onClicked: {
                    _private.slotPassthroughClient.compressorEnabled = !_private.slotPassthroughClient.compressorEnabled;
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 20
            Repeater {
                model: 6
                Item {
                    id: bandDelegate
                    property QtObject filterSettings: _private.slotPassthroughClient === null ? null : _private.slotPassthroughClient.equaliserSettings[model.index]
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 20
                    Rectangle {
                        anchors.fill: parent
                        radius: Kirigami.Units.smallSpacing
                        color: "transparent"
                        border {
                            width: 1
                            color: bandDelegate.filterSettings && bandDelegate.filterSettings.selected ? Kirigami.Theme.focusColor : Kirigami.Theme.textColor
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            bandDelegate.filterSettings.selected = true;
                        }
                    }
                    ColumnLayout {
                        anchors {
                            fill: parent
                            margins: Kirigami.Units.largeSpacing
                        }
                        Kirigami.Heading {
                            text: bandDelegate.filterSettings ? bandDelegate.filterSettings.name : ""
                            level: 3
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit
                            Rectangle {
                                anchors {
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                }
                                height: parent.paintedHeight
                                width: height
                                radius: height / 2
                                color: bandDelegate.filterSettings ? bandDelegate.filterSettings.color : "black"
                            }
                        }
                        Zynthian.PlayGridButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            text: bandDelegate.filterSettings ? bandDelegate.filterSettings.filterTypeName(bandDelegate.filterSettings.filterType) : ""
                            onClicked: {
                                filterTypeCombo.currentIndex = bandDelegate.filterSettings.filterType;
                                filterTypeCombo.onClicked()
                            }
                            Zynthian.ComboBox {
                                id: filterTypeCombo
                                visible: false;
                                model: bandDelegate.filterSettings ? bandDelegate.filterSettings.filterTypeNames() : 0
                                onActivated: {
                                    bandDelegate.filterSettings.filterType = index
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                            ColumnLayout {
                                Layout.fillWidth: true
                                Kirigami.Heading {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    level: 4
                                    text: qsTr("Quality")
                                }
                                QQC2.Dial {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                    Layout.leftMargin: Kirigami.Units.smallSpacing
                                    Layout.rightMargin: Kirigami.Units.smallSpacing
                                    handle: null
                                    value: bandDelegate.filterSettings ? bandDelegate.filterSettings.quality : 0
                                    from: 0
                                    to: 10
                                    stepSize: 0.1
                                    onValueChanged: {
                                        if (bandDelegate.filterSettings) {
                                            bandDelegate.filterSettings.quality = value;
                                        }
                                    }
                                }
                                QQC2.Label {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                                    horizontalAlignment: Text.AlignHCenter
                                    text: bandDelegate.filterSettings ? bandDelegate.filterSettings.quality.toFixed(2) : ""
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                Kirigami.Heading {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    level: 4
                                    text: qsTr("Gain")
                                }
                                QQC2.Dial {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                    Layout.leftMargin: Kirigami.Units.smallSpacing
                                    Layout.rightMargin: Kirigami.Units.smallSpacing
                                    handle: null
                                    value: bandDelegate.filterSettings ? bandDelegate.filterSettings.gain : 0
                                    from: 0
                                    to: 2
                                    stepSize: 0.01
                                    onValueChanged: {
                                        if (bandDelegate.filterSettings) {
                                            bandDelegate.filterSettings.gain = value;
                                        }
                                    }
                                }
                                QQC2.Label {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                                    horizontalAlignment: Text.AlignHCenter
                                    text: bandDelegate.filterSettings ? "%1dB".arg(bandDelegate.filterSettings.gainDb.toFixed(2)) : ""
                                }
                            }
                        }
                        QQC2.Dial {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 6
                            handle: null
                            value: bandDelegate.filterSettings ? bandDelegate.filterSettings.frequency : 0
                            stepSize: 1
                            from: 20
                            to: 20000
                            onValueChanged: {
                                if (bandDelegate.filterSettings) {
                                    bandDelegate.filterSettings.frequency = value;
                                }
                            }
                            QQC2.Label {
                                anchors.fill: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: bandDelegate.filterSettings ? "%1 Hz".arg(bandDelegate.filterSettings.frequency.toFixed(0)) : ""
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            Zynthian.PlayGridButton {
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                Layout.fillHeight: false
                                text: qsTr("S")
                                checked: bandDelegate.filterSettings ? bandDelegate.filterSettings.soloed : false
                                onClicked: {
                                    bandDelegate.filterSettings.soloed =!bandDelegate.filterSettings.soloed;
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 1
                            }
                            Zynthian.PlayGridButton {
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                Layout.fillHeight: false
                                text: qsTr("A")
                                checked: bandDelegate.filterSettings ? bandDelegate.filterSettings.active : false
                                onClicked: {
                                    bandDelegate.filterSettings.active = !bandDelegate.filterSettings.active;
                                }
                            }
                        }
                    }
                }
            }
            Item {
                id: compressorSettings
                property QtObject filterSettings: null
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                Layout.preferredHeight: Kirigami.Units.gridUnit * 20
                Rectangle {
                    anchors.fill: parent
                    radius: Kirigami.Units.smallSpacing
                    color: "transparent"
                    border {
                        width: 1
                        color: bandDelegate.filterSettings && bandDelegate.filterSettings.selected ? Kirigami.Theme.focusColor : Kirigami.Theme.textColor
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                    }
                }
                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.largeSpacing
                    }
                    Kirigami.Heading {
                        text: qsTr("Compressor")
                        level: 3
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
