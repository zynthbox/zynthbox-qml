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
import org.kde.plasma.core 2.0 as PlasmaCore

import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian

QQC2.Pane {
    id: root

    readonly property QtObject song: zynqtgui.sketchpad.song
    readonly property QtObject selectedChannel: song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId)

    Layout.fillWidth: true
    padding: 0
    background: null //for now it is not themeable

    function cuiaCallback(cuia) {
        switch (cuia) {
        case "SWITCH_BACK_SHORT":
        case "SWITCH_BACK_BOLD":
            bottomStack.slotsBar.channelButton.checked = true
            return true

        case "SWITCH_SELECT_SHORT":
            zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
            zynqtgui.bottomBarControlObj = zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId);

            bottomStack.slotsBar.bottomBarButton.checked = true

            return true;

        case "NAVIGATE_LEFT":
            if (zynqtgui.sketchpad.selectedTrackId > 0) {
                zynqtgui.sketchpad.selectedTrackId -= 1;
            }

            return true;

        case "NAVIGATE_RIGHT":
            if (zynqtgui.sketchpad.selectedTrackId < 9) {
                zynqtgui.sketchpad.selectedTrackId += 1;
            }

            return true;
        case "KNOB0_TOUCHED":
        case "KNOB1_TOUCHED":
            // Eat these two events to stop the OSD from showing up
            return true;
        case "KNOB0_UP":
            applicationWindow().updateSelectedChannelVolume(1, false)
            return true;
        case "KNOB0_DOWN":
            applicationWindow().updateSelectedChannelVolume(-1, false)
            return true;
        case "KNOB1_UP":
            pageManager.getPage("sketchpad").updateSelectedChannelPan(1)
            return true;
        case "KNOB1_DOWN":
            pageManager.getPage("sketchpad").updateSelectedChannelPan(-1)
            return true;
        }
        
        return false;
    }

    QQC2.ButtonGroup {
        buttons: buttonsColumn.children
    }

    contentItem: Item {

        ColumnLayout {
            anchors.fill: parent

            Kirigami.Heading {
                visible: false
                text: qsTr("Mixer : %1").arg(song.name)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                BottomStackTabs {
                    id: buttonsColumn
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 6
                }

                QQC2.Control {
                    id: mixerContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    topPadding: svgBg.topPadding
                    bottomPadding: svgBg.bottomPadding
                    leftPadding: svgBg.leftPadding
                    rightPadding: svgBg.rightPadding

                    background: Item {
                        PlasmaCore.FrameSvgItem {
                            id: svgBg
                            visible: fromCurrentTheme
                            anchors.fill: parent

                            readonly property real leftPadding: fixedMargins.left
                            readonly property real rightPadding: fixedMargins.right
                            readonly property real topPadding: fixedMargins.top
                            readonly property real bottomPadding: fixedMargins.bottom

                            imagePath: "widgets/tracks-background"
                            colorGroup: PlasmaCore.Theme.ViewColorGroup
                        }
                    }

                    contentItem: Item {
                        RowLayout {
                            id: channelsVolumeRow

                            function handleClick(channel) {
                                zynqtgui.sketchpad.selectedTrackId = channel.id;
                                zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                zynqtgui.bottomBarControlObj = zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId);
                            }

                            anchors.fill: parent
                            spacing: 0

                            Repeater {
                                model: root.song.channelsModel

                                delegate: QQC2.Control {
                                    id: mixerColumnDelegate
                                    property bool highlighted: index === zynqtgui.sketchpad.selectedTrackId
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    background: Item {
                                        Kirigami.Separator {
                                            height: parent.height
                                            anchors.left: parent.left
                                            visible: index !== 0
                                            width: 1
                                            color: Qt.darker(Kirigami.Theme.backgroundColor, 1.5)
                                        }
                                        Rectangle
                                        {
                                            visible: !svgBg2.visible
                                            anchors.fill: parent
                                            color: mixerColumnDelegate.highlighted ? "#22ffffff" : "transparent"
                                            border.width: 1
                                            border.color: mixerColumnDelegate.highlighted ? Kirigami.Theme.highlightColor : "transparent"
                                        }

                                        PlasmaCore.FrameSvgItem {
                                            id: svgBg2
                                            visible: fromCurrentTheme && mixerColumnDelegate.highlighted
                                            anchors.fill: parent

                                            readonly property real leftPadding: fixedMargins.left
                                            readonly property real rightPadding: fixedMargins.right
                                            readonly property real topPadding: fixedMargins.top
                                            readonly property real bottomPadding: fixedMargins.bottom

                                            imagePath: "widgets/column-delegate-background"
                                            prefix: mixerColumnDelegate.highlighted ? ["focus", ""] : ""
                                            colorGroup: PlasmaCore.Theme.ViewColorGroup
                                        }
                                    }

                                    contentItem: Item {
                                        ColumnLayout {
                                            anchors.fill: parent
                                            spacing: Kirigami.Units.smallSpacing

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

                                                    anchors.fill: parent

                                                    // Disable when muted or channel is not being played in solo mode
                                                    enabled: (zynqtgui.sketchpad.song.playChannelSolo === -1 && !model.channel.muted) || zynqtgui.sketchpad.song.playChannelSolo === model.channel.id
                                                    headerTextVisible: false
                                                    inputAudioLeveldB: visible && !model.channel.muted
                                                                  ? Zynthbox.AudioLevels.channels[model.channel.id]
                                                                  : -400
                                                    onAudioLeveldBChanged: {
                                                        console.log("Channel audio level changed to", audioLeveldB)
                                                    }
                                                    inputAudioLevelVisible: true

                                                    onValueChanged: {
                                                        model.channel.gainHandler.gainDb = slider.value
                                                    }
                                                    slider {
                                                        from: model.channel.gainHandler.minimumDecibel
                                                        to: model.channel.gainHandler.maximumDecibel
                                                    }

                                                    onClicked: {
                                                        channelsVolumeRow.handleClick(channel);
                                                    }
                                                    onDoubleClicked: {
                                                        model.channel.gainHandler.gainDb = model.channel.initialVolume;
                                                    }

                                                    Binding {
                                                        target: volumeControl.slider
                                                        property: "value"
                                                        value: model.channel.gainHandler.gainDb
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
                                                        elide: Text.ElideRight

                                                        font.pointSize: 8

                                                        Timer {
                                                            id: soundnameUpdater;
                                                            repeat: false; running: false; interval: 1;
                                                            onTriggered: soundLabel.updateSoundName();
                                                        }
                                                        Component.onCompleted: soundLabel.updateSoundName();
                                                        Connections {
                                                            target: zynqtgui.fixed_layers
                                                            onList_updated: soundnameUpdater.restart();
                                                        }

                                                        Connections {
                                                            target: model.channel
                                                            onChainedSoundsChanged: model.channel.trackType === "synth" ? soundnameUpdater.restart() : false
                                                            onSamplesChanged: model.channel.trackType === "synth" ? soundnameUpdater.restart() : false
                                                            onTrackTypeChanged: soundnameUpdater.restart()
                                                            onSceneClipChanged: model.channel.trackType === "sample-loop" ? soundnameUpdater.restart() : false
                                                            onSelectedSlotRowChanged: ["synth", "external"].indexOf(model.channel.trackType) >= 0 ? soundnameUpdater.restart() : false
                                                        }

                                                        Connections {
                                                            target: model.channel.sceneClip
                                                            onPathChanged: model.channel.trackType === "sample-loop" ? soundnameUpdater.restart() : false
                                                        }
                                                        Connections {
                                                            target: root
                                                            onVisibleChanged: root.visible ? soundLabel.updateSoundName() : false
                                                        }

                                                        function updateSoundName() {
                                                            if (root.visible) {
                                                                var text = "";

                                                                if (model.channel.trackType === "synth") {
                                                                    for (var id in model.channel.chainedSounds) {
                                                                        if (model.channel.chainedSounds[id] >= 0 &&
                                                                                model.channel.checkIfLayerExists(model.channel.chainedSounds[id])) {
                                                                            var soundName = zynqtgui.fixed_layers.selector_list.getDisplayValue(model.channel.chainedSounds[id]).split(">");
                                                                            text = qsTr("%1").arg(soundName[1] ? soundName[1].trim() : "")
                                                                            break;
                                                                        }
                                                                    }
                                                                    if (text === "") {
                                                                        try {
                                                                            text = model.channel.samples[model.channel.selectedSlotRow].path.split("/").pop()
                                                                        } catch (e) {}
                                                                    }
                                                                } else if (model.channel.trackType === "sample-loop") {
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
                                                from: -1.0
                                                to: 1.0
                                                controlObj: model.channel
                                                controlProp: "pan"
                                                initialValue: model.channel.initialPan
                                            }

                                            QQC2.Label {
                                                Layout.alignment: Qt.AlignCenter
                                                Layout.fillWidth: true
                                                Layout.fillHeight: false
                                                Layout.margins: 4
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                                text: model.channel.name

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        channelsVolumeRow.handleClick(channel);
                                                    }
                                                }
                                            }

                                            QQC2.Label {
                                                Layout.alignment: Qt.AlignCenter
                                                Layout.fillWidth: true
                                                Layout.fillHeight: false
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                                text: qsTr("%1 dB").arg(model.channel.gainHandler.gainDb.toFixed(2))
                                                font.pointSize: 9

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
                                                    checked: root.song.playChannelSolo === model.channel.id
                                                    text: qsTr("S")
                                                    background: Rectangle {
                                                        radius: parent.radius
                                                        border.width: 1
                                                        border.color: Qt.rgba(50, 50, 50, 0.1)
                                                        color: parent.down || parent.checked ? Kirigami.Theme.positiveBackgroundColor : Qt.lighter(Kirigami.Theme.backgroundColor, 1.3)
                                                    }
                                                    onClicked: {
                                                        if (root.song.playChannelSolo == model.channel.id) {
                                                            root.song.playChannelSolo = -1
                                                        } else {
                                                            root.song.playChannelSolo = model.channel.id
                                                        }
                                                    }
                                                }
                                                QQC2.RoundButton {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    Layout.preferredWidth: (parent.width-parent.spacing)/2
                                                    radius: 2
                                                    font.pointSize: 8
                                                    checked: model.channel.muted
                                                    text: qsTr("M")
                                                    background: Rectangle {
                                                        radius: parent.radius
                                                        border.width: 1
                                                        border.color: Qt.rgba(50, 50, 50, 0.1)
                                                        color: parent.down || parent.checked ? Kirigami.Theme.negativeBackgroundColor : Qt.lighter(Kirigami.Theme.backgroundColor, 1.3)
                                                    }
                                                    onClicked: {
                                                        model.channel.muted = !model.channel.muted
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                QQC2.Control {
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    topPadding: svgBg2.topPadding
                    bottomPadding: svgBg2.bottomPadding
                    leftPadding: svgBg2.leftPadding
                    rightPadding: svgBg2.rightPadding

                    background: Item {

                        PlasmaCore.FrameSvgItem {
                            id: svgBg2
                            visible: fromCurrentTheme
                            anchors.fill: parent

                            readonly property real leftPadding: fixedMargins.left
                            readonly property real rightPadding: fixedMargins.right
                            readonly property real topPadding: fixedMargins.top
                            readonly property real bottomPadding: fixedMargins.bottom

                            imagePath: "widgets/tracks-background"
                            colorGroup: PlasmaCore.Theme.ViewColorGroup
                        }
                    }

                    contentItem: Item {
                        VolumeControl {
                            id: masterVolume
                            anchors.fill: parent
                            headerText: root.visible || Zynthbox.AudioLevels.playback <= -40
                                        ? ""
                                        : (Math.round(Zynthbox.AudioLevels.playback) + " (dB)")

                            footerText: "Master"
                            inputAudioLeveldB: visible ? Zynthbox.AudioLevels.playback :  -400
                            inputAudioLevelVisible: true

                            Binding {
                                target: masterVolume.slider
                                property: "value"
                                value: zynqtgui.masterVolume
                            }

                            slider {
                                value: zynqtgui.masterVolume
                                from: 0
                                to: 100
                                stepSize: 1
                            }
                            onValueChanged: {
                                zynqtgui.masterVolume = masterVolume.slider.value;
                                zynqtgui.sketchpad.song.volume = masterVolume.slider.value;
                            }
                            onDoubleClicked: {
                                zynqtgui.masterVolume = zynqtgui.initialMasterVolume
                            }
                        }
                    }
                }

                // Kirigami.Separator {
                //     Layout.fillHeight: true
                //     Layout.preferredWidth: 1
                //     color: "#ff31363b"
                // }
            }
        }
    }

}
