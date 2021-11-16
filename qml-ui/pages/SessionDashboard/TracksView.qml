/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Session Dashboard page for Zynthian GUI

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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

ColumnLayout {
    id: root

    anchors {
        fill: parent
        topMargin: -Kirigami.Units.smallSpacing
        leftMargin: Kirigami.Units.gridUnit
    }

    property int itemHeight: layersView.height / 15
    property QtObject selectedTrack
    spacing: Kirigami.Units.largeSpacing

    RowLayout {
        spacing: Kirigami.Units.gridUnit * 2

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 4
            color: Kirigami.Theme.backgroundColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.gridUnit*0.5
                spacing: 0

                Repeater {
                    model: zynthian.zynthiloops.song.tracksModel
                    delegate: Rectangle {
                        property QtObject track: model.track
                        property QtObject selectedClip: track.clipsModel.getClip(0)

                        id: trackDelegate

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        visible: index < 6
                        border.width: root.selectedTrack === track ? 1 : 0
                        border.color: Kirigami.Theme.highlightColor
                        color: "transparent"
                        radius: 4

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.selectedTrack = track;
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            QQC2.Label {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit*2
                                Layout.leftMargin: Kirigami.Units.gridUnit*0.5
                                Layout.alignment: Qt.AlignVCenter
                                text: (index+1) + "."
                            }
                            Item {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit*4
                                Layout.alignment: Qt.AlignHCenter
                                Layout.rightMargin: Kirigami.Units.gridUnit

                                QQC2.Label {
                                    anchors.centerIn: parent
                                    elide: "ElideRight"
                                    text: model.display
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: false
                                Layout.fillHeight: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit*12
                                Layout.preferredHeight: Kirigami.Units.gridUnit*2
                                Layout.rightMargin: Kirigami.Units.gridUnit
                                Layout.alignment: Qt.AlignVCenter

                                color: Kirigami.Theme.buttonBackgroundColor

                                border.color: "#ff999999"
                                border.width: 1
                                radius: 4

                                QQC2.Label {
                                    width: parent.width
                                    anchors.centerIn: parent
                                    anchors.leftMargin: Kirigami.Units.gridUnit*0.5
                                    anchors.rightMargin: Kirigami.Units.gridUnit*0.5
                                    horizontalAlignment: Text.AlignLeft
                                    text: track.connectedSound >= 0 ? (track.connectedSound+1) + ". "+ zynthian.fixed_layers.selector_list.getDisplayValue(track.connectedSound) : ""
                                    elide: "ElideRight"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        root.selectedTrack = track;
                                        soundsDialog.open();
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: false
                                Layout.fillHeight: false
                                Layout.alignment: Qt.AlignVCenter

                                Repeater {
                                    model: track.clipsModel
                                    delegate: QQC2.RoundButton {
                                        Layout.fillWidth: false
                                        Layout.fillHeight: false
                                        Layout.preferredWidth: Kirigami.Units.gridUnit*1.5
                                        Layout.preferredHeight: Kirigami.Units.gridUnit*1.5
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: 4
                                        highlighted: trackDelegate.selectedClip == model.clip

                                        onClicked: {
                                            root.selectedTrack = track;
                                            trackDelegate.selectedClip = model.clip;
                                        }

                                        QQC2.Label {
                                            anchors.centerIn: parent
                                            text: model.clip.partName
                                        }
                                    }
                                }
                            }
                            Item {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit*4
                                Layout.alignment: Qt.AlignHCenter
                                Layout.leftMargin: Kirigami.Units.gridUnit
                                Layout.rightMargin: Kirigami.Units.gridUnit

                                QQC2.RoundButton {
                                    width: Kirigami.Units.gridUnit*2
                                    height: Kirigami.Units.gridUnit*2

                                    anchors.centerIn: parent
                                    enabled: root.selectedTrack === track
                                    radius: 2

                                    onClicked: {
                                        if (!trackDelegate.selectedClip.isRecording) {
                                            trackDelegate.selectedClip.queueRecording("internal", "");
                                        } else {
                                            trackDelegate.selectedClip.stopRecording();
                                        }
                                    }

                                    Kirigami.Icon {
                                        width: Kirigami.Units.gridUnit
                                        height: Kirigami.Units.gridUnit
                                        anchors.centerIn: parent
                                        source: trackDelegate.selectedClip.isRecording ? "media-playback-stop" : "media-record-symbolic"
                                        color: root.selectedTrack === track && !trackDelegate.selectedClip.isRecording ? "#f44336" : "white"
                                        opacity: root.selectedTrack === track ? 1 : 0.6
                                    }
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }
                }
            }
        }
    }

    QQC2.Dialog {
        id: soundsDialog
        modal: true

        x: root.parent.mapFromGlobal(0, 0).x
        y: root.parent.mapFromGlobal(0, Math.round(Screen.height/2 - height/2)).y
        width: Screen.width - Kirigami.Units.gridUnit*2
        height: Screen.height - Kirigami.Units.gridUnit*2

        header: Kirigami.Heading {
            text: qsTr("Pick a sound for %1").arg(root.selectedTrack.name)
            font.pointSize: 16
            padding: Kirigami.Units.gridUnit
        }

        footer: RowLayout {
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: qsTr("Clear Selection")
                onClicked: {
                    root.selectedTrack.connectedSound = -1;
                    soundsDialog.close();
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: qsTr("Close")
                onClicked: soundsDialog.close();
            }
        }

        contentItem: Item {
            GridLayout {
                rows: 3
                columns: 5
                rowSpacing: Kirigami.Units.gridUnit*0.5
                columnSpacing: rowSpacing

                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.gridUnit
                anchors.rightMargin: Kirigami.Units.gridUnit
                anchors.bottomMargin: Kirigami.Units.gridUnit

                Repeater {
                    model: zynthian.fixed_layers.selector_list
                    delegate: QQC2.Button {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: (parent.width-parent.columnSpacing*(parent.columns-1))/parent.columns
                        Layout.preferredHeight: (parent.height-parent.rowSpacing*(parent.rows-1))/parent.rows
                        text: model.display
                        onClicked: {
                            root.selectedTrack.connectedSound = index;
                            soundsDialog.close();
                        }
                    }
                }
            }
        }
    }
}
