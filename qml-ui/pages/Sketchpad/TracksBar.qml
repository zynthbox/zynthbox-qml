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

import QtQuick 2.15
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

AbstractSketchpadPage {
    id: root
    
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

    enum View {
        Main,
        SYN,
        SMP,
        FX,
        Layers
    }  

    enum SMPView {
        Pitch,
        StartEnd,
        Loop
    }  

    enum SYNView {
        FilterReso,
        Attack,
        Release
    } 

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
            if (slotIndex < Zynthbox.Plugin.sketchpadSlotCount) {
                samplesRow.switchToSlot(slotIndex);
            } else {
                samples2Row.switchToSlot(slotIndex - Zynthbox.Plugin.sketchpadSlotCount);
            }
            break;
        case "TracksBar_sampleslot2":
            samples2Row.switchToSlot(slotIndex);
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
            if (slotIndex < Zynthbox.Plugin.sketchpadSlotCount) {
                samplesRow.switchToSlot(slotIndex, true, onlySelectSlot);
            } else {
                samples2Row.switchToSlot(slotIndex - Zynthbox.Plugin.sketchpadSlotCount, true, onlySelectSlot);
            }
            break;
        case "TracksBar_sampleslot2":
            samples2Row.switchToSlot(slotIndex, true, onlySelectSlot);
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
            } else if (root.selectedChannel.selectedSlot.className === "TracksBar_sampleslot2") {
                slotHasContents = root.selectedChannel.sampleSlotsData[root.selectedChannel.selectedSlot.value + Zynthbox.Plugin.sketchpadSlotCount].cppObjId > -1;
                if (switchIfEmpty && slotHasContents === false) {
                    samples2Row.switchToSlot(0, true, onlySelectSlot);
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
                } else if (root.selectedChannel.trackType === "sample-trig") {
                    samplesRow.switchToSlot(0, true, onlySelectSlot);
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
        if (["TracksBar_synthslot", "TracksBar_sampleslot", "TracksBar_sampleslot2", "TracksBar_sketchslot", "TracksBar_externalslot"].includes(root.selectedChannel.selectedSlot.className)) {
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
            if (root.selectedChannel.trackType == "synth" || root.selectedChannel.trackType == "sample-trig") {
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
                    if (root.selectedChannel.trackType === "sample-trig") {
                        samples2Row.switchToSlot(initialSlotIndex, true, onlySelectSlot);
                    } else {
                        synthsRow.switchToSlot(initialSlotIndex, true, onlySelectSlot);
                    }
                } else if (initialSlotType === 1) {
                    fxRow.switchToSlot(initialSlotIndex, true, onlySelectSlot);
                } else if (initialSlotType === 2) {
                    sketchFxRow.switchToSlot(initialSlotIndex, true, onlySelectSlot);
                }
            }
        }
    }

    function focusNextElementInChain() {
        if(zynqtgui.sketchpad.lastSelectedObj.className.startsWith("TracksBar_")){
            switch(zynqtgui.sketchpad.lastSelectedObj.className) {
                case "TracksBar_item_pitch": _SMPPitchRow.focusNext(); break;
                case "TracksBar_item_startend": _SMPStartEndRow.focusNext(); break;
                case "TracksBar_item_loop": _SMPLoopRow.focusNext(); break;
            }
        }else {
            zynqtgui.sketchpad.selectedTrackId = ZUI.CommonUtils.clamp(zynqtgui.sketchpad.selectedTrackId + 1, 0, Zynthbox.Plugin.sketchpadTrackCount - 1)
            root.sketchpadView.focusChannel(zynqtgui.sketchpad.selectedTrackId)       
        }
    }

    function focusPreviousElementInChain() {
        if(zynqtgui.sketchpad.lastSelectedObj.className.startsWith("TracksBar_")){
           switch(zynqtgui.sketchpad.lastSelectedObj.className) {
                case "TracksBar_item_pitch": _SMPPitchRow.focusPrevious(); break;
                case "TracksBar_item_startend": _SMPStartEndRow.focusPrevious(); break;
                case "TracksBar_item_loop": _SMPLoopRow.focusPrevious(); break;
            }
        }else {
            zynqtgui.sketchpad.selectedTrackId = ZUI.CommonUtils.clamp(zynqtgui.sketchpad.selectedTrackId - 1, 0, Zynthbox.Plugin.sketchpadTrackCount - 1)
            root.sketchpadView.focusChannel(zynqtgui.sketchpad.selectedTrackId)       
        }
    }

    function cuiaCallback(cuia) {
        var returnValue = false;
        // console.log(`TracksBar : cuia: ${cuia}, altButtonPressed: ${zynqtgui.altButtonPressed}, modeButtonPressed: ${zynqtgui.modeButtonPressed}`)
        switch (cuia) {
        case "SWITCH_ARROW_LEFT_RELEASED":
            focusPreviousElementInChain()
            returnValue = true;
            break;

        case "SWITCH_ARROW_RIGHT_RELEASED":
            focusNextElementInChain()
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
                    root.sketchpadView.updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[zynqtgui.sketchpad.lastSelectedObj.value], 0)
                    break;
                case "TracksBar_sampleslot":
                    root.sketchpadView.updateSelectedSampleGain(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                case "TracksBar_sketchslot":
                    root.sketchpadView.updateSelectedSketchGain(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                case "TracksBar_externalslot":
                    break;
                case "TracksBar_fxslot":
                    root.sketchpadView.updateSelectedFxLayerVolume(0, zynqtgui.sketchpad.lastSelectedObj.value)
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
                root.sketchpadView.updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[zynqtgui.sketchpad.lastSelectedObj.value], 1)
                break;
            case "TracksBar_sampleslot":
                root.sketchpadView.updateSelectedSampleGain(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sketchslot":
                root.sketchpadView.updateSelectedSketchGain(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_externalslot":
                break;
            case "TracksBar_fxslot":
                root.sketchpadView.updateSelectedFxLayerVolume(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_item_pitch":
                if(_SMPStack.applyToAll){
                    root.sketchpadView.updateAllSamplePitch(1)
                }else {
                    root.sketchpadView.updateSelectedSamplePitch(1, zynqtgui.sketchpad.lastSelectedObj.value)
                }
                break;
            case "TracksBar_item_startend":
                if(_SMPStack.applyToAll){
                    root.sketchpadView.updateAllSampleStartPositionSamples(1)
                }else {
                    root.sketchpadView.updateSelectedSampleStartPositionSamples(1, zynqtgui.sketchpad.lastSelectedObj.value)
                }
                break;
            case "TracksBar_item_loop":
                if(_SMPStack.applyToAll){
                    root.sketchpadView.updateAllSampleLoopPosition(1, zynqtgui.sketchpad.lastSelectedObj.value)
                }else {
                    root.sketchpadView.updateSelectedSampleLoopPosition(1, zynqtgui.sketchpad.lastSelectedObj.value)
                }
                
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
                root.sketchpadView.updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[zynqtgui.sketchpad.lastSelectedObj.value], -1)
                break;
            case "TracksBar_sampleslot":
                root.sketchpadView.updateSelectedSampleGain(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sketchslot":
                root.sketchpadView.updateSelectedSketchGain(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_externalslot":
                break;
            case "TracksBar_fxslot":
                root.sketchpadView.updateSelectedFxLayerVolume(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_item_pitch":
                if(_SMPStack.applyToAll){
                    root.sketchpadView.updateAllSamplePitch(-1)
                }else {
                    root.sketchpadView.updateSelectedSamplePitch(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                }
                break;
            case "TracksBar_item_startend":
                if(_SMPStack.applyToAll){
                    root.sketchpadView.updateAllSampleStartPositionSamples(-1)
                }else {
                    root.sketchpadView.updateSelectedSampleStartPositionSamples(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                }
                break;
            case "TracksBar_item_loop":
                if(_SMPStack.applyToAll){
                    root.sketchpadView.updateAllSampleLoopPosition(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                }else {
                    root.sketchpadView.updateSelectedSampleLoopPosition(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                }
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
                    root.sketchpadView.updateSelectedChannelSlotLayerCutoff(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                case "TracksBar_sampleslot":
                    break;
                case "TracksBar_sketchslot":
                    break;
                case "TracksBar_externalslot":
                    break;
                case "TracksBar_fxslot":
                    root.sketchpadView.updateSelectedChannelFxLayerCutoff(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                case "TracksBar_sketchfxslot":
                    root.sketchpadView.updateSelectedChannelSketchFxLayerCutoff(0, zynqtgui.sketchpad.lastSelectedObj.value)
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
                root.sketchpadView.updateSelectedChannelSlotLayerCutoff(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sampleslot":
                break;
            case "TracksBar_sketchslot":
                break;
            case "TracksBar_externalslot":
                break;
            case "TracksBar_fxslot":
                root.sketchpadView.updateSelectedChannelFxLayerCutoff(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sketchfxslot":
                root.sketchpadView.updateSelectedChannelSketchFxLayerCutoff(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_item_startend":
                if(_SMPStack.applyToAll){
                    root.sketchpadView.updateAllSampleLengthSamples(1)
                }else {
                    root.sketchpadView.updateSelectedSampleLengthSamples(1, zynqtgui.sketchpad.lastSelectedObj.value)
                }
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
                root.sketchpadView.updateSelectedChannelSlotLayerCutoff(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sampleslot":
                break;
            case "TracksBar_sketchslot":
                break;
            case "TracksBar_externalslot":
                break;
            case "TracksBar_fxslot":
                root.sketchpadView.updateSelectedChannelFxLayerCutoff(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sketchfxslot":
                root.sketchpadView.updateSelectedChannelSketchFxLayerCutoff(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_item_startend":
                if(_SMPStack.applyToAll){
                    root.sketchpadView.updateAllSampleLengthSamples(-1)
                }else {
                    root.sketchpadView.updateSelectedSampleLengthSamples(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                }
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
                    root.sketchpadView.updateSelectedChannelSlotLayerResonance(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                case "TracksBar_sampleslot":
                    break;
                case "TracksBar_sketchslot":
                    break;
                case "TracksBar_externalslot":
                    break;
                case "TracksBar_fxslot":
                    root.sketchpadView.updateSelectedChannelFxLayerResonance(0, zynqtgui.sketchpad.lastSelectedObj.value)
                    break;
                case "TracksBar_sketchfxslot":
                    root.sketchpadView.updateSelectedChannelSketchFxLayerResonance(0, zynqtgui.sketchpad.lastSelectedObj.value)
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
                root.sketchpadView.updateSelectedChannelSlotLayerResonance(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sampleslot":
                break;
            case "TracksBar_sketchslot":
                break;
            case "TracksBar_externalslot":
                break;
            case "TracksBar_fxslot":
                root.sketchpadView.updateSelectedChannelFxLayerResonance(1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sketchfxslot":
                root.sketchpadView.updateSelectedChannelSketchFxLayerResonance(1, zynqtgui.sketchpad.lastSelectedObj.value)
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
                root.sketchpadView.updateSelectedChannelSlotLayerResonance(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sampleslot":
                break;
            case "TracksBar_sketchslot":
                break;
            case "TracksBar_externalslot":
                break;
            case "TracksBar_fxslot":
                root.sketchpadView.updateSelectedChannelFxLayerResonance(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                break;
            case "TracksBar_sketchfxslot":
                root.sketchpadView.updateSelectedChannelSketchFxLayerResonance(-1, zynqtgui.sketchpad.lastSelectedObj.value)
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
            }else {
                focusNextElementInChain()
                returnValue = true;
            }
            break;
        case "KNOB3_DOWN":
            if (zynqtgui.modeButtonPressed) {
                zynqtgui.ignoreNextModeButtonPress = true;
                root.pickPreviousSlot();
                returnValue = true;
            }else {
                focusPreviousElementInChain()
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
            case "TracksBar_sampleslot2":
                bottomStack.slotsBar.handleItemClick("sample-trig2")
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

    TrackStyleSelector {
        id: trackStyleSelector
    }

    contentItem: ZUI.ThreeColumnView {
        
        leftTab: BottomStackTabs {}

        rightTab: ZUI.SectionGroup {
            ColumnLayout {
                anchors.fill: parent
                spacing: ZUI.Theme.spacing

                ZUI.SectionButton{
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "Track-Slots"
                    checked: highlighted
                    highlighted: _tracksBarStack.currentView === TracksBar.View.Main
                    onClicked: _tracksBarStack.setView(TracksBar.View.Main)
                }

                ZUI.SectionButton{
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "SYN"
                    checked: highlighted
                    highlighted: _tracksBarStack.currentView === TracksBar.View.SYN
                    onClicked: _tracksBarStack.setView(TracksBar.View.SYN)
                }

                ZUI.SectionButton{
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "SMP"
                    checked: highlighted
                    highlighted: _tracksBarStack.currentView === TracksBar.View.SMP
                    onClicked: _tracksBarStack.setView(TracksBar.View.SMP)
                }

                 ZUI.SectionButton{
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "FX-Chain"
                    checked: highlighted
                    highlighted: _tracksBarStack.currentView === TracksBar.View.FX
                    onClicked: _tracksBarStack.setView(TracksBar.View.FX)
                }

                ZUI.SectionButton{
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "Layers"
                    checked: highlighted
                    highlighted: _tracksBarStack.currentView === TracksBar.View.PAT
                    onClicked: _tracksBarStack.setView(TracksBar.View.PAT)
                }
            }
        }

        middleTab: QQC2.Pane {

            contentItem: StackLayout {
                id: _tracksBarStack
                property int currentView: TracksBar.View.Main
                currentIndex : currentView

                function setView(view) {
                    _tracksBarStack.currentView = view
                    _tracksBarStack.currentIndex = _tracksBarStack.currentView
                }
               
                ColumnLayout {
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

                            QQC2.ButtonGroup {
                                buttons: tabButtons.children
                            }

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
                                    TrackClearOnSwitchDialog {
                                        id: trackClearOnSwitchDialog
                                    }
                                }

                                ZUI.SectionButton {
                                    Layout.fillWidth: false
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                    Layout.fillHeight: true
                                    checked: highlighted
                                    highlighted: root.selectedChannel != null && ["synth", "sample-trig"].includes(root.selectedChannel.trackType)
                                    text: qsTr("Sketch")
                                    onClicked: {
                                        // Don't switch (or do slot selection type things) if we're already there
                                        if (["synth", "sample-trig"].includes(root.selectedChannel.trackType) == false) {
                                            if (root.selectedChannel.trackRackType == Zynthbox.ZynthboxBasics.SynthRackType) {
                                                trackClearOnSwitchDialog.switchTrackType(root.selectedChannel, "synth");
                                            } else if (root.selectedChannel.trackRackType == Zynthbox.ZynthboxBasics.SampleRackType) {
                                                trackClearOnSwitchDialog.switchTrackType(root.selectedChannel, "sample-trig");
                                            } else {
                                                trackClearOnSwitchDialog.switchTrackType(root.selectedChannel, "synth");
                                            }
                                        }
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
                                        trackClearOnSwitchDialog.switchTrackType(root.selectedChannel, "sample-loop");
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
                                        trackClearOnSwitchDialog.switchTrackType(root.selectedChannel, "external");
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                        ZUI.SectionGroup {
                            Layout.fillHeight: true
                            visible: root.selectedChannel != null && ["synth", "sample-trig"].includes(root.selectedChannel.trackType)
                            RowLayout {
                                anchors.fill: parent
                                spacing: ZUI.Theme.spacing
                                ZUI.SectionButton {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                    Layout.fillHeight: true
                                    checked: highlighted
                                    highlighted: root.selectedChannel != null && root.selectedChannel.trackType === "synth"
                                    text: qsTr("Synthrack")
                                    onClicked: {
                                        if (root.selectedChannel.trackType != "synth") {
                                            trackClearOnSwitchDialog.switchTrackType(root.selectedChannel, "synth");
                                        }
                                    }
                                }
                                ZUI.SectionButton {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                    Layout.fillHeight: true
                                    checked: highlighted
                                    highlighted: root.selectedChannel != null && root.selectedChannel.trackType === "sample-trig"
                                    text: qsTr("Samplerack")
                                    onClicked: {
                                        if (root.selectedChannel.trackType != "sample-trig") {
                                            trackClearOnSwitchDialog.switchTrackType(root.selectedChannel, "sample-trig");
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        ZUI.SectionGroup {
                            Layout.fillHeight: true
                            visible: root.selectedChannel != null && ["synth", "sample-trig"].includes(root.selectedChannel.trackType)

                            RowLayout {
                                anchors.fill: parent
                                spacing: ZUI.Theme.spacing

                                QQC2.Switch {
                                    Layout.fillHeight: true
                                    padding: 4
                                    visible: root.selectedChannel ? root.selectedChannel.trackType === "synth" : false
                                    checked: root.selectedChannel && root.selectedChannel.trackStyle === "one-to-one"
                                    text: qsTr("5 Columns")
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
                                QQC2.Button {
                                    Layout.fillHeight: true
                                    visible: root.selectedChannel ? root.selectedChannel.trackType === "sample-trig" : false
                                    text: root.selectedChannel ? qsTr("Rack Layout: %1").arg(trackStyleName(root.selectedChannel.trackStyle)) : ""
                                    function trackStyleName(trackStyle) {
                                        switch (trackStyle) {
                                        case "everything":
                                            return qsTr("Everything");
                                        case "one-to-one":
                                            return qsTr("5 Columns");
                                        case "drums":
                                            return qsTr("Drumrack");
                                        case "2-low-3-high":
                                            return qsTr("Upper/Lower");
                                        case "10-octaves":
                                            return qsTr("10 Octaves");
                                        default:
                                            return qsTr("Manual");
                                        }
                                    }
                                    onClicked: {
                                        trackStyleSelector.pickTrackStyle(root.selectedChannel);
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
                            visible: root.selectedChannel != null && ["synth", "sample-loop", "external"].includes(root.selectedChannel.trackType)

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
                                visible: root.selectedChannel != null && ["synth", "sample-trig"].includes(root.selectedChannel.trackType)
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
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            visible: root.selectedChannel != null && root.selectedChannel.trackType == "sample-trig"
                            TrackSlotsData {
                                id: samples2Row
                                anchors.fill: parent
                                slotData: root.selectedChannel != null ? root.selectedChannel.sampleSlotsData : []
                                slotType: "sample-trig2"
                                showSlotTypeLabel: true
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
                                visible: root.selectedChannel != null && (["synth", "sample-trig"].includes(root.selectedChannel.trackType) || (root.selectedChannel.trackType == "external" && root.selectedChannel.externalSettings && root.selectedChannel.externalSettings.audioSource != ""))
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
                                } else if (selectedSlot.className === "TracksBar_sampleslot2") {
                                    waveformContainer.clip = root.selectedChannel.samples[selectedSlot.value + Zynthbox.Plugin.sketchpadSlotCount];
                                } else if (selectedSlot.className === "TracksBar_sketchslot") {
                                    waveformContainer.clip = root.selectedChannel.getClipsModelById(selectedSlot.value).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                                } else {
                                    waveformContainer.clip = null;
                                }
                                // We show the waveform container for all selected slots where there is a sample associated
                                waveformContainer.showWaveform = ["TracksBar_sampleslot", "TracksBar_sampleslot2", "TracksBar_sketchslot"].indexOf(root.selectedChannel.selectedSlot.className) >= 0
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
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            ZUI.SectionGroup {
                                anchors.fill: parent
                                mask: waveformContainer.showWaveform
                                fallbackPadding: ZUI.Theme.padding
                                fallbackBackground:  Rectangle {                                             
                                    border.width: 1
                                    border.color: "#ff999999"
                                    radius: ZUI.Theme.radius
                                    color: "#222222"
                                }

                                ColumnLayout {
                                    id: waveItemContainer
                                    anchors.fill: parent

                                    ZUI.SectionGroup {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: false
                                        implicitHeight: Kirigami.Units.gridUnit * 2
                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: ZUI.Theme.spacing

                                            QQC2.Label {
                                                Layout.fillWidth: true
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
                                            Item {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
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

                                                onPressAndHold: {
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

                                                onPressAndHold: {
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
                                        }
                                    } 

                                    Item {     
                                        Layout.fillHeight: true
                                        Layout.fillWidth: true
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
                                                        case "TracksBar_sampleslot2":
                                                            if (!root.selectedChannel.selectedSlot.isEmpty()) {
                                                                root.selectedChannel.samples[root.selectedChannel.selectedSlot.value + Zynthbox.Plugin.sketchpadSlotCount].play()
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
                                                    case "TracksBar_sampleslot2":
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
                                                // Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                                                Layout.alignment: Qt.AlignVCenter
                                                spacing: ZUI.Theme.spacing

                                                // ZUI.SectionButton {
                                                //     property int midiChannel: root.selectedChannel != null && root.selectedChannel.chainedSounds != null && root.selectedChannel.selectedSlot != null ? root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlot.value] : -1
                                                //     property QtObject synthPassthroughClient: root.selectedChannel != null && midiChannel >= 0 && root.selectedChannel.checkIfLayerExists(midiChannel) && Zynthbox.Plugin.synthPassthroughClients[midiChannel] != null ? Zynthbox.Plugin.synthPassthroughClients[midiChannel] : null
                                                //     Layout.fillWidth: true
                                                //     Layout.fillHeight: true
                                                //     visible: root.selectedChannel.selectedSlot != null && root.selectedChannel.selectedSlot.className == "TracksBar_synthslot"
                                                //     text: qsTr("Mute")
                                                //     enabled: infoBar.zynthianLayer != null
                                                //     checkable: false
                                                //     checked: highlighted
                                                //     highlighted: synthPassthroughClient != null && synthPassthroughClient.muted
                                                //     color: checked ? "red" : Kirigami.Theme.textColor
                                                //     onClicked: {
                                                //         synthPassthroughClient.muted = !synthPassthroughClient.muted
                                                //     }
                                                // }

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

                                                ZUI.SectionButton {
                                                    Layout.fillWidth: false
                                                    Layout.preferredWidth: parent.height
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
                                                    progressDots.playbackPositions = root.visible && ["synth", "sample-trig"].includes(root.selectedChannel.trackType) && progressDots.cppClipObject
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
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            id: patternContainer

                            readonly property bool showPattern: root.selectedChannel != null && ["synth", "sample-trig", "external"].includes(root.selectedChannel.trackType)

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
                                anchors.fill: parent
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
                                            text: root.selectedChannel != null ? qsTr("Clip %1%2").arg(root.selectedChannel.id + 1).arg(String.fromCharCode(clipIndex + 97)) : ""
                                            // highlighted: clipDelegate.clip.enabled && clipDelegate.patternHasNotes
                                            highlighted: root.selectedChannel != null && root.selectedChannel.selectedClip === clipIndex
                                            font.pointSize: 9
                                            font.capitalization: Font.AllUppercase
                                            property int clipIndex: model.index
                                            readonly property bool patternHasNotes: root.sequence.getByClipId(root.selectedChannel.id, index).hasNotes

                                            property QtObject clip: root.selectedChannel != null ? zynqtgui.sketchpad.song.getClipById(root.selectedChannel.id, zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex, clipDelegate.clipIndex) : null
                                            readonly property bool clipHasWav: clipDelegate.clip && !clipDelegate.clip.isEmpty
                                            readonly property QtObject cppClipObject: root.visible && root.selectedChannel != null && root.selectedChannel.trackType === "sample-loop" && clipDelegate.clipHasWav ? Zynthbox.PlayGridManager.getClipById(clipDelegate.clip.cppObjId) : null;
                                            readonly property QtObject pattern: root.selectedChannel != null ? root.sequence.getByClipId(root.selectedChannel.id, clipIndex) : null
                                            readonly property bool clipPlaying: clipDelegate.pattern ? clipDelegate.pattern.isPlaying : false
                                            property int nextBarState: Zynthbox.PlayfieldManager.StoppedState

                                            onClicked: {
                                                // if (root.selectedChannel.selectedClip === clipDelegate.clipIndex) {
                                                //     clipDelegate.clip.enabled = !clipDelegate.clip.enabled;
                                                // } else {
                                                //     root.selectedChannel.selectedClip = clipDelegate.clipIndex;
                                                //     clipDelegate.clip.enabled = true;
                                                // }

                                                root.sketchpadView.bottomStack.clipsBar.handleItemClick(root.selectedChannel.id, clipDelegate.clipIndex);
                                            }
                                            Kirigami.Icon {
                                                anchors {
                                                    left: parent.left
                                                    verticalCenter: parent.verticalCenter
                                                    leftMargin: Kirigami.Units.smallSpacing
                                                }
                                                height: 16
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
                                                    leftMargin: Kirigami.Units.smallSpacing
                                                }
                                                height: 16
                                                width: height
                                                // Visible if we are running playback, the clip is playing, and we are going to stop the clip at the top of the next bar
                                                visible: Zynthbox.SyncTimer.timerRunning && clipDelegate.clipPlaying === true && clipDelegate.nextBarState == Zynthbox.PlayfieldManager.StoppedState && Zynthbox.PlayGridManager.metronomeBeat16th % 4 === 0
                                                source: "media-playback-stop-symbolic"
                                            }

                                            padding: 1
                                            leftPadding: padding
                                            topPadding: padding
                                            rightPadding: padding
                                            bottomPadding: padding
                                            contentItem : ColumnLayout {
                                                spacing: ZUI.Theme.spacing
                                                QQC2.Label {
                                                    Layout.margins: 4
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                                                    font: clipDelegate.font
                                                    text: clipDelegate.text
                                                    color: clipDelegate.color
                                                    horizontalAlignment: Qt.AlignHCenter
                                                }

                                                ZUI.SectionGroup {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    mask: false
                                                    background: null 
                                                    padding: 0

                                                    Zynthbox.PatternModelVisualiserItem {
                                                        id: visualiser
                                                        property QtObject pattern: root.sequence && root.selectedChannel ? root.sequence.getByClipId(root.selectedChannel.id, index) : null

                                                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                                                        Kirigami.Theme.inherit: false
                                                        visible: !pattern.isEmpty
                                                        anchors.fill: parent
                                                        patternModel: pattern
                                                        backgroundColor: Kirigami.Theme.backgroundColor
                                                        foregroundColor: Kirigami.Theme.textColor
                                                        fillColor: "black"
                                                        Rectangle { // Progress
                                                            anchors {
                                                                top: parent.top
                                                                bottom: parent.bottom
                                                            }
                                                            visible: root.visible &&
                                                                    root.sequence &&
                                                                    root.sequence.isPlaying &&
                                                                    visualiser.pattern &&
                                                                    visualiser.pattern.enabled
                                                            color: Kirigami.Theme.highlightColor
                                                            width: widthFactor // this way the progress rect is the same width as a step
                                                            property double widthFactor: visible && visualiser.pattern ? parent.width / (visualiser.pattern.width * visualiser.pattern.bankLength) : 1
                                                            x: visible && visualiser.pattern ? visualiser.pattern.bankPlaybackPosition * widthFactor : 0
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

                ColumnLayout {
                    spacing: ZUI.Theme.sectionSpacing
                    enabled: root.selectedChannel.trackType !== "external"
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit *  2
                        Layout.minimumHeight: Kirigami.Units.gridUnit *  2
                        
                        RowLayout {
                            anchors.fill: parent
                            spacing: ZUI.Theme.spacing

                            ZUI.SectionGroup {
                                Layout.fillHeight: true

                                QQC2.ButtonGroup {
                                    buttons: _SYNButtonsRow.children
                                }

                                RowLayout {
                                    id: _SYNButtonsRow
                                    anchors.fill: parent
                                    spacing: ZUI.Theme.spacing

                                    ZUI.SectionButton {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        text: "Filter/Reso"
                                        checked: highlighted
                                        highlighted: _SYNStack.currentView === TracksBar.SYNView.FilterReso
                                        onClicked: _SYNStack.setView(TracksBar.SYNView.FilterReso)
                                    }
                                    ZUI.SectionButton {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        text: "Attack"
                                        checked: highlighted
                                        highlighted: _SYNStack.currentView === TracksBar.SYNView.Attack
                                        onClicked: _SYNStack.setView(TracksBar.SYNView.Attack)
                                    }
                                    ZUI.SectionButton {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        text: "Release"
                                        checked: highlighted
                                        highlighted: _SYNStack.currentView === TracksBar.SYNView.Release
                                        onClicked: _SYNStack.setView(TracksBar.SYNView.Release)
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }

                            ZUI.SectionGroup {
                                Layout.fillHeight: true

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: ZUI.Theme.spacing

                                    ZUI.SectionButton {
                                        checkable: true
                                        checked:_SYNStack.applyToAll
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        text: "All"
                                        onToggled: _SYNStack.applyToAll = checked
                                    }
                                }
                            }
                        }
                    }
                    
                    ZUI.SectionGroup {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        fallbackBackground: Rectangle {
                            Kirigami.Theme.inherit: false
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                            color: Kirigami.Theme.backgroundColor
                            opacity: 0.1
                        }  

                        StackLayout {
                            id: _SYNStack
                            visible: enabled
                            anchors.fill: parent
                            property int currentView: TracksBar.SYNView.FilterReso
                            currentIndex : currentView

                            property bool applyToAll: false
                            function setView(view) {
                                var slotIndex = _SYNStack.currentSlotIndex
                                _SYNStack.currentView = view
                                _SYNStack.currentIndex = _SYNStack.currentView

                                _SYNStack.children[_SYNStack.currentIndex].handleClick(slotIndex)
                            }

                            RowLayout {
                                id: _SYNFilterResoRow
                                spacing: ZUI.Theme.cellSpacing
                                property int globalFilter: 0
                                property int globalReso: 0

                                // function focusNext() {
                                //     let index = Math.min(_SMPStack.currentSlotIndex+1,  root.selectedChannel.trackType === "sample-trig"? 9 : 4)
                                //     handleClick(index)
                                // }

                                // function focusPrevious() {
                                //     let index = Math.max(_SMPStack.currentSlotIndex-1, 0)
                                //     handleClick(index)
                                // }
                                
                                // function handleClick(slot) { 
                                //     root.switchToSlot("sample", slot);
                                //     zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                //     zynqtgui.sketchpad.lastSelectedObj.setTo("TracksBar_item_pitch", slot, _pitchRepeater.itemAt(slot), root.selectedChannel);
                                // }

                                Repeater {
                                    id: _filterResoRepeater
                                    model: Zynthbox.Plugin.sketchpadSlotCount
                                    delegate: ZUI.CellControl {
                                        id: _filterResoDelegate
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        highlighted: (index === root.selectedChannel.selectedSlotRow || _SYNStack.applyToAll) && enabled
                                        enabled: root.selectedChannel.synthSlotsData[index].length > 0

                                        contentItem: RowLayout {
                                            spacing: ZUI.Theme.sectionSpacing

                                            AbstractCellLayout {
                                                id: _cutoffControl
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                readonly property QtObject c_ctrl : root.selectedChannel.filterCutoffControllers[index]
                                                enabled: c_ctrl ? c_ctrl.controlsCount > 0 : false
                                                title: "Cutoff"
                                                text: root.selectedChannel.synthSlotsData[index]
                                                text2: c_ctrl.value + "%"
                                                control1: VolumeControl {
                                                    id: volumeControl
                                                    slider {
                                                        from: _cutoffControl.c_ctrl ? _cutoffControl.c_ctrl.value_min : 0
                                                        to: _cutoffControl.c_ctrl ? _cutoffControl.c_ctrl.value_max : 0
                                                        stepSize: _cutoffControl.c_ctrl ? _cutoffControl.c_ctrl.step_size : 0
                                                    }
                                                    Binding {
                                                        target: volumeControl.slider
                                                        property: "value"
                                                        value: _cutoffControl.c_ctrl ? _cutoffControl.c_ctrl.value : 0
                                                    }

                                                    tickLabelSet : ({"0":"0", "50":"50", "100":"100"})   
                                                    onValueChanged: {
                                                        if(_SYNStack.applyToAll)
                                                        {
                                                            // _SMPLoopRow.globalLoopPosition = slider.value
                                                        }else {
                                                            _cutoffControl.c_ctrl.value = volumeControl.slider.value
                                                        }
                                                    } 
                                                }
                                                underlay: MouseArea {
                                                    anchors.fill: parent
                                                    onPressed: volumeControl.mouseArea.handlePressed(mouse)
                                                    onReleased: volumeControl.mouseArea.released(mouse)
                                                    onPressAndHold: volumeControl.mouseArea.pressAndHold(mouse)
                                                    onClicked: volumeControl.mouseArea.clicked(mouse)
                                                    onMouseXChanged: volumeControl.mouseArea.mouseXChanged(mouse)
                                                    onMouseYChanged: volumeControl.mouseArea.mouseYChanged(mouse)
                                                }
                                            }

                                            AbstractCellLayout {
                                                id: _resControl
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                readonly property QtObject r_ctrl : root.selectedChannel.filterResonanceControllers[index]
                                                enabled: r_ctrl ? r_ctrl.controlsCount > 0 : false
                                                title: "Res"
                                                text: root.selectedChannel.synthSlotsData[index]
                                                text2: r_ctrl.value + "%"
                                                control1: VolumeControl {
                                                    id: _resSlider
                                                    slider {
                                                        from: _resControl.r_ctrl.value_min
                                                        to: _resControl.r_ctrl.value_max
                                                        stepSize: _resControl.r_ctrl.step_size
                                                    }

                                                    Binding {
                                                        target: _resSlider.slider
                                                        property: "value"
                                                        value: _resControl.r_ctrl ? _resControl.r_ctrl.value : 0
                                                    }

                                                    tickLabelSet : ({"0":"0", "50":"50", "100":"100"})   
                                                    onValueChanged: {
                                                        if(_SYNStack.applyToAll)
                                                        {
                                                            // _SMPLoopRow.globalLoopPosition = slider.value
                                                        }else {
                                                            _resControl.r_ctrl.value = _resSlider.slider.value
                                                        }
                                                    } 
                                                }

                                                underlay: MouseArea {
                                                    anchors.fill: parent
                                                    onPressed: _resSlider.mouseArea.handlePressed(mouse)
                                                    onReleased: _resSlider.mouseArea.released(mouse)
                                                    onPressAndHold: _resSlider.mouseArea.pressAndHold(mouse)
                                                    onClicked: _resSlider.mouseArea.clicked(mouse)
                                                    onMouseXChanged: _resSlider.mouseArea.mouseXChanged(mouse)
                                                    onMouseYChanged: _resSlider.mouseArea.mouseYChanged(mouse)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                id: _SYNAttackRow
                                spacing: ZUI.Theme.cellSpacing
                                property int globalAmpAttack: 0
                                property int globalFilterAttack: 0

                                // function focusNext() {
                                //     let index = Math.min(_SMPStack.currentSlotIndex+1,  root.selectedChannel.trackType === "sample-trig"? 9 : 4)
                                //     handleClick(index)
                                // }

                                // function focusPrevious() {
                                //     let index = Math.max(_SMPStack.currentSlotIndex-1, 0)
                                //     handleClick(index)
                                // }
                                
                                // function handleClick(slot) { 
                                //     root.switchToSlot("sample", slot);
                                //     zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                //     zynqtgui.sketchpad.lastSelectedObj.setTo("TracksBar_item_pitch", slot, _pitchRepeater.itemAt(slot), root.selectedChannel);
                                // }

                                Repeater {
                                    id: _attackRepeater
                                    model: Zynthbox.Plugin.sketchpadSlotCount
                                    delegate: ZUI.CellControl {
                                        id: _attackDelegate
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        highlighted: (index === root.selectedChannel.selectedSlotRow || _SYNStack.applyToAll) && enabled
                                        enabled: root.selectedChannel.synthSlotsData[index].length > 0

                                        contentItem: RowLayout {
                                            spacing: ZUI.Theme.sectionSpacing
                                            AbstractCellLayout {
                                                id: _control2
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                enabled: r_ctrl ? r_ctrl.controlsCount > 0 : false
                                                readonly property QtObject r_ctrl : root.selectedChannel.ampAttackControllers[index]
                                                title: "Amp"
                                                text: root.selectedChannel.synthSlotsData[index]
                                                text2: r_ctrl.value + "%"
                                                control1: VolumeControl {
                                                    id: _volControl2
                                                    slider {
                                                        from: _control2.r_ctrl.value_min
                                                        to: _control2.r_ctrl.value_max
                                                        stepSize: _control2.r_ctrl.step_size
                                                    }

                                                    Binding {
                                                        target: _volControl2.slider
                                                        property: "value"
                                                        value: _control2.r_ctrl ? _control2.r_ctrl.value : 0
                                                    }

                                                    tickLabelSet : ({"0":"0", "50":"50", "100":"100"})   
                                                    onValueChanged: {
                                                        if(_SYNStack.applyToAll)
                                                        {
                                                            // _SMPLoopRow.globalLoopPosition = slider.value
                                                        }else {
                                                            _control2.r_ctrl.value = _volControl2.slider.value
                                                        }
                                                    } 
                                                }

                                                underlay: MouseArea {
                                                    anchors.fill: parent
                                                    onPressed: _volControl2.mouseArea.handlePressed(mouse)
                                                    onReleased: _volControl2.mouseArea.released(mouse)
                                                    onPressAndHold: _volControl2.mouseArea.pressAndHold(mouse)
                                                    onClicked: _volControl2.mouseArea.clicked(mouse)
                                                    onMouseXChanged: _volControl2.mouseArea.mouseXChanged(mouse)
                                                    onMouseYChanged: _volControl2.mouseArea.mouseYChanged(mouse)
                                                }
                                            }

                                            AbstractCellLayout {
                                                id: _control1
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                readonly property QtObject c_ctrl : root.selectedChannel.filterAttackControllers[index]
                                                enabled: c_ctrl ? c_ctrl.controlsCount > 0 : false
                                                title: "Filter"
                                                text: root.selectedChannel.synthSlotsData[index]
                                                text2: c_ctrl.value + "%"
                                                control1: VolumeControl {
                                                    id: volumeControl
                                                    slider {
                                                        from: _control1.c_ctrl ? _control1.c_ctrl.value_min : 0
                                                        to: _control1.c_ctrl ? _control1.c_ctrl.value_max : 0
                                                        stepSize: _control1.c_ctrl ? _control1.c_ctrl.step_size : 0
                                                    }
                                                    Binding {
                                                        target: volumeControl.slider
                                                        property: "value"
                                                        value: _control1.c_ctrl ? _control1.c_ctrl.value : 0
                                                    }

                                                    tickLabelSet : ({"0":"0", "50":"50", "100":"100"})   
                                                    onValueChanged: {
                                                        if(_SYNStack.applyToAll)
                                                        {
                                                            // _SMPLoopRow.globalLoopPosition = slider.value
                                                        }else {
                                                            _control1.c_ctrl.value = volumeControl.slider.value
                                                        }
                                                    } 
                                                }
                                                underlay: MouseArea {
                                                    anchors.fill: parent
                                                    onPressed: volumeControl.mouseArea.handlePressed(mouse)
                                                    onReleased: volumeControl.mouseArea.released(mouse)
                                                    onPressAndHold: volumeControl.mouseArea.pressAndHold(mouse)
                                                    onClicked: volumeControl.mouseArea.clicked(mouse)
                                                    onMouseXChanged: volumeControl.mouseArea.mouseXChanged(mouse)
                                                    onMouseYChanged: volumeControl.mouseArea.mouseYChanged(mouse)
                                                }
                                            }

                                        }
                                    }
                                }
                            }

                            RowLayout {
                                id: _SYNReleaseRow
                                spacing: ZUI.Theme.cellSpacing
                                property int globalAmpRelease: 0
                                property int globalFilterRelease: 0

                                // function focusNext() {
                                //     let index = Math.min(_SMPStack.currentSlotIndex+1,  root.selectedChannel.trackType === "sample-trig"? 9 : 4)
                                //     handleClick(index)
                                // }

                                // function focusPrevious() {
                                //     let index = Math.max(_SMPStack.currentSlotIndex-1, 0)
                                //     handleClick(index)
                                // }
                                
                                // function handleClick(slot) { 
                                //     root.switchToSlot("sample", slot);
                                //     zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                //     zynqtgui.sketchpad.lastSelectedObj.setTo("TracksBar_item_pitch", slot, _pitchRepeater.itemAt(slot), root.selectedChannel);
                                // }

                                Repeater {
                                    id: _releaseRepeater
                                    model: Zynthbox.Plugin.sketchpadSlotCount
                                    delegate: ZUI.CellControl {
                                        id: _attackDelegate
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        highlighted: (index === root.selectedChannel.selectedSlotRow || _SYNStack.applyToAll) && enabled
                                        enabled: root.selectedChannel.synthSlotsData[index].length > 0

                                        contentItem: RowLayout {
                                            spacing: ZUI.Theme.sectionSpacing
                                            AbstractCellLayout {
                                                id: _control2
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                enabled: r_ctrl ? r_ctrl.controlsCount > 0 : false
                                                readonly property QtObject r_ctrl : root.selectedChannel.ampReleaseControllers[index]
                                                title: "Amp"
                                                text: root.selectedChannel.synthSlotsData[index]
                                                text2: r_ctrl.value + "%"
                                                control1: VolumeControl {
                                                    id: _volControl2
                                                    slider {
                                                        from: _control2.r_ctrl.value_min
                                                        to: _control2.r_ctrl.value_max
                                                        stepSize: _control2.r_ctrl.step_size
                                                    }

                                                    Binding {
                                                        target: _volControl2.slider
                                                        property: "value"
                                                        value: _control2.r_ctrl ? _control2.r_ctrl.value : 0
                                                    }

                                                    tickLabelSet : ({"0":"0", "50":"50", "100":"100"})   
                                                    onValueChanged: {
                                                        if(_SYNStack.applyToAll)
                                                        {
                                                            // _SMPLoopRow.globalLoopPosition = slider.value
                                                        }else {
                                                            _control2.r_ctrl.value = _volControl2.slider.value
                                                        }
                                                    } 
                                                }

                                                underlay: MouseArea {
                                                    anchors.fill: parent
                                                    onPressed: _volControl2.mouseArea.handlePressed(mouse)
                                                    onReleased: _volControl2.mouseArea.released(mouse)
                                                    onPressAndHold: _volControl2.mouseArea.pressAndHold(mouse)
                                                    onClicked: _volControl2.mouseArea.clicked(mouse)
                                                    onMouseXChanged: _volControl2.mouseArea.mouseXChanged(mouse)
                                                    onMouseYChanged: _volControl2.mouseArea.mouseYChanged(mouse)
                                                }
                                            }

                                            AbstractCellLayout {
                                                id: _control1
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                readonly property QtObject c_ctrl : root.selectedChannel.filterReleaseControllers[index]
                                                enabled: c_ctrl ? c_ctrl.controlsCount > 0 : false
                                                title: "Filter"
                                                text: root.selectedChannel.synthSlotsData[index]
                                                text2: c_ctrl.value + "%"
                                                control1: VolumeControl {
                                                    id: volumeControl
                                                    slider {
                                                        from: _control1.c_ctrl ? _control1.c_ctrl.value_min : 0
                                                        to: _control1.c_ctrl ? _control1.c_ctrl.value_max : 0
                                                        stepSize: _control1.c_ctrl ? _control1.c_ctrl.step_size : 0
                                                    }
                                                    Binding {
                                                        target: volumeControl.slider
                                                        property: "value"
                                                        value: _control1.c_ctrl ? _control1.c_ctrl.value : 0
                                                    }

                                                    tickLabelSet : ({"0":"0", "50":"50", "100":"100"})   
                                                    onValueChanged: {
                                                        if(_SYNStack.applyToAll)
                                                        {
                                                            // _SMPLoopRow.globalLoopPosition = slider.value
                                                        }else {
                                                            _control1.c_ctrl.value = volumeControl.slider.value
                                                        }
                                                    } 
                                                }
                                                underlay: MouseArea {
                                                    anchors.fill: parent
                                                    onPressed: volumeControl.mouseArea.handlePressed(mouse)
                                                    onReleased: volumeControl.mouseArea.released(mouse)
                                                    onPressAndHold: volumeControl.mouseArea.pressAndHold(mouse)
                                                    onClicked: volumeControl.mouseArea.clicked(mouse)
                                                    onMouseXChanged: volumeControl.mouseArea.mouseXChanged(mouse)
                                                    onMouseYChanged: volumeControl.mouseArea.mouseYChanged(mouse)
                                                }
                                            }

                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    spacing: ZUI.Theme.sectionSpacing
                    enabled: root.selectedChannel.trackType !== "external"
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit *  2
                        Layout.minimumHeight: Kirigami.Units.gridUnit *  2
                        
                        RowLayout {
                            anchors.fill: parent
                            spacing: ZUI.Theme.spacing

                            ZUI.SectionGroup {
                                Layout.fillHeight: true

                                QQC2.ButtonGroup {
                                    buttons: _SMPButtonsRow.children
                                }

                                RowLayout {
                                    id: _SMPButtonsRow
                                    anchors.fill: parent
                                    spacing: ZUI.Theme.spacing

                                    ZUI.SectionButton {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        text: "Pitch"
                                        checked: highlighted
                                        highlighted: _SMPStack.currentView === TracksBar.SMPView.Pitch
                                        onClicked: _SMPStack.setView(TracksBar.SMPView.Pitch)
                                    }
                                    ZUI.SectionButton {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        text: "Start/End"
                                        checked: highlighted
                                        highlighted: _SMPStack.currentView === TracksBar.SMPView.StartEnd
                                        onClicked: _SMPStack.setView(TracksBar.SMPView.StartEnd)
                                    }
                                    ZUI.SectionButton {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        text: "Loop"
                                        checked: highlighted
                                        highlighted: _SMPStack.currentView === TracksBar.SMPView.Loop
                                        onClicked: _SMPStack.setView(TracksBar.SMPView.Loop)
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }

                            ZUI.SectionGroup {
                                Layout.fillHeight: true

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: ZUI.Theme.spacing

                                    ZUI.SectionButton {
                                        checkable: true
                                        checked:_SMPStack.applyToAll
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        text: "All"
                                        onToggled: _SMPStack.applyToAll = checked
                                    }
                                }
                            }
                        }
                    }

                    ZUI.SectionGroup {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        fallbackBackground: Rectangle {
                            Kirigami.Theme.inherit: false
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                            color: Kirigami.Theme.backgroundColor
                            opacity: 0.1
                        }  

                        StackLayout {
                            id: _SMPStack
                            visible: enabled
                            anchors.fill: parent
                            property int currentView: TracksBar.SMPView.Pitch
                            currentIndex : currentView

                            property bool applyToAll: false
                            readonly property int currentSlotIndex: root.selectedChannel && root.selectedChannel.selectedSlot ? (root.selectedChannel.selectedSlot.className === "TracksBar_sampleslot" ? root.selectedChannel.selectedSlot.value : root.selectedChannel.selectedSlot.value + Zynthbox.Plugin.sketchpadSlotCount) : -1
                            readonly property var sampleCache : [
                                root.selectedChannel.samples[0],
                                root.selectedChannel.samples[1],
                                root.selectedChannel.samples[2],
                                root.selectedChannel.samples[3],
                                root.selectedChannel.samples[4],
                                root.selectedChannel.samples[5],
                                root.selectedChannel.samples[6],
                                root.selectedChannel.samples[7],
                                root.selectedChannel.samples[8],
                                root.selectedChannel.samples[9]]

                            function setView(view) {
                                var slotIndex = _SMPStack.currentSlotIndex
                                _SMPStack.currentView = view
                                _SMPStack.currentIndex = _SMPStack.currentView

                                _SMPStack.children[_SMPStack.currentIndex].handleClick(slotIndex)
                            }

                            RowLayout {
                                id: _SMPPitchRow
                                spacing: ZUI.Theme.cellSpacing
                                property int globalPitch: 0

                                function focusNext() {
                                    let index = Math.min(_SMPStack.currentSlotIndex+1,  root.selectedChannel.trackType === "sample-trig"? 9 : 4)
                                    handleClick(index)
                                }

                                function focusPrevious() {
                                    let index = Math.max(_SMPStack.currentSlotIndex-1, 0)
                                    handleClick(index)
                                }
                                
                                function handleClick(slot) { 
                                    root.switchToSlot("sample", slot);
                                    zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                    zynqtgui.sketchpad.lastSelectedObj.setTo("TracksBar_item_pitch", slot, _pitchRepeater.itemAt(slot), root.selectedChannel);
                                }

                                Repeater {
                                    id: _pitchRepeater
                                    model: Zynthbox.Plugin.sketchpadSlotCount * 2
                                    delegate: AbstractCellLayout {
                                        id: _pitchDelegate

                                        readonly property QtObject controlObj: _SMPStack.sampleCache[index]
                                        readonly property QtObject clipObj: controlObj ? Zynthbox.PlayGridManager.getClipById(controlObj.cppObjId) : null 
                                        readonly property QtObject sliceObj: clipObj ? clipObj.selectedSliceObject : null
                                        enabled: clipObj && contentItem.visible

                                        contentItem.visible: root.selectedChannel.trackType === "sample-trig" ? true : index < 5
                                        background.opacity: contentItem.visible ? 1 : 0.5

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        highlighted: (index === _SMPStack.currentSlotIndex || _SMPStack.applyToAll) && enabled
                                        title: "S"+ (index+1)
                                        text: controlObj? controlObj.path.split("/").pop() : ""
                                        text2: sliceObj ? sliceObj.pitch.toFixed(2) : ""
                                        onDoubleClicked: sliceObj.pitch = controlObj.initialPitch
                                        onClicked: _SMPPitchRow.handleClick(index)

                                        function setValue(value){
                                            if(!sliceObj)
                                                return;

                                            sliceObj.pitch = value
                                        }

                                        Connections {
                                            target: _SMPPitchRow
                                            onGlobalPitchChanged: setValue(_SMPPitchRow.globalPitch)
                                        }

                                        control1: VolumeControl {
                                            id: volumeControl
                                            tickLabelSet : ({"0":"0", "48":"48", "-48":"-48"})                                           
                                            slider {
                                                from: -48
                                                to: 48
                                                stepSize: 1
                                            }

                                            onDoubleClicked: _pitchDelegate.doubleClicked()
                                            onClicked: _pitchDelegate.clicked()
                                            onValueChanged: {
                                                if(_SMPStack.applyToAll){
                                                    _SMPPitchRow.globalPitch = slider.value
                                                }else{
                                                    _pitchDelegate.setValue(slider.value)
                                                }
                                            }

                                            Binding {
                                                target: volumeControl.slider
                                                property: "value"
                                                value: sliceObj ? sliceObj.pitch : 0   
                                            }
                                        }

                                        underlay: MouseArea {
                                            anchors.fill: parent
                                            onPressed: control1.mouseArea.handlePressed(mouse)
                                            onReleased: control1.mouseArea.released(mouse)
                                            onPressAndHold: control1.mouseArea.pressAndHold(mouse)
                                            onClicked: control1.mouseArea.clicked(mouse)
                                            onMouseXChanged: control1.mouseArea.mouseXChanged(mouse)
                                            onMouseYChanged: control1.mouseArea.mouseYChanged(mouse)
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                id: _SMPStartEndRow
                                spacing: ZUI.Theme.cellSpacing
                                property int globalStartPosition: 0
                                property int globalLengthPosition: 0

                                function focusNext() {
                                    let index = Math.min(_SMPStack.currentSlotIndex+1,  root.selectedChannel.trackType === "sample-trig"? 9 : 4)
                                    handleClick(index)
                                }

                                function focusPrevious() {
                                    let index = Math.max(_SMPStack.currentSlotIndex-1, 0)
                                    handleClick(index)
                                }

                                function handleClick(slot) { 
                                    root.switchToSlot("sample", slot);
                                    zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                    zynqtgui.sketchpad.lastSelectedObj.setTo("TracksBar_item_startend", slot, _startEndRepeater.itemAt(slot), root.selectedChannel);
                                }

                                Repeater {
                                    id: _startEndRepeater
                                    model: Zynthbox.Plugin.sketchpadSlotCount * 2
                                    delegate: AbstractCellLayout {
                                        id: _startEndDelegate

                                        readonly property QtObject controlObj: _SMPStack.sampleCache[index]
                                        readonly property QtObject clipObj: controlObj ? Zynthbox.PlayGridManager.getClipById(controlObj.cppObjId) : null 
                                        readonly property QtObject sliceObj: clipObj ? clipObj.selectedSliceObject : null

                                        enabled: clipObj && contentItem.visible
                                        contentItem.visible: root.selectedChannel.trackType === "sample-trig" ? true : index < 5
                                        background.opacity: contentItem.visible ? 1 : 0.5

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        highlighted: (index === _SMPStack.currentSlotIndex || _SMPStack.applyToAll) && enabled
                                        title: "S"+ (index+1)
                                        text: controlObj ? controlObj.path.split("/").pop() : ""
                                        text2: enabled ? Math.round(_rangeSlider.first.value) +"%-"+Math.round(_rangeSlider.realStopValue)+"%" : "-"

                                        onDoubleClicked: {
                                            if(!sliceObj)
                                                return;

                                            sliceObj.startPositionSamples = 0
                                            sliceObj.lengthSamples = clipObj.durationSamples
                                        }
                                        onClicked: _SMPStartEndRow.handleClick(index)

                                        function setStartPosition(value){
                                            if(!sliceObj)
                                                return;

                                            sliceObj.startPositionSamples = Math.round((value*clipObj.durationSamples)/100)
                                        }

                                        function setLengthPosition(value){
                                            if(!sliceObj)
                                                return;

                                            let endPos = Math.round((value*clipObj.durationSamples)/100)
                                            sliceObj.lengthSamples = endPos - sliceObj.startPositionSamples
                                        }

                                        Connections {
                                            target: _SMPStartEndRow
                                            onGlobalStartPositionChanged: setStartPosition(_SMPStartEndRow.globalStartPosition)
                                            onGlobalLengthPositionChanged: setLengthPosition(_SMPStartEndRow.globalLengthPosition)
                                        }

                                        control1: Item {
                                                
                                            RangeSlider {
                                                id: _rangeSlider                                        
                                                anchors.fill: parent
                                                anchors.margins: Kirigami.Units.smallSpacing + 6

                                                from: 0
                                                to: 100

                                                middlePosition: sliceObj ? 1-(sliceObj.loopDeltaSamples/sliceObj.lengthSamples) : 0
                                                topValueOverflows: realStopValue > 100

                                                readonly property int stopPosition: sliceObj ? Math.min(sliceObj.startPositionSamples+sliceObj.lengthSamples, clipObj.durationSamples) : 0
                                                readonly property int realStopValue: sliceObj ? (100 * (sliceObj.startPositionSamples+sliceObj.lengthSamples))/clipObj.durationSamples : 0

                                                first.value: sliceObj ? (100*sliceObj.startPositionSamples)/clipObj.durationSamples : 0 
                                                first.onMoved: {
                                                    if(_SMPStack.applyToAll){                                                        
                                                        _SMPStartEndRow.globalStartPosition = first.value
                                                    }else {
                                                        _startEndDelegate.setStartPosition(first.value)
                                                    } 
                                                }               

                                                second.value: sliceObj ? (100*stopPosition)/clipObj.durationSamples : 0
                                                second.onMoved: {
                                                    if(_SMPStack.applyToAll){
                                                        _SMPStartEndRow.globalLengthPosition = second.value
                                                    }else {
                                                        _startEndDelegate.setLengthPosition(second.value)
                                                    }
                                                }

                                                MouseArea {    
                                                    // enabled: !_startEndDelegate.highlighted  
                                                    // gesturePolicy: TapHandler.ReleaseWithinBounds
                                                    // grabPermissions: PointerHandler.ApprovesTakeOverByAnything                                     
                                                    // onTapped: _startEndDelegate.clicked()
                                                    // onDoubleTapped: _startEndDelegate.doubleClicked()
                                                    anchors.fill: parent
                                                    onPressed: {
                                                        _startEndDelegate.clicked()
                                                        mouse.accepted = false
                                                    }
                                                }                  
                                            } 
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                id: _SMPLoopRow
                                spacing: ZUI.Theme.cellSpacing
                                property int globalLoopPosition : 0

                                function focusNext() {
                                    let index = Math.min(_SMPStack.currentSlotIndex+1,  root.selectedChannel.trackType === "sample-trig"? 9 : 4)
                                    handleClick(index)
                                }

                                function focusPrevious() {
                                    let index = Math.max(_SMPStack.currentSlotIndex-1, 0)
                                    handleClick(index)
                                }

                                function handleClick(slot) { 
                                    root.switchToSlot("sample", slot, false);
                                    zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                    zynqtgui.sketchpad.lastSelectedObj.setTo("TracksBar_item_loop", slot, _loopRepeater.itemAt(slot), root.selectedChannel);
                                }

                                Repeater {
                                    id: _loopRepeater
                                    model: Zynthbox.Plugin.sketchpadSlotCount * 2
                                    delegate: AbstractCellLayout {
                                        id: _loopDelegate

                                        readonly property QtObject controlObj: _SMPStack.sampleCache[index]
                                        readonly property QtObject clipObj: controlObj ? Zynthbox.PlayGridManager.getClipById(controlObj.cppObjId) : null 
                                        readonly property QtObject sliceObj: clipObj ? clipObj.selectedSliceObject : null

                                        enabled: clipObj && contentItem.visible
                                        contentItem.visible: root.selectedChannel.trackType === "sample-trig" ? true : index < 5 
                                        background.opacity: contentItem.visible ? 1 : 0.5

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        highlighted: (index === _SMPStack.currentSlotIndex || _SMPStack.applyToAll) && enabled
                                        title: "S"+ (index+1)
                                        text: controlObj ? controlObj.path.split("/").pop() : ""
                                        text2: volumeControl.slider.value.toFixed(2)+("%")
                                        onClicked: _SMPLoopRow.handleClick(index)
                                        onDoubleClicked: {
                                            if(!sliceObj)
                                                return

                                            _loopDelegate.setValue(50) 
                                        }

                                        function setValue(value){
                                            if(!sliceObj)
                                                return

                                            sliceObj.loopDeltaSamples = sliceObj.lengthSamples * (value/100)
                                        }

                                        Connections{
                                            target: _SMPLoopRow
                                            onGlobalLoopPositionChanged: setValue(_SMPLoopRow.globalLoopPosition)
                                        }

                                        control1: VolumeControl {
                                            id: volumeControl
                                            tickLabelSet : ({"0":"0", "50":"50", "100":"100"})   
                                            onValueChanged: {
                                                if(_SMPStack.applyToAll)
                                                {
                                                    _SMPLoopRow.globalLoopPosition = slider.value
                                                }else {
                                                    _loopDelegate.setValue(slider.value)
                                                }
                                            }                                            
                                            
                                            onDoubleClicked: _loopDelegate.doubleClicked()
                                            onClicked: _loopDelegate.clicked()

                                            slider {
                                                from: 0
                                                to: 100
                                            }
                                            Binding {
                                                target: volumeControl.slider
                                                property: "value"
                                                value: sliceObj ? (100*sliceObj.loopDeltaSamples)/sliceObj.lengthSamples : 0
                                            }
                                        }
                                        underlay: MouseArea {
                                            anchors.fill: parent
                                            onPressed: control1.mouseArea.handlePressed(mouse)
                                            onReleased: control1.mouseArea.released(mouse)
                                            onPressAndHold: control1.mouseArea.pressAndHold(mouse)
                                            onClicked: control1.mouseArea.clicked(mouse)
                                            onMouseXChanged: control1.mouseArea.mouseXChanged(mouse)
                                            onMouseYChanged: control1.mouseArea.mouseYChanged(mouse)
                                        }
                                    }
                                }
                            }
                        } 
                    }
                }
                Item {}
                Item {}
            }
        }      
    }

    component RangeSlider : QQC2.RangeSlider {
        id: _rangeSlider                                        
        orientation: Qt.Vertical 
        property double middlePosition: 0.5
        property bool topValueOverflows: false
       
        background: Item {
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.height
                width: Kirigami.Units.gridUnit * 0.5
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                implicitWidth: Kirigami.Units.gridUnit
                radius: ZUI.Theme.radius
                color: Kirigami.Theme.backgroundColor
                border.color: Qt.darker(Kirigami.Theme.backgroundColor, 3)
                
                // Highlight range between handles
                Rectangle {
                    visible: enabled
                    y: _rangeSlider.second.visualPosition * parent.height
                    height: (_rangeSlider.first.visualPosition - _rangeSlider.second.visualPosition) * parent.height
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    radius: ZUI.Theme.radius
                    color: Kirigami.Theme.highlightColor 
                    // opacity: 0.2

                    Rectangle {
                        height: 1
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 1
                        color: Kirigami.Theme.textColor
                        y: parent.height * _rangeSlider.middlePosition
                    }
                }
                
            }
        }

        first.handle: Item {
            visible: enabled
            y: (_rangeSlider.first.visualPosition * (_rangeSlider.availableHeight)) - height
            x: _rangeSlider.width/2 - width/2
            implicitWidth: Kirigami.Units.gridUnit * 0.5
            implicitHeight: 22  

            Kirigami.Icon {
                anchors.right: parent.left
                anchors.verticalCenter: parent.bottom
                implicitHeight: 22
                implicitWidth: 22
                source: Qt.resolvedUrl("../../../img/right-arrow.svg")
                color: Kirigami.Theme.textColor
            }
        }

        second.handle: Item {
            visible: enabled && !_rangeSlider.topValueOverflows
            y: (_rangeSlider.second.visualPosition * (_rangeSlider.availableHeight))
            x: _rangeSlider.width/2 - width/2
            implicitWidth: Kirigami.Units.gridUnit * 0.5
            implicitHeight: 22

            Kirigami.Icon {
                anchors.left: parent.right
                anchors.verticalCenter: parent.top
                implicitHeight: 22
                implicitWidth: 22
                source: Qt.resolvedUrl("../../../img/left-arrow.svg")
                color: Kirigami.Theme.textColor
            }
        }                                       
    } 
}
