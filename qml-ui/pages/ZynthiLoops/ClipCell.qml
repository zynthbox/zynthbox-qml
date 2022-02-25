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
import org.kde.kirigami 2.4 as Kirigami
import org.zynthian.quick 1.0 as ZynQuick
import Zynthian 1.0 as Zynthian

QQC2.AbstractButton {
    id: root

    readonly property QtObject song: zynthian.zynthiloops.song
    readonly property int colIndex: index
    property bool isPlaying
    property bool highlighted: false
    property color backgroundColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, root.backgroundOpacity)
    property real backgroundOpacity: 0.05
    property color highlightColor
    property QtObject sequence: track.connectedPattern >= 0 ? ZynQuick.PlayGridManager.getSequenceModel("Scene "+zynthian.zynthiloops.song.scenesModel.selectedSceneName) : null
    property QtObject pattern: sequence ? sequence.get(track.connectedPattern) : null


    onPressed: forceActiveFocus()

    contentItem: Item {
//        TableHeaderLabel {
//            anchors.centerIn: parent
//            text: model.clip.path.length > 0 ? "W" : ""
//            // text: "Clip " + (clip.col+1) // clip.name
//            // text2: clip.length + " Bar"
//        }
        // FIXME: why TableHeaderLabel has a size of 0?
//        QQC2.Label {
//            id: label
//            anchors {
//                right: parent.right
//                bottom: parent.bottom
//            }

//            Connections {
//                target: model.clip
//                onPathChanged: textTimer.restart()
//                onIsPlayingChanged: textTimer.restart()
//            }
//            Connections {
//                target: track
//                onConnectedPatternChanged: textTimer.restart()
//            }
//            Connections {
//                target: sequence
//                onIsPlayingChanged: textTimer.restart()
//            }
//            Connections {
//                target: pattern
//                onLastModifiedChanged: textTimer.restart()
//            }
//            Timer {
//                id: textTimer
//                interval: 250
//                onTriggered: {
//                    if (model.clip.path.length > 0) {
//                        if (model.clip.isPlaying && model.clip.currentBeat >= 0) {
//                            label.text = (model.clip.currentBeat+1) + "/" + model.clip.length
//                        } else {
//                            label.text = model.clip.length
//                        }
//                    } else if (track.connectedPattern >= 0) {
//                        var hasNotes = pattern.bankHasNotes(0)

//                        label.text = hasNotes
//                                ? sequence && sequence.isPlaying
//                                ? (parseInt(pattern.bankPlaybackPosition/4) + 1) + "/" + (pattern.availableBars*4)
//                                : (pattern.availableBars*4)
//                                : ""
//                    } else {
//                        label.text =  ""
//                    }
//                }
//            }
//        }

        Image {
            id: patternVisualiser
            anchors.fill: parent
            smooth: false

            visible: (model.clip.inCurrentScene || root.song.scenesModel.isClipInScene(model.clip, model.clip.col)) &&
                     model.clip.clipTrack.trackAudioType !== "sample-loop" &&
                     track.connectedPattern >= 0 &&
                     pattern.bankHasNotes(0) &&
                     pattern.lastModified
            source: pattern ? "image://pattern/Scene "+zynthian.zynthiloops.song.scenesModel.selectedSceneName+"/" + model.clip.clipTrack.connectedPattern + "/0?" + pattern.lastModified : ""
        }

        QQC2.Label {
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
            visible: (model.clip.inCurrentScene || root.song.scenesModel.isClipInScene(model.clip, model.clip.col)) &&
                     model.clip.clipTrack.trackAudioType === "sample-loop" &&
                     model.clip.path &&
                     model.clip.path.length > 0
            text: qsTr("%1%2")
                    .arg(model.clip.isPlaying &&
                         model.clip.currentBeat >= 0
                            ? (model.clip.currentBeat+1) + "/"
                            : "")
                    .arg(model.clip.length)
        }

        QQC2.Label {
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
            visible: (model.clip.inCurrentScene || root.song.scenesModel.isClipInScene(model.clip, model.clip.col)) &&
                     model.clip.clipTrack.trackAudioType !== "sample-loop" &&
                     track.connectedPattern >= 0 &&
                     pattern.bankHasNotes(0) &&
                     pattern.lastModified
            text: qsTr("%1%2")
                    .arg(pattern.lastModified && pattern.bankHasNotes(0) && sequence && sequence.isPlaying
                            ? (parseInt(pattern.bankPlaybackPosition/4) + 1) + "/"
                            : "")
                    .arg(pattern.availableBars*4)
        }


//        Kirigami.Icon {
//            width: 24
//            height: 24
//            color: "white"
//            anchors.centerIn: parent

//            source: "media-playback-start"
//            visible: root.isPlaying
//        }

        QQC2.Label {
            anchors.centerIn: parent
            color: "#f44336"
            text: qsTr("Mute")
            visible: !(model.clip.inCurrentScene || root.song.scenesModel.isClipInScene(model.clip, model.clip.col))
        }

        QQC2.Label {
            anchors.centerIn: parent
            color: "#ffffff"
            text: qsTr("Loop")
            visible: (model.clip.inCurrentScene || root.song.scenesModel.isClipInScene(model.clip, model.clip.col)) &&
                     model.clip.clipTrack.trackAudioType === "sample-loop" &&
                     model.clip.path &&
                     model.clip.path.length > 0
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
            visible: (model.clip.inCurrentScene || root.song.scenesModel.isClipInScene(model.clip, model.clip.col)) &&
                     model.clip.clipTrack.trackAudioType === "sample-loop" &&
                     model.clip.path &&
                     model.clip.path.length > 0 &&
                     model.clip.isPlaying
            color: Kirigami.Theme.textColor
            height: Kirigami.Units.smallSpacing
            width: (model.clip.progress - model.clip.startPosition)/(((60/zynthian.zynthiloops.song.bpm) * model.clip.length) / parent.width);
        }
        Rectangle {
            id: patternProgressRect

            anchors.bottom: parent.bottom
            visible: (model.clip.inCurrentScene || root.song.scenesModel.isClipInScene(model.clip, model.clip.col)) &&
                     model.clip.clipTrack.trackAudioType !== "sample-loop" &&
                     track.connectedPattern >= 0 &&
                     sequence.isPlaying &&
                     pattern.bankHasNotes(0) &&
                     pattern.lastModified
            color: Kirigami.Theme.textColor
            height: Kirigami.Units.smallSpacing
            width: pattern ? (parent.width/16)*(pattern.bankPlaybackPosition%16) : 0
        }
    }

    onActiveFocusChanged: {
        console.log("Item with active Focus :", activeFocus)
    }

}
