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

    QtObject {
        id: privateProps

        //Try to fit exactly 12 mixers + a master mixer
        property int cellWidth: Math.round(tableLayout.width/13 - loopGrid.columnSpacing*2) + 1
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

                    Connections {
                        target: zynthian.status_information
                        onStatus_changed: {
                            // masterVolume.audioLeveldB = zynthian.status_information.peakB;
                        }
                    }

                    VolumeControl {
                        id: masterVolume
                        Layout.preferredWidth: privateProps.cellWidth
                        Layout.maximumWidth: privateProps.cellWidth
                        Layout.fillHeight: true
                        headerText: zynthian.zynthiloops.masterAudioLevel <= -40
                                        ? ""
                                        : (zynthian.zynthiloops.masterAudioLevel.toFixed(2) + " (dB)")
                        footerText: "Master"
                        audioLeveldB: zynthian.zynthiloops.masterAudioLevel
                        inputAudioLeveldB: -200

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

                        delegate: Rectangle {
                            property bool highlighted: index === zynthian.session_dashboard.selectedTrack
                            width: privateProps.cellWidth
                            height: ListView.view.height
                            color: "transparent"
                            radius: 2
                            border.width: 1
                            border.color: highlighted ? Kirigami.Theme.highlightColor : "transparent"

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

                                            headerText: model.track.audioLevel <= -40 ? "" : (audioLevelText + " (dB)")
        //                                    footerText: model.track.name
                                            audioLeveldB:  model.track.audioLevel
                                            inputAudioLeveldB: highlighted ? zynthian.zynthiloops.recordingAudioLevel : -200

                                            slider.value: model.track.volume
                                            slider.onValueChanged: {
                                                model.track.volume = slider.value
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
                }
            }
        }
    }
}
