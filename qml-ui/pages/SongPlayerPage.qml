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
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: component.width * 2 / 12
                text: qsTr("Song Mode")
                checked: zynthian.zynthiloops.song.mixesModel.songMode
                onClicked: {
                    zynthian.zynthiloops.song.mixesModel.songMode = !zynthian.zynthiloops.song.mixesModel.songMode;
                }
            }
            Repeater {
                model: 10
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredWidth: component.width / 12
                    property QtObject mixObject: zynthian.zynthiloops.song.mixesModel.getMix(model.index)
                    text: mixObject.name
                    checked: zynthian.zynthiloops.song.mixesModel.selectedMixIndex == model.index
                    onClicked: {
                        zynthian.zynthiloops.song.mixesModel.selectedMixIndex = model.index;
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

/// BEGIN Not-song-mode playbackery stuff
        RowLayout {
            Layout.fillWidth: true
            visible: !zynthian.zynthiloops.song.mixesModel.songMode
            QQC2.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Playback is in loop mode and the concept of a single progress bar for continuous playback makes little sense - what should we put here?")
            }
        }
/// END Not-song-mode playbackery stuff

/// BEGIN Song-mode playbackery stuff
        RowLayout {
            Layout.fillWidth: true
            visible: zynthian.zynthiloops.song.mixesModel.songMode && segmentsRepeater.count === 0
            QQC2.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("You've not built a song here yet - head on over to Looper to do that")
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 5
            visible: zynthian.zynthiloops.song.mixesModel.songMode && segmentsRepeater.count > 0
            spacing: 0
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Button
            Repeater {
                id: segmentsRepeater
                property int totalDuration: ZynQuick.PlayGridManager.syncTimer.getMultiplier() * zynthian.zynthiloops.song.mixesModel.selectedMix.segmentsModel.totalBeatDuration
                model: component.visible && totalDuration > 0 ? zynthian.zynthiloops.song.mixesModel.selectedMix.segmentsModel : 0
                delegate: Item {
                    id: segmentDelegate
                    property QtObject segment: model.segment
                    property int duration: ZynQuick.PlayGridManager.syncTimer.getMultiplier() * (segmentDelegate.segment.barLength * 4 + segmentDelegate.segment.beatLength)
                    Layout.fillWidth: true
                    Layout.preferredWidth: component.width * (segmentDelegate.duration / segmentsRepeater.totalDuration)
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 5
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
                    QQC2.Label {
                        anchors {
                            fill: parent
                            margins: 3
                        }
                        wrapMode: Text.WrapAnywhere
                        verticalAlignment: Text.AlignTop
                        horizontalAlignment: Text.AlignLeft
                        text: {
                            var constructed = "";
                            var separator = "";
                            for (var clipIndex = 0; clipIndex < segmentDelegate.segment.clips.length; ++clipIndex) {
                                var clip = segmentDelegate.segment.clips[clipIndex];
                                constructed = constructed + separator + clip.name;
                                if (separator === "") {
                                    separator = ", ";
                                }
                            }
                            return constructed;
                        }
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.minimumHeight: 1
            Layout.maximumHeight: 1
            visible: zynthian.zynthiloops.song.mixesModel.songMode && segmentsRepeater.count > 0
            Item {
                height: 1
                width: 1
                y: 0
                x: component.visible ? parent.width * (ZynQuick.SegmentHandler.playhead / segmentsRepeater.totalDuration) : 0
                Rectangle {
                    anchors {
                        bottom: parent.top
                        horizontalCenter: parent.horizontalCenter
                    }
                    height: Kirigami.Units.gridUnit * 5 + 10 // 10 because the default spacing is 5 and we want it to stick up and down by that spacing amount, why not
                    width: 3
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: Kirigami.Theme.focusColor
                }
            }
        }
/// END Song-mode playbackery stuff
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
