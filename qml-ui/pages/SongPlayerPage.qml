/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Song Player Page

Copyright (C) 2022 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import libzl 1.0 as ZL
import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

Zynthian.ScreenPage {
    id: component
    screenId: "song_player"
    title: qsTr("Song Player")

    function cuiaCallback(cuia) {
        var returnValue = false;
        if (multitrackRecorderPopup.opened) {
            returnValue = multitrackRecorderPopup.cuiaCallback(cuia);
        }
        return returnValue;
    }

    contextualActions: [
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            text: qsTr("Record Song")
            onTriggered: {
                multitrackRecorderPopup.recordSong(zynthian.zynthiloops.song)
            }
        }
    ]
    Zynthian.MultitrackRecorderPopup {
        id: multitrackRecorderPopup
    }
    ColumnLayout {
        anchors.fill: parent;
        Kirigami.Heading {
            Layout.fillWidth: true
            text: component.title
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
