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

//import Zynthian 1.0 as Zynthian

Rectangle {
    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_SELECT_SHORT":
                bottomBar.controlType = BottomBar.ControlType.Track;
                bottomBar.controlObj = zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack);

                bottomStack.currentIndex = 0;
                mixerActionBtn.checked = false;

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
        property int cellWidth: (tableLayout.width - loopGrid.columnSpacing)/13
    }

    GridLayout {
        id: root
        rows: 1
        anchors.fill: parent
        anchors.topMargin: Kirigami.Units.gridUnit*0.3

        readonly property QtObject song: zynthian.zynthiloops.song

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

                    VolumeControl {
                        id: externalVolume
                        Layout.preferredWidth: privateProps.cellWidth + 6
                        Layout.maximumWidth: privateProps.cellWidth + 6
                        Layout.bottomMargin: 5
                        Layout.fillHeight: true
                        footerText: "External"
                        audioLeveldB: -200
                        inputAudioLevelVisible: false

                        slider {
                            value: 0
                            from: 0
                            to: 100
                            stepSize: 1
                            onValueChanged: {
                            }
                        }
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
                                mixerActionBtn.checked = false;
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

                                            anchors.fill: parent

                                            enabled: !model.track.muted
                                            headerText: model.track.muted || model.track.audioLevel <= -40 ? "" : (audioLevelText + " (dB)")
        //                                    footerText: model.track.name
                                            audioLeveldB:  model.track.muted ? -400 : model.track.audioLevel
                                            inputAudioLeveldB: highlighted
                                                                ? !model.track.muted
                                                                    ? zynthian.zynthiloops.recordingAudioLevel
                                                                    : -400
                                                                : -400

                                            slider.value: model.track.volume
                                            slider.onValueChanged: {
                                                model.track.volume = slider.value
                                            }

                                            onClicked: {
                                                tracksVolumeRow.handleClick(track);
                                            }
                                            onDoubleClicked: {
                                                slider.value = model.track.initialVolume;
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
                                                    target: model.track
                                                    onChainedSoundsChanged: {
                                                        soundLabel.updateSoundName();
                                                    }
                                                }

                                                function updateSoundName() {
                                                    var text = "";

                                                    for (var id in model.track.chainedSounds) {
                                                        if (model.track.chainedSounds[id] >= 0 &&
                                                            model.track.checkIfLayerExists(model.track.chainedSounds[id])) {
                                                            var soundName = zynthian.fixed_layers.selector_list.getDisplayValue(model.track.chainedSounds[id]).split(">");
                                                            text = qsTr("%1 (%2)").arg(soundName[1] ? soundName[1].trim() : "").arg(soundName[0] ? soundName[0].trim() : "")
                                                            break;
                                                        }
                                                    }

                                                    soundLabel.text = text;
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
                        Layout.preferredWidth: privateProps.cellWidth*2 - 2
                        Layout.bottomMargin: 5

                        VolumeControl {
                            id: masterVolume
                            width: privateProps.cellWidth
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            headerText: zynthian.zynthiloops.masterAudioLevel <= -40
                                            ? ""
                                            : (zynthian.zynthiloops.masterAudioLevel.toFixed(2) + " (dB)")
                            footerText: "Master"
                            audioLeveldB: zynthian.zynthiloops.masterAudioLevel
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
                                onValueChanged: {
                                    zynthian.master_alsa_mixer.volume = masterVolume.slider.value;
                                    zynthian.zynthiloops.song.volume = masterVolume.slider.value;
                                }
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
