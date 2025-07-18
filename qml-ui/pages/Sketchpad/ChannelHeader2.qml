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
import org.kde.plasma.core 2.0 as PlasmaCore

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

QQC2.Control {
    id: root

    property string text
    property var subText
    property var subSubText
    property QtObject channel
    property alias textSize: contents.font.pointSize
    property var subTextSize
    property var subSubTextSize
    property color color: Kirigami.Theme.backgroundColor
    property bool highlighted: false
    property bool highlightOnFocus: true
    property color highlightColor: Kirigami.Theme.highlightColor
    property bool synthDetailsVisible: true
    property bool active: true

    signal clicked()
    signal doubleClicked()

    contentItem: Item {
        opacity: root.active ? 1 : 0.3

        // Implement a double tap gesture
        // On released event, start the double tap timer if it is not already running
        // On pressed event, if the timer is already running then it means the 2nd tap was done within given time and hence a double tap event should be emitted
        // On pressed event, if the timer is not running then it means it is the first click. Dont do anything as released handler will start the double tap timer
        Timer {
            id: doublePressedTimer
            interval: 200
            repeat: false
            onTriggered: root.clicked()
        }
        MouseArea {
            anchors.fill: parent
            onPressed: {
                root.forceActiveFocus()
            }
            onReleased: {
                if (doublePressedTimer.running) {
                    doublePressedTimer.stop()
                    root.doubleClicked()
                } else {
                    doublePressedTimer.restart()
                }
            }
        }

        // An overlay for channel muted state
        Rectangle {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            color: Kirigami.Theme.negativeBackgroundColor
            opacity: root.channel.muted ? 0.7 : 0

            QQC2.Label {
                anchors.centerIn: parent
                font.bold: true
                font.pointSize: 14
                text: qsTr("M", "Short form for muted")
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 2
            spacing: 2
            // Reduce opacity when muted overlay is active to make muted overlay more prominent
            opacity: !root.channel.muted ? 1 : 0.3

            QQC2.Label {
                id: contents
                Layout.fillWidth: true
                Layout.fillHeight: false
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.text
                font.pointSize: 8
            }

            QQC2.Label {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                visible: subSubText.length > 0

                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pointSize: 8
                text: subSubText
                padding: 0

                // color: Kirigami.Theme.backgroundColor

                background: Rectangle {
                    color: root.color
                    radius: 2
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                QQC2.Label {
                    id: subContents
                    width: parent.width
                    visible: root.subText != null
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: root.subText ? root.subText : ""
                    font.pointSize: 8
                }

                ColumnLayout {
                    width: parent.width
                    anchors.centerIn: parent
                    Layout.alignment: Qt.AlignCenter
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: Kirigami.Units.smallSpacing
                        Layout.leftMargin: Kirigami.Units.largeSpacing
                        Layout.rightMargin: Kirigami.Units.largeSpacing
                        visible: root.channel.trackType == "synth"

                        Repeater {
                            model: root.channel && root.channel.occupiedSynthSlots

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TrackHeaderSlotIndicator {
                                    anchors.centerIn: parent
                                    highlighted: modelData
                                    width: parent.width
                                    height: 2
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: Kirigami.Units.smallSpacing
                        Layout.leftMargin: Kirigami.Units.largeSpacing
                        Layout.rightMargin: Kirigami.Units.largeSpacing
                        visible: root.channel.trackType == "synth"

                        Repeater {
                            model: root.channel && root.channel.occupiedSampleSlots

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TrackHeaderSlotIndicator {
                                    anchors.centerIn: parent
                                    highlighted: modelData
                                    width: parent.width
                                    height: 2
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: Kirigami.Units.smallSpacing
                        Layout.leftMargin: Kirigami.Units.largeSpacing
                        Layout.rightMargin: Kirigami.Units.largeSpacing
                        visible: root.channel.trackType == "synth"

                        Repeater {
                            model: root.channel && root.channel.occupiedFxSlots

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TrackHeaderSlotIndicator {
                                    anchors.centerIn: parent
                                    highlighted: modelData
                                    width: parent.width
                                    height: 2
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: Kirigami.Units.smallSpacing
                        Layout.leftMargin: Kirigami.Units.largeSpacing
                        Layout.rightMargin: Kirigami.Units.largeSpacing
                        visible: root.channel.trackType == "sample-loop"

                        Repeater {
                            model: root.channel && root.channel.occupiedSketchSlots

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TrackHeaderSlotIndicator {
                                    anchors.centerIn: parent
                                    highlighted: modelData
                                    width: parent.width
                                    height: 2
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: Kirigami.Units.smallSpacing
                        Layout.leftMargin: Kirigami.Units.largeSpacing
                        Layout.rightMargin: Kirigami.Units.largeSpacing
                        visible: root.channel.trackType == "sample-loop"

                        Repeater {
                            model: root.channel && root.channel.occupiedSketchFxSlots

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TrackHeaderSlotIndicator {
                                    anchors.centerIn: parent
                                    highlighted: modelData
                                    width: parent.width
                                    height: 2
                                }
                            }
                        }
                    }
                }

                // Hide synth image as this area will now be used to display sounds overview
                // Item {
                //     width: parent.width
                //     height: parent.height
                //     visible: Zynthbox.MidiRouter.sketchpadTrackTargetTracks[root.channel.id] == root.channel.id && root.synthDetailsVisible

                //     Image {
                //         id: synthImage
                //         visible: root.channel.trackType === "synth" &&
                //                  root.channel.occupiedSlotsCount > 0  &&
                //                  synthImage.status !== Image.Error
                //         anchors.fill: parent
                //         fillMode: Image.PreserveAspectCrop
                //         clip: true
                //         opacity: 0.7
                //         property string imageName: String(root.channel.connectedSoundName.split(" > ")[0]).toLowerCase().replace(/ /g, "-")
                //         source: imageName !== "" ? Qt.resolvedUrl("../../../img/synths/" + imageName  + ".png") : ""
                //     }

                //     Image {
                //         visible: (root.channel.trackType === "synth" && synthImage.status === Image.Error && root.channel.occupiedSlotsCount > 0) ||
                //                  root.channel.trackType === "sample-loop"
                //         anchors.fill: parent
                //         fillMode: Image.PreserveAspectCrop
                //         horizontalAlignment: Image.AlignHCenter
                //         verticalAlignment: Image.AlignVCenter
                //         clip: true
                //         opacity: 0.5
                //         source: Qt.resolvedUrl("../../../img/synths/zynth-default.png")
                //     }
                // }

                Item {
                    anchors.fill: parent
                    visible: Zynthbox.MidiRouter.sketchpadTrackTargetTracks[root.channel.id] != root.channel.id
                    QQC2.Label {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: "↪ T%1".arg(Zynthbox.MidiRouter.sketchpadTrackTargetTracks[root.channel.id] + 1)
                    }
                }

                QQC2.Label {
                    id: midiChannelLabel
                    width: parent.width
                    height: parent.height
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pointSize: Kirigami.Units.gridUnit
                    color: Kirigami.Theme.textColor
                    visible: root.channel.trackType === "external"
                    text: root.channel.externalMidiChannel > -1 ? root.channel.externalMidiChannel + 1 : root.channel.id + 1
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: Kirigami.Units.gridUnit * 0.7
                color: "#99888888"

                // QQC2.Label {
                //     id: synthName
                //     anchors.fill: parent
                //     elide: Text.ElideRight
                //     horizontalAlignment: Text.AlignHCenter
                //     verticalAlignment: Text.AlignVCenter
                //     font.pointSize: 8
                //     visible: root.synthDetailsVisible &&
                //              synthName.text &&
                //              synthName.text.length > 0
                //     // text: channel.connectedSoundName.split(" > ")[0]
                //     text: root.channel.trackType === "synth"
                //               ? root.channel.connectedSoundName.split(" > ")[0]
                //               : ""
                // }
            }
        }
    }

    background: Item {
        Rectangle {
            anchors.fill: parent
            visible: !svgBg.visible
            border.width: (root.highlightOnFocus && root.activeFocus) || root.highlighted ? 1 : 0
            border.color: root.highlightColor

            color: Kirigami.Theme.backgroundColor
        }

        PlasmaCore.FrameSvgItem {
            id: svgBg
            visible: fromCurrentTheme && highlighted
            anchors.fill: parent

            property bool highlighted: ((root.highlightOnFocus && root.activeFocus) || root.highlighted)
            readonly property real leftPadding: fixedMargins.left
            readonly property real rightPadding: fixedMargins.right
            readonly property real topPadding: fixedMargins.top
            readonly property real bottomPadding: fixedMargins.bottom

            imagePath: "widgets/column-delegate-background"
            prefix: highlighted ? ["focus", ""] : ""
            colorGroup: PlasmaCore.Theme.ViewColorGroup
        }
    }
}
