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


import io.zynthbox.ui 1.0 as ZUI
import io.zynthbox.components 1.0 as Zynthbox

Item {
    id: component
    readonly property alias heardNotes: _private.heardNotes
    readonly property alias heardVelocities: _private.heardVelocities

    property QtObject selectedChannel: null
    readonly property alias parameterPage: _private.parameterPage
    function setParameterPage(parameterPage) {
        _private.parameterPage = Math.max(0, Math.min(parameterPage, 2));
    }

    /**
     * Update the velocity of all matching subnotes on the given step
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size, and 0 to simply display the current value
     * @param stepButtonIndex The index of the step inside the currently active bar you wish to adjust/display the velocity for
     */
    function updateStepVelocity(sign, stepButtonIndex) {
        updateStepProperty(sign, stepButtonIndex, "velocity");
    }
    /**
     * Update the duration of all matching subnotes on the given step
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size, and 0 to simply display the current value
     * @param stepButtonIndex The index of the step inside the currently active bar you wish to adjust/display the duration for
     */
    function updateStepDuration(sign, stepButtonIndex) {
        updateStepProperty(sign, stepButtonIndex, "duration");
    }
    /**
     * Update the delay/position of all matching subnotes on the given step
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size, and 0 to simply display the current value
     * @param stepButtonIndex The index of the step inside the currently active bar you wish to adjust/display the delay/position for
     */
    function updateStepDelay(sign, stepButtonIndex) {
        updateStepProperty(sign, stepButtonIndex, "delay");
    }
    /**
     * Update the delay/position of all matching subnotes on the given step
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size, and 0 to simply display the current value
     * @param stepButtonIndex The index of the step inside the currently active bar you wish to adjust/display the delay/position for
     */
    function updateStepPosition(sign, stepButtonIndex) {
        updateStepProperty(sign, stepButtonIndex, "delay");
    }
    /**
     * Update the probability of all matching subnotes on the given step
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size, and 0 to simply display the current value
     * @param stepButtonIndex The index of the step inside the currently active bar you wish to adjust/display the probability for
     */
    function updateStepProbability(sign, stepButtonIndex) {
        updateStepProperty(sign, stepButtonIndex, "probability");
    }
    /**
     * Update the next-step property of all matching subnotes on the given step
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size, and 0 to simply display the current value
     * @param stepButtonIndex The index of the step inside the currently active bar you wish to adjust/display the next-step property for
     */
    function updateStepNextStep(sign, stepButtonIndex) {
        updateStepProperty(sign, stepButtonIndex, "next-step");
    }
    /**
     * Update the ratchet style of all matching subnotes on the given step
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size, and 0 to simply display the current value
     * @param stepButtonIndex The index of the step inside the currently active bar you wish to adjust/display the ratchet style for
     */
    function updateStepRatchetStyle(sign, stepButtonIndex) {
        updateStepProperty(sign, stepButtonIndex, "ratchet-style");
    }
    /**
     * Update the ratchet count of all matching subnotes on the given step
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size, and 0 to simply display the current value
     * @param stepButtonIndex The index of the step inside the currently active bar you wish to adjust/display the ratchet count for
     */
    function updateStepRatchetCount(sign, stepButtonIndex) {
        updateStepProperty(sign, stepButtonIndex, "ratchet-count");
    }
    /**
     * Update the ratchet probability of all matching subnotes on the given step
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size, and 0 to simply display the current value
     * @param stepButtonIndex The index of the step inside the currently active bar you wish to adjust/display the ratchet probability for
     */
    function updateStepRatchetProbability(sign, stepButtonIndex) {
        updateStepProperty(sign, stepButtonIndex, "ratchet-probability");
    }
    /**
     * Update the given property of all matching subnotes on the given step
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size, and 0 to simply display the current value
     * @param stepButtonIndex The index of the step inside the currently active bar you wish to adjust/display the property for
     * @param propertyName The name of the property you wish to adjust (currently supported: velocity, duration, delay)
     */
    function updateStepProperty(sign, stepButtonIndex, propertyName) {
        let workingModel = _private.pattern.workingModel;
        let padNoteRow = workingModel.activeBar + workingModel.bankOffset;
        let stepIndex = padNoteRow * workingModel.width + stepButtonIndex;
        let subnoteIndices = [];
        let subnoteValues = [];
        let subnoteDifferences = [];
        let valueAdjustment = 0;
        let initialValue = 0;
        if (propertyName == "velocity") {
            initialValue = workingModel.defaultVelocity;
        }

        let stepNote = workingModel.getNote(padNoteRow, stepButtonIndex);
        let totalSubnoteCount = 0;
        if (stepNote != null) {
            totalSubnoteCount = stepNote.subnotes.length;
        }
        function addSubnoteForEditing(subnoteIndex) {
            subnoteIndices.push(subnoteIndex);
            let tempData = workingModel.subnoteMetadata(padNoteRow, stepButtonIndex, subnoteIndex, propertyName);
            if (tempData == undefined) {
                tempData = initialValue;
            }
            subnoteValues.push(tempData);
            if (subnoteDifferences.length == 0) {
                // The first element has no difference to itself (that is, that's our reference)
                subnoteDifferences.push(0);
            } else {
                // All subsequent entries are those entries' difference from the reference value
                subnoteDifferences.push(tempData - subnoteDifferences[0]);
            }
        }
        if (zynqtgui.ui_settings.hardwareSequencerEditInclusions === 1) {
            for (let i = 0; i < totalSubnoteCount; ++i) {
                addSubnoteForEditing(i);
            }
        } else {
            for (let i = 0; i < _private.heardNotes.length; ++i) {
                let subnoteIndex = workingModel.subnoteIndex(padNoteRow, stepButtonIndex, _private.heardNotes[i].midiNote);
                if (subnoteIndex > -1) {
                    addSubnoteForEditing(subnoteIndex);
                }
            }
        }
        // console.log(subnoteIndices, subnoteValues);
        if (subnoteIndices.length > 0) {
            function valueSetter(value) {
                valueAdjustment = value;
                // console.log("Adjusting", propertyName, "by", valueAdjustment);
                let theDescripton = "";
                let theDefaultValue = undefined;
                let theCurrentValue = 0;
                let theStartValue = 0;
                let theStopValue = 0;
                let theCurrentValueLabel = "";
                let doPreview = false;
                function setValue(value) {
                    for (let i = 0; i < subnoteIndices.length; ++i) {
                        let newValue = ZUI.CommonUtils.clamp(value + subnoteDifferences[i], theStartValue, theStopValue);
                        if (newValue == initialValue) {
                            // If we're setting to the property's default value, then we really should be *unsetting* it instead
                            newValue = theDefaultValue;
                        }
                        workingModel.setSubnoteMetadata(padNoteRow, stepButtonIndex, subnoteIndices[i], propertyName, newValue);
                    }
                    component.handleStepDataChanged(stepIndex);
                }
                if (propertyName == "velocity") {
                    if (subnoteIndices.length === totalSubnoteCount) {
                        theDescripton = qsTr("Step %1 Entry Velocity for all entries").arg(stepIndex + 1);
                    } else if (subnoteIndices.length > 1) {
                        theDescripton = qsTr("Step %1 Entry Velocity for %2 entries").arg(stepIndex + 1).arg(subnoteIndices.length);
                    } else {
                        theDescripton = qsTr("Step %1 Entry %2 Velocity").arg(stepIndex + 1).arg(subnoteIndices[0] + 1);
                    }
                    theStartValue = -1;
                    theStopValue = 127;
                    if (valueAdjustment != 0) {
                        setValue(subnoteValues[0] + valueAdjustment);
                    }
                    theCurrentValue = workingModel.subnoteMetadata(padNoteRow, stepButtonIndex, subnoteIndices[0], propertyName);
                    if (theCurrentValue == undefined) {
                        theCurrentValue = initialValue;
                    }
                    if (theCurrentValue == -1) {
                        theCurrentValueLabel = qsTr("Untriggered");
                    } else if (theCurrentValue == 0) {
                        theCurrentValueLabel = qsTr("%1 (auto, clip default)").arg(workingModel.defaultVelocity);
                    } else {
                        theCurrentValueLabel = qsTr("%1").arg(theCurrentValue);
                    }
                } else if (propertyName == "duration") {
                    if (subnoteIndices.length === totalSubnoteCount) {
                        theDescripton = qsTr("Step %1 Entry Length for all entries").arg(stepIndex + 1);
                    } else if (subnoteIndices.length > 1) {
                        theDescripton = qsTr("Step %1 Entry Length for %2 entries").arg(stepIndex + 1).arg(subnoteIndices.length);
                    } else {
                        theDescripton = qsTr("Step %1 Entry %2 Length").arg(stepIndex + 1).arg(subnoteIndices[0] + 1);
                    }
                    theStartValue = -1;
                    theStopValue = 1024;
                    if (valueAdjustment != 0) {
                        setValue(subnoteValues[0] + valueAdjustment);
                    }
                    theCurrentValue = workingModel.subnoteMetadata(padNoteRow, stepButtonIndex, subnoteIndices[0], propertyName);
                    if (theCurrentValue == undefined) {
                        theCurrentValue = initialValue;
                    }
                    if (theCurrentValue == -1) {
                        if (workingModel.defaultNoteDuration === 0) {
                            theCurrentValueLabel = qsTr("Use default note length (currently step length: %1)").arg(workingModel.stepLengthName(workingModel.stepLength));
                        } else {
                            theCurrentValueLabel = qsTr("Use default note length (currently %1)").arg(workingModel.stepLengthName(workingModel.defaultNoteDuration));
                        }
                    } else if (theCurrentValue == 0) {
                        theCurrentValueLabel = qsTr("Use step length (currently %1)").arg(workingModel.stepLengthName(workingModel.stepLength));
                    } else {
                        theCurrentValueLabel = workingModel.stepLengthName(theCurrentValue);
                    }
                } else if (propertyName == "delay" || propertyName == "position") {
                    if (subnoteIndices.length === totalSubnoteCount) {
                        theDescripton = qsTr("Step %1 Entry Position for all entries").arg(stepIndex + 1);
                    } else if (subnoteIndices.length > 1) {
                        theDescripton = qsTr("Step %1 Entry Position for %2 entries").arg(stepIndex + 1).arg(subnoteIndices.length);
                    } else {
                        theDescripton = qsTr("Step %1 Entry %2 Position").arg(stepIndex + 1).arg(subnoteIndices[0] + 1);
                    }
                    theStartValue = -workingModel.stepLength;
                    theStopValue = workingModel.stepLength;
                    if (valueAdjustment != 0) {
                        setValue(subnoteValues[0] + valueAdjustment);
                    }
                    theCurrentValue = workingModel.subnoteMetadata(padNoteRow, stepButtonIndex, subnoteIndices[0], "delay");
                    if (theCurrentValue == undefined) {
                        theCurrentValue = initialValue;
                    }
                    if (theCurrentValue == 0) {
                        theCurrentValueLabel = qsTr("On-grid (no adjustment)");
                    } else if (theCurrentValue < 0) {
                        theCurrentValueLabel = qsTr("-%1").arg(workingModel.stepLengthName(theCurrentValue));
                    } else {
                        theCurrentValueLabel = workingModel.stepLengthName(theCurrentValue);
                    }
                } else if (propertyName == "probability") {
                    if (subnoteIndices.length === totalSubnoteCount) {
                        theDescripton = qsTr("Step %1 Entry Probability for all entries").arg(stepIndex + 1);
                    } else if (subnoteIndices.length > 1) {
                        theDescripton = qsTr("Step %1 Entry Probability for %2 entries").arg(stepIndex + 1).arg(subnoteIndices.length);
                    } else {
                        theDescripton = qsTr("Step %1 Entry %2 Probability").arg(stepIndex + 1).arg(subnoteIndices[0] + 1);
                    }
                    theStartValue = 0;
                    theStopValue = workingModel.probabilityMax() - 1;
                    if (valueAdjustment != 0) {
                        setValue(subnoteValues[0] + valueAdjustment);
                    }
                    theCurrentValue = workingModel.subnoteMetadata(padNoteRow, stepButtonIndex, subnoteIndices[0], "probability");
                    if (theCurrentValue == undefined) {
                        theCurrentValue = initialValue;
                    }
                    theCurrentValueLabel = workingModel.probabilityName(theCurrentValue);
                } else if (propertyName == "next-step") {
                    if (subnoteIndices.length === totalSubnoteCount) {
                        theDescripton = qsTr("Step %1 Entry Next Step for all entries").arg(stepIndex + 1);
                    } else if (subnoteIndices.length > 1) {
                        theDescripton = qsTr("Step %1 Entry Next Step for %2 entries").arg(stepIndex + 1).arg(subnoteIndices.length);
                    } else {
                        theDescripton = qsTr("Step %1 Entry %2 Next Step").arg(stepIndex + 1).arg(subnoteIndices[0] + 1);
                    }
                    theStartValue = 0;
                    theStopValue = workingModel.width * workingModel.bankLength;
                    if (valueAdjustment != 0) {
                        setValue(subnoteValues[0] + valueAdjustment);
                    }
                    theCurrentValue = workingModel.subnoteMetadata(padNoteRow, stepButtonIndex, subnoteIndices[0], "next-step");
                    if (theCurrentValue == undefined) {
                        theCurrentValue = initialValue;
                    }
                    if (theCurrentValue == 0) {
                        theCurrentValueLabel = qsTr("Next Step (default)");
                    } else if ((theCurrentValue - 1)% workingModel.width == 0) {
                        theCurrentValueLabel = qsTr("Bar %1").arg((theCurrentValue - 1) % 12 + 1);
                    } else {
                        theCurrentValueLabel = qsTr("Step %1").arg(theCurrentValue);
                    }
                } else if (propertyName == "ratchet-style") {
                    if (subnoteIndices.length === totalSubnoteCount) {
                        theDescripton = qsTr("Step %1 Entry Ratchet Style for all entries").arg(stepIndex + 1);
                    } else if (subnoteIndices.length > 1) {
                        theDescripton = qsTr("Step %1 Entry Ratchet Style for %2 entries").arg(stepIndex + 1).arg(subnoteIndices.length);
                    } else {
                        theDescripton = qsTr("Step %1 Entry %2 Ratchet Style").arg(stepIndex + 1).arg(subnoteIndices[0] + 1);
                    }
                    theStartValue = 0;
                    theStopValue = 4;
                    if (valueAdjustment != 0) {
                        setValue(subnoteValues[0] + valueAdjustment);
                    }
                    theCurrentValue = workingModel.subnoteMetadata(padNoteRow, stepButtonIndex, subnoteIndices[0], "ratchet-style");
                    if (theCurrentValue == undefined) {
                        theCurrentValue = initialValue;
                    }
                    if (theCurrentValue == 0) {
                        theCurrentValueLabel = qsTr("Split Step, Overlap (default)");
                    } else if (theCurrentValue == 0) {
                        theCurrentValueLabel = qsTr("Split Step, Choke");
                    } else if (theCurrentValue == 0) {
                        theCurrentValueLabel = qsTr("Split Length, Overlap");
                    } else {
                        theCurrentValueLabel = qsTr("Split Length, Choke");
                    }
                } else if (propertyName == "ratchet-count") {
                    if (subnoteIndices.length === totalSubnoteCount) {
                        theDescripton = qsTr("Step %1 Entry Ratchet Count for all entries").arg(stepIndex + 1);
                    } else if (subnoteIndices.length > 1) {
                        theDescripton = qsTr("Step %1 Entry Ratchet Count for %2 entries").arg(stepIndex + 1).arg(subnoteIndices.length);
                    } else {
                        theDescripton = qsTr("Step %1 Entry %2 Ratchet Count").arg(stepIndex + 1).arg(subnoteIndices[0] + 1);
                    }
                    theStartValue = 0;
                    theStopValue = 12;
                    if (valueAdjustment != 0) {
                        setValue(subnoteValues[0] + valueAdjustment);
                    }
                    theCurrentValue = workingModel.subnoteMetadata(padNoteRow, stepButtonIndex, subnoteIndices[0], "ratchet-count");
                    if (theCurrentValue == undefined) {
                        theCurrentValue = initialValue;
                    }
                    if (theCurrentValue == 0) {
                        theCurrentValueLabel = qsTr("No Ratchet (default)");
                    } else {
                        theCurrentValueLabel = qsTr("Repeat %1 times").arg(theCurrentValue);
                    }
                } else if (propertyName == "ratchet-probability") {
                    if (subnoteIndices.length === totalSubnoteCount) {
                        theDescripton = qsTr("Step %1 Entry Ratchet Probability for all entries").arg(stepIndex + 1);
                    } else if (subnoteIndices.length > 1) {
                        theDescripton = qsTr("Step %1 Entry Ratchet Probability for %2 entries").arg(stepIndex + 1).arg(subnoteIndices.length);
                    } else {
                        theDescripton = qsTr("Step %1 Entry %2 Ratchet Probability").arg(stepIndex + 1).arg(subnoteIndices[0] + 1);
                    }
                    theStartValue = 0;
                    theStopValue = 100;
                    if (valueAdjustment != 0) {
                        setValue(subnoteValues[0] + valueAdjustment);
                    }
                    theCurrentValue = workingModel.subnoteMetadata(padNoteRow, stepButtonIndex, subnoteIndices[0], "ratchet-probability");
                    if (theCurrentValue == undefined) {
                        theCurrentValue = initialValue;
                    }
                    if (theCurrentValue == 0) {
                        theCurrentValueLabel = qsTr("All Repeats Always Play (default)");
                    } else {
                        theCurrentValueLabel = qsTr("%1% Per Repeat").arg(theCurrentValue);
                    }
                }
                // console.log("The first entry's", propertyName, "is", theCurrentValue);
                applicationWindow().showOsd({
                                                parameterName: "subnote_value",
                                                description: theDescripton,
                                                start: theStartValue,
                                                stop: theStopValue,
                                                step: 1,
                                                defaultValue: initialValue,
                                                currentValue: parseFloat(theCurrentValue),
                                                startLabel: qsTr("%1").arg(theStartValue),
                                                stopLabel: qsTr("%1").arg(theStopValue),
                                                valueLabel: theCurrentValueLabel,
                                                setValueFunction: setValue,
                                                showValueLabel: true,
                                                showResetToDefault: true,
                                                showVisualZero: false
                                            });
            }
            valueSetter(valueAdjustment + sign);
        } else {
            if (_private.heardNotes.length == 0) {
                applicationWindow().showPassiveNotification(qsTr("Step %1 does not contain %2").arg(stepIndex + 1).arg(Zynthbox.Chords.shorthand(_private.heardNotes, workingModel.scaleKey, workingModel.pitchKey, workingModel.octaveKey)));
            } else {
                applicationWindow().showPassiveNotification(qsTr("Step %1 does not contain any of %2").arg(stepIndex + 1).arg(Zynthbox.Chords.shorthand(_private.heardNotes, workingModel.scaleKey, workingModel.pitchKey, workingModel.octaveKey)));
            }
        }
    }

    /**
     * Update the given property of the given pattern in the given track
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size, and 0 to simply display the current value
     * @param propertyName The name of the property to change
     * @param trackIndex The index of the track the clip is in
     * @param clipIndex The index of the pattern in that track
     */
    function updatePatternProperty(sign, propertyName, trackIndex, clipIndex) {
        let patternModel = _private.sequence.getByClipId(trackIndex, clipIndex);
        let workingModel = patternModel.workingModel;
        let initialValue = 0;
        let valueAdjustment = 0;
        if (propertyName == "stepLength") {
            initialValue = workingModel.stepLength;
        } else if (propertyName == "swing") {
            initialValue = workingModel.swing;
        } else if (propertyName == "patternLength") {
            initialValue = workingModel.patternLength;
        }

        function valueSetter(value) {
            let theDescripton = "";
            let theDefaultValue = 0;
            let theCurrentValue = 0;
            let theStartValue = 0;
            let theStopValue = 0;
            let theCurrentValueLabel = "";
            if (propertyName == "stepLength") {
                theDescripton = qsTr("Clip %1%2 Step Length").arg(trackIndex + 1).arg(workingModel.clipName);
                theStartValue = 1;
                theStopValue = 6144;
                workingModel.stepLength = ZUI.CommonUtils.clamp(value, theStartValue, theStopValue);
                theDefaultValue = 24;
                theCurrentValue = workingModel.stepLength;
                theCurrentValueLabel = workingModel.stepLengthName(theCurrentValue);
            } else if (propertyName == "swing") {
                theDescripton = qsTr("Clip %1%2 Swing").arg(trackIndex + 1).arg(workingModel.clipName);
                theStartValue = 1;
                theStopValue = 99;
                workingModel.swing = ZUI.CommonUtils.clamp(value, theStartValue, theStopValue);
                theDefaultValue = 50;
                theCurrentValue = workingModel.swing;
                theCurrentValueLabel = workingModel.swing == 50 ? qsTr("No Swing") : qsTr("%1").arg(workingModel.swing);
            } else if (propertyName == "patternLength") {
                theDescripton = qsTr("Clip %1%2 Pattern Length").arg(trackIndex + 1).arg(workingModel.clipName);
                theStartValue = 1;
                theStopValue = workingModel.bankLength * workingModel.width;
                workingModel.patternLength = ZUI.CommonUtils.clamp(value, theStartValue, theStopValue);
                theDefaultValue = workingModel.width;
                theCurrentValue = workingModel.patternLength;
                theCurrentValueLabel = workingModel.availableBars * workingModel.width === workingModel.patternLength
                    ? workingModel.availableBars + " Bars"
                    : "%1.%2 Bars".arg(workingModel.availableBars - 1).arg(workingModel.patternLength - ((workingModel.availableBars - 1) * workingModel.width))
            }
            applicationWindow().showOsd({
                                            parameterName: "pattern_%1".arg(propertyName),
                                            description: theDescripton,
                                            start: theStartValue,
                                            stop: theStopValue,
                                            step: 1,
                                            defaultValue: theDefaultValue,
                                            currentValue: parseFloat(theCurrentValue),
                                            startLabel: qsTr("%1").arg(theStartValue),
                                            stopLabel: qsTr("%1").arg(theStopValue),
                                            valueLabel: theCurrentValueLabel,
                                            setValueFunction: valueSetter,
                                            showValueLabel: true,
                                            showResetToDefault: true,
                                            showVisualZero: true
                                        });
        }
        valueSetter(initialValue + sign);
    }

    function handleStepButtonPress(stepButtonIndex) {
        let workingModel = _private.pattern.workingModel;
        if (_private.interactionMode === _private.interactionModeSequencer) {
            if (zynqtgui.altButtonPressed) {
                if (zynqtgui.backButtonPressed) {
                    zynqtgui.ignoreNextBackButtonPress = true;
                    // Clear the bar contents when holding down the alt+back buttons and pressing a step
                } else {
                    if (stepButtonIndex < 8) {
                        if (stepButtonIndex < workingModel.availableBars) {
                            workingModel.activeBar = stepButtonIndex;
                        }
                    } else {
                        let actualStepIndex = stepButtonIndex - 8;
                        workingModel.patternLength = workingModel.width * (1 + actualStepIndex);
                    }
                }
            } else if (zynqtgui.backButtonPressed) {
                zynqtgui.ignoreNextBackButtonPress = true;
                // Clear the step contents when holding down the back button and pressing a step
            } else if (zynqtgui.playButtonPressed) {
                // Do nothing (the test play wants to happen on down)
            } else {
                let stepOffset = (workingModel.activeBar + workingModel.bankOffset) * workingModel.width;
                // console.log("Toggle entry for step", stepOffset + stepButtonIndex);
                if (_private.heardNotes.length > 0) {
                    let workingModel = _private.pattern.workingModel;
                    let padNoteRow = workingModel.activeBar + workingModel.bankOffset;
                    let removedAtLeastOne = false;
                    // First, let's see if any of the notes in our list are already on this position, and if so, remove them
                    for (var i = 0; i < _private.heardNotes.length; ++i) {
                        var subNoteIndex = workingModel.subnoteIndex(padNoteRow, stepOffset + stepButtonIndex, _private.heardNotes[i].midiNote);
                        if (subNoteIndex > -1) {
                            workingModel.removeSubnote(padNoteRow, stepOffset + stepButtonIndex, subNoteIndex);
                            removedAtLeastOne = true;
                        }
                    }

                    // And then, only if we didn't remove anything should we be adding the notes
                    if (!removedAtLeastOne) {
                        var subNoteIndex = -1;
                        for (var i = 0; i < _private.heardNotes.length; ++i) {
                            subNoteIndex = workingModel.insertSubnoteSorted(padNoteRow, stepOffset + stepButtonIndex, _private.heardNotes[i]);
                            workingModel.setSubnoteMetadata(padNoteRow, stepOffset + stepButtonIndex, subNoteIndex, "velocity", _private.heardVelocities[i]);
                            if (workingModel.defaultNoteDuration > 0) {
                                workingModel.setSubnoteMetadata(padNoteRow, stepOffset + stepButtonIndex, subNoteIndex, "duration", workingModel.defaultNoteDuration);
                            }
                        }
                    }
                } else {
                    // TODO Pick the notes from that pad into the current selection
                }
            }
        } else if (_private.interactionMode === _private.interactionModeTrackClip) {
            if (zynqtgui.backButtonPressed) {
                zynqtgui.ignoreNextBackButtonPress = true;
                // Clear the track/clip contents when holding down the back button and pressing a step
            } else {
                if (stepButtonIndex < 10) {
                    // The track buttons
                    zynqtgui.sketchpad.selectedTrackId = stepButtonIndex;
                } else if (stepButtonIndex < 11) {
                    // The greyed out button in the middle that we need to work out what to do with
                } else if (stepButtonIndex < 16) {
                    // The clip buttons
                    component.selectedChannel.selectedClip = stepButtonIndex - 11;
                }
            }
        } else if (_private.interactionMode === _private.interactionModeMusicalKeys) {
            if (_private.stepKeyNotesActive[stepButtonIndex]) {
                let activeNote = _private.stepKeyNotesActive[stepButtonIndex];
                activeNote.setOff();
                activeNote.sendPitchChange(0);
                activeNote.sendPolyphonicAftertouch(0);
                _private.stepKeyPitchBend[stepButtonIndex] = 0;
                _private.stepKeyPolyphonicAftertouch[stepButtonIndex] = 0;
                _private.stepKeyNotesActive[stepButtonIndex] = null;
            }
        } else if (_private.interactionMode === _private.interactionModeVelocityKeys) {
            // If we've released all the buttons... stop any active notes (to allow for aftertouch to be a thing)
            let anyHeldButton = false;
            for (let buttonIndex = 0; buttonIndex < _private.heldStepButtons.length; ++buttonIndex) {
                if (_private.heldStepButtons[buttonIndex]) {
                    anyHeldButton = true;
                    break;
                }
            }
            if (anyHeldButton === false) {
                for (let noteIndex = 0; noteIndex < _private.velocityKeyNotesActive.length; ++noteIndex) {
                    _private.velocityKeyNotesActive[noteIndex].setOff();
                    _private.velocityKeyNotesActive[noteIndex].sendPitchChange(0);
                }
                _private.velocityKeyNotesActive = [];
            }
        } else if (_private.interactionMode === _private.interactionModeSlots) {
            if (stepButtonIndex < 5) {
                // Release the note, if there's one set
                let synthTestNoteInfo = _private.testSynthsActive[stepButtonIndex];
                _private.testSynthsActive[stepButtonIndex] = null;
                if (synthTestNoteInfo !== null) {
                    Zynthbox.MidiRouter.sendMidiMessageToZynthianSynth(synthTestNoteInfo.midiChannel, 3, 128, synthTestNoteInfo.midiNote, _private.starVelocity);
                }
            } else if (stepButtonIndex < 10) {
                // Stop the given slice, if it's ongoing
                let sampleIndex = stepIndex - 5;
                let sampleTestNoteInfo = _private.testSamplesSlicesActive[sampleIndex];
                _private.testSamplesSlicesActive[sampleIndex] = null;
                if (sampleTestNoteInfo) {
                    let sliceObject = sampleTestNoteInfo.sliceObject;
                    if (sliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.OneshotPlaybackStyle) {
                        // Don't stop a one-shot (this should be done by the slice, really... remember to also stop any existing playback when changing playback style for a slice)
                        sliceObject.stop(sampleTestNoteInfo.midiNote);
                    }
                }
            } else if (stepButtonIndex < 15) {
                // Don't do anything on release here
            } else if (stepButtonIndex === 15) {
                _private.testEnabledForSlots = !_private.testEnabledForSlots;
            }
        }
    }
    function handleStepButtonDown(stepButtonIndex) {
        if (_private.interactionMode === _private.interactionModeSequencer) {
            if (zynqtgui.playButtonPressed) {
                zynqtgui.ignoreNextPlayButtonPress = true;
                // Test-play the entries of the step pressed while holding down the play button
                let stepOffset = (_private.pattern.workingModel.activeBar + _private.pattern.workingModel.bankOffset) * _private.pattern.workingModel.width;
                _private.pattern.playStep(stepOffset + stepButtonIndex);
            }
        } else if (_private.interactionMode === _private.interactionModeMusicalKeys) {
            if (zynqtgui.altButtonPressed) {
                let patternTonic = Zynthbox.PlayGridManager.getNote(Zynthbox.KeyScales.midiPitchValue(_private.pattern.pitchKey, _private.pattern.octaveKey), _private.pattern.sketchpadTrack);
                if (stepButtonIndex < 11) {
                    _private.pattern.workingModel.gridModelStartNote = 12 * stepButtonIndex;
                    _private.pattern.workingModel.gridModelEndNote = _private.pattern.workingModel.gridModelStartNote + 16;
                } else if (stepButtonIndex < 13) {
                    // No bits here, step colour just gets to be empty
                } else if (stepButtonIndex === 13) {
                    _private.pattern.workingModel.gridModelStartNote = patternTonic.midiNote;
                    _private.pattern.workingModel.gridModelEndNote = _private.pattern.workingModel.gridModelStartNote + 16;
                } else if (stepButtonIndex === 14) {
                    _private.pattern.workingModel.gridModelStartNote = patternTonic.midiNote + 8;
                    _private.pattern.workingModel.gridModelEndNote = _private.pattern.workingModel.gridModelStartNote + 16;
                } else if (stepButtonIndex === 15) {
                    _private.pattern.workingModel.gridModelStartNote = patternTonic.midiNote + 16;
                    _private.pattern.workingModel.gridModelEndNote = _private.pattern.workingModel.gridModelStartNote + 16;
                }
            } else {
                if (_private.stepKeyNotesActive[stepButtonIndex]) {
                    let activeNote = _private.stepKeyNotesActive[stepButtonIndex];
                    activeNote.setOff();
                    activeNote.sendPitchChange(0);
                    activeNote.sendPolyphonicAftertouch(0);
                    _private.stepKeyPitchBend[stepButtonIndex] = 0;
                    _private.stepKeyPolyphonicAftertouch[stepButtonIndex] = 0;
                    _private.stepKeyNotesActive[stepButtonIndex] = null;
                }
                let newNote = _private.stepKeyNotes[stepButtonIndex];
                // This can be null, if the note value is out of range
                if (newNote) {
                    newNote.setOn(_private.starVelocity);
                    _private.stepKeyNotesActive[stepButtonIndex] = newNote;
                }
            }
        } else if (_private.interactionMode === _private.interactionModeVelocityKeys) {
            // Stop any currently active notes (because multiple velocities is a little odd when it's all the same notes)
            if (_private.velocityKeyNotesActive.length > 0) {
                // If we've got active notes, treat the new button as aftertouch
                for (let noteIndex = 0; noteIndex < _private.velocityKeyNotesActive.length; ++noteIndex) {
                    let activeNote = _private.velocityKeyNotesActive[noteIndex];
                    Zynthbox.SyncTimer.sendMidiMessageImmediately(3, 160 + activeNote.activeChannel, activeNote.midiNote, _private.velocityKeysVelocities[stepButtonIndex] * 127, activeNote.sketchpadTrack);
                }
            } else {
                let newNotes = [];
                for (let noteIndex = 0; noteIndex < _private.heardNotes.length; ++noteIndex) {
                    let newNote = _private.heardNotes[noteIndex];
                    newNote.setOn(_private.velocityKeysVelocities[stepButtonIndex] * 127);
                    newNotes.push(newNote);
                }
                _private.velocityKeyNotesActive = newNotes;
            }
        } else if (_private.interactionMode === _private.interactionModeSlots) {
            if (stepButtonIndex < 5) {
                // Select the appropriate synth slot
                pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("synth", stepButtonIndex);
                // Test fire only this slot, if there's a synth in it
                let midiChannel = component.selectedChannel.chainedSounds[stepButtonIndex];
                if (midiChannel > -1) {
                    // Use the current clip's tonic as a test note
                    let synthTestNoteInfo = {"midiChannel": midiChannel, "midiNote": Zynthbox.KeyScales.midiPitchValue(_private.pattern.pitchKey, _private.pattern.octaveKey)};
                    _private.testSynthsActive[stepButtonIndex] = synthTestNoteInfo;
                    Zynthbox.MidiRouter.sendMidiMessageToZynthianSynth(synthTestNoteInfo.midiChannel, 3, 144, synthTestNoteInfo.midiNote, _private.starVelocity);
                }
            } else if (stepButtonIndex < 10) {
                // Select the appropriate sample slot
                let sampleIndex = stepIndex - 5;
                pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("synth", sampleIndex);
                // Test fire only this slot, if there's a sample in it
                let sampleClip = component.selectedChannel.sampleSlotsData[sampleIndex];
                if (sampleClip.cppObjId > -1) {
                    let sampleObject = Zynthbox.PlayGridManager.getClipById(sampleClip.cppObjId);
                    let sliceObject = sampleObject.selectedSliceObject;
                    let sampleTestNoteInfo = {"sliceObject": sliceObject, "midiNote": Zynthbox.KeyScales.midiPitchValue(_private.pattern.pitchKey, _private.pattern.octaveKey)};
                    _private.testSamplesSlicesActive[sampleIndex] = sampleTestNoteInfo;
                    sliceObject.play(sampleTestNoteInfo.midiNote, _private.starVelocity);
                }
            } else if (stepButtonIndex < 15) {
                // Select the appropriate fx slot (no test fire here, doesn't really make much sense)
                let fxIndex = stepButtonIndex - 10;
                pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("synth", fxIndex);
            } else if (stepButtonIndex === 15) {
                // Don't do anything on push for the last button, the others are fired on release so do that here as well
            }
        }
    }
    function ignoreHeldStepButtonsReleases() {
        // If we're holding a step button down, make sure that we ignore the next release of those buttons
        // Don't do this for the musical keys and velocity keys modes (otherwise we'll potentially end up not releasing notes, which would be sort of weird)
        let returnValue = false;
        if (_private.interactionMode !== _private.interactionModeMusicalKeys && _private.interactionMode !== _private.interactionModeVelocityKeys) {
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
        return returnValue;
    }
    function cuiaCallback(cuia, originId, track, slot, value) {
        let returnValue = false;
        switch (cuia) {
            case "SWITCH_STEP1_DOWN":
                component.handleStepButtonDown(0);
                returnValue = true;
                break;
            case "SWITCH_STEP1_RELEASED":
                component.handleStepButtonPress(0);
                returnValue = true;
                break;
            case "SWITCH_STEP2_DOWN":
                component.handleStepButtonDown(1);
                returnValue = true;
                break;
            case "SWITCH_STEP2_RELEASED":
                component.handleStepButtonPress(1);
                returnValue = true;
                break;
            case "SWITCH_STEP3_DOWN":
                component.handleStepButtonDown(2);
                returnValue = true;
                break;
            case "SWITCH_STEP3_RELEASED":
                component.handleStepButtonPress(2);
                returnValue = true;
                break;
            case "SWITCH_STEP4_DOWN":
                component.handleStepButtonDown(3);
                returnValue = true;
                break;
            case "SWITCH_STEP4_RELEASED":
                component.handleStepButtonPress(3);
                returnValue = true;
                break;
            case "SWITCH_STEP5_DOWN":
                component.handleStepButtonDown(4);
                returnValue = true;
                break;
            case "SWITCH_STEP5_RELEASED":
                component.handleStepButtonPress(4);
                returnValue = true;
                break;
            case "SWITCH_STEP6_DOWN":
                component.handleStepButtonDown(5);
                returnValue = true;
                break;
            case "SWITCH_STEP6_RELEASED":
                component.handleStepButtonPress(5);
                returnValue = true;
                break;
            case "SWITCH_STEP7_DOWN":
                component.handleStepButtonDown(6);
                returnValue = true;
                break;
            case "SWITCH_STEP7_RELEASED":
                component.handleStepButtonPress(6);
                returnValue = true;
                break;
            case "SWITCH_STEP8_DOWN":
                component.handleStepButtonDown(7);
                returnValue = true;
                break;
            case "SWITCH_STEP8_RELEASED":
                component.handleStepButtonPress(7);
                returnValue = true;
                break;
            case "SWITCH_STEP9_DOWN":
                component.handleStepButtonDown(8);
                returnValue = true;
                break;
            case "SWITCH_STEP9_RELEASED":
                component.handleStepButtonPress(8);
                returnValue = true;
                break;
            case "SWITCH_STEP10_DOWN":
                component.handleStepButtonDown(9);
                returnValue = true;
                break;
            case "SWITCH_STEP10_RELEASED":
                component.handleStepButtonPress(9);
                returnValue = true;
                break;
            case "SWITCH_STEP11_DOWN":
                component.handleStepButtonDown(10);
                returnValue = true;
                break;
            case "SWITCH_STEP11_RELEASED":
                component.handleStepButtonPress(10);
                returnValue = true;
                break;
            case "SWITCH_STEP12_DOWN":
                component.handleStepButtonDown(11);
                returnValue = true;
                break;
            case "SWITCH_STEP12_RELEASED":
                component.handleStepButtonPress(11);
                returnValue = true;
                break;
            case "SWITCH_STEP13_DOWN":
                component.handleStepButtonDown(12);
                returnValue = true;
                break;
            case "SWITCH_STEP13_RELEASED":
                component.handleStepButtonPress(12);
                returnValue = true;
                break;
            case "SWITCH_STEP14_DOWN":
                component.handleStepButtonDown(13);
                returnValue = true;
                break;
            case "SWITCH_STEP14_RELEASED":
                component.handleStepButtonPress(13);
                returnValue = true;
                break;
            case "SWITCH_STEP15_DOWN":
                component.handleStepButtonDown(14);
                returnValue = true;
                break;
            case "SWITCH_STEP15_RELEASED":
                component.handleStepButtonPress(14);
                returnValue = true;
                break;
            case "SWITCH_STEP16_DOWN":
                component.handleStepButtonDown(15);
                returnValue = true;
                break;
            case "SWITCH_STEP16_RELEASED":
                component.handleStepButtonPress(15);
                returnValue = true;
                break;

            // Would perhaps make sense that the sidebar buttons should be less strictly named and just... also be numbered buttons?
            case "SCREEN_SKETCHPAD":
                if (zynqtgui.anyStepButtonPressed && _private.interactionMode == _private.interactionModeSequencer && zynqtgui.altButtonPressed == false) {
                    component.setParameterPage(0);
                    component.ignoreHeldStepButtonsReleases();
                    returnValue = true;
                }
                break;
            case "SCREEN_LAYER":
                if (zynqtgui.anyStepButtonPressed && _private.interactionMode == _private.interactionModeSequencer && zynqtgui.altButtonPressed == false) {
                    component.setParameterPage(1);
                    component.ignoreHeldStepButtonsReleases();
                    returnValue = true;
                }
                break;
            case "SCREEN_EDIT_CONTEXTUAL":
                if (zynqtgui.anyStepButtonPressed && _private.interactionMode == _private.interactionModeSequencer && zynqtgui.altButtonPressed == false) {
                    component.setParameterPage(2);
                    component.ignoreHeldStepButtonsReleases();
                    returnValue = true;
                }
                break;
            case "SCREEN_PLAYGRID":
                if (zynqtgui.anyStepButtonPressed && _private.interactionMode == _private.interactionModeSequencer && zynqtgui.altButtonPressed == false) {
                    component.setParameterPage(3);
                    component.ignoreHeldStepButtonsReleases();
                    returnValue = true;
                }
                break;
            case "SCREEN_SONG_MANAGER":
                if (zynqtgui.anyStepButtonPressed && _private.interactionMode == _private.interactionModeSequencer && zynqtgui.altButtonPressed == false) {
                    component.setParameterPage(4);
                    component.ignoreHeldStepButtonsReleases();
                    returnValue = true;
                }
                break;

            case "SWITCH_BACK_SHORT":
                component.ignoreHeldStepButtonsReleases();
                break;

            // K1 controls velocity
            case "KNOB0_TOUCHED":
                component.ignoreHeldStepButtonsReleases();
                if (zynqtgui.starButtonPressed) {
                    applicationWindow().pageStack.getPage("sketchpad").updateClipDefaultVelocity(component.selectedChannel.id, component.selectedChannel.selectedClip, 0);
                    returnValue = true;
                } else {
                    for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                        if (_private.heldStepButtons[stepButtonIndex]) {
                            if (_private.interactionMode === _private.interactionModeSequencer) {
                                switch (_private.parameterPage) {
                                    case 2:
                                        component.updateStepRatchetStyle(0, stepButtonIndex);
                                        break;
                                    case 1:
                                        component.updateStepProbability(0, stepButtonIndex);
                                        break;
                                    case 0:
                                    default:
                                        component.updateStepVelocity(0, stepButtonIndex);
                                        break;
                                }
                            } else if (_private.interactionMode === _private.interactionModeTrackClip) {
                                if (stepButtonIndex < 10) {
                                    applicationWindow().updateChannelVolume(0, stepButtonIndex);
                                } else if (10 < stepButtonIndex && stepButtonIndex < 16) {
                                    // Clip button + k1 adjusts the clip's step length
                                    component.updatePatternProperty(0, "stepLength", component.selectedChannel.id, stepButtonIndex - 10);
                                }
                            } else if (_private.interactionMode === _private.interactionModeMusicalKeys) {
                                // Send aftertouch to any held note - no display, so don't actually do anything for touched
                            }
                            returnValue = true;
                        }
                    }
                }
                break;
            case "KNOB0_RELEASED":
                break;
            case "KNOB0_UP":
                component.ignoreHeldStepButtonsReleases();
                if (zynqtgui.starButtonPressed) {
                    applicationWindow().pageStack.getPage("sketchpad").updateClipDefaultVelocity(component.selectedChannel.id, component.selectedChannel.selectedClip, 1);
                    returnValue = true;
                } else {
                    for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                        if (_private.heldStepButtons[stepButtonIndex]) {
                            if (_private.interactionMode === _private.interactionModeSequencer) {
                                switch (_private.parameterPage) {
                                    case 2:
                                        component.updateStepRatchetStyle(1, stepButtonIndex);
                                        break;
                                    case 1:
                                        component.updateStepProbability(1, stepButtonIndex);
                                        break;
                                    case 0:
                                    default:
                                        component.updateStepVelocity(1, stepButtonIndex);
                                        break;
                                }
                            } else if (_private.interactionMode === _private.interactionModeTrackClip) {
                                if (stepButtonIndex < 10) {
                                    applicationWindow().updateChannelVolume(1, stepButtonIndex);
                                } else if (10 < stepButtonIndex && stepButtonIndex < 16) {
                                    // Clip button + k1 adjusts the clip's step length
                                    component.updatePatternProperty(1, "stepLength", component.selectedChannel.id, stepButtonIndex - 10);
                                }
                            } else if (_private.interactionMode === _private.interactionModeMusicalKeys) {
                                // Send aftertouch to any held note
                                let stepNote = _private.stepKeyNotesActive[stepButtonIndex];
                                if (stepNote) {
                                    if (_private.stepKeyPolyphonicAftertouch[stepButtonIndex] < 127) {
                                        _private.stepKeyPolyphonicAftertouch[stepButtonIndex] = _private.stepKeyPolyphonicAftertouch[stepButtonIndex] + 1;
                                        stepNote.sendPolyphonicAftertouch(_private.stepKeyPolyphonicAftertouch[stepButtonIndex]);
                                    }
                                }
                            }
                            returnValue = true;
                        }
                    }
                }
                break;
            case "KNOB0_DOWN":
                component.ignoreHeldStepButtonsReleases();
                if (zynqtgui.starButtonPressed) {
                    applicationWindow().pageStack.getPage("sketchpad").updateClipDefaultVelocity(component.selectedChannel.id, component.selectedChannel.selectedClip, -1);
                    returnValue = true;
                } else {
                    for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                        if (_private.heldStepButtons[stepButtonIndex]) {
                            if (_private.interactionMode === _private.interactionModeSequencer) {
                                switch (_private.parameterPage) {
                                    case 2:
                                        component.updateStepRatchetStyle(-1, stepButtonIndex);
                                        break;
                                    case 1:
                                        component.updateStepProbability(-1, stepButtonIndex);
                                        break;
                                    case 0:
                                    default:
                                        component.updateStepVelocity(-1, stepButtonIndex);
                                        break;
                                }
                            } else if (_private.interactionMode === _private.interactionModeTrackClip) {
                                if (stepButtonIndex < 10) {
                                    applicationWindow().updateChannelVolume(-1, stepButtonIndex);
                                } else if (10 < stepButtonIndex && stepButtonIndex < 16) {
                                    // Clip button + k1 adjusts the clip's step length
                                    component.updatePatternProperty(-1, "stepLength", component.selectedChannel.id, stepButtonIndex - 10);
                                }
                            } else if (_private.interactionMode === _private.interactionModeMusicalKeys) {
                                // Send aftertouch to any held note
                                let stepNote = _private.stepKeyNotesActive[stepButtonIndex];
                                if (stepNote) {
                                    if (0 < _private.stepKeyPolyphonicAftertouch[stepButtonIndex]) {
                                        _private.stepKeyPolyphonicAftertouch[stepButtonIndex] = _private.stepKeyPolyphonicAftertouch[stepButtonIndex] - 1;
                                        stepNote.sendPolyphonicAftertouch(_private.stepKeyPolyphonicAftertouch[stepButtonIndex]);
                                    }
                                }
                            }
                            returnValue = true;
                        }
                    }
                }
                break;

            // K2 controls length
            case "KNOB1_TOUCHED":
                component.ignoreHeldStepButtonsReleases();
                for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                    if (_private.heldStepButtons[stepButtonIndex]) {
                        if (_private.interactionMode === _private.interactionModeSequencer) {
                            switch (_private.parameterPage) {
                                case 2:
                                    component.updateStepRatchetCount(0, stepButtonIndex);
                                    break;
                                case 1:
                                    break;
                                case 0:
                                default:
                                    component.updateStepDuration(0, stepButtonIndex);
                                    break;
                            }
                        } else if (_private.interactionMode === _private.interactionModeTrackClip) {
                            if (stepButtonIndex < 10) {
                                applicationWindow().pageStack.getPage("sketchpad").updateChannelPan(0, stepButtonIndex);
                            } else if (10 < stepButtonIndex && stepButtonIndex < 16) {
                                // Clip+k2 adjusts the pattern's swing
                                component.updatePatternProperty(0, "swing", component.selectedChannel.id, stepButtonIndex - 10);
                            }
                        } else if (_private.interactionMode === _private.interactionModeMusicalKeys) {
                            // Send pitch bend to any active note - no display, so don't actually do anything here
                        }
                        returnValue = true;
                    }
                }
                break;
            case "KNOB1_RELEASED":
                break;
            case "KNOB1_UP":
                component.ignoreHeldStepButtonsReleases();
                for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                    if (_private.heldStepButtons[stepButtonIndex]) {
                        if (_private.interactionMode === _private.interactionModeSequencer) {
                            switch (_private.parameterPage) {
                                case 2:
                                    component.updateStepRatchetCount(1, stepButtonIndex);
                                    break;
                                case 1:
                                    break;
                                case 0:
                                default:
                                    component.updateStepDuration(1, stepButtonIndex);
                                    break;
                            }
                        } else if (_private.interactionMode === _private.interactionModeTrackClip) {
                            if (stepButtonIndex < 10) {
                                applicationWindow().pageStack.getPage("sketchpad").updateChannelPan(1, stepButtonIndex);
                            } else if (10 < stepButtonIndex && stepButtonIndex < 16) {
                                // Clip+k2 adjusts the pattern's swing
                                component.updatePatternProperty(1, "swing", component.selectedChannel.id, stepButtonIndex - 10);
                            }
                        } else if (_private.interactionMode === _private.interactionModeMusicalKeys) {
                            // Send pitch bend to any held note
                            let stepNote = _private.stepKeyNotesActive[stepButtonIndex];
                            if (stepNote) {
                                if (_private.stepKeyPitchBend[stepButtonIndex] < 1) {
                                    _private.stepKeyPitchBend[stepButtonIndex] = Math.min(_private.stepKeyPitchBend[stepButtonIndex] + 0.005, 1);
                                    stepNote.sendPitchChange(Math.max(-8192, Math.min(_private.stepKeyPitchBend[stepButtonIndex] * 8192, 8191)));
                                }
                            }
                        }
                        returnValue = true;
                    }
                }
                break;
            case "KNOB1_DOWN":
                component.ignoreHeldStepButtonsReleases();
                for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                    if (_private.heldStepButtons[stepButtonIndex]) {
                        if (_private.interactionMode === _private.interactionModeSequencer) {
                            switch (_private.parameterPage) {
                                case 2:
                                    component.updateStepRatchetCount(-1, stepButtonIndex);
                                    break;
                                case 1:
                                    break;
                                case 0:
                                default:
                                    component.updateStepDuration(-1, stepButtonIndex);
                                    break;
                            }
                        } else if (_private.interactionMode === _private.interactionModeTrackClip) {
                            if (stepButtonIndex < 10) {
                                applicationWindow().pageStack.getPage("sketchpad").updateChannelPan(-1, stepButtonIndex);
                            } else if (10 < stepButtonIndex && stepButtonIndex < 16) {
                                // Clip+k2 adjusts the pattern's swing
                                component.updatePatternProperty(-1, "swing", component.selectedChannel.id, stepButtonIndex - 10);
                            }
                        } else if (_private.interactionMode === _private.interactionModeMusicalKeys) {
                            // Send pitch bend to any held note
                            let stepNote = _private.stepKeyNotesActive[stepButtonIndex];
                            if (stepNote) {
                                if (-1 < _private.stepKeyPitchBend[stepButtonIndex]) {
                                    _private.stepKeyPitchBend[stepButtonIndex] = Math.max(-1, _private.stepKeyPitchBend[stepButtonIndex] - 0.005);
                                    stepNote.sendPitchChange(Math.max(-8192, Math.min(_private.stepKeyPitchBend[stepButtonIndex] * 8192, 8191)));
                                }
                            }
                        }
                        returnValue = true;
                    }
                }
                break;

            // K3 controls position
            case "KNOB2_TOUCHED":
                component.ignoreHeldStepButtonsReleases();
                for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                    if (_private.heldStepButtons[stepButtonIndex]) {
                        if (_private.interactionMode === _private.interactionModeSequencer) {
                            switch (_private.parameterPage) {
                                case 2:
                                    component.updateStepRatchetProbability(0, stepButtonIndex);
                                    break;
                                case 1:
                                    component.updateStepNextStep(0, stepButtonIndex);
                                    break;
                                case 0:
                                default:
                                    component.updateStepPosition(0, stepButtonIndex);
                                    break;
                            }
                        } else if (_private.interactionMode === _private.interactionModeTrackClip) {
                            if (10 < stepButtonIndex && stepButtonIndex < 16) {
                                // Clip+k3 adjusts pattern length
                                component.updatePatternProperty(0, "patternLength", component.selectedChannel.id, stepButtonIndex - 10);
                            }
                        } else if (_private.interactionMode === _private.interactionModeMusicalKeys) {
                            // Send mod wheel to any held note - no display, so don't actually do anything here
                        }
                        returnValue = true;
                    }
                }
                break;
            case "KNOB2_RELEASED":
                break;
            case "KNOB2_UP":
                component.ignoreHeldStepButtonsReleases();
                for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                    if (_private.heldStepButtons[stepButtonIndex]) {
                        if (_private.interactionMode === _private.interactionModeSequencer) {
                            switch (_private.parameterPage) {
                                case 2:
                                    component.updateStepRatchetProbability(1, stepButtonIndex);
                                    break;
                                case 1:
                                    component.updateStepNextStep(1, stepButtonIndex);
                                    break;
                                case 0:
                                default:
                                    component.updateStepPosition(1, stepButtonIndex);
                                    break;
                            }
                        } else if (_private.interactionMode === _private.interactionModeTrackClip) {
                            if (10 < stepButtonIndex && stepButtonIndex < 16) {
                                // Clip+k3 adjusts pattern length
                                component.updatePatternProperty(1, "patternLength", component.selectedChannel.id, stepButtonIndex - 10);
                            }
                        } else if (_private.interactionMode === _private.interactionModeMusicalKeys) {
                            // Send mod wheel to any held note
                            _private.modulationValue = Math.max(0, Math.min(_private.modulationValue + 1, 127));
                        }
                        returnValue = true;
                        // The mod value is global, so only send that once per twist
                        break;
                    }
                }
                break;
            case "KNOB2_DOWN":
                component.ignoreHeldStepButtonsReleases();
                for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                    if (_private.heldStepButtons[stepButtonIndex]) {
                        if (_private.interactionMode === _private.interactionModeSequencer) {
                            switch (_private.parameterPage) {
                                case 2:
                                    component.updateStepRatchetProbability(-1, stepButtonIndex);
                                    break;
                                case 1:
                                    component.updateStepNextStep(-1, stepButtonIndex);
                                    break;
                                case 0:
                                default:
                                    component.updateStepPosition(-1, stepButtonIndex);
                                    break;
                            }
                        } else if (_private.interactionMode === _private.interactionModeTrackClip) {
                            if (10 < stepButtonIndex && stepButtonIndex < 16) {
                                // Clip+k3 adjusts pattern length
                                component.updatePatternProperty(-1, "patternLength", component.selectedChannel.id, stepButtonIndex - 10);
                            }
                        } else if (_private.interactionMode === _private.interactionModeMusicalKeys) {
                            // Send mod wheel to any held note
                            _private.modulationValue = Math.max(0, Math.min(_private.modulationValue - 1, 127));
                        }
                        returnValue = true;
                        // The mod value is global, so only send that once per twist
                        break;
                    }
                }
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
                    returnValue = true;
                } else if (_private.interactionMode === _private.interactionModeMusicalKeys) {
                    if (zynqtgui.altButtonPressed) {
                        applicationWindow().pageStack.getPage("sketchpad").updateClipScale(component.selectedChannel.id, component.selectedChannel.selectedClip, 0);
                        returnValue = true;
                    } else {
                    }
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
                        if (zynqtgui.selectButtonPressed) {
                            zynqtgui.ignoreNextSelectButtonPress = true;
                            currentKey = Math.min(127, currentKey + 12);
                        } else {
                            currentKey = Math.min(127, currentKey + 1);
                        }
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
                } else if (_private.interactionMode === _private.interactionModeSequencer) {
                    let workingModel = _private.pattern.workingModel;
                    for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                        if (_private.heldStepButtons[stepButtonIndex]) {
                            let transposeOctave = false;
                            if (zynqtgui.knob3Pressed) {
                                zynqtgui.ignoreNextKnob3PressedPress = true;
                                transposeOctave = true;
                            }
                            if (zynqtgui.altButtonPressed) {
                                // Hold down a bar button and twist BK to transpose all that bar's notes
                                if (stepButtonIndex < 8) {
                                    workingModel.startLongOperation();
                                    for (let barStepIndex = 0; barStepIndex < workingModel.width; ++barStepIndex) {
                                        workingModel.transposeStep(workingModel.bankOffset + workingModel.activeBar, barStepIndex, 1, -1, transposeOctave);
                                    }
                                    workingModel.endLongOperation();
                                }
                            } else {
                                // Hold down a step button and twist BK to transpose that step's notes
                                workingModel.transposeStep(workingModel.bankOffset + workingModel.activeBar, stepButtonIndex, 1, -1, transposeOctave);
                                let theNote = workingModel.getNote(workingModel.bankOffset + workingModel.activeBar, stepButtonIndex);
                                let stepIndex = (workingModel.activeBar * workingModel.width) + stepButtonIndex;
                                if (theNote) {
                                    applicationWindow().showPassiveNotification(qsTr("Step %1 Transposed to: %2")
                                        .arg(stepIndex + 1)
                                        .arg(Zynthbox.Chords.shorthand(theNote.subnotes, workingModel.scaleKey, workingModel.pitchKey, workingModel.octaveKey))
                                        , 1000);
                                    component.handleStepDataChanged(stepIndex);
                                }
                            }
                            returnValue = true;
                        }
                    }
                } else if (_private.interactionMode === _private.interactionModeTrackClip) {
                    for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                        if (_private.heldStepButtons[stepButtonIndex]) {
                            if (10 < stepButtonIndex && stepButtonIndex < 16) {
                                // Hold down a clip button and twist BK to transpose all notes in that clip
                                let workingModel = _private.sequence.getClipById(component.selectedChannel.id, stepButtonIndex - 10).workingModel;
                                workingModel.startLongOperation();
                                let allDone = false;
                                for (let row = 0; row < workingModel.bankLength; ++row) {
                                    for (let column = 0; column < workingModel.width; ++column) {
                                        if ((row * workingModel.width) + column == workingModel.patternLength) {
                                            allDone = true;
                                            break;
                                        }
                                        workingModel.transposeNote(row, column, 1);
                                    }
                                    if (allDone) { break; }
                                }
                                workingModel.endLongOperation();
                                returnValue = true;
                            }
                        }
                    }
                } else if (_private.interactionMode === _private.interactionModeMusicalKeys) {
                    if (zynqtgui.altButtonPressed) {
                        applicationWindow().pageStack.getPage("sketchpad").updateClipScale(component.selectedChannel.id, component.selectedChannel.selectedClip, 1);
                        returnValue = true;
                    } else {
                    }
                }
                break;
            case "KNOB3_DOWN":
                component.ignoreHeldStepButtonsReleases();
                if (zynqtgui.starButtonPressed) {
                    let currentKey = Zynthbox.KeyScales.midiPitchValue(_private.pattern.pitchKey, _private.pattern.octaveKey);
                    if (currentKey < 127) {
                        if (zynqtgui.selectButtonPressed) {
                            zynqtgui.ignoreNextSelectButtonPress = true;
                            currentKey = Math.max(0, currentKey - 12);
                        } else {
                            currentKey = currentKey - 1;
                        }
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
                } else if (_private.interactionMode === _private.interactionModeSequencer) {
                    let workingModel = _private.pattern.workingModel;
                    for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                        if (_private.heldStepButtons[stepButtonIndex]) {
                            let transposeOctave = false;
                            if (zynqtgui.knob3Pressed) {
                                zynqtgui.ignoreNextKnob3PressedPress = true;
                                transposeOctave = true;
                            }
                            if (zynqtgui.altButtonPressed) {
                                // Hold down a bar button and twist BK to transpose all that bar's notes
                                if (stepButtonIndex < 8) {
                                    workingModel.startLongOperation();
                                    for (let barStepIndex = 0; barStepIndex < workingModel.width; ++barStepIndex) {
                                        workingModel.transposeStep(workingModel.bankOffset + workingModel.activeBar, barStepIndex, -1, -1, transposeOctave);
                                    }
                                    workingModel.endLongOperation();
                                }
                            } else {
                                // Hold down a step button and twist BK to transpose that step's notes
                                workingModel.transposeStep(workingModel.bankOffset + workingModel.activeBar, stepButtonIndex, -1, -1, transposeOctave);
                                let theNote = workingModel.getNote(workingModel.bankOffset + workingModel.activeBar, stepButtonIndex);
                                let stepIndex = (workingModel.activeBar * workingModel.width) + stepButtonIndex;
                                if (theNote) {
                                    applicationWindow().showPassiveNotification(qsTr("Step %1 Transposed to: %2")
                                        .arg(stepIndex + 1)
                                        .arg(Zynthbox.Chords.shorthand(theNote.subnotes, workingModel.scaleKey, workingModel.pitchKey, workingModel.octaveKey))
                                        , 1000);
                                    component.handleStepDataChanged(stepIndex);
                                }
                            }
                            returnValue = true;
                        }
                    }
                } else if (_private.interactionMode === _private.interactionModeTrackClip) {
                    for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                        if (_private.heldStepButtons[stepButtonIndex]) {
                            if (10 < stepButtonIndex && stepButtonIndex < 16) {
                                // Hold down a clip button and twist BK to transpose all notes in that clip
                                let workingModel = _private.sequence.getClipById(component.selectedChannel.id, stepButtonIndex - 10).workingModel;
                                workingModel.startLongOperation();
                                let allDone = false;
                                for (let row = 0; row < workingModel.bankLength; ++row) {
                                    for (let column = 0; column < workingModel.width; ++column) {
                                        if ((row * workingModel.width) + column == workingModel.patternLength) {
                                            allDone = true;
                                            break;
                                        }
                                        workingModel.transposeNote(row, column, -1);
                                    }
                                    if (allDone) { break; }
                                }
                                workingModel.endLongOperation();
                                returnValue = true;
                            }
                        }
                    }
                } else if (_private.interactionMode === _private.interactionModeMusicalKeys) {
                    if (zynqtgui.altButtonPressed) {
                        applicationWindow().pageStack.getPage("sketchpad").updateClipScale(component.selectedChannel.id, component.selectedChannel.selectedClip, -1);
                        returnValue = true;
                    } else {
                    }
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

            case "SWITCH_PLAY":
                if (_private.interactionMode === _private.interactionModeSequencer) {
                    // When in stepsequencer mode and holding down any step button, and then tapping play, toggle enabled for that step to "on" (that is, clear enabled as it's the default)
                    let workingModel = _private.pattern.workingModel;
                    for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                        if (_private.heldStepButtons[stepButtonIndex]) {
                            workingModel.setKeyedDataValue(workingModel.barOffset + workingModel.activeBar, stepButtonIndex, "enabled", undefined);
                            component.ignoreHeldStepButtonsReleases();
                            returnValue = true;
                        }
                    }
                } else {
                    // Don't do anything with the play button unless a step button is held down
                }
                break;
            case "SWITCH_STOP":
                if (_private.interactionMode === _private.interactionModeSequencer) {
                    // When in stepsequencer mode and holding down any step button, and then tapping stop, toggle enabled for that step to "off" (that is, set the value to false)
                    let workingModel = _private.pattern.workingModel;
                    for (let stepButtonIndex = 0; stepButtonIndex < 16; ++stepButtonIndex) {
                        if (_private.heldStepButtons[stepButtonIndex]) {
                            workingModel.setKeyedDataValue(workingModel.barOffset + workingModel.activeBar, stepButtonIndex, "enabled", false);
                            component.ignoreHeldStepButtonsReleases();
                            returnValue = true;
                        }
                    }
                } else {
                    // Don't do anything with the stop button unless a step button is held down
                }
                break;
            case "SWITCH_MODE_RELEASED":
                if (zynqtgui.step1ButtonPressed || zynqtgui.step2ButtonPressed || zynqtgui.step3ButtonPressed || zynqtgui.step4ButtonPressed || zynqtgui.step5ButtonPressed || zynqtgui.step6ButtonPressed || zynqtgui.step7ButtonPressed || zynqtgui.step8ButtonPressed || zynqtgui.step9ButtonPressed || zynqtgui.step10ButtonPressed || zynqtgui.step11ButtonPressed || zynqtgui.step12ButtonPressed || zynqtgui.step13ButtonPressed || zynqtgui.step14ButtonPressed || zynqtgui.step15ButtonPressed || zynqtgui.step16ButtonPressed) {
                    // Don't allow switching modes when holding down a button, that just makes interaction weird...
                } else {
                    // When holding alt, always switch to the musical keys mode, otherwise toggle between steps and track/clip
                    if (zynqtgui.altButtonPressed) {
                        if (_private.interactionMode === _private.interactionModeMusicalKeys) {
                            _private.interactionMode = _private.interactionModeVelocityKeys;
                        } else {
                            _private.interactionMode = _private.interactionModeMusicalKeys;
                        }
                    } else {
                        if (_private.interactionMode === _private.interactionModeSequencer) {
                            _private.interactionMode = _private.interactionModeTrackClip;
                        } else if (_private.interactionMode === _private.interactionModeTrackClip) {
                            _private.interactionMode = _private.interactionModeSlots;
                        } else {
                            _private.interactionMode = _private.interactionModeSequencer;
                        }
                    }
                }
                returnValue = true;
                break;
        }
        return returnValue;
    }

    QtObject {
        id: _private
        property int parameterPage: 0
        onParameterPageChanged: {
            switch(parameterPage) {
                case 2:
                    applicationWindow().showPassiveNotification(qsTr("Parameter Page: Ratchet (style, count, probability)"));
                    break;
                case 1:
                    applicationWindow().showPassiveNotification(qsTr("Parameter Page: Probability (probability, blank, next step)"));
                    break;
                case 0:
                default:
                    applicationWindow().showPassiveNotification(qsTr("Parameter Page: General (velocity, length, position)"));
                    break;
            }
            updateLedColors();
        }
        property QtObject sequence: component.selectedChannel ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName) : null
        property QtObject pattern: sequence && component.selectedChannel ? sequence.getByClipId(component.selectedChannel.id, component.selectedChannel.selectedClip) : null
        property QtObject patternKeyNote: pattern ? Zynthbox.PlayGridManager.getNote(Zynthbox.KeyScales.midiPitchValue(pattern.pitchKey, pattern.octaveKey), pattern.sketchpadTrack) : null
        // property QtObject clip: component.selectedChannel ? component.selectedChannel.getClipsModelById(component.selectedClip).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex) : null
        onPatternChanged: {
            updateSlotPassthroughClients();
            handlePatternDataChange();
        }
        function handlePatternDataChange() {
            let keyNote = Zynthbox.KeyScales.midiPitchValue(pattern.pitchKey, pattern.octaveKey);
            heardNotes = [Zynthbox.PlayGridManager.getNote(keyNote, pattern.sketchpadTrack)];
            heardVelocities = [pattern.defaultVelocity];
            // Build out 16 steps based on the pattern's grid model
            let newStepKeyNotes = [];
            let firstStepKeyNote = pattern.gridModelStartNote;
            for (let stepIndex = 0; stepIndex < 16; ++stepIndex) {
                let stepNote = Zynthbox.KeyScales.transposeNote(firstStepKeyNote, stepIndex, pattern.scaleKey, pattern.pitchKey, pattern.octaveKey);
                if (-1 < stepNote && stepNote < 128) {
                    newStepKeyNotes.push(Zynthbox.PlayGridManager.getNote(stepNote, pattern.sketchpadTrack));
                } else {
                    newStepKeyNotes.push(null);
                }
            }
            stepKeyNotes = newStepKeyNotes;
            updateLedColors();
        }

        property color stepEmpty: Qt.rgba(0.1, 0.1, 0.1)
        property color stepWithNotesDimmed: Qt.rgba(0, 0, 0.7)
        property color stepWithNotes: Qt.rgba(0.5, 0.5, 1)
        property color stepHighlighted: Qt.rgba(0.5, 1, 1)
        property color stepMuted: Qt.rgba(0.5, 0, 0)
        property color stepCurrent: Qt.rgba(1, 1, 0)
        property color stepRecording: Qt.rgba(1, 0, 0)

        property color sequencerModeColor: Qt.rgba(1, 0, 0)
        property color trackClipModeColor: Qt.rgba(1, 1, 0)
        property color musicalKeysModeColor: Qt.rgba(0, 0, 1)
        property color velocityKeysModeColor: Qt.rgba(0, 0, 1)
        property color slotModeColor: Qt.rgba(0, 1, 0)

        property color redColor: Qt.rgba(1, 0, 0)
        property color greenColor: Qt.rgba(0, 1, 1)
        property color blueColor: Qt.rgba(0, 0, 1)

        readonly property int patternSubbeatToTickMultiplier: (Zynthbox.SyncTimer.getMultiplier() / 32);
        property int stepDuration: pattern ? (pattern.stepLength / patternSubbeatToTickMultiplier) : 0

        property var heardNotes: []
        property var heardVelocities: []
        property int noteListeningActivations: 0
        property var noteListeningNotes: []
        property var noteListeningVelocities: []
        onHeardNotesChanged: updateLedColors()

        property QtObject starNote: null
        property int starVelocity: pattern ? pattern.defaultVelocity : 64

        // Should probably do a thing where we show when notes are playing when in keys mode...
        property var stepKeyNotes: [null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null]
        property var stepKeyNotesActive: [null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null]
        property var stepKeyPolyphonicAftertouch: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        // This is a floating point value from -1 through 1, with 0 being no pitch bend.
        // This would really be usually for each channel instead of each note, but the active notes keep
        // track of the active channels, so... we just store the local value per activation for ease of access
        property var stepKeyPitchBend: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        property int modulationValue: 0
        onModulationValueChanged: Zynthbox.PlayGridManager.modulation = modulationValue;

        property var velocityKeyNotesActive: []

        property var slotPassthroughClients: [null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null]
        function updateSlotPassthroughClients() {
            for (let slotIndex = 0; slotIndex < 15; ++slotIndex) {
                let slotPassthroughClient = null;
                if (slotIndex < 5) {
                    // The five synth slots
                    let midiChannel = component.selectedChannel.chainedSounds[slotIndex];
                    if (midiChannel > -1) {
                        slotPassthroughClient = Zynthbox.Plugin.synthPassthroughClients[midiChannel];
                    }
                } else if (slotIndex < 10) {
                    // The five sample slots
                    let sampleClip = component.selectedChannel.sampleSlotsData[slotIndex - 5];
                    if (sampleClip.cppObjId > -1) {
                        let sampleObject = Zynthbox.PlayGridManager.getClipById(sampleClip.cppObjId);
                        slotPassthroughClient = sampleObject.selectedSliceObject;
                    }
                } else if (slotIndex < 15) {
                    // The five fx slots
                    // Note that "muted" here is actually "bypass", and "gain" is "dry/wet mix", and it's range is from 0.0 through 2.0 so it needs scaling down by 0.5 to make sure it's the same range as the gain ones
                    if (component.selectedChannel.occupiedFxSlots[slotIndex - 10]) {
                        slotPassthroughClient = Zynthbox.Plugin.fxPassthroughClients[component.selectedChannel.id][slotIndex - 10];
                    }
                }
                slotPassthroughClients[slotIndex] = slotPassthroughClient;
            }
            updateLedColors();
        }
        property bool testEnabledForSlots: true
        property var testSynthsActive: [null, null, null, null, null]
        property var testSamplesSlicesActive: [null, null, null, null, null]
        onTestEnabledForSlotsChanged: {
            if (testEnabledForSlots) {
                applicationWindow().showPassiveNotification("Tap Slot Button To Test: Enabled", 1500);
            } else {
                applicationWindow().showPassiveNotification("Tap Slot Button To Test: Disabled", 1500);
            }
            updateLedColors();
        }

        property var heldStepButtons: [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]

        // The interaction modes are:
        // 0: Step sequencer (displays the 16 steps of the current bar, tapping toggles the step's entry given either the currently held note, or the clip's key)
        // 1: Track/Clip Selector
        // 2: Musical keyboard for some basic music playings
        // 3: Velocity keyboard (which plays the currently held note at 16 different velocities)
        // 4: Slots (for selecting the 15 slots, with preview for the 10 sound source slots when that slot's button is tapped, colours appropriate for that slot (perhaps with volume indication per slot as a brightness thing and red for muted/bypassed?))
        property int interactionMode: 0
        readonly property int interactionModeSequencer: 0
        readonly property int interactionModeTrackClip: 1
        readonly property int interactionModeMusicalKeys: 2
        readonly property int interactionModeVelocityKeys: 3
        readonly property int interactionModeSlots: 4
        onInteractionModeChanged: {
            updateLedColors();
            switch (interactionMode) {
                case interactionModeSlots:
                    applicationWindow().showPassiveNotification("Slots", 1500);
                    break;
                case interactionModeVelocityKeys:
                    applicationWindow().showPassiveNotification("Velocity Keys", 1500);
                    break;
                case interactionModeMusicalKeys:
                    applicationWindow().showPassiveNotification("Musical Keys", 1500);
                    break;
                case interactionModeTrackClip:
                    applicationWindow().showPassiveNotification("Track and Clip", 1500);
                    break;
                case interactionModeSequencer:
                default:
                    applicationWindow().showPassiveNotification("Sequencer", 1500);
                    break;
            }
        }
        function updateLedsForStepSequencer() {
            zynqtgui.led_config.setModeButtonColor(_private.sequencerModeColor);
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
                    zynqtgui.led_config.setStepButtonColor(stepIndex, stepColor, 1.0);
                }
                // Second is the available bar length (steps are filled if they are less or equal to the available bars, and not filled otherwise, and tapping sets the pattern length in 16 step increments)
                for (let stepIndex = 0; stepIndex < 8; ++stepIndex) {
                    let stepColor = _private.stepEmpty;
                    if (stepIndex < workingModel.availableBars) {
                        stepColor = _private.stepWithNotes;
                    }
                    zynqtgui.led_config.setStepButtonColor(stepIndex + 8, stepColor, 1.0);
                }
            } else {
                let heardNoteValues = [];
                for (let i = 0; i < heardNotes.length; ++i) {
                    heardNoteValues.push(heardNotes[i].midiNote);
                }
                let stepOffset = (workingModel.activeBar + workingModel.bankOffset) * workingModel.width;
                for (let stepIndex = 0; stepIndex < 16; ++stepIndex) {
                    let stepColor = _private.stepEmpty;
                    let stepMuted = (workingModel.getKeyedDataValue(workingModel.activeBar + workingModel.barOffset, stepIndex, "enabled") === false);
                    if (stepMuted) {
                        stepColor = _private.stepMuted;
                    } else {
                        let stepNote = workingModel.getNote(workingModel.activeBar + workingModel.bankOffset, stepIndex);
                        if (stepNote != null && stepNote.subnotes.length > 0) {
                            let atLeastOneHeard = false;
                            for (let subnoteIndex = 0; subnoteIndex < stepNote.subnotes.length; ++subnoteIndex) {
                                let subnote = stepNote.subnotes[subnoteIndex];
                                if (heardNoteValues.includes(subnote.midiNote)) {
                                    atLeastOneHeard = true;
                                    break;
                                }
                            }
                            if (atLeastOneHeard) {
                                stepColor = _private.stepWithNotes;
                            } else {
                                stepColor = _private.stepWithNotesDimmed;
                            }
                        }
                        let actualStepIndex = stepOffset + stepIndex;
                        if (workingModel.playbackPosition === actualStepIndex) {
                            if (workingModel.recordLive) {
                                stepColor = _private.stepRecording;
                            } else {
                                stepColor = Qt.tint(stepColor, _private.stepCurrent);
                            }
                        }
                    }
                    zynqtgui.led_config.setStepButtonColor(stepIndex, stepColor, 1.0);
                }
            }
        }
        function updateLedsForTrackClipSelector() {
            zynqtgui.led_config.setModeButtonColor(_private.trackClipModeColor);
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
                zynqtgui.led_config.setStepButtonColor(trackIndex, stepColor, 1.0);
            }
            // Last button's not really a thing for now, grey it out...
            zynqtgui.led_config.setStepButtonColor(10, _private.stepEmpty, 1.0);
            for (let clipIndex = 0; clipIndex < 5; ++clipIndex) {
                let stepColor = _private.stepEmpty;
                let clipPattern = _private.sequence.getByClipId(component.selectedChannel.id, clipIndex);
                if (clipPattern.currentBankHasNotes) {
                    stepColor = _private.stepWithNotes;
                }
                if (component.selectedChannel.selectedClip === clipIndex) {
                    stepColor = Qt.tint(stepColor, _private.stepCurrent);
                }
                zynqtgui.led_config.setStepButtonColor(clipIndex + 11, stepColor, 1.0);
            }
        }
        function updateLedsForMusicalButtons() {
            zynqtgui.led_config.setModeButtonColor(_private.musicalKeysModeColor);
            if (zynqtgui.altButtonPressed) {
                let patternTonic = Zynthbox.PlayGridManager.getNote(Zynthbox.KeyScales.midiPitchValue(_private.pattern.pitchKey, _private.pattern.octaveKey), _private.pattern.sketchpadTrack);
                for (let stepIndex = 0; stepIndex < 16; ++stepIndex) {
                    let stepColor = _private.stepEmpty;
                    if (stepIndex < 11) {
                        if (pattern.gridModelStartNote == 12 * stepIndex) {
                            stepColor = _private.stepCurrent;
                        } else {
                            stepColor = _private.stepWithNotes;
                        }
                    } else if (stepIndex < 13) {
                        // No bits here, step colour just gets to be empty
                    } else if (stepIndex < 16) {
                        if (stepIndex === 13 && pattern.gridModelStartNote == patternTonic.midiNote) {
                            stepColor = _private.stepCurrent;
                        } else if (stepIndex === 14 && pattern.gridModelStartNote == patternTonic.midiNote + 8) {
                            stepColor = _private.stepCurrent;
                        } else if (stepIndex === 15 && pattern.gridModelStartNote == patternTonic.midiNote + 16) {
                            stepColor = _private.stepCurrent;
                        } else {
                            stepColor = _private.stepWithNotes;
                        }
                    }
                    zynqtgui.led_config.setStepButtonColor(stepIndex, stepColor, 1.0);
                }
            } else {
                for (let stepIndex = 0; stepIndex < 16; ++stepIndex) {
                    let stepColor = _private.stepEmpty;
                    let stepNote = stepKeyNotes[stepIndex];
                    let brightness = 1.0;
                    if (stepNote) {
                        // Normalise the colours to all be on C8 because even brightness is useful in this case
                        stepColor = zynqtgui.theme_chooser.noteColors[(stepNote.midiNote % 12) + 108];
                        brightness = stepNote.isPlaying ? 1.0 : 0.8;
                    }
                    zynqtgui.led_config.setStepButtonColor(stepIndex, stepColor, brightness);
                }
            }
        }
        readonly property var velocityKeysVelocities: [1/16, 2/16, 3/16, 4/16, 5/16, 6/16, 7/16, 8/16, 9/16, 10/16, 11/16, 12/16, 13/16, 14/16, 15/16, 1]
        function updateLedsForVelocityButtons() {
            zynqtgui.led_config.setModeButtonColor(_private.velocityKeysModeColor);
            for (let stepIndex = 0; stepIndex < 16; ++stepIndex) {
                zynqtgui.led_config.setStepButtonColor(stepIndex, Qt.rgba(0, 0, velocityKeysVelocities[stepIndex] * 0.5), 1.0);
            }
        }
        function updateLedsForSlotButtons() {
            zynqtgui.led_config.setModeButtonColor(_private.slotModeColor);
            for (let stepIndex = 0; stepIndex < 16; ++stepIndex) {
                let slotMuted = false;
                let slotGain = 0.0;
                let slotPassthroughClient = _private.slotPassthroughClients[stepIndex];
                let slotFilled = slotPassthroughClient != null;
                if (stepIndex < 5) {
                    // The five synth slots
                    if (slotPassthroughClient) {
                        slotMuted = slotPassthroughClient.muted;
                        slotGain = slotPassthroughClient.dryGainHandler.gainAbsolute;
                    }
                } else if (stepIndex < 10) {
                    // The five sample slots
                    if (slotPassthroughClient) {
                        slotMuted = sampleObject.selectedSliceObject.gainHandler.muted;
                        slotGain = sampleObject.selectedSliceObject.gainHandler.gainAbsolute;
                    }
                } else if (stepIndex < 15) {
                    // The five fx slots
                    // Note that "muted" here is actually "bypass", and "gain" is "dry/wet mix", and it's range is from 0.0 through 2.0 so it needs scaling down by 0.5 to make sure it's the same range as the gain ones
                    if (slotPassthroughClient) {
                        slotMuted = slotPassthroughClient.bypass;
                        slotGain = slotPassthroughClient.dryWetMixAmount * 0.5;
                    }
                } else {
                    // The last step button is a toggle for whether or not we preview when tapping the thing (use the musical keys colour here as the "on" state, to signify that a play thing will happen)
                    slotFilled = _private.testEnabledForSlots;
                }
                if (slotFilled === false) {
                    zynqtgui.led_config.setStepButtonColor(stepIndex, _private.stepEmpty, 1.0);
                } else if (slotMuted) {
                    zynqtgui.led_config.setStepButtonColor(stepIndex, _private.stepMuted, 1.0);
                } else {
                    if (stepIndex < 15) {
                        zynqtgui.led_config.setStepButtonColor(stepIndex, Qt.rgba(0.01, 0.01 + slotGain, 0.01), 1.0);
                    } else {
                        zynqtgui.led_config.setStepButtonColor(stepIndex, _private.musicalKeysModeColor, 1.0);
                    }
                }
            }
        }
        readonly property var libraryPages: ["layers_for_channel", "bank", "preset", "fixed_effects", "effect_preset", "sketch_effect_preset", "sample_library", "effects_for_channel", "sketch_effects_for_channel", "sound_categories"]
        readonly property var editPages: ["control", "channel_wave_editor", "channel_external_setup"]
        function updateNumberButtonColors() {
            if (zynqtgui.anyStepButtonPressed && _private.interactionMode == _private.interactionModeSequencer && zynqtgui.altButtonPressed == false) {
                zynqtgui.led_config.setNumberButtonColor(0, _private.parameterPage === 0 ? _private.stepHighlighted : _private.stepWithNotes, 1);
                zynqtgui.led_config.setNumberButtonColor(1, _private.parameterPage === 1 ? _private.stepHighlighted : _private.stepWithNotes, 1);
                zynqtgui.led_config.setNumberButtonColor(2, _private.parameterPage === 2 ? _private.stepHighlighted : _private.stepWithNotes, 1);
                zynqtgui.led_config.setNumberButtonColor(3, _private.stepEmpty, 1);
                zynqtgui.led_config.setNumberButtonColor(4, _private.stepEmpty, 1);
            } else {
                zynqtgui.led_config.setNumberButtonColor(0, zynqtgui.current_screen_id == "sketchpad" ? _private.greenColor : _private.blueColor, 1);
                zynqtgui.led_config.setNumberButtonColor(1, libraryPages.includes(zynqtgui.current_screen_id) ? _private.greenColor : _private.blueColor, 1);
                zynqtgui.led_config.setNumberButtonColor(2, editPages.includes(zynqtgui.current_screen_id) ? _private.greenColor : _private.blueColor, 1);
                zynqtgui.led_config.setNumberButtonColor(3, zynqtgui.current_screen_id == "playgrid" ? _private.greenColor : _private.blueColor, 1);
                zynqtgui.led_config.setNumberButtonColor(4, zynqtgui.current_screen_id == "song_manager" ? _private.greenColor : _private.blueColor, 1);
            }
        }
        function updateLedColors() {
            ledColorUpdateThrottle.restart();
        }
    }
    Timer {
        id: ledColorUpdateThrottle
        interval: 0; running: false; repeat: false;
        onTriggered: {
            if (_private.pattern) {
                switch (_private.interactionMode) {
                    case _private.interactionModeSlots:
                        _private.updateLedsForSlotButtons();
                        break;
                    case _private.interactionModeVelocityKeys:
                        _private.updateLedsForVelocityButtons();
                        break;
                    case _private.interactionModeMusicalKeys:
                        _private.updateLedsForMusicalButtons();
                        break;
                    case _private.interactionModeTrackClip:
                        _private.updateLedsForTrackClipSelector();
                        break;
                    case _private.interactionModeSequencer:
                    default:
                        _private.updateLedsForStepSequencer();
                        break;
                }
            }
            _private.updateNumberButtonColors();
            // the star note is a thing when the star button itself is pressed, otherwise we have to test that the pattern's root key is pressed
            if ((_private.starNote && _private.starNote.isPlaying) || (_private.patternKeyNote && _private.patternKeyNote.isPlaying)) {
                zynqtgui.led_config.setStarButtonColor(zynqtgui.theme_chooser.noteColors[((_private.starNote ? _private.starNote.midiNote : _private.patternKeyNote.midiNote) % 12) + 108]);
            } else {
                zynqtgui.led_config.setStarButtonColor(_private.stepWithNotesDimmed);
            }
        }
    }
    Repeater {
        model: 5
        Item {
            Connections {
                target: _private.slotPassthroughClients[index] ? _private.slotPassthroughClients[index].dryGainHandler : null
                onGainChanged: _private.updateLedColors()
            }
            Connections {
                target: _private.slotPassthroughClients[index]
                onMutedChanged: _private.updateLedColors()
            }
        }
    }
    Repeater {
        model: 5
        Item {
            Connections {
                target: _private.slotPassthroughClients[index + 5] ? _private.slotPassthroughClients[index + 5].gainHandler : null
                onGainChanged: _private.updateLedColors()
                onMutedChanged: _private.updateLedColors()
            }
        }
    }
    Repeater {
        model: 5
        Item {
            Connections {
                target: _private.slotPassthroughClients[index + 10]
                onDryWetMixAmountChanged: _private.updateLedColors()
                onBypassChanged: _private.updateLedColors()
            }
        }
    }
    Repeater {
        model: 16
        Item {
            Connections {
                target: _private.stepKeyNotes[index]
                // Only activate this for musical keys, no particular reason otherwise
                enabled: _private.interactionMode === _private.interactionModeMusicalKeys
                onIsPlayingChanged: _private.updateLedColors()
            }
        }
    }
    Connections {
        target: component.selectedChannel
        onSamples_changed: _private.updateSlotPassthroughClients()
        onChainedSoundsNamesChanged: _private.updateSlotPassthroughClients()
        onChainedFxNamesChanged: _private.updateSlotPassthroughClients()
    }
    Connections {
        target: _private.pattern
        onGridModelStartNoteChanged: _private.handlePatternDataChange()
        onScaleChanged: _private.handlePatternDataChange()
        onOctaveChanged: _private.handlePatternDataChange()
        onPitchChanged: _private.handlePatternDataChange()
        onIsPlayingChanged: _private.handlePatternDataChange()
        onLastModifiedChanged: _private.updateLedColors()
    }
    Connections {
        target: _private.starNote
        onIsPlayingChanged: _private.updateLedColors()
    }
    Connections {
        target: _private.patternKeyNote
        onIsPlayingChanged: _private.updateLedColors()
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

    // Call this function whenever something changes on a step which would directly impact the step's sound output
    function handleStepDataChanged(stepIndex) {
        stepDataAutoPreviewThrottle.stepToAutoPreview = stepIndex;
        stepDataAutoPreviewThrottle.restart();
    }
    Timer {
        id: stepDataAutoPreviewThrottle
        // A bit of a wait, to ensure we hang back just a tiny bit, so when people do a bunch of knob twiddling, we don't fire too many tests...
        interval: 200
        repeat: false; running: false;
        // To avoid many noisy noises, we only auto-preview a single step at a time (we allow editing multiple steps at the same time, but if we preview them all, it could end up pretty cacophonous)
        property int stepToAutoPreview: -1
        onTriggered: {
            if (-1 < stepToAutoPreview && stepToAutoPreview < _private.pattern.workingModel.patternLength) {
                if (zynqtgui.ui_settings.hardwareSequencerPreviewStyle === 1 // If we're wanting to just always preview
                    || (zynqtgui.ui_settings.hardwareSequencerPreviewStyle === 0 && Zynthbox.SyncTimer.timerRunning === false)) // Or if we're stopped, and want to preview when stopped
                _private.pattern.workingModel.playStep(stepToAutoPreview, true);
                // TODO How do we deal reasonably with negative positions in our step's data? Preview the previous step at the same time maybe?
            }
            stepToAutoPreview = -1;
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
        onAnyStepButtonPressedChanged: _private.updateLedColors()
        onStep1_button_pressed_changed: { _private.heldStepButtons[0] = zynqtgui.step1ButtonPressed; }
        onStep2_button_pressed_changed: { _private.heldStepButtons[1] = zynqtgui.step2ButtonPressed; }
        onStep3_button_pressed_changed: { _private.heldStepButtons[2] = zynqtgui.step3ButtonPressed; }
        onStep4_button_pressed_changed: { _private.heldStepButtons[3] = zynqtgui.step4ButtonPressed; }
        onStep5_button_pressed_changed: { _private.heldStepButtons[4] = zynqtgui.step5ButtonPressed; }
        onStep6_button_pressed_changed: { _private.heldStepButtons[5] = zynqtgui.step6ButtonPressed; }
        onStep7_button_pressed_changed: { _private.heldStepButtons[6] = zynqtgui.step7ButtonPressed; }
        onStep8_button_pressed_changed: { _private.heldStepButtons[7] = zynqtgui.step8ButtonPressed; }
        onStep9_button_pressed_changed: { _private.heldStepButtons[8] = zynqtgui.step9ButtonPressed; }
        onStep10_button_pressed_changed: { _private.heldStepButtons[9] = zynqtgui.step10ButtonPressed; }
        onStep11_button_pressed_changed: { _private.heldStepButtons[10] = zynqtgui.step11ButtonPressed; }
        onStep12_button_pressed_changed: { _private.heldStepButtons[11] = zynqtgui.step12ButtonPressed; }
        onStep13_button_pressed_changed: { _private.heldStepButtons[12] = zynqtgui.step13ButtonPressed; }
        onStep14_button_pressed_changed: { _private.heldStepButtons[13] = zynqtgui.step14ButtonPressed; }
        onStep15_button_pressed_changed: { _private.heldStepButtons[14] = zynqtgui.step15ButtonPressed; }
        onStep16_button_pressed_changed: { _private.heldStepButtons[15] = zynqtgui.step16ButtonPressed; }
    }
    Connections {
        target: Zynthbox.PlayGridManager
        // Only do this when we're in musical keys mode
        enabled: zynqtgui.ui_settings.hardwareSequencer && _private.interactionMode === _private.interactionModeMusicalKeys
        onActiveNotesChanged: _private.updateLedColors()
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