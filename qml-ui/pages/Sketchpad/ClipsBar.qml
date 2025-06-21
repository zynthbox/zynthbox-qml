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
import QtGraphicalEffects 1.0

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

// GridLayout so TabbedControlView knows how to navigate it
QQC2.Pane {
    id: root

    Layout.fillWidth: true
    padding: 0
    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
        // border.color: "orange"
    }

    property QtObject bottomBar: null
    property QtObject selectedChannel: zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId)
    property QtObject selectedClipChannel
    property QtObject selectedClipObject
    property QtObject selectedClipPattern
    property QtObject selectedComponent

    signal clicked()

    function cuiaCallback(cuia) {
        console.log("### Clips Bar CUIA Callback :", cuia)

        var clip;
        var returnVal = false

        switch (cuia) {
        case "SWITCH_BACK_SHORT":
            bottomStack.slotsBar.channelButton.checked = true
            returnVal = true
            break

        case "NAVIGATE_LEFT":
            zynqtgui.sketchpad.selectedTrackId = Zynthian.CommonUtils.clamp(zynqtgui.sketchpad.selectedTrackId - 1, 0, Zynthbox.Plugin.sketchpadTrackCount - 1)
            returnVal = true
            break

        case "NAVIGATE_RIGHT":
            zynqtgui.sketchpad.selectedTrackId = Zynthian.CommonUtils.clamp(zynqtgui.sketchpad.selectedTrackId + 1, 0, Zynthbox.Plugin.sketchpadTrackCount - 1)
            returnVal = true
            break
        }

        console.log("### Clips Bar CUIA Callback :", selectedChannel.id, zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex, cuia, clip)

        return returnVal;
    }

    QQC2.ButtonGroup {
        buttons: buttonsColumn.children
    }

    contentItem: Item {

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            anchors.fill: parent

            BottomStackTabs {
                id: buttonsColumn
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                Layout.maximumWidth: Kirigami.Units.gridUnit * 6
            }

            QQC2.Pane {
                Layout.fillWidth: true
                Layout.fillHeight: true

                padding: 2

                background: Rectangle
                {
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                    Kirigami.Theme.inherit: false
                    color: Kirigami.Theme.backgroundColor
                    border.color: Qt.darker(Kirigami.Theme.alternateBackgroundColor, 2.5)
                    radius: 6
                }

                contentItem: Item {
                    id: clipsContainer

                    layer.enabled: true
                    layer.effect: OpacityMask
                    {
                        maskSource: Rectangle
                        {
                            width: clipsContainer.width
                            height: clipsContainer.height
                            radius: 4
                        }
                    }

                    RowLayout {
                        id: contentColumn
                        anchors.fill: parent

                        spacing: 1

                        Connections {
                            target: Zynthbox.PlayfieldManager
                            function onPlayfieldStateChanged(sketchpadSong, sketchpadTrack, clip, position, newPlaystate) {
                                // signalCounterThing.boop();
                                let trackDelegate = clipDelegateRepeater.itemAt(sketchpadTrack);
                                if (trackDelegate && trackDelegate.channel && sketchpadSong === zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex && position == Zynthbox.PlayfieldManager.NextBarPosition) {
                                    let clipDelegate = trackDelegate.repeater.itemAt(clip);
                                    if (clipDelegate.nextBarState != newPlaystate) {
                                        clipDelegate.nextBarState = newPlaystate;
                                    }
                                }
                            }
                        }
                        // Timer {
                        //     id: signalCounterThing
                        //     interval: 10; running: false; repeat: false;
                        //     property int signalReceivedCount: 0
                        //     function boop() {
                        //         signalReceivedCount += 1;
                        //         restart();
                        //     }
                        //     onTriggered: {
                        //         console.log("Signal received by", root.channel.id, "this number of times:", signalReceivedCount);
                        //         signalReceivedCount = 0;
                        //     }
                        // }
                        Repeater {
                            id: clipDelegateRepeater
                            model: 10
                            delegate: ClipsBarDelegate {
                                id: clipsBarDelegate

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                channel: zynqtgui.sketchpad.song.channelsModel.getChannel(model.index)
                                onClicked: {
                                    zynqtgui.sketchpad.selectedTrackId = model.index
                                    root.selectedClipChannel = clipsBarDelegate.channel
                                    root.selectedClipObject = clipsBarDelegate.selectedClipObject
                                    root.selectedClipPattern = clipsBarDelegate.selectedClipPattern
                                    root.selectedComponent = clipsBarDelegate.selectedComponent
                                    root.clicked()
                                }
                            }
                        }
                    }
                }
            }

            // Clip details colume, visible when not in song mode
            ColumnLayout {
                Layout.fillWidth: false
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6

                QQC2.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WrapAnywhere
                    // visible: root.selectedClipChannel && root.selectedClipChannel.trackType === "sample-loop"
                    text: root.selectedClipObject ? root.selectedClipObject.path.split("/").pop() : ""
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WrapAnywhere
                    // visible: root.selectedClipChannel && root.selectedClipChannel.trackType !== "sample-loop"
                    text: root.selectedClipPattern ? qsTr("Pattern %1%2").arg(root.selectedClipChannel.id + 1).arg(root.selectedClipPattern.clipName) : ""
                }

                // Kirigami.Separator {
                //     Layout.fillWidth: true
                //     Layout.fillHeight: false
                //     Layout.preferredHeight: 2
                // }

                QQC2.Button {
                    Layout.fillWidth: true
                    // visible: root.selectedClipChannel && ["synth", "sample-trig", "external"].indexOf(root.selectedClipChannel.trackType) > -1
                    text: qsTr("Swap with...")
                    onClicked: {
                        bottomStack.slotsBar.pickSlotToSwapWith(root.selectedClipChannel, "pattern", clipsBarDelegate.selectedClipPattern.clipIndex);
                    }
                }

                QQC2.Button {
                    Layout.fillWidth: true
                    // visible: root.selectedClipChannel && root.selectedClipChannel.trackType === "sample-loop"
                    text: qsTr("Swap with...")
                    onClicked: {
                        bottomStack.slotsBar.pickSlotToSwapWith(root.selectedClipChannel, "sketch", clipsBarDelegate.selectedClipPattern.clipIndex);
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
