/* -*- coding: utf-8 -*-7
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

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
import QtQuick.Controls 2.2 as QQC2
import QtQml.Models 2.10
import QtGraphicalEffects 1.0

import org.kde.kirigami 2.4 as Kirigami
import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian

QQC2.AbstractButton {
    id: root

    readonly property QtObject song: zynqtgui.sketchpad.song
    readonly property int colIndex: index
    property bool isPlaying
    property color backgroundColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, root.backgroundOpacity)
    property real backgroundOpacity: 0.05
    property bool highlighted: false
    property color highlightColor: highlighted
                                       ? Kirigami.Theme.highlightColor
                                       : "transparent"
    property bool isInScene: channel.selectedClipNames
                                ? channel.selectedClipNames.join("").length > 0
                                : false
    property QtObject channel: null

    property QtObject sequence
    property QtObject pattern

    onPressed: forceActiveFocus()

    Timer {
        id: highlightThrottle
        interval: 0; running: false; repeat: false;
        onTriggered: {
            if (zynqtgui.sketchpad.song && zynqtgui.sketchpad.song.isLoading === false) {
                root.highlighted = channel.sceneClip.row === zynqtgui.sketchpad.selectedTrackId &&
                                channel.sceneClip.col === zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex // zynqtgui.bottomBarControlObj === channel.sceneClip
            }
        }
    }
    onChannelChanged: highlightThrottle.restart()
    Connections {
        target: zynqtgui.sketchpad
        onSelected_track_id_changed: highlightThrottle.restart()
    }
    Connections {
        target: zynqtgui.sketchpad
        onSong_changed: highlightThrottle.restart()
    }
    Connections {
        target: zynqtgui.sketchpad.song
        onIsLoadingChanged: highlightThrottle.restart()
    }
    Connections {
        target: zynqtgui.sketchpad.song.scenesModel
        onSelected_sketchpad_song_index_changed: highlightThrottle.restart()
    }

    contentItem: Item {
        // QQC2.Label {
        //     width: parent.width - 8
        //     anchors.centerIn: parent
        //     horizontalAlignment: "AlignHCenter"
        //     elide: "ElideRight"
        //     color: root.isInScene ? "#ffffff" : "#f44336" // Color text red when muted
        //     text: root.channel.selectedClipNames.join("").toUpperCase()
        //     font.pointSize: 16

        //     layer.enabled: true
        //     layer.effect: DropShadow {
        //         verticalOffset: 0
        //         color: "#80000000"
        //         radius: 5
        //         samples: 11
        //     }
        // }

        RowLayout {
            id: activeItemsRow
            property string highlightColor: "#ffffffff" // green "#ccaaff00"
            property string inactiveColor: "#33ffffff"
            anchors.centerIn: parent
            spacing: 0
            visible: ["synth", "sample-loop"].indexOf(root.channel.trackType) >= 0

            Repeater {
                model: root.channel ? 5 : 0

                QQC2.Label {
                    property bool isClipEnabled: root.channel.getClipsModelById(index).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).enabled
                    property bool patternHasNotes: Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName).getByClipId(root.channel.id, index).hasNotes

                    color: {
                        let occupied = false
                        if (root.channel.trackType == "synth" && patternHasNotes && isClipEnabled) {
                            occupied = true
                        } else if (root.channel.trackType == "sample-loop" && root.channel.occupiedSketchSlots[index] && isClipEnabled) {
                            occupied = true
                        }

                        if (occupied) {
                            return activeItemsRow.highlightColor
                        } else {
                            return activeItemsRow.inactiveColor
                        }
                    }
                    text: {
                        if (root.channel.trackType == "synth") {
                            return String.fromCharCode(index + 65)
                        } else if (root.channel.trackType == "sample-loop") {
                            return index + 1
                        }
                    }

                    font.pointSize: 12
                    font.bold: true
                }
            }
        }
    }

    background: Rectangle {
        color: root.backgroundColor

        border.width: 1
        border.color: root.highlightColor
                        ? root.highlightColor
                        : root.highlighted
                            ? Kirigami.Theme.highlightColor
                            : "transparent"

        Rectangle {
            id: progressRect
            anchors.bottom: parent.bottom
            visible: root.isInScene &&
                     channel.sceneClip.isPlaying &&
                     channel.trackType === "sample-loop" &&
                     !channel.sceneClip.isEmpty

            color: Kirigami.Theme.textColor
            height: Kirigami.Units.smallSpacing
            width: visible ? (channel.sceneClip.progress - channel.sceneClip.metadata.startPosition)/adjustment : 0
            property double adjustment: visible ? (((60/Zynthbox.SyncTimer.bpm) * channel.sceneClip.metadata.length) / parent.width) : 1
        }
        Rectangle {
            id: patternProgressRect

            anchors.bottom: parent.bottom
            visible: root.isInScene &&
                     channel.trackType !== "sample-loop" &&
                     sequence.isPlaying &&
                     root.pattern.hasNotes
            color: Kirigami.Theme.textColor
            height: Kirigami.Units.smallSpacing
            width: pattern ? (parent.width/(16*pattern.availableBars))*pattern.bankPlaybackPosition : 0
        }
    }

    onActiveFocusChanged: {
        console.log("Item with active Focus :", activeFocus)
    }

}
