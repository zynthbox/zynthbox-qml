/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Marco MArtin <mart@kde.org>

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

//import Zynthian 1.0 as Zynthian

Rectangle {
    readonly property QtObject song: zynthian.zynthiloops.song
    readonly property QtObject scenesModel: song.scenesModel

    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    ColumnLayout {
        anchors.fill: parent
        anchors.centerIn: parent
        anchors.margins: Kirigami.Units.gridUnit*0.3

        Kirigami.Heading {
            id: heading
            text: qsTr("Scenes : Scene %1").arg(scenesModel.getScene(scenesModel.selectedSceneIndex).name)
        }

        QQC2.ButtonGroup {
            id: scenesButtonGroup
            buttons: scenesGrid.children
        }

        GridLayout {
            id: scenesGrid
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            rows: 2
            columns: Math.ceil(scenesModel.count/2)

            Repeater {
                model: scenesModel
                delegate: Item {
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    // height: (scenesGrid.height/scenesGrid.rows) - scenesGrid.rowSpacing*(scenesGrid.rows-1)

                    QQC2.RoundButton {
                        width: parent.height
                        height: parent.height
                        anchors.centerIn: parent

                        radius: 16
                        text: model.scene.name
                        font.pointSize: 28
                        checkable: true
                        checked: index === scenesModel.selectedSceneIndex
                        onClicked: {
                            scenesModel.stopAllClipsInCurrentScene();
                            scenesModel.selectedSceneIndex = index;
                        }
                    }
                }
            }
        }
    }
}
