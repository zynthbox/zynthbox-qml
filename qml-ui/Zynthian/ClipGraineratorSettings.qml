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
import Zynthian 1.0 as Zynthian

Item {
    id: component
    property QtObject clip
    property QtObject cppClipObject: component.clip && component.clip.hasOwnProperty("cppObjId")
                                        ? Zynthbox.PlayGridManager.getClipById(component.clip.cppObjId)
                                        : null
    function nextElement() {
        if (_private.currentElement === _private.elementMax) {
            _private.currentElement = 0;
        } else {
            _private.currentElement = _private.currentElement + 1;
        }
    }
    function previousElement() {
        if (_private.currentElement === 0) {
            _private.currentElement = _private.elementMax;
        } else {
            _private.currentElement = _private.currentElement - 1;
        }
    }
    function increaseCurrentValue() {
        if (_private.settingsCategory === 0) {
            switch(_private.currentElement) {
                case 0:
                    component.clip.playbackStyle = Zynthbox.ClipAudioSource.GranularNonLoopingPlaybackStyle;
                    break;
                case 1:
                    component.cppClipObject.grainPosition = Math.min(1, component.cppClipObject.grainPosition + 0.001);
                    break;
                case 2:
                    component.cppClipObject.grainSpray = Math.min(1, component.cppClipObject.grainSpray + 0.001);
                    break;
                case 3:
                    component.cppClipObject.grainScan = Math.min(100, component.cppClipObject.grainScan + 0.01);
                    break;
                default:
                    break;
            }
        } else if (_private.settingsCategory === 1) {
            switch(_private.currentElement) {
                case 0:
                    component.cppClipObject.grainInterval = component.cppClipObject.grainInterval + 0.1;
                    break;
                case 1:
                    component.cppClipObject.grainIntervalAdditional = component.cppClipObject.grainIntervalAdditional + 0.1;
                    break;
                case 2:
                    component.cppClipObject.grainSize = component.cppClipObject.grainSize + 0.1;
                    break;
                case 3:
                    component.cppClipObject.grainSizeAdditional = component.cppClipObject.grainSizeAdditional + 0.1;
                    break;
                default:
                    break;
            }
        } else if (_private.settingsCategory === 2) {
            switch(_private.currentElement) {
                case 0:
                    component.cppClipObject.grainPanMinimum = Math.min(1, component.cppClipObject.grainPanMinimum + 0.01);
                    break;
                case 1:
                    component.cppClipObject.grainPanMaximum = Math.min(1, component.cppClipObject.grainPanMaximum + 0.01);
                    break;
                case 2:
                    component.cppClipObject.grainPitchMinimum1 = Math.min(2, component.cppClipObject.grainPitchMinimum1 + 0.01);
                    break;
                case 3:
                    component.cppClipObject.grainPitchMaximum1 = Math.min(2, component.cppClipObject.grainPitchMaximum1 + 0.01);
                    break;
                case 4:
                    component.cppClipObject.grainPitchPriority = Math.min(1, component.cppClipObject.grainPitchPriority + 0.01);
                    break;
                case 5:
                    component.cppClipObject.grainPitchMinimum2 = Math.min(2, component.cppClipObject.grainPitchMinimum2 + 0.01);
                    break;
                case 6:
                    component.cppClipObject.grainPitchMaximum2 = Math.min(2, component.cppClipObject.grainPitchMaximum2 + 0.01);
                    break;
                default:
                    break;
            }
        }
    }
    function decreaseCurrentValue() {
        if (_private.settingsCategory === 0) {
            switch(_private.currentElement) {
                case 0:
                    component.clip.playbackStyle = Zynthbox.ClipAudioSource.GranularLoopingPlaybackStyle;
                    break;
                case 1:
                    component.cppClipObject.grainPosition = Math.max(0, component.cppClipObject.grainPosition - 0.001);
                    break;
                case 2:
                    component.cppClipObject.grainSpray = Math.max(0, component.cppClipObject.grainSpray - 0.001);
                    break;
                case 3:
                    component.cppClipObject.grainScan = Math.max(-100, component.cppClipObject.grainScan - 0.01);
                    break;
                default:
                    break;
            }
        } else if (_private.settingsCategory === 1) {
            switch(_private.currentElement) {
                case 0:
                    component.cppClipObject.grainInterval = Math.max(1, component.cppClipObject.grainInterval - 0.1);
                    break;
                case 1:
                    component.cppClipObject.grainIntervalAdditional = Math.max(0, component.cppClipObject.grainIntervalAdditional - 0.1);
                    break;
                case 2:
                    component.cppClipObject.grainSize = Math.max(1, component.cppClipObject.grainSize - 0.1);
                    break;
                case 3:
                    component.cppClipObject.grainSizeAdditional = Math.max(0, component.cppClipObject.grainSizeAdditional - 0.1);
                    break;
                default:
                    break;
            }
        } else if (_private.settingsCategory === 2) {
            switch(_private.currentElement) {
                case 0:
                    component.cppClipObject.grainPanMinimum = Math.max(-1, component.cppClipObject.grainPanMinimum - 0.01);
                    break;
                case 1:
                    component.cppClipObject.grainPanMaximum = Math.max(-1, component.cppClipObject.grainPanMaximum - 0.01);
                    break;
                case 2:
                    component.cppClipObject.grainPitchMinimum1 = Math.max(-2, component.cppClipObject.grainPitchMinimum1 - 0.01);
                    break;
                case 3:
                    component.cppClipObject.grainPitchMaximum1 = Math.max(-2, component.cppClipObject.grainPitchMaximum1 - 0.01);
                    break;
                case 4:
                    component.cppClipObject.grainPitchPriority = Math.max(-1, component.cppClipObject.grainPitchPriority - 0.01);
                    break;
                case 5:
                    component.cppClipObject.grainPitchMinimum2 = Math.max(-2, component.cppClipObject.grainPitchMinimum2 - 0.01);
                    break;
                case 6:
                    component.cppClipObject.grainPitchMaximum2 = Math.max(-2, component.cppClipObject.grainPitchMaximum2 - 0.01);
                    break;
                default:
                    break;
            }
        }
    }
    QtObject {
        id: _private
        property int currentElement: 0
        property int elementMax: 9
        property int settingsCategory: 0
    }
    RowLayout {
        anchors.fill: parent
        spacing: 0
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            enabled: component.cppClipObject && component.cppClipObject.granular
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("Notes")
                checked: _private.settingsCategory === 0
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        _private.currentElement = 0;
                        _private.elementMax = 3;
                        _private.settingsCategory = 0;
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("Voices")
                checked: _private.settingsCategory === 1
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        _private.currentElement = 0;
                        _private.elementMax = 3;
                        _private.settingsCategory = 1;
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("Positions")
                checked: _private.settingsCategory === 2
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        _private.currentElement = 0;
                        _private.elementMax = 6;
                        _private.settingsCategory = 2;
                    }
                }
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: _private.settingsCategory === 0
            Kirigami.Heading {
                level: 2
                text: qsTr("Grainerator\nLooping")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                function toggleGraineratorLooping() {
                    if (component.clip.playbackStyle == Zynthbox.ClipAudioSource.GranularLoopingPlaybackStyle) {
                        component.clip.playbackStyle = Zynthbox.ClipAudioSource.GranularNonLoopingPlaybackStyle;
                    } else {
                        component.clip.playbackStyle = Zynthbox.ClipAudioSource.GranularLoopingPlaybackStyle;
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: toggleGraineratorLooping()
                }
                QQC2.Switch {
                    id: granularEnabledSwitch
                    anchors.centerIn: parent
                    width: Math.min(Math.round(parent.width / 4 * 3), Kirigami.Units.gridUnit * 5)
                    height: Kirigami.Units.gridUnit * 3
                    checked: component.clip ? (component.clip.playbackStyle == Zynthbox.ClipAudioSource.GranularLoopingPlaybackStyle) : false
                    onToggled: toggleGraineratorLooping()
                    Connections {
                        target: component.cppClipObject
                        onGranularChanged: granularEnabledSwitch.checked = (component.clip.playbackStyle == Zynthbox.ClipAudioSource.GranularLoopingPlaybackStyle)
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: _private.currentElement === 0 ? Kirigami.Theme.highlightedTextColor : "transparent"
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit  * 1.5
            visible: _private.settingsCategory === 0
            Kirigami.Heading {
                level: 2
                text: qsTr("Position")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            QQC2.Slider {
                id: grainPositionSlider
                implicitWidth: 1
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Vertical
                stepSize: 0.001
                value: component.cppClipObject ? component.cppClipObject.grainPosition : 0
                from: 0
                to: 1
                onMoved: component.cppClipObject.grainPosition = value
            }
            Kirigami.Heading {
                level: 2
                text: (component.cppClipObject ? component.cppClipObject.grainPosition : 0).toFixed(3)
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: _private.currentElement === 1 ? Kirigami.Theme.highlightedTextColor : "transparent"
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
            visible: _private.settingsCategory === 0
            Kirigami.Heading {
                level: 2
                text: qsTr("Spray")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            QQC2.Slider {
                id: grainSpraySlider
                implicitWidth: 1
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Vertical
                stepSize: 0.001
                value: component.cppClipObject ? component.cppClipObject.grainSpray : 0
                from: 0
                to: 1
                onMoved: component.cppClipObject.grainSpray = value
            }
            Kirigami.Heading {
                level: 2
                text: (component.cppClipObject ? component.cppClipObject.grainSpray : 0).toFixed(3)
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: _private.currentElement === 2 ? Kirigami.Theme.highlightedTextColor : "transparent"
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            visible: _private.settingsCategory === 0
            Kirigami.Heading {
                level: 2
                text: qsTr("Scan")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Zynthian.InfinitySlider {
                id: grainScanSlider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                value: component.cppClipObject ? component.cppClipObject.grainScan : 0
                decimals: 2
                increment: 0.1
                slideIncrement: 0.01
                applyLowerBound: true
                lowerBound: -100
                applyUpperBound: true
                upperBound: 100
                resetOnTap: true
                resetValue: 0
                selected: _private.currentElement === 3
                onValueChanged: component.cppClipObject.grainScan = value
                Connections {
                    target: component.cppClipObject
                    onGrainScanChanged: grainScanSlider.value = component.cppClipObject.grainScan
                }
            }
        }
        GridLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.smallSpacing
            columns: 2
            visible: _private.settingsCategory === 1
            Kirigami.Heading {
                Layout.columnSpan: 2
                level: 2
                text: qsTr("Interval (ms)")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Zynthian.InfinitySlider {
                id: grainIntervalSlider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Min")
                value: component.cppClipObject ? component.cppClipObject.grainInterval : 0
                decimals: 1
                increment: 1
                slideIncrement: 0.1
                applyLowerBound: true
                lowerBound: 1
                selected: _private.currentElement === 0
                onValueChanged: if (component.cppClipObject) { component.cppClipObject.grainInterval = value }
                Connections {
                    target: component.cppClipObject
                    onGrainIntervalChanged: grainIntervalSlider.value = component.cppClipObject.grainInterval
                }
            }
            Zynthian.InfinitySlider {
                id: grainIntervalAdditionalSlider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("More")
                value: component.cppClipObject ? component.cppClipObject.grainIntervalAdditional : 0
                decimals: 1
                increment: 1
                slideIncrement: 0.1
                applyLowerBound: true
                lowerBound: 0
                selected: _private.currentElement === 1
                onValueChanged: if (component.cppClipObject) { component.cppClipObject.grainIntervalAdditional = value }
                Connections {
                    target: component.cppClipObject
                    onGrainIntervalAdditionalChanged: grainIntervalAdditionalSlider.value = component.cppClipObject.grainIntervalAdditional
                }
            }
        }
        GridLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.smallSpacing
            columns: 2
            visible: _private.settingsCategory === 1
            Kirigami.Heading {
                Layout.columnSpan: 2
                level: 2
                text: qsTr("Size (ms)")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Zynthian.InfinitySlider {
                id: grainSizeSlider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Min")
                value: component.cppClipObject ? component.cppClipObject.grainSize : 0
                decimals: 1
                increment: 1
                slideIncrement: 0.1
                applyLowerBound: true
                lowerBound: 1
                selected: _private.currentElement === 2
                onValueChanged: if (component.cppClipObject) { component.cppClipObject.grainSize = value }
                Connections {
                    target: component.cppClipObject
                    onGrainSizeChanged: grainSizeSlider.value = component.cppClipObject.grainSize
                }
            }
            Zynthian.InfinitySlider {
                id: grainSizeAdditionalSlider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("More")
                value: component.cppClipObject ? component.cppClipObject.grainSizeAdditional : 0
                decimals: 1
                increment: 1
                slideIncrement: 1
                applyLowerBound: true
                lowerBound: 0
                selected: _private.currentElement === 3
                onValueChanged: if (component.cppClipObject) { component.cppClipObject.grainSizeAdditional = value }
                Connections {
                    target: component.cppClipObject
                    onGrainSizeAdditionalChanged: grainSizeAdditionalSlider.value = component.cppClipObject.grainSizeAdditional
                }
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            visible: _private.settingsCategory === 1
            QQC2.Label {
                Layout.fillHeight: true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: qsTr("Available\nVoices:\n%1").arg(32)
            }
            QQC2.Label {
                Layout.fillHeight: true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: component.cppClipObject
                    ? qsTr("Grains\nPer Note:\n%1 to %2")
                        .arg(Math.ceil(component.cppClipObject.grainSize / (component.cppClipObject.grainInterval + component.cppClipObject.grainIntervalAdditional)))
                        .arg(Math.floor((component.cppClipObject.grainSize + component.cppClipObject.grainSizeAdditional) / component.cppClipObject.grainInterval))
                    : ""
            }
        }
        GridLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.smallSpacing
            columns: 2
            visible: _private.settingsCategory === 2
            Kirigami.Heading {
                Layout.columnSpan: 2
                level: 2
                text: qsTr("Pan")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Zynthian.InfinitySlider {
                id: grainPanMinimumSlider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Min")
                value: component.cppClipObject ? component.cppClipObject.grainPanMinimum : 0
                applyLowerBound: true
                lowerBound: -1
                applyUpperBound: true
                upperBound: 1
                selected: _private.currentElement === 0
                onValueChanged: if (component.cppClipObject) { component.cppClipObject.grainPanMinimum = value }
                Connections {
                    target: component.cppClipObject
                    onGrainPanMinimumChanged: grainPanMinimumSlider.value = component.cppClipObject.grainPanMinimum
                }
            }
            Zynthian.InfinitySlider {
                id: grainPanMaximumSlider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Max")
                value: component.cppClipObject ? component.cppClipObject.grainPanMaximum : 0
                applyLowerBound: true
                lowerBound: -1
                applyUpperBound: true
                upperBound: 1
                selected: _private.currentElement === 1
                onValueChanged: if (component.cppClipObject) { component.cppClipObject.grainPanMaximum = value }
                Connections {
                    target: component.cppClipObject
                    onGrainPanMaximumChanged: grainPanMaximumSlider.value = component.cppClipObject.grainPanMaximum
                }
            }
        }
        GridLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.smallSpacing
            columns: 5
            visible: _private.settingsCategory === 2
            Kirigami.Heading {
                Layout.columnSpan: 5
                level: 2
                text: qsTr("Pitch Ranges")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Zynthian.InfinitySlider {
                id: grainPitchMinimum1Slider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Min 1")
                value: component.cppClipObject ? component.cppClipObject.grainPitchMinimum1 : 0
                applyLowerBound: true
                lowerBound: -2
                applyUpperBound: true
                upperBound: 2
                selected: _private.currentElement === 2
                onValueChanged: if (component.cppClipObject) { component.cppClipObject.grainPitchMinimum1 = value }
                Connections {
                    target: component.cppClipObject
                    onGrainPitchMinimum1Changed: grainPitchMinimum1Slider.value = component.cppClipObject.grainPitchMinimum1
                }
            }
            Zynthian.InfinitySlider {
                id: grainPitchMaximum1Slider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Max 1")
                value: component.cppClipObject ? component.cppClipObject.grainPitchMaximum1 : 0
                applyLowerBound: true
                lowerBound: -2
                applyUpperBound: true
                upperBound: 2
                selected: _private.currentElement === 3
                onValueChanged: if (component.cppClipObject) { component.cppClipObject.grainPitchMaximum1 = value }
                Connections {
                    target: component.cppClipObject
                    onGrainPitchMaximum1Changed: grainPitchMaximum1Slider.value = component.cppClipObject.grainPitchMaximum1
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Kirigami.Heading {
                    level: 2
                    text: qsTr("%1% ▶").arg(Math.round(component.cppClipObject ? 100 - (100 * component.cppClipObject.grainPitchPriority) : 0))
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
                QQC2.Slider {
                    id: grainPitchPrioritySlider
                    implicitWidth: 1
                    implicitHeight: 1
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: Qt.Vertical
                    stepSize: 0.01
                    value: component.cppClipObject ? component.cppClipObject.grainPitchPriority : 0
                    from: 0
                    to: 1
                    onMoved: component.cppClipObject.grainPitchPriority = value
                }
                Kirigami.Heading {
                    level: 2
                    text: qsTr("◀ %1%").arg(Math.round(component.cppClipObject ? 100 * component.cppClipObject.grainPitchPriority : 0))
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 2
                    Layout.maximumHeight: 2
                    color: _private.currentElement === 4 ? Kirigami.Theme.highlightedTextColor : "transparent"
                }
            }
            Zynthian.InfinitySlider {
                id: grainPitchMinimum2Slider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Min 2")
                value: component.cppClipObject ? component.cppClipObject.grainPitchMinimum2 : 0
                applyLowerBound: true
                lowerBound: -2
                applyUpperBound: true
                upperBound: 2
                selected: _private.currentElement === 5
                onValueChanged: if (component.cppClipObject) { component.cppClipObject.grainPitchMinimum2 = value }
                Connections {
                    target: component.cppClipObject
                    onGrainPitchMinimum2Changed: grainPitchMinimum2Slider.value = component.cppClipObject.grainPitchMinimum2
                }
            }
            Zynthian.InfinitySlider {
                id: grainPitchMaximum2Slider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Max 2")
                value: component.cppClipObject ? component.cppClipObject.grainPitchMaximum2 : 0
                applyLowerBound: true
                lowerBound: -2
                applyUpperBound: true
                upperBound: 2
                selected: _private.currentElement === 6
                onValueChanged: if (component.cppClipObject) { component.cppClipObject.grainPitchMaximum2 = value }
                Connections {
                    target: component.cppClipObject
                    onGrainPitchMaximum2Changed: grainPitchMaximum2Slider.value = component.cppClipObject.grainPitchMaximum2
                }
            }
        }
    }
}
