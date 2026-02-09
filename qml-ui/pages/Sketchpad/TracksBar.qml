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
import QtGraphicalEffects 1.0
import org.kde.plasma.core 2.0 as PlasmaCore

import QtQuick.Controls.Styles 1.4


import io.zynthbox.ui 1.0 as ZUI

import io.zynthbox.components 1.0 as Zynthbox

ZUI.SectionPanel {
    id: root

    readonly property QtObject song: zynqtgui.sketchpad.song
    property QtObject selectedChannel: null
    Timer {
        id: selectedChannelThrottle
        interval: 1; running: false; repeat: false;
        onTriggered: {
            if (root.song && root.song.isLoading == false) {
                root.selectedChannel = applicationWindow().selectedChannel;
            } else {
                selectedChannelThrottle.restart();
                // console.log("Selected channel throttle time, don't have a song yet, or the song is still loading...");
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

    function pickNextSlot(onlySelectSlot=false) {
        switch (root.selectedChannel.selectedSlot.className) {
        case "TracksBar_synthslot":
            if (root.selectedChannel.selectedSlot.value === 4) {
                samplesRow.switchToSlot(0, true, onlySelectSlot);
            } else {
                synthsRow.switchToSlot(root.selectedChannel.selectedSlot.value + 1, true, onlySelectSlot);
            }
            break;
        case "TracksBar_sampleslot":
            if (root.selectedChannel.selectedSlot.value === 4) {
                fxRow.switchToSlot(0, true, onlySelectSlot);
            } else {
                samplesRow.switchToSlot(root.selectedChannel.selectedSlot.value + 1, true, onlySelectSlot);
            }
            break;
        case "TracksBar_sketchslot":
            if (root.selectedChannel.selectedSlot.value === 4) {
                sketchFxRow.switchToSlot(0, true, onlySelectSlot);
            } else {
                sketchesRow.switchToSlot(root.selectedChannel.selectedSlot.value + 1, true, onlySelectSlot);
            }
            break;
        case "TracksBar_externalslot":
            if (root.selectedChannel.selectedSlot.value === 2) {
                externalRow.switchToSlot(0, true, onlySelectSlot);
            } else {
                externalRow.switchToSlot(root.selectedChannel.selectedSlot.value + 1, true, onlySelectSlot);
            }
            break;
        case "TracksBar_fxslot":
            if (root.selectedChannel.selectedSlot.value === 4) {
                synthsRow.switchToSlot(0, true, onlySelectSlot);
            } else {
                fxRow.switchToSlot(root.selectedChannel.selectedSlot.value + 1, true, onlySelectSlot);
            }
            break;
        case "TracksBar_sketchfxslot":
            if (root.selectedChannel.selectedSlot.value === 4) {
                sketchesRow.switchToSlot(0, true, onlySelectSlot);
            } else {
                sketchFxRow.switchToSlot(root.selectedChannel.selectedSlot.value + 1, true, onlySelectSlot);
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
        case "TracksBar_sketchfxslot":
            if (root.selectedChannel.selectedSlot.value === 0) {
                sketchFxRow.switchToSlot(4, true);
            } else {
                sketchFxRow.switchToSlot(root.selectedChannel.selectedSlot.value - 1, true);
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
        case "sketch-fx":
        case "TracksBar_sketchfxslot":
            sketchFxRow.switchToSlot(slotIndex);
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
    function switchToSlot(slotType, slotIndex, onlySelectSlot=false) {
        switch(slotType) {
        default:
            console.log("Unknown slot type: \"" + slotType + "\" - assuming synth")
        case "synth":
        case "TracksBar_synthslot":
            synthsRow.switchToSlot(slotIndex, true, onlySelectSlot);
            break;
        case "sample":
        case "TracksBar_sampleslot":
            samplesRow.switchToSlot(slotIndex, true, onlySelectSlot);
            break;
        case "sketch":
        case "TracksBar_sketchslot":
            sketchesRow.switchToSlot(slotIndex, true, onlySelectSlot);
            break;
        case "fx":
        case "TracksBar_fxslot":
            fxRow.switchToSlot(slotIndex, true, onlySelectSlot);
            break;
        case "sketch-fx":
        case "TracksBar_sketchfxslot":
            sketchFxRow.switchToSlot(slotIndex, true, onlySelectSlot);
            break;
        case "external":
        case "TracksBar_externalslot":
            externalRow.switchToSlot(slotIndex, true, onlySelectSlot);
            break;
        }
    }
    // Depending on track type, select the first and best (occupied) slot
    // If there is a selected slot which has stuff in it, that is the one we will use.
    // If there is is a selected slot, but there is nothing in that slot, we will reset the selection to
    // the first slot in the given type (either sound or fx slot).
    // We will then start from that position, and simply rotate through until we either have a slot
    // selected with something in it, or we have gone through all the slots and found nothing of use.
    function pickFirstAndBestSlot(onlySelectSlot=false) {
        function checkCurrent(switchIfEmpty) {
            let slotHasContents = false;
            if (root.selectedChannel.selectedSlot.className === "TracksBar_synthslot") {
                slotHasContents = root.selectedChannel.checkIfLayerExists(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlot.value]);
                if (switchIfEmpty && slotHasContents === false) {
                    synthsRow.switchToSlot(0, true, onlySelectSlot);
                }
            } else if (root.selectedChannel.selectedSlot.className === "TracksBar_sampleslot") {
                slotHasContents = root.selectedChannel.sampleSlotsData[root.selectedChannel.selectedSlot.value].cppObjId > -1;
                if (switchIfEmpty && slotHasContents === false) {
                    samplesRow.switchToSlot(0, true, onlySelectSlot);
                }
            } else if (root.selectedChannel.selectedSlot.className === "TracksBar_sketchslot") {
                slotHasContents = root.selectedChannel.sketchSlotsData[root.selectedChannel.selectedSlot.value].cppObjId > -1;
                if (switchIfEmpty && slotHasContents === false) {
                    sketchesRow.switchToSlot(0, true, onlySelectSlot);
                }
            } else if (root.selectedChannel.selectedSlot.className === "TracksBar_externalslot") {
                slotHasContents = (root.selectedChannel.externalSlotsData[root.selectedChannel.selectedSlot.value] !== undefined);
                if (switchIfEmpty && slotHasContents === false) {
                    externalRow.switchToSlot(0, true, onlySelectSlot);
                }
            } else if (root.selectedChannel.selectedSlot.className === "TracksBar_fxslot") {
                if (root.selectedChannel.chainedFx[root.selectedChannel.selectedSlot.value] != null) {
                    slotHasContents = true;
                }
                if (switchIfEmpty && (slotHasContents === false)) {
                    fxRow.switchToSlot(0, true, onlySelectSlot);
                }
            }  else if (root.selectedChannel.selectedSlot.className === "TracksBar_sketchfxslot") {
                if (root.selectedChannel.chainedSketchFx[root.selectedChannel.selectedSlot.value] != null) {
                    slotHasContents = true;
                }
                if (switchIfEmpty && (slotHasContents === false)) {
                    sketchFxRow.switchToSlot(0, true, onlySelectSlot);
                }
            } else if (switchIfEmpty) {
                // Select the first and best option for the given TracksBar layout
                if (root.selectedChannel.trackType === "synth") {
                    synthsRow.switchToSlot(0, true, onlySelectSlot);
                } else if (root.selectedChannel.trackType === "sample-loop") {
                    sketchesRow.switchToSlot(0, true, onlySelectSlot);
                } else if (root.selectedChannel.trackType === "external") {
                    externalRow.switchToSlot(0, true, onlySelectSlot);
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
        } else if (root.selectedChannel.selectedSlot.className === "TracksBar_sketchfxslot") {
            initialSlotType = 2;
            initialSlotIndex = root.selectedChannel.selectedSlot.value;
        }
        let slotHasContents = checkCurrent(true);
        if (slotHasContents === false) {
            // Define the total number of slots to test. This is really more of a "the number of slots to check" thing than a direct slot index
            // root.pickNextSlot() will actually select the next slot based on what's currently selected
            let numSlotsToTest = Zynthbox.Plugin.sketchpadSlotCount;
            if (root.selectedChannel.trackType == "synth") {
                // Track type Sound has 3 sets of 5 slots
                numSlotsToTest = Zynthbox.Plugin.sketchpadSlotCount * 3;
            } else if (root.selectedChannel.trackType == "sample-loop") {
                // Track type Sound has 2 sets of 5 slots
                numSlotsToTest = Zynthbox.Plugin.sketchpadSlotCount * 2;
            }

            for (let slotIndex = 0; slotIndex < numSlotsToTest; ++slotIndex) {
                slotHasContents = checkCurrent(false);
                if (slotHasContents) {
                    break;
                }
                root.pickNextSlot(onlySelectSlot);
            }
            // If we have reached this point and still have nothing selected, make sure we select the whatever was previously selected (or default to the first sound slot)
            if (slotHasContents === false) {
                if (initialSlotType === 0) {
                    synthsRow.switchToSlot(initialSlotIndex, true, onlySelectSlot);
                } else if (initialSlotType === 1) {
                    fxRow.switchToSlot(initialSlotIndex, true, onlySelectSlot);
                } else if (initialSlotType === 2) {
                    sketchFxRow.switchToSlot(initialSlotIndex, true, onlySelectSlot);
                }
            }
        }
    }
    function cuiaCallback(cuia) {
        var returnValue = false;
        // console.log(`TracksBar : cuia: ${cuia}, altButtonPressed: ${zynqtgui.altButtonPressed}, modeButtonPressed: ${zynqtgui.modeButtonPressed}`)
        switch (cuia) {
        case "SWITCH_ARROW_LEFT_RELEASED":
            zynqtgui.sketchpad.selectedTrackId = ZUI.CommonUtils.clamp(zynqtgui.sketchpad.selectedTrackId - 1, 0, Zynthbox.Plugin.sketchpadTrackCount - 1)
            returnValue = true;
            break;

        case "SWITCH_ARROW_RIGHT_RELEASED":
            zynqtgui.sketchpad.selectedTrackId = ZUI.CommonUtils.clamp(zynqtgui.sketchpad.selectedTrackId + 1, 0, Zynthbox.Plugin.sketchpadTrackCount - 1)
            returnValue = true;
            break;

        case "SWITCH_ARROW_UP_RELEASED":
            if (zynqtgui.altButtonPressed) {
                returnValue = true;
                switch (zynqtgui.sketchpad.lastSelectedObj.className) {
                case "TracksBar_synthslot":
                    root.selectedChannel.selectPreviousSynthPreset(zynqtgui.sketchpad.lastSelectedObj.value);
                    break;
                case "TracksBar_sampleslot":
                    break;
                case "TracksBar_sketchslot":
                    break;
                case "TracksBar_externalslot":
                    break;
                case "TracksBar_fxslot":
                    root.selectedChannel.selectPreviousFxPreset(zynqtgui.sketchpad.lastSelectedObj.value);
                    break;
                default:
                    returnValue = false;
                    // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                    break;
                }
            }
            break;

        case "SWITCH_ARROW_DOWN_RELEASED":
            if (zynqtgui.altButtonPressed) {
                returnValue = true;
                switch (zynqtgui.sketchpad.lastSelectedObj.className) {
                case "TracksBar_synthslot":
                    root.selectedChannel.selectNextSynthPreset(zynqtgui.sketchpad.lastSelectedObj.value);
                    break;
                case "TracksBar_sampleslot":
                    break;
                case "TracksBar_sketchslot":
                    break;
                case "TracksBar_externalslot":
                    break;
                case "TracksBar_fxslot":
                    root.selectedChannel.selectNextFxPreset(zynqtgui.sketchpad.lastSelectedObj.value);
                    break;
                default:
                    returnValue = false;
                    // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                    break;
                }
            }
            break;
        case "KNOB0_TOUCHED":
            if (!applicationWindow().osd.opened) {
                returnValue = true;
                switch (zynqtgui.sketchpad.lastSelectedObj.className) {
                case "TracksBar_synthslot":
                    pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[zynqtgui.sketchpad.lastSelectedObj.value], 0)
                    break;
                case "TracksBar_sampleslot":
                    pageManager.getPage("sketchpad").updateSelectedSampleGain(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                case "TracksBar_sketchslot":
                    pageManager.getPage("sketchpad").updateSelectedSketchGain(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                case "TracksBar_externalslot":
                    break;
                case "TracksBar_fxslot":
                    pageManager.getPage("sketchpad").updateSelectedFxLayerVolume(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                default:
                    returnValue = false;
                    // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                    break;
                }
            }
            break;
        case "KNOB0_RELEASED":
            returnValue = true;
            switch (zynqtgui.sketchpad.lastSelectedObj.className) {
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
                returnValue = false;
                // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                break;
            }
            break;
        case "KNOB0_UP":
            returnValue = true;
            switch (zynqtgui.sketchpad.lastSelectedObj.className) {
            case "TracksBar_synthslot":
                pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[zynqtgui.sketchpad.lastSelectedObj.value], 1)
                break;
            case "TracksBar_sampleslot":
                pageManager.getPage("sketchpad").updateSelectedSampleGain(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sketchslot":
                pageManager.getPage("sketchpad").updateSelectedSketchGain(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_externalslot":
                break;
            case "TracksBar_fxslot":
                pageManager.getPage("sketchpad").updateSelectedFxLayerVolume(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            default:
                returnValue = false;
                // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                break;
            }
            break;
        case "KNOB0_DOWN":
            returnValue = false;
            switch (zynqtgui.sketchpad.lastSelectedObj.className) {
            case "TracksBar_synthslot":
                pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[zynqtgui.sketchpad.lastSelectedObj.value], -1)
                break;
            case "TracksBar_sampleslot":
                pageManager.getPage("sketchpad").updateSelectedSampleGain(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sketchslot":
                pageManager.getPage("sketchpad").updateSelectedSketchGain(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_externalslot":
                break;
            case "TracksBar_fxslot":
                pageManager.getPage("sketchpad").updateSelectedFxLayerVolume(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            default:
                returnValue = false;
                // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                break;
            }
            break;
        case "KNOB1_TOUCHED":
            if (!applicationWindow().osd.opened) {
                returnValue = true;
                switch (zynqtgui.sketchpad.lastSelectedObj.className) {
                case "TracksBar_synthslot":
                    pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                case "TracksBar_sampleslot":
                    break;
                case "TracksBar_sketchslot":
                    break;
                case "TracksBar_externalslot":
                    break;
                case "TracksBar_fxslot":
                    pageManager.getPage("sketchpad").updateSelectedChannelFxLayerCutoff(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                case "TracksBar_sketchfxslot":
                    pageManager.getPage("sketchpad").updateSelectedChannelSketchFxLayerCutoff(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                default:
                    returnValue = false;
                    // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                    break;
                }
            }
            break;
        case "KNOB1_RELEASED":
            returnValue = true;
            switch (zynqtgui.sketchpad.lastSelectedObj.className) {
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
                returnValue = false;
                // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                break;
            }
            break;
        case "KNOB1_UP":
            returnValue = true;
            switch (zynqtgui.sketchpad.lastSelectedObj.className) {
            case "TracksBar_synthslot":
                pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sampleslot":
                break;
            case "TracksBar_sketchslot":
                break;
            case "TracksBar_externalslot":
                break;
            case "TracksBar_fxslot":
                pageManager.getPage("sketchpad").updateSelectedChannelFxLayerCutoff(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sketchfxslot":
                pageManager.getPage("sketchpad").updateSelectedChannelSketchFxLayerCutoff(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            default:
                returnValue = false;
                // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                break;
            }
            break;
        case "KNOB1_DOWN":
            returnValue = true;
            switch (zynqtgui.sketchpad.lastSelectedObj.className) {
            case "TracksBar_synthslot":
                pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sampleslot":
                break;
            case "TracksBar_sketchslot":
                break;
            case "TracksBar_externalslot":
                break;
            case "TracksBar_fxslot":
                pageManager.getPage("sketchpad").updateSelectedChannelFxLayerCutoff(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sketchfxslot":
                pageManager.getPage("sketchpad").updateSelectedChannelSketchFxLayerCutoff(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            default:
                returnValue = false;
                // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                break;
            }
            break;
        case "KNOB2_TOUCHED":
            if (!applicationWindow().osd.opened) {
                returnValue = true;
                switch (zynqtgui.sketchpad.lastSelectedObj.className) {
                case "TracksBar_synthslot":
                    pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                case "TracksBar_sampleslot":
                    break;
                case "TracksBar_sketchslot":
                    break;
                case "TracksBar_externalslot":
                    break;
                case "TracksBar_fxslot":
                    pageManager.getPage("sketchpad").updateSelectedChannelFxLayerResonance(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                case "TracksBar_sketchfxslot":
                    pageManager.getPage("sketchpad").updateSelectedChannelSketchFxLayerResonance(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                default:
                    returnValue = false;
                    // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                    break;
                }
            }
            break;
        case "KNOB2_RELEASED":
            returnValue = true;
            switch (zynqtgui.sketchpad.lastSelectedObj.className) {
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
                returnValue = false;
                // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                break;
            }
            break;
        case "KNOB2_UP":
            returnValue = true;
            switch (zynqtgui.sketchpad.lastSelectedObj.className) {
            case "TracksBar_synthslot":
                pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sampleslot":
                break;
            case "TracksBar_sketchslot":
                break;
            case "TracksBar_externalslot":
                break;
            case "TracksBar_fxslot":
                pageManager.getPage("sketchpad").updateSelectedChannelFxLayerResonance(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sketchfxslot":
                pageManager.getPage("sketchpad").updateSelectedChannelSketchFxLayerResonance(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            default:
                returnValue = false;
                // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                break;
            }
            break;
        case "KNOB2_DOWN":
            returnValue = true;
            switch (zynqtgui.sketchpad.lastSelectedObj.className) {
            case "TracksBar_synthslot":
                pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sampleslot":
                break;
            case "TracksBar_sketchslot":
                break;
            case "TracksBar_externalslot":
                break;
            case "TracksBar_fxslot":
                pageManager.getPage("sketchpad").updateSelectedChannelFxLayerResonance(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sketchfxslot":
                pageManager.getPage("sketchpad").updateSelectedChannelSketchFxLayerResonance(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            default:
                returnValue = false;
                // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                break;
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
        case "SWITCH_SELECT_RELEASED":
            returnValue = true;
            switch (zynqtgui.sketchpad.lastSelectedObj.className) {
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
                returnValue = false;
                // console.log("Unknown slot type", zynqtgui.sketchpad.lastSelectedObj.className);
                break;
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

    SamplePickingStyleSelector {
        id: samplePickingStyleSelector
    }

    QQC2.ButtonGroup {
        buttons: tabButtons.children
    }
    
    contentItem: Item {
        GridLayout {
            columnSpacing: ZUI.Theme.sectionSpacing
            rowSpacing: columnSpacing
            columns: 2
            rows: 1
            anchors.fill: parent

            BottomStackTabs {
                id: buttonsColumn
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                Layout.maximumWidth: Kirigami.Units.gridUnit * 6
                Layout.column: ZUI.Theme.altTabs ? 1: 0
                
            }

            QQC2.Pane {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Layout.column: ZUI.Theme.altTabs ? 0: 1

                contentItem: Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: Kirigami.Units.gridUnit / 2

                    ColumnLayout {
                        id: contentColumn
                        anchors.fill: parent

                        RowLayout {
                            spacing: ZUI.Theme.sectionSpacing
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                            ZUI.SectionGroup {
                                Layout.fillHeight: true
                                Layout.fillWidth: true

                                Kirigami.Heading { 
                                    anchors.fill: parent
                                    padding: 2                                  
                                    wrapMode: Text.NoWrap
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                    // horizontalAlignment: Text.AlignHCenter
                                    horizontalAlignment: Text.AlignLeft
                                    level: 3
                                    font.bold: true
                                    readonly property string trackId: ("T%1").arg(root.selectedChannel ? root.selectedChannel.id+1 : "")
                                    readonly property string trackName: root.selectedChannel ? root.selectedChannel.name : ""
                                    text: qsTr("Track %1").arg(trackId === trackName ? trackId : trackId + ": " + trackName)
                                }
                            }

                            ZUI.SectionGroup {
                                Layout.fillHeight: true

                                RowLayout {
                                    id: tabButtons
                                    anchors.fill: parent
                                    spacing: ZUI.Theme.spacing

                                    ZUI.SectionButton {
                                        Layout.fillWidth: false
                                        Layout.fillHeight: true
                                        icon.name: "document-edit"
                                        icon.height: 24
                                        icon.width: 24
                                        onClicked: {
                                            trackSettingsDialog.showTrackSettings(root.selectedChannel);
                                        }
                                        Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.medium*1.3)
                                        Layout.preferredHeight: Layout.preferredWidth
                                        TrackSettingsDialog {
                                            id: trackSettingsDialog
                                        }
                                    }

                                    ZUI.SectionButton {
                                        Layout.fillWidth: false
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        Layout.fillHeight: true
                                        checked: highlighted
                                        highlighted: root.selectedChannel != null && root.selectedChannel.trackType === "synth"
                                        text: qsTr("Sketch")
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
                                            visible: root.selectedChannel != null && ((root.selectedChannel.trackType !== "synth" && root.selectedChannel.channelHasSynth) || (root.selectedChannel.trackType === "sample-loop" && root.selectedChannel.channelHasFx))
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
                                            ZUI.DialogQuestion {
                                                id: unusedStuffWarning
                                                width: Kirigami.Units.gridUnit * 30
                                                height: Kirigami.Units.gridUnit * 18
                                                title: root.selectedChannel != null ? qsTr("Unused Engines on Track %1").arg(root.selectedChannel.name) : ""
                                                rejectText: ""
                                                acceptText: qsTr("Close")
                                                textHorizontalAlignment: Text.AlignLeft
                                            }
                                        }
                                      }

                                    ZUI.SectionButton {
                                        // TODO Return for 1.1
                                        visible: false
                                        Layout.fillWidth: false
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        Layout.fillHeight: true
                                        checked: highlighted
                                        highlighted: root.selectedChannel != null && root.selectedChannel.trackType === "sample-loop"
                                        text: qsTr("Loop")
                                        onClicked: {
                                            root.selectedChannel.trackType = "sample-loop";
                                            sketchesRow.switchToSlot(0, true);
                                        }
                                    }

                                    ZUI.SectionButton {
                                        Layout.fillWidth: false
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        Layout.fillHeight: true
                                        checked: highlighted
                                        highlighted: root.selectedChannel != null && root.selectedChannel.trackType === "external"
                                        text: qsTr("External")
                                        onClicked: {
                                            root.selectedChannel.trackType = "external";
                                            externalRow.switchToSlot(0, true);
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                            Item {
                                Layout.fillWidth: true
                            }

                            ZUI.SectionGroup {
                                     
                                Layout.fillHeight: true
                                visible: root.selectedChannel != null && root.selectedChannel.trackType == "synth"

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: ZUI.Theme.spacing

                                    QQC2.Switch {
                                        Layout.fillHeight: true
                                        padding: 4
                                        checked: root.selectedChannel && root.selectedChannel.trackStyle === "one-to-one"
                                        text: qsTr("1:1")
                                        // text: root.selectedChannel ? trackStyleName(root.selectedChannel.trackStyle) : ""
                                        function trackStyleName(trackStyle) {
                                            switch (trackStyle) {
                                            case "everything":
                                                return qsTr("Everything");
                                            case "one-to-one":
                                                return qsTr("1:1");
                                            case "drums":
                                                return qsTr("Drums");
                                            case "2-low-3-high":
                                                return qsTr("2 low/3 high");
                                            default:
                                                return qsTr("Manual");
                                            }
                                        }
                                        onToggled: {
                                            if (root.selectedChannel.trackStyle === "everything") {
                                                root.selectedChannel.trackStyle = "one-to-one";
                                            } else {
                                                root.selectedChannel.trackStyle = "everything";
                                            }
                                            // This will want switching out for a slot picking style selector when we
                                            // introduce more of them (for now we just switch between everything and
                                            // one-to-one, so no reason to spend time on that just yet)
                                        }
                                        background: Rectangle {
                                            opacity: parent.checked ? 0.5 : 1
                                            color: parent.checked ? "#181918" : "#1f2022"
                                            radius: 2
                                        }
                                    }

                                    QQC2.Label {
                                        Layout.fillHeight: true
                                        visible: root.selectedChannel ? root.selectedChannel.trackStyle === "manual" : false
                                        text: qsTr("Slot Selection:")
                                    }
                                    QQC2.Button {
                                        Layout.fillHeight: true
                                        visible: root.selectedChannel ? root.selectedChannel.trackStyle === "manual" : false
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

                                    QQC2.Button {
                                        Layout.fillHeight: true
                                        icon.name: "timeline-use-zone-on"
                                        text: qsTr("Key Zones")
                                        visible: root.selectedChannel ? root.selectedChannel.trackStyle === "manual" : false
                                        onClicked: {
                                            bottomStack.slotsBar.requestChannelKeyZoneSetup();
                                        }
                                    }
                                }

                            }   

                            QQC2.Button {
                                id: bounceButtonLayout
                                Layout.fillHeight: true
                                // TODO Return for 1.1
                                visible: false // root.selectedChannel.trackType == "synth"
                                text: qsTr("Bounce Sketch")
                                icon.name: "go-next"
                                onClicked: {
                                    bouncePopup.bounce(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName, root.selectedChannel, -1);
                                }
                            }

                            QQC2.Button {
                                id: unbounceButtonLayout
                                Layout.fillHeight: true
                                visible: root.selectedChannel != null && root.selectedChannel.trackType === "sample-loop"
                                text: qsTr("Unbounce Track")
                                icon.name: "go-previous"
                                onClicked: {
                                    trackUnbouncer.unbounce(root.selectedChannel.id);
                                }
                            }

                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            // spacing: ZUI.Theme.sectionSpacing                            
                            spacing: ZUI.Theme.slotSpacing[0]                       

                            Item {
                                Layout.fillWidth: true
                                // Layout.fillHeight: true
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                                TrackSlotsData {
                                    id: synthsRow
                                    anchors.fill: parent
                                    slotData: root.selectedChannel != null ? root.selectedChannel.synthSlotsData : []
                                    slotType: "synth"
                                    showSlotTypeLabel: true
                                    visible: root.selectedChannel != null && root.selectedChannel.trackType == "synth"
                                }
                                TrackSlotsData {
                                    id: sketchesRow
                                    anchors.fill: parent
                                    slotData: root.selectedChannel != null ? root.selectedChannel.sketchSlotsData : []
                                    slotType: "sample-loop"
                                    showSlotTypeLabel: true
                                    visible: root.selectedChannel != null && root.selectedChannel.trackType == "sample-loop"
                                }
                                TrackSlotsData {
                                    id: externalRow
                                    anchors.fill: parent
                                    slotData: root.selectedChannel != null ? root.selectedChannel.externalSlotsData : []
                                    slotType: "external"
                                    showSlotTypeLabel: true
                                    visible: root.selectedChannel != null && root.selectedChannel.trackType == "external"
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                                // Layout.fillHeight: true
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                TrackSlotsData {
                                    id: samplesRow
                                    anchors.fill: parent
                                    slotData: root.selectedChannel != null ? root.selectedChannel.sampleSlotsData : []
                                    slotType: "sample-trig"
                                    showSlotTypeLabel: true
                                    visible: root.selectedChannel != null && root.selectedChannel.trackType == "synth"
                                }
                                TrackSlotsData {
                                    id: sketchFxRow
                                    anchors.fill: parent
                                    slotData: root.selectedChannel != null ? root.selectedChannel.sketchFxSlotsData : []
                                    slotType: "sketch-fx"
                                    showSlotTypeLabel: true
                                    visible: root.selectedChannel != null && root.selectedChannel.trackType == "sample-loop"
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                                // Layout.fillHeight: true
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                TrackSlotsData {
                                    id: fxRow
                                    anchors.fill: parent
                                    slotData: root.selectedChannel != null ? root.selectedChannel.fxSlotsData : []
                                    slotType: "fx"
                                    showSlotTypeLabel: true
                                    visible: root.selectedChannel != null && (root.selectedChannel.trackType == "synth" || (root.selectedChannel.trackType == "external" && root.selectedChannel.externalSettings && root.selectedChannel.externalSettings.audioSource != ""))
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

                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                            spacing: ZUI.Theme.sectionSpacing

                            Timer {
                                id: waveformThrottle
                                interval: 1; repeat: false; running: false;
                                onTriggered: {
                                    let selectedSlot = root.selectedChannel.selectedSlot;
                                    if (selectedSlot.className === "TracksBar_sampleslot") {
                                        waveformContainer.clip = root.selectedChannel.samples[selectedSlot.value];
                                    } else if (selectedSlot.className === "TracksBar_sketchslot") {
                                        waveformContainer.clip = root.selectedChannel.getClipsModelById(selectedSlot.value).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                                    } else {
                                        waveformContainer.clip = null;
                                    }
                                    // We show the waveform container for all selected slots where there is a sample associated
                                    waveformContainer.showWaveform = ["TracksBar_sampleslot", "TracksBar_sketchslot"].indexOf(root.selectedChannel.selectedSlot.className) >= 0
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

                            // Take 3/5 th of available width
                           Item {
                                // color: "yellow"
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                ColumnLayout {
                                   
                                    anchors.fill: parent

                                    ZUI.SectionGroup {
                                        Layout.fillWidth: false
                                        Layout.fillHeight: false
                                        implicitHeight: Kirigami.Units.gridUnit * 2
                                        RowLayout {
                                           anchors.fill: parent
                                           spacing: ZUI.Theme.spacing

                                            QQC2.Label {
                                                Layout.fillWidth: false
                                                Layout.fillHeight: true
                                                font.pointSize: 9
                                                visible: waveformContainer.showWaveform
                                                text: waveformContainer.clip
                                                    ? progressDots.cppClipObject && progressDots.cppClipObject.sourceExists === false
                                                        ? qsTr("Missing Wave: %1").arg(waveformContainer.clip.filename)
                                                        : qsTr("Wave : %1").arg(waveformContainer.clip.filename)
                                                : ""
                                                elide: Text.ElideMiddle
                                                color: progressDots.cppClipObject && progressDots.cppClipObject.sourceExists === false ? "red" : Kirigami.Theme.textColor
                                            }

                                            ZUI.SectionButton {
                                                visible: !waveformContainer.showWaveform
                                                Layout.fillHeight: true
                                                Layout.minimumWidth: Kirigami.Units.gridUnit * 3
                                                icon.name: "go-first"
                                                onClicked: {
                                                    switch (root.selectedChannel.selectedSlot.className) {
                                                        case "TracksBar_synthslot":
                                                            root.selectedChannel.selectPreviousSynthBank(root.selectedChannel.selectedSlot.value);
                                                            break;
                                                        case "TracksBar_fxslot":
                                                            root.selectedChannel.selectPreviousFxBank(root.selectedChannel.selectedSlot.value);
                                                            break;
                                                    }
                                                }
                                            }

                                             ZUI.SectionButton {
                                                visible: !waveformContainer.showWaveform
                                                Layout.fillHeight: true
                                                Layout.minimumWidth: Kirigami.Units.gridUnit * 3
                                                icon.name: "go-last"
                                                onClicked: {
                                                    switch (root.selectedChannel.selectedSlot.className) {
                                                        case "TracksBar_synthslot":
                                                            root.selectedChannel.selectNextSynthBank(root.selectedChannel.selectedSlot.value);
                                                            break;
                                                        case "TracksBar_fxslot":
                                                            root.selectedChannel.selectNextFxBank(root.selectedChannel.selectedSlot.value);
                                                            break;
                                                    }
                                                }
                                            }

                                            ZUI.SectionButton {
                                                visible: !waveformContainer.showWaveform
                                                Layout.fillHeight: true
                                                Layout.minimumWidth: Kirigami.Units.gridUnit * 3
                                                icon.name: "go-previous"
                                                onClicked: {
                                                    switch (root.selectedChannel.selectedSlot.className) {
                                                        case "TracksBar_synthslot":
                                                            root.selectedChannel.selectPreviousSynthPreset(root.selectedChannel.selectedSlot.value);
                                                            break;
                                                        case "TracksBar_fxslot":
                                                            root.selectedChannel.selectPreviousFxPreset(root.selectedChannel.selectedSlot.value);
                                                            break;
                                                    }
                                                }
                                            }

                                            ZUI.SectionButton {
                                                visible: !waveformContainer.showWaveform
                                                Layout.minimumWidth: Kirigami.Units.gridUnit * 3
                                                Layout.fillHeight: true
                                                icon.name: "go-next"
                                                onClicked: {
                                                    switch (root.selectedChannel.selectedSlot.className) {
                                                        case "TracksBar_synthslot":
                                                            root.selectedChannel.selectNextSynthPreset(root.selectedChannel.selectedSlot.value);
                                                            break;
                                                        case "TracksBar_fxslot":
                                                            root.selectedChannel.selectNextFxPreset(root.selectedChannel.selectedSlot.value);
                                                            break;
                                                    }
                                                }
                                            }
                                        }
                                    }                                    

                                    ZUI.SectionGroup {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        mask: true
                                        fallbackPadding: ZUI.Theme.padding
                                        fallbackBackground:  Rectangle {                                             
                                            border.width: 1
                                            border.color: "#ff999999"
                                            radius: ZUI.Theme.radius
                                            color: "#222222"
                                        }

                                        Item {
                                            id: waveItemContainer
                                            anchors.fill: parent

                                            MouseArea {
                                                property var lastMouseX
                                                property var lastMouseY
                                                property int horizontalDrag: 0
                                                property int verticalDrag: 0
                                                property int dragDeltaThreshold: 50
                                                anchors.fill: parent
                                                onPressed: {
                                                    lastMouseX = mouse.x;
                                                    lastMouseY = mouse.y;
                                                }
                                                onMouseXChanged: {
                                                    const dx = mouse.x - lastMouseX;
                                                    if (verticalDrag == 0 && Math.abs(dx) > dragDeltaThreshold) {
                                                        horizontalDrag = Math.floor(dx/dragDeltaThreshold);
                                                    }
                                                }
                                                onMouseYChanged: {
                                                    const dy = lastMouseY - mouse.y;
                                                    if (horizontalDrag == 0 && Math.abs(dy) > dragDeltaThreshold) {
                                                        verticalDrag = Math.floor(dy/dragDeltaThreshold);
                                                    }
                                                }
                                                onReleased: {
                                                    if (horizontalDrag == 0 && verticalDrag == 0) {
                                                        // Drag action did not happen. Perform single press action
                                                        switch (root.selectedChannel.selectedSlot.className) {
                                                            case "TracksBar_sampleslot":
                                                                if (!root.selectedChannel.selectedSlot.isEmpty()) {
                                                                    root.selectedChannel.samples[root.selectedChannel.selectedSlot.value].play()
                                                                }
                                                                break;
                                                            case "TracksBar_synthslot":
                                                                zynqtgui.current_screen_id = "preset";
                                                                break;
                                                        }
                                                    } else {
                                                        if (horizontalDrag > 0) {
                                                            switch (root.selectedChannel.selectedSlot.className) {
                                                                case "TracksBar_synthslot":
                                                                    root.selectedChannel.selectNextSynthPreset(root.selectedChannel.selectedSlot.value);
                                                                    break;
                                                                case "TracksBar_fxslot":
                                                                    root.selectedChannel.selectNextFxPreset(root.selectedChannel.selectedSlot.value);
                                                                    break;
                                                            }

                                                        } else if (horizontalDrag < 0) {
                                                            switch (root.selectedChannel.selectedSlot.className) {
                                                                case "TracksBar_synthslot":
                                                                    root.selectedChannel.selectPreviousSynthPreset(root.selectedChannel.selectedSlot.value);
                                                                    break;
                                                                case "TracksBar_fxslot":
                                                                    root.selectedChannel.selectPreviousFxPreset(root.selectedChannel.selectedSlot.value);
                                                                    break;
                                                            }
                                                        }
                                                        if (verticalDrag > 0) {
                                                            switch (root.selectedChannel.selectedSlot.className) {
                                                                case "TracksBar_synthslot":
                                                                    root.selectedChannel.selectNextSynthBank(root.selectedChannel.selectedSlot.value);
                                                                    break;
                                                                case "TracksBar_fxslot":
                                                                    root.selectedChannel.selectNextFxBank(root.selectedChannel.selectedSlot.value);
                                                                    break;
                                                            }
                                                        } else if (verticalDrag < 0) {
                                                            switch (root.selectedChannel.selectedSlot.className) {
                                                                case "TracksBar_synthslot":
                                                                    root.selectedChannel.selectPreviousSynthBank(root.selectedChannel.selectedSlot.value);
                                                                    break;
                                                                case "TracksBar_fxslot":
                                                                    root.selectedChannel.selectPreviousFxBank(root.selectedChannel.selectedSlot.value);
                                                                    break;
                                                            }
                                                        }

                                                        horizontalDrag = 0;
                                                        verticalDrag = 0;
                                                    }
                                                }
                                                onPressAndHold: {
                                                    switch (root.selectedChannel.selectedSlot.className) {
                                                        case "TracksBar_synthslot":
                                                        case "TracksBar_sampleslot":
                                                        case "TracksBar_fxslot":
                                                            if (!root.selectedChannel.selectedSlot.isEmpty()) {
                                                                zynqtgui.callable_ui_action_simple("SCREEN_EDIT_CONTEXTUAL");
                                                            }
                                                            break;
                                                    }
                                                }
                                                // onClicked: zynqtgui.current_screen_id = "preset"
                                            }

                                            RowLayout {
                                                id: infoBar
                                                property QtObject zynthianLayer: {
                                                    let layer = null;
                                                    if (root.selectedChannel != null) {
                                                        let selectedSlot = root.selectedChannel.selectedSlot.value
                                                        switch (root.selectedChannel.selectedSlot.className) {
                                                        case "TracksBar_synthslot":
                                                            let midiChannel = root.selectedChannel.chainedSounds[selectedSlot];
                                                            if (midiChannel >= 0 && root.selectedChannel.checkIfLayerExists(midiChannel)) {
                                                                layer = zynqtgui.layer.get_layer_by_midi_channel(midiChannel)
                                                            }
                                                            break;
                                                        case "TracksBar_fxslot":
                                                            layer = root.selectedChannel.chainedFx[selectedSlot];
                                                            break;
                                                        case "TracksBar_sketchfxslot":
                                                            layer = root.selectedChannel.chainedSketchFx[selectedSlot];
                                                            break;
                                                        }
                                                        if (layer == undefined) {
                                                            layer = null;
                                                        }
                                                    }
                                                    return layer;
                                                }

                                                anchors.fill: parent
                                                // anchors.margins: Kirigami.Units.smallSpacing
                                                spacing: Kirigami.Units.largeSpacing
                                                visible: !waveformContainer.showWaveform

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    Layout.margins: 2
                                                    spacing: 1
                                                    enabled: infoBar.zynthianLayer != null

                                                    QQC2.Label {
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        Layout.alignment: Qt.AlignVCenter
                                                        font.pointSize: Kirigami.Units.gridUnit * 0.5
                                                        font.family: "Hack"
                                                        text: qsTr(" Synth : %1").arg(infoBar.zynthianLayer != null ? infoBar.zynthianLayer.soundInfo.synth : "--")
                                                    }
                                                    QQC2.Label {
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        Layout.alignment: Qt.AlignVCenter
                                                        font.pointSize: Kirigami.Units.gridUnit * 0.5
                                                        font.family: "Hack"
                                                        text: qsTr("  Bank : %1").arg(infoBar.zynthianLayer != null ? infoBar.zynthianLayer.soundInfo.bank : "--")
                                                    }
                                                    QQC2.Label {
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        Layout.alignment: Qt.AlignVCenter
                                                        font.pointSize: Kirigami.Units.gridUnit * 0.5
                                                        font.family: "Hack"
                                                        text: qsTr("Preset : %1").arg(infoBar.zynthianLayer != null ? infoBar.zynthianLayer.soundInfo.preset : "--")
                                                    }
                                                }

                                                
                                                RowLayout {
                                                    Layout.fillWidth: false
                                                    Layout.fillHeight: true
                                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                                                    Layout.alignment: Qt.AlignVCenter
                                                    spacing: ZUI.Theme.spacing

                                                    ZUI.SectionButton {
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        text: qsTr("Fav")
                                                        display: QQC2.ToolButton.IconOnly
                                                        icon.name: checked ? "starred-symbolic" : "non-starred-symbolic"
                                                        enabled: infoBar.zynthianLayer != null
                                                        checkable: false
                                                        color: checked ? "yellow" : Kirigami.Theme.textColor
                                                        // Bind to current index to properly update when preset changed from other screen
                                                        checked: highlighted
                                                        highlighted: infoBar.zynthianLayer != null
                                                                ? zynqtgui.preset.current_index >= 0 && zynqtgui.preset.current_is_favorite
                                                                : false
                                                        onClicked: {
                                                            if (infoBar.zynthianLayer != null) {
                                                                zynqtgui.preset.current_is_favorite = !zynqtgui.preset.current_is_favorite
                                                            }
                                                        }
                                                    }

                                                    ZUI.SectionButton {
                                                        property int midiChannel: root.selectedChannel != null && root.selectedChannel.chainedSounds != null && root.selectedChannel.selectedSlot != null ? root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlot.value] : -1
                                                        property QtObject synthPassthroughClient: root.selectedChannel != null && midiChannel >= 0 && root.selectedChannel.checkIfLayerExists(midiChannel) && Zynthbox.Plugin.synthPassthroughClients[midiChannel] != null ? Zynthbox.Plugin.synthPassthroughClients[midiChannel] : null
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        visible: root.selectedChannel.selectedSlot != null && root.selectedChannel.selectedSlot.className == "TracksBar_synthslot"
                                                        text: qsTr("Mute")
                                                        enabled: infoBar.zynthianLayer != null
                                                        checkable: false
                                                        checked: highlighted
                                                        highlighted: synthPassthroughClient != null && synthPassthroughClient.muted
                                                        color: checked ? "red" : Kirigami.Theme.textColor
                                                        onClicked: {
                                                            synthPassthroughClient.muted = !synthPassthroughClient.muted
                                                        }
                                                    }

                                                    ZUI.SectionButton {
                                                        property QtObject fxPassthroughClient: root.selectedChannel != null && root.selectedChannel.selectedSlot != null && Zynthbox.Plugin.fxPassthroughClients[root.selectedChannel.id] != null ? Zynthbox.Plugin.fxPassthroughClients[root.selectedChannel.id][root.selectedChannel.selectedSlot.value] : null
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        visible: root.selectedChannel.selectedSlot != null && root.selectedChannel.selectedSlot.className == "TracksBar_fxslot"
                                                        text: qsTr("Bypass")
                                                        enabled: infoBar.zynthianLayer != null
                                                        checkable: false
                                                        checked: highlighted
                                                        highlighted: fxPassthroughClient != null && fxPassthroughClient.bypass
                                                        color: checked ? "red" : Kirigami.Theme.textColor
                                                        onClicked: {
                                                            fxPassthroughClient.bypass = !fxPassthroughClient.bypass
                                                        }
                                                    }                                                    
                                                }
                                            }

                                            Zynthbox.WaveFormItem {
                                                id: waveformItem
                                                anchors.fill: parent
                                                clip: true
                                                opacity: waveformContainer.showWaveform ? 1 : 0
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
                                                    x: progressDots.cppClipObject != null ? ZUI.CommonUtils.fitInWindow(startPositionRelative, waveformItem.relativeStart, waveformItem.relativeEnd) * parent.width * parent.width : 0
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
                                                    ? ZUI.CommonUtils.fitInWindow(startLoopLine.startPositionRelative + loopDeltaRelative, waveformItem.relativeStart, waveformItem.relativeEnd) * parent.width
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
                                                    ? ZUI.CommonUtils.fitInWindow(startLoopLine.startPositionRelative + (progressDots.cppClipObject.rootSlice.lengthSamples / progressDots.cppClipObject.durationSamples), waveformItem.relativeStart, waveformItem.relativeEnd) * parent.width
                                                    : 0
                                                }

                                                // Progress line
                                                Rectangle {
                                                    anchors {
                                                        top: parent.top
                                                        bottom: parent.bottom
                                                    }
                                                    visible: root.visible && root.selectedChannel != null && root.selectedChannel.trackType === "sample-loop" && progressDots.cppClipObject && progressDots.cppClipObject.isPlaying
                                                    color: Kirigami.Theme.highlightColor
                                                    width: Kirigami.Units.smallSpacing
                                                    x: visible ? ZUI.CommonUtils.fitInWindow(progressDots.cppClipObject.position, waveformItem.relativeStart, waveformItem.relativeEnd) * parent.width : 0
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
                                                        x: visible ? Math.floor(ZUI.CommonUtils.fitInWindow(progressEntry.progress, waveformItem.relativeStart, waveformItem.relativeEnd) * parent.width) : 0
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Take remaining available width
                            Item {
                                // color: "yellow"
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                ColumnLayout {
                                    id: patternContainer

                                    property bool showPattern: root.selectedChannel != null && (root.selectedChannel.trackType === "synth" || root.selectedChannel.trackType === "external")

                                    anchors.fill: parent
                                    opacity: patternContainer.showPattern ? 1 : 0

                                    Connections {
                                        target: root
                                        function onSelectedChannelChanged() {
                                            if (root.selectedChannel != null) {
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

                                    ZUI.SectionGroup {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: false
                                        implicitHeight: Kirigami.Units.gridUnit * 2
                                        RowLayout {
                                           anchors.fill: parent
                                           spacing: ZUI.Theme.spacing
                                            Repeater {
                                                id: clipBar
                                                model: Zynthbox.Plugin.sketchpadSlotCount
                                                delegate: ZUI.SectionButton {
                                                    id: clipDelegate
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    // Layout.preferredWidth: Kirigami.Units.gridUnit
                                                    text: root.selectedChannel != null ? qsTr("Clip %1%2").arg(root.selectedChannel.id + 1).arg(String.fromCharCode(clipIndex + 97)) : ""
                                                    // highlighted: clipDelegate.clip.enabled && clipDelegate.patternHasNotes
                                                    highlighted: root.selectedChannel != null && root.selectedChannel.selectedClip === clipIndex
                                                    font.pointSize: 9
                                                    font.capitalization: Font.AllUppercase
                                                    // color: Kirigami.Theme.textColor
                                                    property int clipIndex: model.index
                                                    readonly property bool patternHasNotes: root.sequence.getByClipId(root.selectedChannel.id, index).hasNotes

                                                    property QtObject clip: root.selectedChannel != null ? zynqtgui.sketchpad.song.getClipById(root.selectedChannel.id, zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex, clipDelegate.clipIndex) : null
                                                    property bool clipHasWav: clipDelegate.clip && !clipDelegate.clip.isEmpty
                                                    property QtObject cppClipObject: root.visible && root.selectedChannel != null && root.selectedChannel.trackType === "sample-loop" && clipDelegate.clipHasWav ? Zynthbox.PlayGridManager.getClipById(clipDelegate.clip.cppObjId) : null;
                                                    property QtObject pattern: root.selectedChannel != null ? root.sequence.getByClipId(root.selectedChannel.id, clipIndex) : null
                                                    property bool clipPlaying: clipDelegate.pattern ? clipDelegate.pattern.isPlaying : false
                                                    property int nextBarState: Zynthbox.PlayfieldManager.StoppedState

                                                    onClicked: {
                                                        // if (root.selectedChannel.selectedClip === clipDelegate.clipIndex) {
                                                        //     clipDelegate.clip.enabled = !clipDelegate.clip.enabled;
                                                        // } else {
                                                        //     root.selectedChannel.selectedClip = clipDelegate.clipIndex;
                                                        //     clipDelegate.clip.enabled = true;
                                                        // }

                                                        pageManager.getPage("sketchpad").bottomStack.clipsBar.handleItemClick(root.selectedChannel.id, clipDelegate.clipIndex);
                                                    }
                                                    Kirigami.Icon {
                                                        anchors {
                                                            left: parent.left
                                                            verticalCenter: parent.verticalCenter
                                                            leftMargin: parent.paintedWidth + Kirigami.Units.smallSpacing
                                                        }
                                                        height: parent.height - Kirigami.Units.smallSpacing
                                                        width: height
                                                        color: clipDelegate.color
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
                                    }

                                    ZUI.SectionGroup {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        mask: true
                                        fallbackPadding: ZUI.Theme.padding
                                        fallbackBackground:  Rectangle {
                                            border.width: 1
                                            border.color: "#ff999999"
                                            radius: ZUI.Theme.radius
                                            color: "#222222"
                                        }

                                        Item {
                                            id: patternVisualiserItem
                                            anchors.fill: parent
                                            clip: true

                                            visible: root.pattern != null

                                            Zynthbox.PatternModelVisualiserItem {
                                                id: patternVisualiser
                                                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                                Kirigami.Theme.inherit: false
                                                visible: !root.pattern.isEmpty
                                                anchors.fill: parent
                                                patternModel: root.pattern
                                                backgroundColor: Kirigami.Theme.backgroundColor
                                                foregroundColor: Kirigami.Theme.textColor
                                                fillColor: "transparent"
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
}
