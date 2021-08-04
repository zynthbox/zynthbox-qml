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
        applicationWindow().headerVisible = false;
    }

    Component.onDestruction: {
        applicationWindow().controlsVisible = true;
        applicationWindow().headerVisible = true;
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
                Layout.preferredHeight: 50
                Layout.maximumHeight: Layout.preferredHeight
                spacing: 1

                Rectangle {
                    Layout.preferredWidth: 80
                    Layout.maximumWidth: Layout.preferredWidth
                    Layout.fillHeight: true

                    color: Kirigami.Theme.backgroundColor

                    TableHeaderLabel {
                        text: "Song 1"
                    }
                }

                Repeater {
                    model: zynthian.zynthiloops.partsCount

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        color: Kirigami.Theme.backgroundColor

                        TableHeaderLabel {
                            text: "Part " + modelData
                        }
                    }
                }
            }
            // END HEADER ROW

            // TRACK ROWS
            Kirigami.ScrollablePage {
                Layout.fillWidth: true
                Layout.fillHeight: true

                padding: 0
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0

                verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    spacing: 0

                    Repeater {
                        model: zynthian.zynthiloops.model

                        delegate: RowLayout {
                            property var track: model

                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            Layout.maximumHeight: Layout.preferredHeight
                            Layout.bottomMargin: 1
                            spacing: 1

                            Rectangle {
                                Layout.preferredWidth: 80
                                Layout.maximumWidth: Layout.preferredWidth
                                Layout.fillHeight: true

                                color: Kirigami.Theme.backgroundColor

                                TableHeaderLabel {
                                    text: track.name
                                }

                                MultiPointTouchArea {
                                    anchors.fill: parent

                                    onPressed: {
                                        console.log(track);
                                    }
                                }
                            }

                            Repeater {
                                model: zynthian.zynthiloops.partsCount

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    color: "#444"
                                }
                            }
                        }
                    }
                }
            }
            // END TRACK ROWS
        }

        Kirigami.Separator {
            Layout.preferredWidth: 2
            Layout.fillHeight: true
        }

        Sidebar {
            Layout.fillHeight: true
            Layout.preferredWidth: 80
            Layout.maximumWidth: Layout.preferredWidth
        }
    }
}
