/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

Copyright (C) 2021 Marco Martin <mart@kde.org>

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
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import "../Zynthian/private" as ZynthianPrivate

Zynthian.ScreenPage {
    id: root
    title: qsTr("UI Settings")
    screenId: "ui_settings"
    contextualActions: [
    ]
    contentItem: ColumnLayout {
        anchors.margins: Kirigami.Units.largeSpacing
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false

            QQC2.Label {
                Layout.fillWidth: false
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                text: qsTr("Double Click Threshold Amount")
            }
            QQC2.Slider {
                id: doubleClickThresholdSlider
                Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                from: 0
                to: 500
                stepSize: 1
                value: zynqtgui.ui_settings.doubleClickThreshold
                onPressedChanged: {
                    // Set the value on release to save the value only when needed
                    if (!pressed) {
                        zynqtgui.ui_settings.doubleClickThreshold = value
                    }
                }
            }
            Rectangle {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                color: Kirigami.Theme.backgroundColor
                border.color: "#ff999999"
                border.width: 2
                radius: 4

                QQC2.Label {
                    anchors.centerIn: parent
                    text: qsTr("%1 ms").arg(doubleClickThresholdSlider.value)
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false

            QQC2.Label {
                Layout.fillWidth: false
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                text: qsTr("Hardware Sequencer Interaction")
            }
            QQC2.Switch {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                checked: zynqtgui.ui_settings.hardwareSequencer
                onClicked: {
                    zynqtgui.ui_settings.hardwareSequencer = checked;
                }
            }
            Rectangle {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                color: Kirigami.Theme.backgroundColor
                border.color: "#ff999999"
                border.width: 2
                radius: 4

                QQC2.Label {
                    anchors.centerIn: parent
                    text: zynqtgui.ui_settings.hardwareSequencer ? qsTr("Enabled") : qsTr("Disabled")
                }
            }
        }        
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false

            QQC2.Label {
                Layout.fillWidth: false
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                text: qsTr("Display Debug Labels")
            }
            QQC2.Switch {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                checked: zynqtgui.ui_settings.displayDebugLabels
                onClicked: {
                    zynqtgui.ui_settings.displayDebugLabels = checked;
                }
            }
            Rectangle {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                color: Kirigami.Theme.backgroundColor
                border.color: "#ff999999"
                border.width: 2
                radius: 4

                QQC2.Label {
                    anchors.centerIn: parent
                    text: zynqtgui.ui_settings.displayDebugLabels ? qsTr("Enabled") : qsTr("Disabled")
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
