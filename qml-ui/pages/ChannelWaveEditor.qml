/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Channel Wave Editor

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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian
import "./Sketchpad" as Sketchpad

Zynthian.ScreenPage {
    id: component
    screenId: "channel_wave_editor"
    title: qsTr("Track Wave Editor")

    property bool isVisible:zynqtgui.current_screen_id === "channel_wave_editor"
    property QtObject selectedChannel: null
    Timer {
        id: selectedChannelThrottle
        interval: 1; running: false; repeat: false;
        onTriggered: {
            component.selectedChannel = null;
            component.selectedChannel = applicationWindow().selectedChannel;
        }
    }
    Connections {
        target: applicationWindow()
        onSelectedChannelChanged: selectedChannelThrottle.restart()
    }
    Connections {
        target: zynqtgui.sketchpad
        onSongChanged: selectedChannelThrottle.restart()
    }
    Connections {
        target: zynqtgui.sketchpad.song
        onIsLoadingChanged: selectedChannelThrottle.restart()
    }
    Component.onCompleted: {
        selectedChannelThrottle.restart()
    }
    property QtObject selectedClip: component.selectedChannel
                                    ? ["synth", "sample-loop"].indexOf(component.selectedChannel.channelAudioType) >= 0
                                        ? component.selectedChannel.getClipsModelByPart(component.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex)
                                        : component.selectedChannel.samples[component.selectedChannel.selectedSlotRow]
                                    : null
    property bool selectedClipHasWav: false
    Timer {
        id: selectedClipHasWavThrottle
        interval: 1; running: false; repeat: false;
        onTriggered: {
            let newHasWav = selectedClip && !selectedClip.isEmpty;
            if (component.selectedClipHasWav != newHasWav) {
                component.selectedClipHasWav = newHasWav;
            }
        }
    }
    onSelectedClipChanged: selectedClipHasWavThrottle.restart()
    onIsVisibleChanged: {
        selectedChannelThrottle.restart();
        selectedClipHasWavThrottle.restart();
    }

    property var cuiaCallback: function(cuia) {
        var returnValue = false;
        switch (cuia) {
            case "SELECT_UP":
                _private.goUp();
                returnValue = true;
                break;
            case "SELECT_DOWN":
                _private.goDown();
                returnValue = true;
                break;
            case "NAVIGATE_LEFT":
                _private.goLeft();
                returnValue = true;
                break;

            case "NAVIGATE_RIGHT":
                _private.goRight();
                returnValue = true;
                break;
            case "KNOB0_UP":
                _private.knob0Up();
                returnValue = true;
                break;
            case "KNOB0_DOWN":
                _private.knob0Down();
                returnValue = true;
                break;
            case "KNOB1_UP":
                _private.knob1Up();
                returnValue = true;
                break;
            case "KNOB1_DOWN":
                _private.knob1Down();
                returnValue = true;
                break;
            case "KNOB2_UP":
                _private.knob2Up();
                returnValue = true;
                break;
            case "KNOB2_DOWN":
                _private.knob2Down();
                returnValue = true;
                break;
            case "KNOB3_UP":
                _private.goRight();
                returnValue = true;
                break;
            case "KNOB3_DOWN":
                _private.goLeft();
                returnValue = true;
                break;
        }
        return returnValue;
    }
    QtObject {
        id: _private
        function goLeft() {
            if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                clipSettingsADSR.previousADSRElement();
            } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                clipSettingsGrainerator.previousElement();
            }
        }
        function goRight() {
            if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                clipSettingsADSR.nextADSRElement();
            } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                clipSettingsGrainerator.nextElement();
            }
        }
        function goUp() {
            if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                if (zynqtgui.altButtonPressed) {
                    for (var i = 0; i < 10; ++i) {
                        clipSettingsADSR.increaseCurrentValue();
                    }
                } else {
                    clipSettingsADSR.increaseCurrentValue();
                }
            } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                if (zynqtgui.altButtonPressed) {
                    for (var i = 0; i < 10; ++i) {
                        clipSettingsGrainerator.increaseCurrentValue();
                    }
                } else {
                    clipSettingsGrainerator.increaseCurrentValue();
                }
            }
        }
        function goDown() {
            if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                if (zynqtgui.altButtonPressed) {
                    for (var i = 0; i < 10; ++i) {
                        clipSettingsADSR.decreaseCurrentValue();
                    }
                } else {
                    clipSettingsADSR.decreaseCurrentValue();
                }
            } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                if (zynqtgui.altButtonPressed) {
                    for (var i = 0; i < 10; ++i) {
                        clipSettingsGrainerator.decreaseCurrentValue();
                    }
                } else {
                    clipSettingsGrainerator.decreaseCurrentValue();
                }
            }
        }
        function knob0Up() {
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    // Increment startPosition by 0.01
                    // Clamp values between 0 and duration
                    component.selectedClip.startPosition = Math.min(Math.max(component.selectedClip.startPosition + 0.01, 0), component.selectedClip.duration)
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.nextADSRElement();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.nextElement();
                }
            }
        }
        function knob0Down() {
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    // Decrement startPosition by 0.01
                    // Clamp values between 0 and duration
                    component.selectedClip.startPosition = Math.min(Math.max(component.selectedClip.startPosition - 0.01, 0), component.selectedClip.duration)
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.previousADSRElement();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.previousElement();
                }
            }
        }
        function knob1Up() {
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    // Increment loopDelta by 0.01
                    // Clamp values between 0 and length
                    component.selectedClip.loopDelta = Math.min(Math.max(component.selectedClip.loopDelta + 0.01, 0), component.selectedClip.secPerBeat * component.selectedClip.length)
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.increaseCurrentValue();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.increaseCurrentValue();
                }
            }
        }
        function knob1Down() {
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    // Decrement loopDelta by 0.01
                    // Clamp values between 0 and length
                    component.selectedClip.loopDelta = Math.min(Math.max(component.selectedClip.loopDelta - 0.01, 0), component.selectedClip.secPerBeat * component.selectedClip.length)
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.decreaseCurrentValue();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.decreaseCurrentValue();
                }
            }
        }
        function knob2Up() {
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    // Increment length by.1
                    // Clamp values between 0 and 64
                    component.selectedClip.length = Math.min(Math.max(component.selectedClip.length + 1, 0), 64)
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                }
            }
        }
        function knob2Down() {
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    // Decrement length by.1
                    // Clamp values between 0 and 64
                    component.selectedClip.length = Math.min(Math.max(component.selectedClip.length - 1, 0), 64)
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                }
            }
        }
    }
    Connections {
        target: applicationWindow()
        enabled: component.isVisible
        onSelectedChannelChanged: {
            if (applicationWindow().selectedChannel) {
                if (applicationWindow().selectedChannel.channelAudioType === "synth") {
                    zynqtgui.callable_ui_action("SCREEN_EDIT_CONTEXTUAL");
                } else if (applicationWindow().selectedChannel.channelAudioType === "external") {
                    zynqtgui.callable_ui_action("SCREEN_EDIT_CONTEXTUAL");
                }
            }
        }
    }

    contextualActions: [
        Kirigami.Action {
            enabled: true
            text: qsTr("Pick Sample")
            onTriggered: {
                applicationWindow().requestSamplePicker();
            }
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.gridUnit

        QQC2.Label {
            Layout.fillHeight: false
            text: component.selectedChannel ? qsTr("Track %1 Clips").arg(component.selectedChannel.id + 1) : ""
            font.pointSize: Kirigami.Units.gridUnit
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.gridUnit

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.gridUnit

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 10
                    color: "#222222"
                    border.width: 1
                    border.color: "#ff999999"
                    radius: 4
                    enabled: component.selectedClipHasWav
                    opacity: enabled ? 1 : 0.5

                    Sketchpad.WaveEditorBar {
                        anchors.fill: parent
                        clip: true
                        controlObj: component.selectedClip
                        controlType: component.selectedChannel
                                    ? ["synth", "sample-loop"].indexOf(component.selectedChannel.channelAudioType) >= 0
                                        ? "bottombar-controltype-clip"
                                        : "bottombar-controltype-channel"
                                    : ""
                        visible: component.selectedClipHasWav
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 10
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: qsTr("General")
                            enabled: component.selectedClipHasWav
                            checked: clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null && clipSettingsSectionView.currentItem.objectName != null && clipSettingsSectionView.currentItem.objectName === "clipSettingsBar"
                            MouseArea {
                                anchors.fill: parent;
                                enabled: component.selectedClipHasWav
                                onClicked: if (clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null) { clipSettingsSectionView.currentItem = clipSettingsBar }
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: qsTr("Envelope")
                            enabled: component.selectedClipHasWav
                            checked: clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null && clipSettingsSectionView.currentItem.objectName != null && clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR"
                            MouseArea {
                                anchors.fill: parent;
                                enabled: component.selectedClipHasWav
                                onClicked: if (clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null) { clipSettingsSectionView.currentItem = clipSettingsADSR }
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: qsTr("Granular")
                            visible: clipSettingsGrainerator.clip && (clipSettingsGrainerator.clip.playbackStyle == Zynthbox.ClipAudioSource.GranularLoopingPlaybackStyle || clipSettingsGrainerator.clip.playbackStyle == Zynthbox.ClipAudioSource.GranularNonLoopingPlaybackStyle)
                            enabled: component.selectedClipHasWav
                            checked: clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null && clipSettingsSectionView.currentItem.objectName != null && clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator"
                            MouseArea {
                                anchors.fill: parent;
                                enabled: component.selectedClipHasWav
                                onClicked: if (clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null) { clipSettingsSectionView.currentItem = clipSettingsGrainerator }
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: qsTr("Clip Info")
                            enabled: component.selectedClipHasWav
                            checked: clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null && clipSettingsSectionView.currentItem.objectName != null && clipSettingsSectionView.currentItem.objectName === "clipSettingsInfoView"
                            MouseArea {
                                anchors.fill: parent;
                                enabled: component.selectedClipHasWav
                                onClicked: if (clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null) { clipSettingsSectionView.currentItem = clipSettingsInfoView }
                            }
                        }
                    }
                    Rectangle {
                        id: clipSettingsSectionView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                        color: "#222222"
                        border.width: 1
                        border.color: "#ff999999"
                        radius: 4
                        enabled: component.selectedClipHasWav
                        opacity: enabled ? 1 : 0.5
                        property Item currentItem: clipSettingsBar
                        Connections {
                            target: component
                            onSelectedClipChanged: {
                                clipSettingsBarControlObjThrottle.restart();
                                clipSettingsADSRClipThrottle.restart();
                                clipSettingsGraineratorClipThrottle.restart();
                                clipSettingsInfoViewClipThrottle.restart();
                            }
                        }
                        Sketchpad.ClipSettingsBar {
                            id: clipSettingsBar
                            objectName: "clipSettingsBar"
                            visible: clipSettingsSectionView.visible && clipSettingsSectionView.currentItem.objectName === objectName
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.gridUnit
                            controlObjIsManual: true
                            controlObj: component.selectedClip
                            Timer {
                                id: clipSettingsBarControlObjThrottle
                                interval: 1; running: false; repeat: false;
                                onTriggered: {
                                    clipSettingsBar.controlObj = component.selectedClip;
                                }
                            }
                            controlType: component.selectedChannel
                                        ? ["synth", "sample-loop"].indexOf(component.selectedChannel.channelAudioType) >= 0
                                            ? "bottombar-controltype-clip"
                                            : "bottombar-controltype-channel"
                                        : ""
                            showCopyPasteButtons: false
                        }
                        Zynthian.ADSRClipView {
                            id: clipSettingsADSR
                            objectName: "clipSettingsADSR"
                            visible: clipSettingsSectionView.visible && clipSettingsSectionView.currentItem.objectName === objectName
                            anchors.fill: parent
                            clip: null
                            Timer {
                                id: clipSettingsADSRClipThrottle
                                interval: 1; running: false; repeat: false;
                                onTriggered: {
                                    clipSettingsADSR.clip = Zynthbox.PlayGridManager.getClipById(component.selectedClip.cppObjId);
                                }
                            }
                            onSaveMetadata: component.selectedClip.saveMetadata();
                        }
                        Zynthian.ClipGraineratorSettings {
                            id: clipSettingsGrainerator
                            objectName: "clipSettingsGrainerator"
                            visible: clipSettingsSectionView.visible && clipSettingsSectionView.currentItem.objectName === objectName
                            anchors.fill: parent;
                            clip: null
                            Timer {
                                id: clipSettingsGraineratorClipThrottle
                                interval: 1; running: false; repeat: false;
                                onTriggered: {
                                    clipSettingsGrainerator.clip = Zynthbox.PlayGridManager.getClipById(component.selectedClip.cppObjId);
                                }
                            }
                            onSaveMetadata: component.selectedClip.saveMetadata();
                        }
                        Zynthian.ClipInfoView {
                            id: clipSettingsInfoView
                            objectName: "clipSettingsInfoView"
                            visible: clipSettingsSectionView.visible && clipSettingsSectionView.currentItem.objectName === objectName
                            anchors.fill: parent
                            clip: null
                            Timer {
                                id: clipSettingsInfoViewClipThrottle
                                interval: 1; running: false; repeat: false;
                                onTriggered: {
                                    clipSettingsInfoView.clip = Zynthbox.PlayGridManager.getClipById(component.selectedClip.cppObjId);
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                id: partBar

                spacing: 1
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6

                Repeater {
                    model: component.selectedChannel ? 5 : 0
                    delegate: Rectangle {
                        id: partDelegate

                        property QtObject clip: ["synth", "sample-loop"].indexOf(component.selectedChannel.channelAudioType) >= 0
                                                            ? component.selectedChannel.getClipsModelByPart(index).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex)
                                                            : component.selectedChannel.samples[index]
                        property bool clipHasWav: partDelegate.clip && !partDelegate.isEmpty

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#000000"
                        border{
                            color: Kirigami.Theme.highlightColor
                            width: index === component.selectedChannel.selectedSlotRow
                                    ? 1
                                    : 0
                        }
                        Zynthbox.WaveFormItem {
                            anchors.fill: parent
                            color: Kirigami.Theme.textColor
                            source: partDelegate.clip ? partDelegate.clip.path : ""

                            visible: partDelegate.clipHasWav
                        }
                        Rectangle {
                            height: 16
                            anchors {
                                left: parent.left
                                top: parent.top
                                right: parent.right
                            }
                            color: "#99888888"
                            visible: detailsLabel.text && detailsLabel.text.trim().length > 0

                            QQC2.Label {
                                id: detailsLabel

                                anchors.centerIn: parent
                                width: parent.width - 4
                                elide: "ElideRight"
                                horizontalAlignment: "AlignHCenter"
                                font.pointSize: 8
                                text: partDelegate.clipHasWav ? partDelegate.clip.path.split("/").pop() : ""
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                component.selectedChannel.selectedPart = index;
                                component.selectedChannel.selectedSlotRow = index;
                            }
                        }
                    }
                }
            }
        }
    }
}
