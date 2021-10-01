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

// GridLayout so TabbedControlView knows how to navigate it
GridLayout {
    id: root
    rows: 1
    Layout.fillWidth: true

    property QtObject bottomBar: null
    readonly property QtObject song: zynthian.zynthiloops.song


    QtObject {
        id: privateProps

        //Try to fit exactly 12 mixers + master (same width as loopgrid)
        property int cellWidth: Math.round(tableLayout.width/13 - loopGrid.columnSpacing*2)
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true

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
                    headerText: "Master"

                    border.width: 1
                    border.color: Kirigami.Theme.highlightColor

                    Binding {
                        target: masterVolume.slider
                        property: "value"
                        value: zynthian.master_alsa_mixer.volume
                    }

                    slider {
                        value: zynthian.master_alsa_mixer.volume
                        from: 50
                        to: 100
                        stepSize: 1
                        onValueChanged: {
                            zynthian.master_alsa_mixer.volume = masterVolume.slider.value;
                        }
                    }
                }

                ListView {
                    id: tracksVolumeRow

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true
                    spacing: 1
                    orientation: Qt.Horizontal
                    boundsBehavior: Flickable.StopAtBounds

                    model: root.song.tracksModel

                    delegate: VolumeControl {
                        width: privateProps.cellWidth
                        height: ListView.view.height
                        headerText: model.track.name
                        footerText: model.track.audioLevel.toFixed(2) + " (dB)"
                        audioLeveldB: model.track.audioLevel

                        slider.value: model.track.volume
                        slider.onValueChanged: {
                            model.track.volume = slider.value
                        }
                    }
                }
            }
        }
    }
}

