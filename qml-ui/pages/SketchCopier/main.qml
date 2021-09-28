/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Sketch CopierPage

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
    readonly property QtObject copier: zynthian.sketch_copier
    readonly property QtObject session: zynthian.session_dashboard
    readonly property QtObject curSketch: zynthian.zynthiloops.song

    id: root

    title: qsTr("Sketch Copier")
    screenId: "sketch_copier"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8

    contextualActions: [
        Kirigami.Action {
            text: "Sketch"

            Kirigami.Action {
                text: "Add New Sketch"
                onTriggered: {
                }
            }
            Kirigami.Action {
                text: "Add Existing Sketch"
                onTriggered: {
                }
            }
            Kirigami.Action {
                text: "Remove Sketch"
                onTriggered: {
                }
            }
        },
        Kirigami.Action {
            text: "Track"

            Kirigami.Action {
                text: "Copy Track"
                onTriggered: {
                }
            }
            Kirigami.Action {
                text: "Paste Track"
                onTriggered: {
                }
            }
        },
        Kirigami.Action {
            text: "Session"

            Kirigami.Action {
                text: "Save Session"
                onTriggered: {
                }
            }
            Kirigami.Action {
                text: "Load Session"
                onTriggered: {
                }
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

        // 12 buttons for both sketches and tracks
        property real buttonWidth: contentColumn.width/12 - contentColumn.spacing*2 - 10
        property real buttonHeight: Kirigami.Units.gridUnit*6
    }

    contentItem : ColumnLayout {
        id: contentColumn
        Item {
            id: headerData
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit*4

            QQC2.Label {
                anchors.centerIn: parent
                text: qsTr("Session: %1").arg(session.name)
                font.pointSize: 18
            }
        }
        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
        }
        ColumnLayout {
            property var selectedSketch: curSketch
            property int selectedIndex: 0

            id: sketchesData
            Layout.fillWidth: true

            // Available height: Total container height - header height - 2 seperator height
            // Height set: AvailableHeight/2
            Layout.preferredHeight: (contentColumn.height-headerData.height-2)/2

            RowLayout {
                QQC2.Label {
                    text: qsTr("Sketch %1: %2").arg(sketchesData.selectedIndex+1).arg(sketchesData.selectedSketch.name)
                    opacity: 0.7
                }

                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit
                }

                QQC2.Label {
                    text: qsTr("%1 BPM").arg(sketchesData.selectedSketch.bpm)
                }
            }

            RowLayout {
                CopierButton {
                    Layout.preferredWidth: privateProps.buttonWidth
                    Layout.preferredHeight: privateProps.buttonHeight

                    highlighted: sketchesData.selectedSketch == curSketch
                    text: "1"
                    onClicked: {
                        sketchesData.selectedSketch = curSketch;
                        sketchesData.selectedIndex = 0;
                    }
                }

                Repeater {
                    model: Object.keys(copier.sketches)
                    delegate: CopierButton {
                        property var sketch: copier.sketches[modelData]

                        Layout.preferredWidth: privateProps.buttonWidth
                        Layout.preferredHeight: privateProps.buttonHeight

                        highlighted: sketchesData.selectedSketch === sketch
                        text: sketch ? (sketch.id+1) : ""
                        enabled: sketch ? true : false
                        onClicked: {
                            sketchesData.selectedSketch = sketch;
                            sketchesData.selectedIndex = parseInt(modelData);
                        }
                    }
                }

                ColumnLayout {
                    id: sketchesInfoBar

                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: Kirigami.Units.gridUnit*2

                    QQC2.Label {
                        text: qsTr("%1 BPM").arg(sketchesData.selectedSketch.bpm)
                    }
                    Item {
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                    }
                    QQC2.Label {
                        text: qsTr("%1 Tracks").arg(sketchesData.selectedSketch.tracksModel.count)
                    }
                }
            }
        }
        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
        }
        ColumnLayout {
            property var selectedTrack

            id: tracksData
            Layout.fillWidth: true
            Layout.preferredHeight: sketchesData.height

            QQC2.Label {
                text: qsTr("Track %1: %2").arg(tracksData.selectedTrack.id+1).arg(tracksData.selectedTrack.name)
                opacity: 0.7
            }

            RowLayout {
                Repeater {
                    model: sketchesData.selectedSketch.tracksModel
                    delegate: CopierButton {
                        Layout.preferredWidth: privateProps.buttonWidth
                        Layout.preferredHeight: privateProps.buttonHeight

                        highlighted: tracksData.selectedTrack === track
                        text: (index+1)
                        onClicked: {
                            tracksData.selectedTrack = track;
                        }
                    }
                }

                Repeater {
                    model: 12 - (sketchesData.selectedSketch.tracksModel.count
                                   ? sketchesData.selectedSketch.tracksModel.count
                                   : 0)
                    delegate: CopierButton {
                        Layout.preferredWidth: privateProps.buttonWidth
                        Layout.preferredHeight: privateProps.buttonHeight

                        text: ""
                        enabled: false
                    }
                }

                ColumnLayout {
                    id: tracksInfoBar
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: Kirigami.Units.gridUnit*2

                    QQC2.Label {
                        text: qsTr("Sounds:")
                    }
                }
            }
        }
    }
}
