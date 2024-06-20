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
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.DialogQuestion {
    id: component
    function showEqualizer(channel, slotType, slotIndex) {
        _private.slotIndex = slotIndex;
        _private.selectedChannel = channel;
        _private.slotType = slotType;
        component.open();
        _private.slotPassthroughClient.compressorSettings.registerObserver();
    }

    onRejected: {
        _private.slotPassthroughClient.compressorSettings.unregisterObserver();
        _private.slotType = "";
        _private.selectedChannel = null;
        _private.slotIndex = -1;
    }
    onAccepted: {
        _private.slotPassthroughClient.compressorSettings.unregisterObserver();
        _private.slotType = "";
        _private.selectedChannel = null;
        _private.slotIndex = -1;
    }

    height: applicationWindow().height
    width: applicationWindow().width

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
                _private.knob3Up();
                returnValue = true;
                break;
            case "KNOB3_DOWN":
                _private.knob3Down();
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
            case "MODE_SWITCH_SHORT":
            case "MODE_SWITCH_BOLD":
            case "MODE_SWITCH_LONG":
                // when this dialog is open, switching tracks or parts would be... a problem in general, so let's not let that happen
                returnValue = true;
                break;
        }
        return returnValue;
    }

    header: RowLayout {
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 2
            text: component.title
        }
        QQC2.Button {
            text: _private.slotPassthroughClient ? _private.slotPassthroughClient.equaliserEnabled ? qsTr("Equalizer Enabled") :  qsTr("Equalizer Disabled") : ""
            onClicked: {
                _private.slotPassthroughClient.equaliserEnabled = !_private.slotPassthroughClient.equaliserEnabled;
            }
        }
        QQC2.Button {
            text: _private.slotPassthroughClient ? _private.slotPassthroughClient.compressorEnabled ? qsTr("Compressor Enabled") :  qsTr("Compressor Disabled") : ""
            onClicked: {
                _private.slotPassthroughClient.compressorEnabled = !_private.slotPassthroughClient.compressorEnabled;
            }
        }
    }
    contentItem: RowLayout {
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 24
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 10
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
                    property QtObject slotPassthroughClient: slotType === ""
                        ? null
                        : slotType === "global"
                            ? Zynthbox.Plugin.globalPlaybackClient
                            : slotType === "track"
                                ? Zynthbox.Plugin.trackPassthroughClients[selectedChannel.id]
                                : slotType === "synth"
                                    ? Zynthbox.Plugin.synthPassthroughClients[selectedChannel.chainedSounds[slotIndex]]
                                    : slotType === "fx"
                                        ? Zynthbox.Plugin.fxPassthroughClients[selectedChannel.id][slotIndex]
                                        : null
                    function getCurrent() {
                        let currentObject = null;
                        if (_private.slotPassthroughClient.compressorSettings.selected === true) {
                            currentObject = _private.slotPassthroughClient.compressorSettings;
                        } else {
                            for (let slotIndex = 0; slotIndex < _private.slotPassthroughClient.equaliserSettings.length; ++slotIndex) {
                                if (_private.slotPassthroughClient.equaliserSettings[slotIndex].selected) {
                                    currentObject = _private.slotPassthroughClient.equaliserSettings[slotIndex];
                                    break;
                                }
                            }
                            if (currentObject === null) {
                                currentObject = _private.slotPassthroughClient.equaliserSettings[0];
                            }
                        }
                        return currentObject;
                    }
                    function goLeft() {
                        let currentObject = getCurrent();
                        if (currentObject.selected) {
                            if (currentObject === _private.slotPassthroughClient.compressorSettings) {
                                _private.slotPassthroughClient.compressorSettings.selected = false;
                                _private.slotPassthroughClient.equaliserSettings[_private.slotPassthroughClient.equaliserSettings.length - 1].selected = true;
                            } else {
                                if (currentObject.previous) {
                                    currentObject.previous.selected = true;
                                }
                            }
                        } else {
                            currentObject.selected = true;
                        }
                    }
                    function goRight() {
                        let currentObject = getCurrent();
                        if (currentObject.selected) {
                            if (currentObject === _private.slotPassthroughClient.compressorSettings) {
                                // nowhere to go right from here
                            } else {
                                if (currentObject.next) {
                                    // If there is a next defined, then select that
                                    currentObject.next.selected = true;
                                } else {
                                    // Otherwise we're at the end of the equaliser settings and the next object is the compressor
                                    currentObject.selected = false;
                                    _private.slotPassthroughClient.compressorSettings.selected = true;
                                }
                            }
                        } else {
                            currentObject.selected = true;
                        }
                    }
                    function select() {
                        let currentObject = getCurrent();
                        if (currentObject === _private.slotPassthroughClient.compressorSettings) {
                            _private.slotPassthroughClient.compressorEnabled = !_private.slotPassthroughClient.compressorEnabled;
                        } else {
                            if (zynqtgui.modeButtonPressed) {
                                currentObject.soloed = !currentObject.soloed;
                            } else {
                                currentObject.active = !currentObject.active;
                            }
                        }
                    }
                    function knob0Up() {
                        let currentObject = getCurrent();
                        if (currentObject === _private.slotPassthroughClient.compressorSettings) {
                            if (zynqtgui.modeButtonPressed) {
                                currentObject.kneeWidth = currentObject.kneeWidth + 0.01;
                            } else {
                                currentObject.threshold = currentObject.threshold + 0.01;
                            }
                        } else {
                            if (zynqtgui.modeButtonPressed) {
                                currentObject.quality = currentObject.quality + 0.01;
                            } else {
                                currentObject.quality = currentObject.quality + 0.1;
                            }
                        }
                    }
                    function knob0Down() {
                        let currentObject = getCurrent();
                        if (currentObject === _private.slotPassthroughClient.compressorSettings) {
                            if (zynqtgui.modeButtonPressed) {
                                currentObject.kneeWidth = currentObject.kneeWidth - 0.01;
                            } else {
                                currentObject.threshold = currentObject.threshold - 0.01;
                            }
                        } else {
                            if (zynqtgui.modeButtonPressed) {
                                currentObject.quality = currentObject.quality - 0.01;
                            } else {
                                currentObject.quality = currentObject.quality - 0.1;
                            }
                        }
                    }
                    function knob1Up() {
                        let currentObject = getCurrent();
                        if (currentObject === _private.slotPassthroughClient.compressorSettings) {
                            if (zynqtgui.modeButtonPressed) {
                                currentObject.makeUpGain = currentObject.makeUpGain + 0.01;
                            } else {
                                currentObject.attack = currentObject.attack + 1;
                            }
                        } else {
                            currentObject.gainAbsolute = currentObject.gainAbsolute + 0.01;
                        }
                    }
                    function knob1Down() {
                        let currentObject = getCurrent();
                        if (currentObject === _private.slotPassthroughClient.compressorSettings) {
                            if (zynqtgui.modeButtonPressed) {
                                currentObject.makeUpGain = currentObject.makeUpGain - 0.01;
                            } else {
                                currentObject.attack = currentObject.attack - 1;
                            }
                        } else {
                            currentObject.gainAbsolute = currentObject.gainAbsolute - 0.01;
                        }
                    }
                    function knob2Up() {
                        let currentObject = getCurrent();
                        if (currentObject === _private.slotPassthroughClient.compressorSettings) {
                            if (zynqtgui.modeButtonPressed) {
                                currentObject.ratio = currentObject.ratio + 1;
                            } else {
                                currentObject.release = currentObject.release + 1;
                            }
                        } else {
                            if (zynqtgui.modeButtonPressed) {
                                currentObject.frequency = currentObject.frequency + 1;
                            } else {
                                if (currentObject.frequency < 1000.0) {
                                    currentObject.frequency = currentObject.frequency + 1;
                                } else if (currentObject.frequency < 10000.0) {
                                    currentObject.frequency = currentObject.frequency + 10;
                                } else {
                                    currentObject.frequency = currentObject.frequency + 50;
                                }
                            }
                        }
                    }
                    function knob2Down() {
                        let currentObject = getCurrent();
                        if (currentObject === _private.slotPassthroughClient.compressorSettings) {
                            if (zynqtgui.modeButtonPressed) {
                                currentObject.ratio = currentObject.ratio - 1;
                            } else {
                                currentObject.release = currentObject.release - 1;
                            }
                        } else {
                            if (zynqtgui.modeButtonPressed) {
                                currentObject.frequency = currentObject.frequency - 1;
                            } else {
                                if (currentObject.frequency < 1000.0) {
                                    currentObject.frequency = currentObject.frequency - 1;
                                } else if (currentObject.frequency < 10000.0) {
                                    currentObject.frequency = currentObject.frequency - 10;
                                } else {
                                    currentObject.frequency = currentObject.frequency - 50;
                                }
                            }
                        }
                    }
                    function knob3Up() {
                        goRight();
                    }
                    function knob3Down() {
                        goLeft();
                    }
                }
                Zynthbox.JackPassthroughVisualiserItem {
                    anchors.fill: parent
                    source: _private.slotPassthroughClient
                }
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        bottomMargin: slidePoint.selectedBand === null ? 0 : Math.min(Math.max(parent.height - slidePoint.y, 0), parent.height)
                    }
                    height: 1
                    visible: slidePoint.selectedBand !== null
                    color: slidePoint.selectedBand === null ? "black" : slidePoint.selectedBand.color
                }
                MultiPointTouchArea {
                    id: graphTouchArea
                    anchors.fill: parent
                    touchPoints: [
                        TouchPoint {
                            id: slidePoint;
                            property QtObject selectedBand: null
                            property var pressedTime: undefined
                            onPressedChanged: {
                                if (pressed) {
                                    pressedTime = Date.now();
                                    selectedBand = _private.getCurrent();
                                } else {
                                    // Only select what's underneath if the timing was reasonably a tap (arbitrary number here, should be a global constant somewhere we can use for this)
                                    if ((Date.now() - pressedTime) < 300) {
                                        // Find the band underneath the touch point
                                        let frequencyForPosition = 20.0 * Math.pow(2.0, (slidePoint.startX / graphTouchArea.width) * 10.0);
                                        let tappedBand = _private.slotPassthroughClient.equaliserNearestToFrequency(frequencyForPosition);
                                        tappedBand.selected = true;
                                    }
                                    selectedBand = null;
                                }
                            }
                            onYChanged: {
                                if (pressed && selectedBand) {
                                    let newGain = 1-(slidePoint.y / graphTouchArea.height);
                                    selectedBand.gainAbsolute = Math.min(Math.max(newGain, 0), 1);
                                }
                            }
                            readonly property double frequencyLowerBound: 20
                            readonly property double frequencyUpperBound: 20000
                            onXChanged: {
                                if (pressed && selectedBand) {
                                    // first convert position to a normalised 0 through 1 position along the width of the whole area, and then put that position along the frequency area
                                    let newFrequency = 20.0 * Math.pow(2.0, 10 * (slidePoint.x / graphTouchArea.width));
                                    selectedBand.frequency = Math.min(Math.max(newFrequency, frequencyLowerBound), frequencyUpperBound);
                                }
                            }
                        }
                    ]
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 18
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
                                _private.slotPassthroughClient.compressorSettings.selected = false;
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
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: false
                                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                        QQC2.Dial {
                                            anchors {
                                                top: parent.top
                                                bottom: parent.bottom
                                                horizontalCenter: parent.horizontalCenter
                                            }
                                            width: height
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
                                            property double lastPressed: 0
                                            onPressedChanged: {
                                                if (pressed === false) {
                                                    let newTimestamp = Date.now();
                                                    if (newTimestamp - lastPressed < 300) {
                                                        // The same as the inverseRootTwo default
                                                        bandDelegate.filterSettings.quality = 0.70710678118654752440;
                                                    }
                                                    lastPressed = newTimestamp;
                                                }
                                            }
                                            Zynthian.KnobIndicator {
                                                visible: bandDelegate.filterSettings && bandDelegate.filterSettings.selected
                                                anchors.centerIn: parent
                                                height: parent.height / 2
                                                width: height
                                                knobId: 0
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
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: false
                                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                        QQC2.Dial {
                                            anchors {
                                                top: parent.top
                                                bottom: parent.bottom
                                                horizontalCenter: parent.horizontalCenter
                                            }
                                            width: height
                                            handle: null
                                            value: bandDelegate.filterSettings ? bandDelegate.filterSettings.gainAbsolute : 0
                                            from: 0
                                            to: 1
                                            stepSize: 0.01
                                            onValueChanged: {
                                                if (bandDelegate.filterSettings && bandDelegate.filterSettings.gainAbsolute !== value) {
                                                    bandDelegate.filterSettings.gainAbsolute = value;
                                                }
                                            }
                                            property double lastPressed: 0
                                            onPressedChanged: {
                                                if (pressed === false) {
                                                    let newTimestamp = Date.now();
                                                    if (newTimestamp - lastPressed < 300) {
                                                        bandDelegate.filterSettings.gain = 1;
                                                    }
                                                    lastPressed = newTimestamp;
                                                }
                                            }
                                            Zynthian.KnobIndicator {
                                                visible: bandDelegate.filterSettings && bandDelegate.filterSettings.selected
                                                anchors.centerIn: parent
                                                height: parent.height / 2
                                                width: height
                                                knobId: 1
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
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                                QQC2.Dial {
                                    anchors {
                                        top: parent.top
                                        bottom: parent.bottom
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                    width: height
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
                                    property double lastPressed: 0
                                    property var defaultFrequencies: [20, 250, 500, 1000, 5000, 12000]
                                    onPressedChanged: {
                                        if (pressed === false) {
                                            let newTimestamp = Date.now();
                                            if (newTimestamp - lastPressed < 300) {
                                                bandDelegate.filterSettings.frequency = defaultFrequencies[model.index];
                                            }
                                            lastPressed = newTimestamp;
                                        }
                                    }
                                    QQC2.Label {
                                        anchors.fill: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        text: bandDelegate.filterSettings
                                            ?  (bandDelegate.filterSettings.frequency < 1000.0 || zynqtgui.modeButtonPressed)
                                                ? "%1 Hz".arg(bandDelegate.filterSettings.frequency.toFixed(0))
                                                : "%1 kHz".arg((bandDelegate.filterSettings.frequency / 1000.0).toFixed(2))
                                            : ""
                                            Zynthian.KnobIndicator {
                                                visible: bandDelegate.filterSettings && bandDelegate.filterSettings.selected
                                                anchors {
                                                    top: parent.verticalCenter
                                                    horizontalCenter: parent.horizontalCenter
                                                    topMargin: Kirigami.Units.largeSpacing
                                                }
                                                height: parent.paintedHeight
                                                width: height
                                                knobId: 2
                                            }
                                    }
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
            }
        }
        Item {
            id: compressorSettings
            property QtObject filterSettings: null
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
            Rectangle {
                anchors.fill: parent
                radius: Kirigami.Units.smallSpacing
                color: "transparent"
                border {
                    width: 1
                    color: _private.slotPassthroughClient && _private.slotPassthroughClient.compressorSettings.selected ? Kirigami.Theme.focusColor : Kirigami.Theme.textColor
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    let current = _private.getCurrent();
                    if (current !== _private.slotPassthroughClient.compressorSettings) {
                        current.selected = false;
                    }
                    _private.slotPassthroughClient.compressorSettings.selected = true;
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
                Zynthian.PlayGridButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    text: _private.slotPassthroughClient
                        ? _private.slotPassthroughClient.compressorSidechannelLeft.length > 0
                            ? "L: %1".arg(sideChainSourcePicker.model[Zynthbox.MidiRouter.model.audioInSourceIndex(_private.slotPassthroughClient.compressorSidechannelLeft)].text)
                            : qsTr("L: No Sidechannel")
                        : ""
                    onClicked: {
                        sideChainSourcePicker.pickSource(_private.slotPassthroughClient, 0);
                    }
                }
                Zynthian.PlayGridButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    text: _private.slotPassthroughClient
                        ? _private.slotPassthroughClient.compressorSidechannelLeft.length > 0
                            ? "R: %1".arg(sideChainSourcePicker.model[Zynthbox.MidiRouter.model.audioInSourceIndex(_private.slotPassthroughClient.compressorSidechannelLeft)].text)
                            : qsTr("R: No Sidechannel")
                        : ""
                    onClicked: {
                        sideChainSourcePicker.pickSource(_private.slotPassthroughClient, 1);
                    }
                }
                Zynthian.ComboBox {
                    id: sideChainSourcePicker
                    visible: false;
                    model: Zynthbox.MidiRouter.model.audioInSources
                    function pickSource(passthroughClient, channel) {
                        sideChainSourcePicker.passthroughClient = passthroughClient;
                        sideChainSourcePicker.channel = channel;
                        if (channel === 0 && passthroughClient.compressorSidechannelLeft.length > 0) {
                            sideChainSourcePicker.selectIndex(Zynthbox.MidiRouter.model.audioInSourceIndex(passthroughClient.compressorSidechannelLeft));
                        } else if (channel === 1 && passthroughClient.compressorSidechannelRight.length > 0) {
                            sideChainSourcePicker.selectIndex(Zynthbox.MidiRouter.model.audioInSourceIndex(passthroughClient.compressorSidechannelRight));
                        } else {
                            sideChainSourcePicker.selectIndex(-1);
                        }
                        sideChainSourcePicker.onClicked();
                    }
                    textRole: "text"
                    property QtObject passthroughClient: null
                    property int channel: -1
                    onActivated: {
                        let listElement = sideChainSourcePicker.model[index];
                        switch (sideChainSourcePicker.channel) {
                            case 0:
                                sideChainSourcePicker.passthroughClient.compressorSidechannelLeft = listElement.value;
                                break;
                            case 1:
                                sideChainSourcePicker.passthroughClient.compressorSidechannelRight = listElement.value;
                                break;
                            default:
                                console.log("Got an unexpected channel when setting the compressor sidechain:", channel);
                                break;
                        }
                        sideChainSourcePicker.passthroughClient = null;
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
                            text: qsTr("Threshold")
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            QQC2.Dial {
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    horizontalCenter: parent.horizontalCenter
                                }
                                width: height
                                handle: null
                                value: _private.slotPassthroughClient ? _private.slotPassthroughClient.compressorSettings.threshold : 0
                                from: 0
                                to: 1
                                stepSize: 0.01
                                onValueChanged: {
                                    if (_private.slotPassthroughClient && _private.slotPassthroughClient.compressorSettings.threshold !== value) {
                                        _private.slotPassthroughClient.compressorSettings.threshold = value;
                                    }
                                }
                                property double lastPressed: 0
                                onPressedChanged: {
                                    if (pressed === false) {
                                        let newTimestamp = Date.now();
                                        if (newTimestamp - lastPressed < 300) {
                                            _private.slotPassthroughClient.compressorSettings.thresholdDB = -10.0;
                                        }
                                        lastPressed = newTimestamp;
                                    }
                                }
                                Zynthian.KnobIndicator {
                                    visible: _private.slotPassthroughClient && _private.slotPassthroughClient.compressorSettings && _private.slotPassthroughClient.compressorSettings.selected && zynqtgui.modeButtonPressed === false
                                    anchors.centerIn: parent
                                    height: parent.height / 2
                                    width: height
                                    knobId: 0
                                }
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                            horizontalAlignment: Text.AlignHCenter
                            text: _private.slotPassthroughClient ? "%1dB".arg(_private.slotPassthroughClient.compressorSettings.thresholdDB.toFixed(2)) : ""
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
                            text: qsTr("Knee")
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            QQC2.Dial {
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    horizontalCenter: parent.horizontalCenter
                                }
                                width: height
                                handle: null
                                value: _private.slotPassthroughClient ? _private.slotPassthroughClient.compressorSettings.kneeWidth : 0
                                from: 0
                                to: 1
                                stepSize: 0.01
                                onValueChanged: {
                                    if (_private.slotPassthroughClient && _private.slotPassthroughClient.compressorSettings.kneeWidth !== value) {
                                        _private.slotPassthroughClient.compressorSettings.kneeWidth = value;
                                    }
                                }
                                property double lastPressed: 0
                                onPressedChanged: {
                                    if (pressed === false) {
                                        let newTimestamp = Date.now();
                                        if (newTimestamp - lastPressed < 300) {
                                            _private.slotPassthroughClient.compressorSettings.kneeWidthDB = 0;
                                        }
                                        lastPressed = newTimestamp;
                                    }
                                }
                                Zynthian.KnobIndicator {
                                    visible: _private.slotPassthroughClient && _private.slotPassthroughClient.compressorSettings && _private.slotPassthroughClient.compressorSettings.selected && zynqtgui.modeButtonPressed === true
                                    anchors.centerIn: parent
                                    height: parent.height / 2
                                    width: height
                                    knobId: 0
                                }
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                            horizontalAlignment: Text.AlignHCenter
                            text: _private.slotPassthroughClient ? "%1dB".arg(_private.slotPassthroughClient.compressorSettings.kneeWidthDB.toFixed(2)) : ""
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
                            text: qsTr("Attack")
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            QQC2.Dial {
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    horizontalCenter: parent.horizontalCenter
                                }
                                width: height
                                handle: null
                                value: _private.slotPassthroughClient ? _private.slotPassthroughClient.compressorSettings.attack : 0
                                from: 0
                                to: 100
                                stepSize: 0.1
                                onValueChanged: {
                                    if (_private.slotPassthroughClient) {
                                        _private.slotPassthroughClient.compressorSettings.attack = value;
                                    }
                                }
                                property double lastPressed: 0
                                onPressedChanged: {
                                    if (pressed === false) {
                                        let newTimestamp = Date.now();
                                        if (newTimestamp - lastPressed < 300) {
                                            _private.slotPassthroughClient.compressorSettings.attack = 30;
                                        }
                                        lastPressed = newTimestamp;
                                    }
                                }
                                Zynthian.KnobIndicator {
                                    visible: _private.slotPassthroughClient && _private.slotPassthroughClient.compressorSettings && _private.slotPassthroughClient.compressorSettings.selected && zynqtgui.modeButtonPressed === false
                                    anchors.centerIn: parent
                                    height: parent.height / 2
                                    width: height
                                    knobId: 1
                                }
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                            horizontalAlignment: Text.AlignHCenter
                            text: _private.slotPassthroughClient ? "%1ms".arg(_private.slotPassthroughClient.compressorSettings.attack.toFixed(0)) : ""
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
                            text: qsTr("Make Up")
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            QQC2.Dial {
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    horizontalCenter: parent.horizontalCenter
                                }
                                width: height
                                handle: null
                                value: _private.slotPassthroughClient ? _private.slotPassthroughClient.compressorSettings.makeUpGain : 0
                                from: 0
                                to: 1
                                stepSize: 0.01
                                onValueChanged: {
                                    if (_private.slotPassthroughClient && _private.slotPassthroughClient.compressorSettings.makeUpGain !== value) {
                                        _private.slotPassthroughClient.compressorSettings.makeUpGain = value;
                                    }
                                }
                                property double lastPressed: 0
                                onPressedChanged: {
                                    if (pressed === false) {
                                        let newTimestamp = Date.now();
                                        if (newTimestamp - lastPressed < 300) {
                                            _private.slotPassthroughClient.compressorSettings.makeUpGainDB = 0;
                                        }
                                        lastPressed = newTimestamp;
                                    }
                                }
                                Zynthian.KnobIndicator {
                                    visible: _private.slotPassthroughClient && _private.slotPassthroughClient.compressorSettings && _private.slotPassthroughClient.compressorSettings.selected && zynqtgui.modeButtonPressed === true
                                    anchors.centerIn: parent
                                    height: parent.height / 2
                                    width: height
                                    knobId: 1
                                }
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                            horizontalAlignment: Text.AlignHCenter
                            text: _private.slotPassthroughClient ? "%1dB".arg(_private.slotPassthroughClient.compressorSettings.makeUpGainDB.toFixed(2)) : ""
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
                            text: qsTr("Release")
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            QQC2.Dial {
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    horizontalCenter: parent.horizontalCenter
                                }
                                width: height
                                handle: null
                                value: _private.slotPassthroughClient ? _private.slotPassthroughClient.compressorSettings.release : 0
                                from: 0
                                to: 500
                                stepSize: 0.1
                                onValueChanged: {
                                    if (_private.slotPassthroughClient && _private.slotPassthroughClient.compressorSettings.release !== value) {
                                        _private.slotPassthroughClient.compressorSettings.release = value;
                                    }
                                }
                                property double lastPressed: 0
                                onPressedChanged: {
                                    if (pressed === false) {
                                        let newTimestamp = Date.now();
                                        if (newTimestamp - lastPressed < 300) {
                                            _private.slotPassthroughClient.compressorSettings.release = 150;
                                        }
                                        lastPressed = newTimestamp;
                                    }
                                }
                                Zynthian.KnobIndicator {
                                    visible: _private.slotPassthroughClient && _private.slotPassthroughClient.compressorSettings && _private.slotPassthroughClient.compressorSettings.selected && zynqtgui.modeButtonPressed === false
                                    anchors.centerIn: parent
                                    height: parent.height / 2
                                    width: height
                                    knobId: 2
                                }
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                            horizontalAlignment: Text.AlignHCenter
                            text: _private.slotPassthroughClient ? "%1ms".arg(_private.slotPassthroughClient.compressorSettings.release.toFixed(0)) : ""
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
                            text: qsTr("Ratio")
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            QQC2.Dial {
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    horizontalCenter: parent.horizontalCenter
                                }
                                width: height
                                handle: null
                                value: _private.slotPassthroughClient ? _private.slotPassthroughClient.compressorSettings.ratio : 0
                                from: 1
                                to: 16
                                stepSize: 0.1
                                onValueChanged: {
                                    if (_private.slotPassthroughClient) {
                                        _private.slotPassthroughClient.compressorSettings.ratio = value;
                                    }
                                }
                                property double lastPressed: 0
                                onPressedChanged: {
                                    if (pressed === false) {
                                        let newTimestamp = Date.now();
                                        if (newTimestamp - lastPressed < 300) {
                                            _private.slotPassthroughClient.compressorSettings.ratio = 4;
                                        }
                                        lastPressed = newTimestamp;
                                    }
                                }
                                Zynthian.KnobIndicator {
                                    visible: _private.slotPassthroughClient && _private.slotPassthroughClient.compressorSettings && _private.slotPassthroughClient.compressorSettings.selected && zynqtgui.modeButtonPressed === true
                                    anchors.centerIn: parent
                                    height: parent.height / 2
                                    width: height
                                    knobId: 2
                                }
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                            horizontalAlignment: Text.AlignHCenter
                            text: _private.slotPassthroughClient ? "%1:1".arg(_private.slotPassthroughClient.compressorSettings.ratio.toFixed(0)) : ""
                        }
                    }
                }
            }
        }
        Item {
            // id: left channel compressor visualisation
            Layout.minimumWidth: Kirigami.Units.largeSpacing
            Layout.maximumWidth: Kirigami.Units.largeSpacing
            Layout.fillHeight: true
            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: _private.slotPassthroughClient ? _private.slotPassthroughClient.compressorSettings.sidechainPeakLeft * parent.height : 0
            }
            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: _private.slotPassthroughClient && _private.slotPassthroughClient.compressorEnabled ? (1 - _private.slotPassthroughClient.compressorSettings.maxGainReductionLeft) * parent.height : 0
                }
                height: 1
                color: "red"
            }
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: _private.slotPassthroughClient ? _private.slotPassthroughClient.compressorSettings.outputPeakLeft * parent.height : 0
            }
        }
        Item {
            // id: right channel compressor visualisation
            Layout.minimumWidth: Kirigami.Units.largeSpacing
            Layout.maximumWidth: Kirigami.Units.largeSpacing
            Layout.fillHeight: true
            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: _private.slotPassthroughClient ? _private.slotPassthroughClient.compressorSettings.sidechainPeakRight * parent.height : 0
            }
            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: _private.slotPassthroughClient && _private.slotPassthroughClient.compressorEnabled ? (1 - _private.slotPassthroughClient.compressorSettings.maxGainReductionRight) * parent.height : 0
                }
                height: 1
                color: "red"
            }
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: _private.slotPassthroughClient ? _private.slotPassthroughClient.compressorSettings.outputPeakRight * parent.height : 0
            }
        }
    }
}
