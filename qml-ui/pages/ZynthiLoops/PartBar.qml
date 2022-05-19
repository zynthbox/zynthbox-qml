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

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick
import JuceGraphics 1.0

// GridLayout so TabbedControlView knows how to navigate it
Rectangle {
    id: root

    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    property QtObject bottomBar: null
    property QtObject selectedTrack: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)

    function cuiaCallback(cuia) {
        console.log("### Part Bar CUIA Callback :", cuia)

        var clip;
        var returnVal = false

        switch (cuia) {
            case "TRACK_1":
            case "TRACK_6":
                clip = root.selectedTrack.getClipsModelByPart(0).getClip(zynthian.zynthiloops.selectedClipCol)
                clip.enabled = !clip.enabled
                returnVal = true
                break

            case "TRACK_2":
            case "TRACK_7":
                clip = root.selectedTrack.getClipsModelByPart(1).getClip(zynthian.zynthiloops.selectedClipCol)
                clip.enabled = !clip.enabled
                returnVal = true
                break

            case "TRACK_3":
            case "TRACK_8":
                clip = root.selectedTrack.getClipsModelByPart(2).getClip(zynthian.zynthiloops.selectedClipCol)
                clip.enabled = !clip.enabled
                returnVal = true
                break

            case "TRACK_4":
            case "TRACK_9":
                clip = root.selectedTrack.getClipsModelByPart(3).getClip(zynthian.zynthiloops.selectedClipCol)
                clip.enabled = !clip.enabled
                returnVal = true
                break

            case "TRACK_5":
            case "TRACK_10":
                clip = root.selectedTrack.getClipsModelByPart(4).getClip(zynthian.zynthiloops.selectedClipCol)
                clip.enabled = !clip.enabled
                returnVal = true
                break

            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.trackButton.checked = true
                returnVal = true
                break
        }

        console.log("### Part Bar CUIA Callback :", selectedTrack.id, zynthian.zynthiloops.song.scenesModel.selectedSceneIndex, cuia, clip)

        return returnVal;
    }

    GridLayout {
        anchors.fill: parent
        rows: 1

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
                    Layout.minimumWidth: privateProps.cellWidth + 6
                    Layout.maximumWidth: privateProps.cellWidth + 6
                    Layout.bottomMargin: 5
                    Layout.fillHeight: true
                }

                RowLayout {
                    id: contentColumn
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.bottomMargin: 5

                    spacing: 1

                    // Spacer
                    Item {
                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                    }

                    Repeater {
                        model: 10
                        delegate: PartBarDelegate {
                            Layout.fillWidth: false
                            Layout.fillHeight: true
                            Layout.preferredWidth: privateProps.cellWidth
                            track: zynthian.zynthiloops.song.tracksModel.getTrack(model.index)
                        }
                    }

                    Item {
                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        Layout.preferredWidth: privateProps.cellWidth*2
                    }
                }
            }
        }
    }
}
