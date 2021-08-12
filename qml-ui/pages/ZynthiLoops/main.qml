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
import ZynthiLoops 1.0 as ZynthiLoops

Zynthian.ScreenPage {
    id: root

    readonly property QtObject song: zynthian.zynthiloops.song

    screenId: "zynthiloops"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Add Track")
            onTriggered: root.song.addTrack()
        }
    ]

    Component.onCompleted: {
        applicationWindow().controlsVisible = true;
    }

    Component.onDestruction: {
        applicationWindow().controlsVisible = true;
    }

    QtObject {
        id: privateProps

        property int headerWidth: 160
        property int headerHeight: 80
        property int cellWidth: headerWidth
        property int cellHeight: headerHeight
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true

            // HEADER ROW
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: privateProps.headerHeight
                Layout.maximumHeight: privateProps.headerHeight
                spacing: 1

                TableHeader {
                    Layout.preferredWidth: privateProps.headerWidth
                    Layout.maximumWidth: privateProps.headerWidth
                    Layout.fillHeight: true

                    text: "Song " + (root.song.index+1)
                    subText: "BPM: " + root.song.bpm

                    onPressed: {
                        sidebar.heading = "Song " + (root.song.index+1);
                        sidebar.controlType = Sidebar.ControlType.Song;
                        sidebar.controlObj = root.song;
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

                    model: root.song.partsModel

                    delegate: TableHeader {
                        text: "Part " + (part.partIndex+1) // part.name
                        subText: part.length + " Bar"

                        property var part: root.song.partsModel.data(root.song.partsModel.index(index, 0))

                        width: privateProps.headerWidth
                        height: ListView.view.height

                        onPressed: {
                            sidebar.heading = "Part " + (part.partIndex+1) // part.name;
                            sidebar.controlType = Sidebar.ControlType.Part;
                            sidebar.controlObj = part;
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

                    model: root.song.tracksModel

                    delegate: TableHeader {
                        text: track.name
                        subText: track.type === "audio" ? "Audio" : "Midi"

                        property var track: root.song.tracksModel.data(root.song.tracksModel.index(index,0))

                        width: ListView.view.width
                        height: privateProps.headerHeight

                        onPressed: {
                            sidebar.heading = track.name;
                            sidebar.controlType = Sidebar.ControlType.Track;
                            sidebar.controlObj = track;
                        }

                        onPressAndHold: {
                            zynthian.track.trackId = model.id
                            zynthian.current_modal_screen_id = "track"
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
                        columns: root.song.partsModel.rowCount(root.song.partsModel.index(0,0))
                        rowSpacing: 1
                        columnSpacing: 1

                        Repeater {
                            model: root.song.tracksModel

                            delegate: Repeater {
                                property var track: root.song.tracksModel.data(root.song.tracksModel.index(index, 0))
                                property int rowIndex: index

                                // TODO : Populate clips model per track in tracks model
                                model: root.song.partsModel

                                delegate: Rectangle {
                                    property var part: root.song.partsModel.data(root.song.partsModel.index(index, 0))
                                    property int colIndex: index

                                    Layout.preferredWidth: privateProps.cellWidth
                                    Layout.maximumWidth: privateProps.cellWidth
                                    Layout.preferredHeight: privateProps.cellHeight
                                    Layout.maximumHeight: privateProps.cellHeight

                                    color: "#444"

                                    border.width: focus ? 1 : 0
                                    border.color: Kirigami.Theme.highlightColor

                                    ZynthiLoops.Clip {
                                        id: clip
                                        row: rowIndex
                                        col: colIndex

                                        Component.onCompleted: {
                                            track.addClip(clip, colIndex);
                                            part.addClip(clip, rowIndex);
                                        }
                                    }

                                    TableHeaderLabel {
                                        anchors.centerIn: parent
                                        // text: "Clip " + (clip.col+1) // clip.name
                                        // text2: clip.length + " Bar"
                                    }

                                    MultiPointTouchArea {
                                        anchors.fill: parent
                                        onPressed: {
                                            parent.forceActiveFocus();
                                            sidebar.heading = "Clip " + (clip.col+1) // clip.name;
                                            sidebar.controlType = Sidebar.ControlType.Clip;
                                            sidebar.controlObj = clip;
                                        }
                                    }

                                    Kirigami.Icon {
                                        width: 24
                                        height: 24
                                        anchors.centerIn: parent
                                        color: "white"

                                        source: "media-playback-start"
                                        visible: clip.isPlaying
                                    }

                                    onFocusChanged: {
                                        console.log("Clip :", clip.row, clip.col)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Kirigami.Separator {
            Layout.preferredWidth: 2
            Layout.fillHeight: true
        }

        Sidebar {
            id: sidebar

            Layout.preferredWidth: 160
            Layout.maximumWidth: Layout.preferredWidth
            Layout.fillHeight: true
        }
    }
}
