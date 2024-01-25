/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian recording popup

Copyright (C) 2024 Anupam Basak <anupam.basak27@gmail.com>

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

import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami


import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian

Zynthian.Popup {
    id: root
    property QtObject selectedChannel: null
    spacing: Kirigami.Units.gridUnit * 0.5

    Timer {
        id: selectedChannelThrottle
        interval: 1; running: false; repeat: false;
        onTriggered: {
            root.selectedChannel = zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.session_dashboard.selectedChannel)
        }
    }
    Connections {
        target: zynqtgui.session_dashboard
        onSelected_channel_changed: selectedChannelThrottle.restart()
    }
    property var cuiaCallback: function(cuia) {
        var returnValue = false;
        switch (cuia) {
            case "CHANNEL_1":
            case "CHANNEL_2":
            case "CHANNEL_3":
            case "CHANNEL_4":
            case "CHANNEL_5":
            case "NAVIGATE_LEFT":
            case "NAVIGATE_RIGHT":
            case "SELECT_UP":
            case "SELECT_DOWN":
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
            case "SWITCH_SELECT_LONG":
            case "MODE_SWITCH_SHORT":
            case "MODE_SWITCH_BOLD":
            case "MODE_SWITCH_LONG":
            case "KNOB0_UP":
            case "KNOB0_DOWN":
            case "KNOB0_TOUCHED":
            case "KNOB0_RELEASED":
            case "KNOB1_UP":
            case "KNOB1_DOWN":
            case "KNOB1_TOUCHED":
            case "KNOB1_RELEASED":
            case "KNOB2_UP":
            case "KNOB2_DOWN":
            case "KNOB2_TOUCHED":
            case "KNOB2_RELEASED":
            case "KNOB3_UP":
            case "KNOB3_DOWN":
            case "KNOB3_TOUCHED":
            case "KNOB3_RELEASED":
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
    closePolicy: zynqtgui.sketchpad.isRecording ? QQC2.Popup.NoAutoClose : (QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside)
    width: parent.width * 0.99
    height: parent.height * 0.97
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    onSelectedChannelChanged: {
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
    }
    onOpened: {
        zynqtgui.recordingPopupActive = true

        // Set selectedChannel if not already set
        if (root.selectedChannel == null) {
            selectedChannelThrottle.restart()
        }
    }
    onClosed: {
        zynqtgui.recordingPopupActive = false
    }
    contentItem: ColumnLayout {
        anchors.fill: parent
        spacing: root.spacing

        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.leftMargin: root.spacing
            Layout.topMargin: root.spacing
            text: root.selectedChannel ? qsTr("Record Channel %1 - Clip %2").arg(root.selectedChannel.name).arg(root.selectedChannel.selectedSlotRow + 1) : ""
        }
        Kirigami.Separator {
            Layout.fillWidth: true
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: root.spacing

                GridLayout { // Common Settings Section
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 6
                    Layout.maximumHeight: Layout.preferredHeight

                    Zynthian.Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentItem: ColumnLayout {
                            QQC2.Switch {
                                Layout.fillHeight: true
                                Layout.alignment: Qt.AlignCenter
                                // Explicitly set indicator implicitWidth otherwise the switch size is too small
                                indicator.implicitWidth: Kirigami.Units.gridUnit * 3
                                checked: zynqtgui.sketchpad.metronomeEnabled
                                onToggled: {
                                    zynqtgui.sketchpad.metronomeEnabled = checked
                                }
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignBottom
                                wrapMode: QQC2.Label.WordWrap
                                horizontalAlignment: QQC2.Label.AlignHCenter
                                text: "Metronome"
                            }
                        }
                    }
                    Zynthian.Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentItem: ColumnLayout {
                            QQC2.Switch {
                                Layout.fillHeight: true
                                Layout.alignment: Qt.AlignCenter
                                // Explicitly set indicator implicitWidth otherwise the switch size is too small
                                indicator.implicitWidth: Kirigami.Units.gridUnit * 3
                                checked: zynqtgui.sketchpad.recordSolo
                                onToggled: {
                                    zynqtgui.sketchpad.recordSolo = checked
                                }
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignBottom
                                wrapMode: QQC2.Label.WordWrap
                                horizontalAlignment: QQC2.Label.AlignHCenter
                                text: "Solo"
                            }
                        }
                    }
                    Zynthian.Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentItem: ColumnLayout {
                            RowLayout {
                                id: countIn
                                property int from: 0
                                property int to: 4
                                property int value: zynqtgui.sketchpad.countInBars

                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignCenter
                                onValueChanged: {
                                    zynqtgui.sketchpad.countInBars = countIn.value
                                }

                                QQC2.Button {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                                    Layout.preferredHeight: width
                                    icon.name: "list-remove-symbolic"
                                    enabled: countIn.value > countIn.from
                                    onClicked: {
                                        countIn.value = Zynthian.CommonUtils.clamp(countIn.value-1, countIn.from, countIn.to)
                                    }
                                }
                                Rectangle {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                    Kirigami.Theme.inherit: false
                                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                    color: Kirigami.Theme.backgroundColor
                                    border.color: "#ff999999"
                                    border.width: 1
                                    radius: 4

                                    QQC2.Label {
                                        anchors.centerIn: parent
                                        text: countIn.value == 0 ? qsTr("Off") : qsTr("%1 Bar(s)").arg(countIn.value)
                                    }
                                }
                                QQC2.Button {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                                    Layout.preferredHeight: width
                                    icon.name: "list-add-symbolic"
                                    enabled: countIn.value < countIn.to
                                    onClicked: {
                                        countIn.value = Zynthian.CommonUtils.clamp(countIn.value+1, countIn.from, countIn.to)
                                    }
                                }
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignBottom
                                wrapMode: QQC2.Label.WordWrap
                                horizontalAlignment: QQC2.Label.AlignHCenter
                                text: "Count In (Bars)"
                            }
                        }
                    }
                    Zynthian.Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentItem: ColumnLayout {
                            Zynthian.SketchpadDial {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                text: qsTr("BPM")
                                controlObj: Zynthbox.SyncTimer
                                controlProperty: "bpm"
                                fineTuneButtonsVisible: false
                                dial {
                                    stepSize: 1
                                    from: 50
                                    to: 200
                                }
                            }
                        }
                    }
                }
                ColumnLayout { // Recording Type Specific Settings Section
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: root.spacing

                    RowLayout {
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                            Layout.minimumHeight: Layout.preferredHeight
                            checked: zynqtgui.sketchpad.recordingType === "audio"
                            text: qsTr("Record Audio")
                            onClicked: {
                                zynqtgui.sketchpad.recordingType = "audio"
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                            Layout.minimumHeight: Layout.preferredHeight
                            checked: zynqtgui.sketchpad.recordingType === "midi"
                            text: qsTr("Record Midi")
                            onClicked: {
                                zynqtgui.sketchpad.recordingType = "midi"
                            }
                        }
                    }
                    StackLayout {
                        id: recordingTypeSettingsStack
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: {
                            if (zynqtgui.sketchpad.recordingType === "audio") {
                                return 0
                            } else if (zynqtgui.sketchpad.recordingType === "midi") {
                                return 1
                            } else {
                                return -1
                            }
                        }

                        ColumnLayout {
                            RowLayout {
                                Layout.fillWidth: false

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

                                        ListElement { text: "Track 1"; value: 0 }
                                        ListElement { text: "Track 2"; value: 1 }
                                        ListElement { text: "Track 3"; value: 2 }
                                        ListElement { text: "Track 4"; value: 3 }
                                        ListElement { text: "Track 5"; value: 4 }
                                        ListElement { text: "Track 6"; value: 5 }
                                        ListElement { text: "Track 7"; value: 6 }
                                        ListElement { text: "Track 8"; value: 7 }
                                        ListElement { text: "Track 9"; value: 8 }
                                        ListElement { text: "Track 10"; value: 9 }
                                    }
                                    textRole: "text"
                                    currentIndex: visible ? zynqtgui.session_dashboard.selectedChannel : -1
                                    onActivated: {
                                        zynqtgui.session_dashboard.selectedChannel = channelComboModel.get(index).value
                                    }
                                }

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
                            }
                            RowLayout {
                                QQC2.Label {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                                    Layout.alignment: Qt.AlignCenter
                                    text: qsTr("Track")
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
                        }
                        ColumnLayout {
                            // TODO : Implement midi recording and add midi settings here
                            QQC2.Label {
                                text: "Record Midi"
                            }
                        }
                    }
                }
                RowLayout { // Post Recording Preview section
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                    Layout.maximumHeight: Layout.preferredHeight
                    spacing: root.spacing

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#222222"
                        border.width: 1
                        border.color: "#ff999999"
                        radius: 4

                        Zynthbox.WaveFormItem {
                            anchors.fill: parent
                            color: Kirigami.Theme.textColor
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.largeSpacing
                            spacing: Kirigami.Units.largeSpacing
                            opacity: 0.7

                            Rectangle {
                                property real audioLevel: {
                                    if (root.visible && root.selectedChannel != null) {
                                        if (zynqtgui.sketchpad.recordingSource === "internal") {
                                            return Zynthbox.AudioLevels.channels[root.selectedChannel.id]
                                        } else if (zynqtgui.sketchpad.recordingSource === "internal") {
                                            return Zynthbox.AudioLevels.captureA
                                        } else {
                                            return -100
                                        }
                                    } else {
                                        return -100
                                    }
                                }
                                Layout.preferredWidth: parent.width * Zynthian.CommonUtils.interp(audioLevel, -100, 20, 0, 1)
                                Layout.minimumWidth: Layout.preferredWidth
                                Layout.maximumWidth: Layout.preferredWidth
                                Layout.fillHeight: true
                                color: Kirigami.Theme.highlightColor
                                radius: 100
                            }
                            Rectangle {
                                property real audioLevel: {
                                    if (root.visible && root.selectedChannel != null) {
                                        if (zynqtgui.sketchpad.recordingSource === "internal") {
                                            return Zynthbox.AudioLevels.channels[root.selectedChannel.id]
                                        } else if (zynqtgui.sketchpad.recordingSource === "internal") {
                                            return Zynthbox.AudioLevels.captureB
                                        } else {
                                            return -100
                                        }
                                    } else {
                                        return -100
                                    }
                                }
                                Layout.preferredWidth: parent.width * Zynthian.CommonUtils.interp(audioLevel, -100, 20, 0, 1)
                                Layout.minimumWidth: Layout.preferredWidth
                                Layout.maximumWidth: Layout.preferredWidth
                                Layout.fillHeight: true
                                color: Kirigami.Theme.highlightColor
                                radius: 100
                            }
                        }
                    }

                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        icon.name: "delete"
                        icon.color: "#ffffffff"
                    }
                }
            }
            QQC2.Button {
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                Layout.minimumWidth: Layout.preferredWidth
                Layout.rightMargin: root.spacing
                icon.name: zynqtgui.sketchpad.isRecording ? "media-playback-stop" : "media-record-symbolic"
                onClicked: {
                    zynqtgui.callable_ui_action("START_RECORD")
                }
            }
        }
        QQC2.Button {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            text: qsTr("Close")
            onClicked: {
                root.close()
            }
        }
    }
}
