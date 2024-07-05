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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
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
        if (currentADSRElement === 3) {
            currentADSRElement = 0;
        } else {
            currentADSRElement = currentADSRElement + 1;
        }
    }
    function previousADSRElement() {
        if (currentADSRElement === 0) {
            currentADSRElement = 3;
        } else {
            currentADSRElement = currentADSRElement - 1;
        }
    }
    function increaseCurrentValue() {
        if (showGranularSettings) {
            switch(currentADSRElement) {
                case 0:
                case 2:
                    cppClipObject.grainSustain = Math.min(1, cppClipObject.grainSustain + 0.01);
                    break;
                case 1:
                case 3:
                    cppClipObject.grainTilt = Math.min(1, cppClipObject.grainTilt + 0.01);
                    break;
            }
        } else {
            switch(currentADSRElement) {
                case 0:
                    cppClipObject.adsrAttack = cppClipObject.adsrAttack + 0.01;
                    break;
                case 1:
                    cppClipObject.adsrDecay = cppClipObject.adsrDecay + 0.01;
                    break;
                case 2:
                    cppClipObject.adsrSustain = Math.min(1, cppClipObject.adsrSustain + 0.01);
                    break;
                case 3:
                    cppClipObject.adsrRelease = cppClipObject.adsrRelease + 0.01;
                    break;
            }
        }
    }
    function decreaseCurrentValue() {
        if (showGranularSettings) {
            switch(currentADSRElement) {
                case 0:
                case 2:
                    cppClipObject.grainSustain = Math.max(0, cppClipObject.grainSustain - 0.01);
                    break;
                case 1:
                case 3:
                    cppClipObject.grainTilt = Math.max(0, cppClipObject.grainTilt - 0.01);
                    break;
            }
        } else {
            switch(currentADSRElement) {
                case 0:
                    cppClipObject.adsrAttack = Math.max(0, cppClipObject.adsrAttack - 0.01);
                    break;
                case 1:
                    cppClipObject.adsrDecay = Math.max(0, cppClipObject.adsrDecay - 0.01);
                    break;
                case 2:
                    cppClipObject.adsrSustain = Math.max(0, cppClipObject.adsrSustain - 0.01);
                    break;
                case 3:
                    cppClipObject.adsrRelease = Math.max(0, cppClipObject.adsrRelease - 0.01);
                    break;
            }
        }
    }
    QtObject {
        id: _private
        property int settingsCategory: 0
    }
    property QtObject cppObj: clip && clip.hasOwnProperty("cppObjId") ? Zynthbox.PlayGridManager.getClipById(clip.cppObjId) : null
    property bool showGranularSettings: cppObj && cppObj.granular ? _private.settingsCategory === 1 : false
    RowLayout {
        anchors.fill: parent
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.cppObj ? component.cppObj.granular : false
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("Notes")
                checked: _private.settingsCategory === 0
                MouseArea {
                    anchors.fill: parent;
                    onClicked: _private.settingsCategory = 0
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("Grains")
                checked: _private.settingsCategory === 1
                MouseArea {
                    anchors.fill: parent;
                    onClicked: _private.settingsCategory = 1
                }
            }
        }
        Connections {
            target: component.cppClipObject
            function update() {
                if (component.cppClipObject.adsrAttack !== attackSlider.value) {
                    attackSlider.value = component.cppClipObject.adsrAttack;
                }
                if (component.cppClipObject.adsrDecay !== decaySlider.value) {
                    decaySlider.value = component.cppClipObject.adsrDecay;
                }
                if (component.cppClipObject.adsrSustain !== sustainSlider.value) {
                    sustainSlider.value = component.cppClipObject.adsrSustain;
                }
                if (component.cppClipObject.adsrRelease !== releaseSlider.value) {
                    releaseSlider.value = component.cppClipObject.adsrRelease;
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
            visible: component.showGranularSettings === false
            unitLabel: "\n" + qsTr("seconds")
            value: component.cppClipObject ? component.cppClipObject.adsrAttack : 0
            decimals: 2
            increment: 0.1
            slideIncrement: 0.01
            applyLowerBound: true
            lowerBound: 0
            resetOnTap: true
            resetValue: 0
            selected: component.currentADSRElement === 0
            onValueChanged: {
                if (component.cppClipObject && component.cppClipObject.adsrAttack != attackSlider.value) {
                    component.cppClipObject.adsrAttack = attackSlider.value
                }
            }
        }
        InfinitySlider {
            id: decaySlider
            text: qsTr("Decay")
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.showGranularSettings === false
            unitLabel: "\n" + qsTr("seconds")
            value: component.cppClipObject ? component.cppClipObject.adsrDecay : 0
            decimals: 2
            increment: 0.1
            slideIncrement: 0.01
            applyLowerBound: true
            lowerBound: 0
            resetOnTap: true
            resetValue: 0
            selected: component.currentADSRElement === 1
            onValueChanged: {
                if (component.cppClipObject && component.cppClipObject.adsrDecay != decaySlider.value) {
                    component.cppClipObject.adsrDecay = decaySlider.value
                }
            }
        }
        InfinitySlider {
            id: sustainSlider
            text: qsTr("Sustain")
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.showGranularSettings === false
            unitLabel: "%"
            value: component.cppClipObject ? component.cppClipObject.adsrSustain : 0
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
            onValueChanged: {
                if (component.cppClipObject && component.cppClipObject.adsrSustain != sustainSlider.value) {
                    component.cppClipObject.adsrSustain = sustainSlider.value
                }
            }
        }
        InfinitySlider {
            id: releaseSlider
            text: qsTr("Release")
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.showGranularSettings === false
            unitLabel: "\n" + qsTr("seconds")
            value: component.cppClipObject ? component.cppClipObject.adsrRelease : 0
            decimals: 2
            increment: 0.1
            slideIncrement: 0.01
            applyLowerBound: true
            lowerBound: 0
            resetOnTap: true
            resetValue: 0
            selected: component.currentADSRElement === 3
            onValueChanged: {
                if (component.cppClipObject && component.cppClipObject.adsrRelease != releaseSlider.value) {
                    component.cppClipObject.adsrRelease = releaseSlider.value
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
                text: qsTr("Sustain")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            QQC2.Slider {
                implicitWidth: 1
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Vertical
                stepSize: 0.01
                value: component.cppClipObject ? component.cppClipObject.grainSustain : 0
                from: 0
                to: 1
                onMoved: component.cppClipObject.grainSustain = value
            }
            Kirigami.Heading {
                level: 2
                text: (component.cppClipObject ? component.cppClipObject.grainSustain : 0).toFixed(2)
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: component.currentADSRElement === 0 || component.currentADSRElement === 2 ? Kirigami.Theme.highlightedTextColor : "transparent"
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
            }
            QQC2.Slider {
                implicitWidth: 1
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Vertical
                stepSize: 0.01
                value: component.cppClipObject ? component.cppClipObject.grainTilt : 0
                from: 0
                to: 1
                onMoved: component.cppClipObject.grainTilt = value
            }
            Kirigami.Heading {
                level: 2
                text: (component.cppClipObject ? component.cppClipObject.grainTilt : 0).toFixed(2)
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: component.currentADSRElement === 1 || component.currentADSRElement === 3 ? Kirigami.Theme.highlightedTextColor : "transparent"
            }
        }
        AbstractADSRView {
            id: adsrView
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
            property double grainRemaining: component.cppClipObject ? (1 - component.cppClipObject.grainSustain) : 1;
            attackValue: component.cppClipObject ? (component.showGranularSettings ? grainRemaining * component.cppClipObject.grainTilt : component.cppClipObject.adsrAttack) : 0
            attackMax: component.showGranularSettings ? 1 : Math.max(1, component.cppClipObject ? component.cppClipObject.adsrAttack : 1)
            decayValue: component.cppClipObject ? (component.showGranularSettings ? 0 : component.cppClipObject.adsrDecay) : 0
            decayMax: component.showGranularSettings ? 2 : Math.max(1, component.cppClipObject ? component.cppClipObject.adsrDecay : 2)
            decayWidth: component.showGranularSettings ? 0 : decayMax;
            sustainValue: component.cppClipObject ? (component.showGranularSettings ? 1 : component.cppClipObject.adsrSustain) : 0
            sustainMax: 1
            sustainWidth: component.cppClipObject ? (component.showGranularSettings ? component.cppClipObject.grainSustain : 1) : 1
            releaseValue: component.cppClipObject ? (component.showGranularSettings ? grainRemaining * (1.0 - component.cppClipObject.grainTilt) : component.cppClipObject.adsrRelease) : 0
            releaseMax: component.showGranularSettings ? 1 : Math.max(1, component.cppClipObject ? component.cppClipObject.adsrRelease : 1)
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
                target: component.cppClipObject
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
            }
        }
    }
}
