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

import JuceGraphics 1.0

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick
import "../ZynthiLoops" as ZynthiLoops

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

    property QtObject selectedTrack: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)
    spacing: Kirigami.Units.largeSpacing

    function cuiaCallback(cuia) {
        if (bottomDrawer.opened &&
            bottomStack.children[bottomStack.currentIndex].cuiaCallback != null) {
            return bottomStack.children[bottomStack.currentIndex].cuiaCallback(cuia);
        }

        switch (cuia) {
            case "SELECT_UP":
                if (zynthian.session_dashboard.selectedTrack > 0) {
                    zynthian.session_dashboard.selectedTrack -= 1
                    return true;
                } else {
                    return false;
                }

            case "SELECT_DOWN":
                if (zynthian.session_dashboard.selectedTrack < 5) {
                    zynthian.session_dashboard.selectedTrack += 1
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
                    id: tracksRepeater
                    model: zynthian.zynthiloops.song.tracksModel
                    delegate: Rectangle {
                        property QtObject track: model.track
                        property int trackIndex: index
                        property QtObject selectedClip: track.clipsModel.getClip(0)
                        property bool hasWavLoaded: trackDelegate.selectedClip.path.length > 0
                        property bool trackHasConnectedPattern: track.connectedPattern >= 0

                        id: trackDelegate

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        visible: index >= zynthian.session_dashboard.visibleTracksStart && index <= zynthian.session_dashboard.visibleTracksEnd
                        border.width: zynthian.session_dashboard.selectedTrack === trackIndex ? 1 : 0
                        border.color: Kirigami.Theme.highlightColor
                        color: "transparent"
                        radius: 4

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                zynthian.session_dashboard.selectedTrack = trackIndex;
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
                                    text: track.name
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
                                opacity: zynthian.session_dashboard.selectedTrack === trackIndex ? 1 : 0.5

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
                                            target: zynthian.fixed_layers
                                            onList_updated: {
                                                soundLabel.updateSoundName();
                                            }
                                        }

                                        Connections {
                                            target: track
                                            onChainedSoundsChanged: {
                                                soundLabel.updateSoundName();
                                            }
                                        }

                                        elide: "ElideRight"

                                        function updateSoundName() {
                                            var text = "";

                                            for (var id in trackDelegate.track.chainedSounds) {
                                                if (trackDelegate.track.chainedSounds[id] >= 0 &&
                                                    trackDelegate.track.checkIfLayerExists(trackDelegate.track.chainedSounds[id])) {
                                                    text = zynthian.fixed_layers.selector_list.getDisplayValue(trackDelegate.track.chainedSounds[id]);
                                                    break;
                                                }
                                            }

                                            soundLabel.text = text;
                                        }
                                    }

                                    QQC2.Label {
                                        Layout.fillWidth: false
                                        Layout.alignment: Qt.AlignCenter
                                        text: qsTr("+%1").arg(Math.max(trackDelegate.track.chainedSounds.filter(function (e) { return e >= 0 && trackDelegate.track.checkIfLayerExists(e); }).length-1, 0))
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (zynthian.session_dashboard.selectedTrack !== index) {
                                            zynthian.session_dashboard.selectedTrack = index;
                                        } else {
                                            // soundsDialog.open();
                                            console.log("Opening bottom drawer");
                                            bottomTracksBar.forceActiveFocus();
                                            bottomStack.currentIndex = TracksView.BottomStackControlType.Sound;
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
                                    highlighted: trackDelegate.selectedClip === track.sceneClip && track.sceneClip.inCurrentScene
                                    property QtObject sequence: trackDelegate.trackHasConnectedPattern ? ZynQuick.PlayGridManager.getSequenceModel(zynthian.zynthiloops.song.scenesModel.selectedMixName) : null
                                    property QtObject pattern: sequence ? sequence.getByPart(trackIndex, track.selectedPart) : null
                                    Connections {
                                        target: control.pattern
                                        onEnabledChanged: {
                                            if (track.sceneClip.col === control.pattern.bankOffset / control.pattern.bankLength && ((control.pattern.enabled && !track.sceneClip.inCurrentScene) || (!control.pattern.enabled && track.sceneClip.inCurrentScene))) {
                                                zynthian.zynthiloops.song.scenesModel.toggleClipInCurrentScene(track.sceneClip);
                                            }
                                        }
                                    }
                                    background: Rectangle { // Derived from znthian qtquick-controls-style
                                        Kirigami.Theme.inherit: false
                                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                        color: track.sceneClip.inCurrentScene ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                                        border.color: trackDelegate.selectedClip === track.sceneClip
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
                                        trackDelegate.selectedClip = track.sceneClip;

                                        zynthian.zynthiloops.song.scenesModel.toggleClipInCurrentScene(track.sceneClip);
                                        if (control.pattern) {
                                            pattern.bank = track.sceneClip.col === 0 ? "A" : "B";

                                            if (track.sceneClip.inCurrentScene) {
                                                pattern.enabled = true;
                                            } else {
                                                pattern.enabled = false;
                                            }
                                        }
                                    }

                                    QQC2.Label {
                                        anchors.centerIn: parent
                                        text: track.sceneClip.partName
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
                                opacity: zynthian.session_dashboard.selectedTrack === trackIndex ? 1 : 0.5

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (zynthian.session_dashboard.selectedTrack !== index) {
                                            zynthian.session_dashboard.selectedTrack = index;
                                        } else {
                                            if (trackDelegate.trackHasConnectedPattern) {
                                                zynthian.current_modal_screen_id = "playgrid";
                                                ZynQuick.PlayGridManager.setCurrentPlaygrid("playgrid", ZynQuick.PlayGridManager.sequenceEditorIndex);
                                                var sequence = ZynQuick.PlayGridManager.getSequenceModel(zynthian.zynthiloops.song.scenesModel.selectedMixName);
                                                sequence.setActiveTrack(track.id, track.selectedPart);
                                            } else if (trackDelegate.hasWavLoaded) {
                                                console.log("Opening bottom drawer");
                                                bottomBar.forceActiveFocus();
                                                bottomStack.currentIndex = TracksView.BottomStackControlType.Wave;
                                                bottomBar.controlType = ZynthiLoops.BottomBar.ControlType.Clip;
                                                bottomBar.controlObj = trackDelegate.selectedClip;
                                                bottomDrawer.open();
                                            }
                                        }
                                    }
                                }

                                WaveFormItem {
                                    anchors.fill: parent

                                    color: Kirigami.Theme.textColor
                                    source: trackDelegate.selectedClip.path
                                    visible: !trackDelegate.trackHasConnectedPattern && trackDelegate.hasWavLoaded
                                    clip: true

                                    Rectangle {
                                        x: 0
                                        y: parent.height/2 - height/2
                                        width: parent.width
                                        height: 1
                                        color: Kirigami.Theme.textColor
                                        opacity: zynthian.session_dashboard.selectedTrack === trackIndex ? 1 : 0.1
                                    }

                                    Rectangle {  //Start loop
                                        anchors {
                                            top: parent.top
                                            bottom: parent.bottom
                                        }
                                        color: Kirigami.Theme.positiveTextColor
                                        opacity: 0.6
                                        width: Kirigami.Units.smallSpacing
                                        x: (trackDelegate.selectedClip.startPosition / trackDelegate.selectedClip.duration) * parent.width
                                    }

                                    Rectangle {  // End loop
                                        anchors {
                                            top: parent.top
                                            bottom: parent.bottom
                                        }
                                        color: Kirigami.Theme.neutralTextColor
                                        opacity: 0.6
                                        width: Kirigami.Units.smallSpacing
                                        x: ((((60/zynthian.zynthiloops.song.bpm) * trackDelegate.selectedClip.length) / trackDelegate.selectedClip.duration) * parent.width) + ((trackDelegate.selectedClip.startPosition / trackDelegate.selectedClip.duration) * parent.width)
                                    }

                                    Rectangle { // Progress
                                        anchors {
                                            top: parent.top
                                            bottom: parent.bottom
                                        }
                                        visible: trackDelegate.selectedClip.isPlaying
                                        color: Kirigami.Theme.highlightColor
                                        width: Kirigami.Units.smallSpacing
                                        x: trackDelegate.selectedClip.progress/trackDelegate.selectedClip.duration * parent.width
                                    }
                                }

                                Image {
                                    id: patternVisualiser
                                    anchors.fill: parent
                                    visible: trackDelegate.trackHasConnectedPattern
                                    property QtObject sequence: trackDelegate.trackHasConnectedPattern ? ZynQuick.PlayGridManager.getSequenceModel(zynthian.zynthiloops.song.scenesModel.selectedMixName) : null
                                    property QtObject pattern: sequence ? sequence.getByPart(trackIndex, trackDelegate.track.selectedPart) : null
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
                                                .arg(track.connectedPattern+1)
                                                .arg(patternVisualiser.pattern ? patternVisualiser.pattern.bank : "")
                                                .arg(patternVisualiser.pattern ? patternVisualiser.pattern.availableBars : "")
                                    }
                                }

                                QQC2.Label {
                                    anchors.centerIn: parent
                                    visible: !trackDelegate.hasWavLoaded && !trackDelegate.trackHasConnectedPattern
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
                                    enabled: zynthian.session_dashboard.selectedTrack === trackIndex
                                    visible: !trackDelegate.hasWavLoaded && !trackDelegate.trackHasConnectedPattern

                                    onClicked: {
                                        if (zynthian.session_dashboard.selectedTrack !== index) {
                                            zynthian.session_dashboard.selectedTrack = index;
                                        } else {
                                            clipFilePickerDialog.clipObj = trackDelegate.selectedClip;
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
                                    visible: trackDelegate.hasWavLoaded || trackDelegate.trackHasConnectedPattern
                                    enabled: zynthian.session_dashboard.selectedTrack === trackIndex && !zynthian.zynthiloops.isMetronomeRunning

                                    onClicked: {
                                        if (zynthian.session_dashboard.selectedTrack !== index) {
                                            zynthian.session_dashboard.selectedTrack = index;
                                        } else {
                                            if (trackDelegate.trackHasConnectedPattern) {
                                                var seq = ZynQuick.PlayGridManager.getSequenceModel(zynthian.zynthiloops.song.scenesModel.selectedMixName).getByPart(trackDelegate.trackIndex, trackDelegate.track.selectedPart);
                                                seq.enabled = false;
                                                trackDelegate.track.connectedPattern = -1;
                                            } else {
                                                trackDelegate.selectedClip.clear();
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
                                    enabled: zynthian.session_dashboard.selectedTrack === trackIndex
                                    visible: !trackDelegate.hasWavLoaded && !trackDelegate.trackHasConnectedPattern

                                    onClicked: {
                                        if (zynthian.session_dashboard.selectedTrack !== index) {
                                            zynthian.session_dashboard.selectedTrack = index;
                                        } else {
                                            playgridPickerPopup.trackObj = track;
                                            playgridPickerPopup.trackIndex = trackIndex;
                                            playgridPickerPopup.clipObj = trackDelegate.selectedClip;
                                            playgridPickerPopup.open();
                                        }
                                    }
                                }
                                QQC2.RoundButton {
                                    Layout.fillWidth: false
                                    Layout.fillHeight: false
                                    Layout.preferredWidth: Kirigami.Units.gridUnit*2
                                    Layout.preferredHeight: Kirigami.Units.gridUnit*2

                                    enabled: zynthian.session_dashboard.selectedTrack === trackIndex
                                    radius: 2
                                    visible: !trackDelegate.hasWavLoaded && !trackDelegate.trackHasConnectedPattern

                                    onClicked: {
                                        if (zynthian.session_dashboard.selectedTrack !== index) {
                                            zynthian.session_dashboard.selectedTrack = index;
                                        } else {
                                            if (!trackDelegate.selectedClip.isRecording) {
                                                trackDelegate.selectedClip.queueRecording("internal", "");
                                                Zynthian.CommonUtils.startMetronomeAndPlayback();
                                            } else {
                                                trackDelegate.selectedClip.stopRecording();
                                                zynthian.zynthiloops.song.scenesModel.addClipToCurrentScene(trackDelegate.selectedClip);
                                            }
                                        }
                                    }

                                    Kirigami.Icon {
                                        width: Kirigami.Units.gridUnit
                                        height: Kirigami.Units.gridUnit
                                        anchors.centerIn: parent
                                        source: trackDelegate.selectedClip.isRecording ? "media-playback-stop" : "media-record-symbolic"
                                        color: zynthian.session_dashboard.selectedTrack === trackIndex && !trackDelegate.selectedClip.isRecording ? "#f44336" : Kirigami.Theme.textColor
                                        opacity: zynthian.session_dashboard.selectedTrack === trackIndex ? 1 : 0.6
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

        headerText: qsTr("%1 : Pick an audio file").arg(clipObj ? clipObj.trackName : "")
        rootFolder: "/zynthian/zynthian-my-data"
        folderModel {
            nameFilters: ["*.wav"]
        }
        onFileSelected: {
            if (clipObj) {
                clipObj.path = file.filePath
                zynthian.zynthiloops.song.scenesModel.addClipToCurrentScene(clipObj);
            }
        }
    }

    Connections {
        target: zynthian.session_dashboard
        onMidiSelectionRequested: {
            var trackDelegate = tracksRepeater.itemAt(zynthian.session_dashboard.selectedTrack)
            playgridPickerPopup.trackObj = trackDelegate.track;
            playgridPickerPopup.trackIndex = trackDelegate.trackIndex;
            playgridPickerPopup.clipObj = trackDelegate.selectedClip;
            playgridPickerPopup.open()
        }
    }
    QQC2.Popup {
        property QtObject trackObj
        property int trackIndex
        property QtObject clipObj

        id: playgridPickerPopup
        x: root.parent.mapFromGlobal(Math.round(Screen.width/2 - width/2), 0).x
        y: root.parent.mapFromGlobal(0, Math.round(Screen.height/2 - height/2)).y
        width: Kirigami.Units.gridUnit*12
        modal: true

        onVisibleChanged: {
            if (visible) {
                patternsViewMainRepeater.model = Object.keys(ZynQuick.PlayGridManager.dashboardModels);
            } else {
                patternsViewMainRepeater.model = [];
            }
        }

        ColumnLayout {
            anchors.fill: parent

            Repeater {
                id: patternsViewMainRepeater
                model: Object.keys(ZynQuick.PlayGridManager.dashboardModels)
                delegate: Repeater {
                    id: patternsViewPlaygridRepeater
                    model: ZynQuick.PlayGridManager.dashboardModels[modelData]
                    property string playgridId: modelData

                    QQC2.Button {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*5
                        Layout.preferredHeight: Kirigami.Units.gridUnit*3
                        Layout.alignment: Qt.AlignCenter
                        text: model.text
                        visible: !zynthian.zynthiloops.song.tracksModel.checkIfPatternAlreadyConnected(index)

                        onClicked: {
                            if (playgridPickerPopup.trackObj) {
                                playgridPickerPopup.trackObj.clipsModel.getClip(0).clear();
                                playgridPickerPopup.trackObj.clipsModel.getClip(1).clear();
                                playgridPickerPopup.trackObj.connectedPattern = index;

                                var seq = ZynQuick.PlayGridManager.getSequenceModel(zynthian.zynthiloops.song.scenesModel.selectedMixName).getByPart(playgridPickerPopup.trackIndex, playgridPickerPopup.trackObj.selectedPart);
                                seq.midiChannel = playgridPickerPopup.trackObj.connectedSound;
                                seq.bank = "A"
                                seq.enabled = true;

                                playgridPickerPopup.close();

                                if (playgridPickerPopup.clipObj) {
                                    zynthian.zynthiloops.song.scenesModel.addClipToCurrentScene(playgridPickerPopup.clipObj);
                                } else {
                                    console.log("Error setting clip to scene")
                                }
                            } else {
                                console.log("Error connecting pattern to track")
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
                text: qsTr("All patterns are already assigned to tracks")
                wrapMode: "WordWrap"
                font.italic: true
                font.pointSize: 11
                visible: zynthian.zynthiloops.song.tracksModel.connectedPatternsCount >= 5
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

            ZynthiLoops.BottomBar {
                id: bottomBar
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            TracksViewSoundsBar {
                id: bottomTracksBar
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    QQC2.Popup {
        id: cannotRecordEmptyLayerPopup
        x: Math.round(parent.width/2 - width/2)
        y: Math.round(parent.height/2 - height/2)
        width: Kirigami.Units.gridUnit*12
        height: Kirigami.Units.gridUnit*4
        modal: true

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
        target: zynthian.zynthiloops
        onCannotRecordEmptyLayer: {
            cannotRecordEmptyLayerPopup.open();
        }
    }
}
