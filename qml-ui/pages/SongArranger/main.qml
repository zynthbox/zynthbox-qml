/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Arranger Page

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

import Zynthian 1.0 as Zynthian

Zynthian.ScreenPage {
    readonly property QtObject arranger: zynthian.song_arranger

    id: root

    title: qsTr("Song Arranger")
    screenId: "song_arranger"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Start")
            enabled: !arranger.isPlaying
            onTriggered: {
                arranger.start()
            }
        },
        Kirigami.Action {
            text: qsTr("Stop")
            enabled: arranger.isPlaying
            onTriggered: {
                arranger.stop()
            }
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

        //Try to fit exactly until a minimum allowed size
        property int headerWidth: 100
        property int headerHeight: 50
        property int cellWidth: 50
        property int cellHeight: headerHeight
    }    

    contentItem : RowLayout {
        ColumnLayout {
            id: tableLayout
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 1

            // STATUS ROW
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: privateProps.headerHeight/1.5
                Layout.maximumHeight: privateProps.headerHeight/1.5
                spacing: 1

                Zynthian.TableHeader {
                    id: statusCell
                    Layout.preferredWidth: privateProps.headerWidth
                    Layout.maximumWidth: privateProps.headerWidth
                    Layout.fillHeight: true

                    text: "Start : "+(arranger.startFromBar+1)+".1"
                }

                ListView {
                    id: statusHeaderRow

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true
                    spacing: 1
                    contentX: cellGridFlickable.contentX
                    orientation: Qt.Horizontal
                    boundsBehavior: Flickable.StopAtBounds

                    model: root.arranger.bars

                    delegate: Zynthian.TableHeader {
                        iconSource: modelData === arranger.startFromBar
                                        ? "media-playback-start"
                                        : ""

                        width: privateProps.cellWidth
                        height: ListView.view.height
                    }
                }
            }
            // END STATUS ROW

            // HEADER ROW
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: privateProps.headerHeight
                Layout.maximumHeight: privateProps.headerHeight
                spacing: 1

                Zynthian.TableHeader {
                    id: songCell
                    Layout.preferredWidth: privateProps.headerWidth
                    Layout.maximumWidth: privateProps.headerWidth
                    Layout.fillHeight: true

                    text: "Song"

                    onPressed: {
                        sideBar.controlType = SideBar.ControlType.None;
                        sideBar.controlObj = null;
                    }
                }

                ListView {
                    id: barsHeaderRow

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true
                    spacing: 1
                    contentX: cellGridFlickable.contentX
                    orientation: Qt.Horizontal
                    boundsBehavior: Flickable.StopAtBounds

                    model: root.arranger.bars

                    delegate: Zynthian.TableHeader {
                        text: modelData%4 === 0 ? (modelData+1) : ""

                        width: privateProps.cellWidth
                        height: ListView.view.height

                        onPressed: {
                            sideBar.controlType = SideBar.ControlType.None;
                            sideBar.controlObj = null;

                            if (arranger.startFromBar === modelData) {
                                arranger.startFromBar = 0
                            }
                            else {
                                arranger.startFromBar = modelData;
                            }
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
                    contentY: cellGridFlickable.contentY
                    boundsBehavior: Flickable.StopAtBounds

                    model: root.arranger.tracksModel

                    delegate: Zynthian.TableHeader {
                        text: track.zlTrack.name

                        width: ListView.view.width
                        height: privateProps.headerHeight

                        onPressed: {
                            sideBar.controlType = SideBar.ControlType.Track;
                            sideBar.controlObj = model.track;
                        }
                    }
                }

                Flickable {
                    id: cellGridFlickable

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: cellGrid.width
                    contentHeight: cellGrid.height

                    clip: true
                    flickableDirection: Flickable.HorizontalAndVerticalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
                        height: 4
                    }

                    contentX: barsHeaderRow.contentX
                    contentY: tracksHeaderColumns.contentY

                    Item {
                        GridLayout {
                            id: cellGrid
                            columns: root.arranger.bars
                            rowSpacing: 1
                            columnSpacing: 1

                            Repeater {
                                model: root.arranger.tracksModel

                                delegate: Repeater {
                                    model: track.cellsModel

                                    delegate: Rectangle {
                                        id: clipCell

                                        Layout.preferredWidth: privateProps.cellWidth
                                        Layout.maximumWidth: privateProps.cellWidth
                                        Layout.preferredHeight: privateProps.cellHeight
                                        Layout.maximumHeight: privateProps.cellHeight

                                        Layout.columnSpan: zlClip ? zlClip.length : 1

                                        color: cell.isPlaying ?
                                                   Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.5) :
                                                   Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)

                                        MouseArea {
                                            anchors.fill: parent
                                            onPressed: {
                                                if (track.selectedClip) {
                                                    cell.zlClip = track.selectedClip;

                                                    var component = Qt.createComponent("ClipCell.qml");
                                                    var obj = component.createObject(zlClipsContainer, {
                                                        "width": cellGrid.calculateCellWidth(track.selectedClip),
                                                        "height": privateProps.cellHeight,
                                                        "zlClip": track.selectedClip,
                                                        "x": clipCell.x,
                                                        "y": clipCell.y,
                                                        "z": 9999
                                                    });

                                                    obj.onPressed.connect(function() {
                                                        cell.zlClip = null;
                                                        obj.destroy();
                                                    });

                                                    if (obj === null) {
                                                        // Error Handling
                                                        console.log("Error creating object");
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            function calculateCellWidth(clip) {
                                if (clip) {
                                    var bars = Math.ceil(clip.length/4)
                                    return privateProps.cellWidth*bars + cellGrid.columnSpacing*(bars-1)
                                } else {
                                    return privateProps.cellWidth
                                }
                            }
                        }

                        Item {
                            id: zlClipsContainer
                            width: cellGrid.width
                            height: cellGrid.height
                        }
                    }
                }
            }
        }

        SideBar {
            id: sideBar

            Layout.preferredWidth: Kirigami.Units.gridUnit * 7
            Layout.fillWidth: false
            Layout.fillHeight: true
        }
    }
}
