/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

On Screen Display component, used by the main zynthbox UI

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

import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.4 as QQC2
import QtQuick.Window 2.1
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian

QQC2.Popup {
    id: component
    exit: null; enter: null; // Disable the enter and exit transition animations. TODO This really wants doing somewhere central...
    modal: true
    parent: QQC2.Overlay.overlay
    x: Math.round(parent.width/2 - width/2)
    y: Math.round(parent.height/2 - height/2)
    Timer {
        id: hideTimer
        running: false; repeat: false; interval: 1500;
        onTriggered: {
            if (component.opened) {
                component.close();
            }
        }
        property bool isHeld: false;
        function pressed() {
            isHeld = true;
            stop();
        }
        function released() {
            restart();
            isHeld = false;
        }
    }
    Connections {
        target: zynthian.osd
        onUpdate: {
            if (!hideTimer.isHeld) {
                hideTimer.restart();
            }
            component.open();
        }
    }

    readonly property bool invertedScale: zynthian.osd.start > zynthian.osd.stop
    Item {
        implicitWidth: Kirigami.Units.gridUnit * 20
        implicitHeight: Kirigami.Units.gridUnit * 10
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        MouseArea {
            anchors.fill: parent
            onPressed: hideTimer.pressed();
            onReleased: hideTimer.released();
        }
        ColumnLayout {
            anchors.fill: parent
            QQC2.Label {
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: zynthian.osd.description
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                        Item {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        }
                        QQC2.Label {
                            text: zynthian.osd.startLabel === "" ? zynthian.osd.start : zynthian.osd.startLabel
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        QQC2.Label {
                            visible: zynthian.osd.showValueLabel
                            text: zynthian.osd.valueLabel
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        QQC2.Label {
                            text: zynthian.osd.stopLabel === "" ? zynthian.osd.stop : zynthian.osd.stopLabel
                        }
                        Item {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        QQC2.ToolButton {
                            Layout.fillHeight: true
                            icon.name: "arrow-left"
                            onPressed: hideTimer.pressed();
                            onReleased: hideTimer.released();
                            enabled: component.invertedScale ? zynthian.osd.value < zynthian.osd.start : zynthian.osd.value > zynthian.osd.start
                            onClicked: {
                                zynthian.osd.setValue(zynthian.osd.name, component.invertedScale ? zynthian.osd.value + zynthian.osd.step : zynthian.osd.value - zynthian.osd.step);
                            }
                        }
                        Item {
                            id: sliderItem
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                            MultiPointTouchArea {
                                anchors {
                                    fill: parent
                                    topMargin: -sliderItem.height // Let's allow for some sloppy interaction here, why not
                                }
                                touchPoints: [
                                    TouchPoint {
                                        id: slidePoint;
                                        property var currentValue: undefined
                                        onPressedChanged: {
                                            if (pressed) {
                                                currentValue = zynthian.osd.value;
                                                hideTimer.pressed();
                                            } else {
                                                currentValue = undefined;
                                                hideTimer.released();
                                            }
                                        }
                                        onXChanged: {
                                            if (pressed && currentValue !== undefined) {
                                                var delta = (zynthian.osd.stop - zynthian.osd.start) * ((slidePoint.x - slidePoint.startX) / sliderItem.width);
                                                if (component.invertedScale) {
                                                    zynthian.osd.setValue(zynthian.osd.name, Math.min(Math.max(currentValue + delta, zynthian.osd.stop), zynthian.osd.start));
                                                } else {
                                                    zynthian.osd.setValue(zynthian.osd.name, Math.min(Math.max(currentValue + delta, zynthian.osd.start), zynthian.osd.stop));
                                                }
                                            }
                                        }
                                    }
                                ]
                            }
                            Rectangle {
                                anchors.fill: parent
                                color: Kirigami.Theme.backgroundColor
                                border {
                                    width: 2
                                    color: Kirigami.Theme.textColor
                                }
                                radius: height / 2
                            }
                            Item {
                                id: barContainer
                                anchors {
                                    fill: parent
                                    margins: 4
                                    leftMargin: (height / 2) + 4
                                    rightMargin: (height / 2) + 3 // This is uneven, but otherwise the visual ends up weird
                                }
                                property double zeroOffset: (zynthian.osd.visualZero - zynthian.osd.start) / (zynthian.osd.stop - zynthian.osd.start)
                                Rectangle {
                                    anchors {
                                        left: parent.left
                                        leftMargin: parent.width * barContainer.zeroOffset
                                        top: parent.top
                                        bottom: parent.bottom
                                    }
                                    color: Kirigami.Theme.textColor
                                    width: (component.invertedScale ? zynthian.osd.value < zynthian.osd.visualZero : zynthian.osd.value > zynthian.osd.visualZero) ? parent.width * ((zynthian.osd.value - zynthian.osd.visualZero) / (zynthian.osd.stop - zynthian.osd.start)) : 0
                                    Rectangle {
                                        anchors {
                                            top: parent.top
                                            bottom: parent.bottom
                                            horizontalCenter: parent.right
                                        }
                                        radius: (height - 1)  / 2
                                        width: height
                                        color: parent.color
                                    }
                                }
                                Rectangle {
                                    anchors {
                                        left: parent.left
                                        leftMargin: parent.width * barContainer.zeroOffset
                                        top: parent.top
                                        bottom: parent.bottom
                                    }
                                    width: 1
                                    color: Kirigami.Theme.textColor
                                }
                                Rectangle {
                                    anchors {
                                        right: parent.left
                                        rightMargin: -parent.width * barContainer.zeroOffset
                                        top: parent.top
                                        bottom: parent.bottom
                                    }
                                    color: Kirigami.Theme.textColor
                                    width: (component.invertedScale ? zynthian.osd.value > zynthian.osd.visualZero : zynthian.osd.value < zynthian.osd.visualZero) ? (parent.width * barContainer.zeroOffset) - parent.width * ((zynthian.osd.value - zynthian.osd.start) / (zynthian.osd.stop - zynthian.osd.start)) : 0
                                    Rectangle {
                                        anchors {
                                            top: parent.top
                                            bottom: parent.bottom
                                            horizontalCenter: parent.left
                                        }
                                        radius: (height - 1) / 2
                                        width: height
                                        color: parent.color
                                    }
                                }
                            }
                            Item {
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    bottomMargin: -5
                                    left: parent.left
                                    leftMargin: (parent.width * ((zynthian.osd.defaultValue - zynthian.osd.start) / (zynthian.osd.stop - zynthian.osd.start))) - 3
                                }
                                visible: zynthian.osd.showVisualZero
                                width: 5
                                clip: true
                                Rectangle {
                                    anchors {
                                        verticalCenter: parent.bottom
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                    height: 3
                                    width: 3
                                    rotation: 45
                                    color: Kirigami.Theme.textColor
                                }
                            }
                        }
                        QQC2.ToolButton {
                            Layout.fillHeight: true
                            icon.name: "arrow-right"
                            onPressed: hideTimer.pressed();
                            onReleased: hideTimer.released();
                            enabled: component.invertedScale ? zynthian.osd.value > zynthian.osd.stop : zynthian.osd.value < zynthian.osd.stop
                            onClicked: {
                                zynthian.osd.setValue(zynthian.osd.name, component.invertedScale ? zynthian.osd.value - zynthian.osd.step : zynthian.osd.value + zynthian.osd.step);
                            }
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                Item {
                    Layout.fillWidth: true
                }
                QQC2.Button {
                    visible: zynthian.osd.showResetToDefault
                    text: qsTr("Reset to default")
                    onPressed: hideTimer.pressed();
                    onReleased: hideTimer.released();
                    enabled: zynthian.osd.value !== zynthian.osd.defaultValue
                    onClicked: {
                        zynthian.osd.setValue(zynthian.osd.name, zynthian.osd.defaultValue);
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
