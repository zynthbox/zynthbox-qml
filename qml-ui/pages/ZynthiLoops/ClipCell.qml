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
    property color backgroundColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, root.backgroundOpacity)
    property real backgroundOpacity: 0.05
    property bool highlighted: track.sceneClip.row === zynthian.session_dashboard.selectedTrack &&
                               track.sceneClip.col === zynthian.zynthiloops.song.scenesModel.selectedMixIndex // bottomBar.controlObj === track.sceneClip
    property color highlightColor: !highlighted &&
                                   root.isInScene &&
                                   ((track.trackAudioType === "sample-loop" && track.sceneClip.path && track.sceneClip.path.length > 0) || pattern.hasNotes)
                                       ? Qt.rgba(255,255,255,0.6)
                                       : highlighted
                                           ? root.isInScene
                                               ? Kirigami.Theme.highlightColor
                                               : "#aaf44336"
                                           : "transparent"
    property bool isInScene: track.selectedPartNames.length > 0

    property QtObject sequence
    property QtObject pattern

    onPressed: forceActiveFocus()

    contentItem: Item {
        Image {
            id: patternVisualiser
            anchors.fill: parent
            anchors.margins: 2
            smooth: false

            visible: root.isInScene &&
                     track.trackAudioType !== "sample-loop" &&
                     root.pattern &&
                     root.pattern.hasNotes
            source: root.pattern ? root.pattern.thumbnailUrl : ""
            cache: false
        }

        QQC2.Label {
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
            visible: root.isInScene &&
                     track.trackAudioType === "sample-loop" &&
                     track.sceneClip.path &&
                     track.sceneClip.path.length > 0
            text: visible
                ? qsTr("%1%2")
                    .arg(track.sceneClip.isPlaying &&
                         track.sceneClip.currentBeat >= 0
                            ? (track.sceneClip.currentBeat+1) + "/"
                            : "")
                    .arg(track.sceneClip.length.toFixed(2))
                : ""
        }

        QQC2.Label {
            id: patternPlaybackLabel
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
            visible: root.isInScene &&
                     track.trackAudioType !== "sample-loop" &&
                     root.pattern &&
                     root.pattern.hasNotes
            text: patternPlaybackLabel.visible ? playbackPositionString + root.pattern.availableBars*4 : ""
            property string playbackPositionString: patternPlaybackLabel.visible && root.pattern && root.pattern.hasNotes && root.pattern.isPlaying && root.sequence && root.sequence.isPlaying && zynthian.zynthiloops.isMetronomeRunning
                    ? patternPlaybackLabel.playbackPosition + "/"
                    : ""
            property int playbackPosition: 1
            Connections {
                target: root.pattern
                enabled: patternPlaybackLabel.visible
                onBankPlaybackPositionChanged: {
                    let playbackPosition = Math.floor(root.pattern.bankPlaybackPosition/4) + 1
                    if (patternPlaybackLabel.playbackPosition != playbackPosition) {
                        patternPlaybackLabel.playbackPosition = playbackPosition
                    }
                }
            }
        }

        QQC2.Label {
            anchors.centerIn: parent
            color: "#f44336"
            text: qsTr("Mute")
            visible: !root.isInScene
        }

        QQC2.Label {
            width: parent.width - 8
            anchors.centerIn: parent
            horizontalAlignment: "AlignHCenter"
            elide: "ElideRight"
            color: "#ffffff"
            text: qsTr("%1 %2")
                    .arg(track.id+1)
                    .arg(track.selectedPartNames)
            font.pointSize: 7
            visible: root.isInScene
        }

        Rectangle {
            height: Kirigami.Units.gridUnit * 0.7
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            color: "#99888888"
            visible: presetName.text &&
                     presetName.text.length > 0

            QQC2.Label {
                id: presetName
                property string presetText: track.connectedSoundName.split(" > ")[1]

                anchors.fill: parent
                elide: "ElideRight"
                horizontalAlignment: "AlignHCenter"
                verticalAlignment: "AlignVCenter"
                font.pointSize: 7
                text: model.track.trackAudioType === "synth"
                      ? presetText
                          ? presetText
                          : ""
                      : ["sample-trig", "sample-slice"].indexOf(model.track.trackAudioType) >= 0
                          ? model.track.samples[model.track.selectedSampleRow].path.split("/").pop()
                          : model.track.trackAudioType === "sample-loop"
                              ? model.track.sceneClip.path.split("/").pop()
                              : qsTr("Midi %1").arg(model.track.externalMidiChannel > -1 ? model.track.externalMidiChannel + 1 : model.track.id + 1)
            }
        }
    }

    background: Rectangle {
        color: copySourceObj === track.sceneClip ? "#2196f3" : root.backgroundColor

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
                     track.sceneClip.isPlaying &&
                     track.trackAudioType === "sample-loop" &&
                     track.sceneClip.path &&
                     track.sceneClip.path.length > 0

            color: Kirigami.Theme.textColor
            height: Kirigami.Units.smallSpacing
            width: visible ? (track.sceneClip.progress - track.sceneClip.startPosition)/adjustment : 0
            property double adjustment: visible ? (((60/zynthian.zynthiloops.song.bpm) * track.sceneClip.length) / parent.width) : 1
        }
        Rectangle {
            id: patternProgressRect

            anchors.bottom: parent.bottom
            visible: root.isInScene &&
                     track.trackAudioType !== "sample-loop" &&
                     track.connectedPattern >= 0 &&
                     sequence.isPlaying &&
                     root.pattern.hasNotes
            color: Kirigami.Theme.textColor
            height: Kirigami.Units.smallSpacing
            width: pattern ? (parent.width/16)*(pattern.bankPlaybackPosition%16) : 0
        }
    }

    onActiveFocusChanged: {
        console.log("Item with active Focus :", activeFocus)
    }

}
