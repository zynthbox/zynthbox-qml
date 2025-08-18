/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

// The Global Sequencer is our central connection point for handling the hardware sequencer controls (capturing events and reacting to them, updating the light state...)

Copyright (C) 2025 Dan Leinir Turthra Jensen <admin@leinir.dk>

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

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Item {
    id: component
    property QtObject selectedChannel: null
    function handleStepButtonPress(stepButtonIndex) {
        let workingModel = _private.pattern.workingModel;
        if (_private.interactionMode == 0) {
            if (zynqtgui.altButtonPressed) {
                if (stepButtonIndex < 8) {
                    if (stepButtonIndex < workingModel.availableBars) {
                        workingModel.activeBar = stepButtonIndex;
                    }
                } else {
                    let actualStepIndex = stepButtonIndex - 8;
                    workingModel.patternLength = workingModel.width * (1 + stepButtonIndex);
                }
            } else {
                let stepOffset = (workingModel.activeBar + workingModel.bankOffset) * workingModel.width;
                console.log("Toggle entry for step", stepOffset + stepButtonIndex);
            }
        } else if (_private.interactionMode == 1) {
        } else if (_private.interactionMode == 2) {
        }
    }
    function ignoreHeldStepButtonsReleases() {
        // If we're holding a step button down, make sure that we ignore the next release of those buttons
        if (zynqtgui.step1ButtonPressed) {
            zynqtgui.ignoreNextStep1ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step2ButtonPressed) {
            zynqtgui.ignoreNextStep2ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step3ButtonPressed) {
            zynqtgui.ignoreNextStep3ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step4ButtonPressed) {
            zynqtgui.ignoreNextStep4ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step5ButtonPressed) {
            zynqtgui.ignoreNextStep5ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step6ButtonPressed) {
            zynqtgui.ignoreNextStep6ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step7ButtonPressed) {
            zynqtgui.ignoreNextStep7ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step8ButtonPressed) {
            zynqtgui.ignoreNextStep8ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step9ButtonPressed) {
            zynqtgui.ignoreNextStep9ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step10ButtonPressed) {
            zynqtgui.ignoreNextStep10ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step11ButtonPressed) {
            zynqtgui.ignoreNextStep11ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step12ButtonPressed) {
            zynqtgui.ignoreNextStep12ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step13ButtonPressed) {
            zynqtgui.ignoreNextStep13ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step14ButtonPressed) {
            zynqtgui.ignoreNextStep14ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step15ButtonPressed) {
            zynqtgui.ignoreNextStep15ButtonPress = true;
            returnValue = true;
        }
        if (zynqtgui.step16ButtonPressed) {
            zynqtgui.ignoreNextStep16ButtonPress = true;
            returnValue = true;
        }
    }
    function cuiaCallback(cuia, originId, track, slot, value) {
        let returnValue = false;
        switch (cuia) {
            case "SWITCH_STEP1_RELEASED":
                if (zynqtgui.ignoreNextStep1ButtonPress == false) {
                    component.handleStepButtonPress(0);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP2_RELEASED":
                if (zynqtgui.ignoreNextStep2ButtonPress == false) {
                    component.handleStepButtonPress(1);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP3_RELEASED":
                if (zynqtgui.ignoreNextStep3ButtonPress == false) {
                    component.handleStepButtonPress(2);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP4_RELEASED":
                if (zynqtgui.ignoreNextStep4ButtonPress == false) {
                    component.handleStepButtonPress(3);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP5_RELEASED":
                if (zynqtgui.ignoreNextStep5ButtonPress == false) {
                    component.handleStepButtonPress(4);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP6_RELEASED":
                if (zynqtgui.ignoreNextStep6ButtonPress == false) {
                    component.handleStepButtonPress(5);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP7_RELEASED":
                if (zynqtgui.ignoreNextStep7ButtonPress == false) {
                    component.handleStepButtonPress(6);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP8_RELEASED":
                if (zynqtgui.ignoreNextStep8ButtonPress == false) {
                    component.handleStepButtonPress(7);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP9_RELEASED":
                if (zynqtgui.ignoreNextStep9ButtonPress == false) {
                    component.handleStepButtonPress(8);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP10_RELEASED":
                if (zynqtgui.ignoreNextStep10ButtonPress == false) {
                    component.handleStepButtonPress(9);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP11_RELEASED":
                if (zynqtgui.ignoreNextStep11ButtonPress == false) {
                    component.handleStepButtonPress(10);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP12_RELEASED":
                if (zynqtgui.ignoreNextStep12ButtonPress == false) {
                    component.handleStepButtonPress(11);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP13_RELEASED":
                if (zynqtgui.ignoreNextStep13ButtonPress == false) {
                    component.handleStepButtonPress(12);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP14_RELEASED":
                if (zynqtgui.ignoreNextStep14ButtonPress == false) {
                    component.handleStepButtonPress(13);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP15_RELEASED":
                if (zynqtgui.ignoreNextStep15ButtonPress == false) {
                    component.handleStepButtonPress(14);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP16_RELEASED":
                if (zynqtgui.ignoreNextStep16ButtonPress == false) {
                    component.handleStepButtonPress(15);
                }
                returnValue = true;
                break;
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
                component.ignoreHeldStepButtonsReleases();
                break;

            // K1 controls velocity
            case "KNOB0_TOUCHED":
                component.ignoreHeldStepButtonsReleases();
                break;
            case "KNOB0_RELEASED":
                break;
            case "KNOB0_UP":
                component.ignoreHeldStepButtonsReleases();
                break;
            case "KNOB0_DOWN":
                component.ignoreHeldStepButtonsReleases();
                break;

            // K2 controls length
            case "KNOB1_TOUCHED":
                component.ignoreHeldStepButtonsReleases();
                break;
            case "KNOB1_RELEASED":
                break;
            case "KNOB1_UP":
                component.ignoreHeldStepButtonsReleases();
                break;
            case "KNOB1_DOWN":
                component.ignoreHeldStepButtonsReleases();
                break;

            // K3 controls position
            case "KNOB2_TOUCHED":
                component.ignoreHeldStepButtonsReleases();
                break;
            case "KNOB2_RELEASED":
                break;
            case "KNOB2_UP":
                component.ignoreHeldStepButtonsReleases();
                break;
            case "KNOB2_DOWN":
                component.ignoreHeldStepButtonsReleases();
                break;

            // BK controls the note values (transposing the note, and also adjusting the current global captured note, so the display keeps making sense)
            case "KNOB3_TOUCHED":
                component.ignoreHeldStepButtonsReleases();
                break;
            case "KNOB3_RELEASED":
                break;
            case "KNOB3_UP":
                component.ignoreHeldStepButtonsReleases();
                break;
            case "KNOB3_DOWN":
                component.ignoreHeldStepButtonsReleases();
                break;

            case "SWITCH_MODE_RELEASED":
                if (_private.interactionMode === 2) {
                    _private.interactionMode = 0;
                } else {
                    _private.interactionMode = _private.interactionMode + 1;
                }
                returnValue = true;
                break;
        }
        return returnValue;
    }

    QtObject {
        id: _private
        property QtObject sequence: component.selectedChannel ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName) : null
        property QtObject pattern: sequence && component.selectedChannel ? sequence.getByClipId(component.selectedChannel.id, component.selectedChannel.selectedClip) : null
        onPatternChanged: updateLedColors()
        property color stepEmpty: Qt.rgba(0.1, 0.1, 0.1)
        property color stepWithNotes: Qt.rgba(0.1, 0.1, 0.5)
        property color stepCurrent: Qt.rgba(0.4, 0.4, 0.0)
        // The interaction modes are:
        // 0: Step sequencer (displays the 16 steps of the current bar, tapping toggles the step's entry given either the currently held note, or the clip's key)
        // 1: Track/Clip Selector
        // 2: Musical keyboard for some basic music playings
        property int interactionMode: 0
        onInteractionModeChanged: updateLedColors()
        function updateLedsForStepSequencer() {
            let workingModel = _private.pattern.workingModel;
            if (zynqtgui.altButtonPressed) {
                // First the currently selected bar (steps are filled if they are less or equal to the available bars, and current is marked as current step, so tapping sets the current bar)
                for (let stepIndex = 0; stepIndex < 8; ++stepIndex) {
                    let stepColor = _private.stepEmpty;
                    if (stepIndex < workingModel.availableBars) {
                        stepColor = _private.stepWithNotes;
                    }
                    if (stepIndex == workingModel.activeBar) {
                        stepColor = Qt.tint(stepColor, _private.stepCurrent);
                    }
                    zynqtgui.led_config.setStepButtonColor(stepIndex, stepColor);
                }
                // Second is the available bar length (steps are filled if they are less or equal to the available bars, and not filled otherwise, and tapping sets the pattern length in 16 step increments)
                for (let stepIndex = 0; stepIndex < 8; ++stepIndex) {
                    let stepColor = _private.stepEmpty;
                    if (stepIndex < workingModel.availableBars) {
                        stepColor = _private.stepWithNotes;
                    }
                    zynqtgui.led_config.setStepButtonColor(stepIndex + 8, stepColor);
                }
            } else {
                let stepOffset = (workingModel.activeBar + workingModel.bankOffset) * workingModel.width;
                for (let stepIndex = 0; stepIndex < 16; ++stepIndex) {
                    let stepColor = _private.stepEmpty;
                    let stepNote = workingModel.getNote(workingModel.activeBar + workingModel.bankOffset, stepIndex)
                    if (stepNote != null && stepNote.subnotes.length > 0) {
                        stepColor = _private.stepWithNotes;
                    }
                    let actualStepIndex = stepOffset + stepIndex;
                    if (workingModel.playbackPosition === actualStepIndex) {
                        stepColor = Qt.tint(stepColor, _private.stepCurrent);
                    }
                    zynqtgui.led_config.setStepButtonColor(stepIndex, stepColor);
                }
            }
        }
        function updateLedsForTrackClipSelector() {
            for (let stepIndex = 0; stepIndex < 16; ++stepIndex) {
                let stepColor = _private.stepEmpty;
                zynqtgui.led_config.setStepButtonColor(stepIndex, stepColor);
            }
        }
        function updateLedsForMusicalButtons() {
            for (let stepIndex = 0; stepIndex < 16; ++stepIndex) {
                let stepColor = _private.stepEmpty;
                zynqtgui.led_config.setStepButtonColor(stepIndex, stepColor);
            }
        }
        function updateLedColors() {
            // TODO This might potentially want a throttle...
            if (_private.pattern) {
                switch (_private.interactionMode) {
                    case 2:
                        _private.updateLedsForMusicalButtons();
                        break;
                    case 1:
                        _private.updateLedsForTrackClipSelector();
                        break;
                    case 0:
                    default:
                        _private.updateLedsForStepSequencer();
                        break;
                }
            }
        }
    }
    // Thoughts: When in step sequencer mode, hold alt to show a split of the current clip's bar setup (first eight handles current bar, and the other eight lets you set the length by pushing the buttons)
    Connections {
        target: _private.pattern ? _private.pattern.workingModel : null
        onLastModifiedChanged: _private.updateLedColors()
        onActiveBarChanged: _private.updateLedColors()
        onBankOffsetChanged: _private.updateLedColors()
        onPlayingColumnChanged: _private.updateLedColors()
    }
    Connections {
        target: zynqtgui
        onAltButtonPressedChanged: _private.updateLedColors()
    }

    Binding {
        target: Zynthbox.PlayGridManager
        property: "zlSketchpad"
        value: zynqtgui.sketchpad
    }
    Binding {
        target: Zynthbox.SegmentHandler
        property: "song"
        value: zynqtgui.sketchpad.song
    }
    Binding {
        target: Zynthbox.PlayfieldManager
        property: "sketchpad"
        value: zynqtgui.sketchpad.song
    }
    // Our basic structure is logically scene contains channels which contain patterns, and accessing them is done through the song's inverted-structure channels model
    // the channels contain clips models (each of which holds information for all channel/clip combinations for that channel), and each clip in that model holds the data pertaining to one scene/clip/channel
    // there is further a set of sequence models which are partnered each to a scene, and inside each sequence is a pattern, which is paired with a channel
    // Which means that, logically, the structure is actually more:
    // The scene model contains scenes
    //   Each scene contains a sequence
    //     Each sequence contains a number of patterns equal to the number of channels multiplied by the number of clips on each channel
    // The channels model contains channel objects
    //   Each channel contains a clipsModel (holding information for the clip/channel combination for all scenes), and holds clips
    //   Each clip holds information specific to that scene/clip/channel combination
    //   Each scene/clip/channel combination is corresponds to one specific pattern
    // Synchronising the states means matching each pattern with the scene/clip/channel leaf in the channel's tree of data
    // The specific pattern for a leaf can be deduced through the name of the scene, the channel's index, and the clip's index in that channel
    // and fetched from PlayGridManager by asking for the sequence by name ("T1" for example), and then
    // calling getByClipId(trackIndex, clipIndex) to fetch the specific pattern
    Repeater {
        id: tracksRepeater
        delegate: Repeater {
            id: baseTrackDelegate
            property QtObject theTrack: channel
            property int trackIndex: index
            model: baseTrackDelegate.theTrack.clips
            delegate: Repeater {
                id: trackClipDelegate
                property int clipIndex: index
                property QtObject clip: modelData
                model: trackClipDelegate.clip
                delegate: Item {
                    id: trackClipSceneDelegate
                    property QtObject sceneClip: model.clip
                    property int sceneIndex: model.index
                    property string connectedSequenceName: model.index === 0 ? "global" : "global" + (model.index + 1)
                    property QtObject sequence: null
                    property int sequenceIndex: model.index;
                    property QtObject pattern: sequence && sequence.count > 0 ? trackClipSceneDelegate.sequence.getByClipId(baseTrackDelegate.trackIndex, trackClipDelegate.clipIndex) : null;
                    property int patternIndex: sequence ? sequence.indexOf(pattern) : -1;
                    onSequenceChanged: {
                        if (trackClipSceneDelegate.sequence) {
                            trackClipSceneDelegate.sequence.sceneIndex = trackClipSceneDelegate.sceneIndex;
                            // This operation is potentially a bit pricy, as setting the song
                            // to something new will cause the global sequence to be reloaded
                            // to match what is in that song
                            trackClipSceneDelegate.sequence.song = zynqtgui.sketchpad.song;
                        }
                    }
                    onPatternChanged: {
                        if (trackClipSceneDelegate.pattern) {
                            trackClipSceneDelegate.pattern.zlChannel = baseTrackDelegate.theTrack;
                            trackClipSceneDelegate.pattern.zlClip = trackClipDelegate.clip;
                            trackClipSceneDelegate.pattern.zlScene = trackClipSceneDelegate.sceneClip;
                        }
                    }

                    Binding {
                        target: trackClipSceneDelegate
                        property: "sequence"
                        value: Zynthbox.PlayGridManager.getSequenceModel(connectedSequenceName, false); // The bool parameter here makes the system not load the patterns
                        delayed: true
                    }
                }
            }
        }
    }

    Binding {
        target: tracksRepeater
        property: "model"
        value: zynqtgui.sketchpad.song.channelsModel
        delayed: true
    }
}
