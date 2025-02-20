/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Channel Wave Editor

Copyright (C) 2022 Dan Leinir Turthra Jensen <admin@leinir.dk>

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

import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian
import "./Sketchpad" as Sketchpad

Zynthian.ScreenPage {
    id: component
    screenId: "channel_wave_editor"
    title: qsTr("Track Wave Editor")

    property bool isVisible:zynqtgui.current_screen_id === "channel_wave_editor"
    property QtObject selectedChannel: null
    Timer {
        id: selectedChannelThrottle
        interval: 1; running: false; repeat: false;
        onTriggered: {
            component.selectedChannel = null;
            component.selectedChannel = applicationWindow().selectedChannel;
        }
    }
    Connections {
        target: applicationWindow()
        onSelectedChannelChanged: selectedChannelThrottle.restart()
    }
    Connections {
        target: zynqtgui.sketchpad
        onSongChanged: selectedChannelThrottle.restart()
    }
    Connections {
        target: zynqtgui.sketchpad.song
        onIsLoadingChanged: selectedChannelThrottle.restart()
    }
    Component.onCompleted: {
        selectedChannelThrottle.restart()
    }
    property QtObject selectedClip: component.selectedChannel
                                    ? component.selectedChannel.trackType === "sample-loop"
                                        ? component.selectedChannel.getClipsModelById(component.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                                        : component.selectedChannel.samples[component.selectedChannel.selectedSlotRow]
                                    : null
    property QtObject cppClipObject: component.selectedClip && component.selectedClip.hasOwnProperty("cppObjId")
                                        ? Zynthbox.PlayGridManager.getClipById(component.selectedClip.cppObjId)
                                        : null
    property bool selectedClipHasWav: false
    Timer {
        id: selectedClipHasWavThrottle
        interval: 1; running: false; repeat: false;
        onTriggered: {
            let newHasWav = selectedClip && !selectedClip.isEmpty;
            if (component.selectedClipHasWav != newHasWav) {
                component.selectedClipHasWav = newHasWav;
            }
            // When switching to a new clip, update the default test note to match the actual/given pitch (rootNote) of that new clip (or C4 if there isn't a clip)
            testNotePad.midiNote = component.cppClipObject ? component.cppClipObject.selectedSliceObject.rootNote : 60;
            component.heardNotes = [];
        }
    }
    onSelectedClipChanged: selectedClipHasWavThrottle.restart()
    onIsVisibleChanged: {
        selectedChannelThrottle.restart();
        selectedClipHasWavThrottle.restart();
    }

    property var cuiaCallback: function(cuia) {
        var returnValue = false;
        switch (cuia) {
            case "SWITCH_MODE_RELEASED":
                if (zynqtgui.altButtonPressed) {
                    // Cycle between the tabs in order when the alt button is held and mode is pressed
                    if (clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null && clipSettingsSectionView.currentItem.objectName != null) {
                        if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                            clipSettingsSectionView.currentItem = clipSettingsSlices;
                        } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                            clipSettingsSectionView.currentItem = clipSettingsVoices;
                        } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                            clipSettingsSectionView.currentItem = clipSettingsADSR;
                        } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                            if (clipSettingsGrainerator.sliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.GranularLoopingPlaybackStyle || clipSettingsGrainerator.sliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.GranularNonLoopingPlaybackStyle) {
                                clipSettingsSectionView.currentItem = clipSettingsGrainerator;
                            } else {
                                clipSettingsSectionView.currentItem = clipSettingsInfoView;
                            }
                        } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                            clipSettingsSectionView.currentItem = clipSettingsInfoView;
                        } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsInfoView") {
                            clipSettingsSectionView.currentItem = clipSettingsBar;
                        } else {
                            // This is weird... but reset to clipSettingsBar, and output a message about it being weird :P
                            console.log("Unlikely situation, our tab is unknown? Apparently its object name is", clipSettingsSectionView.currentItem.objectName, "and the object itself is", clipSettingsSectionView.currentItem);
                            clipSettingsSectionView.currentItem = clipSettingsBar;
                        }
                    }
                    returnValue = true;
                }
                break;
            case "SELECT_UP":
                returnValue = _private.goUp(cuia);
                break;
            case "SELECT_DOWN":
                returnValue = _private.goDown(cuia);
                break;
            case "NAVIGATE_LEFT":
                returnValue = _private.goLeft(cuia);
                break;
            case "NAVIGATE_RIGHT":
                returnValue = _private.goRight(cuia);
                break;
            case "KNOB0_TOUCHED":
                returnValue = _private.knob0Touched(cuia);
                break;
            case "KNOB0_UP":
                returnValue = _private.knob0Up(cuia);
                break;
            case "KNOB0_DOWN":
                returnValue = _private.knob0Down(cuia);
                break;
            case "KNOB1_TOUCHED":
                returnValue = _private.knob1Touched(cuia);
                break;
            case "KNOB1_UP":
                returnValue = _private.knob1Up(cuia);
                break;
            case "KNOB1_DOWN":
                returnValue = _private.knob1Down(cuia);
                break;
            case "KNOB2_TOUCHED":
                returnValue = _private.knob2Touched(cuia);
                break;
            case "KNOB2_UP":
                returnValue = _private.knob2Up(cuia);
                break;
            case "KNOB2_DOWN":
                returnValue = _private.knob2Down(cuia);
                break;
            case "KNOB3_TOUCHED":
                returnValue = _private.knob3Touched(cuia);
                break;
            case "KNOB3_UP":
                returnValue = _private.goRight(cuia);
                break;
            case "KNOB3_DOWN":
                returnValue = _private.goLeft(cuia);
                break;
        }
        return returnValue;
    }
    QtObject {
        id: _private
        function goLeft(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                    returnValue = clipSettingsSlices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.previousADSRElement();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.previousElement();
                }
            }
            return returnValue;
        }
        function goRight(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                    returnValue = clipSettingsSlices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.nextADSRElement();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.nextElement();
                }
            }
            return returnValue;
        }
        function goUp(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                    returnValue = clipSettingsSlices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    if (zynqtgui.altButtonPressed) {
                        for (var i = 0; i < 10; ++i) {
                            clipSettingsADSR.increaseCurrentValue();
                        }
                    } else {
                        clipSettingsADSR.increaseCurrentValue();
                    }
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    if (zynqtgui.altButtonPressed) {
                        for (var i = 0; i < 10; ++i) {
                            clipSettingsGrainerator.increaseCurrentValue();
                        }
                    } else {
                        clipSettingsGrainerator.increaseCurrentValue();
                    }
                }
            }
            return returnValue;
        }
        function goDown(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                    returnValue = clipSettingsSlices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    if (zynqtgui.altButtonPressed) {
                        for (var i = 0; i < 10; ++i) {
                            clipSettingsADSR.decreaseCurrentValue();
                        }
                    } else {
                        clipSettingsADSR.decreaseCurrentValue();
                    }
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    if (zynqtgui.altButtonPressed) {
                        for (var i = 0; i < 10; ++i) {
                            clipSettingsGrainerator.decreaseCurrentValue();
                        }
                    } else {
                        clipSettingsGrainerator.decreaseCurrentValue();
                    }
                }
            }
            return returnValue;
        }
        function knob0Touched(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                    returnValue = clipSettingsSlices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                }
            }
            return returnValue;
        }
        function knob0Up(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                    returnValue = clipSettingsSlices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.nextADSRElement();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.nextElement();
                }
            }
            return returnValue;
        }
        function knob0Down(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                    returnValue = clipSettingsSlices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.previousADSRElement();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.previousElement();
                }
            }
            return returnValue;
        }
        function knob1Touched(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                    returnValue = clipSettingsSlices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                }
            }
            return returnValue;
        }
        function knob1Up(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                    returnValue = clipSettingsSlices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.increaseCurrentValue();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.increaseCurrentValue();
                }
            }
            return returnValue;
        }
        function knob1Down(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                    returnValue = clipSettingsSlices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                    clipSettingsADSR.decreaseCurrentValue();
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                    clipSettingsGrainerator.decreaseCurrentValue();
                }
            }
            return returnValue;
        }
        function knob2Touched(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                    returnValue = clipSettingsSlices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                }
            }
            return returnValue;
        }
        function knob2Up(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                    returnValue = clipSettingsSlices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                }
            }
            return returnValue;
        }
        function knob2Down(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                    returnValue = clipSettingsSlices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                }
            }
            return returnValue;
        }
        function knob3Touched(cuia) {
            let returnValue = true;
            if (component.selectedClipHasWav) {
                if (clipSettingsSectionView.currentItem.objectName === "clipSettingsBar") {
                    returnValue = waveBar.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices") {
                    returnValue = clipSettingsSlices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices") {
                    returnValue = clipSettingsVoices.cuiaCallback(cuia);
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR") {
                } else if (clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator") {
                }
            }
            return returnValue;
        }
    }
    Connections {
        target: applicationWindow()
        enabled: component.isVisible
        onSelectedChannelChanged: {
            if (applicationWindow().selectedChannel) {
                zynqtgui.callable_ui_action_simple("SCREEN_EDIT_CONTEXTUAL");
            }
        }
    }
    Connections {
        target: Zynthbox.MidiRouter
        enabled: component.isVisible
        onMidiMessage: function(port, size, byte1, byte2, byte3, sketchpadTrack, fromInternal) {
            // console.log("Midi message of size", size, "received on port", port, "with bytes", byte1, byte2, byte3, "from track", sketchpadTrack, fromInternal, "current track id", component.selectedChannel.id, "listening on port", listenToPort);
            if ((port == Zynthbox.MidiRouter.HardwareInPassthroughPort || port == Zynthbox.MidiRouter.InternalControllerPassthroughPort) && sketchpadTrack === component.selectedChannel.id && size === 3) {
                if (127 < byte1 && byte1 < 160) {
                    let setOn = true;
                    // By convention, an "off" note can be either a midi off message, or an on message with a velocity of 0
                    if (byte1 < 144 || byte3 === 0) {
                        setOn = false;
                    }
                    let midiNote = byte2;
                    if (setOn === true) {
                        if (component.noteListeningActivations === 0) {
                            // Clear the current state, in case there's something there (otherwise things look a little weird)
                            component.heardNotes = [];
                        }
                        // Count up one tick for a note on message
                        component.noteListeningActivations = component.noteListeningActivations + 1;
                        // Create a new note based on the new thing that just arrived, but only if it's an on note
                        var newNote = Zynthbox.PlayGridManager.getNote(midiNote, sketchpadTrack);
                        var existingIndex = component.noteListeningNotes.indexOf(newNote);
                        if (existingIndex > -1) {
                            component.noteListeningNotes.splice(existingIndex, 1);
                        }
                        component.noteListeningNotes.push(newNote);
                        // console.log("Registering note on , new activation count is", component.noteListeningActivations, component.noteListeningNotes);
                    } else if (setOn == false) {
                        // Count down one for a note off message
                        component.noteListeningActivations = component.noteListeningActivations - 1;
                        // console.log("Registering note off, new activation count is", component.noteListeningActivations, component.noteListeningNotes, component.noteListeningVelocities);
                    }
                    if (component.noteListeningActivations < 0) {
                        // this will generally happen after stopping playback (as the playback stops, then all off notes are sent out,
                        // and we'll end up receiving a bunch of them while not doing playback, without having received matching on notes)
                        // it might still happen at other times, so we might still need to do some testing later, but... this is the general case.
                        // console.debug("stepsequencer: Problem, we've received too many off notes compared to on notes, this is bad and shouldn't really be happening.");
                        component.noteListeningActivations = 0;
                        component.noteListeningNotes = [];
                    }
                    if (component.noteListeningActivations > 0) {
                        // Now, if we're back down to zero, then we've had all the notes released, and should assign all the heard notes to the heard notes thinger
                        component.heardNotes = component.noteListeningNotes;
                    }
                    if (component.noteListeningActivations === 0) {
                        // Now, if we're back down to zero, then we've had all the notes released, and should be ready to start over
                        component.noteListeningNotes = [];
                        // If we have captured only a single note, and it is the chosen test note, then we
                        // don't actually want there to be any captured notes as that makes interaction weird
                        if (component.heardNotes.length === 1 && component.heardNotes[0].midiNote === testNotePad.midiNote) {
                            component.heardNotes = [];
                        }
                    }
                } else if (175 < byte1 && byte1 < 192 && byte2 === 123) {
                    // console.log("Registering all-off, resetting to empty, bytes are", byte1, byte2, byte3);
                    component.noteListeningActivations = 0;
                    component.noteListeningNotes = [];
                }
            }
        }
    }
    property int noteListeningActivations: 0
    property var noteListeningNotes: []
    property var heardNotes: []

    contextualActions: [
        Kirigami.Action {
            enabled: true
            text: qsTr("Pick Sample")
            onTriggered: {
                applicationWindow().requestSamplePicker();
            }
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        }
    ]

    RowLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            spacing: 0
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.8
                visible: component.selectedChannel && component.selectedChannel.trackType !== "sample-loop"
                columns: 2
                rowSpacing: 0
                columnSpacing: 0
                QQC2.Button {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                    text: "+1"
                    visible: testNotePad.displayCompoundNote === false
                    onClicked: {
                        testNotePad.midiNote = Math.min(127, testNotePad.midiNote + 1);
                    }
                }
                QQC2.Button {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                    text: "+12"
                    visible: testNotePad.displayCompoundNote === false
                    onClicked: {
                        testNotePad.midiNote = Math.min(127, testNotePad.midiNote + 12);
                    }
                }
                Zynthian.NotePad {
                    id: testNotePad
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit
                    Layout.columnSpan: 2
                    positionalVelocity: true
                    highlightOctaveStart: false
                    property int midiNote: 60
                    property QtObject midiNoteObject: component.selectedChannel ? Zynthbox.PlayGridManager.getNote(testNotePad.midiNote, component.selectedChannel.id) : null
                    property bool displayCompoundNote: !(component.heardNotes.length === 0 || (component.heardNotes.length === 1 && component.heardNotes[0].midiNote === testNotePad.midiNote))
                    note: component.selectedChannel
                        ? testNotePad.displayCompoundNote
                            ? Zynthbox.PlayGridManager.getCompoundNote(component.heardNotes)
                            : midiNoteObject
                        : null
                }
                QQC2.Button {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                    text: "-1"
                    visible: testNotePad.displayCompoundNote === false
                    onClicked: {
                        testNotePad.midiNote = Math.max(0, testNotePad.midiNote - 1);
                    }
                }
                QQC2.Button {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                    text: "-12"
                    visible: testNotePad.displayCompoundNote === false
                    onClicked: {
                        testNotePad.midiNote = Math.max(0, testNotePad.midiNote - 12);
                    }
                }
                QQC2.Button {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 0.25
                    Layout.columnSpan: 2
                    icon.name: "edit-clear-locationbar"
                    visible: testNotePad.displayCompoundNote === true
                    onClicked: {
                        component.heardNotes = [];
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.8
                visible: component.selectedChannel && component.selectedChannel.trackType === "sample-loop"
                icon.name: component.cppClipObject && component.cppClipObject.isPlaying ? "media-playback-stop" : "media-playback-start"
                onClicked: {
                    if (component.cppClipObject.isPlaying) {
                        component.cppClipObject.stop();
                    } else {
                        component.cppClipObject.play(false, component.selectedChannel.id);
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.minimumHeight: Kirigami.Units.largeSpacing
                Layout.maximumHeight: Kirigami.Units.largeSpacing
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit
                text: qsTr("General")
                enabled: component.selectedClipHasWav
                checked: clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null && clipSettingsSectionView.currentItem.objectName != null && clipSettingsSectionView.currentItem.objectName === "clipSettingsBar"
                MouseArea {
                    anchors.fill: parent;
                    enabled: component.selectedClipHasWav
                    onClicked: if (clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null) { clipSettingsSectionView.currentItem = clipSettingsBar }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit
                text: qsTr("Slices")
                enabled: component.selectedClipHasWav
                checked: clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null && clipSettingsSectionView.currentItem.objectName != null && clipSettingsSectionView.currentItem.objectName === "clipSettingsSlices"
                MouseArea {
                    anchors.fill: parent;
                    enabled: component.selectedClipHasWav
                    onClicked: if (clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null) { clipSettingsSectionView.currentItem = clipSettingsSlices }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit
                text: qsTr("Voices/EQ")
                enabled: component.selectedClipHasWav
                checked: clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null && clipSettingsSectionView.currentItem.objectName != null && clipSettingsSectionView.currentItem.objectName === "clipSettingsVoices"
                MouseArea {
                    anchors.fill: parent;
                    enabled: component.selectedClipHasWav
                    onClicked: if (clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null) { clipSettingsSectionView.currentItem = clipSettingsVoices }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit
                text: qsTr("Envelope")
                enabled: component.selectedClipHasWav
                checked: clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null && clipSettingsSectionView.currentItem.objectName != null && clipSettingsSectionView.currentItem.objectName === "clipSettingsADSR"
                MouseArea {
                    anchors.fill: parent;
                    enabled: component.selectedClipHasWav
                    onClicked: if (clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null) { clipSettingsSectionView.currentItem = clipSettingsADSR }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit
                text: qsTr("Granular")
                visible: clipSettingsGrainerator.sliceObject && (clipSettingsGrainerator.sliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.GranularLoopingPlaybackStyle || clipSettingsGrainerator.sliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.GranularNonLoopingPlaybackStyle)
                enabled: component.selectedClipHasWav
                checked: clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null && clipSettingsSectionView.currentItem.objectName != null && clipSettingsSectionView.currentItem.objectName === "clipSettingsGrainerator"
                MouseArea {
                    anchors.fill: parent;
                    enabled: component.selectedClipHasWav
                    onClicked: if (clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null) { clipSettingsSectionView.currentItem = clipSettingsGrainerator }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit
                text: qsTr("Clip Info")
                enabled: component.selectedClipHasWav
                checked: clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null && clipSettingsSectionView.currentItem.objectName != null && clipSettingsSectionView.currentItem.objectName === "clipSettingsInfoView"
                MouseArea {
                    anchors.fill: parent;
                    enabled: component.selectedClipHasWav
                    onClicked: if (clipSettingsSectionView != null && clipSettingsSectionView.currentItem != null) { clipSettingsSectionView.currentItem = clipSettingsInfoView }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 16
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 9
                color: "#222222"
                border.width: 1
                border.color: "#ff999999"
                enabled: component.selectedClipHasWav
                opacity: enabled ? 1 : 0.5

                Sketchpad.WaveEditorBar {
                    id: waveBar
                    anchors {
                        fill: parent
                        margins: 1
                        bottomMargin: Kirigami.Units.smallSpacing
                    }
                    internalMargin: 1
                    controlObj: component.selectedClip
                    controlType: component.selectedChannel
                                ? ["synth", "sample-loop"].indexOf(component.selectedChannel.trackType) >= 0
                                    ? "bottombar-controltype-clip"
                                    : "bottombar-controltype-channel"
                                : ""
                    visible: component.selectedClipHasWav
                }
            }
            Rectangle {
                id: clipSettingsSectionView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 11
                color: "#222222"
                border.width: 1
                border.color: "#ff999999"
                radius: 4
                enabled: component.selectedClipHasWav
                opacity: enabled ? 1 : 0.5
                property Item currentItem: clipSettingsBar
                Connections {
                    target: component
                    onSelectedClipChanged: {
                        clipSettingsBarControlObjThrottle.restart();
                        clipSettingsSlicesClipThrottle.restart();
                        clipSettingsVoicesClipThrottle.restart();
                        clipSettingsADSRClipThrottle.restart();
                        clipSettingsGraineratorClipThrottle.restart();
                        clipSettingsInfoViewClipThrottle.restart();
                    }
                }
                Sketchpad.ClipSettingsBar {
                    id: clipSettingsBar
                    objectName: "clipSettingsBar"
                    visible: clipSettingsSectionView.visible && clipSettingsSectionView.currentItem.objectName === objectName
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.largeSpacing
                        topMargin: 0
                    }
                    controlObjIsManual: true
                    controlObj: component.selectedClip
                    Timer {
                        id: clipSettingsBarControlObjThrottle
                        interval: 1; running: false; repeat: false;
                        onTriggered: {
                            clipSettingsBar.controlObj = component.selectedClip;
                        }
                    }
                    controlType: component.selectedChannel
                                ? ["synth", "sample-loop"].indexOf(component.selectedChannel.trackType) >= 0
                                    ? "bottombar-controltype-clip"
                                    : "bottombar-controltype-channel"
                                : ""
                    showCopyPasteButtons: false
                }
                Zynthian.ClipSlicesSettings {
                    id: clipSettingsSlices
                    objectName: "clipSettingsSlices"
                    visible: clipSettingsSectionView.visible && clipSettingsSectionView.currentItem.objectName === objectName
                    anchors.fill: parent
                    clip: null
                    Timer {
                        id: clipSettingsSlicesClipThrottle
                        interval: 1; running: false; repeat: false;
                        onTriggered: {
                            clipSettingsSlices.clip = component.selectedClip;
                            clipSettingsSlices.cppClipObject = component.cppClipObject;
                        }
                    }
                }
                Zynthian.ClipVoicesSettings {
                    id: clipSettingsVoices
                    objectName: "clipSettingsVoices"
                    visible: clipSettingsSectionView.visible && clipSettingsSectionView.currentItem.objectName === objectName
                    anchors.fill: parent
                    clip: null
                    Timer {
                        id: clipSettingsVoicesClipThrottle
                        interval: 1; running: false; repeat: false;
                        onTriggered: {
                            clipSettingsVoices.clip = component.selectedClip;
                            clipSettingsVoices.cppClipObject = component.cppClipObject;
                        }
                    }
                }
                Zynthian.ADSRClipView {
                    id: clipSettingsADSR
                    objectName: "clipSettingsADSR"
                    visible: clipSettingsSectionView.visible && clipSettingsSectionView.currentItem.objectName === objectName
                    anchors.fill: parent
                    clip: null
                    Timer {
                        id: clipSettingsADSRClipThrottle
                        interval: 1; running: false; repeat: false;
                        onTriggered: {
                            clipSettingsADSR.clip = component.selectedClip;
                        }
                    }
                }
                Zynthian.ClipGraineratorSettings {
                    id: clipSettingsGrainerator
                    objectName: "clipSettingsGrainerator"
                    visible: clipSettingsSectionView.visible && clipSettingsSectionView.currentItem.objectName === objectName
                    anchors.fill: parent;
                    clip: null
                    Timer {
                        id: clipSettingsGraineratorClipThrottle
                        interval: 1; running: false; repeat: false;
                        onTriggered: {
                            clipSettingsGrainerator.clip = component.selectedClip;
                        }
                    }
                }
                Zynthian.ClipInfoView {
                    id: clipSettingsInfoView
                    objectName: "clipSettingsInfoView"
                    visible: clipSettingsSectionView.visible && clipSettingsSectionView.currentItem.objectName === objectName
                    anchors.fill: parent
                    clip: null
                    Timer {
                        id: clipSettingsInfoViewClipThrottle
                        interval: 1; running: false; repeat: false;
                        onTriggered: {
                            clipSettingsInfoView.clip = component.cppClipObject;
                        }
                    }
                }
            }
        }

        ColumnLayout {
            id: clipBar

            spacing: 1
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 6

            Repeater {
                model: component.selectedChannel ? 5 : 0
                delegate: Rectangle {
                    id: clipDelegate

                    property QtObject clip: component.selectedChannel.trackType === "sample-loop"
                                                        ? component.selectedChannel.getClipsModelById(index).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                                                        : component.selectedChannel.samples[index]
                    property QtObject cppClipObject: clipDelegate.clip && clipDelegate.clip.hasOwnProperty("cppObjId")
                                                        ? Zynthbox.PlayGridManager.getClipById(clipDelegate.clip.cppObjId)
                                                        : null
                    property bool clipHasWav: clipDelegate.clip && !clipDelegate.isEmpty

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#000000"
                    border{
                        color: index === component.selectedChannel.selectedSlotRow ? Kirigami.Theme.highlightColor : "transparent"
                        width: 1
                    }
                    Zynthbox.WaveFormItem {
                        anchors.fill: parent
                        color: Kirigami.Theme.textColor
                        source: clipDelegate.cppClipObject ? "clip:/%1".arg(clipDelegate.cppClipObject.id) : ""
                        start: clipDelegate.cppClipObject ? clipDelegate.cppClipObject.selectedSliceObject.startPositionSeconds : 0
                        end: clipDelegate.cppClipObject ? clipDelegate.cppClipObject.selectedSliceObject.startPositionSeconds + clipDelegate.cppClipObject.selectedSliceObject.lengthSeconds : 0

                        visible: clipDelegate.clipHasWav
                    }
                    Rectangle {
                        height: 16
                        anchors {
                            left: parent.left
                            top: parent.top
                            right: parent.right
                            margins: 1
                        }
                        color: "#99888888"
                        visible: detailsLabel.text && detailsLabel.text.trim().length > 0

                        QQC2.Label {
                            id: detailsLabel

                            anchors.centerIn: parent
                            width: parent.width - 4
                            elide: "ElideRight"
                            horizontalAlignment: "AlignHCenter"
                            font.pointSize: 8
                            text: clipDelegate.clipHasWav ? clipDelegate.clip.path.split("/").pop() : ""
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if ("sample-loop" === component.selectedChannel.trackType) {
                                component.selectedChannel.selectedClip = index;
                            } else {
                                component.selectedChannel.selectedSlotRow = index;
                            }
                        }
                    }
                }
            }
        }
    }
}
