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
import org.kde.kirigami 2.4 as Kirigami

import '../../Zynthian' 1.0 as Zynthian

Zynthian.ScreenPage {
    screenId: "zynthiloops"
    leftPadding: 0
    rightPadding: 0
    topPadding: 5
    bottomPadding: 5

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Add Track")
            onTriggered: zynthian.zynthiloops.addTrack()
        }
    ]

    Component.onCompleted: {
        applicationWindow().controlsVisible = true;
//        applicationWindow().headerVisible = false;
    }

    Component.onDestruction: {
        applicationWindow().controlsVisible = true;
//        applicationWindow().headerVisible = true;
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
            Layout.alignment: Qt.AlignTop

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

                    color: Kirigami.Theme.backgroundColor

                    TableHeaderLabel {
                        text: "Song 1"
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

                    model: zynthian.zynthiloops.partsCount

                    delegate: Rectangle {
                        width: privateProps.headerWidth
                        height: ListView.view.height

                        color: Kirigami.Theme.backgroundColor

                        TableHeaderLabel {
                            text: "Part " + (modelData + 1)
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

                    model: zynthian.zynthiloops.model

                    delegate: Rectangle {
                        property var track: model

                        width: ListView.view.width
                        height: privateProps.headerHeight

                        color: Kirigami.Theme.backgroundColor

                        TableHeaderLabel {
                            text: track.name
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
                        columns: zynthian.zynthiloops.partsCount
                        rowSpacing: 1
                        columnSpacing: 1

                        Repeater {
                            model: zynthian.zynthiloops.model

                            delegate: Repeater {
                                property int rowIndex: index
                                model: zynthian.zynthiloops.partsCount

                                delegate: Rectangle {
                                    property int colIndex: index

                                    Layout.preferredWidth: privateProps.cellWidth
                                    Layout.maximumWidth: privateProps.cellWidth
                                    Layout.preferredHeight: privateProps.cellHeight
                                    Layout.maximumHeight: privateProps.cellHeight

                                    color: "#444"

                                    QQC2.Label {
                                        anchors.centerIn: parent
                                        text: rowIndex + "," + colIndex
                                    }

                                    MultiPointTouchArea {
                                        anchors.fill: parent
                                        onPressed: {
                                        }
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
            Layout.fillHeight: true
            Layout.preferredWidth: 160
            Layout.maximumWidth: Layout.preferredWidth
        }
    }
}
