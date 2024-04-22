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


import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox
import "../Sketchpad" as Sketchpad


Zynthian.Dialog {
    id: soundsDialog

    /* Disable Sounds Dialog as it is not used anymore

    property QtObject selectedChannel: zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.session_dashboard.selectedChannel)
    property var chainedSoundsArr: selectedChannel ? selectedChannel.chainedSounds.slice() : []
//     property var chainColors: ({
//         t1: "#e6194B",
//         t2: "#3cb44b",
//         t3: "#ffe119",
//         t4: "#4363d8",
//         t5: "#f58231",
//         t6: "#911eb4",
//         t7: "#42d4f4",
//         t8: "#f032e6",
//         t9: "#fabed4",
//         t10: "#9A6324",
//         t11: "#800000",
//         t12: "#fffac8"
//     })
    property var availableChainColors: [
        "#e6194B",
        "#3cb44b",
        "#ffe119",
        "#4363d8",
        "#f5f231",
        "#911eb4",
        "#42d4f4",
        "#f032e6",
        "#fabed4",
        "#9A6324",
        "#800000",
        "#0ffac8",
        "#0abed4",
        "#2A6324",
        "#00f000",
        "#0ffac8"
    ]

    property var chainColors: {}

    onVisibleChanged: {
        if (!visible) {
            return;
        }
        chainColors = {"black": "black"};
        for (var i = 0; i < 16; ++i) {

            chainColors[zynqtgui.layer.printableChainForLayer(i)] = availableChainColors[i];
            print("DDDDD"+i+" "+zynqtgui.layer.printableChainForLayer(i)+ availableChainColors[i])
        }

    }

    modal: true

    x: root.parent ? root.parent.mapFromGlobal(0, 0).x : 0
    y: root.parent ? root.parent.mapFromGlobal(0, Math.round(Screen.height/2 - height/2)).y : 0
    width: Screen.width - Kirigami.Units.gridUnit*2
    height: Screen.height - Kirigami.Units.gridUnit*2

    header: Kirigami.Heading {
        text: qsTr("Pick a sound for %1").arg(soundsDialog.selectedChannel ? soundsDialog.selectedChannel.name : "(no selected channel)")
        font.pointSize: 16
        padding: Kirigami.Units.gridUnit
    }

    QQC2.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.2)
    }

    onAccepted: {
        applicationWindow().soundsDialogAccepted();
    }
    onRejected: {
        applicationWindow().soundsDialogRejected();
    }

    footer: RowLayout {
        QQC2.Button {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            text: qsTr("Un-select all slots")
            onClicked: {
              //  soundsDialog.selectedChannel.connectedSound = -1;
//                soundsDialog.selectedChannel.chainedSounds = [-1,-1,-1,-1, -1]
                soundsDialog.selectedChannel.clearChainedSoundsWithoutCloning();
                soundsDialog.accept();
            }
        }
        QQC2.Button {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            text: qsTr("Close")
            onClicked: soundsDialog.reject();
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
                model: zynqtgui.fixed_layers.selector_list
                delegate: QQC2.RoundButton {
                    id: soundBtnDelegate

                    property int layerIndex: index
                    property bool hasConnectedChannels: false
                    property bool isChained: false
                    property bool hasChannel: false
                    property color borderColor: Qt.rgba(
                                                    Kirigami.Theme.textColor.r,
                                                    Kirigami.Theme.textColor.g,
                                                    Kirigami.Theme.textColor.b,
                                                    0.1
                                                )

                    Layout.fillWidth: false
                    Layout.fillHeight: false
                    Layout.preferredWidth: (parent.width-parent.columnSpacing*(parent.columns-1))/parent.columns
                    Layout.preferredHeight: (parent.height-parent.rowSpacing*(parent.rows-1))/parent.rows
                    radius: 4
                    highlighted: soundsDialog.selectedChannel &&
                                 soundsDialog.selectedChannel.chainedSounds.indexOf(index) >= 0 &&
                                 soundsDialog.selectedChannel.checkIfLayerExists(index)

                    enabled: (!highlighted && !isChained) || !hasChannel

                    background: Rectangle { // Derived from znthian qtquick-controls-style
                        Kirigami.Theme.highlightColor: {
                            if (soundsDialog.selectedChannel && zynqtgui.active_midi_channel === index) {
                                return Qt.rgba(
                                    soundBtnDelegate.borderColor.r,
                                    soundBtnDelegate.borderColor.g,
                                    soundBtnDelegate.borderColor.b,
                                    enabled ? 1 : 0.5
                                )
                            } else if (soundsDialog.selectedChannel && soundsDialog.selectedChannel.chainedSounds.indexOf(index) >= 0 &&
                                       soundsDialog.selectedChannel.checkIfLayerExists(index)) {
                                return Qt.rgba(
                                    soundBtnDelegate.borderColor.r,
                                    soundBtnDelegate.borderColor.g,
                                    soundBtnDelegate.borderColor.b,
                                    0.3
                                )
                            } else {
                                return Qt.rgba(
                                    soundBtnDelegate.borderColor.r,
                                    soundBtnDelegate.borderColor.g,
                                    soundBtnDelegate.borderColor.b,
                                    1
                                )
                            }
                        }

                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: soundBtnDelegate.highlighted
                                ? Kirigami.Theme.highlightColor
                                : soundBtnDelegate.hasChannel
                                  ? Kirigami.Theme.backgroundColor
                                  : "#000000"
                        border.width: 2
                        border.color: soundBtnDelegate.hasChannel
                                          ? Qt.rgba(
                                              soundBtnDelegate.borderColor.r,
                                              soundBtnDelegate.borderColor.g,
                                              soundBtnDelegate.borderColor.b,
                                              0.7
                                            )
                                          : Qt.rgba(
                                                soundBtnDelegate.borderColor.r,
                                                soundBtnDelegate.borderColor.g,
                                                soundBtnDelegate.borderColor.b,
                                                0.3
                                            )
                        radius: soundBtnDelegate.radius

                        Connections {
                            target: soundsDialog
                            onVisibleChanged: {
                                if (!visible) {
                                    // Reset to base border color on dialog close
                                    soundBtnDelegate.borderColor = Qt.rgba(
                                        Kirigami.Theme.textColor.r,
                                        Kirigami.Theme.textColor.g,
                                        Kirigami.Theme.textColor.b,
                                        0.1
                                    );
                                    soundBtnDelegate.isChained = false;
                                    soundBtnDelegate.hasChannel = false;
                                } else {
                                    borderColorTimer.restart();
                                }
                            }
                        }

                        Timer {
                            id: borderColorTimer
                            repeat: false
                            interval: 50
                            running: true
                            onTriggered: {
//                                for (var j in selectedChannel.chainedSounds) {
//                                    if (soundBtnDelegate.layerIndex === selectedChannel.chainedSounds[j] &&
//                                        soundsDialog.selectedChannel.checkIfLayerExists(soundBtnDelegate.layerIndex)) {
//                                        soundBtnDelegate.borderColor = soundsDialog.chainColors[zynqtgui.layer.printableChainForLayer(i)]
//                                        soundBtnDelegate.isChained = true;
//                                        console.log((index+1)+" chained to Selected Channel T"+(selectedChannel.id+1), soundBtnDelegate.borderColor)

//                                        // Return if sound is found in selected channel
//                                        return;
//                                    }
//                                }

                                for (var i=0; i<zynqtgui.sketchpad.song.channelsModel.count; i++) {
                                    var found = false;
                                    var channel = zynqtgui.sketchpad.song.channelsModel.getChannel(i);
                                    var chains = zynqtgui.layer.chainForLayer(i);

                                    // console.log("Track T"+(parseInt(k)+1))

                                    for (var k in channel.chainedSounds) {
                                        // console.log("Comparing layer and chained sounds ---- layerIndex:", soundBtnDelegate.layerIndex, ", Chained Sounds :", channel.chainedSounds[parseInt(k)], ", printableChain :", chains, " chains index :", chains.indexOf(soundBtnDelegate.layerIndex));

                                        if (soundsDialog.selectedChannel && soundsDialog.selectedChannel.checkIfLayerExists(soundBtnDelegate.layerIndex) && soundBtnDelegate.layerIndex === channel.chainedSounds[k]) {
                                            found = true
                                            console.log((index+1)+" chained to T"+(i+1))
//                                            console.log("  > Setting color : "+chainColors["t"+(i+1)]);
                                            soundBtnDelegate.borderColor = soundsDialog.chainColors[zynqtgui.layer.printableChainForLayer(i)]
                                            soundBtnDelegate.isChained = true;
                                            soundBtnDelegate.hasChannel = true;
                                        }
                                    }

                                    // Break out of loop when first connected channel is found
                                    if (found) {
                                        break;
                                    } else if ((chains.length > 1 && chains.indexOf(soundBtnDelegate.layerIndex) >= 0)) {
                                        soundBtnDelegate.borderColor = soundsDialog.chainColors[zynqtgui.layer.printableChainForLayer(i)]
                                        soundBtnDelegate.isChained = true;
                                        soundBtnDelegate.hasChannel = false;
                                    }
                                }
                            }
                        }

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
                        soundsDialog.accept();

                        soundsDialog.selectedChannel.selectSound(index);

                        zynqtgui.fixed_layers.activate_index(index);

                        if (!soundsDialog.selectedChannel.checkIfLayerExists(index)) {
                            applicationWindow().requestOpenLayerSetupDialog();
                        }
                    }

                    // Reset hasConnectedChannels on dialog close
                    Connections {
                        target: soundsDialog
                        onVisibleChanged: {
                            if (!visible) {
                                soundBtnDelegate.hasConnectedChannels = false;
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

                    QQC2.Label {
                        anchors.centerIn: parent
                        width: parent.width
                        horizontalAlignment: "AlignHCenter"
                        verticalAlignment: "AlignVCenter"
                        elide: "ElideRight"
                        color: enabled
                                ? Kirigami.Theme.textColor
                                : Qt.rgba(
                                      Kirigami.Theme.textColor.r,
                                      Kirigami.Theme.textColor.g,
                                      Kirigami.Theme.textColor.b,
                                      0.6
                                  )
                        text: model.display
                    }

                    RowLayout {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: Kirigami.Units.gridUnit*0.5

                        Repeater {
                            model: zynqtgui.sketchpad.song.channelsModel
                            delegate: QQC2.Label {
                                font.pointSize: 10
                                text: model.channel.name
                                visible: model.channel.connectedSound === layerIndex
                                onVisibleChanged: {
                                    if (visible) {
                                        soundBtnDelegate.hasConnectedChannels = true;
                                    }
                                }
                            }
                        }
                    }

                    // Disable Chaining
//                    Kirigami.Icon {
//                        anchors.verticalCenter: parent.verticalCenter
//                        anchors.left: parent.right
//                        anchors.leftMargin: Kirigami.Units.gridUnit*0.5
//                        anchors.rightMargin: Kirigami.Units.gridUnit*0.5
//                        width: Kirigami.Units.gridUnit*1.5
//                        height: width

//                        source: "link"
//                        color: Kirigami.Theme.textColor
//                        visible: (index+1)%5 !== 0
//                        opacity: model.metadata.midi_cloned || (index >= 5 && index <= 9)? 1 : 0.4

//                        MouseArea {
//                            anchors.fill: parent
//                            onClicked: {
//                                if (!(index >= 5 && index <= 9)) {
//                                    console.log("Toggle layer chaining")
//                                    Zynthian.CommonUtils.toggleLayerChaining(model);
//                                }
//                            }
//                        }
//                    }
                }
            }
        }
    }

    */
}
