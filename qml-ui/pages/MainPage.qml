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

        property var iconWidth: mainviewRectId.width / 6
        property var iconHeight:  mainviewRectId.height / 2


        HomeScreenIcon {
            rectWidth: mainviewRectId.width / 6
            rectHeight:  mainviewRectId.height / 2
            rectX:0
            imgSrc: Qt.resolvedUrl("../../img/layers.svg")
            onClicked: zynthian.current_screen_id = "layer"
            text: "Layers"
        }

        HomeScreenIcon {
            rectWidth: mainviewRectId.width / 6
            rectHeight: mainviewRectId.height / 2
            rectX:  mainviewRectId.width / 6
            imgSrc: Qt.resolvedUrl("../../img/playgrid.svg")
            onClicked:  zynthian.current_modal_screen_id = "playgrid"
            text: "Playgrid"
        }

        HomeScreenIcon {
            rectWidth: mainviewRectId.width / 6
            rectHeight: mainviewRectId.height / 2
            rectX:  (mainviewRectId.width / 6) * 2
            imgSrc: Qt.resolvedUrl("../../img/zynthiloops.svg")
            onClicked:  zynthian.current_modal_screen_id = "zynthiloops"
            text: "Zynthiloops"
        }

        HomeScreenIcon {
            rectWidth: mainviewRectId.width / 6
            rectHeight: mainviewRectId.height / 2
            rectX:  (mainviewRectId.width / 6) * 3
            imgSrc: Qt.resolvedUrl("../../img/rec-audio.svg")
            onClicked:  zynthian.current_modal_screen_id = "audio_recorder"
            text: "Audio Recorder"
        }

        HomeScreenIcon {
            rectWidth: mainviewRectId.width / 6
            rectHeight: mainviewRectId.height / 2
            rectX:  (mainviewRectId.width / 6) * 4
            imgSrc: Qt.resolvedUrl("../../img/track.svg")
            onClicked:  zynthian.current_modal_screen_id = "track"
            text: "Tracks"
        }

        HomeScreenIcon {
            rectWidth: mainviewRectId.width / 6
            rectHeight: mainviewRectId.height / 2
            rectX:  (mainviewRectId.width / 6) * 5
            imgSrc: Qt.resolvedUrl("../../img/rec.svg")
            onClicked:  zynthian.current_modal_screen_id = "midi_recorder"
            text: "MIDI Recorder"
        }
 
        HomeScreenIcon {
            rectWidth: mainviewRectId.width / 6
            rectHeight: mainviewRectId.height / 2
            rectX:  0
            rectY: mainviewRectId.height / 2
            imgSrc: Qt.resolvedUrl("../../img/snapshots.svg")
            onClicked:  zynthian.current_modal_screen_id = "snapshot"
            text: "Snapshots"
        }

        HomeScreenIcon {
            rectWidth: mainviewRectId.width / 6
            rectHeight: mainviewRectId.height / 2
            rectX:  mainviewRectId.width / 6
            rectY: mainviewRectId.height / 2
            imgSrc: Qt.resolvedUrl("../../img/settings.svg")
            onClicked:  zynthian.current_modal_screen_id = "admin"
            text: "Settings"
        }
    }

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Synth Setup")
            onTriggered: zynthian.current_screen_id = "layer"
        }
    ]
}
