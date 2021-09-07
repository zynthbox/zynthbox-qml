/* -*- coding: utf-8 -*-
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

import '../../Zynthian' 1.0 as Zynthian

Zynthian.ScreenPage {
    id: root

    readonly property QtObject song: zynthian.zynthiloops.song

    title: qsTr("Zynthiloops")
    screenId: "zynthiloops"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8
    onSongChanged: {
        console.log("Song Changed :", song)

        // Reset focus to song cell
        songCell.focus = true
        bottomBar.controlType = BottomBar.ControlType.Song;
        bottomBar.controlObj = root.song;
    }

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Sketch")

            Kirigami.Action {
                text: qsTr("New Sketch")
                onTriggered: {
                    newSketchDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Clear Sketch")
                onTriggered: {
                    zynthian.zynthiloops.clearCurrentSketch()
                }
            }
        },
        Kirigami.Action {
            text: qsTr("Add Track")
            onTriggered: root.song.addTrack()
        }
    ]

    Component.onCompleted: {
        applicationWindow().controlsVisible = true;
        bottomBar.controlType = BottomBar.ControlType.Song;
        bottomBar.controlObj = root.song;
    }

    Component.onDestruction: {
        applicationWindow().controlsVisible = true;
    }

    QtObject {
        id: privateProps

        //Try to fit exactly until a minimum allowed size
        property int headerWidth: Math.round(
                                    Math.max(Kirigami.Units.gridUnit * 5,
                                            tableLayout.width / 9))
        property int headerHeight: Math.round(Kirigami.Units.gridUnit * 2.5)
        property int cellWidth: headerWidth
        property int cellHeight: headerHeight
    }

    Zynthian.SaveFileDialog {
        id: newSketchDialog
        visible: false

        headerText: qsTr("New Sketch")
        conflictText: qsTr("Sketch Exists")
        overwriteOnConflict: false

        onFileNameChanged: {
            console.log("File Name : " + fileName)
            fileCheckTimer.restart()
        }
        Timer {
            id: fileCheckTimer
            interval: 300
            onTriggered: {
                if (newSketchDialog.fileName.length > 0 && zynthian.zynthiloops.sketchExists(newSketchDialog.fileName)) {
                    newSketchDialog.conflict = true;
                } else {
                    newSketchDialog.conflict = false;
                }
            }
        }

        onAccepted: {
            console.log("Accepted")
            zynthian.zynthiloops.newSketch(newSketchDialog.fileName)
            console.log("List of sketches : ", zynthian.zynthiloops.listSketches())
        }
        onRejected: {
            console.log("Rejected")
        }
    }

    contentItem : ColumnLayout {

        ColumnLayout {
            id: tableLayout
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 1

            // HEADER ROW
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: privateProps.headerHeight
                Layout.maximumHeight: privateProps.headerHeight
                spacing: 1

                TableHeader {
                    id: songCell
                    Layout.preferredWidth: privateProps.headerWidth
                    Layout.maximumWidth: privateProps.headerWidth
                    Layout.fillHeight: true

                    text: root.song.name
                    subText: "BPM: " + root.song.bpm

                    onPressed: {
                        bottomBar.controlType = BottomBar.ControlType.Song;
                        bottomBar.controlObj = root.song;
                    }

                }

                ListView {
                    id: partsHeaderRow

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true
                    spacing: 1
                    contentX: loopGridFlickable.contentX
                    orientation: Qt.Horizontal
                    boundsBehavior: Flickable.StopAtBounds

                    model: root.song.tracksModel

                    delegate: TableHeader {
                        text: model.track.name
                        subText: model.track.type === "audio" ? "Audio" : "Midi"

                        width: privateProps.headerWidth
                        height: ListView.view.height

                        onPressed: {
                            bottomBar.controlType = BottomBar.ControlType.Track;
                            bottomBar.controlObj = model.track;
                        }

                        onPressAndHold: {
                            zynthian.track.trackId = model.track.id
                            zynthian.current_modal_screen_id = "track"
                        }
                    }
                }
            }
            // END HEADER ROW

            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true

                spacing: 1

                ListView {
                    id: tracksHeaderColumns

                    Layout.preferredWidth: privateProps.headerWidth
                    Layout.maximumWidth: privateProps.headerWidth
                    Layout.fillHeight: true

                    clip: true
                    spacing: 1
                    contentY: loopGridFlickable.contentY
                    boundsBehavior: Flickable.StopAtBounds

                    model: root.song.partsModel

                    delegate: TableHeader {
                        text: part.name
                        subText: qsTr("%L1 Bar").arg(model.part.length)

                        width: ListView.view.width
                        height: privateProps.headerHeight

                        onPressed: {
                            bottomBar.controlType = BottomBar.ControlType.Part;
                            bottomBar.controlObj = model.part;
                        }

                        Kirigami.Icon {
                            width: 14
                            height: 14
                            color: "white"
                            anchors {
                                right: parent.right
                                top: parent.top
                            }

                            source: "media-playback-start"
                            visible: model.part.isPlaying
                        }
                    }
                }

                Flickable {
                    id: loopGridFlickable

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: loopGrid.width
                    contentHeight: loopGrid.height

                    clip: true
                    flickableDirection: Flickable.HorizontalAndVerticalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    contentX: partsHeaderRow.contentX
                    contentY: tracksHeaderColumns.contentY

                    GridLayout {
                        id: loopGrid
                        rows: root.song.partsModel.count
                        flow: GridLayout.TopToBottom
                        rowSpacing: 1
                        columnSpacing: 1

                        Repeater {
                            model: root.song.tracksModel

                            delegate: Repeater {
                                property int rowIndex: index

                                model: track.clipsModel

                                delegate: ClipCell {
                                    id: clipCell
                                    isPlaying: model.clip.isPlaying
                                    highlighted: bottomBar.controlObj === model.clip


                                    Layout.preferredWidth: privateProps.cellWidth
                                    Layout.maximumWidth: privateProps.cellWidth
                                    Layout.preferredHeight: privateProps.cellHeight
                                    Layout.maximumHeight: privateProps.cellHeight

                                    onPressed: {
                                        bottomBar.controlType = BottomBar.ControlType.Clip;
                                        bottomBar.controlObj = model.clip;
                                        if (dblTimer.running) {
                                            if (model.clip.isPlaying) {
                                                model.clip.stop();
                                            } else {
                                                model.clip.play();
                                            }
                                        }
                                        dblTimer.restart()
                                    }
                                    Timer { //FIXME: why onDoubleClicked doesn't work
                                        id: dblTimer
                                        interval: 200
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        BottomBar {
            id: bottomBar

            Layout.preferredHeight: Kirigami.Units.gridUnit * 15
            Layout.fillWidth: true
            Layout.fillHeight: false
        }
    }
}
