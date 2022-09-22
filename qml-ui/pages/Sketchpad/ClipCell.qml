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
import org.zynthian.quick 1.0 as ZynQuick
import Zynthian 1.0 as Zynthian

QQC2.AbstractButton {
    id: root

    readonly property QtObject song: zynthian.sketchpad.song
    readonly property int colIndex: index
    property bool isPlaying
    property color backgroundColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, root.backgroundOpacity)
    property real backgroundOpacity: 0.05
    property bool highlighted: channel.sceneClip.row === zynthian.session_dashboard.selectedChannel &&
                               channel.sceneClip.col === zynthian.sketchpad.song.scenesModel.selectedTrackIndex // bottomBar.controlObj === channel.sceneClip
    property color highlightColor: highlighted
                                       ? Kirigami.Theme.highlightColor
                                       : "transparent"
    property bool isInScene: channel.selectedPartNames
                                ? channel.selectedPartNames.join("").length > 0
                                : false

    property QtObject sequence
    property QtObject pattern

    onPressed: forceActiveFocus()

    contentItem: Item {
//        Connections {
//            target: channel
//            onSelectedPartNamesChanged: {
//                console.log("### Selected part names for channel " + channel.name + " : " + channel.selectedPartNames + ", length : " + channel.selectedPartNames.length + ", joined length : ", channel.selectedPartNames.join("").length)
//            }
//        }

//        Image {
//            id: patternVisualiser
//            anchors.fill: parent
//            anchors.margins: 2
//            smooth: false

//            visible: root.isInScene &&
//                     channel.channelAudioType !== "sample-loop" &&
//                     root.pattern &&
//                     root.pattern.hasNotes
//            source: root.pattern ? root.pattern.thumbnailUrl : ""
//            cache: false
//        }

//        QQC2.Label {
//            anchors {
//                right: parent.right
//                bottom: parent.bottom
//            }
//            visible: root.isInScene &&
//                     channel.channelAudioType === "sample-loop" &&
//                     channel.sceneClip.path &&
//                     channel.sceneClip.path.length > 0
//            text: visible
//                ? qsTr("%1%2")
//                    .arg(channel.sceneClip.isPlaying &&
//                         channel.sceneClip.currentBeat >= 0
//                            ? (channel.sceneClip.currentBeat+1) + "/"
//                            : "")
//                    .arg(channel.sceneClip.snapLengthToBeat
//                            ? channel.sceneClip.length.toFixed(0)
//                            : channel.sceneClip.length.toFixed(2))
//                : ""
//        }

//        QQC2.Label {
//            id: patternPlaybackLabel
//            anchors {
//                right: parent.right
//                bottom: parent.bottom
//            }
//            visible: root.isInScene &&
//                     channel.channelAudioType !== "sample-loop" &&
//                     root.pattern &&
//                     root.pattern.hasNotes
//            text: patternPlaybackLabel.visible ? playbackPositionString + root.pattern.availableBars*4 : ""
//            property string playbackPositionString: patternPlaybackLabel.visible && root.pattern && root.pattern.hasNotes && root.pattern.isPlaying && root.sequence && root.sequence.isPlaying && zynthian.sketchpad.isMetronomeRunning
//                    ? patternPlaybackLabel.playbackPosition + "/"
//                    : ""
//            property int playbackPosition: 1
//            Connections {
//                target: root.pattern
//                enabled: patternPlaybackLabel.visible
//                onBankPlaybackPositionChanged: {
//                    let playbackPosition = Math.floor(root.pattern.bankPlaybackPosition/4) + 1
//                    if (patternPlaybackLabel.playbackPosition != playbackPosition) {
//                        patternPlaybackLabel.playbackPosition = playbackPosition
//                    }
//                }
//            }
//        }

        QQC2.Label {
            anchors.centerIn: parent
            color: "#f44336"
            text: qsTr("Mute")
            visible: !root.isInScene
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: spacing
            anchors.bottomMargin: spacing

            Binding {
                target: partNamesRepeater
                delayed: true
                property: "model"
                value: channel.selectedPartNames
            }

            Repeater {
                id: partNamesRepeater
                delegate: RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: modelData.length > 0
                                ? Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.2)
                                : "transparent"
                    }

                    QQC2.Label {
                        Layout.fillWidth: false
                        Layout.minimumWidth: 12
                        Layout.fillHeight: true
                        font.pointSize: 9
                        text: modelData
                    }
                }
            }
        }

        QQC2.Label {
            width: parent.width - 8
            anchors.centerIn: parent
            horizontalAlignment: "AlignHCenter"
            elide: "ElideRight"
            color: "#ffffff"
            text: qsTr("%1")
                    .arg(channel.id+1)
            font.pointSize: 12
            visible: root.isInScene

            layer.enabled: true
            layer.effect: DropShadow {
                verticalOffset: 0
                color: "#80000000"
                radius: 5
                samples: 11
            }
        }

//        Rectangle {
//            height: Kirigami.Units.gridUnit * 0.7
//            anchors.left: parent.left
//            anchors.right: parent.right
//            anchors.top: parent.top
//            color: "#99888888"
//            visible: presetName.text &&
//                     presetName.text.length > 0

//            QQC2.Label {
//                id: presetName
//                property string presetText: channel.connectedSoundName.split(" > ")[1]

//                anchors.fill: parent
//                elide: "ElideRight"
//                horizontalAlignment: "AlignHCenter"
//                verticalAlignment: "AlignVCenter"
//                font.pointSize: 8
//                text: model.channel.channelAudioType === "synth"
//                      ? presetText
//                          ? presetText
//                          : ""
//                      : ["sample-trig", "sample-slice"].indexOf(model.channel.channelAudioType) >= 0
//                          ? model.channel.samples[model.channel.selectedSlotRow].path.split("/").pop()
//                          : model.channel.channelAudioType === "sample-loop"
//                              ? model.channel.sceneClip.path.split("/").pop()
//                              : qsTr("Midi %1").arg(model.channel.externalMidiChannel > -1 ? model.channel.externalMidiChannel + 1 : model.channel.id + 1)
//            }
//        }
    }

    background: Rectangle {
        color: copySourceObj === channel.sceneClip ? "#2196f3" : root.backgroundColor

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
                     channel.channelAudioType === "sample-loop" &&
                     channel.sceneClip.path &&
                     channel.sceneClip.path.length > 0

            color: Kirigami.Theme.textColor
            height: Kirigami.Units.smallSpacing
            width: visible ? (channel.sceneClip.progress - channel.sceneClip.startPosition)/adjustment : 0
            property double adjustment: visible ? (((60/zynthian.sketchpad.song.bpm) * channel.sceneClip.length) / parent.width) : 1
        }
        Rectangle {
            id: patternProgressRect

            anchors.bottom: parent.bottom
            visible: root.isInScene &&
                     channel.channelAudioType !== "sample-loop" &&
                     channel.connectedPattern >= 0 &&
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
