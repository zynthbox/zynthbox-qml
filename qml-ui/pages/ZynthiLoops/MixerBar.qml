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

                    VolumeControl {
                        id: masterVolume
                        Layout.preferredWidth: privateProps.cellWidth
                        Layout.maximumWidth: privateProps.cellWidth
                        Layout.fillHeight: true
                        footerText: "Master"

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

                        delegate: RowLayout {
                            width: privateProps.cellWidth
                            height: ListView.view.height

                            VolumeControl {
                                property var audioLevelText: model.track.audioLevel.toFixed(2)

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                headerText: audioLevelText === "-40.00" ? "" : (audioLevelText + " (dB)")
                                footerText: model.track.name
                                audioLeveldB: model.track.audioLevel

                                slider.value: model.track.volume
                                slider.onValueChanged: {
                                    model.track.volume = slider.value
                                }

                                onDoubleClicked: {
                                    slider.value = model.track.initialVolume;
                                }
                            }

                            Kirigami.Separator {
                                Layout.fillHeight: true
                                Layout.preferredWidth: 1
                                color: "#ff31363b"
                                visible: index != root.song.tracksModel.count-1
                            }
                        }
                    }
                }
            }
        }
    }
}
