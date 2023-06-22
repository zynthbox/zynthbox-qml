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
import QtQml.Models 2.10
import org.kde.kirigami 2.4 as Kirigami
import io.zynthbox.components 1.0 as Zynthbox

import Zynthian 1.0 as Zynthian
import '../SessionDashboard'

Zynthian.ScreenPage {
    id: root

    property alias zlScreen: root
    property alias bottomStack: bottomStack
    readonly property QtObject song: zynqtgui.sketchpad.song
    property bool displaySceneButtons: zynqtgui.sketchpad.displaySceneButtons
    property bool displayTrackButtons: false
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

    /*
    Used to temporarily store last clicked object by user
    If the clicked object is a QObject the object is stored otherwise the index is stored
    Structure : {
        "className": "sketch_track" | "sketch_part" | obj.className
        "value": QObject or int depending on the type of selected object
        "component": QML Component which was clicked to determine co-ordinates of lastSelectedSketchOutline
    }
    */
    property var lastSelectedObj: null
    /*
    Used to temporarily cache clip/channel object to be copied
    copySourceObj is copied from lastSelectedObj when copy button is clicked
    */
    property var copySourceObj: null

    /**
     * Update layer volume of selected channel
     * @param midiChannel The layer midi channel whose volume needs to be updated
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateSelectedChannelLayerVolume(midiChannel, sign) {
        var synthName = ""
        var synthPassthroughClient = Zynthbox.Plugin.synthPassthroughClients[midiChannel]
        try {
            synthName = root.selectedChannel.getLayerNameByMidiChannel(midiChannel).split('>')[0]
        } catch(e) {}

        function valueSetter(value) {
            if (root.selectedChannel.checkIfLayerExists(midiChannel)) {
                synthPassthroughClient.dryAmount = Zynthian.CommonUtils.clamp(value, 0, 1)
                applicationWindow().showOsd({
                    parameterName: "layer_volume",
                    description: qsTr("%1 Volume").arg(synthName),
                    start: 0,
                    stop: 1,
                    step: 0.01,
                    defaultValue: null,
                    currentValue: synthPassthroughClient.dryAmount,
                    startLabel: "0",
                    stopLabel: "1",
                    valueLabel: qsTr("%1").arg(synthPassthroughClient.dryAmount.toFixed(2)),
                    setValueFunction: valueSetter,
                    showValueLabel: true,
                    showResetToDefault: false,
                    showVisualZero: false
                })
            }
        }

        console.log("updateSelectedChannelLayerVolume:", synthPassthroughClient.dryAmount + sign * 0.01)
        valueSetter(synthPassthroughClient.dryAmount + sign * 0.01)
    }
    /**
     * Update selected channel volume
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by 1
     */
    function updateSelectedChannelVolume(sign, showOsd=false) {
        function valueSetter(value) {
            root.selectedChannel.volume = Zynthian.CommonUtils.clamp(value, -40, 20)
            if (showOsd) {
                applicationWindow().showOsd({
                    parameterName: "channel_volume",
                    description: qsTr("%1 Volume").arg(root.selectedChannel.name),
                    start: -40,
                    stop: 20,
                    step: 1,
                    defaultValue: 0,
                    visualZero: -40,
                    currentValue: root.selectedChannel.volume,
                    startLabel: qsTr("%1 dB").arg(-40),
                    stopLabel: qsTr("%1 dB").arg(20),
                    valueLabel: qsTr("%1 dB").arg(root.selectedChannel.volume),
                    setValueFunction: valueSetter,
                    showValueLabel: true,
                    showResetToDefault: true,
                    showVisualZero: true
                })
            }
        }

        valueSetter(root.selectedChannel.volume + sign)
    }
    /**
     * Update clip start position
     * @param clip The clip whose start position needs to be updated
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateClipStartPosition(clip, sign) {
        if (clip != null) {
            clip.startPosition = Zynthian.CommonUtils.clamp(clip.startPosition + sign * 0.01, 0, clip.duration)
        }
    }
    /**
     * Update selected channel pan
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by 1
     */
    function updateSelectedChannelPan(sign) {
        root.selectedChannel.pan = Zynthian.CommonUtils.clamp(root.selectedChannel.pan + sign * 0.05, -1, 1)
    }
    /**
     * Update layer filter cutoff for selected channel
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateSelectedChannelSlotLayerCutoff(sign) {
        var synthName = ""
        var midiChannel = root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow]
        var controller = root.selectedChannel.filterCutoffControllers[root.selectedChannel.selectedSlotRow]
        try {
            synthName = root.selectedChannel.getLayerNameByMidiChannel(midiChannel).split('>')[0]
        } catch(e) {}

        function valueSetter(value) {
            if (controller != null && controller.controlsCount > 0) {
                controller.value = Zynthian.CommonUtils.clamp(value, controller.value_min, controller.value_max)
                zynqtgui.snapshot.schedule_save_last_state_snapshot()
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
     * Update clip loop position
     * @param clip The clip whose loop position needs to be updated
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateClipLoopPosition(clip, sign) {
        if (clip != null) {
            clip.loopDelta = Zynthian.CommonUtils.clamp(clip.loopDelta + sign * 0.01, 0, clip.secPerBeat * clip.length)
        }
    }
    /**
     * Update clip length
     * @param clip The clip whose length needs to be updated
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateClipLength(clip, sign) {
        if (clip != null) {
            if (clip.snapLengthToBeat) {
                clip.length = Zynthian.CommonUtils.clamp(clip.length + sign * 1, 0, 64)
            } else {
                clip.length = Zynthian.CommonUtils.clamp(clip.length + sign * 0.01, 0, 64)
            }
        }
    }
    /**
     * Update layer filter resonance for selected channel
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateSelectedChannelSlotLayerResonance(sign) {
        var synthName = ""
        var midiChannel = root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow]
        var controller = root.selectedChannel.filterResonanceControllers[root.selectedChannel.selectedSlotRow]
        try {
            synthName = root.selectedChannel.getLayerNameByMidiChannel(midiChannel).split('>')[0]
        } catch(e) {}

        function valueSetter(value) {
            if (controller != null && controller.controlsCount > 0) {
                controller.value = Zynthian.CommonUtils.clamp(value, controller.value_min, controller.value_max)
                zynqtgui.snapshot.schedule_save_last_state_snapshot()
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
     * Update clip gain
     * @param clip The clip whose gain needs to be updated
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateClipGain(clip, sign) {
        if (clip != null) {
            clip.gain = Zynthian.CommonUtils.clamp(clip.gain + sign, -24, 8)
        }
    }
    /**
     * Update clip pitch
     * @param clip The clip whose pitch needs to be updated
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateClipPitch(clip, sign) {
        if (clip != null) {
            clip.pitch = Zynthian.CommonUtils.clamp(clip.pitch + sign, -12, 12)
        }
    }
    /**
     * Update clip speed ratio
     * @param clip The clip whose speed ratio needs to be updated
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateClipSpeedRatio(clip, sign) {
        if (clip != null) {
            clip.time = Zynthian.CommonUtils.clamp(clip.time + sign * 0.1, 0.5, 2)
        }
    }
    /**
     * Update clip bpm
     * @param clip The clip whose bpm needs to be updated
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateClipBpm(clip, sign) {
        if (clip != null) {
            clip.bpm = Zynthian.CommonUtils.clamp(clip.bpm + sign, 50, 200)
        }
    }

    title: qsTr("Sketchpad")
    screenId: "sketchpad"
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
        },
        Kirigami.Action {
            text: "" //qsTr("Sounds")
            onTriggered: zynqtgui.show_modal("sound_categories")
            enabled: false
        },
        Kirigami.Action {
            text: qsTr("Mixer")
            checked: bottomStack.slotsBar.mixerButton.checked
            onTriggered: {
                if (bottomStack.slotsBar.mixerButton.checked) {
                    bottomStack.slotsBar.channelButton.checked = true
                } else {
                    bottomStack.slotsBar.mixerButton.checked = true
                }
            }
        },
        Kirigami.Action {
            text: "Get New Sketchpads"
            onTriggered: {
                zynqtgui.show_modal("sketchpad_downloader")
            }
        }

        // Disable undo for now
        /*Kirigami.Action {
            text: qsTr("Undo")
            enabled: root.song.historyLength > 0
            visible: !root.song.isTemp
            onTriggered: {
                root.song.undo();
            }
        }*/
    ]

    cuiaCallback: function(cuia) {
        if (sketchpadPickerDialog.opened) {
            return sketchpadPickerDialog.cuiaCallback(cuia);
        }

        // Forward CUIA actions to bottomBar only when bottomBar is open
        if (bottomStack.currentIndex === 0) {
            if (bottomBar.tabbedView.activeItem.cuiaCallback != null) {
                if (bottomBar.tabbedView.activeItem.cuiaCallback(cuia)) {
                    return true;
                }
            }
        } else {
            if (bottomStack.itemAt(bottomStack.currentIndex).cuiaCallback != null) {
                if (bottomStack.itemAt(bottomStack.currentIndex).cuiaCallback(cuia)) {
                    return true;
                }
            }
        }

        switch (cuia) {
            case "SELECT_UP":
                var selectedMidiChannel = root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow];
                if (root.selectedChannel.checkIfLayerExists(selectedMidiChannel)) {
                    zynqtgui.layer.selectPrevPreset(selectedMidiChannel);
                    infoBar.updateInfoBar();
                }
                return true;

            case "SELECT_DOWN":
                var selectedMidiChannel = root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow];
                if (root.selectedChannel.checkIfLayerExists(selectedMidiChannel)) {
                    zynqtgui.layer.selectNextPreset(selectedMidiChannel);
                    infoBar.updateInfoBar();
                }
                return true;

            case "MODE_SWITCH_SHORT":
            case "MODE_SWITCH_LONG":
            case "MODE_SWITCH_BOLD":
                if (zynqtgui.altButtonPressed) {
                    // Cycle between channel, mixer, synths, samples, fx when alt button is not pressed
                    if (bottomStack.slotsBar.channelButton.checked) {
                        bottomStack.slotsBar.partButton.checked = true
                    } else if (bottomStack.slotsBar.partButton.checked) {
                        bottomStack.slotsBar.synthsButton.checked = true
                    } else if (bottomStack.slotsBar.synthsButton.checked) {
                        bottomStack.slotsBar.samplesButton.checked = true
                    } else if (bottomStack.slotsBar.samplesButton.checked) {
                        bottomStack.slotsBar.fxButton.checked = true
                    } else if (bottomStack.slotsBar.fxButton.checked) {
                        bottomStack.slotsBar.channelButton.checked = true
                    } else {
                        bottomStack.slotsBar.channelButton.checked = true
                    }

                    return true;
                }

                return false;

            case "SCREEN_ADMIN":
                if (root.selectedChannel && root.selectedChannel.channelAudioType === "synth") {
                    var sound = root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow]

                    // when synth and slot is active, edit that sound or show popup when empty
                    if (sound >= 0 && root.selectedChannel.checkIfLayerExists(sound)) {
                        zynqtgui.fixed_layers.activate_index(sound)
                        zynqtgui.control.single_effect_engine = null;
                        zynqtgui.current_screen_id = "control";
                        zynqtgui.forced_screen_back = "sketchpad"
                    } else {
                        bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                    }
                } else if (root.selectedChannel && ["sample-trig", "sample-slice"].indexOf(root.selectedChannel.channelAudioType) >= 0) {
                    var sample = root.selectedChannel.samples[root.selectedChannel.selectedSlotRow]

                    // when sample and slot is active, goto wave editor or show popup when empty
                    if (sample && sample.path && sample.path.length > 0) {
                        zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                        zynqtgui.bottomBarControlObj = root.selectedChannel;
                        bottomStack.slotsBar.bottomBarButton.checked = true;
                        bottomStack.bottomBar.channelWaveEditorAction.trigger();
                    } else {
                        bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                    }
                } else if (root.selectedChannel && root.selectedChannel.channelAudioType === "sample-loop") {
                    var clip = root.selectedChannel.clipsModel.getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex)

                    // when loop and slot is active, goto wave editor or show popup when empty
                    if (clip && clip.path && clip.path.length > 0) {
                        zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
                        zynqtgui.bottomBarControlObj = root.selectedChannel.clipsModel.getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex);
                        bottomStack.slotsBar.bottomBarButton.checked = true;
                        bottomStack.bottomBar.waveEditorAction.trigger();
                    } else {
                        bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                    }
                } else {
                    // do nothing for other cases
                    return false
                }

                return true

            case "KNOB3_UP":
                zynqtgui.session_dashboard.selectedChannel = Zynthian.CommonUtils.clamp(zynqtgui.session_dashboard.selectedChannel + 1, 0, 9)
                return true
            case "KNOB3_DOWN":
                zynqtgui.session_dashboard.selectedChannel = Zynthian.CommonUtils.clamp(zynqtgui.session_dashboard.selectedChannel - 1, 0, 9)
                return true
        }

        return false
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
            if (bottomStack.slotsBar.bottomBarButton.checked && // Checks if bottombar is visible
                bottomBar.tabbedView.activeAction.page.search("ChannelsViewSoundsBar") >= 0 // Checks if current active page is sound combinator or not
            ) {
                zynqtgui.soundCombinatorActive = true;
            } else {
                zynqtgui.soundCombinatorActive = false;
            }

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
                zynqtgui.slotsBarPartActive = false;
                zynqtgui.slotsBarMixerActive = false;
                zynqtgui.slotsBarSynthsActive = false;
                zynqtgui.slotsBarSamplesActive = false;
                zynqtgui.slotsBarFxActive = false;
                // zynqtgui.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.mixerButton.checked) {
                console.log("LED : Slots Mixer Bar active")
                zynqtgui.slotsBarChannelActive = false;
                zynqtgui.slotsBarPartActive = false;
                zynqtgui.slotsBarMixerActive = true;
                zynqtgui.slotsBarSynthsActive = false;
                zynqtgui.slotsBarSamplesActive = false;
                zynqtgui.slotsBarFxActive = false;
                // zynqtgui.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.partButton.checked) {
                console.log("LED : Slots Part Bar active")
                zynqtgui.slotsBarChannelActive = false;
                zynqtgui.slotsBarPartActive = true;
                zynqtgui.slotsBarMixerActive = false;
                zynqtgui.slotsBarSynthsActive = false;
                zynqtgui.slotsBarSamplesActive = false;
                zynqtgui.slotsBarFxActive = false;
                // zynqtgui.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.synthsButton.checked) {
                console.log("LED : Slots Synths Bar active")
                zynqtgui.slotsBarChannelActive = false;
                zynqtgui.slotsBarPartActive = false;
                zynqtgui.slotsBarMixerActive = false;
                zynqtgui.slotsBarSynthsActive = true;
                zynqtgui.slotsBarSamplesActive = false;
                zynqtgui.slotsBarFxActive = false;
                // zynqtgui.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.samplesButton.checked) {
                console.log("LED : Slots Samples Bar active")
                zynqtgui.slotsBarChannelActive = false;
                zynqtgui.slotsBarPartActive = false;
                zynqtgui.slotsBarMixerActive = false;
                zynqtgui.slotsBarSynthsActive = false;
                zynqtgui.slotsBarSamplesActive = true;
                zynqtgui.slotsBarFxActive = false;
                // zynqtgui.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.fxButton.checked) {
                console.log("LED : Slots FX Bar active")
                zynqtgui.slotsBarChannelActive = false;
                zynqtgui.slotsBarPartActive = false;
                zynqtgui.slotsBarMixerActive = false;
                zynqtgui.slotsBarSynthsActive = false;
                zynqtgui.slotsBarSamplesActive = false;
                zynqtgui.slotsBarFxActive = true;
                // zynqtgui.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.soundCombinatorButton.checked) {
                console.log("LED : Slots FX Bar active")
                zynqtgui.slotsBarChannelActive = false;
                zynqtgui.slotsBarPartActive = false;
                zynqtgui.slotsBarMixerActive = false;
                zynqtgui.slotsBarSynthsActive = false;
                zynqtgui.slotsBarSamplesActive = false;
                zynqtgui.slotsBarFxActive = false;
                // zynqtgui.soundCombinatorActive = true;
            } else {
                console.log("LED : No Slots Bar active")
                zynqtgui.slotsBarChannelActive = false;
                zynqtgui.slotsBarPartActive = false;
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
                return qsTr("Clone Sketchpad")
            else if (fileNameDialog.dialogType === "saveas")
                return qsTr("New version")
            else
                return qsTr("New Sketchpad")
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
        onFileSelected: {
            console.log("Selected Sketchpad : " + file.fileName + "("+ file.filePath +")")
            zynqtgui.sketchpad.loadSketchpad(file.filePath, false)
        }
    }

    function resetBottomBar(toggleBottomBar) {
        if (toggleBottomBar) {
            if (bottomStack.slotsBar.channelButton.checked) {
                bottomStack.slotsBar.partButton.checked = true
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

            visible: root.lastSelectedObj && root.lastSelectedObj.className === "sketchpad_part"
                        ? zynqtgui.slotsBarPartActive
                        : root.lastSelectedObj != null
                            ? ["sketchpad_segment", "sketchpad_sketch"].indexOf(root.lastSelectedObj.className) >= 0
                                ? false
                                : root.lastSelectedObj.className === "sketchpad_channel"
                                    ? !root.displayTrackButtons
                                    : root.lastSelectedObj.className === "sketchpad_clip"
                                        ? !root.displaySceneButtons
                                        : root.lastSelectedObj.className === "sketchpad_scene"
                                            ? root.displaySceneButtons
                                            : root.lastSelectedObj.className === "sketchpad_track"
                                                ? root.displayTrackButtons
                                                : false
                            : false

            width: root.lastSelectedObj && root.lastSelectedObj.component ? root.lastSelectedObj.component.width + 8 : 0
            height: root.lastSelectedObj && root.lastSelectedObj.component ? root.lastSelectedObj.component.height + 8 : 0
            x: root.lastSelectedObj && root.lastSelectedObj.component ? root.lastSelectedObj.component.mapToItem(content, 0, 0).x - 4 : 0
            y: root.lastSelectedObj && root.lastSelectedObj.component ? root.lastSelectedObj.component.mapToItem(content, 0, 0).y - 4 : 0
            z: 1000
            border.width: 2
            border.color: Qt.rgba(255, 255, 255, 0.8)

            color: "transparent"
        }

        Rectangle {
            id: copySourceObjIndicator

            visible: root.copySourceObj && root.copySourceObj.className === "sketchpad_part"
                        ? zynqtgui.slotsBarPartActive
                        : root.copySourceObj

            width: root.copySourceObj && root.copySourceObj.component ? root.copySourceObj.component.width : 0
            height: root.copySourceObj && root.copySourceObj.component ? root.copySourceObj.component.height : 0
            x: root.copySourceObj && root.copySourceObj.component ? root.copySourceObj.component.mapToItem(content, 0, 0).x : 0
            y: root.copySourceObj && root.copySourceObj.component ? root.copySourceObj.component.mapToItem(content, 0, 0).y : 0
            z: 1000

            color: "#882196f3"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.bottomMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: Kirigami.Units.gridUnit * 9
                spacing: 1

                ColumnLayout {
                    id: sketchpadSketchHeadersColumn
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    spacing: 1

                    TableHeader {
                        id: songCell
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: sketchpadSketchHeadersColumn.height / 2 - sketchpadSketchHeadersColumn.spacing
                        Layout.minimumHeight: sketchpadSketchHeadersColumn.height / 2 - sketchpadSketchHeadersColumn.spacing
                        Layout.maximumHeight: sketchpadSketchHeadersColumn.height / 2 - sketchpadSketchHeadersColumn.spacing

                        highlightOnFocus: false
//                        highlighted: root.displayTrackButtons
//                        text: qsTr("Track T%1").arg(root.song.scenesModel.selectedTrackIndex + 1)
                        text: qsTr("Channel\nCh%1").arg(root.selectedChannel.id + 1)
                        onPressed: {
//                            root.displayTrackButtons = !root.displayTrackButtons
//                            bottomStack.slotsBar.channelButton.checked = true
//                            zynqtgui.sketchpad.displaySceneButtons = false
                        }
                    }

                    TableHeader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        text: qsTr("Scene")
                        subText: root.song.scenesModel.selectedSceneName
                        highlightOnFocus: false
                        highlighted: root.displaySceneButtons
                        onPressed: {
                            if (zynqtgui.sketchpad.displaySceneButtons) {
                                zynqtgui.sketchpad.displaySceneButtons = false
                                bottomStack.slotsBar.channelButton.checked = true
                            } else {
                                zynqtgui.sketchpad.displaySceneButtons = true
                                bottomStack.slotsBar.partButton.checked = true
                                root.displayTrackButtons = false
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: sketchpadClipsColumn
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 1

                    // Should show arrows is True when segment count is greater than 10 and hence needs arrows to scroll
                    property bool shouldShowSegmentArrows: root.song.sketchesModel.selectedSketch.segmentsModel.count > 10
                    // Segment offset will determine what is the first segment to display when arrow keys are displayed
                    property int segmentOffset: 0
                    // Maximum segment offset allows the arrow keys to check if there are any more segments outside view
                    property int maximumSegmentOffset: root.song.sketchesModel.selectedSketch.segmentsModel.count - 10 + 2

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
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TableHeader {
                                    id: trackHeaderDelegate

                                    property QtObject channel: root.song.channelsModel.getChannel(index)
                                    property QtObject sketch: root.song.sketchesModel.getSketch(index)

                                    visible: root.displayTrackButtons
                                    anchors.fill: parent
                                    color: Kirigami.Theme.backgroundColor
                                    highlightOnFocus: false
                                    highlighted: root.displayTrackButtons
                                                    ? root.song.scenesModel.selectedTrackIndex === index
                                                    : ""

                                    text: root.displayTrackButtons
                                            ? qsTr("T%1").arg(index+1)
                                            : ""
                                    textSize: 10

                                    onPressed: {
                                        if (root.displayTrackButtons) {
                                            root.lastSelectedObj = {
                                                className: "sketchpad_track",
                                                value: index,
                                                component: trackHeaderDelegate
                                            }
                                            root.song.scenesModel.selectedTrackIndex = index
                                        }
                                    }
                                }

                                ChannelHeader2 {
                                    id: channelHeaderDelegate
                                    visible: !root.displayTrackButtons
                                    anchors.fill: parent

                                    channel: root.song.channelsModel.getChannel(index)
                                    text: channelHeaderDelegate.channel.name

                                    Connections {
                                        target: channelHeaderDelegate.channel
                                        function updateKeyZones() {
                                            // all-full is the default, but "manual" is an option and we should leave things alone in that case, so that's this function's default
                                            var sampleSettings = [];
                                            if (channelHeaderDelegate.channel.keyZoneMode == "all-full") {
                                                sampleSettings = [
                                                    [0, 127, 0],
                                                    [0, 127, 0],
                                                    [0, 127, 0],
                                                    [0, 127, 0],
                                                    [0, 127, 0]
                                                ];
                                            } else if (channelHeaderDelegate.channel.keyZoneMode == "split-full") {
                                                // auto-split keyzones: SLOT 4 c-1 - b1, SLOT 2 c1-b3, SLOT 1 c3-b5, SLOT 3 c5-b7, SLOT 5 c7-c9
                                                // root key transpose in semtitones: +48, +24 ,0 , -24, -48
                                                sampleSettings = [
                                                    [48, 71, 0], // slot 1
                                                    [24, 47, -24], // slot 2
                                                    [72, 95, 24], // slot 3
                                                    [0, 23, -48], // slot 4
                                                    [96, 119, 48] // slot 5
                                                ];
                                            } else if (channelHeaderDelegate.channel.keyZoneMode == "split-narrow") {
                                                // Narrow split puts the samples on the keys C4, D4, E4, F4, G4, and plays them as C4 on those notes
                                                sampleSettings = [
                                                    [60, 60, 0], // slot 1
                                                    [62, 62, 2], // slot 2
                                                    [64, 64, 4], // slot 3
                                                    [65, 65, 5], // slot 4
                                                    [67, 67, 7] // slot 5
                                                ];
                                            }
                                            if (sampleSettings.length > 0) {
                                                for (var i = 0; i < channelHeaderDelegate.channel.samples.length; ++i) {
                                                    var sample = channelHeaderDelegate.channel.samples[i];
                                                    var clip = Zynthbox.PlayGridManager.getClipById(sample.cppObjId);
                                                    if (clip && i < sampleSettings.length) {
                                                        clip.keyZoneStart = sampleSettings[i][0];
                                                        clip.keyZoneEnd = sampleSettings[i][1];
                                                        clip.rootNote = 60 + sampleSettings[i][2];
                                                    }
                                                }
                                            }
                                        }
                                        onKeyZoneModeChanged: updateKeyZones();
                                        onSamplesChanged: updateKeyZones();
                                    }
                                    subText: null
                                    subSubText: {
                                        if (channelHeaderDelegate.channel.channelAudioType === "sample-loop") {
                                            return qsTr("Audio")
                                        } else if (channelHeaderDelegate.channel.channelAudioType === "sample-trig") {
                                            return qsTr("Smp: Trig")
                                        } else if (channelHeaderDelegate.channel.channelAudioType === "sample-slice") {
                                            return qsTr("Smp: Slice")
                                        } else if (channelHeaderDelegate.channel.channelAudioType === "synth") {
                                            return qsTr("Synth")
                                        } else if (channelHeaderDelegate.channel.channelAudioType === "external") {
                                            return qsTr("External")
                                        }
                                    }

                                    subSubTextSize: 7

                                    Binding {
                                        target: channelHeaderDelegate
                                        property: "color"
                                        when: root.visible
                                        delayed: true

                                        value: {
                                            if (root.copySourceObj && root.copySourceObj.value === model.channel)
                                                return "#ff2196f3"
                                            else if (channelHeaderDelegate.channel.channelAudioType === "synth")
                                                return "#66ff0000"
                                            else if (channelHeaderDelegate.channel.channelAudioType === "sample-loop")
                                                return "#6600ff00"
                                            else if (channelHeaderDelegate.channel.channelAudioType === "sample-trig")
                                                return "#6600ff00"
                                            else if (channelHeaderDelegate.channel.channelAudioType === "sample-slice")
                                                return "#6600ff00"
                                            else if (channelHeaderDelegate.channel.channelAudioType === "external")
                                                return "#66ffff00"
                                            else
                                                return "#66888888"
                                        }
                                    }

                                    highlightOnFocus: false
                                    highlighted: index === zynqtgui.session_dashboard.selectedChannel // If song mode is not active, highlight if current cell is selected channel

                                    onPressed: {
                                        // If song mode is not active, clicking on cells should activate that channel
                                        root.lastSelectedObj = {
                                            className: channelHeaderDelegate.channel.className,
                                            value: channelHeaderDelegate.channel,
                                            component: channelHeaderDelegate
                                        }

                                        zynqtgui.session_dashboard.selectedChannel = index;

                                        // zynqtgui.session_dashboard.disableNextSoundSwitchTimer();

                                        Qt.callLater(function() {
                                            // Open MixedChannelsViewBar and switch to channel
                                            // bottomStack.slotsBar.channelButton.checked = true
                                            root.resetBottomBar(false)
                                            zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                            zynqtgui.bottomBarControlObj = channelHeaderDelegate.channel;
                                        })
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
                            // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                            model: zynqtgui.isBootingComplete ? root.song.channelsModel : 0

                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TableHeader {
                                    id: sceneHeader
                                    anchors.fill: parent
                                    visible: root.displaySceneButtons
                                    text: String.fromCharCode(65+index).toUpperCase()
                                    highlighted: index === root.song.scenesModel.selectedSceneIndex
                                    highlightOnFocus: false
                                    onPressed: {
//                                            root.lastSelectedObj = {
//                                                className: "sketchpad_scene",
//                                                value: index,
//                                                component: sceneHeader
//                                            }

                                            Zynthian.CommonUtils.switchToScene(index);
                                    }
                                }

                                ClipCell {
                                    id: clipCell

                                    anchors.fill: parent
                                    visible: !root.displaySceneButtons

                                    channel: model.channel
                                    backgroundColor: "#000000"
                                    onHighlightedChanged: {
                                        Qt.callLater(function () {
                                            //console.log("Clip : (" + channel.sceneClip.row+", "+channel.sceneClip.col+")", "Selected Channel :"+ zynqtgui.session_dashboard.selectedChannel)

                                            // Switch to highlighted clip only if previous selected bottombar object was a clip/pattern
//                                            if (highlighted && (zynqtgui.bottomBarControlType === "bottombar-controltype-pattern" || zynqtgui.bottomBarControlType === "bottombar-controltype-clip")) {
//                                                if (channel.connectedPattern >= 0) {
//                                                    zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
//                                                    zynqtgui.bottomBarControlObj = channel.sceneClip;
//                                                } else {
//                                                    zynqtgui.bottomBarControlType = "bottombar-controltype-clip";
//                                                    zynqtgui.bottomBarControlObj = channel.sceneClip;
//                                                }
//                                            }
                                        });
                                    }

                                    Connections {
                                        target: channel.sceneClip
                                        onInCurrentSceneChanged: colorTimer.restart()
                                        onPathChanged: colorTimer.restart()
                                        onIsPlayingChanged: colorTimer.restart()
                                    }
                                    Connections {
                                        target: channel
                                        onConnectedPatternChanged: colorTimer.restart()
                                        onChannelAudioTypeChanged: colorTimer.restart()
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
                                        onSelectedTrackIndexChanged: colorTimer.restart()
                                    }

                                    Timer {
                                        id: colorTimer
                                        interval: 10
                                        onTriggered: {
                                            // update color
//                                                if (channel.channelAudioType === "sample-loop" && channel.sceneClip && channel.sceneClip.inCurrentScene && channel.sceneClip.path && channel.sceneClip.path.length > 0) {
//                                                    // In scene
//                                                    clipCell.backgroundColor = "#3381d4fa";
//                                                } /*else if (channel.sceneClip && (!channel.sceneClip.inCurrentScene && !root.song.scenesModel.isClipInScene(channel.sceneClip, channel.sceneClip.col))) {
//                                                    // Not in scene
//                                                    clipCell.backgroundColor = "#33f44336";
//                                                }*/ else if ((channel.connectedPattern >= 0 && clipCell.pattern.hasNotes)
//                                                    || (channel.channelAudioType === "sample-loop" && channel.sceneClip.path && channel.sceneClip.path.length > 0)) {
//                                                    clipCell.backgroundColor =  Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.02)
//                                                } else {
//                                                    clipCell.backgroundColor =  Qt.rgba(0, 0, 0, 1);
//                                                }

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
                                    sequence: zynqtgui.isBootingComplete ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName) : null
                                    pattern: channel.connectedPattern >= 0 && sequence && !sequence.isLoading && sequence.count > 0 ? sequence.getByPart(channel.id, channel.selectedPart) : null

                                    onPressed: {
                                        root.lastSelectedObj = {
                                            className: channel.sceneClip.className,
                                            value: channel.sceneClip,
                                            component: clipCell
                                        }

                                        zynqtgui.session_dashboard.selectedChannel = channel.id;

                                        root.resetBottomBar(false)
                                        zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                        zynqtgui.bottomBarControlObj = channel;

//                                        zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex = channel.sceneClip.col
//                                        bottomStack.slotsBar.partButton.checked = true

//                                        Qt.callLater(function() {
//                                            if (channel.connectedPattern >= 0) {
//                                                zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
//                                                zynqtgui.bottomBarControlObj = channel.sceneClip;
//                                            } else {
//                                                zynqtgui.bottomBarControlType = "bottombar-controltype-clip";
//                                                zynqtgui.bottomBarControlObj = channel.sceneClip;
//                                            }
//                                        })
                                    }
//                                    onPressAndHold: {
//                                        zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
//                                        zynqtgui.bottomBarControlObj = channel.sceneClip;
//                                        bottomStack.slotsBar.bottomBarButton.checked = true;

//                                        if (channel.channelAudioType === "sample-loop") {
//                                            if (channel.sceneClip && channel.sceneClip.path && channel.sceneClip.path.length > 0) {
//                                                bottomStack.bottomBar.waveEditorAction.trigger();
//                                            } else {
//                                                bottomStack.bottomBar.recordingAction.trigger();
//                                            }
//                                        } else {
//                                            bottomStack.bottomBar.patternAction.trigger();
//                                        }
//                                    }
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
                    spacing: 1

                    // Common copy button to set the object to copy
                    TableHeader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        highlightOnFocus: false
                        font.pointSize: 10
                        enabled: root.lastSelectedObj && root.lastSelectedObj.className
                        text: qsTr("Copy %1").arg(root.lastSelectedObj && root.lastSelectedObj.className
                                                  ? root.lastSelectedObj.className === "sketchpad_clip"
                                                    ? qsTr("Clip")
                                                    : root.lastSelectedObj.className === "sketchpad_channel"
                                                        ? qsTr("Channel")
                                                        : root.lastSelectedObj.className === "sketchpad_track"
                                                            ? qsTr("Track")
                                                            : root.lastSelectedObj.className === "sketchpad_part"
                                                              ? qsTr("Clip")
                                                              : root.lastSelectedObj.className === "sketchpad_segment"
                                                                ? qsTr("Segment")
                                                                : root.lastSelectedObj.className === "sketchpad_sketch"
                                                                  ? qsTr("Sketch")
                                                                  : ""
                                                  : "")
                        visible: root.copySourceObj == null
                        onClicked: {
                            // Check and set copy source object from bottombar as bottombar
                            // controlObj is the current focused/selected object by user

                            root.copySourceObj = root.lastSelectedObj
                            console.log("Copy", root.copySourceObj)
                        }
                    }

                    // Common cancel button to cancel copy
                    TableHeader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        highlightOnFocus: false
                        font.pointSize: 10
                        text: qsTr("Cancel Copy")
                        visible: root.copySourceObj != null
                        onPressed: {
                            root.copySourceObj = null
                        }
                    }

                    // Common button to paste object
                    TableHeader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        highlightOnFocus: false
                        font.pointSize: 10
                        enabled: {
                            if (root.copySourceObj != null &&
                                root.copySourceObj.value &&
                                root.copySourceObj.className) {

                                // Check if source and destination are same
                                if (root.copySourceObj.className === "sketchpad_clip" &&
                                    root.copySourceObj.value !== root.song.getClip(zynqtgui.session_dashboard.selectedChannel, zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex) &&
                                    root.lastSelectedObj.className === "sketchpad_clip") {
                                    return true
                                } else if (root.copySourceObj.className === "sketchpad_channel" &&
                                           root.copySourceObj.value.id !== zynqtgui.session_dashboard.selectedChannel &&
                                           root.lastSelectedObj.className === "sketchpad_channel") {
                                    return true
                                } else if (root.copySourceObj.className === "sketchpad_track" &&
                                           root.copySourceObj.value !== root.song.scenesModel.selectedTrackIndex &&
                                           root.lastSelectedObj.className === "sketchpad_track") {
                                    return true
                                } else if (root.copySourceObj.className === "sketchpad_part" &&
                                           root.copySourceObj.value !== root.lastSelectedObj.value &&
                                           root.lastSelectedObj.className === "sketchpad_part") {
                                   return true
                                } else if (root.copySourceObj.className === "sketchpad_segment" &&
                                           root.copySourceObj.value !== root.lastSelectedObj.value &&
                                           root.lastSelectedObj.className === "sketchpad_segment" &&
                                           root.copySourceObj.value.sketchId === root.lastSelectedObj.value.sketchId) {
                                   return true
                                } else if (root.copySourceObj.className === "sketchpad_sketch" &&
                                           root.copySourceObj.value !== root.lastSelectedObj.value &&
                                           root.lastSelectedObj.className === "sketchpad_sketch") {
                                   return true
                                }
                            }

                            return false
                        }
                        text: qsTr("Paste %1").arg(root.copySourceObj && root.copySourceObj.className
                                                       ? root.copySourceObj.className === "sketchpad_clip"
                                                           ? qsTr("Clip")
                                                           : root.copySourceObj.className === "sketchpad_channel"
                                                               ? qsTr("Channel")
                                                               : root.copySourceObj.className === "sketchpad_track"
                                                                   ? qsTr("Track")
                                                                   : root.copySourceObj.className === "sketchpad_part"
                                                                     ? qsTr("Clip")
                                                                     : root.copySourceObj.className === "sketchpad_segment"
                                                                       ? qsTr("Segment")
                                                                       : root.copySourceObj.className === "sketchpad_sketch"
                                                                         ? qsTr("Sketch")
                                                                         : ""
                                                       : "")
                        onPressed: {
                            if (root.copySourceObj.className && root.copySourceObj.className === "sketchpad_clip") {
                                var sourceClip = root.copySourceObj.value
                                var destClip = root.song.getClip(zynqtgui.session_dashboard.selectedChannel, zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex)

                                // Copy Clip
                                destClip.copyFrom(sourceClip)
                                // Copy pattern
                                var sourcePattern = Zynthbox.PlayGridManager.getSequenceModel("T"+(sourceClip.col + 1)).getByPart(sourceClip.clipChannel.id, sourceClip.clipChannel.selectedPart)
                                var destPattern = Zynthbox.PlayGridManager.getSequenceModel("T"+(destClip.col + 1)).getByPart(destClip.clipChannel.id, destClip.clipChannel.selectedPart)
                                destPattern.cloneOther(sourcePattern)

                                root.copySourceObj = null
                            } else if (root.copySourceObj.className && root.copySourceObj.className === "sketchpad_channel") {
                                zynqtgui.start_loading()

                                // Copy Channel
                                var sourceChannel = root.copySourceObj.value
                                var destChannel = root.song.channelsModel.getChannel(zynqtgui.session_dashboard.selectedChannel)
                                destChannel.copyFrom(sourceChannel)

                                for (var part=0; part<5; part++) {
                                    for (var i=0; i<sourceChannel.clipsModel.count; i++) {
                                        var sourceClip = sourceChannel.parts[part].getClip(i)
                                        var destClip = destChannel.parts[part].getClip(i)
                                        var sourcePattern = Zynthbox.PlayGridManager.getSequenceModel("T"+(sourceClip.col + 1)).getByPart(sourceClip.clipChannel.id, part)
                                        var destPattern = Zynthbox.PlayGridManager.getSequenceModel("T"+(destClip.col + 1)).getByPart(destClip.clipChannel.id, part)

                                        destPattern.cloneOther(sourcePattern)
                                    }
                                }

                                root.copySourceObj = null

                                zynqtgui.stop_loading()
                            } else if (root.copySourceObj.className && root.copySourceObj.className === "sketchpad_track") {
                                zynqtgui.start_loading()

                                // Copy Track
                                root.song.scenesModel.copyTrack(root.copySourceObj.value, root.song.scenesModel.selectedTrackIndex)

                                for (var i=0; i<root.song.channelsModel.count; i++) {
                                    var channel = root.song.channelsModel.getChannel(i)
                                    var sourcePattern = Zynthbox.PlayGridManager.getSequenceModel("T"+(root.copySourceObj.value + 1)).getByPart(channel.id, channel.selectedPart)
                                    var destPattern = Zynthbox.PlayGridManager.getSequenceModel(root.song.scenesModel.selectedTrackName).getByPart(channel.id, channel.selectedPart)

                                    destPattern.cloneOther(sourcePattern)
                                }

                                root.copySourceObj = null

                                zynqtgui.stop_loading()
                            } else if (root.copySourceObj.className && root.copySourceObj.className === "sketchpad_part") {
                                var sourceClip = root.copySourceObj.value
                                var destClip = root.lastSelectedObj.value

                                // Copy Clip
                                destClip.copyFrom(sourceClip)
                                // Copy pattern
                                var sourcePattern = Zynthbox.PlayGridManager.getSequenceModel("T"+(sourceClip.col + 1)).getByPart(sourceClip.clipChannel.id, sourceClip.clipChannel.selectedPart)
                                var destPattern = Zynthbox.PlayGridManager.getSequenceModel("T"+(destClip.col + 1)).getByPart(destClip.clipChannel.id, destClip.clipChannel.selectedPart)
                                destPattern.cloneOther(sourcePattern)

                                root.copySourceObj = null
                            } else if (root.copySourceObj.className && root.copySourceObj.className === "sketchpad_segment") {
                                root.lastSelectedObj.value.copyFrom(root.copySourceObj.value)
                                root.copySourceObj = null
                            } else if (root.copySourceObj.className && root.copySourceObj.className === "sketchpad_sketch") {
                                root.lastSelectedObj.value.copyFrom(root.copySourceObj.value)
                                root.copySourceObj = null
                            }
                        }
                    }

                    TableHeader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        highlightOnFocus: false
                        font.pointSize: 10
                        enabled: root.lastSelectedObj != null &&
                                 root.lastSelectedObj.className != null &&
                                 (root.lastSelectedObj.className === "sketchpad_clip" ||
                                  root.lastSelectedObj.className === "sketchpad_segment" ||
                                  root.lastSelectedObj.className === "sketchpad_sketch")
                        text: qsTr("Clear")
                        onPressed: {
                            if (root.lastSelectedObj.value.clear) {
                                root.lastSelectedObj.value.clear()
                            }

                            if (root.lastSelectedObj.className === "sketchpad_clip") {
                                // Try clearing pattern if exists.
                                try {
                                    if (root.lastSelectedObj.value.connectedPattern >= 0) {
                                        Zynthbox.PlayGridManager.getSequenceModel("T"+(root.song.scenesModel.selectedTrackIndex + 1)).getByPart(root.lastSelectedObj.value.id, root.lastSelectedObj.value.selectedPart).clear()
                                    }
                                } catch(e) {}
                            }
                        }
                    }
                }
            }

            StackLayout {
                id: bottomStack

                property alias bottomBar: bottomBar
                property alias slotsBar: slotsBar

                Layout.fillWidth: true
                Layout.fillHeight: true
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

                MixedChannelsViewBar {
                    id: mixedChannelsViewBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                PartBar {
                    id: partBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onClicked: {
                        root.lastSelectedObj = {
                            className: "sketchpad_part",
                            value: partBar.selectedPartClip,
                            component: partBar.selectedComponent
                        }
                    }
                }

                ChannelsViewSoundsBar {
                    id: soundCombinatorBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            InfoBar {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.leftMargin: Kirigami.Units.gridUnit * 0.5
                Layout.rightMargin: Kirigami.Units.gridUnit * 0.5
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
            }
        }
    }
}
