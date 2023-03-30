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
    readonly property QtObject arranger: zynqtgui.song_arranger

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

        property int headerWidth: 100
        // Try to fix 12 channels
        property int headerHeight: Math.round(tableLayout.height/14 - cellGrid.rowSpacing*2)
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
                        color: arranger.isPlaying && arranger.playingBar === modelData
                                ? "#888888"
                                : null

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
                    id: channelsHeaderColumns

                    Layout.preferredWidth: privateProps.headerWidth
                    Layout.maximumWidth: privateProps.headerWidth
                    Layout.fillHeight: true

                    clip: true
                    spacing: 1
                    contentY: cellGridFlickable.contentY
                    boundsBehavior: Flickable.StopAtBounds

                    model: root.arranger.channelsModel

                    delegate: Zynthian.TableHeader {
                        text: channel.zlChannel.name

                        width: ListView.view.width
                        height: privateProps.headerHeight

                        onPressed: {
                            sideBar.controlType = SideBar.ControlType.Channel;
                            sideBar.controlObj = model.channel;
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

                    contentX: barsHeaderRow.contentX - barsHeaderRow.originX
                    contentY: channelsHeaderColumns.contentY - channelsHeaderColumns.originY

                    Item {
                        Grid {
                            id: cellGrid
                            columns: root.arranger.bars
                            rowSpacing: 1
                            columnSpacing: 1

                            Repeater {
                                model: root.arranger.channelsModel

                                delegate: Repeater {
                                    model: channel.cellsModel

                                    delegate: Item {
                                        width: privateProps.cellWidth
                                        height: privateProps.cellHeight
                                        z: root.arranger.bars - cell.bar

                                        ClipCell {
                                            id: clipCell

                                            zlClip: cell.zlClip

                                            width: cellGrid.calculateCellWidth(cell.zlClip)
                                            height: privateProps.cellHeight

                                            onPressed: {
                                                if (cell.zlClip) {
                                                    // Clip already selected. Remove clip.
                                                    cell.zlClip = null;
                                                } else if (channel.selectedClip) {
                                                    // No clips selected. Add clip
                                                    cell.zlClip = channel.selectedClip;
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
