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
import org.zynthian.quick 1.0 as ZynQuick
import JuceGraphics 1.0

// GridLayout so TabbedControlView knows how to navigate it
Rectangle {
    id: root

    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    property QtObject bottomBar: null
    property QtObject sequence: ZynQuick.PlayGridManager.getSequenceModel("Scene " + zynthian.zynthiloops.song.scenesModel.selectedSceneName)

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.trackButton.checked = true
                return true;
        }
        return false;
    }

    GridLayout {
        anchors.fill: parent
        rows: 1

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 1

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 1

                QQC2.ButtonGroup {
                    buttons: buttonsColumn.children
                }

                BottomStackTabs {
                    id: buttonsColumn
                    Layout.preferredWidth: privateProps.cellWidth + 6
                    Layout.maximumWidth: privateProps.cellWidth + 6
                    Layout.bottomMargin: 5
                    Layout.fillHeight: true
                }

                RowLayout {
                    id: contentColumn
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.bottomMargin: 5

                    spacing: 1

                    // Spacer
                    Item {
                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                    }

                    Repeater {
                        model: 10
                        delegate: ColumnLayout {
                            id: trackDelegate
                            property QtObject track: zynthian.zynthiloops.song.tracksModel.getTrack(model.index);

                            Layout.fillWidth: false
                            Layout.fillHeight: true
                            Layout.preferredWidth: privateProps.cellWidth

                            spacing: 1

                            Repeater {
                                model: 5
                                delegate: Rectangle {
                                    id: partDelegate
                                    property int partIndex: index
                                    property QtObject pattern: root.sequence.getByPart(trackDelegate.track.id, model.index)
                                    property QtObject clip: trackDelegate.track.getClipsModelByPart(partDelegate.partIndex).getClip(zynthian.zynthiloops.selectedClipCol)

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: "#000000"
                                    border{
                                        color: Kirigami.Theme.highlightColor
                                        width: (trackDelegate.track.trackAudioType === "sample-loop" && trackDelegate.track.selectedPart === partDelegate.partIndex) ||
                                               (partDelegate.pattern && partDelegate.pattern.enabled)
                                                ? 1
                                                : 0
                                    }
                                    WaveFormItem {
                                        anchors.fill: parent
                                        color: Kirigami.Theme.textColor
                                        source: partDelegate.clip ? partDelegate.clip.path : ""

                                        visible: trackDelegate.track.trackAudioType === "sample-loop" &&
                                                 partDelegate.clip && partDelegate.clip.path && partDelegate.clip.path.length > 0
                                    }
                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        smooth: false
                                        visible: trackDelegate.track.trackAudioType !== "sample-loop"
                                            && partDelegate.pattern
                                        source: partDelegate.pattern ? partDelegate.pattern.thumbnailUrl : ""
                                        Rectangle {
                                            anchors {
                                                top: parent.top
                                                bottom: parent.bottom
                                            }
                                            visible: partDelegate.pattern ? partDelegate.pattern.isPlaying : false
                                            color: Kirigami.Theme.highlightColor
                                            property double widthFactor: partDelegate.pattern ? parent.width / (partDelegate.pattern.width * partDelegate.pattern.bankLength) : 1
                                            width: Math.max(1, Math.floor(widthFactor))
                                            x: partDelegate.pattern ? partDelegate.pattern.bankPlaybackPosition * widthFactor : 0
                                        }
                                    }
                                    QQC2.Label {
                                        anchors.centerIn: parent
                                        font.pointSize: 8
                                        visible: ["sample-trig", "sample-slice", "synth", "external"].indexOf(trackDelegate.track.trackAudioType) >= 0
                                        text: qsTr("%1%2")
                                                .arg(trackDelegate.track.id + 1)
                                                .arg(String.fromCharCode(partDelegate.partIndex+65).toLowerCase())
                                    }
                                    Rectangle {
                                        height: 16
                                        anchors {
                                            left: parent.left
                                            top: parent.top
                                            right: parent.right
                                        }
                                        color: "#99888888"
                                        visible: trackDelegate.track.trackAudioType === "sample-loop" &&
                                                 detailsLabel.text && detailsLabel.text.trim().length > 0

                                        QQC2.Label {
                                            id: detailsLabel

                                            anchors.centerIn: parent
                                            width: parent.width - 4
                                            elide: "ElideRight"
                                            horizontalAlignment: "AlignHCenter"
                                            font.pointSize: 8
                                            text: partDelegate.clip.path.split("/").pop()
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (trackDelegate.track.selectedPart === partDelegate.partIndex) {
                                                partDelegate.pattern.enabled = !partDelegate.pattern.enabled;
                                            } else {
                                                trackDelegate.track.selectedPart = partDelegate.partIndex;
                                                partDelegate.pattern.enabled = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        Layout.preferredWidth: privateProps.cellWidth*2
                    }
                }
            }
        }
    }
}
