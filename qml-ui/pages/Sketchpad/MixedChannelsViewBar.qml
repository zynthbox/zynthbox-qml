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
                zynqtgui.sketchpad.selectedTrackId = Zynthian.CommonUtils.clamp(zynqtgui.sketchpad.selectedTrackId - 1, 0, Zynthbox.Plugin.sketchpadTrackCount - 1)
                returnValue = true;
                break;

            case "NAVIGATE_RIGHT":
                zynqtgui.sketchpad.selectedTrackId = Zynthian.CommonUtils.clamp(zynqtgui.sketchpad.selectedTrackId + 1, 0, Zynthbox.Plugin.sketchpadTrackCount - 1)
                returnValue = true;
                break;

            case "SELECT_UP":
                if (root.selectedChannel.trackType === "synth" && zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    root.selectedChannel.selectPreviousSynthPreset(zynqtgui.sketchpad.lastSelectedObj.value);
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    root.selectedChannel.selectPreviousFxPreset(zynqtgui.sketchpad.lastSelectedObj.value);
                }
                returnValue = true;
                break;

            case "SELECT_DOWN":
                if (root.selectedChannel.trackType === "synth" && zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                    root.selectedChannel.selectNextSynthPreset(zynqtgui.sketchpad.lastSelectedObj.value);
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    root.selectedChannel.selectNextFxPreset(zynqtgui.sketchpad.lastSelectedObj.value);
                }
                returnValue = true;
                break;
            case "KNOB0_TOUCHED":
                if (!applicationWindow().osd.opened) {
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                        if (root.selectedChannel.trackType == "synth") {
                            pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[zynqtgui.sketchpad.lastSelectedObj.value], 0)
                        } else if (["sample-trig", "sample-slice"].indexOf(root.selectedChannel.trackType) >= 0) {
                            pageManager.getPage("sketchpad").updateSelectedSampleGain(0, zynqtgui.sketchpad.lastSelectedObj.value)
                        } else if (root.selectedChannel.trackType == "sample-loop") {
                            pageManager.getPage("sketchpad").updateSelectedSketchGain(0, zynqtgui.sketchpad.lastSelectedObj.value)
                        }
                        returnValue = true;
                    } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                        pageManager.getPage("sketchpad").updateSelectedFxLayerVolume(0, zynqtgui.sketchpad.lastSelectedObj.value)
                        returnValue = true;
                    }
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
                    if (root.selectedChannel.trackType == "synth") {
                        pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[zynqtgui.sketchpad.lastSelectedObj.value], 1)
                    } else if (["sample-trig", "sample-slice"].indexOf(root.selectedChannel.trackType) >= 0) {
                        pageManager.getPage("sketchpad").updateSelectedSampleGain(1, zynqtgui.sketchpad.lastSelectedObj.value)
                    } else if (root.selectedChannel.trackType == "sample-loop") {
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
                    if (root.selectedChannel.trackType == "synth") {
                        pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[zynqtgui.sketchpad.lastSelectedObj.value], -1)
                    } else if (["sample-trig", "sample-slice"].indexOf(root.selectedChannel.trackType) >= 0) {
                        pageManager.getPage("sketchpad").updateSelectedSampleGain(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                    } else if (root.selectedChannel.trackType == "sample-loop") {
                        pageManager.getPage("sketchpad").updateSelectedSketchGain(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                    }
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    pageManager.getPage("sketchpad").updateSelectedFxLayerVolume(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                    returnValue = true;
                }
                break;
            case "KNOB1_TOUCHED":
                if (!applicationWindow().osd.opened) {
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                        if (root.selectedChannel.trackType == "synth") {
                            pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(0, zynqtgui.sketchpad.lastSelectedObj.value)
                        }
                        returnValue = true;
                    } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                        // Do nothing
                        returnValue = true;
                    }
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
                    if (root.selectedChannel.trackType == "synth") {
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
                    if (root.selectedChannel.trackType == "synth") {
                        pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                    }
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    // Do nothing
                    returnValue = true;
                }
                break;
            case "KNOB2_TOUCHED":
                if (!applicationWindow().osd.opened) {
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_slot") {
                        if (root.selectedChannel.trackType == "synth") {
                            pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(0, zynqtgui.sketchpad.lastSelectedObj.value)
                        }
                        returnValue = true;
                    } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                        // Do nothing
                        returnValue = true;
                    }
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
                    if (root.selectedChannel.trackType == "synth") {
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
                    if (root.selectedChannel.trackType == "synth") {
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
                    if (root.selectedChannel.trackType === "external") {
                        slotMax = 1;
                    } else if (root.selectedChannel.trackType === "sample-slice") {
                        slotMax = 0;
                    } else if (root.selectedChannel.trackType === "sample-loop") {
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
                    if (root.selectedChannel.trackType === "external") {
                        slotMax = 1;
                    } else if (root.selectedChannel.trackType === "sample-slice") {
                        slotMax = 0;
                    } else if (root.selectedChannel.trackType === "sample-loop") {
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
                    bottomStack.slotsBar.handleItemClick(root.selectedChannel.trackType)
                    returnValue = true;
                } else if (zynqtgui.sketchpad.lastSelectedObj.className === "MixedChannelsViewBar_fxslot") {
                    bottomStack.slotsBar.handleItemClick("fx")
                    returnValue = true;
                }
                break;
        }
        return returnValue;
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
                                checked: root.selectedChannel.trackType === "synth"
                                text: qsTr("Synth")
                                onClicked: {
                                    root.selectedChannel.trackType = "synth"
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
                                    visible: (root.selectedChannel.trackType !== "synth" && root.selectedChannel.channelHasSynth)
                                        || (root.selectedChannel.trackType === "sample-loop" && root.selectedChannel.channelHasFx)
                                    onClicked: {
                                        let theText = "<p>" + qsTr("The following things may be causing unneeded load on the system, as this track is set to a mode which does not use these things. You might want to consider getting rid of them to make space for other things.") + "</p>";
                                        if (root.selectedChannel.trackType !== "synth" && root.selectedChannel.channelHasSynth) {
                                            theText = theText + "<br><p><b>" + qsTr("Synths:") + "</b><br> " + qsTr("You have at least one synth engine on the track. While they do not produce sound, they will still be using some amount of processing power.") + "</p>";
                                        }
                                        if (root.selectedChannel.trackType === "sample-loop" && root.selectedChannel.channelHasFx) {
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
                                checked: root.selectedChannel.trackType === "sample-trig"
                                text: qsTr("Sample")
                                onClicked: {
                                    root.selectedChannel.trackType = "sample-trig"
                                    synthRepeater.itemAt(0).switchToThisSlot(true)
                                }
                            }
                            QQC2.Button {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                Layout.fillHeight: true
                                checkable: true
                                checked: root.selectedChannel.trackType.startsWith("sample-loop")
                                text: qsTr("Sketch")
                                onClicked: {
                                    root.selectedChannel.trackType = "sample-loop"
                                    synthRepeater.itemAt(0).switchToThisSlot(true)
                                }
                            }
                            QQC2.Button {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                Layout.fillHeight: true
                                checkable: true
                                checked: root.selectedChannel.trackType === "external"
                                text: qsTr("External")
                                onClicked: {
                                    root.selectedChannel.trackType = "external"
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
                                //         visible: root.selectedChannel.trackType.startsWith("sample-")
                                //         Layout.fillHeight: true
                                //         spacing: 0
                                // 
                                //         QQC2.Button {
                                //             Layout.fillHeight: true
                                //             text: "Audio"
                                //             checked: root.selectedChannel && root.selectedChannel.trackType === "sample-loop"
                                //             onClicked: {
                                //                 root.selectedChannel.trackType = "sample-loop"
                                //             }
                                //         }
                                //         QQC2.Button {
                                //             Layout.fillHeight: true
                                //             text: "Trig"
                                //             checked: root.selectedChannel && root.selectedChannel.trackType === "sample-trig"
                                //             onClicked: {
                                //                 root.selectedChannel.trackType = "sample-trig"
                                //             }
                                //         }
                                //         QQC2.Button {
                                //             Layout.fillHeight: true
                                //             text: "Slice"
                                //             checked: root.selectedChannel && root.selectedChannel.trackType === "sample-slice"
                                //             onClicked: {
                                //                 root.selectedChannel.trackType = "sample-slice"
                                //             }
                                //         }
                                //     }

                                    Item {
                                        Layout.fillWidth: true
                                    }

//                                    RowLayout {
//                                        Layout.fillHeight: true
//                                        visible: root.selectedChannel.trackType === "external"

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
                                        visible: ["synth", "sample-trig", "sample-slice"].indexOf(root.selectedChannel.trackType) >= 0
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
                                                    if (root.selectedChannel.trackRoutingStyle === "standard") {
                                                        return qsTr("Serial");
                                                    } else if (root.selectedChannel.trackRoutingStyle === "one-to-one") {
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
                                        visible: ["sample-trig", "sample-slice"].indexOf(root.selectedChannel.trackType) >= 0

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
                                                bottomStack.slotsBar.requestChannelKeyZoneSetup();
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
                                        visible: root.selectedChannel.trackType !== "sample-loop" && root.selectedChannel.trackType !== "external"
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
                                        visible: root.selectedChannel.trackType === "sample-loop"
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
                                        property bool highlighted: root.selectedChannel.trackType === "sample-slice"
                                                                    ? index === 0
                                                                    : root.selectedChannel.selectedSlotRow === index
                                        property int slotIndex: index
                                        property bool isSketchpadClip: synthRepeater.synthData[index] != null && synthRepeater.synthData[index].hasOwnProperty("className") && synthRepeater.synthData[index].className == "sketchpad_clip"
                                        property QtObject cppClipObject: isSketchpadClip ? Zynthbox.PlayGridManager.getClipById(synthRepeater.synthData[index].cppObjId) : null

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
                                                zynqtgui.bottomBarControlObj = root.selectedChannel.getClipsModelByPart(root.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                                            } else {
                                                if (root.selectedChannel.trackType === "external") {
                                                    // If channel type is external, then it has 2 slots visible
                                                    // and the respective selectedSlotRow is already selected. Hence directly handle item click
                                                    if (!onlyFocus) {
                                                        bottomStack.slotsBar.handleItemClick(root.selectedChannel.trackType)
                                                    }
                                                } else if (root.selectedChannel.trackType === "sample-slice") {
                                                    // If channel type is sample-slice, then it has only 1 slot visible and it is always slot 0
                                                    // Hence set selectedSlotRow to 0 and call handle item click
                                                    root.selectedChannel.selectedSlotRow  = 0
                                                    if (!onlyFocus) {
                                                        bottomStack.slotsBar.handleItemClick(root.selectedChannel.trackType)
                                                    }
                                                } else {
                                                    // For synth, handle item click only if not dragged. For other cases handle click immediately
                                                    if ((root.selectedChannel.trackType == "synth" && !delegateMouseArea.dragHappened) || root.selectedChannel.trackType != "synth") {
                                                        if (!onlyFocus) {
                                                            bottomStack.slotsBar.handleItemClick(root.selectedChannel.trackType)
                                                        }
                                                    }
                                                }
                                            }

                                            if (root.selectedChannel.trackType == "synth") {
                                                root.selectedChannel.setCurlayerByType("synth")
                                            } else if (["sample-trig", "sample-slice"].indexOf(root.selectedChannel.trackType) > -1) {
                                                root.selectedChannel.setCurlayerByType("sample")
                                            } else if (root.selectedChannel.trackType == "sample-loop") {
                                                root.selectedChannel.setCurlayerByType("loop")
                                            } else if (root.selectedChannel.trackType == "external") {
                                                root.selectedChannel.setCurlayerByType("external")
                                            } else {
                                                root.selectedChannel.setCurlayerByType("")
                                            }
                                        }

                                        Rectangle {
                                            id: delegate
                                            property int midiChannel: root.selectedChannel.chainedSounds[index]
                                            property QtObject synthPassthroughClient: Zynthbox.Plugin.synthPassthroughClients[delegate.midiChannel] ? Zynthbox.Plugin.synthPassthroughClients[delegate.midiChannel] : null

                                            anchors.fill: parent
                                            anchors.margins: 4
                                            Kirigami.Theme.inherit: false
                                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                            color: Kirigami.Theme.backgroundColor
                                            border.color: root.selectedChannel.trackType === "sample-loop" && synthRepeater.synthData[index].enabled ? Kirigami.Theme.highlightColor :"#ff999999"
                                            border.width: 2
                                            radius: 4
                                            // For slice mode only first slot is visible.
                                            // For external mode the first two slots are visible
                                            // For other modes all slots are visible
                                            enabled: (root.selectedChannel.trackType !== "sample-slice" && root.selectedChannel.trackType !== "external") ||
                                                     (root.selectedChannel.trackType === "sample-slice" && index === 0) ||
                                                     (root.selectedChannel.trackType === "external" && (index === 0 || index === 1))
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
                                                    visible: root.selectedChannel.trackType === "synth" && synthNameLabel.text.trim().length > 0
                                                    color: Kirigami.Theme.highlightColor
                                                }
                                                Rectangle {
                                                    width: slotDelegate.cppClipObject ? parent.width * slotDelegate.cppClipObject.gainAbsolute : 0
                                                    anchors {
                                                        left: parent.left
                                                        top: parent.top
                                                        bottom: parent.bottom
                                                    }
                                                    radius: 4
                                                    opacity: 0.8
                                                    visible: slotDelegate.cppClipObject
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
                                                text: root.selectedChannel.trackType === "synth" && synthRepeater.synthData[index] && synthRepeater.synthData[index].className == null // Check if synthRepeater.synthData[index] is not a channel/clip object by checking if it has the className property
                                                        ? synthRepeater.synthData[index]
                                                        : (root.selectedChannel.trackType === "sample-trig" ||
                                                          root.selectedChannel.trackType === "sample-slice" ||
                                                          root.selectedChannel.trackType === "sample-loop") &&
                                                          synthRepeater.synthData[index]
                                                            ? synthRepeater.synthData[index].path
                                                              ? synthRepeater.synthData[index].path.split("/").pop()
                                                              : ""
                                                            : root.selectedChannel.trackType === "external"
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
                                                    if (root.selectedChannel.trackType === "synth" && root.selectedChannel.checkIfLayerExists(delegate.midiChannel) && mouse.x - delegateMouseArea.initialMouseX != 0) {
                                                        newVal = Zynthian.CommonUtils.clamp(mouse.x / delegate.width, 0, 1);
                                                        delegateMouseArea.dragHappened = true;
                                                        root.selectedChannel.set_passthroughValue("synthPassthrough", slotDelegate.slotIndex, "dryAmount", newVal)
                                                    } else if (["sample-trig", "sample-slice"].indexOf(root.selectedChannel.trackType) >= 0 && synthRepeater.synthData[index] != null && mouse.x - delegateMouseArea.initialMouseX != 0) {
                                                        newVal = Zynthian.CommonUtils.clamp(mouse.x / delegate.width, 0, 1);
                                                        delegateMouseArea.dragHappened = true;
                                                        slotDelegate.cppClipObject.gainAbsolute = newVal;
                                                    }
                                                }
                                                onPressAndHold: {
                                                    if (!delegateMouseArea.dragHappened) {
                                                        if (root.selectedChannel.trackType === "sample-loop") {
                                                            // If channel type is sample-loop open clip wave editor
                                                            if (waveformContainer.clip && !waveformContainer.clip.isEmpty) {
                                                                zynqtgui.bottomBarControlType = "bottombar-controltype-clip";
                                                                zynqtgui.bottomBarControlObj = waveformContainer.clip;
                                                                bottomStack.slotsBar.bottomBarButton.checked = true;
                                                                Qt.callLater(function() {
                                                                    bottomStack.bottomBar.waveEditorAction.trigger();
                                                                })
                                                            }
                                                        } else if (root.selectedChannel.trackType.startsWith("sample")) {
                                                            // If channel type is sample then open channel wave editor
                                                            if (waveformContainer.clip && !waveformContainer.clip.isEmpty) {
                                                                zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                                                zynqtgui.bottomBarControlObj = root.selectedChannel;
                                                                bottomStack.slotsBar.bottomBarButton.checked = true;
                                                                Qt.callLater(function() {
                                                                    bottomStack.bottomBar.channelWaveEditorAction.trigger();
                                                                })
                                                            }
                                                        } else if (root.selectedChannel.trackType === "synth") {
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
                                        enabled: root.selectedChannel.trackType !== "sample-loop"
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

                                            Item {
                                                anchors {
                                                    fill: parent
                                                    margins: Kirigami.Units.smallSpacing
                                                }
                                                Rectangle {
                                                    // dryWetMixAmount ranges from 0 to 2. Interpolate it to range 0 to 1 to be able to calculate width of progress bar
                                                    width: fxRowDelegate.fxPassthroughClient && fxRowDelegate.fxPassthroughClient.dryWetMixAmount >= 0 ? parent.width * Zynthian.CommonUtils.interp(fxRowDelegate.fxPassthroughClient.dryWetMixAmount, 0, 2, 0, 1) : 0
                                                    anchors {
                                                        left: parent.left
                                                        top: parent.top
                                                        bottom: parent.bottom
                                                    }
                                                    radius: 4
                                                    opacity: 0.8
                                                    visible: fxRepeater.fxData[index] != null && fxRepeater.fxData[index].length > 0
                                                    color: Kirigami.Theme.highlightColor
                                                }
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
                                        waveformContainer.clip = root.selectedChannel.trackType === "sample-loop"
                                            ? root.selectedChannel.getClipsModelByPart(root.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                                            : root.selectedChannel.samples[root.selectedChannel.selectedSlotRow]
                                        waveformContainer.showWaveform = root.selectedChannel.trackType === "sample-trig" ||
                                                                         root.selectedChannel.trackType === "sample-slice" ||
                                                                         root.selectedChannel.trackType === "sample-loop"
                                    }
                                }
                                Connections {
                                    target: root
                                    onSelectedChannelChanged: waveformThrottle.restart()
                                }
                                Connections {
                                    target: root.selectedChannel
                                    onTrack_type_changed: waveformThrottle.restart()
                                    onSelectedSlotRowChanged: waveformThrottle.restart()
                                }
                                Connections {
                                    target: zynqtgui.sketchpad
                                    onSong_changed: waveformThrottle.restart()
                                }
                                Connections {
                                    target: zynqtgui.sketchpad.song.scenesModel
                                    onSelected_sketchpad_song_index_changed: waveformThrottle.restart()
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
                                            id: waveformItem
                                            anchors.fill: parent
                                            color: Kirigami.Theme.textColor
                                            source: waveformContainer.clip ? waveformContainer.clip.path : ""
                                            visible: waveformContainer.clip && !waveformContainer.clip.isEmpty
                                            // Calculate amount of pixels represented by 1 second
                                            property real pixelToSecs: (waveformItem.end - waveformItem.start) / waveformItem.width
                                            // Calculate amount of pixels represented by 1 beat
                                            property real pixelsPerBeat: progressDots.cppClipObject ? (60/Zynthbox.SyncTimer.bpm*progressDots.cppClipObject.speedRatio) / waveformItem.pixelToSecs : 1
                                            start: progressDots.cppClipObject != null && progressDots.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle ? progressDots.cppClipObject.startPositionSeconds : 0
                                            end: progressDots.cppClipObject != null ? (progressDots.cppClipObject.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle ? progressDots.cppClipObject.startPositionSeconds + progressDots.cppClipObject.lengthSeconds : length) : 0
                                            readonly property real relativeStart: waveformItem.start / waveformItem.length
                                            readonly property real relativeEnd: waveformItem.end / waveformItem.length

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
                                                opacity: 0.8
                                                width: 1
                                                property real startPositionRelative: progressDots.cppClipObject
                                                    ? progressDots.cppClipObject.startPositionSamples / progressDots.cppClipObject.durationSamples
                                                    : 1
                                                x: progressDots.cppClipObject != null ? Zynthian.CommonUtils.fitInWindow(startPositionRelative, waveformItem.relativeStart, waveformItem.relativeEnd) * parent.width * parent.width : 0
                                            }

                                            // Loop line
                                            Rectangle {
                                                id: loopLine
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                color: Kirigami.Theme.highlightColor
                                                opacity: 0.8
                                                width: 1
                                                property real loopDeltaRelative: progressDots.cppClipObject
                                                    ? progressDots.cppClipObject.loopDeltaSamples / progressDots.cppClipObject.durationSamples
                                                    : 0
                                                x: progressDots.cppClipObject
                                                    ? Zynthian.CommonUtils.fitInWindow(startLoopLine.startPositionRelative + loopDeltaRelative, waveformItem.relativeStart, waveformItem.relativeEnd) * parent.width
                                                    : 0
                                            }

                                            // End loop line
                                            Rectangle {
                                                id: endLoopLine
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                color: Kirigami.Theme.neutralTextColor
                                                opacity: 0.8
                                                width: 1
                                                x: progressDots.cppClipObject
                                                    ? Zynthian.CommonUtils.fitInWindow(startLoopLine.startPositionRelative + (progressDots.cppClipObject.lengthSamples / progressDots.cppClipObject.durationSamples), waveformItem.relativeStart, waveformItem.relativeEnd) * parent.width
                                                    : 0
                                            }

                                            // Progress line
                                            Rectangle {
                                                anchors {
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                visible: root.visible && root.selectedChannel.trackType === "sample-loop" && progressDots.cppClipObject && progressDots.cppClipObject.isPlaying
                                                color: Kirigami.Theme.highlightColor
                                                width: Kirigami.Units.smallSpacing
                                                x: visible ? Zynthian.CommonUtils.fitInWindow(progressDots.cppClipObject.position, waveformItem.relativeStart, waveformItem.relativeEnd) * parent.width : 0
                                            }

                                            // SamplerSynth progress dots
                                            Timer {
                                                id: dotFetcher
                                                interval: 1; repeat: false; running: false;
                                                onTriggered: {
                                                    progressDots.playbackPositions = root.visible && (root.selectedChannel.trackType === "sample-slice" || root.selectedChannel.trackType === "sample-trig") && progressDots.cppClipObject
                                                        ? progressDots.cppClipObject.playbackPositions
                                                        : null
                                                }
                                            }
                                            Connections {
                                                target: root
                                                onVisibleChanged: dotFetcher.restart();
                                            }
                                            Connections {
                                                target: root.selectedChannel
                                                onTrack_type_changed: dotFetcher.restart();
                                            }
                                            Repeater {
                                                id: progressDots
                                                property QtObject cppClipObject: parent.visible ? Zynthbox.PlayGridManager.getClipById(waveformContainer.clip.cppObjId) : null;
                                                model: Zynthbox.Plugin.clipMaximumPositionCount
                                                property QtObject playbackPositions: null
                                                onCppClipObjectChanged: dotFetcher.restart();
                                                delegate: Item {
                                                    property QtObject progressEntry: progressDots.playbackPositions ? progressDots.playbackPositions.positions[model.index] : null
                                                    visible: progressEntry && progressEntry.id > -1
                                                    Rectangle {
                                                        anchors.centerIn: parent
                                                        rotation: 45
                                                        color: Kirigami.Theme.highlightColor
                                                        width: Kirigami.Units.largeSpacing
                                                        height:  Kirigami.Units.largeSpacing
                                                        scale: progressEntry ? 0.5 + progressEntry.gain : 1
                                                    }
                                                    anchors {
                                                        top: parent.verticalCenter
                                                        topMargin: progressEntry ? progressEntry.pan * (parent.height / 2) : 0
                                                    }
                                                    x: visible ? Math.floor(Zynthian.CommonUtils.fitInWindow(progressEntry.progress, waveformItem.relativeStart, waveformItem.relativeEnd) * parent.width) : 0
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {

                                                // Show waveform on click as well as longclick instead of opening picker dialog
                                                /*if (waveformContainer.showWaveform) {
                                                    bottomStack.slotsBar.handleItemClick(root.selectedChannel.trackType)
                                                }*/
                                                if (waveformContainer.showWaveform) {
                                                    if (root.selectedChannel.trackType === "sample-loop") {
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
                                                    if (root.selectedChannel.trackType === "sample-loop") {
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

                                    property bool showPattern: root.selectedChannel.trackType === "synth" ||
                                                               root.selectedChannel.trackType === "external" ||
                                                               root.selectedChannel.trackType === "sample-trig" ||
                                                               root.selectedChannel.trackType === "sample-slice"

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
