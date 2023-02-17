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

QQC2.Popup {
    id: root
    property QtObject selectedChannel: zynthian.sketchpad.song.channelsModel.getChannel(zynthian.session_dashboard.selectedChannel)

    function cuiaCallback(cuia) {
        var returnValue = false;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                root.close();
                returnValue = true;
                break;
        }

        return returnValue;
    }

    exit: null; enter: null; // Disable the enter and exit transition animations. TODO This really wants doing somewhere central...
    modal: true
    focus: true
    parent: QQC2.Overlay.overlay
    y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
    x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
    closePolicy: !zynthian.sketchpad.isRecording ? (QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside) : QQC2.Popup.NoAutoClose
    width: parent.width * 0.95
    height: parent.height * 0.95
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    onOpenedChanged: {
        if (opened) {
            // Report dialog open to zynthian for passing cuia events to dialog
            zynthian.openedDialog = root
            // Assign clip to record on open so that correct clip is fetched
            zynthian.sketchpad.clipsToRecord = [root.selectedChannel.getClipToRecord()]

            // Reset recordingType combo model to selected value when dialog opens
            for (var i=0; i<recordingTypeComboModel.count; i++) {
                if (recordingTypeComboModel.get(i).value === zynthian.sketchpad.recordingType) {
                    recordingTypeCombo.currentIndex = i
                    break
                }
            }

            // Reset source combo model to selected value when dialog opens
            for (var i=0; i<sourceComboModel.count; i++) {
                if (sourceComboModel.get(i).value === zynthian.sketchpad.recordingSource) {
                    sourceCombo.currentIndex = i
                    break
                }
            }

            // Reset countIn combo model to selected value when dialog opens
            for (var i=0; i<countInComboModel.count; i++) {
                if (countInComboModel.get(i).value === zynthian.sketchpad.countInBars) {
                    countInCombo.currentIndex = i
                    break
                }
            }

            // Reset channel combo model to selected value when dialog opens
            for (var i=0; i<recordingChannelComboModel.count; i++) {
                if (recordingChannelComboModel.get(i).value === zynthian.sketchpad.recordingChannel) {
                    recordingChannelCombo.currentIndex = i
                    break
                }
            }
        } else {
            // Report dialog close to zynthian to stop receiving cuia events
            if (zynthian.openedDialog === root) {
                zynthian.openedDialog = null
            }
        }
    }
    onOpened: {
        zynthian.recordingPopupActive = true
    }
    onClosed: {
        zynthian.recordingPopupActive = false
    }
    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing

        Kirigami.Heading {
            Layout.fillWidth: true
            text: qsTr("Record clip for Channel %1").arg(selectedChannel.name)
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 1
            Layout.maximumHeight: 1
            color: Kirigami.Theme.textColor
            opacity: 0.5
        }
        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                enabled: !zynthian.sketchpad.isRecording
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
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: recordingTypeComboModel

                            ListElement { text: "Audio"; value: "audio" }
                            ListElement { text: "Midi"; value: "midi" }
                        }
                        textRole: "text"
                        onActivated: {
                            zynthian.sketchpad.recordingType = recordingTypeComboModel.get(index).value
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    visible: zynthian.sketchpad.recordingType === "audio"

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Audio Source")
                    }

                    Zynthian.ComboBox {
                        id: sourceCombo

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: sourceComboModel

                            ListElement { text: "Internal (Active Layer)"; value: "internal" }
                            ListElement { text: "External (Audio In)"; value: "external" }
                        }
                        textRole: "text"
                        onActivated: {
                            zynthian.sketchpad.recordingSource = sourceComboModel.get(index).value
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
                        checked: zynthian.sketchpad.recordSolo
                        onToggled: {
                            zynthian.sketchpad.recordSolo = checked
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    visible: zynthian.sketchpad.recordingType === "audio" && // Visible when recordingType is audio
                             zynthian.sketchpad.recordingSource === "internal" // and when source is internal

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        Layout.alignment: Qt.AlignCenter
                        enabled: parent.enabled
                        text: qsTr("Source Channel")
                    }

                    Zynthian.ComboBox {
                        id: channelCombo

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
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
                        currentIndex: visible ? zynthian.session_dashboard.selectedChannel : -1
                        onActivated: {
                            zynthian.session_dashboard.selectedChannel = channelComboModel.get(index).value
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    visible: zynthian.sketchpad.recordingType === "audio" && // Visible when recordingType is audio
                             zynthian.sketchpad.recordingSource === "external" // and when source is external

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Channel")
                    }

                    Zynthian.ComboBox {
                        id: recordingChannelCombo

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: recordingChannelComboModel

                            ListElement { text: "Left Channel"; value: "1" }
                            ListElement { text: "Right Channel"; value: "2" }
                            ListElement { text: "Stereo"; value: "*" }
                        }
                        textRole: "text"
                        onActivated: {
                            zynthian.sketchpad.recordingChannel = recordingChannelComboModel.get(index).value
                        }
                    }
                }

                RowLayout {
                    visible: false // Hide target channels for now
                    Layout.fillWidth: false

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        Layout.alignment: Qt.AlignCenter
                        enabled: parent.enabled
                        text: qsTr("Target Channels")
                    }

                    QQC2.Button {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Select target channels")
                        onClicked: {
                            targetChannelsPopup.open()
                        }

                        QQC2.Popup {
                            id: targetChannelsPopup
                            exit: null; enter: null; // Disable the enter and exit transition animations. TODO This really wants doing somewhere central...
                            modal: true
                            focus: true
                            parent: QQC2.Overlay.overlay
                            y: root.parent.mapFromGlobal(0, Math.round(root.parent.height/2 - height/2)).y
                            x: root.parent.mapFromGlobal(Math.round(root.parent.width/2 - width/2), 0).x
                            closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

                            ColumnLayout {
                                implicitWidth: root.parent.width * 0.6
                                implicitHeight: root.parent.height * 0.7

                                Kirigami.Heading {
                                    Layout.fillWidth: true
                                    text: qsTr("Select slots to record")
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: 1
                                    Layout.maximumHeight: 1
                                    color: Kirigami.Theme.textColor
                                    opacity: 0.5
                                }

                                Repeater {
                                    model: 10
                                    delegate: RowLayout {
                                        id: targetChannelsDelegate
                                        property QtObject channel: zynthian.sketchpad.song.channelsModel.getChannel(index)

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        QQC2.Label {
                                            Layout.fillWidth: false
                                            Layout.fillHeight: true
                                            Layout.minimumWidth: Kirigami.Units.gridUnit * 8
                                            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
                                            elide: "ElideRight"
                                            text: qsTr("Channel %1 (%2)")
                                                    .arg(targetChannelsDelegate.channel.name)
                                                    .arg(targetChannelsDelegate.channel.channelAudioType === "sample-loop"
                                                            ? "Loop"
                                                            : targetChannelsDelegate.channel.channelAudioType === "sample-trig"
                                                                ? "Smp: Trig"
                                                                : targetChannelsDelegate.channel.channelAudioType === "sample-slice"
                                                                    ? "Smp: Slice"
                                                                    : targetChannelsDelegate.channel.channelAudioType === "synth"
                                                                      ? "Synth"
                                                                      : targetChannelsDelegate.channel.channelAudioType === "external"
                                                                            ? "External"
                                                                            : "")
                                        }

                                        Repeater {
                                            id: targetChannelsSlotsRepeater
                                            model: 5
                                            delegate: QQC2.Button {
                                                property QtObject clip: targetChannelsDelegate.channel
                                                                            ? ["sample-trig", "sample-slice"].indexOf(targetChannelsDelegate.channel.channelAudioType) >= 0
                                                                                ? targetChannelsDelegate.channel.samples[index]
                                                                                : index === 0
                                                                                  ? targetChannelsDelegate.channel.sceneClip
                                                                                  : null
                                                                            : null

                                                opacity: clip != null
                                                          ? checked
                                                             ? 1
                                                             : 0.5
                                                          : 0
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                checked: clip && zynthian.sketchpad.clipsToRecord.indexOf(clip) >= 0
                                                text: qsTr("Slot %1").arg(index+1)
                                                onClicked: {
                                                    zynthian.sketchpad.toggleFromClipsToRecord(clip)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
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
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: countInComboModel

                            ListElement { text: "Off"; value: 0 }
                            ListElement { text: "1"; value: 1 }
                            ListElement { text: "2"; value: 2 }
                            ListElement { text: "4"; value: 4 }
                        }
                        textRole: "text"
                        onActivated: zynthian.sketchpad.countInBars = countInComboModel.get(index).value
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Record Master Output")
                    }

                    QQC2.Switch {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: Kirigami.Units.gridUnit * 4
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        checked: zynthian.sketchpad.recordMasterOutput
                        onToggled: {
                            zynthian.sketchpad.recordMasterOutput = checked
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Metronome")
                    }

                    QQC2.Switch {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: Kirigami.Units.gridUnit * 4
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        checked: zynthian.sketchpad.clickChannelEnabled
                        onToggled: {
                            zynthian.sketchpad.clickChannelEnabled = checked
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
                                       ? zynthian.sketchpad.recordingSource === "internal"
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
                                        ? zynthian.sketchpad.recordingSource === "internal"
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

                    icon.name: zynthian.sketchpad.isRecording ? "media-playback-stop" : "media-record-symbolic"

                    onClicked: {
                        if (zynthian.sketchpad.clipsToRecord[0]) {
                            if (!zynthian.sketchpad.isRecording) {
                                // Start recording with first clip in clipsToRecord
                                zynthian.sketchpad.clipsToRecord[0].queueRecording();
                                Zynthian.CommonUtils.startMetronomeAndPlayback();
                            } else {
                                Zynthian.CommonUtils.stopMetronomeAndPlayback();
                                // bottomBar.tabbedView.initialAction.trigger()
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }
}
