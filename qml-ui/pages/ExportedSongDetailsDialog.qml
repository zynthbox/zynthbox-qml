/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

A dialog to display details about exported song

Copyright (C) 2023 Anupam Basak <anupam.basak27@gmail.com>

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
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian

Zynthian.Dialog {
    id: component
    property string recordingDir: ""

    x: Math.round(parent.width/2 - width/2)
    y: Math.round(parent.height/2 - height/2)
    width: parent.width - Kirigami.Units.gridUnit * 4
    height: parent.height - Kirigami.Units.gridUnit * 4
    parent: QQC2.Overlay.overlay

    onOpenedChanged: {
        if (component.opened) {
            let recordingFilenames = []
            for (let index in Zynthbox.AudioLevels.recordingFilenames()) {
                let filepath = Zynthbox.AudioLevels.recordingFilenames()[index]
                if (filepath != null && filepath != "") {
                    if (component.recordingDir === "") {
                        try {
                            component.recordingDir = filepath.match(/.*exported-.*\//)[0]
                        } catch(e) {
                            console.error(e)
                        }
                    }
                    let filename = filepath.split("/").pop()
                    recordingFilenames.push(filename)
                }
            }
            filesListView.model = recordingFilenames
        }
    }

    header: ColumnLayout {
        Kirigami.Heading {
            text: qsTr("Song export details")
            padding: Kirigami.Units.gridUnit
        }
        Kirigami.Separator {
            Layout.fillWidth: true
        }
    }
    footer: QQC2.Button {
        height: Kirigami.Units.gridUnit * 3
        text: qsTr("Close")
        onClicked: component.close()
    }
    contentItem: ColumnLayout {
        spacing: Kirigami.Units.gridUnit
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            Kirigami.Heading {
                text: qsTr("Song exported to :")
                verticalAlignment: Kirigami.Heading.AlignVCenter
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                color: Kirigami.Theme.backgroundColor
                border.color: "#ff999999"
                border.width: 1
                radius: 4
                Kirigami.Heading {
                    id: recordingDirLabel
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    text: component.recordingDir
                    wrapMode: QQC2.Label.WordWrap
                    verticalAlignment: QQC2.Label.AlignVCenter
                }
            }
        }
        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            text: qsTr("Files :")
        }
        ListView {
            id: filesListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Kirigami.Units.gridUnit * 2
            spacing: Kirigami.Units.largeSpacing
            highlightFollowsCurrentItem: false
            delegate: Kirigami.BasicListItem {
                highlighted: false
                width: ListView.view.width
                label: model.modelData
                icon: "audio-x-wav"
            }
        }
    }
}
