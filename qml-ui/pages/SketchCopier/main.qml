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

    id: root

    title: qsTr("Sketch Copier")
    screenId: "sketch_copier"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8

    contextualActions: [
        Kirigami.Action {
            text: "Reload"
            onTriggered: {
                copier.generate_sketches_from_session()
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
    }    

    contentItem : RowLayout {
        ColumnLayout {
            QQC2.Label {
                text: qsTr("Session: %1").arg(session.name)
            }

            QQC2.Label {
                text: "No sketches found in session"
                font.italic: true
                visible: copier.sketches[0] === undefined
            }

            QQC2.Label {
                text: "Song : " + copier.sketches[0].name
                font.italic: true
                visible: copier.sketches[0] !== undefined
            }

            Repeater {
                model: copier.sketches[0].tracksModel
                delegate: QQC2.Label {
                    text: track.name
                }
            }
        }
    }
}
