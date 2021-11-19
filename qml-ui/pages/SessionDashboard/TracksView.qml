/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Session Dashboard page for Zynthian GUI

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
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import JuceGraphics 1.0

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

ColumnLayout {
    id: root

    anchors {
        fill: parent
        topMargin: -Kirigami.Units.smallSpacing
        leftMargin: Kirigami.Units.gridUnit
    }

    property QtObject selectedTrack: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)
    property int itemHeight: layersView.height / 15
    spacing: Kirigami.Units.largeSpacing

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

                        visible: index < 6
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

                                color: Kirigami.Theme.buttonBackgroundColor

                                border.color: "#ff999999"
                                border.width: 1
                                radius: 4

                                QQC2.Label {
                                    width: parent.width
                                    anchors.centerIn: parent
                                    anchors.leftMargin: Kirigami.Units.gridUnit*0.5
                                    anchors.rightMargin: Kirigami.Units.gridUnit*0.5
                                    horizontalAlignment: Text.AlignLeft
                                    text: track.connectedSound >= 0 ? (track.connectedSound+1) + ". "+ zynthian.fixed_layers.selector_list.getDisplayValue(track.connectedSound) : ""
                                    elide: "ElideRight"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        zynthian.session_dashboard.selectedTrack = index;
                                        soundsDialog.open();
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: false
                                Layout.fillHeight: false
                                Layout.alignment: Qt.AlignVCenter

                                Repeater {
                                    model: track.clipsModel
                                    delegate: QQC2.RoundButton {
                                        Layout.fillWidth: false
                                        Layout.fillHeight: false
                                        Layout.preferredWidth: Kirigami.Units.gridUnit*1.5
                                        Layout.preferredHeight: Kirigami.Units.gridUnit*1.5
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: 4
                                        highlighted: trackDelegate.selectedClip == model.clip

                                        onClicked: {
                                            trackDelegate.selectedClip = model.clip;

                                            // TODO : Find a way to select/deselect clip to/from scene
                                            zynthian.zynthiloops.song.scenesModel.toggleClipInCurrentScene(model.clip);
                                            if (track.connectedPattern >= 0) {
                                                var seq = ZynQuick.PlayGridManager.getSequenceModel("Global").get(track.connectedPattern);
                                                seq.bank = model.clip.col === 0 ? "A" : "B";
                                                seq.enabled = true;
                                            }
                                        }

                                        QQC2.Label {
                                            anchors.centerIn: parent
                                            text: model.clip.partName
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.topMargin: Kirigami.Units.gridUnit*0.3
                                Layout.bottomMargin: Kirigami.Units.gridUnit*0.3

                                color: Kirigami.Theme.buttonBackgroundColor
                                border.color: "#99999999"
                                border.width: 1
                                radius: 4

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (trackDelegate.trackHasConnectedPattern) {
                                            zynthian.current_modal_screen_id = "playgrid";
                                            ZynQuick.PlayGridManager.setCurrentPlaygrid("playgrid", ZynQuick.PlayGridManager.sequenceEditorIndex);
                                            var sequence = ZynQuick.PlayGridManager.getSequenceModel("Global");
                                            sequence.activePattern = track.connectedPattern;
                                        }
                                    }
                                }

                                WaveFormItem {
                                    anchors.fill: parent

                                    color: Kirigami.Theme.textColor
                                    source: trackDelegate.selectedClip.path
                                    visible: !trackDelegate.trackHasConnectedPattern && trackDelegate.hasWavLoaded

                                    Rectangle {
                                        x: 0
                                        y: parent.height/2 - height/2
                                        width: parent.width
                                        height: 1
                                        color: Kirigami.Theme.textColor
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
                                    property QtObject sequence: trackDelegate.trackHasConnectedPattern ? ZynQuick.PlayGridManager.getSequenceModel("Global") : null
                                    property QtObject pattern: sequence ? sequence.get(track.connectedPattern) : null
                                    source: pattern ? "image://pattern/Global/" + track.connectedPattern + "/" + (pattern.bankOffset / 8) + "?" + pattern.lastModified : ""
                                    Rectangle { // Progress
                                        anchors {
                                            top: parent.top
                                            bottom: parent.bottom
                                        }
                                        visible: patternVisualiser.sequence.isPlaying && patternVisualiser.pattern.enabled
                                        color: Kirigami.Theme.highlightColor
                                        width: widthFactor // this way the progress rect is the same width as a step
                                        property double widthFactor: parent.width / (patternVisualiser.pattern.width * patternVisualiser.pattern.bankLength)
                                        x: patternVisualiser.pattern.bankPlaybackPosition * widthFactor
                                    }
                                    QQC2.Label {
                                        anchors.fill: parent
                                        horizontalAlignment: Text.AlignRight
                                        verticalAlignment: Text.AlignBottom
                                        text: patternVisualiser.pattern ? patternVisualiser.pattern.objectName : ""
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
                                    visible: !trackDelegate.hasWavLoaded && !trackDelegate.trackHasConnectedPattern

                                    onClicked: {
                                        clipFilePickerDialog.clipObj = trackDelegate.selectedClip;
                                        clipFilePickerDialog.folderModel.folder = clipFilePickerDialog.clipObj.recordingDir;
                                        clipFilePickerDialog.open();
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

                                    onClicked: {
                                        if (trackDelegate.trackHasConnectedPattern) {
                                            track.connectedPattern = -1;
                                        } else {
                                            trackDelegate.selectedClip.clear();
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
                                    visible: !trackDelegate.hasWavLoaded && !trackDelegate.trackHasConnectedPattern

                                    onClicked: {
                                        playgridPickerPopup.trackObj = track;
                                        playgridPickerPopup.clipObj = trackDelegate.selectedClip;
                                        playgridPickerPopup.open();
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
                                        if (!trackDelegate.selectedClip.isRecording) {
                                            trackDelegate.selectedClip.queueRecording("internal", "");
                                        } else {
                                            trackDelegate.selectedClip.stopRecording();
                                            zynthian.zynthiloops.song.scenesModel.toggleClipInCurrentScene(trackDelegate.selectedClip);
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

    QQC2.Dialog {
        id: soundsDialog
        modal: true

        x: root.parent.mapFromGlobal(0, 0).x
        y: root.parent.mapFromGlobal(0, Math.round(Screen.height/2 - height/2)).y
        width: Screen.width - Kirigami.Units.gridUnit*2
        height: Screen.height - Kirigami.Units.gridUnit*2

        header: Kirigami.Heading {
            text: qsTr("Pick a sound for %1").arg(root.selectedTrack.name)
            font.pointSize: 16
            padding: Kirigami.Units.gridUnit
        }

        footer: RowLayout {
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: qsTr("Clear Selection")
                onClicked: {
                    root.selectedTrack.connectedSound = -1;
                    if (root.selectedTrack.connectedPattern >= 0) {
                        var seq = ZynQuick.PlayGridManager.getSequenceModel("Global").get(root.selectedTrack.connectedPattern);
                        seq.midiChannel = root.selectedTrack.connectedSound;
                    }
                    soundsDialog.close();
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: qsTr("Close")
                onClicked: soundsDialog.close();
            }
        }

        contentItem: Item {
            GridLayout {
                rows: 3
                columns: 5
                rowSpacing: Kirigami.Units.gridUnit*2.5
                columnSpacing: rowSpacing

                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.gridUnit
                anchors.rightMargin: Kirigami.Units.gridUnit
                anchors.bottomMargin: Kirigami.Units.gridUnit

                Repeater {
                    model: zynthian.fixed_layers.selector_list
                    delegate: QQC2.RoundButton {
//                        property bool isChained: {
//                            // TODO : Bind to midi_cloned property

//                            if (index >= 5 && index <= 9 &&
//                                root.selectedTrack.connectedSound >=5 && root.selectedTrack.connectedSound <= 9) {
//                                // Highlight set to true for all 6.X slots if any one is selected as all are chained by default
//                                return true;
//                            } else {
//                                // Highlight only if current slot is chained to connected sound
//                                var connected = false;

//                                for (var i=index; i<root.selectedTrack.connectedSound; i++) {
//                                    if (zynthian.fixed_layers.selector_list.getMetadataByIndex(i)["midi_cloned"]) {
//                                        connected = true;
//                                    } else {
//                                        connected = false;
//                                        break;
//                                    }
//                                }

//                                for (var i=root.selectedTrack.connectedSound; i<index; i++) {
//                                    if (zynthian.fixed_layers.selector_list.getMetadataByIndex(i)["midi_cloned"]) {
//                                        connected = true;
//                                    } else {
//                                        connected = false;
//                                        break;
//                                    }
//                                }

//                                return connected;
//                            }
//                        }

                        Kirigami.Theme.highlightColor: {
                            if (root.selectedTrack.connectedSound === index) {
                                return Qt.rgba(
                                    Kirigami.Theme.highlightColor.r,
                                    Kirigami.Theme.highlightColor.g,
                                    Kirigami.Theme.highlightColor.b,
                                    1
                                )
                            } else if (model.metadata.isChainedToConnectedSound) {
                                return Qt.rgba(
                                    Kirigami.Theme.highlightColor.r,
                                    Kirigami.Theme.highlightColor.g,
                                    Kirigami.Theme.highlightColor.b,
                                    0.3
                               )
                            } else {
                                return Qt.rgba(
                                    Kirigami.Theme.highlightColor.r,
                                    Kirigami.Theme.highlightColor.g,
                                    Kirigami.Theme.highlightColor.b,
                                    1
                                )
                            }
                        }

                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: (parent.width-parent.columnSpacing*(parent.columns-1))/parent.columns
                        Layout.preferredHeight: (parent.height-parent.rowSpacing*(parent.rows-1))/parent.rows
                        text: model.display
                        radius: 4
                        highlighted: root.selectedTrack.connectedSound === index || model.metadata.isChainedToConnectedSound
                        onClicked: {
                            root.selectedTrack.connectedSound = index;

                            if (root.selectedTrack.connectedPattern >= 0) {
                                var seq = ZynQuick.PlayGridManager.getSequenceModel("Global").get(root.selectedTrack.connectedPattern);
                                seq.midiChannel = root.selectedTrack.connectedSound;
                            }

                            zynthian.fixed_layers.activate_index(root.selectedTrack.connectedSound);
                            soundsDialog.close();
                        }

                        Kirigami.Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.right
                            anchors.leftMargin: Kirigami.Units.gridUnit*0.5
                            anchors.rightMargin: Kirigami.Units.gridUnit*0.5
                            width: Kirigami.Units.gridUnit*1.5
                            height: width

                            source: "link"
                            color: Kirigami.Theme.textColor
                            visible: (index+1)%5 !== 0
                            opacity: model.metadata.midi_cloned || (index >= 5 && index <= 9)? 1 : 0.4

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (!(index >= 5 && index <= 9)) {
                                        console.log("Toggle layer chaining")
                                        Zynthian.CommonUtils.toggleLayerChaining(model);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
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
                zynthian.zynthiloops.song.scenesModel.toggleClipInCurrentScene(clipObj);
            }
        }
    }

    QQC2.Popup {
        property QtObject trackObj
        property QtObject clipObj

        id: playgridPickerPopup
        x: root.parent.mapFromGlobal(Math.round(Screen.width/2 - width/2), 0).x
        y: root.parent.mapFromGlobal(0, Math.round(Screen.height/2 - height/2)).y
        width: Kirigami.Units.gridUnit*12
        height: Kirigami.Units.gridUnit*12
        modal: true

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
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit*5
                        Layout.alignment: Qt.AlignCenter
                        text: model.text

                        onClicked: {
                            if (playgridPickerPopup.trackObj) {
                                playgridPickerPopup.trackObj.clipsModel.getClip(0).clear();
                                playgridPickerPopup.trackObj.clipsModel.getClip(1).clear();
                                playgridPickerPopup.trackObj.connectedPattern = index;

                                var seq = ZynQuick.PlayGridManager.getSequenceModel("Global").get(playgridPickerPopup.trackObj.connectedPattern);
                                seq.midiChannel = playgridPickerPopup.trackObj.connectedSound;
                                seq.bank = "A"
                                seq.enabled = true;

                                playgridPickerPopup.close();

                                if (playgridPickerPopup.clipObj) {
                                    zynthian.zynthiloops.song.scenesModel.toggleClipInCurrentScene(playgridPickerPopup.clipObj);
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
        }
    }
}
