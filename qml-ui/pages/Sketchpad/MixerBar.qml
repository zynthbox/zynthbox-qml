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
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls.Styles 1.4

import libzl 1.0 as ZL
import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

Rectangle {
    id: root

    readonly property QtObject song: zynthian.sketchpad.song
    readonly property QtObject selectedChannel: song.channelsModel.getChannel(zynthian.session_dashboard.selectedChannel)

    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_SELECT_SHORT":
                bottomBar.controlType = BottomBar.ControlType.Channel;
                bottomBar.controlObj = zynthian.sketchpad.song.channelsModel.getChannel(zynthian.session_dashboard.selectedChannel);

                bottomStack.slotsBar.bottomBarButton.checked = true

                return true;

            case "NAVIGATE_LEFT":
                if (zynthian.session_dashboard.selectedChannel > 0) {
                    zynthian.session_dashboard.selectedChannel -= 1;
                }

                return true;

            case "NAVIGATE_RIGHT":
                if (zynthian.session_dashboard.selectedChannel < 9) {
                    zynthian.session_dashboard.selectedChannel += 1;
                }

                return true;
        }
        
        return false;
    }

    GridLayout {
        rows: 1
        anchors.fill: parent

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true

            Kirigami.Heading {
                visible: false
                text: qsTr("Mixer : %1").arg(song.name)
            }

            ColumnLayout {
                id: tableLayout

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
                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 6
                    }

                    Kirigami.Separator {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: "#ff31363b"
                    }

                    RowLayout {
                        id: channelsVolumeRow

                        function handleClick(channel) {
                            if (zynthian.session_dashboard.selectedChannel !== channel.id) {
                                zynthian.session_dashboard.disableNextSoundSwitchTimer();
                                zynthian.session_dashboard.selectedChannel = channel.id;
                                bottomBar.controlType = BottomBar.ControlType.Channel;
                                bottomBar.controlObj = zynthian.sketchpad.song.channelsModel.getChannel(zynthian.session_dashboard.selectedChannel);
                            } else {
                                bottomBar.controlType = BottomBar.ControlType.Channel;
                                bottomBar.controlObj = zynthian.sketchpad.song.channelsModel.getChannel(zynthian.session_dashboard.selectedChannel);

                                bottomStack.currentIndex = 0
                            }
                        }

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 1

                        Repeater {
                            model: root.song.channelsModel

                            delegate: Rectangle {
                                property bool highlighted: index === zynthian.session_dashboard.selectedChannel
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: highlighted ? "#22ffffff" : "transparent"
                                radius: 2
                                border.width: 1
                                border.color: highlighted ? Kirigami.Theme.highlightColor : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.topMargin: 4
                                    spacing: 0

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 0

                                        Item {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    channelsVolumeRow.handleClick(channel);
                                                }
                                            }

                                            VolumeControl {
                                                id: volumeControl

                                                property var audioLevelText: model.channel.audioLevel.toFixed(2)
                                                property QtObject sampleClipObject: ZynQuick.PlayGridManager.getClipById(model.channel.samples[model.channel.selectedSlotRow].cppObjId);
                                                property real synthAudioLevel

                                                anchors.fill: parent

                                                enabled: !model.channel.muted
                                                headerText: model.channel.muted || model.channel.audioLevel <= -40 ? "" : (audioLevelText + " (dB)")
            //                                    footerText: model.channel.name
                                                audioLeveldB: visible
                                                                ? !model.channel.muted
                                                                    ? model.channel.channelAudioType === "sample-loop"
                                                                        ? ZL.AudioLevels.add(model.channel.audioLevel, synthAudioLevel)
                                                                        : model.channel.channelAudioType === "synth"
                                                                            ? synthAudioLevel
                                                                            : model.channel.channelAudioType === "sample-trig" ||
                                                                                model.channel.channelAudioType === "sample-slice"
                                                                                ? sampleClipObject
                                                                                    ? sampleClipObject.audioLevel
                                                                                    : -400
                                                                                : -400
                                                                    : -400
                                                                : -400
                                                inputAudioLevelVisible: false

                                                onValueChanged: {
                                                     model.channel.volume = slider.value
                                                }

                                                onClicked: {
                                                    channelsVolumeRow.handleClick(channel);
                                                }
                                                onDoubleClicked: {
                                                    model.channel.volume = model.channel.initialVolume;
                                                }

                                                Binding {
                                                    target: volumeControl.slider
                                                    property: "value"
                                                    value: model.channel.volume
                                                }
                                                Binding {
                                                    target: volumeControl
                                                    property: "synthAudioLevel"
                                                    value: root.visible ? ZL.AudioLevels.channels[model.channel.id] : -400
                                                }
                                            }

                                            Rectangle {
                                                width: volumeControl.slider.height
                                                height: soundLabel.height*1.5

                                                anchors.left: parent.right
                                                anchors.bottom: parent.bottom
                                                anchors.leftMargin: -soundLabel.height*2
                                                anchors.bottomMargin: -(soundLabel.height/2)

                                                transform: Rotation {
                                                    origin.x: 0
                                                    origin.y: 0
                                                    angle: -90
                                                }

                                                Kirigami.Theme.inherit: false
                                                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                                color: "transparent"

                                                border.color: "transparent"
                                                border.width: 1
                                                radius: 4

                                                QQC2.Label {
                                                    id: soundLabel

                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
        //                                            anchors.leftMargin: Kirigami.Units.gridUnit*0.5
        //                                            anchors.rightMargin: Kirigami.Units.gridUnit*0.5
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    elide: "ElideRight"

                                                    font.pointSize: 8

                                                    Timer {
                                                        id: soundnameUpdater;
                                                        repeat: false; running: false; interval: 1;
                                                        onTriggered: soundLabel.updateSoundName();
                                                    }
                                                    Component.onCompleted: soundLabel.updateSoundName();
                                                    Connections {
                                                        target: zynthian.fixed_layers
                                                        onList_updated: soundnameUpdater.restart();
                                                    }

                                                    Connections {
                                                        target: model.channel
                                                        onChainedSoundsChanged: model.channel.channelAudioType === "synth" ? soundnameUpdater.restart() : false
                                                        onSamplesChanged: ["sample-trig", "sample-slice"].indexOf(model.channel.channelAudioType) >= 0 ? soundnameUpdater.restart() : false
                                                        onChannelAudioTypeChanged: soundnameUpdater.restart()
                                                        onSceneClipChanged: model.channel.channelAudioType === "sample-loop" ? soundnameUpdater.restart() : false
                                                        onSelectedSlotRowChanged: ["sample-trig", "sample-slice", "external"].indexOf(model.channel.channelAudioType) >= 0 ? soundnameUpdater.restart() : false
                                                    }

                                                    Connections {
                                                        target: model.channel.sceneClip
                                                        onPathChanged: model.channel.channelAudioType === "sample-loop" ? soundnameUpdater.restart() : false
                                                    }
                                                    Connections {
                                                        target: root
                                                        onVisibleChanged: root.visible ? soundLabel.updateSoundName() : false
                                                    }

                                                    function updateSoundName() {
                                                        if (root.visible) {
                                                            var text = "";

                                                            if (model.channel.channelAudioType === "synth") {
                                                                for (var id in model.channel.chainedSounds) {
                                                                    if (model.channel.chainedSounds[id] >= 0 &&
                                                                        model.channel.checkIfLayerExists(model.channel.chainedSounds[id])) {
                                                                        var soundName = zynthian.fixed_layers.selector_list.getDisplayValue(model.channel.chainedSounds[id]).split(">");
                                                                        text = qsTr("%1").arg(soundName[1] ? soundName[1].trim() : "")
                                                                        break;
                                                                    }
                                                                }
                                                            } else if (model.channel.channelAudioType === "sample-trig" ||
                                                                    model.channel.channelAudioType === "sample-slice") {
                                                                try {
                                                                    text = model.channel.samples[model.channel.selectedSlotRow].path.split("/").pop()
                                                                } catch (e) {}
                                                            } else if (model.channel.channelAudioType === "sample-loop") {
                                                                try {
                                                                    text = model.channel.sceneClip.path.split("/").pop()
                                                                } catch (e) {}
                                                            }

                                                            soundLabel.text = text;
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Zynthian.ResetableSlider {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: false
                                            Layout.preferredHeight: Kirigami.Units.gridUnit
                                            orientation: Qt.Horizontal
                                            from: 1.0
                                            to: -1.0
                                            controlObj: model.channel
                                            controlProp: "pan"
                                            initialValue: model.channel.initialPan
                                        }

                                        QQC2.Label {
                                            Layout.alignment: Qt.AlignCenter
                                            Layout.fillWidth: true
                                            Layout.fillHeight: false
                                            Layout.margins: 4
                                            horizontalAlignment: "AlignHCenter"
                                            elide: "ElideRight"
                                            text: model.channel.name

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    channelsVolumeRow.handleClick(channel);
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: false
                                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                                            Layout.margins: 4
                                            spacing: 2

                                            QQC2.RoundButton {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Layout.preferredWidth: (parent.width-parent.spacing)/2
                                                radius: 2
                                                font.pointSize: 8
                                                checkable: true
                                                checked: root.song.playChannelSolo === model.channel.id
                                                text: qsTr("S")
                                                background: Rectangle {
                                                    radius: parent.radius
                                                    border.width: 1
                                                    border.color: Qt.rgba(50, 50, 50, 0.1)
                                                    color: parent.down || parent.checked ? "#4caf50" : Qt.lighter(Kirigami.Theme.backgroundColor, 1.3)
                                                }
                                                onToggled: {
                                                    if (checked) {
                                                        root.song.playChannelSolo = model.channel.id
                                                    } else {
                                                        root.song.playChannelSolo = -1
                                                    }
                                                }
                                            }
                                            QQC2.RoundButton {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Layout.preferredWidth: (parent.width-parent.spacing)/2
                                                radius: 2
                                                font.pointSize: 8
                                                checkable: true
                                                text: qsTr("M")
                                                background: Rectangle {
                                                    radius: parent.radius
                                                    border.width: 1
                                                    border.color: Qt.rgba(50, 50, 50, 0.1)
                                                    color: parent.down || parent.checked ? "#f44336" : Qt.lighter(Kirigami.Theme.backgroundColor, 1.3)
                                                }
                                                onCheckedChanged: {
                                                    model.channel.muted = checked;
                                                }
                                            }
                                        }
                                    }

                                    Kirigami.Separator {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: 1
                                        color: "#ff31363b"
                                        visible: index != root.song.channelsModel.count-1 && !highlighted
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 6

                        VolumeControl {
                            id: masterVolume
                            width: Kirigami.Units.gridUnit * 3
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            headerText: root.visible
                                            ? zynthian.sketchpad.masterAudioLevel <= -40
                                                ? ""
                                                : (zynthian.sketchpad.masterAudioLevel.toFixed(2) + " (dB)")
                                            : ""
                            footerText: "Master"
                            audioLeveldB: visible ? zynthian.sketchpad.masterAudioLevel :  -400
                            inputAudioLevelVisible: false

                            Binding {
                                target: masterVolume.slider
                                property: "value"
                                value: zynthian.master_alsa_mixer.volume
                            }

                            slider {
                                value: zynthian.master_alsa_mixer.volume
                                from: 0
                                to: 100
                                stepSize: 1
                            }
                            onValueChanged: {
                                zynthian.master_alsa_mixer.volume = masterVolume.slider.value;
                                zynthian.sketchpad.song.volume = masterVolume.slider.value;
                            }
                            onDoubleClicked: {
                                zynthian.master_alsa_mixer.volume = zynthian.master_alsa_mixer.initialVolume
                            }
                        }
                    }

                    Kirigami.Separator {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: "#ff31363b"
                    }
                }
            }
        }
    }
}
