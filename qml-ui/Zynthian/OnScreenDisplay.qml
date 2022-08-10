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
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian

QQC2.Popup {
    id: component
    exit: null; enter: null; // Disable the enter and exit transition animations. TODO This really wants doing somewhere central...
    modal: true
    parent: QQC2.Overlay.overlay
    x: Math.round(parent.width/2 - width/2)
    y: Kirigami.Units.largeSpacing
    Timer {
        id: hideTimer
        running: false; repeat: false; interval: 3000;
        onTriggered: {
            if (component.opened) {
                component.close();
            }
        }
    }
    Connections {
        target: zynthian.osd
        onUpdate: {
            hideTimer.restart();
            component.open();
        }
    }

    readonly property bool invertedScale: zynthian.osd.start > zynthian.osd.stop
    Item {
        implicitWidth: Kirigami.Units.gridUnit * 10
        implicitHeight: Kirigami.Units.gridUnit * 5
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        MouseArea {
            anchors.fill: parent
            onPressed: hideTimer.stop();
            onReleased: hideTimer.start();
        }
        ColumnLayout {
            anchors.fill: parent
            QQC2.Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: zynthian.osd.description
            }
            RowLayout {
                Layout.fillWidth: true
                QQC2.Button {
                    icon.name: "arrow-left"
                    onPressed: hideTimer.stop();
                    onReleased: hideTimer.start();
                    enabled: component.invertedScale ? zynthian.osd.value < zynthian.osd.start : zynthian.osd.value > zynthian.osd.start
                    onClicked: {
                        zynthian.osd.setValue(zynthian.osd.name,  component.invertedScale ? zynthian.osd.value + zynthian.osd.step : zynthian.osd.value - zynthian.osd.step);
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label {
                            text: zynthian.osd.start
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        QQC2.Label {
                            text: (zynthian.osd.value + "").substring(0, (zynthian.osd.value < 0 ? 5 : 4))
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        QQC2.Label {
                            text: zynthian.osd.stop
                        }
                    }
                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        from: zynthian.osd.start
                        to: zynthian.osd.stop
                        value: zynthian.osd.value
                    }
                }
                QQC2.Button {
                    icon.name: "arrow-right"
                    onPressed: hideTimer.stop();
                    onReleased: hideTimer.start();
                    enabled: component.invertedScale ? zynthian.osd.value > zynthian.osd.stop : zynthian.osd.value < zynthian.osd.stop
                    onClicked: {
                        zynthian.osd.setValue(zynthian.osd.name, component.invertedScale ? zynthian.osd.value - zynthian.osd.step : zynthian.osd.value + zynthian.osd.step);
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Item {
                    Layout.fillWidth: true
                }
                QQC2.Button {
                    text: qsTr("Reset to default")
                    onPressed: hideTimer.stop();
                    onReleased: hideTimer.start();
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
