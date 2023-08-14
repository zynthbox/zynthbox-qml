/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian slots bar page

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
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls.Styles 1.4

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Rectangle {
    id: root

    readonly property QtObject song: zynqtgui.sketchpad.song
    property QtObject selectedChannel: null
    Timer {
        id: selectedChannelThrottle
        interval: 1; running: false; repeat: false;
        onTriggered: {
            root.selectedChannel = applicationWindow().selectedChannel;
            // Focus a slot when a clip/channel/slot is not already focussed
            if (zynqtgui.sketchpad.lastSelectedObj.className != "sketchpad_channel" &&
                    zynqtgui.sketchpad.lastSelectedObj.className != "sketchpad_clip" &&
                    zynqtgui.sketchpad.lastSelectedObj.className != "MixedChannelsViewBar_slot" &&
                    zynqtgui.sketchpad.lastSelectedObj.className != "MixedChannelsViewBar_fxslot" ) {
                synthRepeater.itemAt(0).switchToThisSlot(true)
            }
        }
    }
    Connections {
        target: applicationWindow()
        onSelectedChannelChanged: selectedChannelThrottle.restart()
    }
    Component.onCompleted: {
        selectedChannelThrottle.restart()
    }

    property QtObject sequence: root.selectedChannel ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName) : null
    property QtObject pattern: root.sequence && root.selectedChannel ? root.sequence.getByPart(root.selectedChannel.id, root.selectedChannel.selectedPart) : null


    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    function cuiaCallback(cuia) {
        var returnValue = false;
        console.log(`MixedChannelsViewBar : cuia: ${cuia}, altButtonPressed: ${zynqtgui.altButtonPressed}, modeButtonPressed: ${zynqtgui.modeButtonPressed}`)
        switch (cuia) {
            case "NAVIGATE_LEFT":
                if (zynqtgui.session_dashboard.selectedChannel > 0) {
                    zynqtgui.session_dashboard.selectedChannel -= 1;
                }
                returnValue = true;
                break;

            case "NAVIGATE_RIGHT":
                if (zynqtgui.session_dashboard.selectedChannel < 9) {
                    zynqtgui.session_dashboard.selectedChannel += 1;
                }
                returnValue = true;
                break;

            case "SELECT_UP":
                if (root.selectedChannel.channelAudioType === "sample-trig") {
                    if (root.selectedChannel.selectedSlotRow > 0) {
                        root.selectedChannel.selectedSlotRow -= 1;
                    }
                    returnValue = true;
                }
                break;

            case "SELECT_DOWN":
                if (root.selectedChannel.channelAudioType === "sample-trig") {
                    if (root.selectedChannel.selectedSlotRow < 4) {
                        root.selectedChannel.selectedSlotRow += 1;
                    }
                    returnValue = true;
                }
                break;
            case "KNOB0_UP":
                if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    if (root.selectedChannel.channelAudioType == "synth") {
                        pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[zynqtgui.sketchpad.lastSelectedObj.value], 1)
                    } else if (["sample-trig", "sample-slice"].indexOf(root.selectedChannel.channelAudioType) >= 0) {
                        pageManager.getPage("sketchpad").updateSelectedSampleGain(1, zynqtgui.sketchpad.lastSelectedObj.value)
                    } else if (root.selectedChannel.channelAudioType == "sample-loop") {
                        pageManager.getPage("sketchpad").updateSelectedSketchGain(1, zynqtgui.sketchpad.lastSelectedObj.value)
                    }
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    pageManager.getPage("sketchpad").updateSelectedFxLayerVolume(1, zynqtgui.sketchpad.lastSelectedObj.value)
                    returnValue = true;
                }
                break;
            case "KNOB0_DOWN":
                if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    if (root.selectedChannel.channelAudioType == "synth") {
                        pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[zynqtgui.sketchpad.lastSelectedObj.value], -1)
                    } else if (["sample-trig", "sample-slice"].indexOf(root.selectedChannel.channelAudioType) >= 0) {
                        pageManager.getPage("sketchpad").updateSelectedSampleGain(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                    } else if (root.selectedChannel.channelAudioType == "sample-loop") {
                        pageManager.getPage("sketchpad").updateSelectedSketchGain(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                    }
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    pageManager.getPage("sketchpad").updateSelectedFxLayerVolume(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                    returnValue = true;
                }
                break;
            case "KNOB1_UP":
                if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    if (root.selectedChannel.channelAudioType == "synth") {
                        pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(1, zynqtgui.sketchpad.lastSelectedObj.value)
                    }
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    // Do nothing
                    returnValue = true;
                }
                break;
            case "KNOB1_DOWN":
                if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    if (root.selectedChannel.channelAudioType == "synth") {
                        pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                    }
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    // Do nothing
                    returnValue = true;
                }
                break;
            case "KNOB2_UP":
                if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    if (root.selectedChannel.channelAudioType == "synth") {
                        pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(1, zynqtgui.sketchpad.lastSelectedObj.value)
                    }
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    // Do nothing
                    returnValue = true;
                }
                break;
            case "KNOB2_DOWN":
                if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    if (root.selectedChannel.channelAudioType == "synth") {
                        pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                    }
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    // Do nothing
                    returnValue = true;
                }
                break;
            case "KNOB3_UP":
                if (zynqtgui.modeButtonPressed) {
                    zynqtgui.ignoreNextModeButtonPress = true;
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                        if (zynqtgui.sketchpad.lastSelectedObj.value === 4) {
                            // if we're on the last slot, select the first fx slot
                            fxRepeater.itemAt(0).switchToThisSlot(true);
                        } else {
                            // otherwise select the next slot
                            synthRepeater.itemAt(zynqtgui.sketchpad.lastSelectedObj.value + 1).switchToThisSlot(true)
                        }
                    } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                        if (zynqtgui.sketchpad.lastSelectedObj.value === 4) {
                            // if we're on the last fx slot, select the first slot
                            synthRepeater.itemAt(0).switchToThisSlot(true);
                        } else {
                            // otherwise select the next slot
                            fxRepeater.itemAt(zynqtgui.sketchpad.lastSelectedObj.value + 1).switchToThisSlot(true)
                        }
                    } else {
                        // select the first slot
                        synthRepeater.itemAt(0).switchToThisSlot(true);
                    }
                    returnValue = true;
                }
                break;
            case "KNOB3_DOWN":
                if (zynqtgui.modeButtonPressed) {
                    zynqtgui.ignoreNextModeButtonPress = true;
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                        if (zynqtgui.sketchpad.lastSelectedObj.value === 0) {
                            // if we're on the first slot, select the last fx slot
                            fxRepeater.itemAt(4).switchToThisSlot(true);
                        } else {
                            // otherwise select the previous slot
                            synthRepeater.itemAt(zynqtgui.sketchpad.lastSelectedObj.value - 1).switchToThisSlot(true)
                        }
                    } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                        if (zynqtgui.sketchpad.lastSelectedObj.value === 0) {
                            // if we're on the first fx slot, select the last slot
                            synthRepeater.itemAt(4).switchToThisSlot(true);
                        } else {
                            // otherwise select the previous fx slot
                            fxRepeater.itemAt(zynqtgui.sketchpad.lastSelectedObj.value - 1).switchToThisSlot(true)
                        }
                    } else {
                        // select the last fx
                        fxRepeater.itemAt(4).switchToThisSlot(true);
                    }
                    returnValue = true;
                }
                break;
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
            case "SWITCH_SELECT_LONG":
                if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    bottomStack.slotsBar.handleItemClick("fx")
                    returnValue = true;
                }
                break;
            case "SCREEN_EDIT_CONTEXTUAL":
                if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    if (root.selectedChannel.channelAudioType.startsWith("sample-")) {
                        zynqtgui.show_modal("channel_wave_editor")
                    } else if (root.selectedChannel.channelAudioType === "synth") {
                        var sound = root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow]
                        if (sound >= 0 && root.selectedChannel.checkIfLayerExists(sound)) {
                            zynqtgui.show_screen("control")
                        } else {
                            applicationWindow().showMessageDialog(qsTr("Selected slot is empty. Cannot open edit page."), 2000)
                        }
                    } else if (root.selectedChannel.channelAudioType === "external") {
                        show_modal("channel_external_setup")
                    }
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    if (root.selectedChannel.chainedFx[root.selectedChannel.selectedFxSlotRow] != null) {
                        zynqtgui.show_screen("control")
                    } else {
                        applicationWindow().showMessageDialog(qsTr("Selected slot is empty. Cannot open edit page."), 2000)
                    }
                } else {
                    applicationWindow().showMessageDialog(qsTr("No slots selected. Cannot open edit page."), 2000)
                }

                returnValue = true;
                break;
        }
        return returnValue;
    }

    Zynthian.Popup {
        id: channelKeyZoneSetup
        parent: QQC2.Overlay.overlay
        y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
        x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
        ChannelKeyZoneSetup {
            id: channelKeyZoneSetupItem
            anchors.fill: parent
            implicitWidth: root.width
            implicitHeight: root.height
            selectedChannel: null
            Timer {
                id: keyZoneSetupSelectedChannelThrottle
                interval: 1; running: false; repeat: false;
                onTriggered: {
                    channelKeyZoneSetupItem.selectedChannel = zynqtgui.sketchpad.song ? zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.session_dashboard.selectedChannel) : null;
                }
            }
            Connections {
                target: zynqtgui.session_dashboard
                onSelected_channel_changed: keyZoneSetupSelectedChannelThrottle.restart()
            }
        }
    }

    BouncePopup {
        id: bouncePopup
    }

    GridLayout {
        rows: 1
        anchors.fill: parent

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true

            QQC2.ButtonGroup {
                buttons: tabButtons.children
            }

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
                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 6
                    }

                    ColumnLayout {
                        id: contentColumn
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: Kirigami.Units.gridUnit / 2

                        RowLayout {
                            id: tabButtons
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                            EditableHeader {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                controlObj: root.selectedChannel
                                controlType: "bottombar-controltype-channel"

                                text: qsTr("Track: %1").arg(controlObj ? controlObj.name : "")
                            }

                            QQC2.Button {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                Layout.fillHeight: true
                                checkable: true
                                checked: root.selectedChannel.channelAudioType === "synth"
                                text: qsTr("Synth")
                                onClicked: {
                                    root.selectedChannel.channelAudioType = "synth"
                                    synthRepeater.itemAt(0).switchToThisSlot(true)
                                }
                            }
                            QQC2.Button {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                Layout.fillHeight: true
                                checkable: true
                                checked: root.selectedChannel.channelAudioType === "sample-trig"
                                text: qsTr("Sample")
                                onClicked: {
                                    root.selectedChannel.channelAudioType = "sample-trig"
                                    synthRepeater.itemAt(0).switchToThisSlot(true)
                                }
                            }
                            QQC2.Button {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                Layout.fillHeight: true
                                checkable: true
                                checked: root.selectedChannel.channelAudioType.startsWith("sample-loop")
                                text: qsTr("Sketch")
                                onClicked: {
                                    root.selectedChannel.channelAudioType = "sample-loop"
                                    synthRepeater.itemAt(0).switchToThisSlot(true)
                                }
                            }
                            QQC2.Button {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                Layout.fillHeight: true
                                checkable: true
                                checked: root.selectedChannel.channelAudioType === "external"
                                text: qsTr("External")
                                onClicked: {
                                    root.selectedChannel.channelAudioType = "external"
                                    synthRepeater.itemAt(0).switchToThisSlot(true)
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5

                                RowLayout {
                                    anchors.fill: parent
                                
                                //     RowLayout {
                                //         visible: root.selectedChannel.channelAudioType.startsWith("sample-")
                                //         Layout.fillHeight: true
                                //         spacing: 0
                                // 
                                //         QQC2.Button {
                                //             Layout.fillHeight: true
                                //             text: "Audio"
                                //             checked: root.selectedChannel && root.selectedChannel.channelAudioType === "sample-loop"
                                //             onClicked: {
                                //                 root.selectedChannel.channelAudioType = "sample-loop"
                                //             }
                                //         }
                                //         QQC2.Button {
                                //             Layout.fillHeight: true
                                //             text: "Trig"
                                //             checked: root.selectedChannel && root.selectedChannel.channelAudioType === "sample-trig"
                                //             onClicked: {
                                //                 root.selectedChannel.channelAudioType = "sample-trig"
                                //             }
                                //         }
                                //         QQC2.Button {
                                //             Layout.fillHeight: true
                                //             text: "Slice"
                                //             checked: root.selectedChannel && root.selectedChannel.channelAudioType === "sample-slice"
                                //             onClicked: {
                                //                 root.selectedChannel.channelAudioType = "sample-slice"
                                //             }
                                //         }
                                //     }

                                    Item {
                                        Layout.fillWidth: true
                                    }

//                                    RowLayout {
//                                        Layout.fillHeight: true
//                                        visible: root.selectedChannel.channelAudioType === "external"

//                                        QQC2.Button {
//                                            Layout.fillHeight: true
//                                            text: qsTr("External Midi Channel: %1").arg(root.selectedChannel ? (root.selectedChannel.externalMidiChannel > -1 ? root.selectedChannel.externalMidiChannel + 1 : root.selectedChannel.id + 1) : "")
//                                            onClicked: {
//                                                externalMidiChannelPicker.pickChannel(root.selectedChannel);
//                                            }
//                                        }
//                                        Item {
//                                            Layout.fillWidth: false
//                                            Layout.fillHeight: false
//                                            Layout.preferredWidth: Kirigami.Units.gridUnit
//                                        }
//                                    }

                                    RowLayout {
                                        Layout.fillHeight: true
                                        visible: root.selectedChannel.channelAudioType === "sample-trig"

                                        QQC2.Label {
                                            Layout.fillHeight: true
                                            text: "Key Split"
                                        }
                                        RowLayout {
                                            Layout.fillHeight: true
                                            spacing: 0
                                            QQC2.Button {
                                                Layout.fillHeight: true
                                                text: "Off"
                                                checked: root.selectedChannel && root.selectedChannel.keyZoneMode === "all-full"
                                                onClicked: {
                                                    root.selectedChannel.keyZoneMode = "all-full";
                                                }
                                            }
//                                            QQC2.Button {
//                                                Layout.fillHeight: true
//                                                text: "Auto"
//                                                checked: root.selectedChannel && root.selectedChannel.keyZoneMode === "split-full"
//                                                onClicked: {
//                                                    root.selectedChannel.keyZoneMode = "split-full";
//                                                }
//                                            }
                                            QQC2.Button {
                                                Layout.fillHeight: true
                                                text: "Narrow"
                                                checked: root.selectedChannel && root.selectedChannel.keyZoneMode === "split-narrow"
                                                onClicked: {
                                                    root.selectedChannel.keyZoneMode = "split-narrow";
                                                }
                                            }
                                        }
//                                        QQC2.Button {
//                                            Layout.fillHeight: true
//                                            icon.name: "timeline-use-zone-on"
//                                            onClicked: {
//                                                channelKeyZoneSetup.open();
//                                            }
//                                        }
                                        Item {
                                            Layout.fillWidth: false
                                            Layout.fillHeight: false
                                            Layout.preferredWidth: Kirigami.Units.gridUnit
                                        }
                                    }
                                    RowLayout {
                                        id: bounceButtonLayout
                                        Layout.fillHeight: true
                                        property bool shouldUnbounce: root.selectedChannel.channelAudioType === "sample-loop" && waveformContainer.clip && waveformContainer.clip.metadataMidiRecording != null && waveformContainer.clip.metadataMidiRecording.length > 10
                                        property bool shouldBounce: root.selectedChannel.channelAudioType !== "sample-loop" && root.selectedChannel.channelAudioType !== "external"
                                        visible: shouldBounce || shouldUnbounce
                                        QQC2.Button {
                                            text: bounceButtonLayout.shouldBounce ? qsTr("Bounce To Sketch") : (bounceButtonLayout.shouldUnbounce ? qsTr("Unbounce To Pattern") : "")
                                            icon.name: bounceButtonLayout.shouldBounce ? "go-next" : "go-previous"
                                            onClicked: {
                                                if (bounceButtonLayout.shouldBounce) {
                                                    bouncePopup.bounce(zynqtgui.sketchpad.song.scenesModel.selectedTrackName, root.selectedChannel);
                                                } else if (bounceButtonLayout.shouldUnbounce) {
                                                    // TODO Actually implement unbouncing functionality, dependent on what's contained in the sketch
                                                    sketchUnbouncer.unbounce(waveformContainer.clip, zynqtgui.sketchpad.song.scenesModel.selectedTrackName, root.selectedChannel, root.selectedChannel.selectedSlotRow);
                                                }
                                            }
                                            SketchUnbouncer {
                                                id: sketchUnbouncer
                                            }
                                        }
                                        Item {
                                            Layout.fillWidth: false
                                            Layout.fillHeight: false
                                            Layout.preferredWidth: Kirigami.Units.gridUnit
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                                Binding { //Optimization
                                    target: synthRepeater
                                    property: "synthData"
                                    delayed: true
                                    value: root.selectedChannel.channelAudioType === "synth"
                                                ? root.selectedChannel.chainedSoundsNames
                                                : root.selectedChannel.channelAudioType === "sample-trig" ||
                                                root.selectedChannel.channelAudioType === "sample-slice"
                                                    ? root.selectedChannel.samples
                                                    : root.selectedChannel.channelAudioType === "sample-loop"
                                                        ? [root.selectedChannel.getClipsModelByPart(0).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex),
                                                           root.selectedChannel.getClipsModelByPart(1).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex),
                                                           root.selectedChannel.getClipsModelByPart(2).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex),
                                                           root.selectedChannel.getClipsModelByPart(3).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex),
                                                           root.selectedChannel.getClipsModelByPart(4).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex)]
                                                        : root.selectedChannel.channelAudioType === "external"
                                                            ? [qsTr("Midi Channel: %1").arg(root.selectedChannel ? (root.selectedChannel.externalMidiChannel > -1 ? root.selectedChannel.externalMidiChannel + 1 : root.selectedChannel.id + 1) : ""), null, null, null, null]
                                                            : [null, null, null, null, null]

                                }

                                Repeater {
                                    id: synthRepeater

                                    model: 5
                                    property var synthData: [null, null, null, null, null]
                                    delegate: Rectangle {
                                        id: slotDelegate
                                        property bool highlighted: root.selectedChannel.channelAudioType === "sample-slice" ||
                                                                   root.selectedChannel.channelAudioType === "external"
                                                                    ? index === 0
                                                                    : root.selectedChannel.selectedSlotRow === index

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
//                                        border.color: highlighted ? Kirigami.Theme.highlightColor : "transparent"
//                                        border.width: 2
                                        color: "transparent"
                                        radius: 4

                                        function switchToThisSlot(onlyFocus=false) {
                                            if (zynqtgui.sketchpad.lastSelectedObj.className != "MixedChannelsViewBar_slot" || zynqtgui.sketchpad.lastSelectedObj.value != index) {
                                                zynqtgui.sketchpad.lastSelectedObj.className = "MixedChannelsViewBar_slot"
                                                zynqtgui.sketchpad.lastSelectedObj.value = index
                                                zynqtgui.sketchpad.lastSelectedObj.component = slotDelegate
                                                root.selectedChannel.selectedSlotRow = index
                                            } else {
                                                if (root.selectedChannel.channelAudioType === "external") {
                                                    // If channel type is external, then it has only 1 slot visible
                                                    // and the respective selectedSlotRow is already selected. Hence directly handle item click
                                                    if (!onlyFocus) {
                                                        bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                                                    }
                                                } else if (root.selectedChannel.channelAudioType === "sample-slice") {
                                                    // If channel type is sample-slice, then it has only 1 slot visible and it is always slot 0
                                                    // Hence set selectedSlotRow to 0 and call handle item click
                                                    root.selectedChannel.selectedSlotRow  = 0
                                                    if (!onlyFocus) {
                                                        bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                                                    }
                                                } else {
                                                    // For synth, handle item click only if not dragged. For other cases handle click immediately
                                                    if ((root.selectedChannel.channelAudioType == "synth" && !delegateMouseArea.dragHappened) || root.selectedChannel.channelAudioType != "synth") {
                                                        if (!onlyFocus) {
                                                            bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                                                        }
                                                    }
                                                }
                                            }

                                            if (root.selectedChannel.channelAudioType == "synth") {
                                                root.selectedChannel.setCurlayerByType("synth")
                                            } else if (["sample-trig", "sample-slice"].indexOf(root.selectedChannel.channelAudioType) == 0) {
                                                root.selectedChannel.setCurlayerByType("sample")
                                            } else if (root.selectedChannel.channelAudioType == "sample-loop") {
                                                root.selectedChannel.setCurlayerByType("loop")
                                            } else if (root.selectedChannel.channelAudioType == "external") {
                                                root.selectedChannel.setCurlayerByType("external")
                                            } else {
                                                root.selectedChannel.setCurlayerByType("")
                                            }
                                        }

                                        Rectangle {
                                            id: delegate
                                            property int midiChannel: root.selectedChannel.chainedSounds[index]
                                            property QtObject synthPassthroughClient: Zynthbox.Plugin.synthPassthroughClients[delegate.midiChannel] ? Zynthbox.Plugin.synthPassthroughClients[delegate.midiChannel] : null
                                            property QtObject sample: ["sample-trig", "sample-slice"].indexOf(root.selectedChannel.channelAudioType) >= 0 ? Zynthbox.PlayGridManager.getClipById(root.selectedChannel.samples[index].cppObjId) : null
                                            property QtObject clip: root.selectedChannel.channelAudioType === "sample-loop" && synthRepeater.synthData[index] != null && synthRepeater.synthData[index].path != null && synthRepeater.synthData[index].path.length >= 0 ? Zynthbox.PlayGridManager.getClipById(synthRepeater.synthData[index].cppObjId) : null

                                            anchors.fill: parent
                                            anchors.margins: 4
                                            Kirigami.Theme.inherit: false
                                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                            color: Kirigami.Theme.backgroundColor
                                            border.color: "#ff999999"
                                            border.width: 1
                                            radius: 4
                                            // For loop, slice and external modes only first slot is visible.
                                            // For other modes all slots are visible
                                            enabled: root.selectedChannel.channelAudioType === "sample-slice" ||
                                                     root.selectedChannel.channelAudioType === "external"
                                                        ? index === 0
                                                        : true
                                            opacity: enabled ? 1 : 0
                                            visible: enabled

                                            Rectangle {
                                                width: delegate.synthPassthroughClient ? parent.width * delegate.synthPassthroughClient.dryAmount : 0
                                                anchors {
                                                    left: parent.left
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                visible: root.selectedChannel.channelAudioType === "synth" &&
                                                         synthNameLabel.text.trim().length > 0

                                                color: Kirigami.Theme.highlightColor
                                            }
                                            Rectangle {
                                                width: delegate.sample ? parent.width * delegate.sample.gainAbsolute : 0
                                                anchors {
                                                    left: parent.left
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                visible: delegate.sample != null
                                                color: Kirigami.Theme.highlightColor
                                            }
                                            Rectangle {
                                                width: delegate.clip ? parent.width * delegate.clip.gainAbsolute : 0
                                                anchors {
                                                    left: parent.left
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                visible: delegate.clip != null
                                                color: Kirigami.Theme.highlightColor
                                            }

                                            QQC2.Label {
                                                id: synthNameLabel
                                                anchors {
                                                    verticalCenter: parent.verticalCenter
                                                    left: parent.left
                                                    right: parent.right
                                                    leftMargin: Kirigami.Units.gridUnit*0.5
                                                    rightMargin: Kirigami.Units.gridUnit*0.5
                                                }
                                                horizontalAlignment: Text.AlignLeft
                                                text: root.selectedChannel.channelAudioType === "synth" && synthRepeater.synthData[index] && synthRepeater.synthData[index].className == null // Check if synthRepeater.synthData[index] is not a channel/clip object by checking if it has the className property
                                                        ? synthRepeater.synthData[index]
                                                        : (root.selectedChannel.channelAudioType === "sample-trig" ||
                                                          root.selectedChannel.channelAudioType === "sample-slice" ||
                                                          root.selectedChannel.channelAudioType === "sample-loop") &&
                                                          synthRepeater.synthData[index]
                                                            ? synthRepeater.synthData[index].path
                                                              ? synthRepeater.synthData[index].path.split("/").pop()
                                                              : ""
                                                            : root.selectedChannel.channelAudioType === "external"
                                                                ? synthRepeater.synthData[index]
                                                                : ""

                                                elide: "ElideRight"
                                            }

                                            MouseArea {
                                                id: delegateMouseArea
                                                property real initialMouseX
                                                property bool dragHappened: false

                                                anchors.fill: parent
                                                onPressed: {
                                                    delegateMouseArea.initialMouseX = mouse.x
                                                }
                                                onReleased: {
                                                    dragHappenedResetTimer.restart()
                                                }
                                                onClicked: slotDelegate.switchToThisSlot()
                                                onMouseXChanged: {
                                                    var newVal
                                                    if (root.selectedChannel.channelAudioType === "synth" && root.selectedChannel.checkIfLayerExists(delegate.midiChannel) && mouse.x - delegateMouseArea.initialMouseX != 0) {
                                                        newVal = Zynthian.CommonUtils.clamp(mouse.x / delegate.width, 0, 1);
                                                        delegateMouseArea.dragHappened = true;
                                                        delegate.synthPassthroughClient.dryAmount = newVal;
                                                    } else if (["sample-trig", "sample-slice"].indexOf(root.selectedChannel.channelAudioType) >= 0 && delegate.sample && mouse.x - delegateMouseArea.initialMouseX != 0) {
                                                        newVal = Zynthian.CommonUtils.clamp(mouse.x / delegate.width, 0, 1);
                                                        delegateMouseArea.dragHappened = true;
                                                        delegate.sample.gainAbsolute = newVal;
                                                    }
                                                }
                                                onPressAndHold: {
                                                    if (!delegateMouseArea.dragHappened) {
                                                        if (root.selectedChannel.channelAudioType === "sample-loop") {
                                                            // If channel type is sample-loop open clip wave editor
                                                            if (waveformContainer.clip && waveformContainer.clip.path && waveformContainer.clip.path.length > 0) {
                                                                zynqtgui.bottomBarControlType = "bottombar-controltype-clip";
                                                                zynqtgui.bottomBarControlObj = waveformContainer.clip;
                                                                bottomStack.slotsBar.bottomBarButton.checked = true;
                                                                Qt.callLater(function() {
                                                                    bottomStack.bottomBar.waveEditorAction.trigger();
                                                                })
                                                            }
                                                        } else if (root.selectedChannel.channelAudioType.startsWith("sample")) {
                                                            // If channel type is sample then open channel wave editor
                                                            if (waveformContainer.clip && waveformContainer.clip.path && waveformContainer.clip.path.length > 0) {
                                                                zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                                                zynqtgui.bottomBarControlObj = root.selectedChannel;
                                                                bottomStack.slotsBar.bottomBarButton.checked = true;
                                                                Qt.callLater(function() {
                                                                    bottomStack.bottomBar.channelWaveEditorAction.trigger();
                                                                })
                                                            }
                                                        } else if (root.selectedChannel.channelAudioType === "synth") {
                                                            // If channel type is synth open synth edit page
                                                            if (root.selectedChannel.checkIfLayerExists(root.selectedChannel.chainedSounds[index])) {
                                                                zynqtgui.fixed_layers.activate_index(root.selectedChannel.chainedSounds[index])
                                                                zynqtgui.control.single_effect_engine = null;
                                                                zynqtgui.current_screen_id = "control";
                                                                zynqtgui.forced_screen_back = "sketchpad"
                                                            }
                                                        }
                                                    }
                                                }
                                                Timer {
                                                    id: dragHappenedResetTimer
                                                    interval: 100
                                                    repeat: false
                                                    onTriggered: {
                                                        delegateMouseArea.dragHappened = false
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                                Binding { //Optimization
                                    target: fxRepeater
                                    property: "fxData"
                                    delayed: true
                                    value: root.selectedChannel.chainedFxNames
                                }

                                Repeater {
                                    id: fxRepeater

                                    model: 5
                                    property var fxData: [null, null, null, null, null]
                                    delegate: Rectangle {
                                        id: fxRowDelegate
                                        property bool highlighted: root.selectedChannel.selectedFxSlotRow === index
                                        property QtObject fxPassthroughClient: Zynthbox.Plugin.fxPassthroughClients[root.selectedChannel.id] ? Zynthbox.Plugin.fxPassthroughClients[root.selectedChannel.id][index] : null
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
//                                        border.color: highlighted ? Kirigami.Theme.highlightColor : "transparent"
//                                        border.width: 2
                                        color: "transparent"
                                        radius: 4

                                        function switchToThisSlot() {
                                            if (zynqtgui.sketchpad.lastSelectedObj.className != "MixedChannelsViewBar_fxslot" || zynqtgui.sketchpad.lastSelectedObj.value != index) {
                                                zynqtgui.sketchpad.lastSelectedObj.className = "MixedChannelsViewBar_fxslot"
                                                zynqtgui.sketchpad.lastSelectedObj.value = index
                                                zynqtgui.sketchpad.lastSelectedObj.component = fxRowDelegate
                                                root.selectedChannel.selectedFxSlotRow = index
                                            } else {
                                                if (!fxDelegateMouseArea.dragHappened) {
                                                    bottomStack.slotsBar.handleItemClick("fx")
                                                }
                                            }
                                            root.selectedChannel.setCurlayerByType("fx")
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            Kirigami.Theme.inherit: false
                                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                            color: Kirigami.Theme.backgroundColor
                                            border.color: "#ff999999"
                                            border.width: 1
                                            radius: 4

                                            Rectangle {
                                                width: fxRowDelegate.fxPassthroughClient && fxRowDelegate.fxPassthroughClient.dryWetMixAmount >= 0 ? parent.width * fxRowDelegate.fxPassthroughClient.dryWetMixAmount : 0
                                                anchors {
                                                    left: parent.left
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                visible: fxRepeater.fxData[index] != null && fxRepeater.fxData[index].length > 0
                                                color: Kirigami.Theme.highlightColor
                                            }

                                            QQC2.Label {
                                                anchors {
                                                    verticalCenter: parent.verticalCenter
                                                    left: parent.left
                                                    right: parent.right
                                                    leftMargin: Kirigami.Units.gridUnit*0.5
                                                    rightMargin: Kirigami.Units.gridUnit*0.5
                                                }
                                                horizontalAlignment: Text.AlignLeft
                                                text: fxRepeater.fxData[index] ? fxRepeater.fxData[index] : ""

                                                elide: "ElideRight"
                                            }

                                            MouseArea {
                                                id: fxDelegateMouseArea
                                                property real initialMouseX
                                                property bool dragHappened: false

                                                anchors.fill: parent
                                                onPressed: {
                                                    fxDelegateMouseArea.initialMouseX = mouse.x
                                                }
                                                onReleased: {
                                                    fxDelegateDragHappenedResetTimer.restart()
                                                }
                                                onMouseXChanged: {
                                                    if (fxRepeater.fxData[index] != null && fxRepeater.fxData[index].length > 0 && mouse.x - fxDelegateMouseArea.initialMouseX != 0) {
                                                        var newVal = Zynthian.CommonUtils.clamp(mouse.x / fxRowDelegate.width, 0, 1);
                                                        fxDelegateMouseArea.dragHappened = true;
                                                        fxRowDelegate.fxPassthroughClient.dryWetMixAmount = newVal;
                                                    }
                                                }
                                                onClicked: fxRowDelegate.switchToThisSlot()
                                                Timer {
                                                    id: fxDelegateDragHappenedResetTimer
                                                    interval: 100
                                                    repeat: false
                                                    onTriggered: {
                                                        fxDelegateMouseArea.dragHappened = false
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }

                            RowLayout {
                                id: waveformContainer

                                property bool showWaveform: false

                                property QtObject clip: null
                                Timer {
                                    id: waveformThrottle
                                    interval: 1; repeat: false; running: false;
                                    onTriggered: {
                                        waveformContainer.clip = root.selectedChannel.channelAudioType === "sample-loop"
                                            ? root.selectedChannel.getClipsModelByPart(root.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex)
                                            : root.selectedChannel.samples[root.selectedChannel.selectedSlotRow]
                                        waveformContainer.showWaveform = root.selectedChannel.channelAudioType === "sample-trig" ||
                                                                         root.selectedChannel.channelAudioType === "sample-slice" ||
                                                                         root.selectedChannel.channelAudioType === "sample-loop"
                                    }
                                }
                                Connections {
                                    target: root
                                    onSelectedChannelChanged: waveformThrottle.restart()
                                }
                                Connections {
                                    target: root.selectedChannel
                                    onChannel_audio_type_changed: waveformThrottle.restart()
                                }
                                Connections {
                                    target: zynqtgui.sketchpad
                                    onSong_changed: waveformThrottle.restart()
                                }
                                Connections {
                                    target: zynqtgui.sketchpad.song.scenesModel
                                    onSelected_track_index_changed: waveformThrottle.restart()
                                }

                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                                spacing: Kirigami.Units.gridUnit / 2

                                // Take 3/5 th of available width
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3

                                    QQC2.Label {
                                        Layout.fillWidth: false
                                        Layout.fillHeight: false
                                        font.pointSize: 9
                                        opacity: waveformContainer.showWaveform ? 1 : 0
                                        text: waveformContainer.clip ? qsTr("Wave : %1").arg(waveformContainer.clip.filename) : ""
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: "#222222"
                                        border.width: 1
                                        border.color: "#ff999999"
                                        radius: 4
                                        opacity: waveformContainer.showWaveform ? 1 : 0

                                        Zynthbox.WaveFormItem {
                                            anchors.fill: parent
                                            color: Kirigami.Theme.textColor
                                            source: waveformContainer.clip ? waveformContainer.clip.path : ""

                                            visible: waveformContainer.clip && waveformContainer.clip.path && waveformContainer.clip.path.length > 0

                                            // Mask for wave part before start
                                            Rectangle {
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                    left: parent.left
                                                    right: startLoopLine.left
                                                }
                                                color: "#99000000"
                                            }

                                            // Mask for wave part after
                                            Rectangle {
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                    left: endLoopLine.right
                                                    right: parent.right
                                                }
                                                color: "#99000000"
                                            }

                                            // Start loop line
                                            Rectangle {
                                                id: startLoopLine
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                color: Kirigami.Theme.positiveTextColor
                                                opacity: 0.6
                                                width: Kirigami.Units.smallSpacing
                                                x: (waveformContainer.clip.startPosition / waveformContainer.clip.duration) * parent.width
                                            }

                                            // End loop line
                                            Rectangle {
                                                id: endLoopLine
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                color: Kirigami.Theme.neutralTextColor
                                                opacity: 0.6
                                                width: Kirigami.Units.smallSpacing
                                                x: ((((60/Zynthbox.SyncTimer.bpm) * waveformContainer.clip.length) / waveformContainer.clip.duration) * parent.width) + ((waveformContainer.clip.startPosition / waveformContainer.clip.duration) * parent.width)
                                            }

                                            // Progress line
                                            Rectangle {
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                visible: root.visible && waveformContainer.clip.isPlaying
                                                color: Kirigami.Theme.highlightColor
                                                width: Kirigami.Units.smallSpacing
                                                x: visible ? waveformContainer.clip.progress/waveformContainer.clip.duration * parent.width : 0
                                            }

                                            // SamplerSynth progress dots
                                            Repeater {
                                                property QtObject cppClipObject: parent.visible ? Zynthbox.PlayGridManager.getClipById(waveformContainer.clip.cppObjId) : null;
                                                model: (root.visible && root.selectedChannel.channelAudioType === "sample-slice" || root.selectedChannel.channelAudioType === "sample-trig") && cppClipObject
                                                    ? cppClipObject.playbackPositions
                                                    : 0
                                                delegate: Item {
                                                    visible: model.positionID > -1
                                                    Rectangle {
                                                        anchors.centerIn: parent
                                                        rotation: 45
                                                        color: Kirigami.Theme.highlightColor
                                                        width: Kirigami.Units.largeSpacing
                                                        height:  Kirigami.Units.largeSpacing
                                                        scale: 0.5 + model.positionGain
                                                    }
                                                    anchors {
                                                        top: parent.verticalCenter
                                                        topMargin: model.positionPan * (parent.height / 2)
                                                    }
                                                    x: Math.floor(model.positionProgress * parent.width)
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {

                                                // Show waveform on click as well as longclick instead of opening picker dialog
                                                /*if (waveformContainer.showWaveform) {
                                                    bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                                                }*/
                                                if (waveformContainer.showWaveform) {
                                                    if (root.selectedChannel.channelAudioType === "sample-loop") {
                                                        if (waveformContainer.clip && waveformContainer.clip.path && waveformContainer.clip.path.length > 0) {
                                                            zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
                                                            zynqtgui.bottomBarControlObj = waveformContainer.clip;
                                                            bottomStack.slotsBar.bottomBarButton.checked = true;
                                                            Qt.callLater(function() {
                                                                bottomStack.bottomBar.waveEditorAction.trigger();
                                                            })
                                                        }
                                                    } else {
                                                        if (waveformContainer.clip && waveformContainer.clip.path && waveformContainer.clip.path.length > 0) {
                                                            zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                                            zynqtgui.bottomBarControlObj = root.selectedChannel;
                                                            bottomStack.slotsBar.bottomBarButton.checked = true;
                                                            Qt.callLater(function() {
                                                                bottomStack.bottomBar.channelWaveEditorAction.trigger();
                                                            })
                                                        }
                                                    }
                                                }
                                            }
                                            onPressAndHold: {
                                                if (waveformContainer.showWaveform) {
                                                    if (root.selectedChannel.channelAudioType === "sample-loop") {
                                                        if (waveformContainer.clip && waveformContainer.clip.path && waveformContainer.clip.path.length > 0) {
                                                            zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
                                                            zynqtgui.bottomBarControlObj = waveformContainer.clip;
                                                            bottomStack.slotsBar.bottomBarButton.checked = true;
                                                            Qt.callLater(function() {
                                                                bottomStack.bottomBar.waveEditorAction.trigger();
                                                            })
                                                        }
                                                    } else {
                                                        if (waveformContainer.clip && waveformContainer.clip.path && waveformContainer.clip.path.length > 0) {
                                                            zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                                            zynqtgui.bottomBarControlObj = root.selectedChannel;
                                                            bottomStack.slotsBar.bottomBarButton.checked = true;
                                                            Qt.callLater(function() {
                                                                bottomStack.bottomBar.channelWaveEditorAction.trigger();
                                                            })
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Take remaining available width
                                ColumnLayout {
                                    id: patternContainer

                                    property bool showPattern: root.selectedChannel.channelAudioType === "synth" ||
                                                               root.selectedChannel.channelAudioType === "external" ||
                                                               root.selectedChannel.channelAudioType === "sample-trig" ||
                                                               root.selectedChannel.channelAudioType === "sample-slice"

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                                    opacity: patternContainer.showPattern ? 1 : 0

                                    QQC2.Label {
                                        Layout.fillWidth: false
                                        Layout.fillHeight: false
                                        font.pointSize: 9
                                        text: qsTr("Clip : %1%2").arg(root.selectedChannel.id + 1).arg(String.fromCharCode(root.selectedChannel.selectedSlotRow + 97))
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2

                                        border.width: 1
                                        border.color: "#ff999999"
                                        radius: 4
                                        color: "#222222"
                                        clip: true

                                        Image {
                                            id: patternVisualiser

                                            visible: root.selectedChannel &&
                                                     root.selectedChannel.connectedPattern >= 0

                                            anchors {
                                                fill: parent
                                                centerIn: parent
                                                topMargin: 3
                                                leftMargin: 3
                                                rightMargin: 3
                                                bottomMargin: 2
                                            }
                                            smooth: false
                                            asynchronous: true
                                            source: root.pattern ? root.pattern.thumbnailUrl : ""
                                            Rectangle { // Progress
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                visible: root.visible &&
                                                         root.sequence &&
                                                         root.sequence.isPlaying &&
                                                         root.pattern &&
                                                         root.pattern.enabled
                                                color: Kirigami.Theme.highlightColor
                                                width: widthFactor // this way the progress rect is the same width as a step
                                                property double widthFactor: visible && root.pattern ? parent.width / (root.pattern.width * root.pattern.bankLength) : 1
                                                x: visible && root.pattern ? root.pattern.bankPlaybackPosition * widthFactor : 0
                                            }
                                            MouseArea {
                                                anchors.fill:parent
                                                onClicked: {
                                                    if (patternContainer.showPattern) {
                                                        var screenBack = zynqtgui.current_screen_id;
                                                        zynqtgui.current_modal_screen_id = "playgrid";
                                                        zynqtgui.forced_screen_back = "sketchpad";
                                                        Zynthbox.PlayGridManager.setCurrentPlaygrid("playgrid", Zynthbox.PlayGridManager.sequenceEditorIndex);
                                                        var sequence = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName);
                                                        sequence.setActiveChannel(root.selectedChannel.id, root.selectedChannel.selectedPart);
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
            }
        }
    }
}
