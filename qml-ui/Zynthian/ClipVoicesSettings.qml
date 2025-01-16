/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Voice details editor for sketchpad clips

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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian

Item {
    id: component
    property QtObject clip
    property QtObject cppClipObject
    onCppClipObjectChanged: {
        _private.editVoice = 0;
    }
    function cuiaCallback(cuia) {
        let returnValue = false;
        switch (cuia) {
            case "SELECT_UP":
                _private.goUp();
                returnValue = true;
                break;
            case "SELECT_DOWN":
                _private.goDown();
                returnValue = true;
                break;
            case "NAVIGATE_LEFT":
                _private.goLeft();
                returnValue = true;
                break;
            case "NAVIGATE_RIGHT":
                _private.goRight();
                returnValue = true;
                break;
            case "KNOB0_TOUCHED":
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
            case "KNOB1_TOUCHED":
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
            case "KNOB2_TOUCHED":
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
            case "KNOB3_TOUCHED":
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
        };
        return returnValue;
    }
    QtObject {
        id: _private
        property int currentElement: 0
        property int elementMax: 1

        property int editVoice: 0

        function goLeft() {
            if (currentElement === 0) {
                if (component.cppClipObject.selectedSliceObject.subvoiceCount > 0) {
                    currentElement = elementMax;
                } else {
                    currentElement = elementMax  - 1;
                }
            } else {
                currentElement = currentElement - 1;
            }
        }
        function goRight() {
            if (currentElement === elementMax) {
                currentElement = 0;
            } else {
                if (component.cppClipObject.selectedSliceObject.subvoiceCount > 0) {
                    currentElement = currentElement + 1;
                }
            }
        }
        function goUp() {
        }
        function goDown() {
        }
        function knob0Up() {
            switch (currentElement) {
                case 0:
                    if (component.cppClipObject) {
                        component.cppClipObject.selectedSliceObject.subvoiceCount = Math.min(16, component.cppClipObject.selectedSliceObject.subvoiceCount + 1);
                    }
                    break;
                case 1:
                    if (component.cppClipObject) {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            if (component.cppClipObject.selectedSliceObject.subvoiceCount > 0) {
                                _private.editVoice = Math.min(component.cppClipObject.selectedSliceObject.subvoiceCount - 1, _private.editVoice + 1);
                            }
                        } else {
                            if (component.cppClipObject.selectedSliceObject.subvoiceCount > 0) {
                                component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pan = Math.min(1, component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pan + 0.01);
                            }
                        }
                    }
                    break;
                default:
                    console.log("Somehow ended up on element", currentElement, "which doesn't really exist");
                    break;
            }
        }
        function knob0Down() {
            switch (currentElement) {
                case 0:
                    if (component.cppClipObject) {
                        component.cppClipObject.selectedSliceObject.subvoiceCount = Math.max(0, component.cppClipObject.selectedSliceObject.subvoiceCount - 1);
                    }
                    break;
                case 1:
                    if (component.cppClipObject) {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            if (component.cppClipObject.selectedSliceObject.subvoiceCount > 0) {
                                _private.editVoice = Math.max(0, _private.editVoice - 1);
                            }
                        } else {
                            if (component.cppClipObject.selectedSliceObject.subvoiceCount > 0) {
                                component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pan = Math.max(-1, component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pan - 0.01);
                            }
                        }
                    }
                    break;
                default:
                    console.log("Somehow ended up on element", currentElement, "which doesn't really exist");
                    break;
            }
        }
        function knob1Up() {
            switch (currentElement) {
                case 0:
                    if (component.cppClipObject) {
                        if (component.cppClipObject.selectedSliceObject.subvoiceCount > 0) {
                            _private.editVoice = Math.min(component.cppClipObject.selectedSliceObject.subvoiceCount - 1, _private.editVoice + 1);
                        }
                    }
                    break;
                case 1:
                    if (component.cppClipObject && component.cppClipObject.selectedSliceObject.subvoiceCount > 0) {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pitch = Math.min(48, component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pitch + 0.01);
                        } else {
                            component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pitch = Math.min(48, component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pitch + 0.1);
                        }
                    }
                    break;
                default:
                    console.log("Somehow ended up on element", currentElement, "which doesn't really exist");
                    break;
            }
        }
        function knob1Down() {
            switch (currentElement) {
                case 0:
                    if (component.cppClipObject) {
                        if (component.cppClipObject.selectedSliceObject.subvoiceCount > 0) {
                            _private.editVoice = Math.max(0, _private.editVoice - 1);
                        }
                    }
                    break;
                case 1:
                    if (component.cppClipObject && component.cppClipObject.selectedSliceObject.subvoiceCount > 0) {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pitch = Math.max(-48, component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pitch - 0.01);
                        } else {
                            component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pitch = Math.max(-48, component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pitch - 0.1);
                        }
                    }
                    break;
                default:
                    console.log("Somehow ended up on element", currentElement, "which doesn't really exist");
                    break;
            }
        }
        function knob2Up() {
            switch (currentElement) {
                case 0:
                    break;
                case 1:
                    if (component.cppClipObject && component.cppClipObject.selectedSliceObject.subvoiceCount > 0) {
                        component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].gainAbsolute = Math.min(1, component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].gainAbsolute + 0.01);
                    }
                    break;
                default:
                    console.log("Somehow ended up on element", currentElement, "which doesn't really exist");
                    break;
            }
        }
        function knob2Down() {
            switch (currentElement) {
                case 0:
                    break;
                case 1:
                    if (component.cppClipObject && component.cppClipObject.selectedSliceObject.subvoiceCount > 0) {
                        component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].gainAbsolute = Math.max(-1, component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].gainAbsolute - 0.01);
                    }
                    break;
                default:
                    console.log("Somehow ended up on element", currentElement, "which doesn't really exist");
                    break;
            }
        }
    }
    RowLayout {
        anchors.fill: parent
        spacing: 0
        Zynthian.InfinitySlider {
            id: subvoiceCountSlider
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            text: qsTr("Sub-voices")
            value: component.cppClipObject ? component.cppClipObject.selectedSliceObject.subvoiceCount : 0
            valueString: component.cppClipObject ? component.cppClipObject.selectedSliceObject.subvoiceCount : 0
            decimals: 0
            increment: 1
            slideIncrement: 0.05
            applyLowerBound: true
            lowerBound: 0
            applyUpperBound: true
            upperBound: 16
            selected: _private.currentElement === 0
            knobId: 0
            onValueChanged: if (component.cppClipObject) { component.cppClipObject.selectedSliceObject.subvoiceCount = value; }
            Connections {
                target: component.cppClipObject ? component.cppClipObject.selectedSliceObject : null
                onSubvoiceCountChanged: {
                    subvoiceCountSlider.value = component.cppClipObject.selectedSliceObject.subvoiceCount;
                    if (_private.editVoice > subvoiceCountSlider.value - 1) {
                        _private.editVoice = Math.max(0, subvoiceCountSlider.value - 1);
                    }
                    if (component.cppClipObject.selectedSliceObject.subvoiceCount === 0) {
                        _private.currentElement = 0;
                    }
                }
            }
            KnobIndicator {
                anchors {
                    top: parent.bottom
                    horizontalCenter: parent.right
                }
                width: Kirigami.Units.iconSizes.small
                height: width
                visible: parent.selected
                knobId: 3
            }
        }
        Zynthian.InfinitySlider {
            id: editVoiceSlider
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            text: qsTr("Sub-voice ►")
            value: _private.editVoice
            valueString: _private.editVoice + 1
            decimals: 0
            increment: 1
            slideIncrement: 0.05
            applyLowerBound: true
            lowerBound: 0
            applyUpperBound: true
            upperBound: component.cppClipObject ? component.cppClipObject.selectedSliceObject.subvoiceCount - 1 : 1
            resetOnTap: true
            resetValue: 0
            selected: _private.currentElement === 0
            knobId: 1
            onValueChanged: _private.editVoice = value
            Connections {
                target: _private
                onEditVoiceChanged: editVoiceSlider.value = _private.editVoice
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.minimumWidth: Kirigami.Units.largeSpacing * 2
            Layout.maximumWidth: Kirigami.Units.largeSpacing * 2
        }

        Item {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.fill: parent
                enabled: component.cppClipObject && component.cppClipObject.selectedSliceObject.subvoiceCount > 0
                Kirigami.Heading {
                    level: 2
                    text: qsTr("Sub-voice %1 Changes").arg(_private.editVoice + 1)
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing
                    horizontalAlignment: Text.AlignHCenter
                }
                RowLayout {
                    spacing: 0
                    Layout.bottomMargin: 2 // To give even space for the selected indicator that sits two pixels below the thing
                    Zynthian.SketchpadDial {
                        id: panDial
                        text: qsTr("Pan")
                        controlObj: component.cppClipObject ? component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice] : null
                        controlProperty: "pan"
                        valueString: component.cppClipObject ? component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pan.toFixed(2) : 0
                        selected: _private.currentElement === 1
                        showKnobIndicator: selected
                        knobId: 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit
                        dial {
                            stepSize: 0.01
                            from: -1
                            to: 1
                        }
                        onDoubleClicked: {
                            if (component.cppClipObject) {
                                component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pan = 0;
                            }
                        }
                    }

                    Zynthian.SketchpadDial {
                        id: pitchDial
                        text: qsTr("Pitch")
                        controlObj: component.cppClipObject ? component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice] : null
                        controlProperty: "pitch"
                        fixedPointTrail: 2
                        selected: _private.currentElement === 1
                        showKnobIndicator: selected
                        knobId: 1
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit
                        dial {
                            stepSize: 0.1
                            from: -48
                            to: 48
                        }
                        onDoubleClicked: {
                            if (component.cppClipObject) {
                                component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].pitch = 0;
                            }
                        }
                    }

                    Zynthian.SketchpadDial {
                        id: gainDial
                        text: qsTr("Gain (dB)")
                        controlObj: component.cppClipObject ? component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice] : null
                        controlProperty: "gainAbsolute"
                        valueString: component.cppClipObject ? qsTr("%1 dB").arg(component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].gainDb.toFixed(2)) : 0
                        selected: _private.currentElement === 1
                        showKnobIndicator: selected
                        knobId: 2
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit

                        dial {
                            stepSize: 0.01
                            from: 0
                            to: 1
                        }

                        onDoubleClicked: {
                            if (component.cppClipObject) {
                                component.cppClipObject.selectedSliceObject.subvoiceSettings[_private.editVoice].gainAbsolute = 0.5;
                            }
                        }
                    }
                }
            }
            KnobIndicator {
                anchors {
                    top: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                width: Kirigami.Units.iconSizes.small
                height: width
                visible: pitchDial.selected
                knobId: 3
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.minimumWidth: Kirigami.Units.largeSpacing * 3
            Layout.maximumWidth: Kirigami.Units.largeSpacing * 3
        }

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            Layout.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing
            enabled: component.cppClipObject
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: component.cppClipObject && component.cppClipObject.equaliserEnabled === true ? qsTr("Equalizer:\nEnabled") : qsTr("Equalizer:\nDisabled")
                checked: _private.settingsCategory === 0
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        component.cppClipObject.equaliserEnabled = !component.cppClipObject.equaliserEnabled;
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: component.cppClipObject && component.cppClipObject.compressorEnabled === true ? qsTr("Compressor:\nEnabled") : qsTr("Compressor:\nDisabled")
                checked: _private.settingsCategory === 1
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        component.cppClipObject.compressorEnabled = !component.cppClipObject.compressorEnabled;
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("Equalizer...")
                checked: _private.settingsCategory === 2
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        let channel = zynqtgui.sketchpad.song.channelsModel.getChannel(component.cppClipObject.sketchpadTrack);
                        if (component.clip.isChannelSample) {
                            pageManager.getPage("sketchpad").bottomStack.slotsBar.requestSlotEqualizer(channel, "sample", component.clip.lane);
                        } else {
                            pageManager.getPage("sketchpad").bottomStack.slotsBar.requestSlotEqualizer(channel, "sketch", component.clip.id);
                        }
                    }
                }
            }
        }
    }
}
