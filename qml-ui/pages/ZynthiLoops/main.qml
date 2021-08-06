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
    screenId: "zynthiloops"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Add Track")
            onTriggered: song.addTrack()
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

    ZynthiLoops.Song {
        id: song
        index: 0
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

                Rectangle {
                    Layout.preferredWidth: privateProps.headerWidth
                    Layout.maximumWidth: privateProps.headerWidth
                    Layout.fillHeight: true

                    border.width: focus ? 1 : 0
                    border.color: Kirigami.Theme.highlightColor

                    color: Kirigami.Theme.backgroundColor

                    TableHeaderLabel {
                        anchors.centerIn: parent

                        text: "Song " + (song.index+1)
                        text2: "BPM: " + song.bpm
                    }

                    MultiPointTouchArea {
                        anchors.fill: parent
                        onPressed: {
                            parent.focus = true;
                            sidebar.heading = "Song " + (song.index+1);
                            sidebar.controlType = Sidebar.ControlType.Song;
                            sidebar.controlObj = song;
                        }
                    }

                    onFocusChanged: {
                        console.log("Song focus :", focus)
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

                    model: song.partsModel

                    delegate: Rectangle {
                        property var part: song.partsModel.data(song.partsModel.index(index, 0))

                        width: privateProps.headerWidth
                        height: ListView.view.height

                        color: Kirigami.Theme.backgroundColor

                        border.width: focus ? 1 : 0
                        border.color: Kirigami.Theme.highlightColor

                        TableHeaderLabel {
                            anchors.centerIn: parent
                            text: "Part " + (part.partIndex+1) // part.name
                            text2: "Length: " + part.length + " Bar"
                        }

                        MultiPointTouchArea {
                            anchors.fill: parent
                            onPressed: {
                                parent.focus = true;
                                sidebar.heading = "Part " + (part.partIndex+1) // part.name;
                                sidebar.controlType = Sidebar.ControlType.Part;
                                sidebar.controlObj = part;
                            }
                        }

                        onFocusChanged: {
                            console.log("Part focus :", focus)
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

                    model: song.tracksModel

                    delegate: Rectangle {
                        property var track: model

                        width: ListView.view.width
                        height: privateProps.headerHeight

                        color: Kirigami.Theme.backgroundColor

                        border.width: focus ? 1 : 0
                        border.color: Kirigami.Theme.highlightColor

                        TableHeaderLabel {
                            anchors.centerIn: parent
                            text: track.name
                            text2: track.type === "audio" ? "Audio" : "Midi"
                        }

                        MultiPointTouchArea {
                            anchors.fill: parent
                            onPressed: {
                                parent.focus = true;
                                sidebar.heading = track.name;
                                sidebar.controlType = Sidebar.ControlType.Track;
                                sidebar.controlObj = track;
                            }
                        }

                        onFocusChanged: {
                            console.log("Track focus :", focus)
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
                        columns: song.partsModel.rowCount(song.partsModel.index(0,0))
                        rowSpacing: 1
                        columnSpacing: 1

                        Repeater {
                            model: song.tracksModel

                            delegate: Repeater {
                                property var track: song.tracksModel.data(song.tracksModel.index(index, 0))
                                property int rowIndex: index

                                // TODO : Populate clips model per track in tracks model
                                model: song.partsModel

                                delegate: Rectangle {
                                    property var part: song.partsModel.data(song.partsModel.index(index, 0))
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
                                        text: "Clip " + (clip.col+1) // clip.name
                                        text2: "Length: " + clip.length + " Bar"
                                    }

                                    MultiPointTouchArea {
                                        anchors.fill: parent
                                        onPressed: {
                                            parent.focus = true;
                                            sidebar.heading = "Clip " + (clip.col+1) // clip.name;
                                            sidebar.controlType = Sidebar.ControlType.Clip;
                                            sidebar.controlObj = clip;
                                        }
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
