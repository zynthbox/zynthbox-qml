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
import QtQml.Models 2.10
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian


QQC2.AbstractButton {
    id: root

    Layout.preferredWidth: privateProps.headerWidth
    Layout.maximumWidth: privateProps.headerWidth
    Layout.fillHeight: true

    property var subText
    property var subSubText
    property QtObject track

    property alias textSize: contents.font.pointSize
    property var subTextSize
    property var subSubTextSize

    property color color: Kirigami.Theme.backgroundColor
    property bool highlighted: false
    property bool highlightOnFocus: true

    property bool synthDetailsVisible: true

    property bool active: true

    contentItem: Item {
        opacity: root.active ? 1 : 0.3

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 2
            spacing: 2

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                color: root.color
                radius: 2
                visible: subSubText.length > 0

                QQC2.Label {
                    width: parent.width
                    anchors.centerIn: parent
                    horizontalAlignment: "AlignHCenter"
                    elide: "ElideRight"
                    font.pointSize: 6
                    text: subSubText
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                QQC2.Label {
                    id: contents
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.synthDetailsVisible
                            ? parent.width * 0.4
                            : parent.width
                    horizontalAlignment: "AlignHCenter"
                    elide: "ElideRight"
                    text: root.text
                    font.pointSize: 8
                }

                QQC2.Label {
                    id: subContents
                    anchors.top: contents.bottom
                    width: root.synthDetailsVisible
                            ? parent.width * 0.4
                            : parent.width
                    visible: root.subText != null
                    horizontalAlignment: "AlignHCenter"
                    verticalAlignment: "AlignVCenter"
                    elide: "ElideRight"
                    text: root.subText ? root.subText : ""
                    font.pointSize: 7
                }

                Item {
                    anchors {
                        left: contents.right
                    }
                    width: parent.width * 0.6
                    height: parent.height
                    visible: root.synthDetailsVisible

                    Image {
                        id: synthImage
                        visible: root.track.trackAudioType === "synth" &&
                                 root.track.occupiedSlotsCount > 0  &&
                                 synthImage.status !== Image.Error
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                        opacity: 0.7
                        property string imageName: String(root.track.connectedSoundName.split(" > ")[0]).toLowerCase().replace(/ /g, "-")
                        source: imageName !== "" ? Qt.resolvedUrl("../../../img/synths/" + imageName  + ".png") : ""
                    }

                    Image {
                        visible: (root.track.trackAudioType === "synth" && synthImage.status === Image.Error && root.track.occupiedSlotsCount > 0) ||
                                 ["sample-loop", "sample-trig", "sample-slice"].indexOf(root.track.trackAudioType) >= 0
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        horizontalAlignment: Image.AlignHCenter
                        verticalAlignment: Image.AlignVCenter
                        clip: true
                        opacity: 0.5
                        source: Qt.resolvedUrl("../../../img/synths/zynth-default.png")
                    }
                }

                Rectangle {
                    height: Kirigami.Units.gridUnit * 0.7
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    color: "#99888888"
                    visible: root.synthDetailsVisible &&
                             synthName.text &&
                             synthName.text.length > 0

                    QQC2.Label {
                        id: synthName
                        anchors.fill: parent
                        elide: "ElideRight"
                        horizontalAlignment: "AlignHCenter"
                        verticalAlignment: "AlignVCenter"
                        font.pointSize: 7
                        // text: track.connectedSoundName.split(" > ")[0]
                        text: root.track.trackAudioType === "synth"
                                  ? root.track.connectedSoundName.split(" > ")[0]
                                  : ""
                    }
                }
            }
        }
    }

    onPressed: {
        root.forceActiveFocus()
    }

    background: Rectangle {
        border.width: (root.highlightOnFocus && root.activeFocus) || root.highlighted ? 1 : 0
        border.color: Kirigami.Theme.highlightColor

        color: Kirigami.Theme.backgroundColor
    }
}
