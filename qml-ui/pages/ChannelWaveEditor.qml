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
    title: qsTr("Channel Wave Editor")

    property bool isVisible:zynqtgui.current_screen_id === "channel_wave_editor"
    property QtObject selectedChannel: applicationWindow().selectedChannel
    property QtObject selectedClip: ["synth", "sample-loop"].indexOf(component.selectedChannel.channelAudioType) >= 0
                                        ? component.selectedChannel.getClipsModelByPart(selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex)
                                        : component.selectedChannel.samples[selectedChannel.selectedSlotRow]
    property bool selectedClipHasWav: selectedClip && selectedClip.path && selectedClip.path.length > 0


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
        }
        return returnValue;
    }
    Connections {
        target: zynqtgui.channel_wave_editor
        onBigKnobValueChanged: {
            if (zynqtgui.channel_wave_editor.bigKnobValue < 0) {
                for (var i = zynqtgui.channel_wave_editor.bigKnobValue; i < 0; ++i) {
                    _private.goLeft();
                }
            } else if (zynqtgui.channel_wave_editor.bigKnobValue > 0) {
                for (var i = zynqtgui.channel_wave_editor.bigKnobValue; i > 0; --i) {
                    _private.goRight();
                }
            } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
        }
        onKnob1ValueChanged: {
            if (zynqtgui.channel_wave_editor.knob1Value < 0) {
                for (var i = zynqtgui.channel_wave_editor.knob1Value; i < 0; ++i) {
                    _private.knob1Down();
                }
            } else if (zynqtgui.channel_wave_editor.knob1Value > 0) {
                for (var i = zynqtgui.channel_wave_editor.knob1Value; i > 0; --i) {
                    _private.knob1Up();
                }
            } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
        }
        onKnob2ValueChanged: {
            if (zynqtgui.channel_wave_editor.knob2Value < 0) {
                for (var i = zynqtgui.channel_wave_editor.knob2Value; i < 0; ++i) {
                    _private.knob2Down();
                }
            } else if (zynqtgui.channel_wave_editor.knob2Value > 0) {
                for (var i = zynqtgui.channel_wave_editor.knob2Value; i > 0; --i) {
                    _private.knob2Up();
                }
            } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
        }
        onKnob3ValueChanged: {
            if (zynqtgui.channel_wave_editor.knob3Value < 0) {
                for (var i = zynqtgui.channel_wave_editor.knob3Value; i < 0; ++i) {
                    _private.knob3Down();
                }
            } else if (zynqtgui.channel_wave_editor.knob3Value > 0) {
                for (var i = zynqtgui.channel_wave_editor.knob3Value; i > 0; --i) {
                    _private.knob3Up();
                }
            } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
        }
    }
    QtObject {
        id: _private
        function goLeft() {
            if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                clipSettingsADSR.previousADSRElement();
            }
        }
        function goRight() {
            if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                clipSettingsADSR.nextADSRElement();
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
            }
        }
        function knob1Up() {
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    // Increment startPosition by 0.01
                    // Clamp values between 0 and duration
                    component.selectedClip.startPosition = Math.min(Math.max(component.selectedClip.startPosition + 0.01, 0), component.selectedClip.duration)
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.nextADSRElement();
                }
            }
        }
        function knob1Down() {
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    // Decrement startPosition by 0.01
                    // Clamp values between 0 and duration
                    component.selectedClip.startPosition = Math.min(Math.max(component.selectedClip.startPosition - 0.01, 0), component.selectedClip.duration)
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.previousADSRElement();
                }
            }
        }
        function knob2Up() {
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    // Increment loopDelta by 0.01
                    // Clamp values between 0 and length
                    component.selectedClip.loopDelta = Math.min(Math.max(component.selectedClip.loopDelta + 0.01, 0), component.selectedClip.secPerBeat * component.selectedClip.length)
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.increaseCurrentValue();
                }
            }
        }
        function knob2Down() {
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    // Decrement loopDelta by 0.01
                    // Clamp values between 0 and length
                    component.selectedClip.loopDelta = Math.min(Math.max(component.selectedClip.loopDelta - 0.01, 0), component.selectedClip.secPerBeat * component.selectedClip.length)
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.decreaseCurrentValue();
                }
            }
        }
        function knob3Up() {
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    // Increment length by.1
                    // Clamp values between 0 and 64
                    component.selectedClip.length = Math.min(Math.max(component.selectedClip.length + 1, 0), 64)
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                }
            }
        }
        function knob3Down() {
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    // Decrement length by.1
                    // Clamp values between 0 and 64
                    component.selectedClip.length = Math.min(Math.max(component.selectedClip.length - 1, 0), 64)
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
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
            text: qsTr("Channel %1 Clips").arg(component.selectedChannel.id + 1)
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
                        controlType: ["synth", "sample-loop"].indexOf(component.selectedChannel.channelAudioType) >= 0
                                        ? "bottombar-controltype-clip"
                                        : "bottombar-controltype-channel"
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
                            checked: clipSettingsSectionView.currentItem.objectName === "clipSettingsBar"
                            MouseArea {
                                anchors.fill: parent;
                                enabled: component.selectedClipHasWav
                                onClicked: clipSettingsSectionView.currentItem = clipSettingsBar
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: qsTr("ADSR\nEnvelope")
                            enabled: component.selectedClipHasWav
                            checked: clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR"
                            MouseArea {
                                anchors.fill: parent;
                                enabled: component.selectedClipHasWav
                                onClicked: clipSettingsSectionView.currentItem = clipSettingsADSR
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
                        Sketchpad.ClipSettingsBar {
                            id: clipSettingsBar
                            objectName: "clipSettingsBar"
                            visible: clipSettingsSectionView.visible && clipSettingsSectionView.currentItem.objectName === objectName
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.gridUnit
                            controlObj: component.selectedClip
                            controlType: ["synth", "sample-loop"].indexOf(component.selectedChannel.channelAudioType) >= 0
                                            ? "bottombar-controltype-clip"
                                            : "bottombar-controltype-channel"
                            showCopyPasteButtons: false
                            enabled: component.selectedClipHasWav
                        }
                        Zynthian.ADSRClipView {
                            id: clipSettingsADSR
                            objectName: "clipSettingsADSR"
                            visible: clipSettingsSectionView.visible && clipSettingsSectionView.currentItem.objectName === objectName
                            anchors.fill: parent
                            enabled: component.selectedClipHasWav
                            clip: Zynthbox.PlayGridManager.getClipById(component.selectedClip.cppObjId)
                            onSaveMetadata: component.selectedClip.saveMetadata();
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
                        property bool clipHasWav: partDelegate.clip && partDelegate.clip.path && partDelegate.clip.path.length > 0

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
