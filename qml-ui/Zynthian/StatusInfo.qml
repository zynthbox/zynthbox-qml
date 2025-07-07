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
import org.kde.plasma.core 2.0 as PlasmaCore

import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian
import "private" as Private

QQC2.Pane
{
    id: root

    property bool highlighted : false

    Layout.minimumWidth: Kirigami.Units.gridUnit * 10
    Layout.maximumWidth: Kirigami.Units.gridUnit * 10

    Layout.fillHeight: true

    topPadding: svgBg.visible ? svgBg.topPadding : Kirigami.Units.smallSpacing
    bottomPadding: svgBg.visible ? svgBg.bottomPadding : Kirigami.Units.smallSpacing
    leftPadding: svgBg.visible ? svgBg.leftPadding : Kirigami.Units.smallSpacing
    rightPadding: svgBg.visible ? svgBg.rightPadding : Kirigami.Units.smallSpacing

    background: Item
    {
        PlasmaCore.FrameSvgItem {
            id: svgBg
            visible: fromCurrentTheme
            anchors.fill: parent

            readonly property real leftPadding: margins.left
            readonly property real rightPadding: margins.right
            readonly property real topPadding: margins.top
            readonly property real bottomPadding: margins.bottom

            imagePath: "widgets/statusinfo_background"
            //colorGroup: PlasmaCore.Theme.ViewColorGroup
            prefix: root.highlighted ? ["focus", ""] : ""
            colorGroup: PlasmaCore.Theme.ViewColorGroup
        }
    }

    contentItem: MouseArea {

        onClicked: zynqtgui.globalPopupOpened = true

        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.mediumSpacing

            ColumnLayout {
                Layout.fillWidth: true

                Item {
                    id: bar1

                    Layout.fillWidth: true
                    implicitHeight: 6
                    clip: true

                    Rectangle {
                        id: holdSignalARect
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                        }
                        radius: 3
                        x: Math.floor(Math.min(Math.max(0, 1 + Zynthbox.AudioLevels.playbackAHold / zynqtgui.status_information.rangedB), 1) * bar1.width)
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
                        width: highSignalARect.peakSignalA * bar1.width
                        property double peakSignalA: Math.min(Math.max(0, 1 + Zynthbox.AudioLevels.playbackA / zynqtgui.status_information.rangedB), 1)
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
                        width: Math.min(highSignalARect.peakSignalA, zynqtgui.status_information.over) * bar1.width
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
                        width: Math.min(highSignalARect.peakSignalA, zynqtgui.status_information.high) * bar1.width
                    }
                }

                Item {
                    id: bar2

                    Layout.fillWidth: true
                    implicitHeight: 6
                    clip: true

                    Rectangle {
                        id: holdSignalBRect
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                        }
                        radius: 3
                        x: Math.floor(Math.min(Math.max(0, 1 + Zynthbox.AudioLevels.playbackBHold / zynqtgui.status_information.rangedB), 1) * bar2.width)
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
                        width: Math.min(highSignalBRect.peakSignalB, 1) * bar2.width
                        property double peakSignalB: Math.min(Math.max(0, 1 + Zynthbox.AudioLevels.playbackB / zynqtgui.status_information.rangedB), 1)
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
                        width: Math.min(highSignalBRect.peakSignalB, zynqtgui.status_information.over) * bar2.width
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
                        width: Math.min(highSignalBRect.peakSignalB, zynqtgui.status_information.high) * bar2.width
                    }
                }

                RowLayout {
                    id: statusIconsLayout
                    Layout.fillWidth: true

                    QQC2.Label {
                        color: Kirigami.Theme.textColor
                        text: "ALT"
                        padding: 1
                        visible: zynqtgui.altButtonPressed
                        font.pointSize: 6
                        background: Rectangle {
                            color: "transparent"
                            border {
                                width: 1
                                color: Kirigami.Theme.textColor
                            }
                            radius: 3
                        }
                    }
                    Kirigami.Icon {
                        implicitHeight: 16
                        implicitWidth: 16
                        source: "dialog-warning-symbolic"
                        color: Kirigami.Theme.negativeTextColor
                        visible: zynqtgui.status_information.xrun
                    }
                    Kirigami.Icon {
                        implicitHeight: 16
                        implicitWidth: 16
                        source: "preferences-system-power"
                        visible: zynqtgui.status_information.undervoltage
                    }
                    Kirigami.Icon {
                        id: audioRecorderIcon
                        implicitHeight: 16
                        implicitWidth: 16
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
                            color: Kirigami.Theme.neutralTextColor
                        }
                        visible: zynqtgui.status_information.audio_recorder.length > 0
                    }
                    QQC2.Label {
                        visible: Zynthbox.PlayGridManager.hardwareInActiveNotes.length > 0
                        text: visible
                              ? "<font size=\"1\">I:</font>" + Zynthbox.PlayGridManager.hardwareInActiveNotes[0] + (Zynthbox.PlayGridManager.hardwareInActiveNotes.length > 1 ? "+" + (Zynthbox.PlayGridManager.hardwareInActiveNotes.length - 1) : "")
                              : ""
                        font.pointSize: 8
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignRight
                        visible: Zynthbox.PlayGridManager.internalControllerPassthroughActiveNotes.length > 0
                        text: visible
                              ? Zynthbox.PlayGridManager.internalControllerPassthroughActiveNotes[0] + (Zynthbox.PlayGridManager.internalControllerPassthroughActiveNotes.length > 1 ? "+" + (Zynthbox.PlayGridManager.internalControllerPassthroughActiveNotes.length - 1) : "")
                              : ""
                        font.pointSize: 8
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignRight
                        visible: Zynthbox.PlayGridManager.internalPassthroughActiveNotes.length > 0
                        text: visible
                              ? "<font size=\"1\">S:</font>" + Zynthbox.PlayGridManager.internalPassthroughActiveNotes[0] + (Zynthbox.PlayGridManager.internalPassthroughActiveNotes.length > 1 ? "+" + (Zynthbox.PlayGridManager.internalPassthroughActiveNotes.length - 1) : "")
                              : ""
                        font.pointSize: 8
                    }
                    //        QQC2.Label {
                    //            visible: Zynthbox.PlayGridManager.hardwareOutActiveNotes.length > 0
                    //            text: visible
                    //                ? "<font size=\"1\">O:</font>" + Zynthbox.PlayGridManager.hardwareOutActiveNotes[0] + (Zynthbox.PlayGridManager.hardwareOutActiveNotes.length > 1 ? "+" + (Zynthbox.PlayGridManager.hardwareOutActiveNotes.length - 1) : "")
                    //                : ""
                    //            font.pointSize: 9
                    //        }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignRight
                        id: metronomeLabel
                        // font.pointSize: 8
                        text: {
                            if (zynqtgui.sketchpad.isMetronomeRunning && zynqtgui.sketchpad.currentBeat >= 0 && zynqtgui.sketchpad.currentBar >= 0) {
                                return (zynqtgui.sketchpad.currentBar+1) + "." + (zynqtgui.sketchpad.currentBeat+1)
                            } else {
                                return "1.1"
                            }
                        }
                    }
                }
            }

            ColumnLayout {
               Layout.fillHeight: true
                QQC2.Label {
                    id: bpmLabel
                    Layout.alignment: Qt.AlignTop
                    // Hide scale info for now
                    // text: zynqtgui.sketchpad.song.selectedScale +" "+ Zynthbox.SyncTimer.bpm
                    text: Zynthbox.SyncTimer.bpm
                    font.pointSize: 8
                }
                Kirigami.Icon {
                    Layout.alignment: Qt.AlignCenter
                    implicitHeight: 16
                    implicitWidth: 16
                    source: Qt.resolvedUrl("../../img/metronome.svg")
                    color: Kirigami.Theme.textColor
                    opacity: zynqtgui.sketchpad.metronomeEnabled ? 1 : 0
                }
            }
        }

        Zynthian.Popup {
            id: popup

            property var cuiaCallback: function(cuia) {
                var result = popup.opened;
                switch(cuia) {
                case "SWITCH_PLAY":
                case "SWITCH_STOP":
                case "ALL_NOTES_OFF":
                case "ALL_SOUNDS_OFF":
                case "ALL_OFF":
                    // Playback control is not handled by us, so pass these through
                    result = false;
                    break;
                case "SELECT_UP":
                case "SELECT_DOWN":
                case "NAVIGATE_LEFT":
                case "NAVIGATE_RIGHT":
                    // Let's ensure we don't accidentally switch tracks and whatnot with the popup open
                    result = true;
                    break;
                case "SWITCH_SELECT_SHORT":
                case "SWITCH_SELECT_BOLD":
                case "SWITCH_BACK_SHORT":
                case "SWITCH_BACK_BOLD":
                    zynqtgui.globalPopupOpened = false;
                    result = true;
                    break;
                case "SCREEN_MAIN_MENU":
                case "SCREEN_LAYER":
                case "SCREEN_LAYER_FX":
                case "SCREEN_BANK":
                case "SCREEN_PRESET":
                case "SCREEN_CONTROL":
                case "SCREEN_SKETCHPAD":
                case "SCREEN_SONG_MANAGER":
                case "SCREEN_PLAYGRID":
                case "SCREEN_ALSA_MIXER":
                    // If someone hits one of the under-screen buttons, just close the thing,
                    // but also pass the buttons through so we can switch to that screen
                    zynqtgui.globalPopupOpened = false;
                    result = false;
                    break;
                case "KNOB0_UP":
                    applicationWindow().updateSketchpadBpm(1);
                    result = true;
                    break;
                case "KNOB0_DOWN":
                    applicationWindow().updateSketchpadBpm(-1);
                    result = true;
                    break;
                case "KNOB1_UP":
                    applicationWindow().updateGlobalDelayFXAmount(1);
                    result = true;
                    break;
                case "KNOB1_DOWN":
                    applicationWindow().updateGlobalDelayFXAmount(-1);
                    result = true;
                    break;
                case "KNOB2_UP":
                    applicationWindow().updateGlobalReverbFXAmount(1);
                    result = true;
                    break;
                case "KNOB2_DOWN":
                    applicationWindow().updateGlobalReverbFXAmount(-1);
                    result = true;
                    break;
                case "KNOB3_UP":
                    if (zynqtgui.altButtonPressed) {
                        zynqtgui.sketchpad.metronomeVolume = Math.min(1, zynqtgui.sketchpad.metronomeVolume + 0.01);
                    } else {
                        applicationWindow().updateMasterVolume(1);
                    }
                    result = true;
                    break;
                case "KNOB3_DOWN":
                    if (zynqtgui.altButtonPressed) {
                        zynqtgui.sketchpad.metronomeVolume = Math.max(0, zynqtgui.sketchpad.metronomeVolume - 0.01);
                    } else {
                        applicationWindow().updateMasterVolume(-1);
                    }
                    result = true;
                    break;
                }
                return result;
            }

            visible: zynqtgui.globalPopupOpened
            y: parent.height
            x: parent.width - width
            width: Kirigami.Units.gridUnit * 24
            height: Kirigami.Units.gridUnit * 28
            onClosed: zynqtgui.globalPopupOpened = false
            contentItem: Item {
                GridLayout {
                    anchors.fill: parent
                    columns: 3
                    Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                        contentItem: Item {
                            ColumnLayout {
                                anchors.fill: parent
                                SketchpadDial {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    Layout.margins: Kirigami.Units.gridUnit
                                    id: volumeDial
                                    text: qsTr("Volume")
                                    controlObj: zynqtgui
                                    controlProperty: "masterVolume"
                                    valueString: qsTr("%1%").arg(dial.value)
                                    knobId: 3

                                    dial {
                                        stepSize: 1
                                        from: 0
                                        to: 100
                                    }
                                }
                            }
                        }
                    }
                    Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
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
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                        contentItem: Item {
                            ColumnLayout {
                                anchors.fill: parent
                                SketchpadDial {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    Layout.margins: Kirigami.Units.gridUnit
                                    id: bpmDial
                                    text: qsTr("BPM")
                                    controlObj: Zynthbox.SyncTimer
                                    controlProperty: "bpm"
                                    knobId: 0

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
                                            Zynthbox.SyncTimer.setBpm(bpmDial.bpm)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                        contentItem: Item {
                            ColumnLayout {
                                anchors.fill: parent
                                SketchpadDial {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    Layout.margins: Kirigami.Units.gridUnit
                                    text: qsTr("Delay")
                                    controlObj: zynqtgui.delayController
                                    controlProperty: "value"
                                    valueString: qsTr("%1%").arg(dial.value)
                                    knobId: 1

                                    dial {
                                        stepSize: zynqtgui.delayController.step_size
                                        from: zynqtgui.delayController.value_min
                                        to: zynqtgui.delayController.value_max
                                    }
                                    onClicked: {
                                        zynqtgui.editGlobalFX(0);
                                        popup.close();
                                    }
                                    // Apparently neither of our two global fx picks have presets defined, so... never mind showing the button
                                    // action: QQC2.Action {
                                    //     text: "Preset Name"
                                    //     onTriggered: {
                                    //         zynqtgui.selectGlobalFXPreset(0);
                                    //         popup.close();
                                    //     }
                                    // }
                                }
                            }
                        }
                    }
                    Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
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
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                        contentItem: Item {
                            ColumnLayout {
                                anchors.fill: parent
                                SketchpadDial {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.margins: Kirigami.Units.gridUnit
                                    text: qsTr("Reverb")
                                    controlObj: zynqtgui.reverbController
                                    controlProperty: "value"
                                    valueString: qsTr("%1%").arg(dial.value)
                                    knobId: 2

                                    dial {
                                        stepSize: zynqtgui.reverbController.step_size
                                        from: zynqtgui.reverbController.value_min
                                        to: zynqtgui.reverbController.value_max
                                    }
                                    onClicked: {
                                        zynqtgui.editGlobalFX(1);
                                        popup.close();
                                    }
                                    // Apparently neither of our two global fx picks have presets defined, so... never mind showing the button
                                    // action: QQC2.Action {
                                    //     text: "Preset Name"
                                    //     onTriggered: {
                                    //         zynqtgui.selectGlobalFXPreset(1);
                                    //         popup.close();
                                    //     }
                                    // }
                                }
                            }
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                        Layout.columnSpan: 2
                        contentItem: RowLayout {
                            Layout.alignment: Qt.AlignLeft
                            QQC2.Switch {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                checked: zynqtgui.sketchpad.metronomeEnabled
                                text: qsTr("Click")
                                onToggled: {
                                    zynqtgui.sketchpad.metronomeEnabled = checked
                                }
                            }
                            QQC2.Slider {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredHeight: Kirigami.Units.gridUnit
                                Layout.fillWidth: true
                                enabled: zynqtgui.sketchpad.metronomeEnabled
                                from: 0
                                to: 1
                                value: zynqtgui.sketchpad.metronomeVolume
                                onValueChanged: zynqtgui.sketchpad.metronomeVolume = value
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
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                        text: qsTr("Stop All Notes")
                        onClicked: zynqtgui.callable_ui_action_simple("ALL_NOTES_OFF")
                    }

                    RowLayout {
                        Layout.columnSpan: 3
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.largeSpacing
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        QQC2.Label {
                            Layout.fillHeight: true
                            text: qsTr("DSP Load:")
                        }
                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Private.CardBackground {
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    right: parent.right
                                    margins: 1
                                }
                                height: Kirigami.Units.largeSpacing * 2
                                Rectangle {
                                    anchors {
                                        fill: parent
                                        margins: 1
                                    }
                                    color: "green"
                                    Rectangle {
                                        anchors {
                                            fill: parent
                                            leftMargin: parent.width * 2 / 3
                                        }
                                        color: "yellow"
                                        Rectangle {
                                            anchors {
                                                fill: parent
                                                leftMargin: parent.width * 2 / 3
                                            }
                                            color: "red"
                                        }
                                    }
                                }
                                Rectangle {
                                    anchors {
                                        top: parent.top
                                        right: parent.right
                                        bottom: parent.bottom
                                        margins: 1
                                    }
                                    width: zynqtgui.globalPopupOpened ? (parent.width - 2) * (1 - Zynthbox.MidiRouter.processingLoad) : 0
                                    color: Kirigami.Theme.backgroundColor
                                }
                                QQC2.Label {
                                    anchors {
                                        fill: parent
                                        margins: 2
                                    }
                                    text: zynqtgui.globalPopupOpened ? qsTr("%1%").arg((100 * Zynthbox.MidiRouter.processingLoad).toFixed(1)) : ""
                                    font.pixelSize: height
                                }
                            }
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
}
