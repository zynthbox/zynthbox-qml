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
    signal saveMetadata()
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
                    clip.grainSustain = Math.min(1, clip.grainSustain + 0.01);
                    break;
                case 1:
                case 3:
                    clip.grainTilt = Math.min(1, clip.grainTilt + 0.01);
                    break;
            }
        } else {
            switch(currentADSRElement) {
                case 0:
                    clip.adsrAttack = Math.min(2, clip.adsrAttack + 0.01);
                    break;
                case 1:
                    clip.adsrDecay = Math.min(2, clip.adsrDecay + 0.01);
                    break;
                case 2:
                    clip.adsrSustain = Math.min(1, clip.adsrSustain + 0.01);
                    break;
                case 3:
                    clip.adsrRelease = Math.min(2, clip.adsrRelease + 0.01);
                    break;
            }
        }
    }
    function decreaseCurrentValue() {
        if (showGranularSettings) {
            switch(currentADSRElement) {
                case 0:
                case 2:
                    clip.grainSustain = Math.max(0, clip.grainSustain - 0.01);
                    break;
                case 1:
                case 3:
                    clip.grainTilt = Math.max(0, clip.grainTilt - 0.01);
                    break;
            }
        } else {
            switch(currentADSRElement) {
                case 0:
                    clip.adsrAttack = Math.max(0, clip.adsrAttack - 0.01);
                    break;
                case 1:
                    clip.adsrDecay = Math.max(0, clip.adsrDecay - 0.01);
                    break;
                case 2:
                    clip.adsrSustain = Math.max(0, clip.adsrSustain - 0.01);
                    break;
                case 3:
                    clip.adsrRelease = Math.max(0, clip.adsrRelease - 0.01);
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
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.showGranularSettings === false
            Kirigami.Heading {
                level: 2
                text: qsTr("Attack")
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
                value: component.clip ? component.clip.adsrAttack : 0
                from: 0
                to: 2
                onMoved: component.clip.adsrAttack = value
            }
            Kirigami.Heading {
                level: 2
                text: qsTr("%1\nseconds").arg((component.clip ? component.clip.adsrAttack : 0).toFixed(2))
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: component.currentADSRElement === 0 ? Kirigami.Theme.highlightedTextColor : "transparent"
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.showGranularSettings === false
            Kirigami.Heading {
                level: 2
                text: qsTr("Decay")
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
                value: component.clip ? component.clip.adsrDecay : 0
                from: 0
                to: 2
                onMoved: component.clip.adsrDecay = value
            }
            Kirigami.Heading {
                level: 2
                text: qsTr("%1\nseconds").arg((component.clip ? component.clip.adsrDecay : 0).toFixed(2))
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: component.currentADSRElement === 1 ? Kirigami.Theme.highlightedTextColor : "transparent"
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.showGranularSettings === false
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
                value: component.clip ? component.clip.adsrSustain : 0
                from: 0
                to: 1
                onMoved: component.clip.adsrSustain = value
            }
            Kirigami.Heading {
                level: 2
                text: "%1%\n".arg(component.clip ? component.clip.adsrSustain.toFixed(2) * 100 : 0)
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: component.currentADSRElement === 2 ? Kirigami.Theme.highlightedTextColor : "transparent"
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: component.showGranularSettings === false
            Kirigami.Heading {
                level: 2
                text: qsTr("Release")
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
                value: component.clip ? component.clip.adsrRelease : 0
                from: 0
                to: 2
                onMoved: component.clip.adsrRelease = value
            }
            Kirigami.Heading {
                level: 2
                text: qsTr("%1\nseconds").arg((component.clip ? component.clip.adsrRelease : 0).toFixed(2))
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: component.currentADSRElement === 3 ? Kirigami.Theme.highlightedTextColor : "transparent"
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
                value: component.clip ? component.clip.grainSustain : 0
                from: 0
                to: 1
                onMoved: component.clip.grainSustain = value
            }
            Kirigami.Heading {
                level: 2
                text: (component.clip ? component.clip.grainSustain : 0).toFixed(2)
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
                value: component.clip ? component.clip.grainTilt : 0
                from: 0
                to: 1
                onMoved: component.clip.grainTilt = value
            }
            Kirigami.Heading {
                level: 2
                text: (component.clip ? component.clip.grainTilt : 0).toFixed(2)
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
            property double grainRemaining: component.clip ? (1 - component.clip.grainSustain) : 1;
            attackValue: component.clip ? (component.showGranularSettings ? grainRemaining * component.clip.grainTilt : component.clip.adsrAttack) : 0
            attackMax: component.showGranularSettings ? 1 : 2
            decayValue: component.clip ? (component.showGranularSettings ? 0 : component.clip.adsrDecay) : 0
            decayMax: 2
            decayWidth: component.showGranularSettings ? 0 : 1;
            sustainValue: component.clip ? (component.showGranularSettings ? 1 : component.clip.adsrSustain) : 0
            sustainMax: 1
            sustainWidth: component.clip ? (component.showGranularSettings ? component.clip.grainSustain : 1) : 1
            releaseValue: component.clip ? (component.showGranularSettings ? grainRemaining * (1.0 - component.clip.grainTilt) : component.clip.adsrRelease) : 0
            releaseMax: component.showGranularSettings ? 1 : 2
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
                target: component.clip
                function updateAndSave() {
                    if (component.visible) {
                        adsrView.requestPaint();
                        component.saveMetadata();
                    }
                }
                onGrainTiltChanged: updateAndSave()
                onGrainSustainChanged: updateAndSave();
                onAdsrParametersChanged: updateAndSave()
            }
        }
    }
}
