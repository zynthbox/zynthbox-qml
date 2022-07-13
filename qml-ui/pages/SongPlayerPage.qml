/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Song Player Page

Copyright (C) 2022 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import libzl 1.0 as ZL
import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

Zynthian.ScreenPage {
    id: component
    screenId: "song_player"
    title: qsTr("Song Player")

    function cuiaCallback(cuia) {
        var returnValue = false;
        if (multitrackRecorderPopup.opened) {
            returnValue = multitrackRecorderPopup.cuiaCallback(cuia);
        }
        return returnValue;
    }

    contextualActions: [
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            text: qsTr("Record Song")
            onTriggered: {
                multitrackRecorderPopup.recordSong(zynthian.zynthiloops.song)
            }
        }
    ]
    Zynthian.MultitrackRecorderPopup {
        id: multitrackRecorderPopup
    }
    ColumnLayout {
        anchors.fill: parent;
        Kirigami.Heading {
            Layout.fillWidth: true
            text: component.title
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit
            spacing: 0
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Button
            Repeater {
                id: segmentsRepeater
                model: component.visible ? zynthian.zynthiloops.song.mixesModel.selectedMix.segmentsModel : 0
                property int totalDuration: ZynQuick.PlayGridManager.syncTimer.getMultiplier() * zynthian.zynthiloops.song.mixesModel.selectedMix.segmentsModel.totalBeatDuration
                delegate: Item {
                    id: segmentDelegate
                    property QtObject segment: model.segment
                    property int duration: ZynQuick.PlayGridManager.syncTimer.getMultiplier() * (segmentDelegate.segment.barLength * 4 + segmentDelegate.segment.beatLength)
                    Layout.fillWidth: true
                    Layout.preferredWidth: component.width * (segmentDelegate.duration / segmentsRepeater.totalDuration)
                    Layout.preferredHeight: Kirigami.Units.gridUnit
                    Rectangle {
                        anchors {
                            fill: parent;
                            margins: 1
                        }
                        border {
                            width: 1
                            color: Kirigami.Theme.focusColor
                        }
                        color: Kirigami.Theme.backgroundColor
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.minimumHeight: 1
            Layout.maximumHeight: 1
            Item {
                height: 1
                width: 1
                y: 0
                x: component.visible ? parent.width * (ZynQuick.SegmentHandler.playhead / segmentsRepeater.totalDuration) : 0
                //onXChanged: console.log("New position", x, parent.width, ZynQuick.SegmentHandler.playhead, segmentsRepeater.totalDuration);
                Rectangle {
                    anchors {
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                    height: Kirigami.Units.gridUnit
                    width: 3
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: Kirigami.Theme.focusColor
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
