/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Session Dashboard page for Zynthian GUI

Copyright (C) 2021 Marco Martin <mart@kde.org>
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
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import JuceGraphics 1.0

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick
import "../ZynthiLoops" as ZynthiLoops


QQC2.Dialog {
    id: soundsDialog

    property QtObject selectedTrack: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)
    property var chainedSoundsArr: selectedTrack.chainedSounds.slice()

    modal: true

    x: root.parent ? root.parent.mapFromGlobal(0, 0).x : 0
    y: root.parent ? root.parent.mapFromGlobal(0, Math.round(Screen.height/2 - height/2)).y : 0
    width: Screen.width - Kirigami.Units.gridUnit*2
    height: Screen.height - Kirigami.Units.gridUnit*2

    header: Kirigami.Heading {
        text: qsTr("Pick a sound for %1").arg(soundsDialog.selectedTrack ? soundsDialog.selectedTrack.name : "(no selected track)")
        font.pointSize: 16
        padding: Kirigami.Units.gridUnit
    }

    QQC2.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.2)
    }

    footer: RowLayout {
        QQC2.Button {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            text: qsTr("Un-select all slots")
            onClicked: {
              //  soundsDialog.selectedTrack.connectedSound = -1;
                soundsDialog.selectedTrack.chainedSounds = [-1,-1,-1,-1, -1]
                /*if (soundsDialog.selectedTrack.connectedPattern >= 0) {
                    var seq = ZynQuick.PlayGridManager.getSequenceModel("Global").get(soundsDialog.selectedTrack.connectedPattern);
                    seq.midiChannel = soundsDialog.selectedTrack.connectedSound;
                }*/
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
            id: mainLayout
            rows: 3
            columns: 5
            rowSpacing: Kirigami.Units.gridUnit*2.5
            columnSpacing: rowSpacing

            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.gridUnit
            anchors.rightMargin: Kirigami.Units.gridUnit
            anchors.bottomMargin: Kirigami.Units.gridUnit

            Repeater {
                model: zynthian.fixed_layers.selector_list
                delegate: QQC2.RoundButton {
                    id: soundBtnDelegate

                    property int layerIndex: index
                    property bool hasConnectedTracks: false
/*
                    Kirigami.Theme.highlightColor: {
                        if (soundsDialog.selectedTrack && zynthian.active_midi_channel === index) {
                            return Qt.rgba(
                                Kirigami.Theme.highlightColor.r,
                                Kirigami.Theme.highlightColor.g,
                                Kirigami.Theme.highlightColor.b,
                                1
                            )
                        } else if (soundsDialog.selectedTrack.chainedSounds.indexOf(index) >= 0 &&
                                   soundsDialog.selectedTrack.checkIfLayerExists(index)) {
                            return Qt.rgba(
                                Kirigami.Theme.highlightColor.r,
                                Kirigami.Theme.highlightColor.g,
                                Kirigami.Theme.highlightColor.b,
                                0.3
                            )
                        } else {
                            return Qt.rgba(
                                Kirigami.Theme.highlightColor.r,
                                Kirigami.Theme.highlightColor.g,
                                Kirigami.Theme.highlightColor.b,
                                1
                            )
                        }
                    }*/

                    Layout.fillWidth: false
                    Layout.fillHeight: false
                    Layout.preferredWidth: (parent.width-parent.columnSpacing*(parent.columns-1))/parent.columns
                    Layout.preferredHeight: (parent.height-parent.rowSpacing*(parent.rows-1))/parent.rows
                    text: model.display
                    radius: 4
                    highlighted: soundsDialog.selectedTrack &&
                                 soundsDialog.selectedTrack.chainedSounds.indexOf(index) >= 0 &&
                                 soundsDialog.selectedTrack.checkIfLayerExists(index)

                    background: Rectangle { // Derived from znthian qtquick-controls-style
                        Kirigami.Theme.inherit: true
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: soundBtnDelegate.highlighted
                                ? Kirigami.Theme.highlightColor
                                : Kirigami.Theme.backgroundColor
                        border.color: soundBtnDelegate.hasConnectedTracks
                                        ? Kirigami.Theme.highlightColor
                                        : Qt.rgba(
                                                Kirigami.Theme.textColor.r,
                                                Kirigami.Theme.textColor.g,
                                                Kirigami.Theme.textColor.b,
                                                0.4
                                            )
                        radius: soundBtnDelegate.radius

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            gradient: Gradient {
                                GradientStop { position: 0; color: soundBtnDelegate.pressed ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.05)}
                                GradientStop { position: 1; color: soundBtnDelegate.pressed ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.05)}
                            }
                        }
                    }
                    onClicked: {
                        soundsDialog.close();

                        soundsDialog.selectedTrack.selectSound(index);

                        if (soundsDialog.selectedTrack.connectedPattern >= 0) {
                            var seq = ZynQuick.PlayGridManager.getSequenceModel("Global").get(soundsDialog.selectedTrack.connectedPattern);
                            seq.midiChannel = soundsDialog.selectedTrack.connectedSound;
                        }

                        zynthian.fixed_layers.activate_index(index);
                    }

                    // Reset hasConnectedTracks on dialog close
                    Connections {
                        target: soundsDialog
                        onVisibleChanged: {
                            if (!visible) {
                                soundBtnDelegate.hasConnectedTracks = false;
                            }
                        }
                    }

                    QQC2.Label {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: Kirigami.Units.gridUnit*0.5
                        font.pointSize: 10
                        text: (index + 1)
                    }

                    RowLayout {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: Kirigami.Units.gridUnit*0.5

                        Repeater {
                            model: zynthian.zynthiloops.song.tracksModel
                            delegate: QQC2.Label {
                                font.pointSize: 10
                                text: model.track.name
                                visible: model.track.connectedSound === layerIndex
                                onVisibleChanged: {
                                    if (visible) {
                                        soundBtnDelegate.hasConnectedTracks = true;
                                    }
                                }
                            }
                        }
                    }

                    // Disable Chaining
                    /*Kirigami.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.right
                        anchors.leftMargin: Kirigami.Units.gridUnit*0.5
                        anchors.rightMargin: Kirigami.Units.gridUnit*0.5
                        width: Kirigami.Units.gridUnit*1.5
                        height: width

                        source: "link"
                        color: Kirigami.Theme.textColor
                        visible: (index+1)%5 !== 0
                        opacity: model.metadata.midi_cloned || (index >= 5 && index <= 9)? 1 : 0.4

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!(index >= 5 && index <= 9)) {
                                    console.log("Toggle layer chaining")
                                    Zynthian.CommonUtils.toggleLayerChaining(model);
                                }
                            }
                        }
                    }*/
                }
            }
        }
    }
}
