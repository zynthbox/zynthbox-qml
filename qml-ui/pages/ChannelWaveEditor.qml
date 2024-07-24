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
                                    ? ["synth", "sample-loop"].indexOf(component.selectedChannel.trackType) >= 0
                                        ? component.selectedChannel.getClipsModelByPart(component.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                                        : component.selectedChannel.samples[component.selectedChannel.selectedSlotRow]
                                    : null
    property QtObject cppClipObject: component.selectedClip && component.selectedClip.hasOwnProperty("cppObjId")
                                        ? Zynthbox.PlayGridManager.getClipById(component.selectedClip.cppObjId)
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
                returnValue = _private.goUp(cuia);
                break;
            case "SELECT_DOWN":
                returnValue = _private.goDown(cuia);
                break;
            case "NAVIGATE_LEFT":
                returnValue = _private.goLeft(cuia);
                break;
            case "NAVIGATE_RIGHT":
                returnValue = _private.goRight(cuia);
                break;
            case "KNOB0_TOUCHED":
                returnValue = _private.knob0Touched(cuia);
                break;
            case "KNOB0_UP":
                returnValue = _private.knob0Up(cuia);
                break;
            case "KNOB0_DOWN":
                returnValue = _private.knob0Down(cuia);
                break;
            case "KNOB1_TOUCHED":
                returnValue = _private.knob1Touched(cuia);
                break;
            case "KNOB1_UP":
                returnValue = _private.knob1Up(cuia);
                break;
            case "KNOB1_DOWN":
                returnValue = _private.knob1Down(cuia);
                break;
            case "KNOB2_TOUCHED":
                returnValue = _private.knob2Touched(cuia);
                break;
            case "KNOB2_UP":
                returnValue = _private.knob2Up(cuia);
                break;
            case "KNOB2_DOWN":
                returnValue = _private.knob2Down(cuia);
                break;
            case "KNOB3_TOUCHED":
                returnValue = _private.knob3Touched(cuia);
                break;
            case "KNOB3_UP":
                returnValue = _private.goRight(cuia);
                break;
            case "KNOB3_DOWN":
                returnValue = _private.goLeft(cuia);
                break;
        }
        return returnValue;
    }
    QtObject {
        id: _private
        function goLeft(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.previousADSRElement();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.previousElement();
                }
            }
            return returnValue;
        }
        function goRight(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.nextADSRElement();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.nextElement();
                }
            }
            return returnValue;
        }
        function goUp(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
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
            return returnValue;
        }
        function goDown(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
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
            return returnValue;
        }
        function knob0Touched(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                }
            }
            return returnValue;
        }
        function knob0Up(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.nextADSRElement();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.nextElement();
                }
            }
            return returnValue;
        }
        function knob0Down(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.previousADSRElement();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.previousElement();
                }
            }
            return returnValue;
        }
        function knob1Touched(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                }
            }
            return returnValue;
        }
        function knob1Up(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.increaseCurrentValue();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.increaseCurrentValue();
                }
            }
            return returnValue;
        }
        function knob1Down(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.decreaseCurrentValue();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.decreaseCurrentValue();
                }
            }
            return returnValue;
        }
        function knob2Touched(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                }
            }
            return returnValue;
        }
        function knob2Up(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                }
            }
            return returnValue;
        }
        function knob2Down(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                }
            }
            return returnValue;
        }
        function knob3Touched(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                }
            }
            return returnValue;
        }
    }
    Connections {
        target: applicationWindow()
        enabled: component.isVisible
        onSelectedChannelChanged: {
            if (applicationWindow().selectedChannel) {
                if (applicationWindow().selectedChannel.trackType === "synth") {
                    zynqtgui.callable_ui_action("SCREEN_EDIT_CONTEXTUAL");
                } else if (applicationWindow().selectedChannel.trackType === "external") {
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
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            Layout.fillHeight: false
            text: component.selectedChannel ? qsTr("Track %1 Clips").arg(component.selectedChannel.id + 1) : ""
            font.pointSize: Kirigami.Units.gridUnit
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                spacing: 0
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.8
                    visible: component.selectedChannel && component.selectedChannel.trackType !== "sample-loop"
                    rows: 3
                    columns: 2
                    rowSpacing: 0
                    columnSpacing: 0
                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                        text: "+1"
                        onClicked: {
                            testNotePad.midiNote = Math.min(127, testNotePad.midiNote + 1);
                        }
                    }
                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                        text: "+12"
                        onClicked: {
                            testNotePad.midiNote = Math.min(127, testNotePad.midiNote + 12);
                        }
                    }
                    Zynthian.NotePad {
                        id: testNotePad
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                        Layout.columnSpan: 2
                        positionalVelocity: true
                        highlightOctaveStart: false
                        property int midiNote: 60
                        note: component.selectedChannel ? Zynthbox.PlayGridManager.getNote(midiNote, component.selectedChannel.id) : null
                    }
                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                        text: "-1"
                        onClicked: {
                            testNotePad.midiNote = Math.max(0, testNotePad.midiNote - 1);
                        }
                    }
                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                        text: "-12"
                        onClicked: {
                            testNotePad.midiNote = Math.max(0, testNotePad.midiNote - 12);
                        }
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.8
                    visible: component.selectedChannel && component.selectedChannel.trackType === "sample-loop"
                    icon.name: component.cppClipObject && component.cppClipObject.isPlaying ? "media-playback-stop" : "media-playback-start"
                    onClicked: {
                        if (component.cppClipObject.isPlaying) {
                            component.cppClipObject.stop();
                        } else {
                            component.cppClipObject.play(false, component.selectedChannel.id);
                        }
                    }
                }
                Item {
                    Layout.fillWidth: true
                    Layout.minimumHeight: Kirigami.Units.largeSpacing
                    Layout.maximumHeight: Kirigami.Units.largeSpacing
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit
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
                    Layout.preferredHeight: Kirigami.Units.gridUnit
                    text: qsTr("Voices/EQ")
                    enabled: component.selectedClipHasWav
                    checked: clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null && clipSettingsSectionView.currentItem.objectName != null && clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices"
                    MouseArea {
                        anchors.fill: parent;
                        enabled: component.selectedClipHasWav
                        onClicked: if (clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null) { clipSettingsSectionView.currentItem = clipSettingsVoices }
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit
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
                    Layout.preferredHeight: Kirigami.Units.gridUnit
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
                    Layout.preferredHeight: Kirigami.Units.gridUnit
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

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 9
                    color: "#222222"
                    border.width: 1
                    border.color: "#ff999999"
                    radius: 4
                    enabled: component.selectedClipHasWav
                    opacity: enabled ? 1 : 0.5

                    Sketchpad.WaveEditorBar {
                        id: waveBar
                        anchors.fill: parent
                        internalMargin: 0
                        clip: true
                        controlObj: component.selectedClip
                        controlType: component.selectedChannel
                                    ? ["synth", "sample-loop"].indexOf(component.selectedChannel.trackType) >= 0
                                        ? "bottombar-controltype-clip"
                                        : "bottombar-controltype-channel"
                                    : ""
                        visible: component.selectedClipHasWav
                    }
                }
                Rectangle {
                    id: clipSettingsSectionView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 11
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
                            clipSettingsVoicesClipThrottle.restart();
                            clipSettingsADSRClipThrottle.restart();
                            clipSettingsGraineratorClipThrottle.restart();
                            clipSettingsInfoViewClipThrottle.restart();
                        }
                    }
                    Sketchpad.ClipSettingsBar {
                        id: clipSettingsBar
                        objectName: "clipSettingsBar"
                        visible: clipSettingsSectionView.visible && clipSettingsSectionView.currentItem.objectName === objectName
                        anchors {
                            fill: parent
                            margins: Kirigami.Units.largeSpacing
                            topMargin: 0
                        }
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
                                    ? ["synth", "sample-loop"].indexOf(component.selectedChannel.trackType) >= 0
                                        ? "bottombar-controltype-clip"
                                        : "bottombar-controltype-channel"
                                    : ""
                        showCopyPasteButtons: false
                    }
                    Zynthian.ClipVoicesSettings {
                        id: clipSettingsVoices
                        objectName: "clipSettingsVoices"
                        visible: clipSettingsSectionView.visible && clipSettingsSectionView.currentItem.objectName === objectName
                        anchors.fill: parent
                        clip: null
                        Timer {
                            id: clipSettingsVoicesClipThrottle
                            interval: 1; running: false; repeat: false;
                            onTriggered: {
                                clipSettingsVoices.clip = component.selectedClip;
                                clipSettingsVoices.cppClipObject = component.cppClipObject;
                            }
                        }
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
                                clipSettingsADSR.clip = component.selectedClip;
                            }
                        }
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
                                clipSettingsGrainerator.clip = component.selectedClip;
                            }
                        }
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
                                clipSettingsInfoView.clip = component.cppClipObject;
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

                        property QtObject clip: ["synth", "sample-loop"].indexOf(component.selectedChannel.trackType) >= 0
                                                            ? component.selectedChannel.getClipsModelByPart(index).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                                                            : component.selectedChannel.samples[index]
                        property QtObject cppClipObject: partDelegate.clip && partDelegate.clip.hasOwnProperty("cppObjId")
                                                            ? Zynthbox.PlayGridManager.getClipById(partDelegate.clip.cppObjId)
                                                            : null
                        property bool clipHasWav: partDelegate.clip && !partDelegate.isEmpty

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#000000"
                        border{
                            color: index === component.selectedChannel.selectedSlotRow ? Kirigami.Theme.highlightColor : "transparent"
                            width: 1
                        }
                        Zynthbox.WaveFormItem {
                            anchors.fill: parent
                            color: Kirigami.Theme.textColor
                            source: partDelegate.clip ? partDelegate.clip.path : ""
                            start: partDelegate.cppClipObject ? partDelegate.cppClipObject.startPositionSeconds : 0
                            end: partDelegate.cppClipObject ? partDelegate.cppClipObject.startPositionSeconds + partDelegate.cppClipObject.lengthSeconds : 0

                            visible: partDelegate.clipHasWav
                        }
                        Rectangle {
                            height: 16
                            anchors {
                                left: parent.left
                                top: parent.top
                                right: parent.right
                                margins: 1
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
