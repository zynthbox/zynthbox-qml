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
    property QtObject selectedChannel: zynthian.sketchpad.song.channelsModel.getChannel(zynthian.session_dashboard.selectedChannel)
    property QtObject selectedPartChannel
    property QtObject selectedPartClip
    property QtObject selectedPartPattern
    property QtObject selectedComponent

    property bool songMode: zynthian.sketchpad.song.sketchesModel.songMode

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
                if (zynthian.session_dashboard.selectedChannel > 0) {
                    zynthian.session_dashboard.selectedChannel -= 1;
                }
                returnVal = true
                break

            case "NAVIGATE_RIGHT":
                if (zynthian.session_dashboard.selectedChannel < 9) {
                    zynthian.session_dashboard.selectedChannel += 1;
                }
                returnVal = true
                break
        }

        console.log("### Part Bar CUIA Callback :", selectedChannel.id, zynthian.sketchpad.song.scenesModel.selectedTrackIndex, cuia, clip)

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

                    Repeater {
                        id: partDelegateRepeater
                        model: 10
                        delegate: PartBarDelegate {
                            id: partBarDelegate

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            channel: zynthian.sketchpad.song.channelsModel.getChannel(model.index)
                            onClicked: {
                                if (!root.songMode) {
                                    zynthian.session_dashboard.selectedChannel = model.index
                                    root.selectedPartChannel = partBarDelegate.channel
                                    root.selectedPartClip = partBarDelegate.selectedPartClip
                                    root.selectedPartPattern = partBarDelegate.selectedPartPattern
                                    root.selectedComponent = partBarDelegate.selectedComponent
                                    root.clicked()
                                }
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
                        visible: !root.songMode

                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            wrapMode: "WrapAtWordBoundaryOrAnywhere"
                            visible: root.selectedPartChannel && root.selectedPartChannel.channelAudioType === "sample-loop"
                            text: root.selectedPartClip ? root.selectedPartClip.path.split("/").pop() : ""
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            wrapMode: "WrapAtWordBoundaryOrAnywhere"
                            visible: root.selectedPartChannel && root.selectedPartChannel.channelAudioType !== "sample-loop"
                            text: root.selectedPartPattern ? root.selectedPartPattern.objectName : ""
                        }

                        Kirigami.Separator {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: 2
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }

                    // Segment details colume, visible when in song mode
                    ColumnLayout {
                        id: segmentDetails

                        property QtObject selectedSegment: zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegment

                        anchors.fill: parent
                        visible: root.songMode

                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            horizontalAlignment: "AlignHCenter"
                            verticalAlignment: "AlignVCenter"
                            text: segmentDetails.selectedSegment.name
                        }

                        Kirigami.Separator {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: 2
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: false

                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                horizontalAlignment: "AlignHCenter"
                                verticalAlignment: "AlignVCenter"
                                text: qsTr("Bar")
                            }
                            QQC2.Label {
                                Layout.fillWidth: false
                                Layout.fillHeight: false
                                horizontalAlignment: "AlignHCenter"
                                verticalAlignment: "AlignVCenter"
                                text: "/"
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                horizontalAlignment: "AlignHCenter"
                                verticalAlignment: "AlignVCenter"
                                text: qsTr("Beat")
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                            QQC2.TextField {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                horizontalAlignment: "AlignHCenter"
                                verticalAlignment: "AlignVCenter"
                                inputMethodHints: Qt.ImhDigitsOnly
                                activeFocusOnTab: false
                                text: segmentDetails.selectedSegment.barLength
                                onAccepted: {
                                    segmentDetails.selectedSegment.barLength = parseInt(text)
                                }
                            }
                            QQC2.Label {
                                Layout.fillWidth: false
                                Layout.fillHeight: true
                                horizontalAlignment: "AlignHCenter"
                                verticalAlignment: "AlignVCenter"
                                text: "/"
                            }
                            QQC2.TextField {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                horizontalAlignment: "AlignHCenter"
                                verticalAlignment: "AlignVCenter"
                                inputMethodHints: Qt.ImhDigitsOnly
                                activeFocusOnTab: false
                                text: segmentDetails.selectedSegment.beatLength
                                onAccepted: {
                                    segmentDetails.selectedSegment.beatLength = parseInt(text)
                                }
                            }
                        }

                        QQC2.Button {
                            text: qsTr("Play Segment")
                            onClicked: {
                                console.log(
                                    "Playing Segment",
                                    segmentDetails.selectedSegment.segmentId,
                                    " : Offset",
                                    segmentDetails.selectedSegment.getOffsetInBeats(),
                                    ", durationInBeats",
                                    (segmentDetails.selectedSegment.barLength * 4 + segmentDetails.selectedSegment.beatLength),
                                    ", durationInTicks",
                                    ZynQuick.PlayGridManager.syncTimer.getMultiplier() * (segmentDetails.selectedSegment.barLength * 4 + segmentDetails.selectedSegment.beatLength)
                                )

                                ZynQuick.SegmentHandler.startPlayback(
                                    ZynQuick.PlayGridManager.syncTimer.getMultiplier() * segmentDetails.selectedSegment.getOffsetInBeats(),
                                    ZynQuick.PlayGridManager.syncTimer.getMultiplier() * (segmentDetails.selectedSegment.barLength * 4 + segmentDetails.selectedSegment.beatLength)
                                )
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        QQC2.Button {
                            text: qsTr("Add Before")
                            onClicked: {
                                zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.new_segment(segmentDetails.selectedSegment.segmentId);
                            }
                        }
                        QQC2.Button {
                            text: confirmRemoval.visible ? qsTr("Don't Remove") : qsTr("Remove...")
                            onClicked: {
                                confirmRemoval.visible = !confirmRemoval.visible;
                            }
                            QQC2.Button {
                                id: confirmRemoval
                                anchors {
                                    top: parent.top
                                    right: parent.left
                                    rightMargin: Kirigami.Units.smallSpacing
                                    bottom: parent.bottom
                                }
                                visible: false
                                width: parent.width
                                text: qsTr("Remove")
                                onClicked: {
                                    confirmRemoval.visible = false;
                                    if (zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count === 1) {
                                        // If there's only this single segment, don't actually delete it, just clear it
                                        zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegment.clear();
                                    } else {
                                        // If there's more than one, we can remove the one we've got selected
                                        if (zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex === zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count - 1) {
                                            // If we've got the last segment selected, and we're deleting that, we need to go back a step to avoid ouchies
                                            zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex = zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex - 1;
                                            zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.remove_segment(zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex + 1);
                                        } else {
                                            zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.remove_segment(zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex);
                                        }
                                    }
                                }
                            }
                        }
                        QQC2.Button {
                            text: qsTr("Add After")
                            onClicked: {
                                zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.new_segment(segmentDetails.selectedSegment.segmentId + 1);
                                zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex = segmentDetails.selectedSegment.segmentId + 1;
                            }
                        }
                    }
                }
            }
        }
    }
}
