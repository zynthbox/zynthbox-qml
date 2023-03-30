/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian recording popup

Copyright (C) 2022 Anupam Basak <anupam.basak27@gmail.com>

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
import QtQuick.Controls.Styles 1.4

import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami


import libzl 1.0 as ZL
import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

Zynthian.Popup {
    id: root
    property QtObject selectedChannel: zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.session_dashboard.selectedChannel)
    property var cuiaCallback: function(cuia) {
        var returnValue = false;
        switch (cuia) {
            case "NAVIGATE_LEFT":
                returnValue = true
                break

            case "NAVIGATE_RIGHT":
                returnValue = true
                break

            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                root.close();
                returnValue = true;
                break;
        }

        return returnValue;
    }

    parent: QQC2.Overlay.overlay
    y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
    x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
    closePolicy: !zynqtgui.sketchpad.isRecording ? (QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside) : QQC2.Popup.NoAutoClose
    width: parent.width * 0.95
    height: parent.height * 0.95
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    onSelectedChannelChanged: {
        console.log("Recording popup selectedChannelChanged handler")

        if (root.selectedChannel.channelAudioType === "external") {
            zynqtgui.sketchpad.recordingSource = "external"
            zynqtgui.sketchpad.recordingChannel = "*"
        } else {
            zynqtgui.sketchpad.recordingSource = "internal"
        }

        // Reset source combo model to selected value when channel changes
        for (var i=0; i<sourceComboModel.count; i++) {
            if (sourceComboModel.get(i).value === zynqtgui.sketchpad.recordingSource) {
                sourceCombo.currentIndex = i
                break
            }
        }

        for (var i=0; i<recordingChannelComboModel.count; i++) {
            if (recordingChannelComboModel.get(i).value === zynqtgui.sketchpad.recordingChannel) {
                recordingChannelCombo.currentIndex = i
                break
            }
        }

        console.log(zynqtgui.sketchpad.recordingSource, zynqtgui.sketchpad.recordingChannel, sourceCombo.currentIndex, recordingChannelCombo.currentIndex)
    }
    onOpened: {
        zynqtgui.recordingPopupActive = true

        // Reset recordingType combo model to selected value when dialog opens
        for (var i=0; i<recordingTypeComboModel.count; i++) {
            if (recordingTypeComboModel.get(i).value === zynqtgui.sketchpad.recordingType) {
                recordingTypeCombo.currentIndex = i
                break
            }
        }

        // Reset countIn combo model to selected value when dialog opens
        for (var i=0; i<countInComboModel.count; i++) {
            if (countInComboModel.get(i).value === zynqtgui.sketchpad.countInBars) {
                countInCombo.currentIndex = i
                break
            }
        }
    }
    onClosed: {
        zynqtgui.recordingPopupActive = false
    }
    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing

        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.fillHeight: false
            text: qsTr("Record Channel %1 - Clip %2").arg(selectedChannel.name).arg(selectedChannel.selectedSlotRow + 1)
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.minimumHeight: 1
            Layout.maximumHeight: 1
            color: Kirigami.Theme.textColor
            opacity: 0.5
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                enabled: !zynqtgui.sketchpad.isRecording
                spacing: Kirigami.Units.gridUnit/2

                RowLayout {
                    Layout.fillWidth: false

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Recording Type")
                    }

                    Zynthian.ComboBox {
                        id: recordingTypeCombo

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: recordingTypeComboModel

                            ListElement { text: "Audio"; value: "audio" }
                            ListElement { text: "Midi"; value: "midi" }
                        }
                        textRole: "text"
                        onActivated: {
                            zynqtgui.sketchpad.recordingType = recordingTypeComboModel.get(index).value
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    visible: zynqtgui.sketchpad.recordingType === "audio"

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Audio Source")
                    }

                    Zynthian.ComboBox {
                        id: sourceCombo

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: sourceComboModel

                            ListElement { text: "Internal (Active Layer)"; value: "internal" }
                            ListElement { text: "External (Audio In)"; value: "external" }
                        }
                        textRole: "text"
                        onActivated: {
                            zynqtgui.sketchpad.recordingSource = sourceComboModel.get(index).value
                        }
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Solo")
                    }

                    QQC2.Switch {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: Kirigami.Units.gridUnit * 4
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        checked: zynqtgui.sketchpad.recordSolo
                        onToggled: {
                            zynqtgui.sketchpad.recordSolo = checked
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    visible: zynqtgui.sketchpad.recordingType === "audio" && // Visible when recordingType is audio
                             zynqtgui.sketchpad.recordingSource === "internal" // and when source is internal

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        Layout.alignment: Qt.AlignCenter
                        enabled: parent.enabled
                        text: qsTr("Source Channel")
                    }

                    Zynthian.ComboBox {
                        id: channelCombo

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: channelComboModel

                            ListElement { text: "Channel 1"; value: 0 }
                            ListElement { text: "Channel 2"; value: 1 }
                            ListElement { text: "Channel 3"; value: 2 }
                            ListElement { text: "Channel 4"; value: 3 }
                            ListElement { text: "Channel 5"; value: 4 }
                            ListElement { text: "Channel 6"; value: 5 }
                            ListElement { text: "Channel 7"; value: 6 }
                            ListElement { text: "Channel 8"; value: 7 }
                            ListElement { text: "Channel 9"; value: 8 }
                            ListElement { text: "Channel 10"; value: 9 }
                        }
                        textRole: "text"
                        currentIndex: visible ? zynqtgui.session_dashboard.selectedChannel : -1
                        onActivated: {
                            zynqtgui.session_dashboard.selectedChannel = channelComboModel.get(index).value
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    visible: zynqtgui.sketchpad.recordingType === "audio" && // Visible when recordingType is audio
                             zynqtgui.sketchpad.recordingSource === "external" // and when source is external

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Channel")
                    }

                    Zynthian.ComboBox {
                        id: recordingChannelCombo

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: recordingChannelComboModel

                            ListElement { text: "Left Channel"; value: "1" }
                            ListElement { text: "Right Channel"; value: "2" }
                            ListElement { text: "Stereo"; value: "*" }
                        }
                        textRole: "text"
                        onActivated: {
                            zynqtgui.sketchpad.recordingChannel = recordingChannelComboModel.get(index).value
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Count In (Bars)")
                    }

                    Zynthian.ComboBox {
                        id: countInCombo

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: countInComboModel

                            ListElement { text: "Off"; value: 0 }
                            ListElement { text: "1"; value: 1 }
                            ListElement { text: "2"; value: 2 }
                            ListElement { text: "4"; value: 4 }
                        }
                        textRole: "text"
                        onActivated: zynqtgui.sketchpad.countInBars = countInComboModel.get(index).value
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Record Master Output")
                    }

                    QQC2.Switch {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: Kirigami.Units.gridUnit * 4
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        checked: zynqtgui.sketchpad.recordMasterOutput
                        onToggled: {
                            zynqtgui.sketchpad.recordMasterOutput = checked
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Metronome")
                    }

                    QQC2.Switch {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: Kirigami.Units.gridUnit * 4
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        checked: zynqtgui.sketchpad.clickChannelEnabled
                        onToggled: {
                            zynqtgui.sketchpad.clickChannelEnabled = checked
                        }
                    }
                }

                // Fill up remaining space so that the above items do not center themselves vertically in parent
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: false
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                        spacing: Kirigami.Units.gridUnit * 2

                        ColumnLayout {
                            Extras.Gauge {
                                Layout.fillHeight: true
                                Layout.leftMargin: -10 // Magic number to align valuebar corectly with bottom text. TODO : Find a proper way to vertically center valuebar in gauge
                                minimumValue: -100
                                maximumValue: 20
                                font.pointSize: 8
                                value: visible
                                       ? zynqtgui.sketchpad.recordingSource === "internal"
                                          ? ZL.AudioLevels.channels[root.selectedChannel.id]
                                          : ZL.AudioLevels.captureA
                                       : -100
                                style: GaugeStyle {
                                    valueBar: Rectangle {
                                        color: Qt.lighter(Kirigami.Theme.highlightColor, 1.6)
                                        implicitWidth: 6
                                    }
                                    minorTickmark: null
                                    tickmark: null
                                    tickmarkLabel: null
                                }
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                horizontalAlignment: QQC2.Label.AlignHCenter
                                text: qsTr("L")
                            }
                        }

                        ColumnLayout {
                            Extras.Gauge {
                                Layout.fillHeight: true
                                Layout.leftMargin: -10 // Magic number to align valuebar corectly with bottom text. TODO : Find a proper way to vertically center valuebar in gauge
                                minimumValue: -100
                                maximumValue: 20
                                font.pointSize: 8
                                value: visible
                                        ? zynqtgui.sketchpad.recordingSource === "internal"
                                           ? ZL.AudioLevels.channels[root.selectedChannel.id]
                                           : ZL.AudioLevels.captureB
                                        : -100
                                style: GaugeStyle {
                                    valueBar: Rectangle {
                                        color: Qt.lighter(Kirigami.Theme.highlightColor, 1.6)
                                        implicitWidth: 6
                                    }
                                    minorTickmark: null
                                    tickmark: null
                                    tickmarkLabel: null
                                }
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                horizontalAlignment: QQC2.Label.AlignHCenter
                                text: qsTr("R")
                            }
                        }
                    }
                }

                QQC2.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Audio Level"
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: false
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8

                QQC2.Button {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 6
                    Layout.alignment: Qt.AlignCenter

                    icon.name: zynqtgui.sketchpad.isRecording ? "media-playback-stop" : "media-record-symbolic"

                    onClicked: {
                        zynqtgui.callable_ui_action("START_RECORD")
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5

            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("Close")
                onClicked: {
                    root.close()
                }
            }
        }
    }
}
