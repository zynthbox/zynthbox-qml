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

Item {
    id: component
    property QtObject clip
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
                    clip.metadata.graineratorSustain = Math.min(1, clip.metadata.graineratorSustain + 0.01);
                    break;
                case 1:
                case 3:
                    clip.metadata.graineratorTilt = Math.min(1, clip.metadata.graineratorTilt + 0.01);
                    break;
            }
        } else {
            switch(currentADSRElement) {
                case 0:
                    clip.metadata.adsrAttack = clip.metadata.adsrAttack + 0.01;
                    break;
                case 1:
                    clip.metadata.adsrDecay = clip.metadata.adsrDecay + 0.01;
                    break;
                case 2:
                    clip.metadata.adsrSustain = Math.min(1, clip.metadata.adsrSustain + 0.01);
                    break;
                case 3:
                    clip.metadata.adsrRelease = clip.metadata.adsrRelease + 0.01;
                    break;
            }
        }
    }
    function decreaseCurrentValue() {
        if (showGranularSettings) {
            switch(currentADSRElement) {
                case 0:
                case 2:
                    clip.metadata.graineratorSustain = Math.max(0, clip.metadata.graineratorSustain - 0.01);
                    break;
                case 1:
                case 3:
                    clip.metadata.graineratorTilt = Math.max(0, clip.metadata.graineratorTilt - 0.01);
                    break;
            }
        } else {
            switch(currentADSRElement) {
                case 0:
                    clip.metadata.adsrAttack = Math.max(0, clip.metadata.adsrAttack - 0.01);
                    break;
                case 1:
                    clip.metadata.adsrDecay = Math.max(0, clip.metadata.adsrDecay - 0.01);
                    break;
                case 2:
                    clip.metadata.adsrSustain = Math.max(0, clip.metadata.adsrSustain - 0.01);
                    break;
                case 3:
                    clip.metadata.adsrRelease = Math.max(0, clip.metadata.adsrRelease - 0.01);
                    break;
            }
        }
    }
    QtObject {
        id: _private
        property int settingsCategory: 0
    }
    property bool showGranularSettings: clip && clip.granular && _private.settingsCategory === 1
    RowLayout {
        anchors.fill: parent
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.clip && component.clip.granular
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
            enabled: component.clip != null
            target: component.clip.metadata
            function update() {
                if (component.clip.metadata.adsrAttack !== attackSlider.value) {
                    attackSlider.value = component.clip.metadata.adsrAttack;
                }
                if (component.clip.metadata.adsrDecay !== decaySlider.value) {
                    decaySlider.value = component.clip.metadata.adsrDecay;
                }
                if (component.clip.metadata.adsrSustain !== sustainSlider.value) {
                    sustainSlider.value = component.clip.metadata.adsrSustain;
                }
                if (component.clip.metadata.adsrRelease !== releaseSlider.value) {
                    releaseSlider.value = component.clip.metadata.adsrRelease;
                }
            }
            onAdsrAttackChanged: update()
            onAdsrDecayChanged: update()
            onAdsrReleaseChanged: update()
            onAdsrSustainChanged: update()
        }
        InfinitySlider {
            id: attackSlider
            text: qsTr("Attack")
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.showGranularSettings === false
            unitLabel: "\n" + qsTr("seconds")
            value: component.clip ? component.clip.metadata.adsrAttack : 0
            decimals: 2
            increment: 0.1
            slideIncrement: 0.01
            applyLowerBound: true
            lowerBound: 0
            resetOnTap: true
            resetValue: 0
            selected: component.currentADSRElement === 0
            onValueChanged: {
                if (component.clip && component.clip.metadata.adsrAttack != attackSlider.value) {
                    component.clip.metadata.adsrAttack = attackSlider.value
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
            value: component.clip ? component.clip.metadata.adsrDecay : 0
            decimals: 2
            increment: 0.1
            slideIncrement: 0.01
            applyLowerBound: true
            lowerBound: 0
            resetOnTap: true
            resetValue: 0
            selected: component.currentADSRElement === 1
            onValueChanged: {
                if (component.clip && component.clip.metadata.adsrDecay != decaySlider.value) {
                    component.clip.metadata.adsrDecay = decaySlider.value
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
            value: component.clip ? component.clip.metadata.adsrSustain : 0
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
                if (component.clip && component.clip.metadata.adsrSustain != sustainSlider.value) {
                    component.clip.metadata.adsrSustain = sustainSlider.value
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
            value: component.clip ? component.clip.metadata.adsrRelease : 0
            decimals: 2
            increment: 0.1
            slideIncrement: 0.01
            applyLowerBound: true
            lowerBound: 0
            resetOnTap: true
            resetValue: 0
            selected: component.currentADSRElement === 3
            onValueChanged: {
                if (component.clip && component.clip.metadata.adsrRelease != releaseSlider.value) {
                    component.clip.metadata.adsrRelease = releaseSlider.value
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
                value: component.clip ? component.clip.metadata.graineratorSustain : 0
                from: 0
                to: 1
                onMoved: component.clip.metadata.graineratorSustain = value
            }
            Kirigami.Heading {
                level: 2
                text: (component.clip ? component.clip.metadata.graineratorSustain : 0).toFixed(2)
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
                value: component.clip ? component.clip.metadata.graineratorTilt : 0
                from: 0
                to: 1
                onMoved: component.clip.metadata.graineratorTilt = value
            }
            Kirigami.Heading {
                level: 2
                text: (component.clip ? component.clip.metadata.graineratorTilt : 0).toFixed(2)
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
            property double grainRemaining: component.clip ? (1 - component.clip.metadata.graineratorSustain) : 1;
            attackValue: component.clip ? (component.showGranularSettings ? grainRemaining * component.clip.metadata.graineratorTilt : component.clip.metadata.adsrAttack) : 0
            attackMax: component.showGranularSettings ? 1 : Math.max(1, component.clip ? component.clip.metadata.adsrAttack : 1)
            decayValue: component.clip ? (component.showGranularSettings ? 0 : component.clip.metadata.adsrDecay) : 0
            decayMax: component.showGranularSettings ? 2 : Math.max(1, component.clip ? component.clip.metadata.adsrDecay : 2)
            decayWidth: component.showGranularSettings ? 0 : decayMax;
            sustainValue: component.clip ? (component.showGranularSettings ? 1 : component.clip.metadata.adsrSustain) : 0
            sustainMax: 1
            sustainWidth: component.clip ? (component.showGranularSettings ? component.clip.metadata.graineratorSustain : 1) : 1
            releaseValue: component.clip ? (component.showGranularSettings ? grainRemaining * (1.0 - component.clip.metadata.graineratorTilt) : component.clip.metadata.adsrRelease) : 0
            releaseMax: component.showGranularSettings ? 1 : Math.max(1, component.clip ? component.clip.metadata.adsrRelease : 1)
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
                enabled: component.clip != null
                target: component.clip.metadata
                function update() {
                    if (component.visible) {
                        adsrView.requestPaint();
                    }
                }
                onGraineratorSustainChanged: update()
                onGraineratorTiltChanged: update()
                onAdsrAttackChanged: update()
                onAdsrDecayChanged: update()
                onAdsrReleaseChanged: update()
                onAdsrSustainChanged: update()
            }
        }
    }
}
