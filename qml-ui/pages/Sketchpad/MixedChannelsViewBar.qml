/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian slots bar page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Marco MArtin <mart@kde.org>

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
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls.Styles 1.4

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Rectangle {
    id: root

    readonly property QtObject song: zynqtgui.sketchpad.song
    property QtObject selectedChannel: null
    Timer {
        id: selectedChannelThrottle
        interval: 0; running: false; repeat: false;
        onTriggered: {
            root.selectedChannel = applicationWindow().selectedChannel;
        }
    }
    Connections {
        target: applicationWindow()
        onSelectedChannelChanged: selectedChannelThrottle.restart()
    }
    Component.onCompleted: {
        selectedChannelThrottle.restart()
    }

    property QtObject sequence: root.selectedChannel ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName) : null
    property QtObject pattern: root.sequence && root.selectedChannel ? root.sequence.getByPart(root.selectedChannel.id, root.selectedChannel.selectedPart) : null


    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    function cuiaCallback(cuia) {
        var returnValue = false;
        var selectedMidiChannel = root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow]
        console.log(`MixedChannelsViewBar : cuia: ${cuia}, altButtonPressed: ${zynqtgui.altButtonPressed}`)
        switch (cuia) {
            case "NAVIGATE_LEFT":
                if (zynqtgui.session_dashboard.selectedChannel > 0) {
                    zynqtgui.session_dashboard.selectedChannel -= 1;
                }
                returnValue = true;
                break;

            case "NAVIGATE_RIGHT":
                if (zynqtgui.session_dashboard.selectedChannel < 9) {
                    zynqtgui.session_dashboard.selectedChannel += 1;
                }
                returnValue = true;
                break;

            case "SELECT_UP":
                if (root.selectedChannel.channelAudioType === "sample-trig") {
                    if (root.selectedChannel.selectedSlotRow > 0) {
                        root.selectedChannel.selectedSlotRow -= 1;
                    }
                    returnValue = true;
                }
                break;

            case "SELECT_DOWN":
                if (root.selectedChannel.channelAudioType === "sample-trig") {
                    if (root.selectedChannel.selectedSlotRow < 4) {
                        root.selectedChannel.selectedSlotRow += 1;
                    }
                    returnValue = true;
                }
                break;
            case "KNOB0_UP":
                pageManager.getPage("sketchpad").updateSelectedChannelVolume(1, true)
                returnValue = true;
                break;
            case "KNOB0_DOWN":
                pageManager.getPage("sketchpad").updateSelectedChannelVolume(-1, true)
                returnValue = true;
                break;
            case "KNOB1_UP":
                if (root.selectedChannel.channelAudioType == "synth") {
                    pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(1)
                }
                returnValue = true;
                break;
            case "KNOB1_DOWN":
                if (root.selectedChannel.channelAudioType == "synth") {
                    pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(-1)
                }
                returnValue = true;
                break;
            case "KNOB2_UP":
                if (root.selectedChannel.channelAudioType == "synth") {
                    pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(1)
                }
                returnValue = true;
                break;
            case "KNOB2_DOWN":
                if (root.selectedChannel.channelAudioType == "synth") {
                    pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(-1)
                }
                returnValue = true;
                break;
        }
        return returnValue;
    }

    Zynthian.Popup {
        id: channelKeyZoneSetup
        parent: QQC2.Overlay.overlay
        y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
        x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
        ChannelKeyZoneSetup {
            id: channelKeyZoneSetupItem
            anchors.fill: parent
            implicitWidth: root.width
            implicitHeight: root.height
            selectedChannel: null
            Timer {
                id: keyZoneSetupSelectedChannelThrottle
                interval: 1; running: false; repeat: false;
                onTriggered: {
                    channelKeyZoneSetupItem.selectedChannel = zynqtgui.sketchpad.song ? zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.session_dashboard.selectedChannel) : null;
                }
            }
            Connections {
                target: zynqtgui.session_dashboard
                onSelected_channel_changed: keyZoneSetupSelectedChannelThrottle.restart()
            }
        }
    }

    BouncePopup {
        id: bouncePopup
    }

    GridLayout {
        rows: 1
        anchors.fill: parent

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true

            QQC2.ButtonGroup {
                buttons: tabButtons.children
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 1

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 1

                    QQC2.ButtonGroup {
                        buttons: buttonsColumn.children
                    }

                    BottomStackTabs {
                        id: buttonsColumn
                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 6
                    }

                    ColumnLayout {
                        id: contentColumn
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: Kirigami.Units.gridUnit / 2

                        RowLayout {
                            id: tabButtons
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                            EditableHeader {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                controlObj: root.selectedChannel
                                controlType: "bottombar-controltype-channel"

                                text: qsTr("Channel: %1").arg(controlObj ? controlObj.name : "")
                            }

                            QQC2.Button {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                                Layout.fillHeight: true
                                checkable: true
                                checked: root.selectedChannel.channelAudioType === "synth"
                                text: qsTr("Synth")
                                onClicked: root.selectedChannel.channelAudioType = "synth"
                            }
                            QQC2.Button {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                                Layout.fillHeight: true
                                checkable: true
                                checked: root.selectedChannel.channelAudioType.startsWith("sample-")
                                text: qsTr("Samples")
                                onClicked: root.selectedChannel.channelAudioType = "sample-trig"
                            }
                            QQC2.Button {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                                Layout.fillHeight: true
                                checkable: true
                                checked: root.selectedChannel.channelAudioType === "external"
                                text: qsTr("External")
                                onClicked: root.selectedChannel.channelAudioType = "external"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Kirigami.Units.gridUnit

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5

                                RowLayout {
                                    anchors.fill: parent

                                    RowLayout {
                                        visible: root.selectedChannel.channelAudioType.startsWith("sample-")
                                        Layout.fillHeight: true
                                        spacing: 0

                                        QQC2.Button {
                                            Layout.fillHeight: true
                                            text: "Audio"
                                            checked: root.selectedChannel && root.selectedChannel.channelAudioType === "sample-loop"
                                            onClicked: {
                                                root.selectedChannel.channelAudioType = "sample-loop"
                                            }
                                        }
                                        QQC2.Button {
                                            Layout.fillHeight: true
                                            text: "Trig"
                                            checked: root.selectedChannel && root.selectedChannel.channelAudioType === "sample-trig"
                                            onClicked: {
                                                root.selectedChannel.channelAudioType = "sample-trig"
                                            }
                                        }
                                        QQC2.Button {
                                            Layout.fillHeight: true
                                            text: "Slice"
                                            checked: root.selectedChannel && root.selectedChannel.channelAudioType === "sample-slice"
                                            onClicked: {
                                                root.selectedChannel.channelAudioType = "sample-slice"
                                            }
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

//                                    RowLayout {
//                                        Layout.fillHeight: true
//                                        visible: root.selectedChannel.channelAudioType === "external"

//                                        QQC2.Button {
//                                            Layout.fillHeight: true
//                                            text: qsTr("External Midi Channel: %1").arg(root.selectedChannel ? (root.selectedChannel.externalMidiChannel > -1 ? root.selectedChannel.externalMidiChannel + 1 : root.selectedChannel.id + 1) : "")
//                                            onClicked: {
//                                                externalMidiChannelPicker.pickChannel(root.selectedChannel);
//                                            }
//                                        }
//                                        Item {
//                                            Layout.fillWidth: false
//                                            Layout.fillHeight: false
//                                            Layout.preferredWidth: Kirigami.Units.gridUnit
//                                        }
//                                    }

                                    RowLayout {
                                        Layout.fillHeight: true
                                        visible: root.selectedChannel.channelAudioType === "sample-trig"

                                        QQC2.Label {
                                            Layout.fillHeight: true
                                            text: "Key Split"
                                        }
                                        RowLayout {
                                            Layout.fillHeight: true
                                            spacing: 0
                                            QQC2.Button {
                                                Layout.fillHeight: true
                                                text: "Off"
                                                checked: root.selectedChannel && root.selectedChannel.keyZoneMode === "all-full"
                                                onClicked: {
                                                    root.selectedChannel.keyZoneMode = "all-full";
                                                }
                                            }
//                                            QQC2.Button {
//                                                Layout.fillHeight: true
//                                                text: "Auto"
//                                                checked: root.selectedChannel && root.selectedChannel.keyZoneMode === "split-full"
//                                                onClicked: {
//                                                    root.selectedChannel.keyZoneMode = "split-full";
//                                                }
//                                            }
                                            QQC2.Button {
                                                Layout.fillHeight: true
                                                text: "Narrow"
                                                checked: root.selectedChannel && root.selectedChannel.keyZoneMode === "split-narrow"
                                                onClicked: {
                                                    root.selectedChannel.keyZoneMode = "split-narrow";
                                                }
                                            }
                                        }
//                                        QQC2.Button {
//                                            Layout.fillHeight: true
//                                            icon.name: "timeline-use-zone-on"
//                                            onClicked: {
//                                                channelKeyZoneSetup.open();
//                                            }
//                                        }
                                        Item {
                                            Layout.fillWidth: false
                                            Layout.fillHeight: false
                                            Layout.preferredWidth: Kirigami.Units.gridUnit
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillHeight: true
                                        visible: root.selectedChannel.channelAudioType === "sample-trig" ||
                                                 root.selectedChannel.channelAudioType === "sample-slice" ||
                                                 root.selectedChannel.channelAudioType === "synth"
                                        QQC2.Button {
                                            Layout.fillHeight: true
                                            text: "Bounce To Audio"
                                            onClicked: {
                                                bouncePopup.bounce(zynqtgui.sketchpad.song.scenesModel.selectedTrackName, root.selectedChannel);
                                            }
                                        }
                                        Item {
                                            Layout.fillWidth: false
                                            Layout.fillHeight: false
                                            Layout.preferredWidth: Kirigami.Units.gridUnit
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                                Binding { //Optimization
                                    target: synthRepeater
                                    property: "synthData"
                                    delayed: true
                                    value: root.selectedChannel.channelAudioType === "synth"
                                                ? root.selectedChannel.chainedSoundsNames
                                                : root.selectedChannel.channelAudioType === "sample-trig" ||
                                                root.selectedChannel.channelAudioType === "sample-slice"
                                                    ? root.selectedChannel.samples
                                                    : root.selectedChannel.channelAudioType === "sample-loop"
                                                        ? [root.selectedChannel.getClipsModelByPart(root.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex), null, null, null, null]
                                                        : root.selectedChannel.channelAudioType === "external"
                                                            ? [qsTr("Midi Channel: %1").arg(root.selectedChannel ? (root.selectedChannel.externalMidiChannel > -1 ? root.selectedChannel.externalMidiChannel + 1 : root.selectedChannel.id + 1) : ""), null, null, null, null]
                                                            : [null, null, null, null, null]

                                }

                                Repeater {
                                    id: synthRepeater

                                    model: 5
                                    property var synthData: [null, null, null, null, null]
                                    delegate: Rectangle {
                                        property bool highlighted: root.selectedChannel.channelAudioType === "sample-loop" ||
                                                                   root.selectedChannel.channelAudioType === "sample-slice" ||
                                                                   root.selectedChannel.channelAudioType === "external"
                                                                    ? index === 0
                                                                    : root.selectedChannel.selectedSlotRow === index

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                                        border.color: highlighted ? Kirigami.Theme.highlightColor : "transparent"
                                        border.width: 2
                                        color: "transparent"
                                        radius: 4

                                        Rectangle {
                                            id: delegate

                                            property var volumeControlObj: null
                                            property real volume: volumeControlObj != null ? volumeControlObj.value/100 : 0
                                            Timer {
                                                id: volumeControlObjThrottle
                                                interval: 1; running: false; repeat: false;
                                                onTriggered: {
                                                    delegate.volumeControlObj = zynqtgui.fixed_layers.volumeControllers[root.selectedChannel.chainedSounds[index]];
                                                }
                                            }
                                            Connections {
                                                target: zynqtgui.fixed_layers
                                                onVolumeControllersChanged: volumeControlObjThrottle.restart()
                                            }
                                            Connections {
                                                target: root
                                                onSelectedChannelChanged: volumeControlObjThrottle.restart()
                                            }
                                            Connections {
                                                target: root.selectedChannel
                                                onChained_sounds_changed: volumeControlObjThrottle.restart()
                                            }

                                            anchors.fill: parent
                                            anchors.margins: 4

                                            Kirigami.Theme.inherit: false
                                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                            color: Kirigami.Theme.backgroundColor

                                            border.color: "#ff999999"
                                            border.width: 1
                                            radius: 4

                                            // For loop, slice and external modes only first slot is visible.
                                            // For other modes all slots are visible
                                            enabled: root.selectedChannel.channelAudioType === "sample-loop" ||
                                                     root.selectedChannel.channelAudioType === "sample-slice" ||
                                                     root.selectedChannel.channelAudioType === "external"
                                                        ? index === 0
                                                        : true
                                            opacity: enabled ? 1 : 0
                                            visible: enabled

                                            Rectangle {
                                                width: parent.width * delegate.volume
                                                anchors {
                                                    left: parent.left
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                visible: root.selectedChannel.channelAudioType === "synth" &&
                                                         synthNameLabel.text.trim().length > 0

                                                color: Kirigami.Theme.highlightColor
                                            }

                                            QQC2.Label {
                                                id: synthNameLabel
                                                anchors {
                                                    verticalCenter: parent.verticalCenter
                                                    left: parent.left
                                                    right: parent.right
                                                    leftMargin: Kirigami.Units.gridUnit*0.5
                                                    rightMargin: Kirigami.Units.gridUnit*0.5
                                                }
                                                horizontalAlignment: Text.AlignLeft
                                                text: root.selectedChannel.channelAudioType === "synth" && synthRepeater.synthData[index] && synthRepeater.synthData[index].className == null // Check if synthRepeater.synthData[index] is not a channel/clip object by checking if it has the className property
                                                        ? synthRepeater.synthData[index]
                                                        : (root.selectedChannel.channelAudioType === "sample-trig" ||
                                                          root.selectedChannel.channelAudioType === "sample-slice" ||
                                                          root.selectedChannel.channelAudioType === "sample-loop") &&
                                                          synthRepeater.synthData[index]
                                                            ? synthRepeater.synthData[index].path
                                                              ? synthRepeater.synthData[index].path.split("/").pop()
                                                              : ""
                                                            : root.selectedChannel.channelAudioType === "external"
                                                                ? synthRepeater.synthData[index]
                                                                : ""

                                                elide: "ElideRight"
                                            }

                                            MouseArea {
                                                id: delegateMouseArea
                                                property real initialMouseX
                                                property bool dragHappened: false

                                                anchors.fill: parent
                                                onPressed: {
                                                    delegateMouseArea.initialMouseX = mouse.x
                                                }
                                                onClicked: {
                                                    if (root.selectedChannel.channelAudioType === "sample-loop" ||
                                                        root.selectedChannel.channelAudioType === "external"
                                                    ) {
                                                        // If channel type is sample-loop or external, then it has only 1 slot visible
                                                        // and the respective selectedSlotRow is already selected. Hence directly handle item click
                                                        bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                                                    } else if (root.selectedChannel.channelAudioType === "sample-slice") {
                                                        // If channel type is sample-slice, then it has only 1 slot visible and it is always slot 0
                                                        // Hence set selectedSlotRow to 0 and call handle item click
                                                        root.selectedChannel.selectedSlotRow  = 0
                                                        bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                                                    } else {
                                                        // For any other channel modes, set selectedSlotRow first if not already set
                                                        if (index !== root.selectedChannel.selectedSlotRow) {
                                                            root.selectedChannel.selectedSlotRow = index
                                                        } else {
                                                            // For synth, handle item click only if not dragged. For other cases handle click immediately
                                                            if ((root.selectedChannel.channelAudioType == "synth" && !delegateMouseArea.dragHappened) || root.selectedChannel.channelAudioType != "synth") {
                                                                bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                                                            }
                                                        }
                                                    }

                                                    delegateMouseArea.dragHappened = false
                                                }
                                                onMouseXChanged: {
                                                    if (mouse.x - delegateMouseArea.initialMouseX != 0) {
                                                        var newVal = (mouse.x / delegate.width) * 100
                                                        delegateMouseArea.dragHappened = true
                                                        delegate.volumeControlObj.value = newVal
                                                    }
                                                }

                                                onPressAndHold: {
                                                    if (!delegateMouseArea.dragHappened) {
                                                        if (root.selectedChannel.channelAudioType === "sample-loop") {
                                                            // If channel type is sample-loop open clip wave editor
                                                            if (waveformContainer.clip && waveformContainer.clip.path && waveformContainer.clip.path.length > 0) {
                                                                zynqtgui.bottomBarControlType = "bottombar-controltype-clip";
                                                                zynqtgui.bottomBarControlObj = waveformContainer.clip;
                                                                bottomStack.slotsBar.bottomBarButton.checked = true;
                                                                Qt.callLater(function() {
                                                                    bottomStack.bottomBar.waveEditorAction.trigger();
                                                                })
                                                            }
                                                        } else if (root.selectedChannel.channelAudioType.startsWith("sample")) {
                                                            // If channel type is sample then open channel wave editor
                                                            if (waveformContainer.clip && waveformContainer.clip.path && waveformContainer.clip.path.length > 0) {
                                                                zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                                                zynqtgui.bottomBarControlObj = root.selectedChannel;
                                                                bottomStack.slotsBar.bottomBarButton.checked = true;
                                                                Qt.callLater(function() {
                                                                    bottomStack.bottomBar.channelWaveEditorAction.trigger();
                                                                })
                                                            }
                                                        } else if (root.selectedChannel.channelAudioType === "synth") {
                                                            // If channel type is synth open synth edit page
                                                            if (root.selectedChannel.checkIfLayerExists(root.selectedChannel.chainedSounds[index])) {
                                                                zynqtgui.fixed_layers.activate_index(root.selectedChannel.chainedSounds[index])
                                                                zynqtgui.control.single_effect_engine = null;
                                                                zynqtgui.current_screen_id = "control";
                                                                zynqtgui.forced_screen_back = "sketchpad"
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }

                            RowLayout {
                                id: waveformContainer

                                property bool showWaveform: false

                                property QtObject clip: null
                                Timer {
                                    id: waveformThrottle
                                    interval: 1; repeat: false; running: false;
                                    onTriggered: {
                                        waveformContainer.clip = root.selectedChannel.channelAudioType === "sample-loop"
                                            ? root.selectedChannel.getClipsModelByPart(root.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex)
                                            : root.selectedChannel.samples[root.selectedChannel.selectedSlotRow]
                                        waveformContainer.showWaveform = root.selectedChannel.channelAudioType === "sample-trig" ||
                                                                         root.selectedChannel.channelAudioType === "sample-slice" ||
                                                                         root.selectedChannel.channelAudioType === "sample-loop"
                                    }
                                }
                                Connections {
                                    target: root
                                    onSelectedChannelChanged: waveformThrottle.restart()
                                }
                                Connections {
                                    target: root.selectedChannel
                                    onChannel_audio_type_changed: waveformThrottle.restart()
                                }
                                Connections {
                                    target: zynqtgui.sketchpad
                                    onSong_changed: waveformThrottle.restart()
                                }
                                Connections {
                                    target: zynqtgui.sketchpad.song.scenesModel
                                    onSelected_track_index_changed: waveformThrottle.restart()
                                }

                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                                spacing: Kirigami.Units.gridUnit / 2

                                // Take 3/5 th of available width
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3

                                    QQC2.Label {
                                        Layout.fillWidth: false
                                        Layout.fillHeight: false
                                        font.pointSize: 9
                                        opacity: waveformContainer.showWaveform ? 1 : 0
                                        text: waveformContainer.clip ? qsTr("Wave : %1").arg(waveformContainer.clip.filename) : ""
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: "#222222"
                                        border.width: 1
                                        border.color: "#ff999999"
                                        radius: 4
                                        opacity: waveformContainer.showWaveform ? 1 : 0

                                        Zynthbox.WaveFormItem {
                                            anchors.fill: parent
                                            color: Kirigami.Theme.textColor
                                            source: waveformContainer.clip ? waveformContainer.clip.path : ""

                                            visible: waveformContainer.clip && waveformContainer.clip.path && waveformContainer.clip.path.length > 0

                                            // Mask for wave part before start
                                            Rectangle {
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                    left: parent.left
                                                    right: startLoopLine.left
                                                }
                                                color: "#99000000"
                                            }

                                            // Mask for wave part after
                                            Rectangle {
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                    left: endLoopLine.right
                                                    right: parent.right
                                                }
                                                color: "#99000000"
                                            }

                                            // Start loop line
                                            Rectangle {
                                                id: startLoopLine
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                color: Kirigami.Theme.positiveTextColor
                                                opacity: 0.6
                                                width: Kirigami.Units.smallSpacing
                                                x: (waveformContainer.clip.startPosition / waveformContainer.clip.duration) * parent.width
                                            }

                                            // End loop line
                                            Rectangle {
                                                id: endLoopLine
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                color: Kirigami.Theme.neutralTextColor
                                                opacity: 0.6
                                                width: Kirigami.Units.smallSpacing
                                                x: ((((60/Zynthbox.SyncTimer.bpm) * waveformContainer.clip.length) / waveformContainer.clip.duration) * parent.width) + ((waveformContainer.clip.startPosition / waveformContainer.clip.duration) * parent.width)
                                            }

                                            // Progress line
                                            Rectangle {
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                visible: root.visible && waveformContainer.clip.isPlaying
                                                color: Kirigami.Theme.highlightColor
                                                width: Kirigami.Units.smallSpacing
                                                x: visible ? waveformContainer.clip.progress/waveformContainer.clip.duration * parent.width : 0
                                            }

                                            // SamplerSynth progress dots
                                            Repeater {
                                                property QtObject cppClipObject: parent.visible ? Zynthbox.PlayGridManager.getClipById(waveformContainer.clip.cppObjId) : null;
                                                model: (root.visible && root.selectedChannel.channelAudioType === "sample-slice" || root.selectedChannel.channelAudioType === "sample-trig") && cppClipObject
                                                    ? cppClipObject.playbackPositions
                                                    : 0
                                                delegate: Item {
                                                    visible: model.positionID > -1
                                                    Rectangle {
                                                        anchors.centerIn: parent
                                                        rotation: 45
                                                        color: Kirigami.Theme.highlightColor
                                                        width: Kirigami.Units.largeSpacing
                                                        height:  Kirigami.Units.largeSpacing
                                                        scale: 0.5 + model.positionGain
                                                    }
                                                    anchors {
                                                        top: parent.verticalCenter
                                                        topMargin: model.positionPan * (parent.height / 2)
                                                    }
                                                    x: Math.floor(model.positionProgress * parent.width)
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {

                                                // Show waveform on click as well as longclick instead of opening picker dialog
                                                /*if (waveformContainer.showWaveform) {
                                                    bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                                                }*/
                                                if (waveformContainer.showWaveform) {
                                                    if (root.selectedChannel.channelAudioType === "sample-loop") {
                                                        if (waveformContainer.clip && waveformContainer.clip.path && waveformContainer.clip.path.length > 0) {
                                                            zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
                                                            zynqtgui.bottomBarControlObj = waveformContainer.clip;
                                                            bottomStack.slotsBar.bottomBarButton.checked = true;
                                                            Qt.callLater(function() {
                                                                bottomStack.bottomBar.waveEditorAction.trigger();
                                                            })
                                                        }
                                                    } else {
                                                        if (waveformContainer.clip && waveformContainer.clip.path && waveformContainer.clip.path.length > 0) {
                                                            zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                                            zynqtgui.bottomBarControlObj = root.selectedChannel;
                                                            bottomStack.slotsBar.bottomBarButton.checked = true;
                                                            Qt.callLater(function() {
                                                                bottomStack.bottomBar.channelWaveEditorAction.trigger();
                                                            })
                                                        }
                                                    }
                                                }
                                            }
                                            onPressAndHold: {
                                                if (waveformContainer.showWaveform) {
                                                    if (root.selectedChannel.channelAudioType === "sample-loop") {
                                                        if (waveformContainer.clip && waveformContainer.clip.path && waveformContainer.clip.path.length > 0) {
                                                            zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
                                                            zynqtgui.bottomBarControlObj = waveformContainer.clip;
                                                            bottomStack.slotsBar.bottomBarButton.checked = true;
                                                            Qt.callLater(function() {
                                                                bottomStack.bottomBar.waveEditorAction.trigger();
                                                            })
                                                        }
                                                    } else {
                                                        if (waveformContainer.clip && waveformContainer.clip.path && waveformContainer.clip.path.length > 0) {
                                                            zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                                            zynqtgui.bottomBarControlObj = root.selectedChannel;
                                                            bottomStack.slotsBar.bottomBarButton.checked = true;
                                                            Qt.callLater(function() {
                                                                bottomStack.bottomBar.channelWaveEditorAction.trigger();
                                                            })
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Take remaining available width
                                ColumnLayout {
                                    id: patternContainer

                                    property bool showPattern: root.selectedChannel.channelAudioType === "synth" ||
                                                               root.selectedChannel.channelAudioType === "external" ||
                                                               root.selectedChannel.channelAudioType === "sample-trig" ||
                                                               root.selectedChannel.channelAudioType === "sample-slice"

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                                    opacity: patternContainer.showPattern ? 1 : 0

                                    QQC2.Label {
                                        Layout.fillWidth: false
                                        Layout.fillHeight: false
                                        font.pointSize: 9
                                        text: qsTr("Clip : %1%2").arg(root.selectedChannel.id + 1).arg(String.fromCharCode(root.selectedChannel.selectedSlotRow + 97))
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2

                                        border.width: 1
                                        border.color: "#ff999999"
                                        radius: 4
                                        color: "#222222"
                                        clip: true

                                        Image {
                                            id: patternVisualiser

                                            visible: root.selectedChannel &&
                                                     root.selectedChannel.connectedPattern >= 0

                                            anchors {
                                                fill: parent
                                                centerIn: parent
                                                topMargin: 3
                                                leftMargin: 3
                                                rightMargin: 3
                                                bottomMargin: 2
                                            }
                                            smooth: false
                                            asynchronous: true
                                            source: root.pattern ? root.pattern.thumbnailUrl : ""
                                            Rectangle { // Progress
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                visible: root.visible &&
                                                         root.sequence &&
                                                         root.sequence.isPlaying &&
                                                         root.pattern &&
                                                         root.pattern.enabled
                                                color: Kirigami.Theme.highlightColor
                                                width: widthFactor // this way the progress rect is the same width as a step
                                                property double widthFactor: visible && root.pattern ? parent.width / (root.pattern.width * root.pattern.bankLength) : 1
                                                x: visible && root.pattern ? root.pattern.bankPlaybackPosition * widthFactor : 0
                                            }
                                            MouseArea {
                                                anchors.fill:parent
                                                onClicked: {
                                                    if (patternContainer.showPattern) {
                                                        var screenBack = zynqtgui.current_screen_id;
                                                        zynqtgui.current_modal_screen_id = "playgrid";
                                                        zynqtgui.forced_screen_back = "sketchpad";
                                                        Zynthbox.PlayGridManager.setCurrentPlaygrid("playgrid", Zynthbox.PlayGridManager.sequenceEditorIndex);
                                                        var sequence = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName);
                                                        sequence.setActiveChannel(root.selectedChannel.id, root.selectedChannel.selectedPart);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
