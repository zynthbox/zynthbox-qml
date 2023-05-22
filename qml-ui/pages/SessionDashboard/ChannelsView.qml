/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Session Dashboard page for Zynthian GUI

Copyright (C) 2021 Marco Martin <mart@kde.org>
Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>

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
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami


import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox
import "../Sketchpad" as Sketchpad

ColumnLayout {
    id: root

    enum BottomStackControlType {
        Wave = 0,
        Sound = 1
    }

    anchors {
        fill: parent
        topMargin: -Kirigami.Units.smallSpacing
        leftMargin: Kirigami.Units.gridUnit
    }

    property QtObject selectedChannel: zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.session_dashboard.selectedChannel)
    spacing: Kirigami.Units.largeSpacing

    function cuiaCallback(cuia) {
        if (clipFilePickerDialog.opened) {
            return clipFilePickerDialog.cuiaCallback(cuia);
        }
        if (bottomDrawer.opened &&
            bottomStack.children[bottomStack.currentIndex].cuiaCallback != null) {
            return bottomStack.children[bottomStack.currentIndex].cuiaCallback(cuia);
        }

        switch (cuia) {
            case "SELECT_UP":
                if (zynqtgui.session_dashboard.selectedChannel > 0) {
                    zynqtgui.session_dashboard.selectedChannel -= 1
                    return true;
                } else {
                    return false;
                }

            case "SELECT_DOWN":
                if (zynqtgui.session_dashboard.selectedChannel < 5) {
                    zynqtgui.session_dashboard.selectedChannel += 1
                    return true;
                } else {
                    return false;
                }

            default:
                return false;
        }
    }

    RowLayout {
        spacing: Kirigami.Units.gridUnit * 2

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 4
            color: Kirigami.Theme.backgroundColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.gridUnit*0.5
                spacing: 0

                Repeater {
                    id: channelsRepeater
                    model: zynqtgui.sketchpad.song.channelsModel
                    delegate: Rectangle {
                        property QtObject channel: model.channel
                        property int channelIndex: index
                        property QtObject selectedClip: channel.clipsModel.getClip(0)
                        property bool hasWavLoaded: channelDelegate.selectedClip.path.length > 0
                        property bool channelHasConnectedPattern: channel.connectedPattern >= 0

                        id: channelDelegate

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        visible: index >= zynqtgui.session_dashboard.visibleChannelsStart && index <= zynqtgui.session_dashboard.visibleChannelsEnd
                        border.width: zynqtgui.session_dashboard.selectedChannel === channelIndex ? 1 : 0
                        border.color: Kirigami.Theme.highlightColor
                        color: "transparent"
                        radius: 4

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                zynqtgui.session_dashboard.selectedChannel = channelIndex;
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Kirigami.Units.gridUnit
                            anchors.rightMargin: Kirigami.Units.gridUnit
                            spacing: Kirigami.Units.gridUnit

                            QQC2.Label {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit*1
                                Layout.alignment: Qt.AlignVCenter
                                text: (index+1) + "."
                            }
                            Item {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit*3
                                Layout.alignment: Qt.AlignHCenter

                                QQC2.Label {
                                    width: parent.width
                                    anchors.centerIn: parent
                                    elide: "ElideRight"
                                    text: channel.name
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: false
                                Layout.fillHeight: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit*12
                                Layout.preferredHeight: Kirigami.Units.gridUnit*2
                                Layout.alignment: Qt.AlignVCenter

                                Kirigami.Theme.inherit: false
                                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                color: Kirigami.Theme.backgroundColor

                                border.color: "#ff999999"
                                border.width: 1
                                radius: 4
                                opacity: zynqtgui.session_dashboard.selectedChannel === channelIndex ? 1 : 0.5

                                RowLayout {
                                    anchors {
                                        verticalCenter: parent.verticalCenter
                                        left: parent.left
                                        right: parent.right
                                        leftMargin: Kirigami.Units.gridUnit*0.5
                                        rightMargin: Kirigami.Units.gridUnit*0.5
                                    }

                                    QQC2.Label {
                                        id: soundLabel

                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignCenter
                                        horizontalAlignment: Text.AlignLeft
                                        text: {
                                            soundLabel.updateSoundName();
                                        }

                                        Connections {
                                            target: zynqtgui.fixed_layers
                                            onList_updated: {
                                                soundLabel.updateSoundName();
                                            }
                                        }

                                        Connections {
                                            target: channel
                                            onChainedSoundsChanged: {
                                                soundLabel.updateSoundName();
                                            }
                                        }

                                        elide: "ElideRight"

                                        function updateSoundName() {
                                            var text = "";

                                            for (var id in channelDelegate.channel.chainedSounds) {
                                                if (channelDelegate.channel.chainedSounds[id] >= 0 &&
                                                    channelDelegate.channel.checkIfLayerExists(channelDelegate.channel.chainedSounds[id])) {
                                                    text = zynqtgui.fixed_layers.selector_list.getDisplayValue(channelDelegate.channel.chainedSounds[id]);
                                                    break;
                                                }
                                            }

                                            soundLabel.text = text;
                                        }
                                    }

                                    QQC2.Label {
                                        Layout.fillWidth: false
                                        Layout.alignment: Qt.AlignCenter
                                        text: qsTr("+%1").arg(Math.max(channelDelegate.channel.chainedSounds.filter(function (e) { return e >= 0 && channelDelegate.channel.checkIfLayerExists(e); }).length-1, 0))
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (zynqtgui.session_dashboard.selectedChannel !== index) {
                                            zynqtgui.session_dashboard.selectedChannel = index;
                                        } else {
                                            // soundsDialog.open();
                                            console.log("Opening bottom drawer");
                                            bottomChannelsBar.forceActiveFocus();
                                            bottomStack.currentIndex = ChannelsView.BottomStackControlType.Sound;
                                            bottomDrawer.open();
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: false
                                Layout.fillHeight: false
                                Layout.alignment: Qt.AlignVCenter

                                QQC2.RoundButton {
                                    id: control
                                    Layout.fillWidth: false
                                    Layout.fillHeight: false
                                    Layout.preferredWidth: Kirigami.Units.gridUnit*2
                                    Layout.preferredHeight: Kirigami.Units.gridUnit*2
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: 2
                                    highlighted: channelDelegate.selectedClip === channel.sceneClip && channel.sceneClip.inCurrentScene
                                    property QtObject sequence: channelDelegate.channelHasConnectedPattern ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName) : null
                                    property QtObject pattern: sequence ? sequence.getByPart(channelIndex, channel.selectedPart) : null
                                    Connections {
                                        target: control.pattern
                                        onEnabledChanged: {
                                            if (channel.sceneClip.col === control.pattern.bankOffset / control.pattern.bankLength && ((control.pattern.enabled && !channel.sceneClip.inCurrentScene) || (!control.pattern.enabled && channel.sceneClip.inCurrentScene))) {
                                                zynqtgui.sketchpad.song.scenesModel.toggleClipInCurrentScene(channel.sceneClip);
                                            }
                                        }
                                    }
                                    background: Rectangle { // Derived from znthian qtquick-controls-style
                                        Kirigami.Theme.inherit: false
                                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                        color: channel.sceneClip.inCurrentScene ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                                        border.color: channelDelegate.selectedClip === channel.sceneClip
                                                        ? Kirigami.Theme.highlightColor
                                                        : Qt.rgba(
                                                                Kirigami.Theme.textColor.r,
                                                                Kirigami.Theme.textColor.g,
                                                                Kirigami.Theme.textColor.b,
                                                                0.4
                                                            )
                                        radius: control.radius

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: parent.radius
                                            gradient: Gradient {
                                                GradientStop { position: 0; color: control.pressed ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.05)}
                                                GradientStop { position: 1; color: control.pressed ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.05)}
                                            }
                                        }
                                    }

                                    onClicked: {
                                        channelDelegate.selectedClip = channel.sceneClip;

                                        zynqtgui.sketchpad.song.scenesModel.toggleClipInCurrentScene(channel.sceneClip);
                                        if (control.pattern) {
                                            pattern.bank = channel.sceneClip.col === 0 ? "A" : "B";

                                            if (channel.sceneClip.inCurrentScene) {
                                                pattern.enabled = true;
                                            } else {
                                                pattern.enabled = false;
                                            }
                                        }
                                    }

                                    QQC2.Label {
                                        anchors.centerIn: parent
                                        text: channel.sceneClip.partName
                                    }
                                }

                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.topMargin: Kirigami.Units.gridUnit*0.3
                                Layout.bottomMargin: Kirigami.Units.gridUnit*0.3

                                Kirigami.Theme.inherit: false
                                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                color: Kirigami.Theme.backgroundColor
                                border.color: "#99999999"
                                border.width: 1
                                radius: 4
                                opacity: zynqtgui.session_dashboard.selectedChannel === channelIndex ? 1 : 0.5

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (zynqtgui.session_dashboard.selectedChannel !== index) {
                                            zynqtgui.session_dashboard.selectedChannel = index;
                                        } else {
                                            if (channelDelegate.channelHasConnectedPattern) {
                                                zynqtgui.current_modal_screen_id = "playgrid";
                                                Zynthbox.PlayGridManager.setCurrentPlaygrid("playgrid", Zynthbox.PlayGridManager.sequenceEditorIndex);
                                                var sequence = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName);
                                                sequence.setActiveChannel(channel.id, channel.selectedPart);
                                            } else if (channelDelegate.hasWavLoaded) {
                                                console.log("Opening bottom drawer");
                                                bottomBar.forceActiveFocus();
                                                bottomStack.currentIndex = ChannelsView.BottomStackControlType.Wave;
                                                zynqtgui.bottomBarControlType = "bottombar-controltype-clip";
                                                zynqtgui.bottomBarControlObj = channelDelegate.selectedClip;
                                                bottomDrawer.open();
                                            }
                                        }
                                    }
                                }

                                Zynthbox.WaveFormItem {
                                    anchors.fill: parent

                                    color: Kirigami.Theme.textColor
                                    source: channelDelegate.selectedClip.path
                                    visible: !channelDelegate.channelHasConnectedPattern && channelDelegate.hasWavLoaded
                                    clip: true

                                    Rectangle {
                                        x: 0
                                        y: parent.height/2 - height/2
                                        width: parent.width
                                        height: 1
                                        color: Kirigami.Theme.textColor
                                        opacity: zynqtgui.session_dashboard.selectedChannel === channelIndex ? 1 : 0.1
                                    }

                                    Rectangle {  //Start loop
                                        anchors {
                                            top: parent.top
                                            bottom: parent.bottom
                                        }
                                        color: Kirigami.Theme.positiveTextColor
                                        opacity: 0.6
                                        width: Kirigami.Units.smallSpacing
                                        x: (channelDelegate.selectedClip.startPosition / channelDelegate.selectedClip.duration) * parent.width
                                    }

                                    Rectangle {  // End loop
                                        anchors {
                                            top: parent.top
                                            bottom: parent.bottom
                                        }
                                        color: Kirigami.Theme.neutralTextColor
                                        opacity: 0.6
                                        width: Kirigami.Units.smallSpacing
                                        x: ((((60/Zynthbox.SyncTimer.bpm) * channelDelegate.selectedClip.length) / channelDelegate.selectedClip.duration) * parent.width) + ((channelDelegate.selectedClip.startPosition / channelDelegate.selectedClip.duration) * parent.width)
                                    }

                                    Rectangle { // Progress
                                        anchors {
                                            top: parent.top
                                            bottom: parent.bottom
                                        }
                                        visible: channelDelegate.selectedClip.isPlaying
                                        color: Kirigami.Theme.highlightColor
                                        width: Kirigami.Units.smallSpacing
                                        x: channelDelegate.selectedClip.progress/channelDelegate.selectedClip.duration * parent.width
                                    }
                                }

                                Image {
                                    id: patternVisualiser
                                    anchors.fill: parent
                                    visible: channelDelegate.channelHasConnectedPattern
                                    property QtObject sequence: channelDelegate.channelHasConnectedPattern ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName) : null
                                    property QtObject pattern: sequence ? sequence.getByPart(channelIndex, channelDelegate.channel.selectedPart) : null
                                    source: pattern ? pattern.thumbnailUrl : ""
                                    Rectangle { // Progress
                                        anchors {
                                            top: parent.top
                                            bottom: parent.bottom
                                        }
                                        visible: patternVisualiser.sequence && patternVisualiser.sequence.isPlaying && patternVisualiser.pattern && patternVisualiser.pattern.enabled
                                        color: Kirigami.Theme.highlightColor
                                        width: widthFactor // this way the progress rect is the same width as a step
                                        property double widthFactor: patternVisualiser.pattern ? parent.width / (patternVisualiser.pattern.width * patternVisualiser.pattern.bankLength) : 1
                                        x: patternVisualiser.pattern ? patternVisualiser.pattern.bankPlaybackPosition * widthFactor : 0
                                    }
                                    QQC2.Label {
                                        anchors.fill: parent
                                        horizontalAlignment: Text.AlignRight
                                        verticalAlignment: Text.AlignBottom
                                        text: qsTr("Pattern %1, pt.%2 (%3)")
                                                .arg(channel.connectedPattern+1)
                                                .arg(patternVisualiser.pattern ? patternVisualiser.pattern.bank : "")
                                                .arg(patternVisualiser.pattern ? patternVisualiser.pattern.availableBars : "")
                                    }
                                }

                                QQC2.Label {
                                    anchors.centerIn: parent
                                    visible: !channelDelegate.hasWavLoaded && !channelDelegate.channelHasConnectedPattern
                                    text: qsTr("Select a wav or pattern")
                                    font.italic: true
                                    font.pointSize: 9
                                    color: "#88ffffff"
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit*7
                                Layout.alignment: Qt.AlignHCenter

                                QQC2.RoundButton {
                                    Layout.fillWidth: false
                                    Layout.fillHeight: false
                                    Layout.preferredWidth: Kirigami.Units.gridUnit*2
                                    Layout.preferredHeight: Kirigami.Units.gridUnit*2

                                    radius: 2
                                    enabled: zynqtgui.session_dashboard.selectedChannel === channelIndex
                                    visible: !channelDelegate.hasWavLoaded && !channelDelegate.channelHasConnectedPattern

                                    onClicked: {
                                        if (zynqtgui.session_dashboard.selectedChannel !== index) {
                                            zynqtgui.session_dashboard.selectedChannel = index;
                                        } else {
                                            clipFilePickerDialog.clipObj = channelDelegate.selectedClip;
                                            clipFilePickerDialog.folderModel.folder = clipFilePickerDialog.clipObj.recordingDir;
                                            clipFilePickerDialog.open();
                                        }
                                    }

                                    Kirigami.Icon {
                                        width: Math.round(Kirigami.Units.gridUnit)
                                        height: width
                                        anchors.centerIn: parent
                                        source: "document-open"
                                        color: Kirigami.Theme.textColor
                                    }
                                }
                                QQC2.RoundButton {
                                    Layout.fillWidth: false
                                    Layout.fillHeight: false
                                    Layout.preferredWidth: Kirigami.Units.gridUnit*2
                                    Layout.preferredHeight: Kirigami.Units.gridUnit*2

                                    radius: 2
                                    visible: channelDelegate.hasWavLoaded || channelDelegate.channelHasConnectedPattern
                                    enabled: zynqtgui.session_dashboard.selectedChannel === channelIndex && !zynqtgui.sketchpad.isMetronomeRunning

                                    onClicked: {
                                        if (zynqtgui.session_dashboard.selectedChannel !== index) {
                                            zynqtgui.session_dashboard.selectedChannel = index;
                                        } else {
                                            if (channelDelegate.channelHasConnectedPattern) {
                                                var seq = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName).getByPart(channelDelegate.channelIndex, channelDelegate.channel.selectedPart);
                                                seq.enabled = false;
                                                channelDelegate.channel.connectedPattern = -1;
                                            } else {
                                                channelDelegate.selectedClip.clear();
                                            }
                                        }
                                    }

                                    Kirigami.Icon {
                                        width: Math.round(Kirigami.Units.gridUnit)
                                        height: width
                                        anchors.centerIn: parent
                                        source: "edit-clear-all"
                                        color: Kirigami.Theme.textColor
                                    }
                                }
                                QQC2.RoundButton {
                                    Layout.fillWidth: false
                                    Layout.fillHeight: false
                                    Layout.preferredWidth: Kirigami.Units.gridUnit*3
                                    Layout.preferredHeight: Kirigami.Units.gridUnit*2

                                    text: qsTr("Midi")
                                    radius: 2
                                    enabled: zynqtgui.session_dashboard.selectedChannel === channelIndex
                                    visible: !channelDelegate.hasWavLoaded && !channelDelegate.channelHasConnectedPattern

                                    onClicked: {
                                        if (zynqtgui.session_dashboard.selectedChannel !== index) {
                                            zynqtgui.session_dashboard.selectedChannel = index;
                                        } else {
                                            playgridPickerPopup.channelObj = channel;
                                            playgridPickerPopup.channelIndex = channelIndex;
                                            playgridPickerPopup.clipObj = channelDelegate.selectedClip;
                                            playgridPickerPopup.open();
                                        }
                                    }
                                }
                                QQC2.RoundButton {
                                    Layout.fillWidth: false
                                    Layout.fillHeight: false
                                    Layout.preferredWidth: Kirigami.Units.gridUnit*2
                                    Layout.preferredHeight: Kirigami.Units.gridUnit*2

                                    enabled: zynqtgui.session_dashboard.selectedChannel === channelIndex
                                    radius: 2
                                    visible: !channelDelegate.hasWavLoaded && !channelDelegate.channelHasConnectedPattern

                                    onClicked: {
                                        if (zynqtgui.session_dashboard.selectedChannel !== index) {
                                            zynqtgui.session_dashboard.selectedChannel = index;
                                        } else {
                                            if (!zynqtgui.sketchpad.isRecording) {
                                                zynqtgui.sketchpad.recordingSource = "internal"
                                                zynqtgui.sketchpad.recordingChannel = ""
                                                channelDelegate.selectedClip.queueRecording();
                                                Zynthian.CommonUtils.startMetronomeAndPlayback();
                                            } else {
                                                channelDelegate.selectedClip.stopRecording();
                                                zynqtgui.sketchpad.song.scenesModel.addClipToCurrentScene(channelDelegate.selectedClip);
                                            }
                                        }
                                    }

                                    Kirigami.Icon {
                                        width: Kirigami.Units.gridUnit
                                        height: Kirigami.Units.gridUnit
                                        anchors.centerIn: parent
                                        source: zynqtgui.sketchpad.isRecording ? "media-playback-stop" : "media-record-symbolic"
                                        color: zynqtgui.session_dashboard.selectedChannel === channelIndex && !zynqtgui.sketchpad.isRecording ? "#f44336" : Kirigami.Theme.textColor
                                        opacity: zynqtgui.session_dashboard.selectedChannel === channelIndex ? 1 : 0.6
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    SoundsDialog {
        id: soundsDialog
    }
    Zynthian.FilePickerDialog {
        property QtObject clipObj

        id: clipFilePickerDialog

        headerText: qsTr("%1 : Pick an audio file").arg(clipObj ? clipObj.channelName : "")
        rootFolder: "/zynthian/zynthian-my-data"
        folderModel {
            nameFilters: ["*.wav"]
        }
        onFileSelected: {
            if (clipObj) {
                clipObj.path = file.filePath
                zynqtgui.sketchpad.song.scenesModel.addClipToCurrentScene(clipObj);
            }
        }
    }

    Connections {
        target: zynqtgui.session_dashboard
        onMidiSelectionRequested: {
            var channelDelegate = channelsRepeater.itemAt(zynqtgui.session_dashboard.selectedChannel)
            playgridPickerPopup.channelObj = channelDelegate.channel;
            playgridPickerPopup.channelIndex = channelDelegate.channelIndex;
            playgridPickerPopup.clipObj = channelDelegate.selectedClip;
            playgridPickerPopup.open()
        }
    }
    Zynthian.Popup {
        property QtObject channelObj
        property int channelIndex
        property QtObject clipObj

        id: playgridPickerPopup
        x: root.parent.mapFromGlobal(Math.round(Screen.width/2 - width/2), 0).x
        y: root.parent.mapFromGlobal(0, Math.round(Screen.height/2 - height/2)).y
        width: Kirigami.Units.gridUnit*12

        onVisibleChanged: {
            if (visible) {
                patternsViewMainRepeater.model = Object.keys(Zynthbox.PlayGridManager.dashboardModels);
            } else {
                patternsViewMainRepeater.model = [];
            }
        }

        ColumnLayout {
            anchors.fill: parent

            Repeater {
                id: patternsViewMainRepeater
                model: Object.keys(Zynthbox.PlayGridManager.dashboardModels)
                delegate: Repeater {
                    id: patternsViewPlaygridRepeater
                    model: Zynthbox.PlayGridManager.dashboardModels[modelData]
                    property string playgridId: modelData

                    QQC2.Button {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*5
                        Layout.preferredHeight: Kirigami.Units.gridUnit*3
                        Layout.alignment: Qt.AlignCenter
                        text: model.text
                        visible: !zynqtgui.sketchpad.song.channelsModel.checkIfPatternAlreadyConnected(index)

                        onClicked: {
                            if (playgridPickerPopup.channelObj) {
                                playgridPickerPopup.channelObj.clipsModel.getClip(0).clear();
                                playgridPickerPopup.channelObj.clipsModel.getClip(1).clear();
                                playgridPickerPopup.channelObj.connectedPattern = index;

                                var seq = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName).getByPart(playgridPickerPopup.channelIndex, playgridPickerPopup.channelObj.selectedPart);
                                seq.midiChannel = playgridPickerPopup.channelObj.connectedSound;
                                seq.bank = "A"
                                seq.enabled = true;

                                playgridPickerPopup.close();

                                if (playgridPickerPopup.clipObj) {
                                    zynqtgui.sketchpad.song.scenesModel.addClipToCurrentScene(playgridPickerPopup.clipObj);
                                } else {
                                    console.log("Error setting clip to scene")
                                }
                            } else {
                                console.log("Error connecting pattern to channel")
                            }
                        }
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: Kirigami.Units.gridUnit*3
                Layout.margins: Kirigami.Units.gridUnit
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: "AlignHCenter"
                verticalAlignment: "AlignVCenter"
                text: qsTr("All patterns are already assigned to channels")
                wrapMode: "WordWrap"
                font.italic: true
                font.pointSize: 11
                visible: zynqtgui.sketchpad.song.channelsModel.connectedPatternsCount >= 5
                opacity: 0.7
            }
        }
    }

    QQC2.Drawer {
        id: bottomDrawer

        edge: Qt.BottomEdge
        modal: true

        width: parent.width
        height: Kirigami.Units.gridUnit * 15

        StackLayout {
            id: bottomStack
            anchors.fill: parent

            Sketchpad.BottomBar {
                id: bottomBar
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            ChannelsViewSoundsBar {
                id: bottomChannelsBar
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    Zynthian.Popup {
        id: cannotRecordEmptyLayerPopup
        x: Math.round(parent.width/2 - width/2)
        y: Math.round(parent.height/2 - height/2)
        width: Kirigami.Units.gridUnit*12
        height: Kirigami.Units.gridUnit*4

        QQC2.Label {
            anchors.margins: Kirigami.Units.gridUnit
            width: parent.width
            height: parent.height
            horizontalAlignment: "AlignHCenter"
            verticalAlignment: "AlignVCenter"
            text: qsTr("Cannot record empty sound layer")
            font.italic: true
            font.pointSize: 11
            wrapMode: "WordWrap"
        }
    }

    Connections {
        target: zynqtgui.sketchpad
        onCannotRecordEmptyLayer: {
            cannotRecordEmptyLayerPopup.open();
        }
    }
}
