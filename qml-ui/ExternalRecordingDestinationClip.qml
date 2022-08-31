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

import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1
import org.kde.kirigami 2.6 as Kirigami

ColumnLayout {
    id: component
    anchors {
        fill: parent
    }
    property QtObject selectedClip: channelsList.currentItem && channelsList.currentItem.selectedClip ? channelsList.currentItem.selectedClip : null
    Kirigami.Heading {
        Layout.fillWidth: true
        text: qsTr("Record Into A Clip");
    }
    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: qsTr("(not a thing yet - WIP) Recordings from this module will be stored as the contents of a clip selected by you here. Each time you hit record, the existing contents of the clip will be replaced by the new recording.")
    }
    ListView {
        id: channelsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: 10
        delegate: QQC2.ItemDelegate {
            width: ListView.view.width
            property QtObject selectedClip: contentItem.selectedClip
            contentItem: RowLayout {
                id: delegate
                property QtObject channel: zynthian.sketchpad.song.channelsModel.getChannel(index)
                property QtObject selectedClip: null
                property int thisIndex: index
                QQC2.Label {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    text: "Channel " + (index+1)
                }
                Repeater {
                    model: 10
                    QQC2.Button {
                        property QtObject clip: delegate.channel.clipsModel.getClip(index)
                        Layout.fillHeight: true
                        text: clip.name
                        checked: ListView.isCurrentItem && delegate.selectedClip === clip
                        onClicked: {
                            delegate.selectedClip = clip;
                            channelsList.currentIndex = delegate.thisIndex;
                        }
                    }
                }
            }
        }
    }
}
