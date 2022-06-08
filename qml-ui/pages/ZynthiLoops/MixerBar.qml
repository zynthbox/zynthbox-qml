/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

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
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls.Styles 1.4

import libzl 1.0 as ZL
import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

Rectangle {
    id: root

    readonly property QtObject song: zynthian.zynthiloops.song
    readonly property QtObject selectedTrack: song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)

    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_SELECT_SHORT":
                bottomBar.controlType = BottomBar.ControlType.Track;
                bottomBar.controlObj = zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack);

                bottomStack.slotsBar.bottomBarButton.checked = true

                return true;

            case "NAVIGATE_LEFT":
                if (zynthian.session_dashboard.selectedTrack > 0) {
                    zynthian.session_dashboard.selectedTrack -= 1;
                }

                return true;

            case "NAVIGATE_RIGHT":
                if (zynthian.session_dashboard.selectedTrack < 9) {
                    zynthian.session_dashboard.selectedTrack += 1;
                }

                return true;
        }
        
        return false;
    }

    QtObject {
        id: privateProps

        //Try to fit exactly 12 mixers + a master mixer
        property int cellWidth: (root.width - loopGrid.columnSpacing)/13
    }

    GridLayout {
        rows: 1
        anchors.fill: parent

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true

            Kirigami.Heading {
                visible: false
                text: qsTr("Mixer : %1").arg(song.name)
            }

            ColumnLayout {
                id: tableLayout

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
                        Layout.minimumWidth: privateProps.cellWidth*1.5 + 6
                        Layout.maximumWidth: privateProps.cellWidth*1.5 + 6
                        Layout.bottomMargin: 5
                        Layout.fillHeight: true
                    }

                    Kirigami.Separator {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: "#ff31363b"
                    }

                    ListView {
                        id: tracksVolumeRow

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        clip: true
                        spacing: 0
                        orientation: Qt.Horizontal
                        boundsBehavior: Flickable.StopAtBounds

                        model: root.song.tracksModel

                        function handleClick(track) {
                            if (zynthian.session_dashboard.selectedTrack !== track.id) {
                                zynthian.session_dashboard.disableNextSoundSwitchTimer();
                                zynthian.session_dashboard.selectedTrack = track.id;
                                bottomBar.controlType = BottomBar.ControlType.Track;
                                bottomBar.controlObj = zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack);
                            } else {
                                bottomBar.controlType = BottomBar.ControlType.Track;
                                bottomBar.controlObj = zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack);

                                bottomStack.currentIndex = 0
                            }
                        }

                        delegate: Rectangle {
                            property bool highlighted: index === zynthian.session_dashboard.selectedTrack
                            width: privateProps.cellWidth
                            height: ListView.view.height
                            color: highlighted ? "#22ffffff" : "transparent"
                            radius: 2
                            border.width: 1
                            border.color: highlighted ? Kirigami.Theme.highlightColor : "transparent"

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    tracksVolumeRow.handleClick(track);
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.topMargin: 4
                                spacing: 0

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 0

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        VolumeControl {
                                            id: volumeControl

                                            property var audioLevelText: model.track.audioLevel.toFixed(2)
                                            property QtObject sampleClipObject: ZynQuick.PlayGridManager.getClipById(model.track.samples[model.track.selectedSlotRow].cppObjId);
                                            property real synthAudioLevel

                                            anchors.fill: parent

                                            enabled: !model.track.muted
                                            headerText: model.track.muted || model.track.audioLevel <= -40 ? "" : (audioLevelText + " (dB)")
        //                                    footerText: model.track.name
                                            audioLeveldB: visible
                                                            ? !model.track.muted
                                                                ? model.track.trackAudioType === "sample-loop"
                                                                    ? ZL.AudioLevels.add(model.track.audioLevel, synthAudioLevel)
                                                                    : model.track.trackAudioType === "synth"
                                                                        ? synthAudioLevel
                                                                        : model.track.trackAudioType === "sample-trig" ||
                                                                            model.track.trackAudioType === "sample-slice"
                                                                            ? sampleClipObject
                                                                                ? sampleClipObject.audioLevel
                                                                                : -400
                                                                            : -400
                                                                : -400
                                                            : -400
                                            inputAudioLevelVisible: false

                                            onValueChanged: {
                                                 model.track.volume = slider.value
                                            }

                                            onClicked: {
                                                tracksVolumeRow.handleClick(track);
                                            }
                                            onDoubleClicked: {
                                                model.track.volume = model.track.initialVolume;
                                            }

                                            Binding {
                                                target: volumeControl.slider
                                                property: "value"
                                                value: model.track.volume
                                            }
                                            Binding {
                                                target: volumeControl
                                                property: "synthAudioLevel"
                                                value: root.visible ? ZL.AudioLevels.tracks[model.track.id] : -400
                                            }
                                        }

                                        Rectangle {
                                            width: volumeControl.slider.height
                                            height: soundLabel.height*1.5

                                            anchors.left: parent.right
                                            anchors.bottom: parent.bottom
                                            anchors.leftMargin: -soundLabel.height*2
                                            anchors.bottomMargin: -(soundLabel.height/2)

                                            transform: Rotation {
                                                origin.x: 0
                                                origin.y: 0
                                                angle: -90
                                            }

                                            Kirigami.Theme.inherit: false
                                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                            color: "transparent"

                                            border.color: "transparent"
                                            border.width: 1
                                            radius: 4

                                            QQC2.Label {
                                                id: soundLabel

                                                anchors.left: parent.left
                                                anchors.right: parent.right
    //                                            anchors.leftMargin: Kirigami.Units.gridUnit*0.5
    //                                            anchors.rightMargin: Kirigami.Units.gridUnit*0.5
                                                anchors.verticalCenter: parent.verticalCenter
                                                elide: "ElideRight"

                                                font.pointSize: 8

                                                Timer {
                                                    id: soundnameUpdater;
                                                    repeat: false; running: false; interval: 1;
                                                    onTriggered: soundLabel.updateSoundName();
                                                }
                                                Component.onCompleted: soundLabel.updateSoundName();
                                                Connections {
                                                    target: zynthian.fixed_layers
                                                    onList_updated: soundnameUpdater.restart();
                                                }

                                                Connections {
                                                    target: model.track
                                                    onChainedSoundsChanged: model.track.trackAudioType === "synth" ? soundnameUpdater.restart() : false
                                                    onSamplesChanged: ["sample-trig", "sample-slice"].indexOf(model.track.trackAudioType) >= 0 ? soundnameUpdater.restart() : false
                                                    onTrackAudioTypeChanged: soundnameUpdater.restart()
                                                    onSceneClipChanged: model.track.trackAudioType === "sample-loop" ? soundnameUpdater.restart() : false
                                                    onSelectedSampleRowChanged: ["sample-trig", "sample-slice", "external"].indexOf(model.track.trackAudioType) >= 0 ? soundnameUpdater.restart() : false
                                                }

                                                Connections {
                                                    target: model.track.sceneClip
                                                    onPathChanged: model.track.trackAudioType === "sample-loop" ? soundnameUpdater.restart() : false
                                                }
                                                Connections {
                                                    target: root
                                                    onVisibleChanged: root.visible ? soundLabel.updateSoundName() : false
                                                }

                                                function updateSoundName() {
                                                    if (root.visible) {
                                                        var text = "";

                                                        if (model.track.trackAudioType === "synth") {
                                                            for (var id in model.track.chainedSounds) {
                                                                if (model.track.chainedSounds[id] >= 0 &&
                                                                    model.track.checkIfLayerExists(model.track.chainedSounds[id])) {
                                                                    var soundName = zynthian.fixed_layers.selector_list.getDisplayValue(model.track.chainedSounds[id]).split(">");
                                                                    text = qsTr("%1").arg(soundName[1] ? soundName[1].trim() : "")
                                                                    break;
                                                                }
                                                            }
                                                        } else if (model.track.trackAudioType === "sample-trig" ||
                                                                model.track.trackAudioType === "sample-slice") {
                                                            try {
                                                                text = model.track.samples[model.track.selectedSlotRow].path.split("/").pop()
                                                            } catch (e) {}
                                                        } else if (model.track.trackAudioType === "sample-loop") {
                                                            try {
                                                                text = model.track.sceneClip.path.split("/").pop()
                                                            } catch (e) {}
                                                        }

                                                        soundLabel.text = text;
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    QQC2.Label {
                                        Layout.alignment: Qt.AlignCenter
                                        Layout.fillWidth: true
                                        horizontalAlignment: "AlignHCenter"
                                        elide: "ElideRight"
                                        text: model.track.name
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: false
                                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                                        Layout.margins: 4
                                        spacing: 2

                                        QQC2.RoundButton {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: (parent.width-parent.spacing)/2
                                            radius: 2
                                            font.pointSize: 8
                                            checkable: true
                                            text: qsTr("S")
                                            background: Rectangle {
                                                radius: parent.radius
                                                border.width: 1
                                                border.color: Qt.rgba(50, 50, 50, 0.1)
                                                color: parent.down || parent.checked ? "#4caf50" : Qt.lighter(Kirigami.Theme.backgroundColor, 1.3)
                                            }
                                            onCheckedChanged: {
                                            }
                                        }
                                        QQC2.RoundButton {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: (parent.width-parent.spacing)/2
                                            radius: 2
                                            font.pointSize: 8
                                            checkable: true
                                            text: qsTr("M")
                                            background: Rectangle {
                                                radius: parent.radius
                                                border.width: 1
                                                border.color: Qt.rgba(50, 50, 50, 0.1)
                                                color: parent.down || parent.checked ? "#f44336" : Qt.lighter(Kirigami.Theme.backgroundColor, 1.3)
                                            }
                                            onCheckedChanged: {
                                                model.track.muted = checked;
                                            }
                                        }
                                    }
                                }

                                Kirigami.Separator {
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 1
                                    color: "#ff31363b"
                                    visible: index != root.song.tracksModel.count-1 && !highlighted
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        Layout.leftMargin: 2
                        Layout.preferredWidth: privateProps.cellWidth*1.5 - 10
                        Layout.bottomMargin: 5

                        VolumeControl {
                            id: masterVolume
                            width: privateProps.cellWidth
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            headerText: root.visible
                                            ? zynthian.zynthiloops.masterAudioLevel <= -40
                                                ? ""
                                                : (zynthian.zynthiloops.masterAudioLevel.toFixed(2) + " (dB)")
                                            : ""
                            footerText: "Master"
                            audioLeveldB: visible ? zynthian.zynthiloops.masterAudioLevel :  -400
                            inputAudioLevelVisible: false

                            Binding {
                                target: masterVolume.slider
                                property: "value"
                                value: zynthian.master_alsa_mixer.volume
                            }

                            slider {
                                value: zynthian.master_alsa_mixer.volume
                                from: 0
                                to: 100
                                stepSize: 1
                            }
                            onValueChanged: {
                                zynthian.master_alsa_mixer.volume = masterVolume.slider.value;
                                zynthian.zynthiloops.song.volume = masterVolume.slider.value;
                            }
                        }
                    }

                    Kirigami.Separator {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: "#ff31363b"
                    }
                }
            }
        }
    }
}
