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

import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian

Item {
    id: component
    property QtObject clip
    property QtObject cppClipObject
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
        property int elementMax: 4

        function goLeft() {
            if (currentElement === 0) {
                currentElement = elementMax;
            } else {
                currentElement = currentElement - 1;
            }
        }
        function goRight() {
            if (currentElement === elementMax) {
                currentElement = 0;
            } else {
                currentElement = currentElement + 1;
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
                        component.cppClipObject.sliceCount = component.cppClipObject.sliceCount + 1;
                    }
                    break;
                case 1:
                    if (component.cppClipObject) {
                        component.cppClipObject.selectedSliceObject.keyZoneStart = component.cppClipObject.selectedSliceObject.keyZoneStart + 1;
                    }
                    break;
                case 2:
                    if (component.cppClipObject) {
                        component.cppClipObject.selectedSliceObject.velocityMinimum = component.cppClipObject.selectedSliceObject.velocityMinimum + 1;
                    }
                    break;
                case 3:
                    if (component.cppClipObject) {
                        component.cppClipObject.selectedSliceObject.rootNote = component.cppClipObject.selectedSliceObject.rootNote + 1;
                    }
                    break;
                case 4:
                    if (component.cppClipObject) {
                        component.cppClipObject.slicesContiguous = true;
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
                        component.cppClipObject.sliceCount = component.cppClipObject.sliceCount - 1;
                    }
                    break;
                case 1:
                    if (component.cppClipObject) {
                        component.cppClipObject.selectedSliceObject.keyZoneStart = component.cppClipObject.selectedSliceObject.keyZoneStart - 1;
                    }
                    break;
                case 2:
                    if (component.cppClipObject) {
                        component.cppClipObject.selectedSliceObject.velocityMinimum = component.cppClipObject.selectedSliceObject.velocityMinimum - 1;
                    }
                    break;
                case 3:
                    if (component.cppClipObject) {
                        component.cppClipObject.selectedSliceObject.rootNote = component.cppClipObject.selectedSliceObject.rootNote - 1;
                    }
                    break;
                case 4:
                    if (component.cppClipObject) {
                        component.cppClipObject.slicesContiguous = false;
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
                        component.cppClipObject.selectedSlice = component.cppClipObject.selectedSlice + 1;
                    }
                    break;
                case 1:
                    if (component.cppClipObject) {
                        component.cppClipObject.selectedSliceObject.keyZoneEnd = component.cppClipObject.selectedSliceObject.keyZoneEnd + 1;
                    }
                    break;
                case 2:
                    if (component.cppClipObject) {
                        component.cppClipObject.selectedSliceObject.velocityMaximum = component.cppClipObject.selectedSliceObject.velocityMaximum + 1;
                    }
                    break;
                case 3:
                    if (component.cppClipObject) {
                    }
                    break;
                case 4:
                    if (component.cppClipObject) {
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
                        component.cppClipObject.selectedSlice = component.cppClipObject.selectedSlice - 1;
                    }
                    break;
                case 1:
                    if (component.cppClipObject) {
                        component.cppClipObject.selectedSliceObject.keyZoneEnd = component.cppClipObject.selectedSliceObject.keyZoneEnd - 1;
                    }
                    break;
                case 2:
                    if (component.cppClipObject) {
                        component.cppClipObject.selectedSliceObject.velocityMaximum = component.cppClipObject.selectedSliceObject.velocityMaximum - 1;
                    }
                    break;
                case 3:
                    if (component.cppClipObject) {
                    }
                    break;
                case 4:
                    if (component.cppClipObject) {
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
                    if (component.cppClipObject) {
                    }
                    break;
                case 1:
                    if (component.cppClipObject) {
                    }
                    break;
                case 2:
                    if (component.cppClipObject) {
                    }
                    break;
                case 3:
                    if (component.cppClipObject) {
                    }
                    break;
                case 4:
                    if (component.cppClipObject) {
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
                    if (component.cppClipObject) {
                    }
                    break;
                case 1:
                    if (component.cppClipObject) {
                    }
                    break;
                case 2:
                    if (component.cppClipObject) {
                    }
                    break;
                case 3:
                    if (component.cppClipObject) {
                    }
                    break;
                case 4:
                    if (component.cppClipObject) {
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
            id: sliceCountSlider
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            text: qsTr("Slices")
            value: component.cppClipObject ? component.cppClipObject.sliceCount : 0
            valueString: component.cppClipObject ? component.cppClipObject.sliceCount : 0
            decimals: 0
            increment: 1
            slideIncrement: 0.05
            applyLowerBound: true
            lowerBound: 0
            applyUpperBound: true
            upperBound: 16
            selected: _private.currentElement === 0
            knobId: 0
            onValueChanged: if (component.cppClipObject) { component.cppClipObject.sliceCount = value; }
            Connections {
                target: component.cppClipObject ? component.cppClipObject.selectedSliceObject : null
                onSubvoiceCountChanged: {
                    sliceCountSlider.value = component.cppClipObject.sliceCount;
                    if (_private.editVoice > sliceCountSlider.value - 1) {
                        _private.editVoice = Math.max(0, sliceCountSlider.value - 1);
                    }
                    if (component.cppClipObject.sliceCount === 0) {
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
            id: editSliceSlider
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            text: qsTr("Slice")
            value: component.cppClipObject ? component.cppClipObject.selectedSlice : 0
            valueString: component.cppClipObject
                ? component.cppClipObject.selectedSlice === -1
                    ? qsTr("Root")
                    : qsTr("Slice %1").arg(component.cppClipObject.selectedSlice + 1)
                : ""
            decimals: 0
            increment: 1
            slideIncrement: 1
            applyLowerBound: true
            lowerBound: -1
            applyUpperBound: true
            upperBound: component.cppClipObject ? component.cppClipObject.sliceCount - 1 : -1
            resetOnTap: true
            resetValue: -1
            selected: _private.currentElement === 0
            knobId: 1
            onValueChanged: if (component.cppClipObject) { component.cppClipObject.selectedSlice = value; }
            Connections {
                target: component.cppClipObject
                onSelectedSliceChanged: editSliceSlider.value = component.cppClipObject.selectedSlice
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
                enabled: component.cppClipObject
                Kirigami.Heading {
                    level: 2
                    text: component.cppClipObject
                        ? component.cppClipObject.selectedSlice === -1
                            ? qsTr("Root Slice Key-zone")
                            : qsTr("Slice %1 Key-zone").arg(component.cppClipObject.selectedSlice + 1)
                        : qsTr("Slice Key-zone")
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing
                    horizontalAlignment: Text.AlignHCenter
                }
                RowLayout {
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
                            text: component.cppClipObject ? qsTr("First:\n%1").arg(Zynthbox.KeyScales.midiNoteName(component.cppClipObject.selectedSliceObject.keyZoneStart)) : ""
                            MouseArea {
                                anchors.fill: parent;
                                onClicked: {
                                    applicationWindow().pickNote(component.cppClipObject.selectedSliceObject.keyZoneStart, function(newNote) {
                                        component.cppClipObject.selectedSliceObject.keyZoneStart = newNote;
                                    });
                                }
                            }
                            KnobIndicator {
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    margins: Kirigami.Units.smallSpacing
                                }
                                width: Kirigami.Units.iconSizes.small
                                height: width
                                visible: _private.currentElement === 1
                                knobId: 0
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: qsTr("Note\nLimit")
                            Layout.fillHeight: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: component.cppClipObject ? qsTr("Last:\n%1").arg(Zynthbox.KeyScales.midiNoteName(component.cppClipObject.selectedSliceObject.keyZoneEnd)) : ""
                            MouseArea {
                                anchors.fill: parent;
                                onClicked: {
                                    applicationWindow().pickNote(component.cppClipObject.selectedSliceObject.keyZoneEnd, function(newNote) {
                                        component.cppClipObject.selectedSliceObject.keyZoneEnd = newNote;
                                    });
                                }
                            }
                            KnobIndicator {
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    margins: Kirigami.Units.smallSpacing
                                }
                                width: Kirigami.Units.iconSizes.small
                                height: width
                                visible: _private.currentElement === 1
                                knobId: 1
                            }
                            Rectangle {
                                anchors {
                                    top: parent.bottom
                                    topMargin: 2
                                    left: parent.left
                                    right: parent.right
                                }
                                height: 2
                                color: _private.currentElement === 1 ? Kirigami.Theme.highlightedTextColor : "transparent"
                                KnobIndicator {
                                    anchors {
                                        top: parent.bottom
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                    width: Kirigami.Units.iconSizes.small
                                    height: width
                                    visible: _private.currentElement === 1
                                    knobId: 3
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.minimumWidth: Kirigami.Units.largeSpacing
                        Layout.maximumWidth: Kirigami.Units.largeSpacing
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
                            text: component.cppClipObject ? qsTr("Minimum:\n%1").arg(component.cppClipObject.selectedSliceObject.velocityMinimum) : ""
                            MouseArea {
                                anchors.fill: parent;
                                onClicked: {
                                    
                                }
                            }
                            KnobIndicator {
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    margins: Kirigami.Units.smallSpacing
                                }
                                width: Kirigami.Units.iconSizes.small
                                height: width
                                visible: _private.currentElement === 2
                                knobId: 0
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: qsTr("Velocity\nLimit")
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: component.cppClipObject ? qsTr("Maximum:\n%1").arg(component.cppClipObject.selectedSliceObject.velocityMaximum) : ""
                            MouseArea {
                                anchors.fill: parent;
                                onClicked: {
                                    
                                }
                            }
                            KnobIndicator {
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    margins: Kirigami.Units.smallSpacing
                                }
                                width: Kirigami.Units.iconSizes.small
                                height: width
                                visible: _private.currentElement === 2
                                knobId: 1
                            }
                            Rectangle {
                                anchors {
                                    top: parent.bottom
                                    topMargin: 2
                                    left: parent.left
                                    right: parent.right
                                }
                                height: 2
                                color: _private.currentElement === 2 ? Kirigami.Theme.highlightedTextColor : "transparent"
                                KnobIndicator {
                                    anchors {
                                        top: parent.bottom
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                    width: Kirigami.Units.iconSizes.small
                                    height: width
                                    visible: _private.currentElement === 2
                                    knobId: 3
                                }
                            }
                        }
                    }
                }
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
                text: component.cppClipObject ? qsTr("Sample\nPitch:\n%1").arg(Zynthbox.KeyScales.midiNoteName(component.cppClipObject.selectedSliceObject.rootNote)) : qsTr("Sample\nPitch\n")
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        
                    }
                }
                KnobIndicator {
                    anchors {
                        top: parent.top
                        left: parent.left
                        margins: Kirigami.Units.smallSpacing
                    }
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    visible: _private.currentElement === 3
                    knobId: 0
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                // Select split point in popup (probably snow the sample, and show split point in that popup...)
                text: qsTr("Split\nSlice...")
                enabled: false
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                // What this does will depend on the style... free-form or contiguous
                // - free-form/overlapping just clears the slice and moves those above down (popup is just confirm/reject)
                // - contiguous will add the length of the deleted slice to another slice
                //   - for first slice, offer to remove and add length to next, or simply remove
                //   - for all others, offer to remove and add length to either next or previous
                //   - for the last slice, offer to remove and add length to previous, or simply remove
                text: qsTr("Delete\nSlice...")
                enabled: false
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        
                    }
                }
                Rectangle {
                    anchors {
                        top: parent.bottom
                        topMargin: 2
                        left: parent.left
                        right: parent.right
                    }
                    height: 2
                    color: _private.currentElement === 3 ? Kirigami.Theme.highlightedTextColor : "transparent"
                    KnobIndicator {
                        anchors {
                            top: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                        width: Kirigami.Units.iconSizes.small
                        height: width
                        visible: _private.currentElement === 3
                        knobId: 3
                    }
                }
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
                // Simply setting this will only apply the logic if things already line up.
                // In the popup, show an option to force-apply things (sort things by start positions and set lengths to the stop point of the next slice)
                text: component.cppClipObject
                    ? component.cppClipObject.slicesContiguous
                        ? qsTr("Slicing Style:\nContiguous")
                        : qsTr("Slicing Style:\nFree-form")
                    : qsTr("Slicing Style:\n(no sample)")
                enabled: false
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        
                    }
                }
                KnobIndicator {
                    anchors {
                        top: parent.top
                        left: parent.left
                        margins: Kirigami.Units.smallSpacing
                    }
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    visible: _private.currentElement === 4
                    knobId: 0
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                // Offer options for...
                // - even splits full sample and even split based on some other slice (pre-selecting the current slice)
                // - beat/transient detection, see juce's detection logic for this (based on some existing slice, pre-selecting current slice)
                text: qsTr("Auto\nSlice...")
                enabled: false
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("Clear All\nSlices...")
                enabled: false
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        
                    }
                }
                Rectangle {
                    anchors {
                        top: parent.bottom
                        topMargin: 2
                        left: parent.left
                        right: parent.right
                    }
                    height: 2
                    color: _private.currentElement === 4 ? Kirigami.Theme.highlightedTextColor : "transparent"
                    KnobIndicator {
                        anchors {
                            top: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                        width: Kirigami.Units.iconSizes.small
                        height: width
                        visible: _private.currentElement === 4
                        knobId: 3
                    }
                }
            }
        }
    }
}
