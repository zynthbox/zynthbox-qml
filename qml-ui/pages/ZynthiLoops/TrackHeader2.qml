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

    property alias textSize: contents.font.pointSize
    property var subTextSize
    property var subSubTextSize

    property color color: Kirigami.Theme.backgroundColor
    property bool highlighted: false
    property bool highlightOnFocus: true

    contentItem: Item {
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
                    width: parent.width * 0.4
                    height: parent.height

                    horizontalAlignment: "AlignHCenter"
                    verticalAlignment: "AlignVCenter"
                    elide: "ElideRight"
                    text: root.text
                    font.pointSize: 8
                }

                Item {
                    anchors {
                        left: contents.right
                    }
                    width: parent.width * 0.6
                    height: parent.height

                    Image {
                        id: synthImage
                        visible: model.track.trackAudioType === "synth" &&
                                 model.track.occupiedSlotsCount > 0  &&
                                 synthImage.status !== Image.Error
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                        opacity: 0.7
                        property string imageName: String(model.track.connectedSoundName.split(" > ")[0]).toLowerCase().replace(/ /g, "-")
                        source: imageName !== "" ? Qt.resolvedUrl("../../../img/synths/" + imageName  + ".png") : ""
                    }

                    Image {
                        visible: (model.track.trackAudioType === "synth" && synthImage.status === Image.Error && model.track.occupiedSlotsCount > 0) ||
                                 ["sample-loop", "sample-trig", "sample-slice"].indexOf(model.track.trackAudioType) >= 0
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        horizontalAlignment: Image.AlignHCenter
                        verticalAlignment: Image.AlignVCenter
                        clip: true
                        opacity: 0.5
                        source: Qt.resolvedUrl("../../../img/synths/zynth-default.png")
                    }
                }

//                Rectangle {
//                    anchors {
//                        left: parent.left
//                        right: parent.right
//                        bottom: parent.bottom
//                    }
//                    height: Kirigami.Units.gridUnit * 0.5

//                    color: "#66444444"
//                    visible: detailsLabel.text &&
//                             detailsLabel.text.length > 0

//                    QQC2.Label {
//                        id: detailsLabel
//                        anchors.fill: parent
//                        elide: "ElideRight"
//                        horizontalAlignment: "AlignHCenter"
//                        verticalAlignment: "AlignVCenter"
//                        font.pointSize: 7
//                        text: model.track.trackAudioType === "synth"
//                              ? model.track.connectedSoundName.split(" > ")[0]
//                              : ["sample-trig", "sample-slice"].indexOf(model.track.trackAudioType) >= 0
//                                  ? model.track.samples[0].path.split("/").pop()
//                                  : model.track.trackAudioType === "sample-loop"
//                                      ? model.track.sceneClip.path.split("/").pop()
//                                      : qsTr("Midi %1").arg(model.track.externalMidiChannel > -1 ? model.track.externalMidiChannel + 1 : model.track.id + 1)
//                    }
//                }


                Rectangle {
                    height: Kirigami.Units.gridUnit * 0.7
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    color: "#99888888"
                    visible: synthName.text &&
                             synthName.text.length > 0

                    QQC2.Label {
                        id: synthName
                        anchors.fill: parent
                        elide: "ElideRight"
                        horizontalAlignment: "AlignHCenter"
                        verticalAlignment: "AlignVCenter"
                        font.pointSize: 7
                        // text: track.connectedSoundName.split(" > ")[0]
                        text: model.track.trackAudioType === "synth"
                                  ? model.track.connectedSoundName.split(" > ")[0]
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
