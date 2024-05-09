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
import io.zynthbox.components 1.0 as Zynthbox

// GridLayout so TabbedControlView knows how to navigate it
Rectangle {
    id: root

    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    property QtObject bottomBar: null
    property QtObject selectedChannel: zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId)
    property QtObject selectedPartChannel
    property QtObject selectedPartClip
    property QtObject selectedPartPattern
    property QtObject selectedComponent

    signal clicked()

    function cuiaCallback(cuia) {
        console.log("### Part Bar CUIA Callback :", cuia)

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

        console.log("### Part Bar CUIA Callback :", selectedChannel.id, zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex, cuia, clip)

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
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 6
                }

                RowLayout {
                    id: contentColumn
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    spacing: 1

                    Connections {
                        target: Zynthbox.PlayfieldManager
                        function onPlayfieldStateChanged(sketchpadSong, sketchpadTrack, clip, position, newPlaystate) {
                            // signalCounterThing.boop();
                            let trackDelegate = partDelegateRepeater.itemAt(sketchpadTrack);
                            if (trackDelegate && trackDelegate.channel && sketchpadSong === 0 && position == Zynthbox.PlayfieldManager.NextBarPosition) {
                                let partDelegate = trackDelegate.repeater.itemAt(clip);
                                if (partDelegate.nextBarState != newPlaystate) {
                                    partDelegate.nextBarState = newPlaystate;
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
                        id: partDelegateRepeater
                        model: 10
                        delegate: PartBarDelegate {
                            id: partBarDelegate

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            channel: zynqtgui.sketchpad.song.channelsModel.getChannel(model.index)
                            onClicked: {
                                zynqtgui.sketchpad.selectedTrackId = model.index
                                root.selectedPartChannel = partBarDelegate.channel
                                root.selectedPartClip = partBarDelegate.selectedPartClip
                                root.selectedPartPattern = partBarDelegate.selectedPartPattern
                                root.selectedComponent = partBarDelegate.selectedComponent
                                root.clicked()
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6

                    // Part details colume, visible when not in song mode
                    ColumnLayout {
                        anchors.fill: parent

                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            wrapMode: "WrapAtWordBoundaryOrAnywhere"
                            visible: root.selectedPartChannel && root.selectedPartChannel.trackType === "sample-loop"
                            text: root.selectedPartClip ? root.selectedPartClip.path.split("/").pop() : ""
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            wrapMode: "WrapAtWordBoundaryOrAnywhere"
                            visible: root.selectedPartChannel && root.selectedPartChannel.trackType !== "sample-loop"
                            text: root.selectedPartPattern ? qsTr("Pattern %1%2").arg(root.selectedPartChannel.id + 1).arg(root.selectedPartPattern.partName) : ""
                        }

                        Kirigami.Separator {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: 2
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            visible: root.selectedPartChannel && ["synth", "sample-trig", "sample-slice", "external"].indexOf(root.selectedPartChannel.trackType) > -1
                            text: qsTr("Swap with...")
                            onClicked: {
                                bottomStack.slotsBar.pickSlotToSwapWith(root.selectedPartChannel, "pattern", partBarDelegate.selectedPartPattern.partIndex);
                            }
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            visible: root.selectedPartChannel && root.selectedPartChannel.trackType === "sample-loop"
                            text: qsTr("Swap with...")
                            onClicked: {
                                bottomStack.slotsBar.pickSlotToSwapWith(root.selectedPartChannel, "sketch", partBarDelegate.selectedPartPattern.partIndex);
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
    }
}
