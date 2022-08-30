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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

MouseArea {
    id: root
    implicitWidth: Kirigami.Units.gridUnit * 10
    Layout.minimumWidth: Kirigami.Units.gridUnit * 10
    Layout.fillHeight: true

    onClicked: zynthian.globalPopupOpened = true

    ColumnLayout {
        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
        }
        height: parent.height / 2
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                id: holdSignalARect
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                radius: 3
                x: Math.floor(zynthian.status_information.holdSignalA * root.width)
                opacity: x === 0 ? 0 : 1
                implicitWidth: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.negativeTextColor
                Behavior on x {
                    XAnimator {
                        duration: Kirigami.Units.shortDuration
                        easing.type: Easing.InOutQuad
                    }
                }
                Behavior on opacity {
                    OpacityAnimator {
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }
            Rectangle {
                id: highSignalARect
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }
                radius: 3
                color: Kirigami.Theme.negativeTextColor
                width: highSignalARect.peakSignalA * root.width
                property double peakSignalA: zynthian.status_information.peakSignalA
            }
            Rectangle {
                id: mediumSignalARect
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }
                radius: 3
                color: Kirigami.Theme.neutralTextColor
                width: Math.min(highSignalARect.peakSignalA, zynthian.status_information.over) * root.width
            }
            Rectangle {
                id: lowSignalARect
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }
                radius: 3
                color: Kirigami.Theme.positiveTextColor
                width: Math.min(highSignalARect.peakSignalA, zynthian.status_information.high) * root.width
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                id: holdSignalBRect
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                radius: 3
                x: Math.floor(Math.min(zynthian.status_information.holdSignalB, 1) * root.width)
                opacity: x === 0 ? 0 : 1
                implicitWidth: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.negativeTextColor
                Behavior on x {
                    XAnimator {
                        duration: Kirigami.Units.shortDuration
                        easing.type: Easing.InOutQuad
                    }
                }
                Behavior on opacity {
                    OpacityAnimator {
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }
            Rectangle {
                id: highSignalBRect
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }
                radius: 3
                color: Kirigami.Theme.negativeTextColor
                width: Math.min(highSignalBRect.peakSignalB, 1) * root.width
                property double peakSignalB: zynthian.status_information.peakSignalB
            }
            Rectangle {
                id: mediumSignalBRect
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }
                radius: 3
                color: Kirigami.Theme.neutralTextColor
                width: Math.min(highSignalBRect.peakSignalB, zynthian.status_information.over) * root.width
            }
            Rectangle {
                id: lowSignalBRect
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }
                radius: 3
                color: Kirigami.Theme.positiveTextColor
                width: Math.min(highSignalBRect.peakSignalB, zynthian.status_information.high) * root.width
            }
        }
    }

    RowLayout {
        id: statusIconsLayout
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        height: Math.min(parent.height / 2, Kirigami.Units.iconSizes.smallMedium)
        Kirigami.Icon {
            Layout.fillHeight: true
            Layout.preferredWidth: height
            source: "dialog-warning-symbolic"
            color: Kirigami.Theme.negativeTextColor
            visible: zynthian.status_information.xrun
        }
        Kirigami.Icon {
            Layout.fillHeight: true
            Layout.preferredWidth: height
            source: "preferences-system-power"
            visible: zynthian.status_information.undervoltage
        }
        Kirigami.Icon {
            id: audioRecorderIcon
            Layout.fillHeight: true
            Layout.preferredWidth: height
            color: Kirigami.Theme.textColor
            source: "media-playback-start-symbolic";
            function updateIcon() {
                if (audioRecorderIcon.visible) {
                    switch(zynthian.status_information.audio_recorder) {
                    case "PLAY":
                        if (audioRecorderIcon.source !== "media-playback-start-symbolic") {
                            audioRecorderIcon.source = "media-playback-start-symbolic";
                        }
                        break;
                    case "REC":
                    default:
                        if (audioRecorderIcon.source !== "media-record-symbolic") {
                            audioRecorderIcon.source = "media-record-symbolic";
                        }
                        break;
                    }
                }
            }
            Connections {
                target: zynthian.status_information
                onAudio_recorderChanged: audioRecorderIcon.updateIcon();
            }
            onVisibleChanged: audioRecorderIcon.updateIcon();
            QQC2.Label {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }
                font.pointSize: 6
                text: qsTr("Audio")
            }
            visible: zynthian.status_information.audio_recorder.length > 0
        }
        Kirigami.Icon {
            id: midiRecorderIcon
            Layout.fillHeight: true
            Layout.preferredWidth: height
            color: Kirigami.Theme.textColor
            source: "media-playback-start-symbolic"
            function updateIcon() {
                if (midiRecorderIcon.visible) {
                    switch(zynthian.status_information.midi_recorder) {
                    case "PLAY":
                        if (midiRecorderIcon.source !== "media-playback-start-symbolic") {
                            midiRecorderIcon.source = "media-playback-start-symbolic";
                        }
                        break;
                    case "REC":
                    default:
                        if (midiRecorderIcon.source !== "media-record-symbolic") {
                            midiRecorderIcon.source = "media-record-symbolic";
                        }
                        break;
                    }
                }
            }
            Connections {
                target: zynthian.status_information
                onMidi_recorderChanged: midiRecorderIcon.updateIcon()
            }
            onVisibleChanged: midiRecorderIcon.updateIcon()
            QQC2.Label {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }
                font.pointSize: 6
                text: "Midi"
            }
            visible: zynthian.status_information.midi_recorder.length > 0
        }
        QQC2.Label {
            visible: ZynQuick.PlayGridManager.hardwareInActiveNotes.length > 0
            text: visible
                ? "<font size=\"1\">I:</font>" + ZynQuick.PlayGridManager.hardwareInActiveNotes[0] + (ZynQuick.PlayGridManager.hardwareInActiveNotes.length > 1 ? "+" + (ZynQuick.PlayGridManager.hardwareInActiveNotes.length - 1) : "")
                : ""
            font.pointSize: 9
        }
        QQC2.Label {
            visible: ZynQuick.PlayGridManager.internalPassthroughActiveNotes.length > 0
            text: visible
                ? ZynQuick.PlayGridManager.internalPassthroughActiveNotes[0] + (ZynQuick.PlayGridManager.internalPassthroughActiveNotes.length > 1 ? "+" + (ZynQuick.PlayGridManager.internalPassthroughActiveNotes.length - 1) : "")
                : ""
            font.pointSize: 9
        }
        QQC2.Label {
            visible: ZynQuick.PlayGridManager.hardwareOutActiveNotes.length > 0
            text: visible
                ? "<font size=\"1\">O:</font>" + ZynQuick.PlayGridManager.hardwareOutActiveNotes[0] + (ZynQuick.PlayGridManager.hardwareOutActiveNotes.length > 1 ? "+" + (ZynQuick.PlayGridManager.hardwareOutActiveNotes.length - 1) : "")
                : ""
            font.pointSize: 9
        }
        QQC2.Label {
            id: metronomeLabel
            text: {
                if (zynthian.zynthiloops.isMetronomeRunning && zynthian.zynthiloops.currentBeat >= 0 && zynthian.zynthiloops.currentBar >= 0) {
                    return (zynthian.zynthiloops.currentBar+1) + "." + (zynthian.zynthiloops.currentBeat+1)
                } else {
                    return "1.1"
                }
            }
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignBottom
            Layout.topMargin: parent.height  -height
            QQC2.Label {
                id: bpmLabel
                text: zynthian.zynthiloops.song.selectedScale +" "+ zynthian.zynthiloops.song.bpm
                font.pointSize: 9
            }
            Kirigami.Icon {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                source: Qt.resolvedUrl("../../img/metronome.svg")
                color: "#ffffff"
                opacity: zynthian.zynthiloops.clickChannelEnabled ? 1.0 : 0.0
            }
        }
    }

    QQC2.Popup {
        id: popup
        visible: zynthian.globalPopupOpened

        y: parent.height
        x: parent.width - width
        width: Kirigami.Units.gridUnit * 20
        height: Kirigami.Units.gridUnit * 25

        exit: null; enter: null; // Disable the enter and exit transition animations. TODO This really wants doing somewhere central...
        modal: true
        onClosed: zynthian.globalPopupOpened = false
        contentItem: GridLayout {
            columns: 3
            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                contentItem: ZynthiloopsDial {
                    id: bpmDial
                    text: qsTr("BPM")
                    controlObj: zynthian.zynthiloops.song
                    controlProperty: "bpm"

                    dial {
                        stepSize: 1
                        from: 50
                        to: 200
                    }

                    onPressed: registerTap();
                    property int bpm: 0
                    property var timestamps: []
                    function registerTap() {
                        var newStamp = Date.now();
                        if (bpmDial.timestamps.length > 0 && newStamp - bpmDial.timestamps[timestamps.length - 1] > 2000) {
                            // If the most recent tap was more than two seconds ago, clear the list and start a new estimation
                            bpmDial.timestamps = [];
                            bpm = 0;
                        }
                        bpmDial.timestamps.push(newStamp);
                        if (bpmDial.timestamps.length > 1) {
                            var differences = [];
                            for (var i = 0; i < bpmDial.timestamps.length - 1; ++i) {
                                differences.push(bpmDial.timestamps[i + 1] - bpmDial.timestamps[i]);
                            }
                            var sum = 0;
                            for (var i = 0; i < differences.length; ++i) {
                                sum += differences[i];
                            }
                            var average = sum / differences.length;
                            bpmDial.bpm = 60000 / average;
                            zynthian.zynthiloops.song.bpm = Math.min(Math.max(bpmDial.bpm, 50), 200);
                        }
                    }
                }
            }
            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                contentItem: ColumnLayout {
                    ZynthiloopsMultiSwitch {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        controlObj: zynthian.zynthiloops.song
                        controlProperty: "selectedScaleIndex"
                        from: 0
                        to: 11
                        text: zynthian.zynthiloops.song.selectedScale
                    }
                    QQC2.Label {
                        text: qsTr("Scale")
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                contentItem: ZynthiloopsDial {
                    id: volumeDial
                    text: qsTr("Volume")
                    controlObj: zynthian.master_alsa_mixer
                    controlProperty: "volume"
                    valueString: qsTr("%1%").arg(dial.value)

                    dial {
                        stepSize: 1
                        from: 0
                        to: 100
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                contentItem: ZynthiloopsDial {
                    text: qsTr("Delay")
                    controlObj: zynthian
                    controlProperty: "delayKnobValue"
                    valueString: qsTr("%1%").arg(dial.value)

                    dial {
                        stepSize: 1
                        from: 0
                        to: 100
                    }
                }
            }
            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                contentItem: Item {}
            }
            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                contentItem: ZynthiloopsDial {
                    text: qsTr("Reverb")
                    controlObj: zynthian
                    controlProperty: "reverbKnobValue"
                    valueString: qsTr("%1%").arg(dial.value)

                    dial {
                        stepSize: 1
                        from: 0
                        to: 100
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                contentItem: RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    QQC2.Label {
                        text: qsTr("Click")
                    }

                    QQC2.Switch {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: Kirigami.Units.gridUnit * 3
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        checked: zynthian.zynthiloops.clickChannelEnabled
                        onToggled: {
                            zynthian.zynthiloops.clickChannelEnabled = checked
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                text: qsTr("Stop All Notes")
                onClicked: zynthian.callable_ui_action("ALL_NOTES_OFF")
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                text: qsTr("Stop Playback")
                onClicked: {
                    Zynthian.CommonUtils.stopMetronomeAndPlayback();
                }
            }
        }
    }
}
