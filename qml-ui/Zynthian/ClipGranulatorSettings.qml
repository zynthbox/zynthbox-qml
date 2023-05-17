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

import Zynthian 1.0 as Zynthian

Item {
    id: component
    property QtObject clip
    signal saveMetadata()
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
        switch(_private.currentElement) {
            case 0:
                component.clip.granular = true;
                break;
            case 1:
            case 2:
            case 3:
                break;
            case 4:
                component.clip.grainInterval = component.clip.grainInterval + 1;
                break;
            case 5:
                component.clip.grainIntervalAdditional = component.clip.grainIntervalAdditional + 1;
                break;
            case 6:
                component.clip.grainSize = component.clip.grainSize + 1;
                break;
            case 7:
                component.clip.grainSizeAdditional = component.clip.grainSizeAdditional + 1;
                break;
            case 8:
                component.clip.grainPanMinimum = Math.min(1, component.clip.grainPanMinimum + 0.01);
                break;
            case 9:
                component.clip.grainPanMaximum = Math.min(1, component.clip.grainPanMaximum + 0.01);
                break;
            default:
                break;
        }
    }
    function decreaseCurrentValue() {
        switch(_private.currentElement) {
            case 0:
                component.clip.granular = false;
                break;
            case 1:
            case 2:
            case 3:
                break;
            case 4:
                component.clip.grainInterval = Math.max(1, component.clip.grainInterval - 1);
                break;
            case 5:
                component.clip.grainIntervalAdditional = Math.max(0, component.clip.grainIntervalAdditional - 1);
                break;
            case 6:
                component.clip.grainSize = Math.max(1, component.clip.grainSize - 1);
                break;
            case 7:
                component.clip.grainSizeAdditional = Math.max(0, component.clip.grainSizeAdditional - 1);
                break;
            case 8:
                component.clip.grainPanMinimum = Math.max(-1, component.clip.grainPanMinimum - 0.01);
                break;
            case 9:
                component.clip.grainPanMaximum = Math.max(-1, component.clip.grainPanMaximum - 0.01);
                break;
            default:
                break;
        }
    }
    QtObject {
        id: _private
        property int currentElement: 0
        property int elementMax: 9
    }
    RowLayout {
        anchors.fill: parent
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.3
            Kirigami.Heading {
                level: 2
                text: qsTr("Enable")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                MouseArea {
                    anchors.fill: parent
                    onClicked: component.clip.granular = !component.clip.granular
                }
                QQC2.Switch {
                    id: granularEnabledSwitch
                    anchors.centerIn: parent
                    width: Math.min(Math.round(parent.width / 4 * 3), Kirigami.Units.gridUnit * 5)
                    height: Kirigami.Units.gridUnit * 3
                    checked: component.clip.granular
                    onToggled: component.clip.granular = !component.clip.granular
                    Connections {
                        target: component.clip
                        onGranularChanged: granularEnabledSwitch.checked = component.clip.granular
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
            Layout.preferredWidth: Kirigami.Units.gridUnit
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
                // value: component.clip ? component.clip.adsrAttack : 0
                from: 0
                to: 1
                // onMoved: component.clip.adsrAttack = value
            }
            Kirigami.Heading {
                level: 2
                text: (component.clip ? component.clip.adsrAttack : 0).toFixed(3)
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
            Layout.preferredWidth: Kirigami.Units.gridUnit
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
                // value: component.clip ? component.clip.adsrAttack : 0
                from: 0
                to: 1
                // onMoved: component.clip.adsrAttack = value
            }
            Kirigami.Heading {
                level: 2
                text: (component.clip ? component.clip.adsrAttack : 0).toFixed(3)
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
            Kirigami.Heading {
                level: 2
                text: qsTr("Scan")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            QQC2.Slider {
                id: grainScanSlider
                implicitWidth: 1
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Vertical
                stepSize: 1
                // value: component.clip ? component.clip.adsrAttack : 0
                from: 0
                to: 1000
                // onMoved: component.clip.adsrAttack = value
            }
            Kirigami.Heading {
                level: 2
                text: qsTr("%1\nsmp/ms").arg((component.clip ? component.clip.adsrAttack : 0).toFixed(0))
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 2
                Layout.maximumHeight: 2
                color: _private.currentElement === 3 ? Kirigami.Theme.highlightedTextColor : "transparent"
            }
        }
        GridLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.smallSpacing
            columns: 2
            Kirigami.Heading {
                Layout.columnSpan: 2
                level: 2
                text: qsTr("Interval")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Zynthian.InfinitySlider {
                id: grainIntervalSlider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Min")
                value: component.clip.grainInterval
                unitLabel: qsTr("ms")
                decimals: 0
                increment: 1
                slideIncrement: 1
                applyLowerBound: true
                lowerBound: 1
                selected: _private.currentElement === 4
                Connections {
                    target: component.clip
                    onGrainIntervalChanged: grainIntervalSlider.value = component.clip.grainInterval
                }
            }
            Zynthian.InfinitySlider {
                id: grainIntervalAdditionalSlider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("More")
                value: component.clip.grainIntervalAdditional
                unitLabel: qsTr("ms")
                decimals: 0
                increment: 1
                slideIncrement: 1
                applyLowerBound: true
                lowerBound: 0
                selected: _private.currentElement === 5
                Connections {
                    target: component.clip
                    onGrainIntervalAdditionalChanged: grainIntervalAdditionalSlider.value = component.clip.grainIntervalAdditional
                }
            }
        }
        GridLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.smallSpacing
            columns: 2
            Kirigami.Heading {
                Layout.columnSpan: 2
                level: 2
                text: qsTr("Size")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Zynthian.InfinitySlider {
                id: grainSizeSlider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Min")
                value: component.clip.grainSize
                unitLabel: qsTr("ms")
                decimals: 0
                increment: 1
                slideIncrement: 1
                applyLowerBound: true
                lowerBound: 1
                selected: _private.currentElement === 6
                Connections {
                    target: component.clip
                    onGrainSizeChanged: grainSizeSlider.value = component.clip.grainSize
                }
            }
            Zynthian.InfinitySlider {
                id: grainSizeAdditionalSlider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("More")
                value: component.clip.grainSizeAdditional
                unitLabel: qsTr("ms")
                decimals: 0
                increment: 1
                slideIncrement: 1
                applyLowerBound: true
                lowerBound: 0
                selected: _private.currentElement === 7
                Connections {
                    target: component.clip
                    onGrainSizeAdditionalChanged: grainSizeAdditionalSlider.value = component.clip.grainSizeAdditional
                }
            }
        }
        GridLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.smallSpacing
            columns: 2
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
                value: component.clip.grainPanMinimum
                applyLowerBound: true
                lowerBound: -1
                applyUpperBound: true
                upperBound: 1
                selected: _private.currentElement === 8
                Connections {
                    target: component.clip
                    onGrainPanMinimumChanged: grainPanMinimumSlider.value = component.clip.grainPanMinimum
                }
            }
            Zynthian.InfinitySlider {
                id: grainPanMaximumSlider
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Max")
                value: component.clip.grainPanMaximum
                applyLowerBound: true
                lowerBound: -1
                applyUpperBound: true
                upperBound: 1
                selected: _private.currentElement === 9
                Connections {
                    target: component.clip
                    onGrainPanMaximumChanged: grainPanMaximumSlider.value = component.clip.grainPanMaximum
                }
            }
        }
    }
}
