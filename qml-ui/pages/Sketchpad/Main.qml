/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

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
import QtQuick.Window 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4 as Extras
import QtQml.Models 2.10
import org.kde.kirigami 2.4 as Kirigami
import io.zynthbox.components 1.0 as Zynthbox
import org.kde.plasma.core 2.0 as PlasmaCore

import Zynthian 1.0 as Zynthian

Zynthian.ScreenPage {
    id: root

    property alias zlScreen: root
    property alias bottomStack: bottomStack
    readonly property QtObject song: zynqtgui.sketchpad.song
    property bool displaySceneButtons: zynqtgui.sketchpad.displaySceneButtons
    property bool displayTrackButtons: false
    property bool showOccupiedSlotsHeader: false
    property QtObject selectedChannel: null
    Timer {
        id: selectedChannelThrottle
        interval: 1; running: false; repeat: false;
        onTriggered: {
            root.selectedChannel = applicationWindow().selectedChannel;
        }
    }
    Connections {
        target: applicationWindow()
        onSelectedChannelChanged: selectedChannelThrottle.restart()
    }

    /**
     * Update layer volume of selected fx slot
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateSelectedFxLayerVolume(sign, slot=-1) {
        if (slot === -1) {
            slot = root.selectedChannel.selectedFxSlotRow
        }
        var fxName = root.selectedChannel.chainedFxNames[slot]
        var fxLayer = root.selectedChannel.chainedFx[slot]

        if (fxLayer != null) {
            var fxPassthroughClient = Zynthbox.Plugin.fxPassthroughClients[root.selectedChannel.id][slot]

            function valueSetter(value) {
                root.selectedChannel.set_passthroughValue("fxPassthrough", slot, "dryWetMixAmount", Zynthian.CommonUtils.clamp(value, 0, 2))
                applicationWindow().showOsd({
                                                parameterName: "fxlayer_volume",
                                                description: qsTr("%1 Dry/Wet Mix").arg(fxName),
                                                start: 0,
                                                stop: 2,
                                                step: 0.01,
                                                defaultValue: 1.0,
                                                currentValue: fxPassthroughClient.dryWetMixAmount,
                                                startLabel: " ",
                                                stopLabel: " ",
                                                valueLabel: qsTr("%1% Dry / %2% Wet").arg((Math.min(1, 2-fxPassthroughClient.dryWetMixAmount)*100).toFixed(0)).arg((Math.min(1.0, fxPassthroughClient.dryWetMixAmount)*100).toFixed(0)),
                                                setValueFunction: valueSetter,
                                                showValueLabel: true,
                                                showResetToDefault: true,
                                                showVisualZero: true
                                            })
            }
            valueSetter(fxPassthroughClient.dryWetMixAmount + sign * 0.01)
        } else {
            applicationWindow().showMessageDialog(qsTr("Selected slot does not have any FX"), 2000)
        }
    }
    /**
     * Update layer volume of selected channel
     * @param midiChannel The layer midi channel whose volume needs to be updated
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateSelectedChannelLayerVolume(midiChannel, sign) {
        var synthName = ""
        var synthPassthroughClient
        try {
            synthPassthroughClient = Zynthbox.Plugin.synthPassthroughClients[midiChannel]
            synthName = root.selectedChannel.getLayerNameByMidiChannel(midiChannel).split('>')[0]
        } catch(e) {}
        var chainedSounds = root.selectedChannel.chainedSounds;
        var slot = -1;
        for (let i = 0; i < 5; ++i) {
            if (chainedSounds[i] === midiChannel) {
                slot = i;
                break;
            }
        }

        function valueSetter(value) {
            synthPassthroughClient.dryGainHandler.gainAbsolute = Zynthian.CommonUtils.clamp(value, 0, 1)
            applicationWindow().showOsd({
                                            parameterName: "layer_volume",
                                            description: qsTr("%1 Volume").arg(synthName),
                                            start: 0,
                                            stop: 1,
                                            step: 0.01,
                                            defaultValue: synthPassthroughClient.dryGainHandler.absoluteGainAtZeroDb,
                                            currentValue: synthPassthroughClient.dryGainHandler.gainAbsolute,
                                            startLabel: "-24 dB",
                                            stopLabel: "+24 dB",
                                            valueLabel: qsTr("%1 dB").arg(synthPassthroughClient.dryGainHandler.gainDb.toFixed(2)),
                                            setValueFunction: valueSetter,
                                            showValueLabel: true,
                                            showResetToDefault: true,
                                            showVisualZero: true
                                        })
        }

        if (synthPassthroughClient != null && root.selectedChannel.checkIfLayerExists(midiChannel)) {
            valueSetter(synthPassthroughClient.dryGainHandler.gainAbsolute + sign * 0.01)
        } else {
            applicationWindow().showMessageDialog(qsTr("Selected slot does not have any synth"), 2000)
        }
    }
    /**
     * Update selected sample gain
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateSelectedSampleGain(sign, slot=-1) {
        if (slot === -1) {
            slot = root.selectedChannel.selectedSlotRow
        }
        let sample = root.selectedChannel.samples[slot];
        let clipCppObj = Zynthbox.PlayGridManager.getClipById(sample.cppObjId);
        function valueSetter(value) {
            if (sample != null && !sample.isEmpty) {
                clipCppObj.rootSlice.gainHandler.gainAbsolute = Zynthian.CommonUtils.clamp(value, 0, 1)
                applicationWindow().showOsd({
                                                parameterName: "sample_gain",
                                                description: qsTr("%1 Gain").arg(sample.path.split("/").pop()),
                                                start: 0,
                                                stop: 1,
                                                step: 0.01,
                                                defaultValue: clipCppObj.rootSlice.gainHandler.absoluteGainAtZeroDb,
                                                currentValue: parseFloat(clipCppObj.rootSlice.gainHandler.gainAbsolute),
                                                startLabel: "-24 dB",
                                                stopLabel: "24 dB",
                                                valueLabel: qsTr("%1 dB").arg(clipCppObj.rootSlice.gainHandler.gainDb.toFixed(2)),
                                                setValueFunction: valueSetter,
                                                showValueLabel: true,
                                                showResetToDefault: true,
                                                showVisualZero: true
                                            })
            } else {
                applicationWindow().showMessageDialog(qsTr("Selected slot does not have any sample"), 2000)
            }
        }
        valueSetter(clipCppObj.rootSlice.gainHandler.gainAbsolute + sign*0.01)
    }
    /**
     * Update selected sketch gain
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateSelectedSketchGain(sign, slot=-1) {
        if (slot === -1) {
            slot = root.selectedChannel.selectedSlotRow
        }
        var clip = root.selectedChannel.getClipsModelById(slot).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
        let clipCppObj = Zynthbox.PlayGridManager.getClipById(clip.cppObjId);
        function valueSetter(value) {
            if (clip != null && !clip.isEmpty) {
                clipCppObj.rootSlice.gainHandler.gainAbsolute = Zynthian.CommonUtils.clamp(value, 0, 1)
                applicationWindow().showOsd({
                                                parameterName: "clip_gain",
                                                description: qsTr("%1 Gain").arg(clip.path.split("/").pop()),
                                                start: 0,
                                                stop: 1,
                                                step: 0.01,
                                                defaultValue: clipCppObj.rootSlice.gainHandler.absoluteGainAtZeroDb,
                                                currentValue: parseFloat(clipCppObj.rootSlice.gainHandler.gainAbsolute),
                                                startLabel: "-24 dB",
                                                stopLabel: "24 dB",
                                                valueLabel: qsTr("%1 dB").arg(clipCppObj.rootSlice.gainHandler.gainDb.toFixed(2)),
                                                setValueFunction: valueSetter,
                                                showValueLabel: true,
                                                showResetToDefault: true,
                                                showVisualZero: true
                                            })
            } else {
                applicationWindow().showMessageDialog(qsTr("Selected slot does not have any sketch"), 2000)
            }
        }
        valueSetter(clipCppObj.rootSlice.gainHandler.gainAbsolute + sign*0.01)
    }
    /**
     * Update selected channel pan
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by 1
     */
    function updateSelectedChannelPan(sign) {
        updateChannelPan(sign, root.selectedChannel.id)
    }
    /**
     * Update channel pan
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by 1
     */
    function updateChannelPan(sign, channelId) {
        applicationWindow().channels[channelId].pan = Zynthian.CommonUtils.clamp(applicationWindow().channels[channelId].pan + sign * 0.05, -1, 1)
    }
    /**
     * Update layer filter cutoff for selected channel
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateSelectedChannelSlotLayerCutoff(sign, slot=-1) {
        if (slot === -1) {
            slot = root.selectedChannel.selectedSlotRow
        }
        var synthName = ""
        var midiChannel = root.selectedChannel.chainedSounds[slot]
        var controller = root.selectedChannel.filterCutoffControllers[slot]
        try {
            synthName = root.selectedChannel.getLayerNameByMidiChannel(midiChannel).split('>')[0]
        } catch(e) {}

        function valueSetter(value) {
            if (controller != null && controller.controlsCount > 0) {
                controller.value = Zynthian.CommonUtils.clamp(value, controller.value_min, controller.value_max)
                applicationWindow().showOsd({
                                                parameterName: "layer_filter_cutoff",
                                                description: qsTr("%1 Filter Cutoff").arg(synthName),
                                                start: controller.value_min,
                                                stop: controller.value_max,
                                                step: controller.step_size,
                                                defaultValue: null,
                                                currentValue: controller.value,
                                                startLabel: qsTr("%1").arg(controller.value_min),
                                                stopLabel: qsTr("%1").arg(controller.value_max),
                                                valueLabel: qsTr("%1").arg(controller.value),
                                                setValueFunction: valueSetter,
                                                showValueLabel: true,
                                                showResetToDefault: false,
                                                showVisualZero: false
                                            })
            } else if (root.selectedChannel.checkIfLayerExists(midiChannel)) {
                applicationWindow().showMessageDialog(qsTr("%1 does not have Filter Cutoff controller").arg(synthName), 2000)
            }
        }

        valueSetter(controller.value + sign * controller.step_size)
    }
    /**
     * Update layer filter resonance for selected channel
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateSelectedChannelSlotLayerResonance(sign, slot=-1) {
        if (slot === -1) {
            slot = root.selectedChannel.selectedSlotRow
        }
        var synthName = ""
        var midiChannel = root.selectedChannel.chainedSounds[slot]
        var controller = root.selectedChannel.filterResonanceControllers[slot]
        try {
            synthName = root.selectedChannel.getLayerNameByMidiChannel(midiChannel).split('>')[0]
        } catch(e) {}

        function valueSetter(value) {
            if (controller != null && controller.controlsCount > 0) {
                controller.value = Zynthian.CommonUtils.clamp(value, controller.value_min, controller.value_max)
                applicationWindow().showOsd({
                                                parameterName: "layer_filter_resonance",
                                                description: qsTr("%1 Filter Resonance").arg(synthName),
                                                start: controller.value_min,
                                                stop: controller.value_max,
                                                step: controller.step_size,
                                                defaultValue: null,
                                                currentValue: controller.value,
                                                startLabel: qsTr("%1").arg(controller.value_min),
                                                stopLabel: qsTr("%1").arg(controller.value_max),
                                                valueLabel: qsTr("%1").arg(controller.value),
                                                setValueFunction: valueSetter,
                                                showValueLabel: true,
                                                showResetToDefault: false,
                                                showVisualZero: false
                                            })
            } else if (root.selectedChannel.checkIfLayerExists(midiChannel)) {
                applicationWindow().showMessageDialog(qsTr("%1 does not have Filter Resonance controller").arg(synthName), 2000)
            }
        }

        valueSetter(controller.value + sign * controller.step_size)
    }
    /**
     * Update layer filter cutoff for selected channel
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateSelectedChannelFxLayerCutoff(sign, slot=-1) {
        if (slot === -1) {
            slot = root.selectedChannel.selectedSlot.value
        }
        var synthName = root.selectedChannel.chainedFxNames[slot].split('>')[0]
        var midiChannel = root.selectedChannel.chainedFx[slot]
        var controller = root.selectedChannel.fxFilterCutoffControllers[slot]

        function valueSetter(value) {
            if (controller != null && controller.controlsCount > 0) {
                controller.value = Zynthian.CommonUtils.clamp(value, controller.value_min, controller.value_max)
                applicationWindow().showOsd({
                                                parameterName: "layer_fx_filter_cutoff",
                                                description: qsTr("%1 Filter Cutoff").arg(synthName),
                                                start: controller.value_min,
                                                stop: controller.value_max,
                                                step: controller.step_size,
                                                defaultValue: null,
                                                currentValue: controller.value,
                                                startLabel: qsTr("%1").arg(controller.value_min),
                                                stopLabel: qsTr("%1").arg(controller.value_max),
                                                valueLabel: qsTr("%1").arg(controller.value),
                                                setValueFunction: valueSetter,
                                                showValueLabel: true,
                                                showResetToDefault: false,
                                                showVisualZero: false
                                            })
            } else if (root.selectedChannel.checkIfLayerExists(midiChannel)) {
                applicationWindow().showMessageDialog(qsTr("%1 does not have Filter Cutoff controller").arg(synthName), 2000)
            }
        }

        valueSetter(controller.value + sign * controller.step_size)
    }
    /**
     * Update layer filter resonance for selected channel
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateSelectedChannelFxLayerResonance(sign, slot=-1) {
        if (slot === -1) {
            slot = root.selectedChannel.selectedSlot.value
        }
        var synthName = root.selectedChannel.chainedFxNames[slot].split('>')[0]
        var midiChannel = root.selectedChannel.chainedFx[slot]
        var controller = root.selectedChannel.fxFilterResonanceControllers[slot]

        function valueSetter(value) {
            if (controller != null && controller.controlsCount > 0) {
                controller.value = Zynthian.CommonUtils.clamp(value, controller.value_min, controller.value_max)
                applicationWindow().showOsd({
                                                parameterName: "layer_fx_filter_resonance",
                                                description: qsTr("%1 Filter Resonance").arg(synthName),
                                                start: controller.value_min,
                                                stop: controller.value_max,
                                                step: controller.step_size,
                                                defaultValue: null,
                                                currentValue: controller.value,
                                                startLabel: qsTr("%1").arg(controller.value_min),
                                                stopLabel: qsTr("%1").arg(controller.value_max),
                                                valueLabel: qsTr("%1").arg(controller.value),
                                                setValueFunction: valueSetter,
                                                showValueLabel: true,
                                                showResetToDefault: false,
                                                showVisualZero: false
                                            })
            } else if (root.selectedChannel.checkIfLayerExists(midiChannel)) {
                applicationWindow().showMessageDialog(qsTr("%1 does not have Filter Resonance controller").arg(synthName), 2000)
            }
        }

        valueSetter(controller.value + sign * controller.step_size)
    }
    /**
     * Update layer filter cutoff for selected channel
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateSelectedChannelSketchFxLayerCutoff(sign, slot=-1) {
        if (slot === -1) {
            slot = root.selectedChannel.selectedSlot.value
        }
        var synthName = root.selectedChannel.chainedSketchFxNames[slot].split('>')[0]
        var midiChannel = root.selectedChannel.chainedSketchFx[slot]
        var controller = root.selectedChannel.sketchFxFilterCutoffControllers[slot]

        function valueSetter(value) {
            if (controller != null && controller.controlsCount > 0) {
                controller.value = Zynthian.CommonUtils.clamp(value, controller.value_min, controller.value_max)
                applicationWindow().showOsd({
                                                parameterName: "layer_fx_filter_cutoff",
                                                description: qsTr("%1 Filter Cutoff").arg(synthName),
                                                start: controller.value_min,
                                                stop: controller.value_max,
                                                step: controller.step_size,
                                                defaultValue: null,
                                                currentValue: controller.value,
                                                startLabel: qsTr("%1").arg(controller.value_min),
                                                stopLabel: qsTr("%1").arg(controller.value_max),
                                                valueLabel: qsTr("%1").arg(controller.value),
                                                setValueFunction: valueSetter,
                                                showValueLabel: true,
                                                showResetToDefault: false,
                                                showVisualZero: false
                                            })
            } else if (root.selectedChannel.checkIfLayerExists(midiChannel)) {
                applicationWindow().showMessageDialog(qsTr("%1 does not have Filter Cutoff controller").arg(synthName), 2000)
            }
        }

        valueSetter(controller.value + sign * controller.step_size)
    }
    /**
     * Update layer filter resonance for selected channel
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateSelectedChannelSketchFxLayerResonance(sign, slot=-1) {
        if (slot === -1) {
            slot = root.selectedChannel.selectedSlot.value
        }
        var synthName = root.selectedChannel.chainedSketchFxNames[slot].split('>')[0]
        var midiChannel = root.selectedChannel.chainedSketchFx[slot]
        var controller = root.selectedChannel.sketchFxFilterResonanceControllers[slot]

        function valueSetter(value) {
            if (controller != null && controller.controlsCount > 0) {
                controller.value = Zynthian.CommonUtils.clamp(value, controller.value_min, controller.value_max)
                applicationWindow().showOsd({
                                                parameterName: "layer_fx_filter_resonance",
                                                description: qsTr("%1 Filter Resonance").arg(synthName),
                                                start: controller.value_min,
                                                stop: controller.value_max,
                                                step: controller.step_size,
                                                defaultValue: null,
                                                currentValue: controller.value,
                                                startLabel: qsTr("%1").arg(controller.value_min),
                                                stopLabel: qsTr("%1").arg(controller.value_max),
                                                valueLabel: qsTr("%1").arg(controller.value),
                                                setValueFunction: valueSetter,
                                                showValueLabel: true,
                                                showResetToDefault: false,
                                                showVisualZero: false
                                            })
            } else if (root.selectedChannel.checkIfLayerExists(midiChannel)) {
                applicationWindow().showMessageDialog(qsTr("%1 does not have Filter Resonance controller").arg(synthName), 2000)
            }
        }

        valueSetter(controller.value + sign * controller.step_size)
    }
    /**
     * Update clip gain
     * @param clip The clip whose gain needs to be updated
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateClipGain(clip, sign) {
        if (clip != null) {
            let clipCppObj = Zynthbox.PlayGridManager.getClipById(clip.cppObjId);
            clipCppObj.rootSlice.gainHandler.gainAbsolute = Zynthian.CommonUtils.clamp(clipCppObj.rootSlice.gainHandler.gainAbsolute + sign*0.01, 0, 1)
        }
    }
    /**
     * Update clip pitch
     * @param clip The clip whose pitch needs to be updated
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateClipPitch(clip, sign) {
        if (clip != null) {
            let clipCppObj = Zynthbox.PlayGridManager.getClipById(clip.cppObjId);
            clipCppObj.rootSlice.pitch = Zynthian.CommonUtils.clamp(clipCppObj.rootSlice.pitch + sign, -48, 48)
        }
    }
    /**
     * Update clip speed ratio
     * @param clip The clip whose speed ratio needs to be updated
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateClipSpeedRatio(clip, sign) {
        if (clip != null) {
            let clipCppObj = Zynthbox.PlayGridManager.getClipById(clip.cppObjId);
            clipCppObj.speedRatio = Zynthian.CommonUtils.clamp(clipCppObj.speedRatio + sign * 0.1, 0.5, 2)
        }
    }
    /**
     * Update clip bpm
     * @param clip The clip whose bpm needs to be updated
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateClipBpm(clip, sign) {
        if (clip != null) {
            let clipCppObj = Zynthbox.PlayGridManager.getClipById(clip.cppObjId);
            clipCppObj.bpm = Zynthian.CommonUtils.clamp(clipCppObj.bpm + sign, 50, 200)
        }
    }

    title: qsTr("Sketchpad")
    screenId: "sketchpad"
    padding: 0
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    backAction.visible: false

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Sketchpad")

            Kirigami.Action {
                // Rename Save button as Save as for temp sketchpad
                text: root.song.isTemp ? qsTr("Save As") : qsTr("Save")
                onTriggered: {
                    if (root.song.isTemp) {
                        fileNameDialog.dialogType = "save";
                        fileNameDialog.fileName = "Sketchpad-1";
                        fileNameDialog.open();
                    } else {
                        zynqtgui.sketchpad.saveSketchpad();
                    }
                }
            }
            Kirigami.Action {
                text: qsTr("Save As")
                visible: !root.song.isTemp
                onTriggered: {
                    fileNameDialog.dialogType = "saveas";
                    fileNameDialog.fileName = song.name;
                    fileNameDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Clone As")
                visible: !root.song.isTemp
                onTriggered: {
                    fileNameDialog.dialogType = "savecopy";
                    fileNameDialog.fileName = song.sketchpadFolderName;
                    fileNameDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Load Sketchpad")
                onTriggered: {
                    sketchpadPickerDialog.folderModel.folder = sketchpadPickerDialog.rootFolder;
                    sketchpadPickerDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("New Sketchpad")
                onTriggered: {
                    zynqtgui.sketchpad.newSketchpad()
                }
            }
            Kirigami.Action {
                text: "Get New Sketchpads"
                onTriggered: {
                    zynqtgui.show_modal("sketchpad_downloader")
                }
            }
        },
        Kirigami.Action {
            text: "" //qsTr("Sounds")
            onTriggered: zynqtgui.show_modal("sound_categories")
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            text: qsTr("Mixer")
            checked: bottomStack.slotsBar.mixerButton.checked
            onTriggered: zynqtgui.toggleSketchpadMixer()
        }
    ]

    cuiaCallback: function(cuia) {
        let returnValue = false;
        if (sketchpadPickerDialog.opened) {
            returnValue = sketchpadPickerDialog.cuiaCallback(cuia);
        } else {
            // Forward CUIA actions to bottomBar only when bottomBar is open
            if (bottomStack.currentIndex === 0) {
                if (bottomBar.tabbedView.activeItem.cuiaCallback != null) {
                    returnValue = bottomBar.tabbedView.activeItem.cuiaCallback(cuia);
                }
            } else {
                if (bottomStack.itemAt(bottomStack.currentIndex).cuiaCallback != null) {
                    returnValue = bottomStack.itemAt(bottomStack.currentIndex).cuiaCallback(cuia);
                }
            }

            if (returnValue == false) {
                switch (cuia) {
                case "SWITCH_MODE_RELEASED":
                    if (zynqtgui.altButtonPressed) {
                        // Cycle between channel, mixer, synths, samples, fx when alt button is pressed
                        if (bottomStack.slotsBar.mixerButton.checked) {
                            bottomStack.slotsBar.channelButton.checked = true;
                        } else if (bottomStack.slotsBar.channelButton.checked) {
                            bottomStack.slotsBar.clipsButton.checked = true;
                        } else if (bottomStack.slotsBar.clipsButton.checked) {
                            bottomStack.slotsBar.synthsButton.checked = true;
                        } else if (bottomStack.slotsBar.synthsButton.checked) {
                            bottomStack.slotsBar.samplesButton.checked = true;
                        } else if (bottomStack.slotsBar.samplesButton.checked) {
                            bottomStack.slotsBar.fxButton.checked = true;
                        } else if (bottomStack.slotsBar.fxButton.checked) {
                            bottomStack.slotsBar.channelButton.checked = true;
                        } else {
                            bottomStack.slotsBar.channelButton.checked = true;
                        }
                        returnValue = true;
                    }
                    break;
                case "SCREEN_ADMIN":
                    if (root.selectedChannel && root.selectedChannel.trackType === "synth") {
                        if (root.channel.selectedSlot.className === "TracksBar_synthslot") {
                            let sound = root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow]
                            // when synth and slot is active, edit that sound or show popup when empty
                            if (sound >= 0 && root.selectedChannel.checkIfLayerExists(sound)) {
                                zynqtgui.fixed_layers.activate_index(sound);
                                zynqtgui.control.single_effect_engine = null;
                                zynqtgui.current_screen_id = "control";
                                zynqtgui.forced_screen_back = "sketchpad"
                            } else {
                                bottomStack.slotsBar.handleItemClick("synth");
                            }
                        } else {
                            let sample = root.selectedChannel.samples[root.selectedChannel.selectedSlotRow];
                            // when sample and slot is active, goto wave editor or show popup when empty
                            if (sample && !sample.isEmpty) {
                                zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                zynqtgui.bottomBarControlObj = root.selectedChannel;
                                bottomStack.slotsBar.bottomBarButton.checked = true;
                                bottomStack.bottomBar.channelWaveEditorAction.trigger();
                            } else {
                                bottomStack.slotsBar.handleItemClick("sample-trig");
                            }
                        }
                        returnValue = true;
                    } else if (root.selectedChannel && root.selectedChannel.trackType === "sample-loop") {
                        let clip = root.selectedChannel.clipsModel.getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                        // when loop and slot is active, goto wave editor or show popup when empty
                        if (clip && !clip.isEmpty) {
                            zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
                            zynqtgui.bottomBarControlObj = root.selectedChannel.clipsModel.getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                            bottomStack.slotsBar.bottomBarButton.checked = true;
                            bottomStack.bottomBar.waveEditorAction.trigger();
                        } else {
                            bottomStack.slotsBar.handleItemClick("sample-loop");
                        }
                        returnValue = true;
                    } else {
                        // do nothing for other cases
                        returnValue = false;
                    }
                    break;
                case "KNOB0_TOUCHED":
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "sketchpad_channel") {
                        applicationWindow().updateChannelVolume(0, zynqtgui.sketchpad.lastSelectedObj.value.id);
                    }
                    returnValue = true;
                    break;
                case "KNOB0_RELEASED":
                    returnValue = true;
                    break;
                case "KNOB0_UP":
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "sketchpad_channel") {
                        applicationWindow().updateChannelVolume(1, zynqtgui.sketchpad.lastSelectedObj.value.id);
                    }
                    returnValue = true;
                    break;
                case "KNOB0_DOWN":
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "sketchpad_channel") {
                        applicationWindow().updateChannelVolume(-1, zynqtgui.sketchpad.lastSelectedObj.value.id);
                    }
                    returnValue = true;
                    break;
                case "KNOB1_TOUCHED":
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "sketchpad_channel") {
                        applicationWindow().updateChannelDelaySend(0, zynqtgui.sketchpad.lastSelectedObj.value.id);
                    }
                    returnValue = true;
                    break;
                case "KNOB1_RELEASED":
                    returnValue = true;
                    break;
                case "KNOB1_UP":
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "sketchpad_channel") {
                        applicationWindow().updateChannelDelaySend(1, zynqtgui.sketchpad.lastSelectedObj.value.id);
                    }
                    returnValue = true;
                    break;
                case "KNOB1_DOWN":
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "sketchpad_channel") {
                        applicationWindow().updateChannelDelaySend(-1, zynqtgui.sketchpad.lastSelectedObj.value.id);
                    }
                    returnValue = true;
                    break;
                case "KNOB2_TOUCHED":
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "sketchpad_channel") {
                        applicationWindow().updateChannelReverbSend(0, zynqtgui.sketchpad.lastSelectedObj.value.id);
                    }
                    returnValue = true;
                    break;
                case "KNOB2_RELEASED":
                    returnValue = true;
                    break;
                case "KNOB2_UP":
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "sketchpad_channel") {
                        applicationWindow().updateChannelReverbSend(1, zynqtgui.sketchpad.lastSelectedObj.value.id);
                    }
                    returnValue = true;
                    break;
                case "KNOB2_DOWN":
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "sketchpad_channel") {
                        applicationWindow().updateChannelReverbSend(-1, zynqtgui.sketchpad.lastSelectedObj.value.id);
                    }
                    returnValue = true;
                    break;
                case "KNOB3_TOUCHED":
                    returnValue = true;
                    break;
                case "KNOB3_RELEASED":
                    returnValue = true;
                    break;
                case "KNOB3_UP":
                    zynqtgui.sketchpad.selectedTrackId = Zynthian.CommonUtils.clamp(zynqtgui.sketchpad.selectedTrackId + 1, 0, Zynthbox.Plugin.sketchpadTrackCount - 1);
                    returnValue = true;
                    break;
                case "KNOB3_DOWN":
                    zynqtgui.sketchpad.selectedTrackId = Zynthian.CommonUtils.clamp(zynqtgui.sketchpad.selectedTrackId - 1, 0, Zynthbox.Plugin.sketchpadTrackCount - 1);
                    returnValue = true;
                    break;
                }
            }
        }

        return returnValue
    }

    Connections {
        target: zynqtgui
        onToggleMixer: {
            if (bottomStack.slotsBar.mixerButton.checked) {
                bottomStack.slotsBar.channelButton.checked = true;
            } else {
                bottomStack.slotsBar.mixerButton.checked = true;
                zynqtgui.sketchpad.displaySceneButtons = false;
            }
        }
        onShowMixer: {
            bottomStack.slotsBar.mixerButton.checked = true;
            zynqtgui.sketchpad.displaySceneButtons = false;
        }
        onHideMixer: {
            bottomStack.slotsBar.channelButton.checked = true;
        }
    }

    Connections {
        target: bottomBar.tabbedView
        onActiveActionChanged: updateLedVariablesTimer.restart()
    }

    Timer {
        id: updateLedVariablesTimer
        interval: 30
        repeat: false
        onTriggered: {
            // Check if song bar is active
            if (bottomStack.slotsBar.bottomBarButton.checked && // Checks if bottombar is visible
                    bottomBar.tabbedView.activeAction.page.search("SongBar") >= 0 // Checks if current active page is sound combinator or not
                    ) {
                zynqtgui.songBarActive = true;
            } else {
                zynqtgui.songBarActive = false;
            }

            // Check if sound combinator is active
            // if (bottomStack.slotsBar.bottomBarButton.checked && // Checks if bottombar is visible
            //     bottomBar.tabbedView.activeAction.page.search("ChannelsViewSoundsBar") >= 0 // Checks if current active page is sound combinator or not
            // ) {
            //     zynqtgui.soundCombinatorActive = true;
            // } else {
            //     zynqtgui.soundCombinatorActive = false;
            // }

            // Check if sound combinator is active
            if (bottomStack.slotsBar.bottomBarButton.checked && // Checks if bottombar is visible
                    bottomBar.tabbedView.activeAction.page.search("SamplesBar") >= 0 // Checks if current active page is samples bar
                    ) {
                zynqtgui.channelSamplesBarActive = true;
            } else {
                zynqtgui.channelSamplesBarActive = false;
            }

            // Check if channel wave editor bar is active
            if (bottomStack.slotsBar.bottomBarButton.checked && // Checks if bottombar is visible
                    zynqtgui.bottomBarControlType === "bottombar-controltype-channel" && // Checks if channel is selected
                    bottomBar.tabbedView.activeAction.page.search("WaveEditorBar") >= 0 // Checks if current active page is wave editor or not
                    ) {
                zynqtgui.channelWaveEditorBarActive = true;
            } else {
                zynqtgui.channelWaveEditorBarActive = false;
            }

            // Check if clip wave editor bar is active
            if (bottomStack.slotsBar.bottomBarButton.checked && // Checks if bottombar is visible
                    (zynqtgui.bottomBarControlType === "bottombar-controltype-clip" || zynqtgui.bottomBarControlType === "bottombar-controltype-pattern") && // Checks if clip/pattern is selected
                    bottomBar.tabbedView.activeAction.page.search("WaveEditorBar") >= 0 // Checks if current active page is wave editor or not
                    ) {
                zynqtgui.clipWaveEditorBarActive = true;
            } else {
                zynqtgui.clipWaveEditorBarActive = false;
            }

            if (bottomStack.slotsBar.channelButton.checked) {
                console.log("LED : Slots Channel Bar active")
                zynqtgui.slotsBarChannelActive = true;
                zynqtgui.slotsBarClipsActive = false;
                zynqtgui.slotsBarMixerActive = false;
                zynqtgui.slotsBarSynthsActive = false;
                zynqtgui.slotsBarSamplesActive = false;
                zynqtgui.slotsBarFxActive = false;
                // zynqtgui.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.mixerButton.checked) {
                console.log("LED : Slots Mixer Bar active")
                zynqtgui.slotsBarChannelActive = false;
                zynqtgui.slotsBarClipsActive = false;
                zynqtgui.slotsBarMixerActive = true;
                zynqtgui.slotsBarSynthsActive = false;
                zynqtgui.slotsBarSamplesActive = false;
                zynqtgui.slotsBarFxActive = false;
                // zynqtgui.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.clipsButton.checked) {
                console.log("LED : Slots Clips Bar active")
                zynqtgui.slotsBarChannelActive = false;
                zynqtgui.slotsBarClipsActive = true;
                zynqtgui.slotsBarMixerActive = false;
                zynqtgui.slotsBarSynthsActive = false;
                zynqtgui.slotsBarSamplesActive = false;
                zynqtgui.slotsBarFxActive = false;
                // zynqtgui.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.synthsButton.checked) {
                console.log("LED : Slots Synths Bar active")
                zynqtgui.slotsBarChannelActive = false;
                zynqtgui.slotsBarClipsActive = false;
                zynqtgui.slotsBarMixerActive = false;
                zynqtgui.slotsBarSynthsActive = true;
                zynqtgui.slotsBarSamplesActive = false;
                zynqtgui.slotsBarFxActive = false;
                // zynqtgui.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.samplesButton.checked) {
                console.log("LED : Slots Samples Bar active")
                zynqtgui.slotsBarChannelActive = false;
                zynqtgui.slotsBarClipsActive = false;
                zynqtgui.slotsBarMixerActive = false;
                zynqtgui.slotsBarSynthsActive = false;
                zynqtgui.slotsBarSamplesActive = true;
                zynqtgui.slotsBarFxActive = false;
                // zynqtgui.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.fxButton.checked) {
                console.log("LED : Slots FX Bar active")
                zynqtgui.slotsBarChannelActive = false;
                zynqtgui.slotsBarClipsActive = false;
                zynqtgui.slotsBarMixerActive = false;
                zynqtgui.slotsBarSynthsActive = false;
                zynqtgui.slotsBarSamplesActive = false;
                zynqtgui.slotsBarFxActive = true;
                // zynqtgui.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.soundCombinatorButton.checked) {
                console.log("LED : Slots FX Bar active")
                zynqtgui.slotsBarChannelActive = false;
                zynqtgui.slotsBarClipsActive = false;
                zynqtgui.slotsBarMixerActive = false;
                zynqtgui.slotsBarSynthsActive = false;
                zynqtgui.slotsBarSamplesActive = false;
                zynqtgui.slotsBarFxActive = false;
                // zynqtgui.soundCombinatorActive = true;
            } else {
                console.log("LED : No Slots Bar active")
                zynqtgui.slotsBarChannelActive = false;
                zynqtgui.slotsBarClipsActive = false;
                zynqtgui.slotsBarMixerActive = false;
                zynqtgui.slotsBarSynthsActive = false;
                zynqtgui.slotsBarSamplesActive = false;
                zynqtgui.slotsBarFxActive = false;
                // zynqtgui.soundCombinatorActive = false;
            }
        }
    }

    Connections {
        target: zynqtgui.sketchpad
        onSong_changed: {
            console.log("$$$ Song Changed :", song)

            zynqtgui.bottomBarControlType = "bottombar-controltype-song";
            zynqtgui.bottomBarControlObj = root.song;
            bottomStack.slotsBar.channelButton.checked = true
        }
    }

    Component.onCompleted: {
        applicationWindow().controlsVisible = true;
        zynqtgui.bottomBarControlType = "bottombar-controltype-song";
        zynqtgui.bottomBarControlObj = root.song;
        bottomStack.slotsBar.channelButton.checked = true
        selectedChannelThrottle.restart()
    }

    Component.onDestruction: {
        applicationWindow().controlsVisible = true;
    }

    Zynthian.SaveFileDialog {
        property string dialogType: "save"

        id: fileNameDialog
        visible: false

        headerText: {
            if (fileNameDialog.dialogType == "savecopy")
                return qsTr("Enter Name for Sketchpad Copy")
            else if (fileNameDialog.dialogType === "saveas")
                return qsTr("Enter New Version's Name")
            else if (fileNameDialog.dialogType === "save")
                return qsTr("Enter Sketchpad Name")
            else
                return qsTr("Enter New Sketchpad Name")
        }
        conflictText: {
            if (dialogType == "savecopy")
                return qsTr("Sketchpad Exists")
            else if (dialogType == "saveas")
                return qsTr("Version Exists")
            else
                return qsTr("Exists")
        }
        overwriteOnConflict: false

        onFileNameChanged: {
            console.log("File Name : " + fileName)
            fileCheckTimer.restart()
        }
        Timer {
            id: fileCheckTimer
            interval: 300
            onTriggered: {
                if (fileNameDialog.dialogType == "savecopy"
                        && fileNameDialog.fileName.length > 0
                        && zynqtgui.sketchpad.sketchpadExists(fileNameDialog.fileName)) {
                    // Sketchpad with name already exists
                    fileNameDialog.conflict = true;
                } else if (fileNameDialog.dialogType === "saveas"
                           && fileNameDialog.fileName.length > 0
                           && zynqtgui.sketchpad.versionExists(fileNameDialog.fileName)) {
                    fileNameDialog.conflict = true;
                } else if (fileNameDialog.dialogType === "save"
                           && root.song.isTemp
                           && fileNameDialog.fileName.length > 0
                           && zynqtgui.sketchpad.sketchpadExists(fileNameDialog.fileName)) {
                    fileNameDialog.conflict = true;
                } else {
                    fileNameDialog.conflict = false;
                }
            }
        }

        onAccepted: {
            console.log("Accepted")

            if (dialogType === "save") {
                zynqtgui.sketchpad.createSketchpad(fileNameDialog.fileName)
            } else if (dialogType === "saveas") {
                root.song.name = fileNameDialog.fileName;
                zynqtgui.sketchpad.saveSketchpad();
            } else if (dialogType === "savecopy") {
                zynqtgui.sketchpad.saveCopy(fileNameDialog.fileName);
            }
        }
        onRejected: {
            console.log("Rejected")
        }
    }

    Zynthian.FilePickerDialog {
        id: sketchpadPickerDialog
        parent: root

        headerText: qsTr("Pick a sketchpad")
        rootFolder: "/zynthian/zynthian-my-data/sketchpads/"
        folderModel {
            nameFilters: ["*.sketchpad.json"]
        }
        folderInfoStrings: {
            "file:///zynthian/zynthian-my-data/sketchpads/community-sketchpads": qsTr("When you open a Community Sketchpad, it gets copied over to my-sketchpads under the same name (or with a numbered suffix if you already have something there - we'll not overwrite other sketchpads)")
        }
        onAccepted: {
            console.log("Selected Sketchpad : " + sketchpadPickerDialog.selectedFile.fileName + "("+ sketchpadPickerDialog.selectedFile.filePath +")")
            zynqtgui.sketchpad.loadSketchpad(sketchpadPickerDialog.selectedFile.filePath, false)
        }
    }

    function resetBottomBar(toggleBottomBar) {
        if (toggleBottomBar) {
            if (bottomStack.slotsBar.channelButton.checked) {
                bottomStack.slotsBar.clipsButton.checked = true
            } else {
                bottomStack.slotsBar.channelButton.checked = true
            }
        } else {
            bottomStack.slotsBar.channelButton.checked = true
        }
    }

    contentItem : Item {
        id: content

        Rectangle {
            id: lastSelectedObjIndicator
            visible: {
                // If lastSelectedObj is a TracksBar slot, then do not display selected indicator when another slot is selected
                if (zynqtgui.sketchpad.lastSelectedObj.className.startsWith("TracksBar_")) {
                    return zynqtgui.sketchpad.lastSelectedObj.track == root.selectedChannel && zynqtgui.sketchpad.lastSelectedObj.component && zynqtgui.sketchpad.lastSelectedObj.component.visible
                } else {
                    return zynqtgui.sketchpad.lastSelectedObj.component && zynqtgui.sketchpad.lastSelectedObj.component.visible
                }
            }
            z: 1000
            border.width: 2
            border.color: Kirigami.Theme.textColor
            color: "transparent"

            function updateLastSelectedObjIndicatorPosition() {
                lastSelectedObjIndicatorPositioner.restart();
            }
            Timer {
                id: lastSelectedObjIndicatorPositioner
                interval: 0; repeat: false; running: false;
                onTriggered: {
                    lastSelectedObjIndicator.width = zynqtgui.sketchpad.lastSelectedObj && zynqtgui.sketchpad.lastSelectedObj.component ? zynqtgui.sketchpad.lastSelectedObj.component.width + 8 : 0
                    lastSelectedObjIndicator.height = zynqtgui.sketchpad.lastSelectedObj && zynqtgui.sketchpad.lastSelectedObj.component ? zynqtgui.sketchpad.lastSelectedObj.component.height + 8 : 0
                    lastSelectedObjIndicator.x = zynqtgui.sketchpad.lastSelectedObj && zynqtgui.sketchpad.lastSelectedObj.component ? zynqtgui.sketchpad.lastSelectedObj.component.mapToItem(content, 0, 0).x - 4 : 0
                    lastSelectedObjIndicator.y = zynqtgui.sketchpad.lastSelectedObj && zynqtgui.sketchpad.lastSelectedObj.component ? zynqtgui.sketchpad.lastSelectedObj.component.mapToItem(content, 0, 0).y - 4 : 0
                }
            }
            Connections {
                target: zynqtgui.sketchpad ? zynqtgui.sketchpad.lastSelectedObj : null
                onComponentChanged: lastSelectedObjIndicator.updateLastSelectedObjIndicatorPosition();
            }
            Connections {
                target: content
                onHeightChanged: lastSelectedObjIndicator.updateLastSelectedObjIndicatorPosition()
                onWidthChanged: lastSelectedObjIndicator.updateLastSelectedObjIndicatorPosition()
            }
        }

        Rectangle {
            id: copySourceObjIndicator
            visible: {
                // If copySourceObj is a TracksBar slot, then to not show copySourceObjIndicator if current track is not the same as copySourceObj
                if (zynqtgui.sketchpad.copySourceObj.className.startsWith("TracksBar_")) {
                    return zynqtgui.sketchpad.copySourceObj.track == root.selectedChannel && zynqtgui.sketchpad.copySourceObj.component && zynqtgui.sketchpad.copySourceObj.component.visible
                } else {
                    return zynqtgui.sketchpad.copySourceObj.component && zynqtgui.sketchpad.copySourceObj.component.visible
                }
            }
            width: zynqtgui.sketchpad.copySourceObj && zynqtgui.sketchpad.copySourceObj.component ? zynqtgui.sketchpad.copySourceObj.component.width : 0
            height: zynqtgui.sketchpad.copySourceObj && zynqtgui.sketchpad.copySourceObj.component ? zynqtgui.sketchpad.copySourceObj.component.height : 0
            x: zynqtgui.sketchpad.copySourceObj && zynqtgui.sketchpad.copySourceObj.component ? zynqtgui.sketchpad.copySourceObj.component.mapToItem(content, 0, 0).x : 0
            y: zynqtgui.sketchpad.copySourceObj && zynqtgui.sketchpad.copySourceObj.component ? zynqtgui.sketchpad.copySourceObj.component.mapToItem(content, 0, 0).y : 0
            z: 1000
            color: Kirigami.Theme.textColor
            opacity: 0.5
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.bottomMargin: Kirigami.Units.largeSpacing
            spacing: 2

            QQC2.Control {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: Kirigami.Units.gridUnit * 9
                // Layout.margins: svgBg.inset.top

                topPadding: svgBg.topPadding
                bottomPadding: svgBg.bottomPadding
                leftPadding: svgBg.leftPadding
                rightPadding: svgBg.rightPadding

                background: Item
                {
                    PlasmaCore.FrameSvgItem {
                        id: svgBg
                        visible: fromCurrentTheme
                        anchors.fill: parent

                        readonly property real leftPadding: fixedMargins.left
                        readonly property real rightPadding: fixedMargins.right
                        readonly property real topPadding: fixedMargins.top
                        readonly property real bottomPadding: fixedMargins.bottom

                        imagePath: "widgets/statusinfo_background"
                        colorGroup: PlasmaCore.Theme.ViewColorGroup
                        enabledBorders: PlasmaCore.FrameSvgItem.BottomBorder
                    }
                }

                contentItem: Item {

                    RowLayout {
                        anchors.fill: parent
                        spacing: 2

                        QQC2.Control
                        {
                            Layout.fillWidth: false
                            Layout.fillHeight: true
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 6

                            contentItem: Item {
                                ColumnLayout {
                                    id: sketchpadSketchHeadersColumn
                                    anchors.fill: parent
                                    spacing: 2

                                    TableHeader {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        text: qsTr("Scene\n%1").arg(root.song.scenesModel.selectedSceneName)
                                        highlightOnFocus: false
                                        highlighted: root.displaySceneButtons
                                        onPressed: {
                                            if (zynqtgui.sketchpad.displaySceneButtons) {
                                                zynqtgui.sketchpad.displaySceneButtons = false
                                                bottomStack.slotsBar.channelButton.checked = true
                                            } else {
                                                zynqtgui.sketchpad.displaySceneButtons = true
                                                bottomStack.slotsBar.clipsButton.checked = true
                                                // root.displayTrackButtons = false
                                            }
                                        }
                                    }

                                    // Placeholder item of same size to have 2 rows in here
                                    TableHeader {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        text: ""
                                        highlightOnFocus: false
                                        highlighted: false
                                    }
                                }
                            }
                        }

                        QQC2.Control
                        {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.margins: svgBg2.inset.top

                            topPadding: svgBg2.topPadding
                            bottomPadding: svgBg2.bottomPadding
                            leftPadding: svgBg2.leftPadding
                            rightPadding: svgBg2.rightPadding

                            background: Item
                            {
                                PlasmaCore.FrameSvgItem {
                                    id: svgBg2
                                    anchors.fill: parent
                                    // property bool highlighted

                                    readonly property real leftPadding: fixedMargins.left
                                    readonly property real rightPadding: fixedMargins.right
                                    readonly property real topPadding: fixedMargins.top
                                    readonly property real bottomPadding: fixedMargins.bottom

                                    imagePath: "widgets/tracks-background"
                                    colorGroup: PlasmaCore.Theme.NormalColorGroup
                                    // enabledBorders: PlasmaCore.FrameSvgItem.BottomBorder
                                }
                            }


                            contentItem: Item {
                                // id: sketchpadClipContent

                                // layer.enabled: true
                                // layer.effect: OpacityMask
                                // {
                                //     maskSource: Rectangle
                                //     {
                                //         width: sketchpadClipContent.width
                                //         height: sketchpadClipContent.height
                                //         radius: 4
                                //     }
                                // }

                                ColumnLayout {
                                    id: sketchpadClipsColumn
                                    anchors.fill: parent
                                    spacing: 1

                                    // Should show arrows is True when segment count is greater than 10 and hence needs arrows to scroll
                                    property bool shouldShowSegmentArrows: root.song.arrangementsModel.selectedArrangement.segmentsModel.count > 10
                                    // Segment offset will determine what is the first segment to display when arrow keys are displayed
                                    property int segmentOffset: 0
                                    // Maximum segment offset allows the arrow keys to check if there are any more segments outside view
                                    property int maximumSegmentOffset: root.song.arrangementsModel.selectedArrangement.segmentsModel.count - 10 + 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 1

                                        // Display 10 header buttons which will show channel header buttons
                                        Repeater {
                                            id: channelsHeaderRepeater

                                            // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                                            model: zynqtgui.isBootingComplete
                                                   ? 10
                                                   : 0

                                            delegate: Item {
                                                id: headerDelegate
                                                property QtObject channel: root.song.channelsModel.getChannel(index)
                                                function switchToThisChannel() {
                                                    // If song mode is not active, clicking on cells should activate that channel
                                                    zynqtgui.sketchpad.lastSelectedObj.setTo(channelHeaderDelegate.channel.className, channelHeaderDelegate.channel, channelHeaderDelegate, channelHeaderDelegate.channel)
                                                    zynqtgui.sketchpad.selectedTrackId = index;
                                                    Qt.callLater(function() {
                                                        // Open TracksBar and switch to channel
                                                        // bottomStack.slotsBar.channelButton.checked = true
                                                        root.resetBottomBar(false)
                                                        zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                                        zynqtgui.bottomBarControlObj = channelHeaderDelegate.channel;
                                                    })
                                                }

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Layout.topMargin: 1 // Without this magic number, the top of header row doesn't match with left side scenes button or right side copy button
                                                state: root.displaySceneButtons
                                                       ? "SceneMode"
                                                       : "ChannelMode"
                                                states: [
                                                    State {
                                                        name: "SceneMode"
                                                        PropertyChanges { target: sceneHeader; visible: true }
                                                        PropertyChanges { target: channelHeaderDelegate; visible: false }
                                                        PropertyChanges { target: volumeGauge; visible: false }
                                                    },
                                                    State {
                                                        name: "ChannelMode"
                                                        PropertyChanges { target: sceneHeader; visible: false }
                                                        PropertyChanges { target: channelHeaderDelegate; visible: true }
                                                        PropertyChanges { target: volumeGauge; visible: true }
                                                    }
                                                ]

                                                TableHeader {
                                                    id: sceneHeader
                                                    anchors.fill: parent
                                                    text: String.fromCharCode(65+index).toUpperCase()
                                                    highlighted: index === root.song.scenesModel.selectedSceneIndex
                                                    highlightOnFocus: false
                                                    onPressed: {
                                                        Zynthian.CommonUtils.switchToScene(index);
                                                    }
                                                }

                                                ChannelHeader2 {
                                                    id: channelHeaderDelegate
                                                    anchors.fill: parent

                                                    channel: headerDelegate.channel
                                                    text: channelHeaderDelegate.channel.name
                                                    subText: null
                                                    subSubText: Zynthbox.MidiRouter.sketchpadTrackTargetTracks[channelHeaderDelegate.channel.id] == channelHeaderDelegate.channel.id ? channelHeaderDelegate.channel.channelTypeDisplayName : qsTr("Redirected")
                                                    subSubTextSize: 7

                                                    Binding {
                                                        target: channelHeaderDelegate
                                                        property: "color"
                                                        when: root.visible
                                                        delayed: true

                                                        value: {
                                                            if (zynqtgui.sketchpad.copySourceObj && zynqtgui.sketchpad.copySourceObj.value === model.channel) {
                                                                return "#ff2196f3"
                                                            } else if (channelHeaderDelegate.channel.trackType === "external" || channelHeaderDelegate.channel.occupiedSlotsCount > 0) {
                                                                return channelHeaderDelegate.channel.color;
                                                            }
                                                            return "#66888888";
                                                        }
                                                    }

                                                    highlightOnFocus: false
                                                    highlighted: index === zynqtgui.sketchpad.selectedTrackId // If song mode is not active, highlight if current cell is selected channel

                                                    onClicked: {
                                                        headerDelegate.switchToThisChannel()
                                                    }
                                                    onDoubleClicked: {
                                                        channelHeaderDelegate.channel.muted = !channelHeaderDelegate.channel.muted
                                                    }
                                                }

                                                Extras.Gauge {
                                                    id: volumeGauge
                                                    visible: Zynthbox.MidiRouter.sketchpadTrackTargetTracks[channelHeaderDelegate.channel.id] == channelHeaderDelegate.channel.id
                                                    anchors {
                                                        top: parent.top
                                                        bottom: parent.bottom
                                                        right: parent.right
                                                        rightMargin: 2
                                                        topMargin: -4
                                                        bottomMargin: -4
                                                    }
                                                    minimumValue: -40
                                                    maximumValue: 20
                                                    value: channelHeaderDelegate.channel.volume
                                                    font.pointSize: 8
                                                    opacity: 0.7
                                                    style: GaugeStyle {
                                                        valueBar: Rectangle {
                                                            color: Kirigami.Theme.highlightColor
                                                            implicitWidth: 6
                                                        }
                                                        minorTickmark: null
                                                        tickmark: null
                                                        tickmarkLabel: null
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 1

                                        Repeater {
                                            id: clipsRepeater
                                            // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                                            model: zynqtgui.isBootingComplete ? root.song.channelsModel : 0

                                            delegate: Item {
                                                id: clipsDelegate
                                                function switchToThisClip(allowToggle) {
                                                    if (zynqtgui.sketchpad.lastSelectedObj != null &&
                                                            zynqtgui.sketchpad.lastSelectedObj.className === "sketchpad_clipoverview" &&
                                                            zynqtgui.sketchpad.lastSelectedObj.value === index &&
                                                            zynqtgui.sketchpad.lastSelectedObj.component != null &&
                                                            zynqtgui.sketchpad.lastSelectedObj.component === clipCell) {
                                                        // Clip overview is already selected. Toggle between track/clips view
                                                        root.resetBottomBar(allowToggle)
                                                    } else {
                                                        // Clip overview is not selected. Open clips grid view
                                                        bottomStack.slotsBar.clipsButton.checked = true
                                                        zynqtgui.sketchpad.lastSelectedObj.setTo("sketchpad_clipoverview", index, clipCell, clipCell.channel)
                                                        zynqtgui.sketchpad.selectedTrackId = clipCell.channel.id
                                                    }
                                                }
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Layout.bottomMargin: 1 // Without this magic number, the bottom of clips row doesn't match with left side scenes button or right side copy button
                                                state: bottomStack.slotsBar.mixerButton.checked
                                                       ? "MixerMode"
                                                       : "ClipsMode"
                                                states: [
                                                    State {
                                                        name: "ClipsMode"
                                                        PropertyChanges { target: clipCell; visible: true }
                                                        PropertyChanges { target: mixerCell; visible: false }
                                                    },
                                                    State {
                                                        name: "MixerMode"
                                                        PropertyChanges { target: clipCell; visible: false }
                                                        PropertyChanges { target: mixerCell; visible: true }
                                                    }
                                                ]

                                                ClipCell {
                                                    id: clipCell

                                                    anchors.fill: parent
                                                    channel: model.channel
                                                    backgroundColor: "#000000"
                                                    Connections {
                                                        target: channel.sceneClip
                                                        onInCurrentSceneChanged: colorTimer.restart()
                                                        onPathChanged: colorTimer.restart()
                                                        onIsPlayingChanged: colorTimer.restart()
                                                    }
                                                    Connections {
                                                        target: channel
                                                        onConnectedPatternChanged: colorTimer.restart()
                                                        onTrackTypeChanged: colorTimer.restart()
                                                        onClipsModelChanged: colorTimer.restart()
                                                    }
                                                    Connections {
                                                        target: clipCell.pattern
                                                        onLastModifiedChanged: colorTimer.restart()
                                                        onEnabledChanged: colorTimer.restart()
                                                    }
                                                    Connections {
                                                        target: clipCell.sequence
                                                        onIsPlayingChanged: colorTimer.restart()
                                                    }
                                                    Connections {
                                                        target: zynqtgui.sketchpad
                                                        onIsMetronomeRunningChanged: colorTimer.restart()
                                                    }
                                                    Connections {
                                                        target: root.song.scenesModel
                                                        onSelectedSketchpadSongIndexChanged: colorTimer.restart()
                                                    }

                                                    Timer {
                                                        id: colorTimer
                                                        interval: 10
                                                        onTriggered: {
                                                            // update isPlaying
                                                            if (channel.connectedPattern < 0) {
                                                                clipCell.isPlaying = channel.sceneClip.isPlaying;
                                                            } else {
                                                                var patternIsPlaying = false;
                                                                if (clipCell.sequence && clipCell.sequence.isPlaying) {
                                                                    if (clipCell.sequence.soloPattern > -1) {
                                                                        patternIsPlaying = (clipCell.sequence.soloPattern == channel.connectedPattern)
                                                                    } else if (clipCell.pattern) {
                                                                        patternIsPlaying = clipCell.pattern.enabled
                                                                    }
                                                                }
                                                                clipCell.isPlaying = patternIsPlaying && root.song.scenesModel.isClipInScene(channel.sceneClip, channel.sceneClip.col) && zynqtgui.sketchpad.isMetronomeRunning;
                                                            }
                                                        }
                                                    }

                                                    // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                                                    sequence: zynqtgui.isBootingComplete ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName) : null
                                                    pattern: channel.connectedPattern >= 0 && sequence && !sequence.isLoading && sequence.count > 0 ? sequence.getByClipId(channel.id, channel.selectedClip) : null

                                                    onPressed: {
                                                        clipsDelegate.switchToThisClip(true)
                                                    }
                                                }

                                                Rectangle {
                                                    id: mixerCell
                                                    anchors.fill: parent
                                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)

                                                    RowLayout {
                                                        anchors.fill: parent

                                                        QQC2.Dial {
                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true
                                                            Layout.leftMargin: Kirigami.Units.smallSpacing
                                                            Layout.rightMargin: Kirigami.Units.smallSpacing
                                                            inputMode: QQC2.Dial.Vertical
                                                            handle: null
                                                            value: applicationWindow().channels[index].wetFx1Amount
                                                            stepSize: 1
                                                            from: 0
                                                            to: 100
                                                            onValueChanged: {
                                                                applicationWindow().channels[index].wetFx1Amount = value;
                                                            }
                                                        }

                                                        ColumnLayout {
                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true

                                                            QQC2.Label {
                                                                Layout.fillWidth: true
                                                                Layout.fillHeight: false
                                                                Layout.preferredWidth: 1
                                                                Layout.topMargin: Kirigami.Units.smallSpacing
                                                                Layout.bottomMargin: Kirigami.Units.smallSpacing
                                                                font.pointSize: 8
                                                                text: "Sends"
                                                            }
                                                            QQC2.Dial {
                                                                Layout.fillWidth: true
                                                                Layout.fillHeight: true
                                                                Layout.leftMargin: Kirigami.Units.smallSpacing
                                                                Layout.rightMargin: Kirigami.Units.smallSpacing
                                                                inputMode: QQC2.Dial.Vertical
                                                                handle: null
                                                                value: applicationWindow().channels[index].wetFx2Amount
                                                                stepSize: 1
                                                                from: 0
                                                                to: 100
                                                                onValueChanged: {
                                                                    applicationWindow().channels[index].wetFx2Amount = value;
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
                            id: sketchpadCopyPasteButtonsColumn
                            Layout.fillWidth: false
                            Layout.fillHeight: true
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                            spacing: 2

                            // Common copy button to set the object to copy
                            TableHeader {
                                id: copyButton
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                highlightOnFocus: false
                                font.pointSize: 10
                                // Button is enabled only if lastSelectedObj can be copy-pasted
                                enabled: zynqtgui.sketchpad.lastSelectedObj.component != null && zynqtgui.sketchpad.lastSelectedObj.component.visible && zynqtgui.sketchpad.lastSelectedObj.isCopyable
                                text: qsTr("Copy")
                                // Button is visible only when there is no ongoing copy action
                                visible: !zynqtgui.sketchpad.copySourceObj.isCopyable
                                onClicked: {
                                    zynqtgui.sketchpad.copySourceObj.setTo(zynqtgui.sketchpad.lastSelectedObj.className, zynqtgui.sketchpad.lastSelectedObj.value, zynqtgui.sketchpad.lastSelectedObj.component, zynqtgui.sketchpad.lastSelectedObj.track)
                                }
                            }

                            // Common cancel button to cancel copy
                            TableHeader {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                highlightOnFocus: false
                                font.pointSize: 10
                                text: qsTr("Cancel Copy")
                                visible: !copyButton.visible
                                onPressed: {
                                    zynqtgui.sketchpad.copySourceObj.reset()
                                }
                            }

                            // Common button to paste object
                            TableHeader {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                highlightOnFocus: false
                                font.pointSize: 10
                                // Button is enabled if there is an ongoing copy action and the selected slot is of the same type
                                enabled: {
                                    // If copySourceObj is a TracksBar slot, allow pasting to same slot index of track is different
                                    if (zynqtgui.sketchpad.copySourceObj.className.startsWith("TracksBar_")) {
                                        if (root.selectedChannel == zynqtgui.sketchpad.copySourceObj.track) {
                                            return zynqtgui.sketchpad.copySourceObj.isCopyable && zynqtgui.sketchpad.copySourceObj.className == zynqtgui.sketchpad.lastSelectedObj.className && zynqtgui.sketchpad.copySourceObj.value != zynqtgui.sketchpad.lastSelectedObj.value
                                        } else {
                                            return zynqtgui.sketchpad.copySourceObj.isCopyable && zynqtgui.sketchpad.copySourceObj.className == zynqtgui.sketchpad.lastSelectedObj.className
                                        }
                                    } else {
                                        return zynqtgui.sketchpad.copySourceObj.isCopyable && zynqtgui.sketchpad.copySourceObj.className == zynqtgui.sketchpad.lastSelectedObj.className && zynqtgui.sketchpad.copySourceObj.value != zynqtgui.sketchpad.lastSelectedObj.value
                                    }
                                }
                                text: qsTr("Paste")
                                onPressed: {
                                    applicationWindow().confirmer.confirmSomething(qsTr("Confirm Paste"), qsTr("Are you sure that you want to paste %1 to %2? This action is irreversible and will clear all existing contents of %2.").arg(zynqtgui.sketchpad.copySourceObj.humanReadableObjName).arg(zynqtgui.sketchpad.lastSelectedObj.humanReadableObjName), function() {
                                        zynqtgui.sketchpad.lastSelectedObj.copyFrom(zynqtgui.sketchpad.copySourceObj)
                                        zynqtgui.sketchpad.copySourceObj.reset()
                                    });
                                }
                            }

                            TableHeader {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                highlightOnFocus: false
                                font.pointSize: 10
                                // Button is enabled when a copy action is not running and selected slot can be copy-pasted
                                enabled: copyButton.visible && copyButton.enabled && zynqtgui.sketchpad.lastSelectedObj.isCopyable
                                text: qsTr("Clear")
                                onPressed: {
                                    applicationWindow().confirmer.confirmSomething(qsTr("Confirm Clear"), qsTr("Are you sure that you want to clear %1? This action is irreversible and will clear all existing contents of %1.").arg(zynqtgui.sketchpad.lastSelectedObj.humanReadableObjName), function() {
                                        zynqtgui.sketchpad.lastSelectedObj.clear()
                                    });
                                }
                            }
                        }
                    }
                }
            }

            QQC2.Control {
                Layout.fillWidth: true
                Layout.fillHeight: true

                topPadding: svgBg3.topPadding
                bottomPadding: svgBg3.bottomPadding
                leftPadding: svgBg3.leftPadding
                rightPadding: svgBg3.rightPadding

                background: Item
                {
                    PlasmaCore.FrameSvgItem {
                        id: svgBg3
                        visible: fromCurrentTheme
                        anchors.fill: parent

                        readonly property real leftPadding: visible ? fixedMargins.left : 0
                        readonly property real rightPadding: visible ? fixedMargins.right : 0
                        readonly property real topPadding: visible ? fixedMargins.top : 0
                        readonly property real bottomPadding: visible ? fixedMargins.bottom : 0

                        imagePath: "widgets/statusinfo_background"
                        colorGroup: PlasmaCore.Theme.NormalColorGroup
                        enabledBorders: PlasmaCore.FrameSvgItem.NoBorder
                    }
                }

                contentItem : Item {

                    StackLayout {
                        id: bottomStack
                        anchors.fill: parent

                        property alias bottomBar: bottomBar
                        property alias mixerBar: mixerBar
                        property alias slotsBar: slotsBar
                        property alias tracksBar: tracksBar
                        property alias clipsBar: clipsBar

                        onCurrentIndexChanged: updateLedVariablesTimer.restart()

                        BottomBar {
                            id: bottomBar
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        MixerBar {
                            id: mixerBar
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        SlotsBar {
                            id: slotsBar
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        TracksBar {
                            id: tracksBar
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        ClipsBar {
                            id: clipsBar
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            onClicked: {
                                zynqtgui.sketchpad.lastSelectedObj.setTo(clipsBar.selectedClipObject.className, clipsBar.selectedClipObject, clipsBar.selectedComponent, clipsBar.selectedClipObject.clipChannel)
                            }
                            onPressAndHold: {
                                zynqtgui.sketchpad.lastSelectedObj.setTo(clipsBar.selectedClipObject.className, clipsBar.selectedClipObject, clipsBar.selectedComponent, clipsBar.selectedClipObject.clipChannel)
                            }
                        }

                        // If this needs reviving - it used to be a part of SessionDashboard
                        // ChannelsViewSoundsBar {
                        //     id: soundCombinatorBar
                        //     Layout.fillWidth: true
                        //     Layout.fillHeight: true
                        // }
                    }
                }
            }
        }
    }
}
