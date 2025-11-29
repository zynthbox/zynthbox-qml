/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

ADSR envelope editor for sketchpad clips

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
import QtQuick.Window 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import io.zynthbox.components 1.0 as Zynthbox

Item {
    id: component
    property QtObject clip
    property QtObject cppClipObject: component.clip && component.clip.hasOwnProperty("cppObjId")
                                        ? Zynthbox.PlayGridManager.getClipById(component.clip.cppObjId)
                                        : null
    property int currentADSRElement: 0
    function nextADSRElement() {
        if (currentADSRElement === _private.lastElement) {
            currentADSRElement = 0;
        } else {
            currentADSRElement = currentADSRElement + 1;
        }
    }
    function previousADSRElement() {
        if (currentADSRElement === 0) {
            currentADSRElement = _private.lastElement;
        } else {
            currentADSRElement = currentADSRElement - 1;
        }
    }
    function increaseCurrentValue() {
        if (showCrossfadeSettings) {
            switch(currentADSRElement) {
                case 0:
                    component.cppClipObject.selectedSliceObject.loopStartCrossfadeDirection = Zynthbox.ClipAudioSource.CrossfadeInnie;
                    break;
                case 1:
                    component.cppClipObject.selectedSliceObject.stopCrossfadeDirection = Zynthbox.ClipAudioSource.CrossfadeInnie;
                    break;
                case 2:
                    component.cppClipObject.selectedSliceObject.loopCrossfadeAmount = component.cppClipObject.selectedSliceObject.loopCrossfadeAmount + 0.01;
                    break;
            }
        } else if (showGranularSettings) {
            switch(currentADSRElement) {
                case 0:
                case 2:
                    component.cppClipObject.selectedSliceObject.grainSustain = Math.min(1, component.cppClipObject.selectedSliceObject.grainSustain + 0.01);
                    break;
                case 1:
                case 3:
                    component.cppClipObject.selectedSliceObject.grainTilt = Math.min(1, component.cppClipObject.selectedSliceObject.grainTilt + 0.01);
                    break;
            }
        } else {
            switch(currentADSRElement) {
                case 0:
                    component.cppClipObject.selectedSliceObject.adsrAttack = component.cppClipObject.selectedSliceObject.adsrAttack + 0.01;
                    break;
                case 1:
                    component.cppClipObject.selectedSliceObject.adsrDecay = component.cppClipObject.selectedSliceObject.adsrDecay + 0.01;
                    break;
                case 2:
                    component.cppClipObject.selectedSliceObject.adsrSustain = Math.min(1, component.cppClipObject.selectedSliceObject.adsrSustain + 0.01);
                    break;
                case 3:
                    component.cppClipObject.selectedSliceObject.adsrRelease = component.cppClipObject.selectedSliceObject.adsrRelease + 0.01;
                    break;
            }
        }
    }
    function decreaseCurrentValue() {
        if (showCrossfadeSettings) {
            switch(currentADSRElement) {
                case 0:
                    component.cppClipObject.selectedSliceObject.loopStartCrossfadeDirection = Zynthbox.ClipAudioSource.CrossfadeOutie;
                    break;
                case 1:
                    component.cppClipObject.selectedSliceObject.stopCrossfadeDirection = Zynthbox.ClipAudioSource.CrossfadeOutie;
                    break;
                case 2:
                    component.cppClipObject.selectedSliceObject.loopCrossfadeAmount = component.cppClipObject.selectedSliceObject.loopCrossfadeAmount - 0.01;
                    break;
            }
        } else if (showGranularSettings) {
            switch(currentADSRElement) {
                case 0:
                case 2:
                    component.cppClipObject.selectedSliceObject.grainSustain = Math.max(0, component.cppClipObject.selectedSliceObject.grainSustain - 0.01);
                    break;
                case 1:
                case 3:
                    component.cppClipObject.selectedSliceObject.grainTilt = Math.max(0, component.cppClipObject.selectedSliceObject.grainTilt - 0.01);
                    break;
            }
        } else {
            switch(currentADSRElement) {
                case 0:
                    component.cppClipObject.selectedSliceObject.adsrAttack = Math.max(0, component.cppClipObject.selectedSliceObject.adsrAttack - 0.01);
                    break;
                case 1:
                    component.cppClipObject.selectedSliceObject.adsrDecay = Math.max(0, component.cppClipObject.selectedSliceObject.adsrDecay - 0.01);
                    break;
                case 2:
                    component.cppClipObject.selectedSliceObject.adsrSustain = Math.max(0, component.cppClipObject.selectedSliceObject.adsrSustain - 0.01);
                    break;
                case 3:
                    component.cppClipObject.selectedSliceObject.adsrRelease = Math.max(0, component.cppClipObject.selectedSliceObject.adsrRelease - 0.01);
                    break;
            }
        }
    }
    QtObject {
        id: _private
        property int settingsCategory: 0
        property int lastElement: settingsCategory === 2 ? 2 : 3
    }
    property bool showNotesSettings: showGranularSettings === false && showCrossfadeSettings === false
    property bool showGranularSettings: component.cppClipObject && component.cppClipObject.selectedSliceObject.granular ? _private.settingsCategory === 1 : false
    // Wavetable style ignores the crossfade setting anyway, so don't show it
    property bool showCrossfadeSettings: component.cppClipObject && component.cppClipObject.selectedSliceObject.looping && component.cppClipObject.selectedSliceObject.effectivePlaybackStyle != Zynthbox.ClipAudioSource.WavetableStyle ? _private.settingsCategory === 2 : false
    RowLayout {
        anchors.fill: parent
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.cppClipObject ? (component.cppClipObject.selectedSliceObject.granular || (component.cppClipObject.selectedSliceObject.looping && component.cppClipObject.selectedSliceObject.effectivePlaybackStyle != Zynthbox.ClipAudioSource.WavetableStyle)) : false
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit
                text: qsTr("Notes")
                checked: _private.settingsCategory === 0
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        _private.settingsCategory = 0;
                        component.currentADSRElement = 0;
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit
                visible: component.cppClipObject ? component.cppClipObject.selectedSliceObject.granular : false
                text: qsTr("Grains")
                checked: _private.settingsCategory === 1
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        _private.settingsCategory = 1;
                        component.currentADSRElement = 0;
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit
                visible: component.cppClipObject ? (component.cppClipObject.selectedSliceObject.looping && component.cppClipObject.selectedSliceObject.effectivePlaybackStyle != Zynthbox.ClipAudioSource.WavetableStyle) : false
                text: qsTr("Loop\nX-Fade")
                checked: _private.settingsCategory === 2
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        _private.settingsCategory = 2;
                        component.currentADSRElement = 0;
                    }
                }
            }
        }
        Connections {
            target: component.cppClipObject ? component.cppClipObject.selectedSliceObject : null
            function update() {
                if (component.cppClipObject.selectedSliceObject.adsrAttack !== attackSlider.value) {
                    attackSlider.value = component.cppClipObject.selectedSliceObject.adsrAttack;
                }
                if (component.cppClipObject.selectedSliceObject.adsrDecay !== decaySlider.value) {
                    decaySlider.value = component.cppClipObject.selectedSliceObject.adsrDecay;
                }
                if (component.cppClipObject.selectedSliceObject.adsrSustain !== sustainSlider.value) {
                    sustainSlider.value = component.cppClipObject.selectedSliceObject.adsrSustain;
                }
                if (component.cppClipObject.selectedSliceObject.adsrRelease !== releaseSlider.value) {
                    releaseSlider.value = component.cppClipObject.selectedSliceObject.adsrRelease;
                }
            }
            onAdsrParametersChanged: update()
        }
        InfinitySlider {
            id: attackSlider
            text: qsTr("Attack")
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.showNotesSettings
            unitLabel: "\n" + qsTr("seconds")
            value: component.cppClipObject ? component.cppClipObject.selectedSliceObject.adsrAttack : 0
            decimals: 2
            increment: 0.1
            slideIncrement: 0.01
            applyLowerBound: true
            lowerBound: 0
            resetOnTap: true
            resetValue: 0
            selected: component.currentADSRElement === 0
            knobId: 1
            onValueChanged: {
                if (component.cppClipObject && component.cppClipObject.selectedSliceObject.adsrAttack != attackSlider.value) {
                    component.cppClipObject.selectedSliceObject.adsrAttack = attackSlider.value
                }
            }
            KnobIndicator {
                anchors {
                    top: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                width: Kirigami.Units.iconSizes.small
                height: width
                visible: parent.selected
                knobId: 3
            }
        }
        InfinitySlider {
            id: decaySlider
            text: qsTr("Decay")
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.showNotesSettings
            unitLabel: "\n" + qsTr("seconds")
            value: component.cppClipObject ? component.cppClipObject.selectedSliceObject.adsrDecay : 0
            decimals: 2
            increment: 0.1
            slideIncrement: 0.01
            applyLowerBound: true
            lowerBound: 0
            resetOnTap: true
            resetValue: 0
            selected: component.currentADSRElement === 1
            knobId: 1
            onValueChanged: {
                if (component.cppClipObject && component.cppClipObject.selectedSliceObject.adsrDecay != decaySlider.value) {
                    component.cppClipObject.selectedSliceObject.adsrDecay = decaySlider.value
                }
            }
            KnobIndicator {
                anchors {
                    top: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                width: Kirigami.Units.iconSizes.small
                height: width
                visible: parent.selected
                knobId: 3
            }
        }
        InfinitySlider {
            id: sustainSlider
            text: qsTr("Sustain")
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.showNotesSettings
            unitLabel: "%"
            value: component.cppClipObject ? component.cppClipObject.selectedSliceObject.adsrSustain : 0
            decimals: 2
            increment: 0.1
            slideIncrement: 0.01
            applyLowerBound: true
            lowerBound: 0
            applyUpperBound: true
            upperBound: 1
            resetOnTap: true
            resetValue: 1
            selected: component.currentADSRElement === 2
            knobId: 1
            onValueChanged: {
                if (component.cppClipObject && component.cppClipObject.selectedSliceObject.adsrSustain != sustainSlider.value) {
                    component.cppClipObject.selectedSliceObject.adsrSustain = sustainSlider.value
                }
            }
            KnobIndicator {
                anchors {
                    top: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                width: Kirigami.Units.iconSizes.small
                height: width
                visible: parent.selected
                knobId: 3
            }
        }
        InfinitySlider {
            id: releaseSlider
            text: qsTr("Release")
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.showNotesSettings
            unitLabel: "\n" + qsTr("seconds")
            value: component.cppClipObject ? component.cppClipObject.selectedSliceObject.adsrRelease : 0
            decimals: 2
            increment: 0.1
            slideIncrement: 0.01
            applyLowerBound: true
            lowerBound: 0
            resetOnTap: true
            resetValue: 0
            selected: component.currentADSRElement === 3
            knobId: 1
            onValueChanged: {
                if (component.cppClipObject && component.cppClipObject.selectedSliceObject.adsrRelease != releaseSlider.value) {
                    component.cppClipObject.selectedSliceObject.adsrRelease = releaseSlider.value
                }
            }
            KnobIndicator {
                anchors {
                    top: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                width: Kirigami.Units.iconSizes.small
                height: width
                visible: parent.selected
                knobId: 3
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
            visible: component.showGranularSettings
            Kirigami.Heading {
                level: 2
                text: qsTr("Sustain")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                KnobIndicator {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.horizontalCenter
                        rightMargin: parent.paintedWidth / 2
                    }
                    width: Kirigami.Units.iconSizes.small
                    visible: component.currentADSRElement === 0 || component.currentADSRElement === 2
                    knobId: 1
                }
            }
            QQC2.Slider {
                implicitWidth: 1
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Vertical
                stepSize: 0.01
                value: component.cppClipObject ? component.cppClipObject.selectedSliceObject.grainSustain : 0
                from: 0
                to: 1
                onMoved: component.cppClipObject.selectedSliceObject.grainSustain = value
            }
            Kirigami.Heading {
                level: 2
                text: (component.cppClipObject ? component.cppClipObject.selectedSliceObject.grainSustain : 0).toFixed(2)
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: component.currentADSRElement === 0 || component.currentADSRElement === 2 ? Kirigami.Theme.highlightedTextColor : "transparent"
                KnobIndicator {
                    anchors {
                        top: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    visible: component.currentADSRElement === 0 || component.currentADSRElement === 2
                    knobId: 3
                }
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
            visible: component.showGranularSettings
            Kirigami.Heading {
                level: 2
                text: qsTr("Tilt")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                KnobIndicator {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.horizontalCenter
                        rightMargin: parent.paintedWidth / 2
                    }
                    width: Kirigami.Units.iconSizes.small
                    visible: component.currentADSRElement === 1 || component.currentADSRElement === 3
                    knobId: 1
                }
            }
            QQC2.Slider {
                implicitWidth: 1
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Vertical
                stepSize: 0.01
                value: component.cppClipObject ? component.cppClipObject.selectedSliceObject.grainTilt : 0
                from: 0
                to: 1
                onMoved: component.cppClipObject.selectedSliceObject.grainTilt = value
            }
            Kirigami.Heading {
                level: 2
                text: (component.cppClipObject ? component.cppClipObject.selectedSliceObject.grainTilt : 0).toFixed(2)
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: component.currentADSRElement === 1 || component.currentADSRElement === 3 ? Kirigami.Theme.highlightedTextColor : "transparent"
                KnobIndicator {
                    anchors {
                        top: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    visible: component.currentADSRElement === 1 || component.currentADSRElement === 3
                    knobId: 3
                }
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            visible: component.showCrossfadeSettings
            Kirigami.Heading {
                level: 2
                text: qsTr("Loop Point")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                KnobIndicator {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.horizontalCenter
                        rightMargin: parent.paintedWidth / 2
                    }
                    width: Kirigami.Units.iconSizes.small
                    visible: component.currentADSRElement === 0
                    knobId: 1
                }
            }
            QQC2.Button {
                implicitWidth: 1
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                checked: component.cppClipObject ? component.cppClipObject.selectedSliceObject.loopStartCrossfadeDirection == Zynthbox.ClipAudioSource.CrossfadeInnie : false
                text: qsTr("Innie")
                MouseArea {
                    anchors.fill: parent
                    onClicked: component.cppClipObject.selectedSliceObject.loopStartCrossfadeDirection = Zynthbox.ClipAudioSource.CrossfadeInnie
                }
            }
            QQC2.Button {
                implicitWidth: 1
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                checked: component.cppClipObject ? component.cppClipObject.selectedSliceObject.loopStartCrossfadeDirection == Zynthbox.ClipAudioSource.CrossfadeOutie : false
                text: qsTr("Outie")
                MouseArea {
                    anchors.fill: parent
                    onClicked: component.cppClipObject.selectedSliceObject.loopStartCrossfadeDirection = Zynthbox.ClipAudioSource.CrossfadeOutie
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: component.currentADSRElement === 0 ? Kirigami.Theme.highlightedTextColor : "transparent"
                KnobIndicator {
                    anchors {
                        top: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    visible: component.currentADSRElement === 0
                    knobId: 3
                }
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            visible: component.showCrossfadeSettings
            Kirigami.Heading {
                level: 2
                text: qsTr("Stop Point")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                KnobIndicator {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.horizontalCenter
                        rightMargin: parent.paintedWidth / 2
                    }
                    width: Kirigami.Units.iconSizes.small
                    visible: component.currentADSRElement === 1
                    knobId: 1
                }
            }
            QQC2.Button {
                implicitWidth: 1
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                checked: component.cppClipObject ? component.cppClipObject.selectedSliceObject.stopCrossfadeDirection == Zynthbox.ClipAudioSource.CrossfadeInnie : false
                text: qsTr("Innie")
                MouseArea {
                    anchors.fill: parent
                    onClicked: component.cppClipObject.selectedSliceObject.stopCrossfadeDirection = Zynthbox.ClipAudioSource.CrossfadeInnie
                }
            }
            QQC2.Button {
                implicitWidth: 1
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                checked: component.cppClipObject ? component.cppClipObject.selectedSliceObject.stopCrossfadeDirection == Zynthbox.ClipAudioSource.CrossfadeOutie : false
                text: qsTr("Outie")
                MouseArea {
                    anchors.fill: parent
                    onClicked: component.cppClipObject.selectedSliceObject.stopCrossfadeDirection = Zynthbox.ClipAudioSource.CrossfadeOutie
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: component.currentADSRElement === 1 ? Kirigami.Theme.highlightedTextColor : "transparent"
                KnobIndicator {
                    anchors {
                        top: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    visible: component.currentADSRElement === 1
                    knobId: 3
                }
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            visible: component.showCrossfadeSettings
            Kirigami.Heading {
                level: 2
                text: qsTr("Amount")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                KnobIndicator {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.horizontalCenter
                        rightMargin: parent.paintedWidth / 2
                    }
                    width: Kirigami.Units.iconSizes.small
                    visible: component.currentADSRElement === 2
                    knobId: 1
                }
            }
            QQC2.Slider {
                implicitWidth: 1
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Vertical
                stepSize: 0.01
                value: component.cppClipObject ? component.cppClipObject.selectedSliceObject.loopCrossfadeAmount : 0
                from: 0
                to: 0.5
                onMoved: component.cppClipObject.selectedSliceObject.loopCrossfadeAmount = value
            }
            Kirigami.Heading {
                level: 2
                text: qsTr("%1% of\nloop").arg((component.cppClipObject ? component.cppClipObject.selectedSliceObject.loopCrossfadeAmount : 0).toFixed(2) * 100)
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: component.currentADSRElement === 2 ? Kirigami.Theme.highlightedTextColor : "transparent"
                KnobIndicator {
                    anchors {
                        top: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    visible: component.currentADSRElement === 2
                    knobId: 3
                }
            }
        }
        AbstractADSRView {
            id: adsrView
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
            property double grainRemaining: component.cppClipObject ? (1 - component.cppClipObject.selectedSliceObject.grainSustain) : 1;

            property double crossfadeSustainDuration: component.cppClipObject
                ? component.cppClipObject.selectedSliceObject.loopStartCrossfadeDirection == Zynthbox.ClipAudioSource.CrossfadeInnie && component.cppClipObject.selectedSliceObject.stopCrossfadeDirection == Zynthbox.ClipAudioSource.CrossfadeInnie
                    ? 1 - (component.cppClipObject.selectedSliceObject.loopCrossfadeAmount * 2) // Both are innies
                    : component.cppClipObject.selectedSliceObject.loopStartCrossfadeDirection == Zynthbox.ClipAudioSource.CrossfadeInnie || component.cppClipObject.selectedSliceObject.stopCrossfadeDirection == Zynthbox.ClipAudioSource.CrossfadeInnie
                        ? 1 - component.cppClipObject.selectedSliceObject.loopCrossfadeAmount // One of the two is an outie
                        : 1
                : 1
            attackLine: component.showCrossfadeSettings && component.cppClipObject.selectedSliceObject.loopStartCrossfadeDirection == Zynthbox.ClipAudioSource.CrossfadeInnie // vertical line at attack start point
            attackLabel: qsTr("Loop Area")
            // decayLine: false // vertical line at decay start point - don't need this for this thing (it's functionally similar to the grain envelope, minus tilt, and with slightly different sustain length logic)
            // decayLabel: ""
            sustainLine: component.showCrossfadeSettings && component.cppClipObject.selectedSliceObject.loopStartCrossfadeDirection == Zynthbox.ClipAudioSource.CrossfadeOutie // vertical line at sustain start point
            sustainLabel: adsrView.crossfadeSustainDuration > 0 ? qsTr("Loop Area") : ""
            releaseLine: component.showCrossfadeSettings && component.cppClipObject.selectedSliceObject.stopCrossfadeDirection == Zynthbox.ClipAudioSource.CrossfadeOutie // vertical line at release start point
            // releaseLabel: ""
            endLine: component.showCrossfadeSettings && component.cppClipObject.selectedSliceObject.stopCrossfadeDirection == Zynthbox.ClipAudioSource.CrossfadeInnie // vertical line at envelope end point
            // endLabel: ""
            attackValue: component.cppClipObject
                ? component.showCrossfadeSettings
                    ? component.cppClipObject.selectedSliceObject.loopCrossfadeAmount
                    : component.showGranularSettings
                        ? grainRemaining * component.cppClipObject.selectedSliceObject.grainTilt
                        : component.showCrossfadeSettings
                            ? 0
                            : component.cppClipObject.selectedSliceObject.adsrAttack
                : 0
            attackMax: component.cppClipObject
                ? component.showCrossfadeSettings
                    ? 1
                    : component.showGranularSettings
                        ? 1
                        : Math.max(1, component.cppClipObject.selectedSliceObject.adsrAttack)
                : 1
            decayValue: component.cppClipObject
                ? component.showCrossfadeSettings
                    ? 0
                    : component.showGranularSettings
                        ? 0
                        : component.cppClipObject.selectedSliceObject.adsrDecay
                : 0
            decayMax: component.cppClipObject
                ? component.showCrossfadeSettings
                    ? 2
                    : component.showGranularSettings
                        ? 2
                        : Math.max(1, component.cppClipObject.selectedSliceObject.adsrDecay)
                : 2
            decayWidth: component.cppClipObject
                ? component.showCrossfadeSettings
                    ? 0
                    : component.showGranularSettings
                        ? 0
                        : decayMax
                : 0
            sustainValue: component.cppClipObject
                ? component.showCrossfadeSettings
                    ? 1
                    : component.showGranularSettings
                        ? 1
                        : component.cppClipObject.selectedSliceObject.adsrSustain
                : 0
            sustainMax: 1
            sustainWidth: component.cppClipObject
                ? component.showCrossfadeSettings
                    ? adsrView.crossfadeSustainDuration
                    : component.showGranularSettings
                        ? component.cppClipObject.selectedSliceObject.grainSustain
                        : 1
                : 1
            releaseValue: component.cppClipObject
                ? component.showCrossfadeSettings
                    ? component.cppClipObject.selectedSliceObject.loopCrossfadeAmount
                    : component.showGranularSettings
                        ? grainRemaining * (1.0 - component.cppClipObject.selectedSliceObject.grainTilt)
                        : component.cppClipObject.selectedSliceObject.adsrRelease
                : 0
            releaseMax: component.cppClipObject
                ? component.showCrossfadeSettings
                    ? 1
                    : component.showGranularSettings
                        ? 1
                        : Math.max(1, component.cppClipObject.selectedSliceObject.adsrRelease)
                : 1
            Connections {
                target: component
                onClipChanged: {
                    if (component.visible) {
                        adsrView.requestPaint()
                    }
                }
                onVisibleChanged: {
                    if (component.visible) {
                        adsrView.requestPaint();
                    }
                }
            }
            Connections {
                target: component.cppClipObject ? component.cppClipObject.selectedSliceObject : null
                function update() {
                    if (component.visible) {
                        adsrView.requestPaint();
                    }
                }
                onGrainSustainChanged: update()
                onGrainTiltChanged: update()
                onAdsrAttackChanged: update()
                onAdsrDecayChanged: update()
                onAdsrReleaseChanged: update()
                onAdsrSustainChanged: update()
                onLoopStartCrossfadeDirectionChanged: update()
                onStopCrossfadeDirectionChanged: update()
                onLoopCrossfadeAmountChanged: update()
            }
        }
    }
}
