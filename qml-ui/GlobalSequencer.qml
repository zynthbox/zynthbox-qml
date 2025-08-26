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
    readonly property alias heardNotes: _private.heardNotes
    readonly property alias heardVelocities: _private.heardVelocities

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
                if (_private.heardNotes.length > 0) {
                    let workingModel = _private.pattern.workingModel;
                    let padNoteRow = workingModel.activeBar + workingModel.bankOffset;
                    let removedAtLeastOne = false;
                    // First, let's see if any of the notes in our list are already on this position, and if so, remove them
                    for (var i = 0; i < _private.heardNotes.length; ++i) {
                        var subNoteIndex = workingModel.subnoteIndex(padNoteRow, stepButtonIndex, _private.heardNotes[i].midiNote);
                        if (subNoteIndex > -1) {
                            workingModel.removeSubnote(padNoteRow, stepButtonIndex, subNoteIndex);
                            removedAtLeastOne = true;
                        }
                    }

                    // And then, only if we didn't remove anything should we be adding the notes
                    if (!removedAtLeastOne) {
                        var subNoteIndex = -1;
                        for (var i = 0; i < _private.heardNotes.length; ++i) {
                            subNoteIndex = workingModel.insertSubnoteSorted(padNoteRow, stepButtonIndex, _private.heardNotes[i]);
                            workingModel.setSubnoteMetadata(padNoteRow, stepButtonIndex, subNoteIndex, "velocity", _private.heardVelocities[i]);
                            if (workingModel.defaultNoteDuration > 0) {
                                workingModel.setSubnoteMetadata(padNoteRow, stepButtonIndex, subNoteIndex, "duration", workingModel.defaultNoteDuration);
                            }
                        }
                    }
                } else {
                    // TODO Pick the notes from that pad into the current selection
                }
            }
        } else if (_private.interactionMode == 1) {
            if (stepButtonIndex < 10) {
                // The track buttons
                zynqtgui.sketchpad.selectedTrackId = stepButtonIndex;
            } else if (stepButtonIndex < 11) {
                // The greyed out button in the middle that we need to work out what to do with
            } else if (stepButtonIndex < 16) {
                // The clip buttons
                component.selectedChannel.selectedClip = stepButtonIndex - 11;
            }
        } else if (_private.interactionMode == 2) {
            if (_private.stepKeyNotesActive[stepButtonIndex]) {
                let activeNote = _private.stepKeyNotesActive[stepButtonIndex];
                activeNote.setOff();
                activeNote.sendPitchChange(0);
                _private.stepKeyNotesActive[stepButtonIndex] = null;
            }
        }
    }
    function handleStepButtonDown(stepButtonIndex) {
        if (_private.interactionMode === 2) {
            if (_private.stepKeyNotesActive[stepButtonIndex]) {
                let activeNote = _private.stepKeyNotesActive[stepButtonIndex];
                activeNote.setOff();
                activeNote.sendPitchChange(0);
                _private.stepKeyNotesActive[stepButtonIndex] = null;
            }
            let newNote = _private.stepKeyNotes[stepButtonIndex];
            // This can be null, if the note value is out of range
            if (newNote) {
                newNote.setOn(_private.starVelocity);
                _private.stepKeyNotesActive[stepButtonIndex] = newNote;
            }
        }
    }
    function ignoreHeldStepButtonsReleases() {
        // If we're holding a step button down, make sure that we ignore the next release of those buttons
        // Do this for the sequencer interaction mode only (otherwise we'll potentially end up not releasing notes, which would be sort of weird)
        if (_private.interactionMode == 0) {
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
    }
    function cuiaCallback(cuia, originId, track, slot, value) {
        let returnValue = false;
        switch (cuia) {
            case "SWITCH_STEP1_DOWN":
                component.handleStepButtonDown(0);
                returnValue = true;
                break;
            case "SWITCH_STEP1_RELEASED":
                if (zynqtgui.ignoreNextStep1ButtonPress == false) {
                    component.handleStepButtonPress(0);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP2_DOWN":
                component.handleStepButtonDown(1);
                returnValue = true;
                break;
            case "SWITCH_STEP2_RELEASED":
                if (zynqtgui.ignoreNextStep2ButtonPress == false) {
                    component.handleStepButtonPress(1);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP3_DOWN":
                component.handleStepButtonDown(2);
                returnValue = true;
                break;
            case "SWITCH_STEP3_RELEASED":
                if (zynqtgui.ignoreNextStep3ButtonPress == false) {
                    component.handleStepButtonPress(2);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP4_DOWN":
                component.handleStepButtonDown(3);
                returnValue = true;
                break;
            case "SWITCH_STEP4_RELEASED":
                if (zynqtgui.ignoreNextStep4ButtonPress == false) {
                    component.handleStepButtonPress(3);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP5_DOWN":
                component.handleStepButtonDown(4);
                returnValue = true;
                break;
            case "SWITCH_STEP5_RELEASED":
                if (zynqtgui.ignoreNextStep5ButtonPress == false) {
                    component.handleStepButtonPress(4);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP6_DOWN":
                component.handleStepButtonDown(5);
                returnValue = true;
                break;
            case "SWITCH_STEP6_RELEASED":
                if (zynqtgui.ignoreNextStep6ButtonPress == false) {
                    component.handleStepButtonPress(5);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP7_DOWN":
                component.handleStepButtonDown(6);
                returnValue = true;
                break;
            case "SWITCH_STEP7_RELEASED":
                if (zynqtgui.ignoreNextStep7ButtonPress == false) {
                    component.handleStepButtonPress(6);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP8_DOWN":
                component.handleStepButtonDown(7);
                returnValue = true;
                break;
            case "SWITCH_STEP8_RELEASED":
                if (zynqtgui.ignoreNextStep8ButtonPress == false) {
                    component.handleStepButtonPress(7);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP9_DOWN":
                component.handleStepButtonDown(8);
                returnValue = true;
                break;
            case "SWITCH_STEP9_RELEASED":
                if (zynqtgui.ignoreNextStep9ButtonPress == false) {
                    component.handleStepButtonPress(8);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP10_DOWN":
                component.handleStepButtonDown(9);
                returnValue = true;
                break;
            case "SWITCH_STEP10_RELEASED":
                if (zynqtgui.ignoreNextStep10ButtonPress == false) {
                    component.handleStepButtonPress(9);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP11_DOWN":
                component.handleStepButtonDown(10);
                returnValue = true;
                break;
            case "SWITCH_STEP11_RELEASED":
                if (zynqtgui.ignoreNextStep11ButtonPress == false) {
                    component.handleStepButtonPress(10);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP12_DOWN":
                component.handleStepButtonDown(11);
                returnValue = true;
                break;
            case "SWITCH_STEP12_RELEASED":
                if (zynqtgui.ignoreNextStep12ButtonPress == false) {
                    component.handleStepButtonPress(11);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP13_DOWN":
                component.handleStepButtonDown(12);
                returnValue = true;
                break;
            case "SWITCH_STEP13_RELEASED":
                if (zynqtgui.ignoreNextStep13ButtonPress == false) {
                    component.handleStepButtonPress(12);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP14_DOWN":
                component.handleStepButtonDown(13);
                returnValue = true;
                break;
            case "SWITCH_STEP14_RELEASED":
                if (zynqtgui.ignoreNextStep14ButtonPress == false) {
                    component.handleStepButtonPress(13);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP15_DOWN":
                component.handleStepButtonDown(14);
                returnValue = true;
                break;
            case "SWITCH_STEP15_RELEASED":
                if (zynqtgui.ignoreNextStep15ButtonPress == false) {
                    component.handleStepButtonPress(14);
                }
                returnValue = true;
                break;
            case "SWITCH_STEP16_DOWN":
                component.handleStepButtonDown(15);
                returnValue = true;
                break;
            case "SWITCH_STEP16_RELEASED":
                if (zynqtgui.ignoreNextStep16ButtonPress == false) {
                    component.handleStepButtonPress(15);
                }
                returnValue = true;
                break;
            case "SWITCH_BACK_SHORT":
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
            // - hold star button and scroll BK to change the current pattern's key
            case "KNOB3_TOUCHED":
                component.ignoreHeldStepButtonsReleases();
                if (zynqtgui.starButtonPressed) {
                    applicationWindow().showPassiveNotification(qsTr("Clip %1 Key: %2%3")
                        .arg((_private.pattern.sketchpadTrack + 1) + _private.pattern.clipName)
                        .arg(Zynthbox.KeyScales.pitchName(_private.pattern.pitchKey))
                        .arg(Zynthbox.KeyScales.octaveName(_private.pattern.octaveKey))
                        , 1000);
                }
                break;
            case "KNOB3_RELEASED":
                component.ignoreHeldStepButtonsReleases();
                if (zynqtgui.starButtonPressed) {
                    // Release doesn't really want anything doing...
                }
                break;
            case "KNOB3_UP":
                component.ignoreHeldStepButtonsReleases();
                if (zynqtgui.starButtonPressed) {
                    let currentKey = Zynthbox.KeyScales.midiPitchValue(_private.pattern.pitchKey, _private.pattern.octaveKey);
                    if (currentKey > 0) {
                        currentKey = currentKey + 1;
                        _private.pattern.octaveKey = Zynthbox.KeyScales.midiNoteToOctave(currentKey);
                        _private.pattern.pitchKey = Zynthbox.KeyScales.midiNoteToPitch(currentKey);
                    }
                    applicationWindow().showPassiveNotification(qsTr("Clip %1 Key: %2%3")
                        .arg((_private.pattern.sketchpadTrack + 1) + _private.pattern.clipName)
                        .arg(Zynthbox.KeyScales.pitchName(_private.pattern.pitchKey))
                        .arg(Zynthbox.KeyScales.octaveName(_private.pattern.octaveKey))
                        , 1000);
                    // Since we're holding the key down while we're here, restart the note when we do the twist here
                    _private.starNote.setOff();
                    _private.starNote.sendPitchChange(0);
                    _private.starNote = Zynthbox.PlayGridManager.getNote(Zynthbox.KeyScales.midiPitchValue(_private.pattern.pitchKey, _private.pattern.octaveKey), _private.pattern.sketchpadTrack);
                    _private.starNote.setOn(_private.starVelocity);
                    returnValue = true;
                }
                break;
            case "KNOB3_DOWN":
                component.ignoreHeldStepButtonsReleases();
                if (zynqtgui.starButtonPressed) {
                    let currentKey = Zynthbox.KeyScales.midiPitchValue(_private.pattern.pitchKey, _private.pattern.octaveKey);
                    if (currentKey < 127) {
                        currentKey = currentKey - 1;
                        _private.pattern.octaveKey = Zynthbox.KeyScales.midiNoteToOctave(currentKey);
                        _private.pattern.pitchKey = Zynthbox.KeyScales.midiNoteToPitch(currentKey);
                    }
                    applicationWindow().showPassiveNotification(qsTr("Clip %1 Key: %2%3")
                        .arg((_private.pattern.sketchpadTrack + 1) + _private.pattern.clipName)
                        .arg(Zynthbox.KeyScales.pitchName(_private.pattern.pitchKey))
                        .arg(Zynthbox.KeyScales.octaveName(_private.pattern.octaveKey))
                        , 1000);
                    // Since we're holding the key down while we're here, restart the note when we do the twist here
                    _private.starNote.setOff();
                    _private.starNote.sendPitchChange(0);
                    _private.starNote = Zynthbox.PlayGridManager.getNote(Zynthbox.KeyScales.midiPitchValue(_private.pattern.pitchKey, _private.pattern.octaveKey), _private.pattern.sketchpadTrack);
                    _private.starNote.setOn(_private.starVelocity);
                    returnValue = true;
                }
                break;

            case "SWITCH_STAR_DOWN":
                // TODO Maybe we can set the key's velocity by holding star and twisting K1?
                // Note-on for the current pattern's key, save the note value in _private so we can be sure it's the same one being turned off again if people change clips or whatever while holding down the thing
                _private.starNote = Zynthbox.PlayGridManager.getNote(Zynthbox.KeyScales.midiPitchValue(_private.pattern.pitchKey, _private.pattern.octaveKey), _private.pattern.sketchpadTrack);
                _private.starNote.setOn(_private.starVelocity);
                returnValue = true;
                break;
            case "SWITCH_STAR_RELEASED":
                // Note-off for whatever's stored on the _private property, and then remove it
                _private.starNote.setOff();
                _private.starNote.sendPitchChange(0);
                _private.starNote = null;
                returnValue = true;
                break;

            case "SWITCH_MODE_RELEASED":
                // Don't swallow mode when alt is pressed, that's for tab switching on e.g. sketchpad main
                if (zynqtgui.altButtonPressed == false) {
                    if (zynqtgui.step1ButtonPressed || zynqtgui.step2ButtonPressed || zynqtgui.step3ButtonPressed || zynqtgui.step4ButtonPressed || zynqtgui.step5ButtonPressed || zynqtgui.step6ButtonPressed || zynqtgui.step7ButtonPressed || zynqtgui.step8ButtonPressed || zynqtgui.step9ButtonPressed || zynqtgui.step10ButtonPressed || zynqtgui.step11ButtonPressed || zynqtgui.step12ButtonPressed || zynqtgui.step13ButtonPressed || zynqtgui.step14ButtonPressed || zynqtgui.step15ButtonPressed || zynqtgui.step16ButtonPressed) {
                        // Don't allow switching modes when holding down a button, that just makes interaction weird...
                    } else {
                        if (_private.interactionMode === 2) {
                            _private.interactionMode = 0;
                        } else {
                            _private.interactionMode = _private.interactionMode + 1;
                        }
                    }
                    returnValue = true;
                }
                break;
        }
        return returnValue;
    }

    QtObject {
        id: _private
        property QtObject sequence: component.selectedChannel ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName) : null
        property QtObject pattern: sequence && component.selectedChannel ? sequence.getByClipId(component.selectedChannel.id, component.selectedChannel.selectedClip) : null
        // property QtObject clip: component.selectedChannel ? component.selectedChannel.getClipsModelById(component.selectedClip).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex) : null
        onPatternChanged: handlePatternDataChange()
        function handlePatternDataChange() {
            let keyNote = Zynthbox.KeyScales.midiPitchValue(pattern.pitchKey, pattern.octaveKey);
            heardNotes = [Zynthbox.PlayGridManager.getNote(keyNote, pattern.sketchpadTrack)];
            heardVelocities = [64];
            // Build out 16 steps based on the pattern's grid model
            let newStepKeyNotes = [];
            let firstStepKeyNote = pattern.gridModelStartNote;
            for (let stepIndex = 0; stepIndex < 16; ++stepIndex) {
                let stepNote = Zynthbox.KeyScales.transposeNote(firstStepKeyNote, stepIndex, pattern.scaleKey, pattern.pitchKey, pattern.octaveKey);
                newStepKeyNotes.push(Zynthbox.PlayGridManager.getNote(stepNote, pattern.sketchpadTrack));
            }
            stepKeyNotes = newStepKeyNotes;
            updateLedColors();
        }

        property color stepEmpty: Qt.rgba(0.1, 0.1, 0.1)
        property color stepWithNotes: Qt.rgba(0.1, 0.1, 0.5)
        property color stepCurrent: Qt.rgba(0.4, 0.4, 0.0)

        property var heardNotes: []
        property var heardVelocities: []
        property int noteListeningActivations: 0
        property var noteListeningNotes: []
        property var noteListeningVelocities: []

        property QtObject starNote: null
        property int starVelocity: 64

        // Should probably do a thing where we show when notes are playing when in keys mode...
        property var stepKeyNotes: []
        property var stepKeyNotesActive: [null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null]

        // The interaction modes are:
        // 0: Step sequencer (displays the 16 steps of the current bar, tapping toggles the step's entry given either the currently held note, or the clip's key)
        // 1: Track/Clip Selector
        // 2: Musical keyboard for some basic music playings
        property int interactionMode: 0
        onInteractionModeChanged: {
            updateLedColors();
            switch (interactionMode) {
                case 2:
                    applicationWindow().showPassiveNotification("3/3: Musical Keys", 1500);
                    break;
                case 1:
                    applicationWindow().showPassiveNotification("2/3: Track and Clip", 1500);
                    break;
                case 0:
                default:
                    applicationWindow().showPassiveNotification("1/3: Sequencer", 1500);
                    break;
            }
        }
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
            for (let trackIndex = 0; trackIndex < 10; ++trackIndex) {
                let stepColor = _private.stepEmpty;
                let theTrack = zynqtgui.sketchpad.song.channelsModel.getChannel(trackIndex);
                if (theTrack.occupiedSlotsCount > 0 || theTrack.occupiedSampleSlotsCount > 0) {
                    stepColor = _private.stepWithNotes;
                }
                if (zynqtgui.sketchpad.selectedTrackId == trackIndex) {
                    stepColor = Qt.tint(stepColor, _private.stepCurrent);
                }
                // Maybe mark red when muted?
                zynqtgui.led_config.setStepButtonColor(trackIndex, stepColor);
            }
            // Last button's not really a thing for now, grey it out...
            zynqtgui.led_config.setStepButtonColor(10, _private.stepEmpty);
            for (let clipIndex = 0; clipIndex < 5; ++clipIndex) {
                let stepColor = _private.stepEmpty;
                let clipPattern = _private.sequence.getByClipId(component.selectedChannel.id, clipIndex);
                if (clipPattern.currentBankHasNotes) {
                    stepColor = _private.stepWithNotes;
                }
                if (component.selectedChannel.selectedClip === clipIndex) {
                    stepColor = Qt.tint(stepColor, _private.stepCurrent);
                }
                zynqtgui.led_config.setStepButtonColor(clipIndex + 11, stepColor);
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
    Connections {
        target: _private.pattern
        onGridModelStartNoteChanged: _private.handlePatternDataChange()
        onScaleChanged: _private.handlePatternDataChange()
        onOctaveChanged: _private.handlePatternDataChange()
        onPitchChanged: _private.handlePatternDataChange()
    }
    Connections {
        target: Zynthbox.MidiRouter
        enabled: zynqtgui.ui_settings.hardwareSequencer
        onMidiMessage: function(port, size, byte1, byte2, byte3, sketchpadTrack, fromInternal) {
            // console.log("Midi message of size", size, "received on port", port, "with bytes", byte1, byte2, byte3, "from track", sketchpadTrack, fromInternal, "current pattern's channel index", _private.pattern.sketchpadTrack, "listening on port", listenToPort);
            let targetTrack = Zynthbox.MidiRouter.sketchpadTrackTargetTrack(_private.pattern.sketchpadTrack);
            if ((port == Zynthbox.MidiRouter.HardwareInPassthroughPort || port == Zynthbox.MidiRouter.InternalControllerPassthroughPort)
                && (targetTrack == _private.pattern.sketchpadTrack
                    ? sketchpadTrack == _private.pattern.sketchpadTrack
                    : sketchpadTrack == targetTrack
                )
                && size === 3) {
                if (127 < byte1 && byte1 < 160) {
                    let setOn = true;
                    // By convention, an "off" note can be either a midi off message, or an on message with a velocity of 0
                    if (byte1 < 144 || byte3 === 0) {
                        setOn = false;
                    }
                    let midiNote = byte2;
                    let velocity = byte3;
                    if (setOn === true) {
                        if (_private.noteListeningActivations === 0) {
                            // Clear the current state, in case there's something there (otherwise things look a little weird)
                            _private.heardNotes = [];
                            _private.heardVelocities = [];
                        }
                        // Count up one tick for a note on message
                        _private.noteListeningActivations = _private.noteListeningActivations + 1;
                        // Create a new note based on the new thing that just arrived, but only if it's an on note
                        var newNote = Zynthbox.PlayGridManager.getNote(midiNote, _private.pattern.sketchpadTrack);
                        var existingIndex = _private.noteListeningNotes.indexOf(newNote);
                        if (existingIndex > -1) {
                            _private.noteListeningNotes.splice(existingIndex, 1);
                            _private.noteListeningVelocities.splice(existingIndex, 1);
                        }
                        _private.noteListeningNotes.push(newNote);
                        _private.noteListeningVelocities.push(velocity);
                        // console.log("Registering note on , new activation count is", _private.noteListeningActivations, _private.noteListeningNotes);
                    } else if (setOn == false) {
                        // Count down one for a note off message
                        _private.noteListeningActivations = _private.noteListeningActivations - 1;
                        // console.log("Registering note off, new activation count is", _private.noteListeningActivations, _private.noteListeningNotes, _private.noteListeningVelocities);
                    }
                    if (_private.noteListeningActivations < 0) {
                        // this will generally happen after stopping playback (as the playback stops, then all off notes are sent out,
                        // and we'll end up receiving a bunch of them while not doing playback, without having received matching on notes)
                        // it might still happen at other times, so we might still need to do some testing later, but... this is the general case.
                        // console.debug("stepsequencer: Problem, we've received too many off notes compared to on notes, this is bad and shouldn't really be happening.");
                        _private.noteListeningActivations = 0;
                        _private.noteListeningNotes = [];
                        _private.noteListeningVelocities = [];
                    }
                    if (_private.noteListeningActivations > 0) {
                        // As we listen, assign all the heard notes to the heard notes thinger so we show things as we listen
                        _private.heardNotes = _private.noteListeningNotes;
                        _private.heardVelocities = _private.noteListeningVelocities;
                    }
                    if (_private.noteListeningActivations === 0) {
                        // Now, if we're back down to zero, then we've had all the notes released, and we should clear our lists, ready for next go
                        _private.noteListeningNotes = [];
                        _private.noteListeningVelocities = [];
                    }
                } else if (175 < byte1 && byte1 < 192 && byte2 === 123) {
                    // console.log("Registering all-off, resetting to empty, bytes are", byte1, byte2, byte3);
                    _private.noteListeningActivations = 0;
                    _private.noteListeningNotes = [];
                    _private.noteListeningVelocities = [];
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
