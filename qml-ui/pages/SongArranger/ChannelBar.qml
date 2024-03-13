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

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian

// GridLayout so TabbedControlView knows how to navigate it
GridLayout {
    id: root
    rows: 1
    Layout.fillWidth: true

    property QtObject sideBar: null

    ColumnLayout {
        Layout.alignment: Qt.AlignTop
        Layout.fillHeight: true
        Layout.fillWidth: true

        QQC2.Label {
            text: "Clips :"
        }

        ListView {
            id: clipsList
            model: root.sideBar.controlObj.zlChannel.clipsModel
            Layout.fillWidth: true
            Layout.fillHeight: true
            interactive: true
            clip: true
            delegate: Kirigami.BasicListItem {
                leftPadding: 0
                width: ListView.view.width
                text: model.clip.name + "(" + model.clip.duration.toFixed(2) +"s)"
                visible: !model.clip.isEmpty
                highlighted: root.sideBar.controlObj.selectedClip === model.clip
                onClicked: {
                    root.sideBar.controlObj.selectedClip = model.clip
                }
            }
        }
    }
}

