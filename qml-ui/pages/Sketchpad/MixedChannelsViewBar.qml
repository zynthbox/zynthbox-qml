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
            // Focus a slot when a clip/channel/slot is not already focused
            if (zynqtgui.sketchpad.lastSelectedObj.className != "sketchpad_channel" &&
                    zynqtgui.sketchpad.lastSelectedObj.className != "sketchpad_clip" &&
                    zynqtgui.sketchpad.lastSelectedObj.className != "MixedChannelsViewBar_slot" &&
                    zynqtgui.sketchpad.lastSelectedObj.className != "MixedChannelsViewBar_fxslot" ) {
                if (synthRepeater.itemAt(0)) {
                    synthRepeater.itemAt(0).switchToThisSlot(true)
                } else {
                    selectedChannelThrottle.restart();
                }
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

    property QtObject sequence: root.selectedChannel ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName) : null
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
                if (root.selectedChannel.channelAudioType === "synth" && zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    root.selectedChannel.selectPreviousSynthPreset(zynqtgui.sketchpad.lastSelectedObj.value);
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    root.selectedChannel.selectPreviousFxPreset(zynqtgui.sketchpad.lastSelectedObj.value);
                }
                returnValue = true;
                break;

            case "SELECT_DOWN":
                if (root.selectedChannel.channelAudioType === "synth" && zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    root.selectedChannel.selectNextSynthPreset(zynqtgui.sketchpad.lastSelectedObj.value);
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    root.selectedChannel.selectNextFxPreset(zynqtgui.sketchpad.lastSelectedObj.value);
                }
                returnValue = true;
                break;
            case "KNOB0_TOUCHED":
                if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    if (root.selectedChannel.channelAudioType == "synth") {
                        pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[zynqtgui.sketchpad.lastSelectedObj.value], 0)
                    } else if (["sample-trig", "sample-slice"].indexOf(root.selectedChannel.channelAudioType) >= 0) {
                        pageManager.getPage("sketchpad").updateSelectedSampleGain(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    } else if (root.selectedChannel.channelAudioType == "sample-loop") {
                        pageManager.getPage("sketchpad").updateSelectedSketchGain(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    }
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    pageManager.getPage("sketchpad").updateSelectedFxLayerVolume(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    returnValue = true;
                }
                break;
            case "KNOB0_RELEASED":
                if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    // Do nothing
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    // Do nothing
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
            case "KNOB1_TOUCHED":
                if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    if (root.selectedChannel.channelAudioType == "synth") {
                        pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    }
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    // Do nothing
                    returnValue = true;
                }
                break;
            case "KNOB1_RELEASED":
                if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    // Do nothing
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    // Do nothing
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
            case "KNOB2_TOUCHED":
                if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    if (root.selectedChannel.channelAudioType == "synth") {
                        pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    }
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    // Do nothing
                    returnValue = true;
                }
                break;
            case "KNOB2_RELEASED":
                if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    // Do nothing
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
            case "KNOB3_TOUCHED":
                if (zynqtgui.modeButtonPressed) {
                    zynqtgui.ignoreNextModeButtonPress = true;
                    returnValue = true;
                }
                break;
            case "KNOB3_RELEASED":
                if (zynqtgui.modeButtonPressed) {
                    zynqtgui.ignoreNextModeButtonPress = true;
                    returnValue = true;
                }
                break;
            case "KNOB3_UP":
                if (zynqtgui.modeButtonPressed) {
                    zynqtgui.ignoreNextModeButtonPress = true;
                    let slotMax = 4;
                    let fxSlotMax = 4;
                    if (root.selectedChannel.channelAudioType === "external") {
                        slotMax = 1;
                    } else if (root.selectedChannel.channelAudioType === "sample-slice") {
                        slotMax = 0;
                    } else if (root.selectedChannel.channelAudioType === "sample-loop") {
                        fxSlotMax = -1;
                    }
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                        if (zynqtgui.sketchpad.lastSelectedObj.value === slotMax) {
                            if (fxSlotMax > -1) {
                                // if we're on the last slot, select the first fx slot
                                fxRepeater.itemAt(0).switchToThisSlot(true);
                            } else {
                                // If we're not showing the fx row, select the first synth slot
                                synthRepeater.itemAt(0).switchToThisSlot(true);
                            }
                        } else {
                            // otherwise select the next slot
                            synthRepeater.itemAt(zynqtgui.sketchpad.lastSelectedObj.value + 1).switchToThisSlot(true)
                        }
                    } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                        if (zynqtgui.sketchpad.lastSelectedObj.value === fxSlotMax) {
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
                    let slotMax = 4;
                    let fxSlotMax = 4;
                    if (root.selectedChannel.channelAudioType === "external") {
                        slotMax = 1;
                    } else if (root.selectedChannel.channelAudioType === "sample-slice") {
                        slotMax = 0;
                    } else if (root.selectedChannel.channelAudioType === "sample-loop") {
                        fxSlotMax = -1;
                    }
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                        if (zynqtgui.sketchpad.lastSelectedObj.value === 0) {
                            if (fxSlotMax > -1) {
                                // if we're on the first slot, select the last fx slot
                                fxRepeater.itemAt(fxSlotMax).switchToThisSlot(true);
                            } else {
                                synthRepeater.itemAt(slotMax).switchToThisSlot(true);
                            }
                        } else {
                            // otherwise select the previous slot
                            synthRepeater.itemAt(zynqtgui.sketchpad.lastSelectedObj.value - 1).switchToThisSlot(true)
                        }
                    } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                        if (zynqtgui.sketchpad.lastSelectedObj.value === 0) {
                            // if we're on the first fx slot, select the last slot
                            synthRepeater.itemAt(slotMax).switchToThisSlot(true);
                        } else {
                            // otherwise select the previous fx slot
                            fxRepeater.itemAt(zynqtgui.sketchpad.lastSelectedObj.value - 1).switchToThisSlot(true)
                        }
                    } else {
                        if (fxSlotMax > -1) {
                            // select the last fx
                            fxRepeater.itemAt(fxSlotMax).switchToThisSlot(true);
                        } else {
                            // if we're not using the fx row, select the last synth slot
                            synthRepeater.itemAt(slotMax).switchToThisSlot(true);
                        }
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
        }
        return returnValue;
    }

    ChannelKeyZoneSetup {
        id: channelKeyZoneSetup
    }

    BouncePopup {
        id: bouncePopup
    }

    TrackUnbouncer {
        id: trackUnbouncer
    }

    RoutingStylePicker {
        id: routingStylePicker
    }

    SamplePickingStyleSelector {
        id: samplePickingStyleSelector
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
                                QQC2.Button {
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        bottom: parent.bottom
                                        margins: Kirigami.Units.smallSpacing
                                    }
                                    width: height
                                    icon.name: "dialog-warning-symbolic"
                                    visible: (root.selectedChannel.channelAudioType !== "synth" && root.selectedChannel.channelHasSynth)
                                        || (root.selectedChannel.channelAudioType === "sample-loop" && root.selectedChannel.channelHasFx)
                                    onClicked: {
                                        let theText = "<p>" + qsTr("The following things may be causing unneeded load on the system, as this track is set to a mode which does not use these things. You might want to consider getting rid of them to make space for other things.") + "</p>";
                                        if (root.selectedChannel.channelAudioType !== "synth" && root.selectedChannel.channelHasSynth) {
                                            theText = theText + "<br><p><b>" + qsTr("Synths:") + "</b><br> " + qsTr("You have at least one synth engine on the track. While they do not produce sound, they will still be using some amount of processing power.") + "</p>";
                                        }
                                        if (root.selectedChannel.channelAudioType === "sample-loop" && root.selectedChannel.channelHasFx) {
                                            theText = theText + "<br><p><b>" + qsTr("Effects:") + "</b><br> " + qsTr("You have effects set up on the track. While they will not affect the sound of your Sketch, they will still be using some amount of processing power.") + "</p>";
                                        }
                                        unusedStuffWarning.text = theText;
                                        unusedStuffWarning.open();
                                    }
                                    Zynthian.DialogQuestion {
                                        id: unusedStuffWarning
                                        width: Kirigami.Units.gridUnit * 30
                                        height: Kirigami.Units.gridUnit * 18
                                        title: qsTr("Unused Engines on Track %1").arg(root.selectedChannel.name)
                                        rejectText: ""
                                        acceptText: qsTr("Close")
                                        textHorizontalAlignment: Text.AlignLeft
                                    }
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
                                        visible: ["synth", "sample-trig", "sample-slice"].indexOf(root.selectedChannel.channelAudioType) >= 0
                                        QQC2.Label {
                                            Layout.fillHeight: true
                                            text: qsTr("Routing")
                                        }
                                        QQC2.Button {
                                            Layout.fillHeight: true
                                            onClicked: {
                                                routingStylePicker.pickRoutingStyle(root.selectedChannel);
                                            }
                                            text: {
                                                if (root.selectedChannel) {
                                                    if (root.selectedChannel.channelRoutingStyle === "standard") {
                                                        return qsTr("Serial");
                                                    } else if (root.selectedChannel.channelRoutingStyle === "one-to-one") {
                                                        return qsTr("One-to-One");
                                                    } else {
                                                        return qsTr("Unknown");
                                                    }
                                                }
                                                return ""
                                            }
                                        }
                                        Item {
                                            Layout.fillWidth: false
                                            Layout.fillHeight: false
                                            Layout.preferredWidth: Kirigami.Units.gridUnit
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillHeight: true
                                        visible: ["sample-trig", "sample-slice"].indexOf(root.selectedChannel.channelAudioType) >= 0

                                        QQC2.Label {
                                            Layout.fillHeight: true
                                            text: qsTr("Selection:")
                                        }
                                        QQC2.Button {
                                            Layout.fillHeight: true
                                            onClicked: {
                                                samplePickingStyleSelector.pickSamplePickingStyle(root.selectedChannel);
                                            }
                                            text: {
                                                if (root.selectedChannel) {
                                                    if (root.selectedChannel.samplePickingStyle === "same-or-first") {
                                                        return qsTr("Same or First");
                                                    } else if (root.selectedChannel.samplePickingStyle === "same") {
                                                        return qsTr("Same Only");
                                                    } else if (root.selectedChannel.samplePickingStyle === "first") {
                                                        return qsTr("First Match");
                                                    } else if (root.selectedChannel.samplePickingStyle === "all") {
                                                        return qsTr("All Matches");
                                                    }
                                                }
                                                return "";
                                            }
                                        }

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
                                        QQC2.Button {
                                            Layout.fillHeight: true
                                            icon.name: "timeline-use-zone-on"
                                            visible: root.selectedChannel && root.selectedChannel.samplePickingStyle !== "same-or-first"
                                            onClicked: {
                                                channelKeyZoneSetup.open();
                                            }
                                        }
                                        Item {
                                            Layout.fillWidth: false
                                            Layout.fillHeight: false
                                            Layout.preferredWidth: Kirigami.Units.gridUnit
                                        }
                                    }
                                    RowLayout {
                                        id: bounceButtonLayout
                                        Layout.fillHeight: true
                                        visible: root.selectedChannel.channelAudioType !== "sample-loop" && root.selectedChannel.channelAudioType !== "external"
                                        QQC2.Button {
                                            text: qsTr("Bounce To Sketch")
                                            icon.name: "go-next"
                                            onClicked: {
                                                bouncePopup.bounce(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName, root.selectedChannel, -1);
                                            }
                                        }
                                        Item {
                                            Layout.fillWidth: false
                                            Layout.fillHeight: false
                                            Layout.preferredWidth: Kirigami.Units.gridUnit
                                        }
                                    }
                                    RowLayout {
                                        id: unbounceButtonLayout
                                        Layout.fillHeight: true
                                        visible: root.selectedChannel.channelAudioType === "sample-loop"
                                        QQC2.Button {
                                            text: qsTr("Unbounce Track")
                                            icon.name: "go-previous"
                                            onClicked: {
                                                trackUnbouncer.unbounce(root.selectedChannel.id);
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

                                Repeater {
                                    id: synthRepeater

                                    model: 5
                                    property var synthData: root.selectedChannel.slotsData
                                    delegate: Rectangle {
                                        id: slotDelegate
                                        property bool highlighted: root.selectedChannel.channelAudioType === "sample-slice"
                                                                    ? index === 0
                                                                    : root.selectedChannel.selectedSlotRow === index
                                        property int slotIndex: index

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
                                                root.selectedChannel.selectedPart = index
                                                root.selectedChannel.selectedSlotRow = index
                                                zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
                                                zynqtgui.bottomBarControlObj = root.selectedChannel.getClipsModelByPart(root.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex);
                                            } else {
                                                if (root.selectedChannel.channelAudioType === "external") {
                                                    // If channel type is external, then it has 2 slots visible
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
                                            property QtObject clip: root.selectedChannel.channelAudioType === "sample-loop" ? Zynthbox.PlayGridManager.getClipById(synthRepeater.synthData[index].cppObjId) : null

                                            anchors.fill: parent
                                            anchors.margins: 4
                                            Kirigami.Theme.inherit: false
                                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                            color: Kirigami.Theme.backgroundColor
                                            border.color: root.selectedChannel.channelAudioType === "sample-loop" && synthRepeater.synthData[index].enabled ? Kirigami.Theme.highlightColor :"#ff999999"
                                            border.width: 2
                                            radius: 4
                                            // For slice mode only first slot is visible.
                                            // For external mode the first two slots are visible
                                            // For other modes all slots are visible
                                            enabled: (root.selectedChannel.channelAudioType !== "sample-slice" && root.selectedChannel.channelAudioType !== "external") ||
                                                     (root.selectedChannel.channelAudioType === "sample-slice" && index === 0) ||
                                                     (root.selectedChannel.channelAudioType === "external" && (index === 0 || index === 1))
                                            opacity: enabled ? 1 : 0
                                            visible: enabled

                                            Item {
                                                anchors {
                                                    fill: parent
                                                    margins: Kirigami.Units.smallSpacing
                                                }
                                                Rectangle {
                                                    width: delegate.synthPassthroughClient ? parent.width * delegate.synthPassthroughClient.dryAmount : 0
                                                    anchors {
                                                        left: parent.left
                                                        top: parent.top
                                                        bottom: parent.bottom
                                                    }
                                                    radius: 4
                                                    opacity: 0.8
                                                    visible: root.selectedChannel.channelAudioType === "synth" && synthNameLabel.text.trim().length > 0
                                                    color: Kirigami.Theme.highlightColor
                                                }
                                                Rectangle {
                                                    width: delegate.sample ? parent.width * delegate.sample.gainAbsolute : 0
                                                    anchors {
                                                        left: parent.left
                                                        top: parent.top
                                                        bottom: parent.bottom
                                                    }
                                                    radius: 4
                                                    opacity: 0.8
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
                                                    radius: 4
                                                    opacity: 0.8
                                                    visible: delegate.clip != null
                                                    color: Kirigami.Theme.highlightColor
                                                }
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
                                                        root.selectedChannel.set_passthroughValue("synthPassthrough", slotDelegate.slotIndex, "dryAmount", newVal)
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
                                                            if (waveformContainer.clip && !waveformContainer.clip.isEmpty) {
                                                                zynqtgui.bottomBarControlType = "bottombar-controltype-clip";
                                                                zynqtgui.bottomBarControlObj = waveformContainer.clip;
                                                                bottomStack.slotsBar.bottomBarButton.checked = true;
                                                                Qt.callLater(function() {
                                                                    bottomStack.bottomBar.waveEditorAction.trigger();
                                                                })
                                                            }
                                                        } else if (root.selectedChannel.channelAudioType.startsWith("sample")) {
                                                            // If channel type is sample then open channel wave editor
                                                            if (waveformContainer.clip && !waveformContainer.clip.isEmpty) {
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
                                        // Show fx slots for all modes except sketch
                                        enabled: root.selectedChannel.channelAudioType !== "sample-loop"
                                        opacity: enabled ? 1 : 0
                                        visible: enabled

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
                                                // dryWetMixAmount ranges from 0 to 2. Interpolate it to range 0 to 1 to be able to calculate width of progress bar
                                                width: fxRowDelegate.fxPassthroughClient && fxRowDelegate.fxPassthroughClient.dryWetMixAmount >= 0 ? parent.width * Zynthian.CommonUtils.interp(fxRowDelegate.fxPassthroughClient.dryWetMixAmount, 0, 2, 0, 1) : 0
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
                                                        // dryWetMixAmount ranges from 0 to 2. Interpolate newVal to range from 0 to 1 to 0 to 2
                                                        root.selectedChannel.set_passthroughValue("fxPassthrough", index, "dryWetMixAmount", Zynthian.CommonUtils.interp(newVal, 0, 1, 0, 2));
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
                                    onSelectedSlotRowChanged: waveformThrottle.restart()
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

                                            visible: waveformContainer.clip && !waveformContainer.clip.isEmpty

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
                                                x: waveformContainer.clip != null ? (waveformContainer.clip.startPosition / waveformContainer.clip.duration) * parent.width : 0
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
                                                x: waveformContainer.clip != null ? ((((60/Zynthbox.SyncTimer.bpm) * waveformContainer.clip.length) / waveformContainer.clip.duration) * parent.width) + ((waveformContainer.clip.startPosition / waveformContainer.clip.duration) * parent.width) : 0
                                            }

                                            // Progress line
                                            Rectangle {
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                visible: root.visible && root.selectedChannel.channelAudioType === "sample-loop" && progressDots.cppClipObject && progressDots.cppClipObject.isPlaying
                                                color: Kirigami.Theme.highlightColor
                                                width: Kirigami.Units.smallSpacing
                                                x: visible && progressDots.cppClipObject ? progressDots.cppClipObject.position * parent.width : 0
                                            }

                                            // SamplerSynth progress dots
                                            Repeater {
                                                id: progressDots
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
                                                        if (waveformContainer.clip && !waveformContainer.clip.isEmpty) {
                                                            zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
                                                            zynqtgui.bottomBarControlObj = waveformContainer.clip;
                                                            bottomStack.slotsBar.bottomBarButton.checked = true;
                                                            Qt.callLater(function() {
                                                                bottomStack.bottomBar.waveEditorAction.trigger();
                                                            })
                                                        }
                                                    } else {
                                                        if (waveformContainer.clip && !waveformContainer.clip.isEmpty) {
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
                                                        if (waveformContainer.clip && !waveformContainer.clip.isEmpty) {
                                                            zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
                                                            zynqtgui.bottomBarControlObj = waveformContainer.clip;
                                                            bottomStack.slotsBar.bottomBarButton.checked = true;
                                                            Qt.callLater(function() {
                                                                bottomStack.bottomBar.waveEditorAction.trigger();
                                                            })
                                                        }
                                                    } else {
                                                        if (waveformContainer.clip && !waveformContainer.clip.isEmpty) {
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
                                        text: qsTr("Clip : %1%2").arg(root.selectedChannel.id + 1).arg(String.fromCharCode(root.selectedChannel.selectedPart + 97))
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

                                            visible: root.pattern != null

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
                                                        zynqtgui.current_modal_screen_id = "playgrid";
                                                        zynqtgui.forced_screen_back = "sketchpad";
                                                        Zynthbox.PlayGridManager.setCurrentPlaygrid("playgrid", Zynthbox.PlayGridManager.sequenceEditorIndex);
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
