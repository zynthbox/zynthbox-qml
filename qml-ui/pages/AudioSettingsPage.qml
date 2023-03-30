/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI
A Page for displaying capture ports and its audio levels

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>

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
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import "Sketchpad" as Sketchpad

Zynthian.ScreenPage {
    id: root
    title: qsTr("Audio Settings")
    screenId: "audio_settings"

    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        radius: 2

        ColumnLayout {
            anchors.fill: parent
            QQC2.Label {
                Layout.topMargin: Kirigami.Units.gridUnit
                Layout.leftMargin: Kirigami.Units.gridUnit
                font.pointSize: 20
                text: root.title
            }

            RowLayout {
                Layout.leftMargin: Kirigami.Units.gridUnit*2
                Layout.bottomMargin: Kirigami.Units.gridUnit
                Layout.preferredHeight: Kirigami.Units.gridUnit*2.5

                QQC2.Label {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit*8
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
                    Layout.leftMargin: Kirigami.Units.gridUnit
                    horizontalAlignment: TextInput.AlignLeft
                    text: "Card Name"
                }

                QQC2.TextField {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit*12
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
                    horizontalAlignment: TextInput.AlignHCenter
                    readOnly: true
                    text: zynqtgui.audio_settings.soundcardName
                }
            }

            QQC2.Label {
                Layout.leftMargin: Kirigami.Units.gridUnit
                font.pointSize: 16
                text: qsTr("Channels")
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 16
                Repeater {
                    model: zynqtgui.audio_settings.channels
                    delegate: ColumnLayout {
                        Sketchpad.VolumeControl {
                            id: volumeDelegate
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 16
                            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
                            Layout.bottomMargin: 5
                            footerText: modelData.name
                            audioLeveldB: -200
                            inputAudioLevelVisible: false

                            slider {
                                value: modelData.value
                                from: modelData.value_min
                                to: modelData.value_max
                                stepSize: 1
                            }
                            onValueChanged: {
                                zynqtgui.audio_settings.setChannelValue(modelData.name, volumeDelegate.slider.value);
                            }
                        }
                    }
                }
            }
        }
    }
}
