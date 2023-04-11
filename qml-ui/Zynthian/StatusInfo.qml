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

import libzl 1.0 as ZL
import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

MouseArea {
    id: root
    implicitWidth: Kirigami.Units.gridUnit * 10
    Layout.minimumWidth: Kirigami.Units.gridUnit * 10
    Layout.fillHeight: true

    onClicked: zynqtgui.globalPopupOpened = true

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
                x: Math.floor(Math.min(Math.max(0, 1 + ZL.AudioLevels.playbackAHold / zynqtgui.status_information.rangedB), 1) * root.width)
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
                property double peakSignalA: Math.min(Math.max(0, 1 + ZL.AudioLevels.playbackA / zynqtgui.status_information.rangedB), 1)
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
                width: Math.min(highSignalARect.peakSignalA, zynqtgui.status_information.over) * root.width
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
                width: Math.min(highSignalARect.peakSignalA, zynqtgui.status_information.high) * root.width
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
                x: Math.floor(Math.min(Math.max(0, 1 + ZL.AudioLevels.playbackBHold / zynqtgui.status_information.rangedB), 1) * root.width)
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
                property double peakSignalB: Math.min(Math.max(0, 1 + ZL.AudioLevels.playbackB / zynqtgui.status_information.rangedB), 1)
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
                width: Math.min(highSignalBRect.peakSignalB, zynqtgui.status_information.over) * root.width
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
                width: Math.min(highSignalBRect.peakSignalB, zynqtgui.status_information.high) * root.width
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
        QQC2.Label {
            Layout.fillHeight: true
            Layout.margins: statusIconsLayout.height / 4
            color: Kirigami.Theme.textColor
            font.pixelSize: Math.floor(statusIconsLayout.height / 2)
            text: "ALT"
            visible: zynqtgui.altButtonPressed
            Rectangle {
                anchors {
                    fill: parent
                    margins: -2
                }
                color: "transparent"
                border {
                    width: 1
                    color: Kirigami.Theme.textColor
                }
                radius: 3
            }
        }
        Kirigami.Icon {
            Layout.fillHeight: true
            Layout.preferredWidth: height
            source: "dialog-warning-symbolic"
            color: Kirigami.Theme.negativeTextColor
            visible: zynqtgui.status_information.xrun
        }
        Kirigami.Icon {
            Layout.fillHeight: true
            Layout.preferredWidth: height
            source: "preferences-system-power"
            visible: zynqtgui.status_information.undervoltage
        }
        Kirigami.Icon {
            id: audioRecorderIcon
            Layout.fillHeight: true
            Layout.preferredWidth: height
            color: Kirigami.Theme.textColor
            source: "media-playback-start-symbolic";
            function updateIcon() {
                if (audioRecorderIcon.visible) {
                    switch(zynqtgui.status_information.audio_recorder) {
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
                target: zynqtgui.status_information
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
            visible: zynqtgui.status_information.audio_recorder.length > 0
        }
        Kirigami.Icon {
            id: midiRecorderIcon
            Layout.fillHeight: true
            Layout.preferredWidth: height
            color: Kirigami.Theme.textColor
            source: "media-playback-start-symbolic"
            function updateIcon() {
                if (midiRecorderIcon.visible) {
                    switch(zynqtgui.status_information.midi_recorder) {
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
                target: zynqtgui.status_information
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
            visible: zynqtgui.status_information.midi_recorder.length > 0
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
//        QQC2.Label {
//            visible: ZynQuick.PlayGridManager.hardwareOutActiveNotes.length > 0
//            text: visible
//                ? "<font size=\"1\">O:</font>" + ZynQuick.PlayGridManager.hardwareOutActiveNotes[0] + (ZynQuick.PlayGridManager.hardwareOutActiveNotes.length > 1 ? "+" + (ZynQuick.PlayGridManager.hardwareOutActiveNotes.length - 1) : "")
//                : ""
//            font.pointSize: 9
//        }
        QQC2.Label {
            id: metronomeLabel
            text: {
                if (zynqtgui.sketchpad.isMetronomeRunning && zynqtgui.sketchpad.currentBeat >= 0 && zynqtgui.sketchpad.currentBar >= 0) {
                    return (zynqtgui.sketchpad.currentBar+1) + "." + (zynqtgui.sketchpad.currentBeat+1)
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
                // Hide scale info for now
                // text: zynqtgui.sketchpad.song.selectedScale +" "+ zynqtgui.sketchpad.song.bpm
                text: zynqtgui.sketchpad.song.bpm
                font.pointSize: 9
            }
            Kirigami.Icon {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                source: Qt.resolvedUrl("../../img/metronome.svg")
                color: "#ffffff"
                opacity: zynqtgui.sketchpad.clickChannelEnabled ? 1.0 : 0.0
            }
        }
    }

    Zynthian.Popup {
        id: popup

        property var cuiaCallback: function(cuia) {
            switch(cuia) {
                // If Global button is pressed when global popup is open, close it
                case "SCREEN_AUDIO_SETTINGS":
                    popup.close()
                    return true
            }
        }

        visible: zynqtgui.globalPopupOpened
        y: parent.height
        x: parent.width - width
        width: Kirigami.Units.gridUnit * 20
        height: Kirigami.Units.gridUnit * 25
        onClosed: zynqtgui.globalPopupOpened = false
        contentItem: Item {
            GridLayout {
                anchors.fill: parent;
                columns: 3
                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    contentItem: SketchpadDial {
                        id: bpmDial
                        text: qsTr("BPM")
                        controlObj: zynqtgui.sketchpad.song
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
                                zynqtgui.sketchpad.song.bpm = Math.min(Math.max(bpmDial.bpm, 50), 200);
                            }
                        }
                    }
                }
                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    contentItem: ColumnLayout {
                        visible: false // Hide scale for now
                        SketchpadMultiSwitch {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            controlObj: zynqtgui.sketchpad.song
                            controlProperty: "selectedScaleIndex"
                            from: 0
                            to: 11
                            text: zynqtgui.sketchpad.song.selectedScale
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
                    contentItem: SketchpadDial {
                        id: volumeDial
                        text: qsTr("Volume")
                        controlObj: zynqtgui
                        controlProperty: "masterVolume"
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
                    contentItem: SketchpadDial {
                        text: qsTr("Delay")
                        controlObj: zynqtgui
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
                    contentItem: ColumnLayout {
                        visible: false // Hide BT for now
                        Layout.alignment: Qt.AlignVCenter
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.Wrap
                            text: bluetoothSetup.connectedDevice === null ? qsTr("Not\nConnected") : qsTr("Connected to\n%1").arg(bluetoothSetup.connectedDevice.name)
                        }
                        QQC2.Button {
                            icon.name: bluetoothSetup.connectedDevice === null ? "network-bluetooth" : "network-bluetooth-activated"
                            text: qsTr("Setup")
                            display: QQC2.AbstractButton.TextBesideIcon
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                            onClicked: {
                                bluetoothSetup.show();
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: qsTr("BT Audio")
                        }
                    }
                }
                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    contentItem: SketchpadDial {
                        text: qsTr("Reverb")
                        controlObj: zynqtgui
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
                            checked: zynqtgui.sketchpad.clickChannelEnabled
                            onToggled: {
                                zynqtgui.sketchpad.clickChannelEnabled = checked
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
                    onClicked: zynqtgui.callable_ui_action("ALL_NOTES_OFF")
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
        BluetoothConnections {
            id: bluetoothSetup
            visible: false
            anchors.fill: parent
            Connections {
                target: zynqtgui
                onGlobalPopupOpenedChanged: {
                    if (zynqtgui.globalPopupOpened === false) {
                        bluetoothSetup.hide();
                    }
                }
            }
        }
    }
}
