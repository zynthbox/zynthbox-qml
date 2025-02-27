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
            if (root.song && root.song.isLoading == false) {
                root.selectedChannel = applicationWindow().selectedChannel;
                if (root.selectedChannel) {
                    if (root.selectedChannel.selectedSlot.component === null && zynqtgui.isBootingComplete) {
                        root.pickFirstAndBestSlot();
                    }
                } else {
                    selectedChannelThrottle.restart();
                }
            } else {
                selectedChannelThrottle.restart();
            }
            console.log("Selected channel throttle time, let's goooo...");
        }
    }
    Connections {
        target: applicationWindow()
        onSelectedChannelChanged: selectedChannelThrottle.restart()
    }
    Component.onCompleted: {
        selectedChannelThrottle.restart()
    }
    Connections {
        target: selectedChannel
        function onRequestSwitchToSlot(slotType, slotIndex) {
            root.switchToSlot(slotType, slotIndex);
        }
    }
    Connections {
        target: root.song
        onIsLoadingChanged: {
            if (root.song.isLoading == false) {
                selectedChannelThrottle.restart();
            }
        }
    }
    onSongChanged: {
        selectedChannelThrottle.restart();
    }

    property QtObject sequence: root.selectedChannel ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName) : null
    property QtObject pattern: root.sequence && root.selectedChannel ? root.sequence.getByClipId(root.selectedChannel.id, root.selectedChannel.selectedClip) : null

    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    function pickNextSlot() {
        switch (root.selectedChannel.selectedSlot.className) {
            case "TracksBar_synthslot":
                if (root.selectedChannel.selectedSlot.value === 4) {
                    samplesRow.switchToSlot(0, true);
                } else {
                    synthsRow.switchToSlot(root.selectedChannel.selectedSlot.value + 1, true);
                }
                break;
            case "TracksBar_sampleslot":
                if (root.selectedChannel.selectedSlot.value === 4) {
                    synthsRow.switchToSlot(0, true);
                } else {
                    samplesRow.switchToSlot(root.selectedChannel.selectedSlot.value + 1, true);
                }
                break;
            case "TracksBar_sketchslot":
                if (root.selectedChannel.selectedSlot.value === 4) {
                    sketchesRow.switchToSlot(0, true);
                } else {
                    sketchesRow.switchToSlot(root.selectedChannel.selectedSlot.value + 1, true);
                }
                break;
            case "TracksBar_externalslot":
                if (root.selectedChannel.selectedSlot.value === 2) {
                    externalRow.switchToSlot(0, true);
                } else {
                    externalRow.switchToSlot(root.selectedChannel.selectedSlot.value + 1, true);
                }
                break;
            case "TracksBar_fxslot":
                if (root.selectedChannel.selectedSlot.value === 4) {
                    fxRow.switchToSlot(0, true);
                } else {
                    fxRow.switchToSlot(root.selectedChannel.selectedSlot.value + 1, true);
                }
                break;
            default:
                console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                break;
        }
    }
    function pickPreviousSlot() {
        switch (root.selectedChannel.selectedSlot.className) {
            case "TracksBar_synthslot":
                if (root.selectedChannel.selectedSlot.value === 0) {
                    samplesRow.switchToSlot(4, true);
                } else {
                    synthsRow.switchToSlot(root.selectedChannel.selectedSlot.value - 1, true);
                }
                break;
            case "TracksBar_sampleslot":
                if (root.selectedChannel.selectedSlot.value === 0) {
                    synthsRow.switchToSlot(4, true);
                } else {
                    samplesRow.switchToSlot(root.selectedChannel.selectedSlot.value - 1, true);
                }
                break;
            case "TracksBar_sketchslot":
                if (root.selectedChannel.selectedSlot.value === 0) {
                    sketchesRow.switchToSlot(4, true);
                } else {
                    sketchesRow.switchToSlot(root.selectedChannel.selectedSlot.value - 1, true);
                }
                break;
            case "TracksBar_externalslot":
                if (root.selectedChannel.selectedSlot.value === 0) {
                    externalRow.switchToSlot(2, true);
                } else {
                    externalRow.switchToSlot(root.selectedChannel.selectedSlot.value - 1, true);
                }
                break;
            case "TracksBar_fxslot":
                if (root.selectedChannel.selectedSlot.value === 0) {
                    fxRow.switchToSlot(4, true);
                } else {
                    fxRow.switchToSlot(root.selectedChannel.selectedSlot.value - 1, true);
                }
                break;
            default:
                console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                break;
        }
    }
    function activateSlot(slotType, slotIndex) {
        // First ensure we have the given slot selected
        switchToSlot(slotType, slotIndex);
        // Then activate it
        switch(slotType) {
            case "synth":
            case "TracksBar_synthslot":
                synthsRow.switchToSlot(slotIndex);
                break;
            case "sample":
            case "TracksBar_sampleslot":
                samplesRow.switchToSlot(slotIndex);
                break;
            case "sketch":
            case "TracksBar_sketchslot":
                sketchesRow.switchToSlot(slotIndex);
                break;
            case "fx":
            case "TracksBar_fxslot":
                fxRow.switchToSlot(slotIndex);
                break;
            case "external":
            case "TracksBar_externalslot":
                externalRow.switchToSlot(slotIndex);
                break;
            default:
                console.log("Unknown slot type:", slotType)
                break;
        }
    }
    function switchToSlot(slotType, slotIndex) {
        switch(slotType) {
            default:
                console.log("Unknown slot type: \"" + slotType + "\" - assuming synth")
            case "synth":
            case "TracksBar_synthslot":
                root.selectedChannel.displayFx = false;
                synthsRow.switchToSlot(slotIndex, true);
                break;
            case "sample":
            case "TracksBar_sampleslot":
                root.selectedChannel.displayFx = false;
                samplesRow.switchToSlot(slotIndex, true);
                break;
            case "sketch":
            case "TracksBar_sketchslot":
                root.selectedChannel.displayFx = false;
                sketchesRow.switchToSlot(slotIndex, true);
                break;
            case "fx":
            case "TracksBar_fxslot":
                root.selectedChannel.displayFx = true;
                fxRow.switchToSlot(slotIndex, true);
                break;
            case "external":
            case "TracksBar_externalslot":
                root.selectedChannel.displayFx = false;
                externalRow.switchToSlot(slotIndex, true);
                break;
        }
    }
    // Depending on track type, select the first and best (occupied) slot
    // If there is a selected slot which has stuff in it, that is the one we will use.
    // If there is is a selected slot, but there is nothing in that slot, we will reset the selection to
    // the first slot in the given type (either sound or fx slot).
    // We will then start from that position, and simply rotate through until we either have a slot
    // selected with something in it, or we have gone through all the slots and found nothing of use.
    function pickFirstAndBestSlot() {
        function checkCurrent(switchIfEmpty) {
            let slotHasContents = false;
            if (root.selectedChannel.selectedSlot.className === "TracksBar_synthslot") {
                slotHasContents = root.selectedChannel.checkIfLayerExists(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlot.value]);
                if (switchIfEmpty && slotHasContents === false) {
                    synthsRow.switchToSlot(0, true);
                }
            } else if (root.selectedChannel.selectedSlot.className === "TracksBar_sampleslot") {
                slotHasContents = root.selectedChannel.sampleSlotsData[root.selectedChannel.selectedSlot.value].cppObjId > -1;
                if (switchIfEmpty && slotHasContents === false) {
                    samplesRow.switchToSlot(0, true);
                }
            } else if (root.selectedChannel.selectedSlot.className === "TracksBar_sketchslot") {
                slotHasContents = root.selectedChannel.sketchSlotsData[root.selectedChannel.selectedSlot.value].cppObjId > -1;
                if (switchIfEmpty && slotHasContents === false) {
                    sketchesRow.switchToSlot(0, true);
                }
            } else if (root.selectedChannel.selectedSlot.className === "TracksBar_externalslot") {
                slotHasContents = (root.selectedChannel.externalSlotsData[root.selectedChannel.selectedSlot.value] !== undefined);
                if (switchIfEmpty && slotHasContents === false) {
                    externalRow.switchToSlot(0, true);
                }
            } else if (root.selectedChannel.selectedSlot.className === "TracksBar_fxslot") {
                if (root.selectedChannel.chainedFx[root.selectedChannel.selectedSlot.value] != null) {
                    slotHasContents = true;
                }
                if (switchIfEmpty && (slotHasContents === false)) {
                    fxRow.switchToSlot(0, true);
                }
            } else if (switchIfEmpty) {
                // Select the first and best option for the given TracksBar layout
                if (root.selectedChannel.displayFx === true) {
                    fxRow.switchToSlot(0, true);
                } else if (root.selectedChannel.trackType === "synth") {
                    synthsRow.switchToSlot(0, true);
                } else if (root.selectedChannel.trackType === "sample-loop") {
                    sketchesRow.switchToSlot(0, true);
                } else if (root.selectedChannel.trackType === "external") {
                    externalRow.switchToSlot(0, true);
                }
            }
            return slotHasContents;
        }
        let initialSlotIndex = 0;
        let initialSlotType = 0;
        if (["TracksBar_synthslot", "TracksBar_sampleslot", "TracksBar_sketchslot", "TracksBar_externalslot"].includes(root.selectedChannel.selectedSlot.className)) {
            initialSlotIndex = root.selectedChannel.selectedSlot.value;
        } else if (root.selectedChannel.selectedSlot.className === "TracksBar_fxslot") {
            initialSlotType = 1;
            initialSlotIndex = root.selectedChannel.selectedSlot.value;
        }
        let slotHasContents = checkCurrent(true);
        if (slotHasContents === false) {
            for (let slotIndex = 0; slotIndex < (Zynthbox.Plugin.sketchpadSlotCount * 2); ++slotIndex) {
                slotHasContents = checkCurrent(false);
                if (slotHasContents) {
                    break;
                }
                root.pickNextSlot();
            }
            // If we have reached this point and still have nothing selected, make sure we select the whatever was previously selected (or default to the first sound slot)
            if (slotHasContents === false) {
                if (initialSlotType === 0) {
                    synthsRow.switchToSlot(initialSlotIndex, true);
                } else if (initialSlotType === 1) {
                    fxRow.switchToSlot(initialSlotIndex, true);
                }
            }
        }
    }
    function cuiaCallback(cuia) {
        var returnValue = false;
        // console.log(`TracksBar : cuia: ${cuia}, altButtonPressed: ${zynqtgui.altButtonPressed}, modeButtonPressed: ${zynqtgui.modeButtonPressed}`)
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
                if (zynqtgui.altButtonPressed) {
                    root.pickFirstAndBestSlot();
                    switch (root.selectedChannel.selectedSlot.className) {
                        case "TracksBar_synthslot":
                            root.selectedChannel.selectPreviousSynthPreset(root.selectedChannel.selectedSlot.value);
                            break;
                        case "TracksBar_sampleslot":
                            break;
                        case "TracksBar_sketchslot":
                            break;
                        case "TracksBar_externalslot":
                            break;
                        case "TracksBar_fxslot":
                            root.selectedChannel.selectPreviousFxPreset(root.selectedChannel.selectedSlot.value);
                            break;
                        default:
                            console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                            break;
                    }
                }
                returnValue = true;
                break;

            case "SELECT_DOWN":
                if (zynqtgui.altButtonPressed) {
                    root.pickFirstAndBestSlot();
                    switch (root.selectedChannel.selectedSlot.className) {
                        case "TracksBar_synthslot":
                            root.selectedChannel.selectNextSynthPreset(root.selectedChannel.selectedSlot.value);
                            break;
                        case "TracksBar_sampleslot":
                            break;
                        case "TracksBar_sketchslot":
                            break;
                        case "TracksBar_externalslot":
                            break;
                        case "TracksBar_fxslot":
                            root.selectedChannel.selectNextFxPreset(root.selectedChannel.selectedSlot.value);
                            break;
                        default:
                            console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                            break;
                    }
                }
                returnValue = true;
                break;
            case "KNOB0_TOUCHED":
                if (!applicationWindow().osd.opened) {
                    root.pickFirstAndBestSlot();
                    switch (root.selectedChannel.selectedSlot.className) {
                        case "TracksBar_synthslot":
                            pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlot.value], 0)
                            break;
                        case "TracksBar_sampleslot":
                            pageManager.getPage("sketchpad").updateSelectedSampleGain(0, root.selectedChannel.selectedSlot.value)
                            break;
                        case "TracksBar_sketchslot":
                            pageManager.getPage("sketchpad").updateSelectedSketchGain(0, root.selectedChannel.selectedSlot.value)
                            break;
                        case "TracksBar_externalslot":
                            break;
                        case "TracksBar_fxslot":
                            pageManager.getPage("sketchpad").updateSelectedFxLayerVolume(0, root.selectedChannel.selectedSlot.value)
                            break;
                        default:
                            console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                            break;
                    }
                    returnValue = true;
                }
                break;
            case "KNOB0_RELEASED":
                switch (root.selectedChannel.selectedSlot.className) {
                    case "TracksBar_synthslot":
                        break;
                    case "TracksBar_sampleslot":
                        break;
                    case "TracksBar_sketchslot":
                        break;
                    case "TracksBar_externalslot":
                        break;
                    case "TracksBar_fxslot":
                        break;
                    default:
                        console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                        break;
                }
                returnValue = true;
                break;
            case "KNOB0_UP":
                root.pickFirstAndBestSlot();
                switch (root.selectedChannel.selectedSlot.className) {
                    case "TracksBar_synthslot":
                        pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlot.value], 1)
                        break;
                    case "TracksBar_sampleslot":
                        pageManager.getPage("sketchpad").updateSelectedSampleGain(1, root.selectedChannel.selectedSlot.value)
                        break;
                    case "TracksBar_sketchslot":
                        pageManager.getPage("sketchpad").updateSelectedSketchGain(1, root.selectedChannel.selectedSlot.value)
                        break;
                    case "TracksBar_externalslot":
                        break;
                    case "TracksBar_fxslot":
                        pageManager.getPage("sketchpad").updateSelectedFxLayerVolume(1, root.selectedChannel.selectedSlot.value)
                        break;
                    default:
                        console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                        break;
                }
                returnValue = true;
                break;
            case "KNOB0_DOWN":
                root.pickFirstAndBestSlot();
                switch (root.selectedChannel.selectedSlot.className) {
                    case "TracksBar_synthslot":
                        pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlot.value], -1)
                        break;
                    case "TracksBar_sampleslot":
                        pageManager.getPage("sketchpad").updateSelectedSampleGain(-1, root.selectedChannel.selectedSlot.value)
                        break;
                    case "TracksBar_sketchslot":
                        pageManager.getPage("sketchpad").updateSelectedSketchGain(-1, root.selectedChannel.selectedSlot.value)
                        break;
                    case "TracksBar_externalslot":
                        break;
                    case "TracksBar_fxslot":
                        pageManager.getPage("sketchpad").updateSelectedFxLayerVolume(-1, root.selectedChannel.selectedSlot.value)
                        break;
                    default:
                        console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                        break;
                }
                returnValue = true;
                break;
            case "KNOB1_TOUCHED":
                if (!applicationWindow().osd.opened) {
                    root.pickFirstAndBestSlot();
                    switch (root.selectedChannel.selectedSlot.className) {
                        case "TracksBar_synthslot":
                            pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(0, root.selectedChannel.selectedSlot.value)
                            break;
                        case "TracksBar_sampleslot":
                            break;
                        case "TracksBar_sketchslot":
                            break;
                        case "TracksBar_externalslot":
                            break;
                        case "TracksBar_fxslot":
                            // Do nothing
                            break;
                        default:
                            console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                            break;
                    }
                    returnValue = true;
                }
                break;
            case "KNOB1_RELEASED":
                switch (root.selectedChannel.selectedSlot.className) {
                    case "TracksBar_synthslot":
                        break;
                    case "TracksBar_sampleslot":
                        break;
                    case "TracksBar_sketchslot":
                        break;
                    case "TracksBar_externalslot":
                        break;
                    case "TracksBar_fxslot":
                        break;
                    default:
                        console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                        break;
                }
                returnValue = true;
                break;
            case "KNOB1_UP":
                root.pickFirstAndBestSlot();
                switch (root.selectedChannel.selectedSlot.className) {
                    case "TracksBar_synthslot":
                        pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(1, root.selectedChannel.selectedSlot.value)
                        break;
                    case "TracksBar_sampleslot":
                        break;
                    case "TracksBar_sketchslot":
                        break;
                    case "TracksBar_externalslot":
                        break;
                    case "TracksBar_fxslot":
                        break;
                    default:
                        console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                        break;
                }
                returnValue = true;
                break;
            case "KNOB1_DOWN":
                root.pickFirstAndBestSlot();
                switch (root.selectedChannel.selectedSlot.className) {
                    case "TracksBar_synthslot":
                        pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(-1, root.selectedChannel.selectedSlot.value)
                        break;
                    case "TracksBar_sampleslot":
                        break;
                    case "TracksBar_sketchslot":
                        break;
                    case "TracksBar_externalslot":
                        break;
                    case "TracksBar_fxslot":
                        break;
                    default:
                        console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                        break;
                }
                returnValue = true;
                break;
            case "KNOB2_TOUCHED":
                if (!applicationWindow().osd.opened) {
                    root.pickFirstAndBestSlot();
                    switch (root.selectedChannel.selectedSlot.className) {
                        case "TracksBar_synthslot":
                            pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(0, root.selectedChannel.selectedSlot.value)
                            break;
                        case "TracksBar_sampleslot":
                            break;
                        case "TracksBar_sketchslot":
                            break;
                        case "TracksBar_externalslot":
                            break;
                        case "TracksBar_fxslot":
                            break;
                        default:
                            console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                            break;
                    }
                    returnValue = true;
                }
                break;
            case "KNOB2_RELEASED":
                switch (root.selectedChannel.selectedSlot.className) {
                    case "TracksBar_synthslot":
                        break;
                    case "TracksBar_sampleslot":
                        break;
                    case "TracksBar_sketchslot":
                        break;
                    case "TracksBar_externalslot":
                        break;
                    case "TracksBar_fxslot":
                        break;
                    default:
                        console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                        break;
                }
                returnValue = true;
                break;
            case "KNOB2_UP":
                root.pickFirstAndBestSlot();
                switch (root.selectedChannel.selectedSlot.className) {
                    case "TracksBar_synthslot":
                        pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(1, root.selectedChannel.selectedSlot.value)
                        break;
                    case "TracksBar_sampleslot":
                        break;
                    case "TracksBar_sketchslot":
                        break;
                    case "TracksBar_externalslot":
                        break;
                    case "TracksBar_fxslot":
                        break;
                    default:
                        console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                        break;
                }
                returnValue = true;
                break;
            case "KNOB2_DOWN":
                root.pickFirstAndBestSlot();
                switch (root.selectedChannel.selectedSlot.className) {
                    case "TracksBar_synthslot":
                        pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(-1, root.selectedChannel.selectedSlot.value)
                        break;
                    case "TracksBar_sampleslot":
                        break;
                    case "TracksBar_sketchslot":
                        break;
                    case "TracksBar_externalslot":
                        break;
                    case "TracksBar_fxslot":
                        break;
                    default:
                        console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                        break;
                }
                returnValue = true;
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
                    root.pickNextSlot();
                    returnValue = true;
                }
                break;
            case "KNOB3_DOWN":
                if (zynqtgui.modeButtonPressed) {
                    zynqtgui.ignoreNextModeButtonPress = true;
                    root.pickPreviousSlot();
                    returnValue = true;
                }
                break;
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
                root.pickFirstAndBestSlot();
                switch (root.selectedChannel.selectedSlot.className) {
                    case "TracksBar_synthslot":
                        bottomStack.slotsBar.handleItemClick("synth")
                        break;
                    case "TracksBar_sampleslot":
                        bottomStack.slotsBar.handleItemClick("sample-trig")
                        break;
                    case "TracksBar_sketchslot":
                        bottomStack.slotsBar.handleItemClick("sample-loop")
                        break;
                    case "TracksBar_externalslot":
                        bottomStack.slotsBar.handleItemClick("external")
                        break;
                    case "TracksBar_fxslot":
                        bottomStack.slotsBar.handleItemClick("fx")
                        break;
                    default:
                        console.log("Unknown slot type", root.selectedChannel.selectedSlot.className);
                        break;
                }
                returnValue = true;
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

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Kirigami.Heading {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    wrapMode: Text.NoWrap
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                    level: 3
                                    text: qsTr("Track: %1").arg(root.selectedChannel ? root.selectedChannel.name : "")
                                }
                                QQC2.Button {
                                    Layout.fillWidth: false
                                    Layout.fillHeight: true
                                    icon.name: "document-edit"
                                    onClicked: {
                                        trackSettingsDialog.showTrackSettings(root.selectedChannel);
                                    }
                                    Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.medium*1.3)
                                    Layout.preferredHeight: Layout.preferredWidth
                                    TrackSettingsDialog {
                                        id: trackSettingsDialog
                                    }
                                }
                            }

                            QQC2.Button {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                Layout.fillHeight: true
                                checked: root.selectedChannel.trackType === "synth" && root.selectedChannel.displayFx === false
                                text: qsTr("Sound")
                                onClicked: {
                                    root.selectedChannel.trackType = "synth";
                                    synthsRow.switchToSlot(0, true);
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
                                id: fxTabButton
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                Layout.fillHeight: true
                                checked: root.selectedChannel.displayFx === true
                                text: qsTr("Fx")
                                onClicked: {
                                    fxRow.switchToSlot(0, true);
                                }
                            }
                            QQC2.Button {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                Layout.fillHeight: true
                                checked: root.selectedChannel.trackType === "sample-loop" && root.selectedChannel.displayFx === false
                                text: qsTr("Sketch")
                                onClicked: {
                                    root.selectedChannel.trackType = "sample-loop";
                                    sketchesRow.switchToSlot(0, true);
                                }
                            }
                            QQC2.Button {
                                Layout.fillWidth: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                Layout.fillHeight: true
                                checked: root.selectedChannel.trackType === "external" && root.selectedChannel.displayFx === false
                                text: qsTr("External")
                                onClicked: {
                                    root.selectedChannel.trackType = "external";
                                    externalRow.switchToSlot(0, true);
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

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    RowLayout {
                                        Layout.fillHeight: true
                                        visible: root.selectedChannel.displayFx === false && root.selectedChannel.trackType == "synth"

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
                                        visible: root.selectedChannel.trackType == "synth"
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

                            TrackSlotsData {
                                id: synthsRow
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                slotData: root.selectedChannel.synthSlotsData
                                slotType: "synth"
                                visible: root.selectedChannel.displayFx === false && root.selectedChannel.trackType == "synth"
                            }

                            TrackSlotsData {
                                id: samplesRow
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                slotData: root.selectedChannel.sampleSlotsData
                                slotType: "sample-trig"
                                visible: root.selectedChannel.displayFx === false && root.selectedChannel.trackType == "synth"
                            }

                            TrackSlotsData {
                                id: sketchesRow
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                slotData: root.selectedChannel.sketchSlotsData
                                slotType: "sample-loop"
                                visible: root.selectedChannel.displayFx === false && root.selectedChannel.trackType == "sample-loop"
                            }
                            Item {
                                // id: sketchesSpacer
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                visible: sketchesRow.visible
                            }

                            TrackSlotsData {
                                id: externalRow
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                slotData: root.selectedChannel.externalSlotsData
                                slotType: "external"
                                visible: root.selectedChannel.displayFx === false && root.selectedChannel.trackType == "external"
                            }
                            Item {
                                // id: externalSpacer
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                visible: externalRow.visible
                            }

                            TrackSlotsData {
                                id: fxRow
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                slotData: root.selectedChannel.fxSlotsData
                                slotType: "fx"
                                visible: root.selectedChannel.displayFx === true
                            }
                            Item {
                                // id: fxSpacer
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                visible: fxRow.visible
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
                                        waveformContainer.clip = root.selectedChannel.selectedSlot.component && root.selectedChannel.selectedSlot.component.clip && root.selectedChannel.selectedSlot.component.clip.hasOwnProperty("className") && root.selectedChannel.selectedSlot.component.clip.className == "sketchpad_clip"
                                            ? root.selectedChannel.selectedSlot.component.clip
                                            : null
                                        // We show the waveform container for all track types except external
                                        waveformContainer.showWaveform = root.selectedChannel.trackType === "sample-loop" ||
                                                                         root.selectedChannel.trackType === "synth"
                                    }
                                }
                                Connections {
                                    target: root
                                    onSelectedChannelChanged: waveformThrottle.restart()
                                }
                                Connections {
                                    target: root.selectedChannel
                                    onTrack_type_changed: waveformThrottle.restart()
                                }
                                Connections {
                                    target: root.selectedChannel ? root.selectedChannel.selectedSlot : null
                                    onComponentChanged: waveformThrottle.restart()
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
                                            source: progressDots.cppClipObject ? "clip:/%1".arg(progressDots.cppClipObject.id) : ""
                                            visible: waveformContainer.clip && !waveformContainer.clip.isEmpty
                                            // Calculate amount of pixels represented by 1 second
                                            property real pixelToSecs: (waveformItem.end - waveformItem.start) / waveformItem.width
                                            // Calculate amount of pixels represented by 1 beat
                                            property real pixelsPerBeat: progressDots.cppClipObject ? (60/Zynthbox.SyncTimer.bpm*progressDots.cppClipObject.speedRatio) / waveformItem.pixelToSecs : 1
                                            start: progressDots.cppClipObject != null && progressDots.cppClipObject.rootSlice.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle ? progressDots.cppClipObject.rootSlice.startPositionSeconds : 0
                                            end: progressDots.cppClipObject != null ? (progressDots.cppClipObject.rootSlice.playbackStyle == Zynthbox.ClipAudioSource.WavetableStyle ? progressDots.cppClipObject.rootSlice.startPositionSeconds + progressDots.cppClipObject.rootSlice.lengthSeconds : length) : 0
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
                                                    ? progressDots.cppClipObject.rootSlice.startPositionSamples / progressDots.cppClipObject.durationSamples
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
                                                    ? progressDots.cppClipObject.rootSlice.loopDeltaSamples / progressDots.cppClipObject.durationSamples
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
                                                    ? Zynthian.CommonUtils.fitInWindow(startLoopLine.startPositionRelative + (progressDots.cppClipObject.rootSlice.lengthSamples / progressDots.cppClipObject.durationSamples), waveformItem.relativeStart, waveformItem.relativeEnd) * parent.width
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
                                                    progressDots.playbackPositions = root.visible && root.selectedChannel.trackType === "synth" && progressDots.cppClipObject
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
                                                    bottomStack.slotsBar.handleItemClick(root.selectedChannel.trackType === "synth" ? "sample-trig" : "sample-loop")
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
                                                               root.selectedChannel.trackType === "external"

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                                    opacity: patternContainer.showPattern ? 1 : 0

                                    Connections {
                                        target: root
                                        function onSelectedChannelChanged() {
                                            if (clipBar.count > 0) {
                                                for (let clipIndex = 0; clipIndex < Zynthbox.Plugin.sketchpadSlotCount; ++clipIndex) {
                                                    let clipDelegate = clipBar.itemAt(clipIndex);
                                                    if (clipDelegate) {
                                                        let newPlaystate = Zynthbox.PlayfieldManager.clipPlaystate(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex, root.selectedChannel.id, clipIndex, Zynthbox.PlayfieldManager.NextBarPosition);
                                                        if (clipDelegate.nextBarState != newPlaystate) {
                                                            clipDelegate.nextBarState = newPlaystate;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    Connections {
                                        target: Zynthbox.PlayfieldManager
                                        function onPlayfieldStateChanged(sketchpadSong, sketchpadTrack, clipIndex, position, newPlaystate) {
                                            if (root.selectedChannel) {
                                                if (sketchpadTrack === root.selectedChannel.id && sketchpadSong === zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex && position == Zynthbox.PlayfieldManager.NextBarPosition) {
                                                    let clipDelegate = clipBar.itemAt(clipIndex);
                                                    if (clipDelegate.nextBarState != newPlaystate) {
                                                        clipDelegate.nextBarState = newPlaystate;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: false
                                        Repeater {
                                            id: clipBar
                                            model: Zynthbox.Plugin.sketchpadSlotCount
                                            QQC2.Label {
                                                id: clipDelegate
                                                font.pointSize: 9
                                                Layout.fillWidth: true
                                                Layout.preferredWidth: Kirigami.Units.gridUnit
                                                text: qsTr("Clip %1%2").arg(root.selectedChannel.id + 1).arg(String.fromCharCode(clipIndex + 97))
                                                font.underline: root.selectedChannel.selectedClip === clipIndex
                                                property int clipIndex: model.index
                                                property QtObject clip: zynqtgui.sketchpad.song.getClipById(root.selectedChannel.id, zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex, clipDelegate.clipIndex);
                                                property bool clipHasWav: clipDelegate.clip && !clipDelegate.clip.isEmpty
                                                property QtObject cppClipObject: root.visible && root.selectedChannel.trackType === "sample-loop" && clipDelegate.clipHasWav ? Zynthbox.PlayGridManager.getClipById(clipDelegate.clip.cppObjId) : null;
                                                property QtObject pattern: root.sequence.getByClipId(root.selectedChannel.id, clipIndex)
                                                property bool clipPlaying: clipDelegate.pattern ? clipDelegate.pattern.isPlaying : false
                                                property int nextBarState: Zynthbox.PlayfieldManager.StoppedState
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        if (root.selectedChannel.selectedClip === clipDelegate.clipIndex) {
                                                            clipDelegate.clip.enabled = !clipDelegate.clip.enabled;
                                                        } else {
                                                            root.selectedChannel.selectedClip = clipDelegate.clipIndex;
                                                            clipDelegate.clip.enabled = true;
                                                        }
                                                    }
                                                }
                                                Kirigami.Icon {
                                                    anchors {
                                                        left: parent.left
                                                        verticalCenter: parent.verticalCenter
                                                        leftMargin: parent.paintedWidth + Kirigami.Units.smallSpacing
                                                    }
                                                    height: parent.height - Kirigami.Units.smallSpacing
                                                    width: height
                                                    // Visible if we are running playback, the clip is not playing, and we are going to start the clip at the top of the next bar
                                                    // Also visible (non-blinking) if the timer is running, the clip is playing, and it is going to keep playing on the next bar
                                                    visible: (Zynthbox.SyncTimer.timerRunning && clipDelegate.clipPlaying === false && clipDelegate.nextBarState == Zynthbox.PlayfieldManager.PlayingState && Zynthbox.PlayGridManager.metronomeBeat16th % 4 === 0)
                                                        || (Zynthbox.SyncTimer.timerRunning && clipDelegate.clipPlaying === true && clipDelegate.nextBarState == Zynthbox.PlayfieldManager.PlayingState)
                                                    source: "media-playback-start-symbolic"
                                                }
                                                Kirigami.Icon {
                                                    anchors {
                                                        left: parent.left
                                                        verticalCenter: parent.verticalCenter
                                                        leftMargin: parent.paintedWidth + Kirigami.Units.smallSpacing
                                                    }
                                                    height: parent.height - Kirigami.Units.smallSpacing
                                                    width: height
                                                    // Visible if we are running playback, the clip is playing, and we are going to stop the clip at the top of the next bar
                                                    visible: Zynthbox.SyncTimer.timerRunning && clipDelegate.clipPlaying === true && clipDelegate.nextBarState == Zynthbox.PlayfieldManager.StoppedState && Zynthbox.PlayGridManager.metronomeBeat16th % 4 === 0
                                                    source: "media-playback-stop-symbolic"
                                                }
                                            }
                                        }
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
