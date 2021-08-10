 /* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

Copyright (C) 2021 Marco Martin <mart@kde.org>

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

import Zynthian 1.0 as Zynthian

Zynthian.SelectorPage {
    screenId: "main"
    backAction.visible: false

    Rectangle {
        id:mainviewRectId
        width: screen.width - (Kirigami.Units.gridUnit * 2) - 4
        height: screen.height - (Kirigami.Units.gridUnit * 8) - 4
        anchors.centerIn:parent
        color:"transparent"

        Rectangle {
            id:layersRect
            width:mainviewRectId.width / 6
            height:mainviewRectId.height / 2
            color:"transparent"

            QQC2.Button {
                anchors.fill: parent
                onClicked: zynthian.current_screen_id = "layer"
            
                Image {
                    id:layersSvg
                    anchors.centerIn: parent
                    width:90;height:90
                    source:  Qt.resolvedUrl("../../img/layers.svg")
                }

                Kirigami.Heading {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                    }
                    text: "Layers"
                    font.pointSize: 12
                }
            }
        }

        Rectangle {
            id:playgridRect
            x:layersRect.width
            width:mainviewRectId.width / 6
            height:mainviewRectId.height / 2
            color:"transparent"

            QQC2.Button {
                anchors.fill: parent
                onClicked:  zynthian.current_modal_screen_id = "playgrid"
            
                Image {
                    id:playgridSvg
                    anchors.centerIn: parent
                    width:90;height:90
                    source:  Qt.resolvedUrl("../../img/playgrid.svg")
                }

                Kirigami.Heading {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                    }
                    text: "Playgrid"
                    font.pointSize: 12
                }
            }
        }

        Rectangle {
            id:zynthiloopsRect
            x:playgridRect.x + playgridRect.width
            width:mainviewRectId.width / 6
            height:mainviewRectId.height / 2
            color:"transparent"

            
            QQC2.Button {
                anchors.fill: parent
                onClicked: zynthian.current_modal_screen_id = "zynthiloops"

                Image {
                    id:zynthiloopsSvg
                    anchors.centerIn: parent
                    width:90;height:90
                    source:  Qt.resolvedUrl("../../img/zynthiloops.svg")
                }

                Kirigami.Heading {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                    }
                    text: "ZynthiLoops"
                    font.pointSize: 12
                }

            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }
        }

        Rectangle {
            id:trackRect
            x:zynthiloopsRect.x + zynthiloopsRect.width
            width:mainviewRectId.width / 6
            height:mainviewRectId.height / 2
            color:"transparent"

            Image {
                anchors.centerIn: parent
                width:90;height:90
                source:  Qt.resolvedUrl("../../img/track.svg")
            }

            Kirigami.Heading {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.bottom
                    bottomMargin: Kirigami.Units.gridUnit * 2
                }
                text: "Tracks"
                font.pointSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    zynthian.current_modal_screen_id = "track"
                }
            }
        }

        Rectangle {
            id:audiorecorderRect
            x:trackRect.x + trackRect.width
            width:mainviewRectId.width / 6
            height:width
            color:"transparent"

            Image {
                id:audiorecorderSvg
                anchors.centerIn: parent
                width:90;height:90
                source:  Qt.resolvedUrl("../../img/rec-audio.svg")
            }

            Kirigami.Heading {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.bottom
                    bottomMargin: Kirigami.Units.gridUnit * 2
                }
                text: "Audio Recorder"
                font.pointSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    zynthian.current_modal_screen_id = "audio_recorder"
                }
            }
        }

        Rectangle {
            id:midirecorderRect
            x:audiorecorderRect.x + audiorecorderRect.width
            width:mainviewRectId.width / 6
            height:mainviewRectId.height / 2
            color:"transparent"

            Image {
                id:midirecorderSvg
                anchors.centerIn: parent
                width:90;height:90
                source:  Qt.resolvedUrl("../../img/rec.svg")
            }

            Kirigami.Heading {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.bottom
                    bottomMargin: Kirigami.Units.gridUnit * 2
                }
                text: "MIDI Recorder"
                font.pointSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    zynthian.current_modal_screen_id = "midi_recorder"
                }
            }
        }

        Rectangle {
            id:snapshotsRect
            y:mainviewRectId.height / 2
            width:mainviewRectId.width / 6
            height:mainviewRectId.height / 2
            color:"transparent"

            Image {
                id:snapshotsSvg
                anchors.centerIn: parent
                width:90;height:90
                source:  Qt.resolvedUrl("../../img/snapshots.svg")
            }

            Kirigami.Heading {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.bottom
                    bottomMargin: Kirigami.Units.gridUnit * 2
                }
                text: "Snapshots"
                font.pointSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    zynthian.current_modal_screen_id = "snapshot"
                }
            }
        }

        Rectangle {
            id:settingsRect
            x: snapshotsRect.x + snapshotsRect.width
            y:mainviewRectId.height / 2
            width:mainviewRectId.width / 6
            height:mainviewRectId.height / 2
            color:"transparent"

            Image {
                id:settingsSvg
                anchors.centerIn: parent
                width:90;height:90
                source:  Qt.resolvedUrl("../../img/settings.svg")
            }

            
            Kirigami.Heading {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.bottom
                    bottomMargin: Kirigami.Units.gridUnit * 2
                }
                text: "Settings"
                font.pointSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    zynthian.current_modal_screen_id = "admin"
                }
            }
        }
    }

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Synth Setup")
            onTriggered: zynthian.current_screen_id = "layer"
        }
    ]
}
