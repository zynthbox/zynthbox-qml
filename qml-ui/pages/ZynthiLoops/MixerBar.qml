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

        //Try to fit exactly until a minimum allowed size
        property int cellWidth: Math.round(
                                    Math.max(Kirigami.Units.gridUnit * 5,
                                            tableLayout.width / 9))
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
                    Layout.preferredWidth: privateProps.cellWidth
                    Layout.maximumWidth: privateProps.cellWidth
                    Layout.fillHeight: true
                    headerText: "Master"

                    slider.value: 100
                }

                Kirigami.Separator {
                    Layout.preferredWidth: 2
                    Layout.fillHeight: true
                    color: Kirigami.Theme.highlightColor
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

                        slider.value: 100
                    }
                }
            }
        }
    }
}

