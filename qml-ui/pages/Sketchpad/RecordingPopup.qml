/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian recording popup

Copyright (C) 2024 Anupam Basak <anupam.basak27@gmail.com>

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
import QtQml 2.15
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami
import QtGraphicalEffects 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian

Zynthian.Popup {
    id: root
    property QtObject selectedChannel: null
    property string selectedSlotType: "synth"
    property int selectedSlotIndex: 0
    property int selectedClip: 0
    property string lastSelectedClassName
    property QtObject lastSelectedValue
    property QtObject lastSelectedComponent

    spacing: Kirigami.Units.gridUnit * 0.5

    readonly property var acceptedButtonsWhenClosed: ["STOP_RECORD", "SWITCH_STOP", "SWITCH_RECORD"]
    property var cuiaCallback: function(cuia) {
        var returnValue = false;
        // This gets called from main when the dialog is not opened, so let's be explicit about what we want in that case
        if (root.opened || acceptedButtonsWhenClosed.indexOf(cuia) > -1) {
            switch (cuia) {
                case "SCREEN_MAIN_MENU":
                case "SCREEN_LAYER":
                case "SCREEN_LAYER_FX":
                case "SCREEN_BANK":
                case "SCREEN_PRESET":
                case "SCREEN_CONTROL":
                case "SCREEN_SKETCHPAD":
                case "SCREEN_SONG_MANAGER":
                case "SCREEN_PLAYGRID":
                case "SCREEN_ALSA_MIXER":
                case "SCREEN_EDIT_CONTEXTUAL":
                    // If someone hits one of the under-screen buttons, just close the thing,
                    // but also pass the buttons through so we can switch to that screen
                    root.close();
                    returnValue = false;
                    break;
                case "TRACK_1":
                case "TRACK_2":
                case "TRACK_3":
                case "TRACK_4":
                case "TRACK_5":
                case "NAVIGATE_LEFT":
                case "NAVIGATE_RIGHT":
                case "SELECT_UP":
                case "SELECT_DOWN":
                case "SWITCH_SELECT_SHORT":
                case "SWITCH_SELECT_BOLD":
                case "SWITCH_MODE_RELEASED":
                case "KNOB0_TOUCHED":
                case "KNOB0_RELEASED":
                case "KNOB1_TOUCHED":
                case "KNOB1_RELEASED":
                case "KNOB2_TOUCHED":
                case "KNOB2_RELEASED":
                case "KNOB3_TOUCHED":
                case "KNOB3_RELEASED":
                    returnValue = true;
                    break
                case "KNOB0_UP":
                    zynqtgui.sketchpad.metronomeEnabled = true
                    returnValue = true;
                    break;
                case "KNOB0_DOWN":
                    if (root.opened) {
                        zynqtgui.sketchpad.metronomeEnabled = false
                        returnValue = true;
                    }
                    break;
                case "KNOB1_UP":
                    countIn.value = Zynthian.CommonUtils.clamp(countIn.value + 1, countIn.from, countIn.to)
                    returnValue = true;
                    break;
                case "KNOB1_DOWN":
                    countIn.value = Zynthian.CommonUtils.clamp(countIn.value - 1, countIn.from, countIn.to)
                    returnValue = true;
                    break;
                case "KNOB2_UP":
                    applicationWindow().updateMasterVolume(1, false)
                    returnValue = true;
                    break;
                case "KNOB2_DOWN":
                    applicationWindow().updateMasterVolume(-1, false)
                    returnValue = true;
                    break;
                case "KNOB3_UP":
                    Zynthbox.SyncTimer.bpm = Zynthbox.SyncTimer.bpm + 1;
                    returnValue = true;
                    break;
                case "KNOB3_DOWN":
                    Zynthbox.SyncTimer.bpm = Zynthbox.SyncTimer.bpm - 1;
                    returnValue = true;
                    break;
                case "SWITCH_BACK_SHORT":
                case "SWITCH_BACK_BOLD":
                    root.close();
                    returnValue = true;
                    break;
                case "STOP_RECORD":
                case "SWITCH_STOP":
                    if (zynqtgui.sketchpad.recordingType === "midi" && zynqtgui.sketchpad.isRecording) {
                        // If stopping the recording using the stop button, don't open the dialog back up again, just stop recording
                        // Don't reset the state to what we had before recording, as that would be disruptive, just let the user get on where they are
                        _private.selectedPattern.recordLive = false;
                        zynqtgui.sketchpad.isRecording = false;
                        // Enable clip after recording
                        _private.selectedClip.enabled = true;
                        returnValue = true;
                    }
                    // TODO 1.1 For audio recording, move the logic in here as well, instead of the core cuia handler - either that, or the opposite direction, but we should have it in one place, instead of split up
                    break;
                case "SWITCH_RECORD":
                    // If user does alt+record, recording should be started immediately, and metronome+record to do so with default countin (if done while stopped, otherwise just start recording immediately)
                    if (zynqtgui.sketchpad.isRecording === false && (zynqtgui.altButtonPressed || zynqtgui.metronomeButtonPressed)) {
                        let doCountin = false;
                        if (zynqtgui.metronomeButtonPressed) {
                            doCountin = true;
                            zynqtgui.ignoreNextMetronomeButtonPress = true
                        }
                        let currentTrack = zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId);
                        // Take a snapshot of our current state, so we can keep that stable when changing settings
                        root.selectedChannel = currentTrack;
                        root.selectedSlotIndex = root.selectedChannel.selectedSlot.value;
                        root.selectedSlotType = root.selectedChannel.selectedSlot.className;
                        root.selectedClip = root.selectedChannel.selectedClip;
                        // Take a snapshot of our lastSelectedObj, so we can keep that stable when changing settings
                        root.lastSelectedClassName = zynqtgui.sketchpad.lastSelectedObj.className
                        root.lastSelectedValue = zynqtgui.sketchpad.lastSelectedObj.value
                        root.lastSelectedComponent = zynqtgui.sketchpad.lastSelectedObj.component
                        // Ensure that the solo state is restored when we close, but also that it matches what (if any) was set in the dialogue previously
                        _private.soloChannelOnOpen = zynqtgui.sketchpad.song.playChannelSolo;
                        _private.updateSoloState();
                        // Start the recording
                        root.beginMidiRecording(doCountin);
                        // And finally, say we consumed the event
                        returnValue = true;
                    } else if (zynqtgui.sketchpad.recordingType === "midi") {
                        // Only handle the recording work here if we're recording midi, as audio recording is handled by python logic
                        if (zynqtgui.sketchpad.isRecording) {
                            if (root.opened) {
                                // If the dialog is already open, and we push the record button again, stop recording
                                _private.selectedPattern.recordLive = false;
                                zynqtgui.sketchpad.isRecording = false;
                                // Enable clip after recording
                                _private.selectedClip.enabled = true;
                            } else {
                                // If we are recording and press the record button again, just open the dialog
                                root.open();
                            }
                        } else if (root.opened == false) {
                            // If we are not open, and also not recording, open the dialog
                            root.open();
                        } else {
                            root.beginMidiRecording(true);
                        }
                        returnValue = true;
                    } else if (zynqtgui.sketchpad.recordingType === "audio") {
                        // We want to make sure we set the recording clip to the one for our selected slot, otherwise we'll be recording to the wrong place
                        if (zynqtgui.sketchpad.isRecording === false) {
                            zynqtgui.clipToRecord = _private.selectedClip;
                        }
                        // But *don't* return true, because we still want this handled by the core event handler
                        // TODO 1.1 For audio recording, move the logic in here as well, instead of the core cuia handler - either that, or the opposite direction, but we should have it in one place, instead of split up
                    }
                    break;
            }
        }

        return returnValue;
    }

    function beginMidiRecording(startWithCountin) {
        zynqtgui.sketchpad.recordingType = "midi";
        zynqtgui.sketchpad.isRecording = true;
        _private.selectedPattern.liveRecordingSource = Zynthbox.MidiRouter.model.midiInSources[midiSourceCombo.currentIndex].value;
        _private.selectedPattern.recordLive = true;
        if (Zynthbox.SyncTimer.timerRunning == false) {
            if (startWithCountin && countIn.value > 0) {
                Zynthbox.SyncTimer.startWithCountin(countIn.value);
            } else {
                Zynthian.CommonUtils.startMetronomeAndPlayback();
            }
        }
    }

    parent: QQC2.Overlay.overlay
    y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
    x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
    closePolicy: zynqtgui.sketchpad.isRecording ? QQC2.Popup.NoAutoClose : (QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside)
    width: parent.width * 0.99
    height: parent.height * 0.97
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    onSelectedChannelChanged: {
        if (root.selectedChannel.trackType === "external") {
            zynqtgui.sketchpad.recordingSource = "external"
            zynqtgui.sketchpad.recordingChannel = "*"
        } else {
            zynqtgui.sketchpad.recordingSource = "internal-track"
        }

        // Reset source combo model to selected value when channel changes
        for (var i=0; i<sourceComboModel.count; i++) {
            if (sourceComboModel.get(i).value === zynqtgui.sketchpad.recordingSource) {
                sourceCombo.currentIndex = i
                break
            }
        }

        for (var i=0; i<recordingChannelComboModel.count; i++) {
            if (recordingChannelComboModel.get(i).value === zynqtgui.sketchpad.recordingChannel) {
                recordingChannelCombo.currentIndex = i
                break
            }
        }

        // Update selected track dropdown
        channelCombo.currentIndex = root.selectedChannel.id
    }
    function requestAudioRecording() {
        _private.recordAudio = true;
        root.open();
    }
    onOpened: {
        zynqtgui.recordingPopupActive = true

        let currentTrack = zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId);
        if (zynqtgui.sketchpad.isRecording === false) {
            if (_private.recordAudio) {
                // Only display the recording dialogue in audio mode if explicitly requested to do so
                zynqtgui.sketchpad.recordingType = "audio";
            } else {
                // Otherwise do midi recording
                zynqtgui.sketchpad.recordingType = "midi";
            }
            // If we're not already recording, take a snapshot of our current state, so we can keep that stable when changing settings
            root.selectedChannel = currentTrack;
            root.selectedSlotIndex = root.selectedChannel.selectedSlot.value;
            root.selectedSlotType = root.selectedChannel.selectedSlot.className;
            root.selectedClip = root.selectedChannel.selectedClip;
            // If we're not already recording, take a snapshot of our lastSelectedObj, so we can keep that stable when changing settings
            root.lastSelectedClassName = zynqtgui.sketchpad.lastSelectedObj.className
            root.lastSelectedValue = zynqtgui.sketchpad.lastSelectedObj.value
            root.lastSelectedComponent = zynqtgui.sketchpad.lastSelectedObj.component
            // Ensure that the solo state is restored when we close, but also that it matches what (if any) was set in the dialogue previously
            _private.soloChannelOnOpen = zynqtgui.sketchpad.song.playChannelSolo;
            _private.updateSoloState();
        }
    }
    onClosed: {
        if (zynqtgui.sketchpad.isRecording === false) {
            // Restore the previous solo state from before recording activities began
            if (zynqtgui.sketchpad.song.playChannelSolo !== _private.soloChannelOnOpen) {
                zynqtgui.sketchpad.song.playChannelSolo = _private.soloChannelOnOpen;
            }
            // Restore the current track state to also match the previous state
            zynqtgui.sketchpad.selectedTrackId = root.selectedChannel.id;
            applicationWindow().pageStack.getPage("sketchpad").bottomStack.tracksBar.switchToSlot(root.selectedSlotType, root.selectedSlotIndex);
            root.selectedChannel.selectedClip = root.selectedClip;
            // Restore the lastSelectedObj to also match the previous state
            zynqtgui.sketchpad.lastSelectedObj.setTo(root.lastSelectedClassName, root.lastSelectedValue, root.lastSelectedComponent)
            // Switch the track type to whatever the appropriate one is for the recorded sample if...
            // ... the recording was completed while the dialog was open (zynqtgui.sketchpad.isRecording === false)
            // ... we were doing audio recording (this doesn't make sense for midi)
            // ... we did not clear the recording first
            if (zynqtgui.sketchpad.recordingType === "audio" && _private.mostRecentlyRecordedClip !== null) {
                if (_private.mostRecentlyRecordedClip.isChannelSample) {
                    root.selectedChannel.trackType = "synth";
                } else {
                    root.selectedChannel.trackType = "sample-loop";
                }
            }
            // Clear out the known most-recent clip, because otherwise it'll be kept there forever and ever and ever, and we don't want that...
            _private.mostRecentlyRecordedClip = null;
            _private.recordAudio = false;
        }
        zynqtgui.recordingPopupActive = false
    }
    contentItem: ColumnLayout {
        anchors.fill: parent
        spacing: root.spacing

        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.leftMargin: root.spacing
            Layout.topMargin: root.spacing
            text: root.selectedChannel
                ? zynqtgui.sketchpad.recordingType === "audio"
                    ? _private.recordingIntoSketch
                        ? qsTr("Record into Sketch Slot %1 on Track %2").arg(root.selectedSlotIndex + 1).arg(root.selectedChannel.name)
                        : qsTr("Record into Sample Slot %1 on Track %2").arg(root.selectedSlotIndex + 1).arg(root.selectedChannel.name)
                    : qsTr("Recording into Clip %1%2 on Track %3").arg(root.selectedChannel.id + 1).arg(_private.selectedPattern.clipName).arg(root.selectedChannel.name)
                : ""
            QtObject {
                id: _private
                property bool recordAudio: false
                readonly property double preferredRowHeight: Kirigami.Units.gridUnit * 2.3
                readonly property bool recordingIntoSketch: ["TracksBar_sketchslot", "sketch"].includes(root.selectedSlotType)
                readonly property QtObject selectedClip: root.selectedChannel
                    ? recordingIntoSketch
                        ? root.selectedChannel.getClipsModelById(root.selectedSlotIndex).getClip(root.selectedChannel.id)
                        : root.selectedChannel.samples[root.selectedSlotIndex]
                    : null
                readonly property QtObject selectedSequence: root.selectedChannel ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName) : null
                readonly property QtObject selectedPattern: sequence && root.selectedChannel ? sequence.getByClipId(root.selectedChannel.id, root.selectedChannel.selectedClip) : null
                readonly property QtObject selectedClipPattern: sequence && root.selectedChannel ? sequence.getByClipId(root.selectedChannel.id, root.selectedSlotIndex) : null
                property QtObject mostRecentlyRecordedClip: null
                property bool midiSoloTrack: false
                property int soloChannelOnOpen: -1
                property bool armRecording: false
                onMidiSoloTrackChanged: {
                    _private.updateSoloState();
                }
                function updateSoloState() {
                    if (root.visible) {
                        if (zynqtgui.sketchpad.recordingType === "midi" && _private.midiSoloTrack) {
                            zynqtgui.sketchpad.song.playChannelSolo = root.selectedChannel.id;
                        } else {
                            zynqtgui.sketchpad.song.playChannelSolo = -1;
                        }
                    }
                }
                function stepLengthUp() {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        _private.selectedPattern.stepLength = _private.selectedPattern.stepLength + 1;
                    } else {
                       _private.selectedPattern.stepLength = _private.selectedPattern.nextStepLengthStep(_private.selectedPattern.stepLength, 1);
                    }
                }
                function stepLengthDown() {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        _private.selectedPattern.stepLength = _private.selectedPattern.stepLength - 1;
                    } else {
                        _private.selectedPattern.stepLength = _private.selectedPattern.nextStepLengthStep(_private.selectedPattern.stepLength, -1);
                    }
                }
                function patternQuantizingAmountUp() {
                    if (_private.selectedPattern && _private.selectedPattern.liveRecordingQuantizingAmount < 1536) {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            _private.selectedPattern.liveRecordingQuantizingAmount = _private.selectedPattern.liveRecordingQuantizingAmount + 1;
                        } else {
                            _private.selectedPattern.liveRecordingQuantizingAmount = _private.selectedPattern.nextStepLengthStep(_private.selectedPattern.liveRecordingQuantizingAmount, 1);
                        }
                    }
                }
                function patternQuantizingAmountDown() {
                    if (_private.selectedPattern && _private.selectedPattern.liveRecordingQuantizingAmount > 0) {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            _private.selectedPattern.liveRecordingQuantizingAmount = _private.selectedPattern.liveRecordingQuantizingAmount -0;
                        } else {
                            if (_private.selectedPattern.liveRecordingQuantizingAmount === 1) {
                                _private.selectedPattern.liveRecordingQuantizingAmount = 0;
                            } else {
                                _private.selectedPattern.liveRecordingQuantizingAmount = _private.selectedPattern.nextStepLengthStep(_private.selectedPattern.liveRecordingQuantizingAmount, -1);
                            }
                        }
                    }
                }
                function patternLengthUp() {
                    if (_private.selectedPattern && _private.selectedPattern.patternLength < (_private.selectedPattern.bankLength * _private.selectedPattern.width)) {
                        if (zynqtgui.modeButtonPressed) {
                            zynqtgui.ignoreNextModeButtonPress = true;
                            _private.selectedPattern.patternLength = _private.selectedPattern.patternLength + 1;
                        } else {
                            if (_private.selectedPattern.availableBars * _private.selectedPattern.width === _private.selectedPattern.patternLength) {
                                _private.selectedPattern.patternLength = _private.selectedPattern.patternLength + _private.selectedPattern.width;
                            } else {
                                _private.selectedPattern.patternLength = _private.selectedPattern.availableBars * _private.selectedPattern.width;
                            }
                        }
                    }
                }
                function patternLengthDown() {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        _private.selectedPattern.patternLength = _private.selectedPattern.patternLength - 1;
                    } else {
                        if (_private.selectedPattern && _private.selectedPattern.patternLength > _private.selectedPattern.width) {
                            if (_private.selectedPattern.availableBars * _private.selectedPattern.width === _private.selectedPattern.patternLength) {
                                _private.selectedPattern.patternLength = _private.selectedPattern.patternLength - _private.selectedPattern.width;
                            } else {
                                _private.selectedPattern.patternLength = (_private.selectedPattern.availableBars - 1) * _private.selectedPattern.width;
                            }
                        }
                    }
                }
            }
            Connections {
                target: zynqtgui.sketchpad
                onRecordingTypeChanged: {
                    _private.updateSoloState();
                }
                onClipToRecordChanged: {
                    if (zynqtgui.sketchpad.clipToRecord != null) {
                        _private.mostRecentlyRecordedClip = zynqtgui.sketchpad.clipToRecord;
                    }
                }
            }
        }
        Kirigami.Separator {
            Layout.fillWidth: true
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: root.spacing
                enabled: zynqtgui.sketchpad.isRecording === false

                RowLayout { // Common Settings Section
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                    Layout.maximumHeight: Layout.preferredHeight
                    Layout.minimumHeight: Layout.preferredHeight

                    Zynthian.Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        contentItem: Item {
                            Zynthian.KnobIndicator {
                                anchors {
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                height: Kirigami.Units.gridUnit * 1.3
                                width: height
                                knobId: 0
                            }
                            ColumnLayout {
                                anchors.fill: parent
                                QQC2.Switch {
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignCenter
                                    // Explicitly set indicator implicitWidth otherwise the switch size is too small
                                    indicator.implicitWidth: Kirigami.Units.gridUnit * 3
                                    checked: zynqtgui.sketchpad.metronomeEnabled
                                    onToggled: {
                                        zynqtgui.sketchpad.metronomeEnabled = checked
                                    }
                                }
                                QQC2.Label {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignBottom
                                    wrapMode: QQC2.Label.WordWrap
                                    horizontalAlignment: QQC2.Label.AlignHCenter
                                    text: "Metronome"
                                }
                            }
                        }
                    }
                    Zynthian.Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        contentItem: Item {
                            Zynthian.KnobIndicator {
                                anchors {
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                height: Kirigami.Units.gridUnit * 1.3
                                width: height
                                knobId: 1
                            }
                            ColumnLayout {
                                anchors.fill: parent
                                RowLayout {
                                    id: countIn
                                    property int from: 0
                                    property int to: 4
                                    property int value: zynqtgui.sketchpad.countInBars

                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignCenter
                                    onValueChanged: {
                                        if (zynqtgui.sketchpad.countInBars != countIn.value) {
                                            zynqtgui.sketchpad.countInBars = countIn.value;
                                        }
                                    }

                                    QQC2.Button {
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                                        Layout.preferredHeight: width
                                        icon.name: "list-remove-symbolic"
                                        enabled: countIn.value > countIn.from
                                        onClicked: {
                                            countIn.value = Zynthian.CommonUtils.clamp(countIn.value-1, countIn.from, countIn.to)
                                        }
                                    }
                                    Rectangle {
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                        Kirigami.Theme.inherit: false
                                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                        color: Kirigami.Theme.backgroundColor
                                        border.color: "#ff999999"
                                        border.width: 1
                                        radius: 4

                                        QQC2.Label {
                                            anchors.centerIn: parent
                                            text: countIn.value == 0
                                                ? qsTr("Off")
                                                : countIn.value == 1
                                                    ? qsTr("1 bar")
                                                    : qsTr("%1 Bars").arg(countIn.value)
                                        }
                                    }
                                    QQC2.Button {
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                                        Layout.preferredHeight: width
                                        icon.name: "list-add-symbolic"
                                        enabled: countIn.value < countIn.to
                                        onClicked: {
                                            countIn.value = Zynthian.CommonUtils.clamp(countIn.value+1, countIn.from, countIn.to)
                                        }
                                    }
                                }
                                QQC2.Label {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignBottom
                                    wrapMode: QQC2.Label.WordWrap
                                    horizontalAlignment: QQC2.Label.AlignHCenter
                                    text: "Count In (Bars)"
                                }
                            }
                        }
                    }
                    Zynthian.Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        contentItem: Item {
                            Zynthian.KnobIndicator {
                                anchors {
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                height: Kirigami.Units.gridUnit * 1.3
                                width: height
                                knobId: 2
                            }
                            RowLayout {
                                anchors.fill: parent
                                Item { Layout.fillHeight: true; Layout.fillWidth: true; }
                                QQC2.Label {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                    text: qsTr("Master\nVolume")
                                }
                                Zynthian.SketchpadDial {
                                    property QtObject gainHandler: Zynthbox.Plugin.globalPlaybackClient.dryGainHandler
                                    Layout.fillHeight: true
                                    controlObj: gainHandler
                                    controlProperty: "gainDb"
                                    valueString: qsTr("%1 dB").arg(dial.value.toFixed(2))
                                    fineTuneButtonsVisible: false
                                    onDoubleClicked: gainHandler.gainDb = zynqtgui.initialMasterVolume
                                    dial {
                                        stepSize: 0.5
                                        from: gainHandler.minimumDecibel
                                        to: gainHandler.maximumDecibel
                                    }
                                }
                                Item { Layout.fillHeight: true; Layout.fillWidth: true; }
                            }
                        }
                    }
                    Zynthian.Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        contentItem: Item {
                            Zynthian.KnobIndicator {
                                anchors {
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                height: Kirigami.Units.gridUnit * 1.3
                                width: height
                                knobId: 3
                            }
                            RowLayout {
                                anchors.fill: parent
                                Item { Layout.fillHeight: true; Layout.fillWidth: true; }
                                QQC2.Label {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignRight
                                    text: qsTr("BPM")
                                }
                                Zynthian.SketchpadDial {
                                    Layout.fillHeight: true
                                    controlObj: Zynthbox.SyncTimer
                                    controlProperty: "bpm"
                                    fineTuneButtonsVisible: false
                                    dial {
                                        stepSize: 1
                                        from: 50
                                        to: 200
                                    }
                                }
                                Item { Layout.fillHeight: true; Layout.fillWidth: true; }
                            }
                        }
                    }
                }
                ColumnLayout { // Recording Type Specific Settings Section
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 10
                    Layout.topMargin: root.spacing

                    // RowLayout {
                    //     QQC2.Button {
                    //         Layout.fillWidth: true
                    //         Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    //         Layout.preferredHeight: _private.preferredRowHeight
                    //         checked: zynqtgui.sketchpad.recordingType === "audio"
                    //         text: qsTr("Record Audio")
                    //         onClicked: {
                    //             zynqtgui.sketchpad.recordingType = "audio"
                    //         }
                    //     }
                    //     QQC2.Button {
                    //         Layout.fillWidth: true
                    //         Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    //         Layout.preferredHeight: _private.preferredRowHeight
                    //         checked: zynqtgui.sketchpad.recordingType === "midi"
                    //         text: qsTr("Record Midi")
                    //         onClicked: {
                    //             zynqtgui.sketchpad.recordingType = "midi"
                    //         }
                    //     }
                    // }
                    StackLayout {
                        id: recordingTypeSettingsStack
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: {
                            if (zynqtgui.sketchpad.recordingType === "audio") {
                                return 0
                            } else if (zynqtgui.sketchpad.recordingType === "midi") {
                                return 1
                            } else {
                                return -1
                            }
                        }

                        ColumnLayout {
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                QQC2.Label {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                                    Layout.alignment: Qt.AlignCenter
                                    text: qsTr("Audio Source:")
                                }
                                Zynthian.ComboBox {
                                    id: sourceCombo

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.alignment: Qt.AlignCenter
                                    model: ListModel {
                                        id: sourceComboModel

                                        ListElement { text: "Internal (Sketchpad Track)"; value: "internal-track" }
                                        ListElement { text: "Internal (Master Output)"; value: "internal-master" }
                                        ListElement { text: "External (Audio In)"; value: "external" }
                                    }
                                    textRole: "text"
                                    onActivated: {
                                        zynqtgui.sketchpad.recordingSource = sourceComboModel.get(index).value
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                visible: zynqtgui.sketchpad.recordingSource === "external"
                                QQC2.Label {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                                    Layout.alignment: Qt.AlignCenter
                                    text: qsTr("Recording Channel:")
                                }
                                Zynthian.ComboBox {
                                    id: recordingChannelCombo

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.alignment: Qt.AlignCenter
                                    model: ListModel {
                                        id: recordingChannelComboModel

                                        ListElement { text: "Left Channel"; value: "1" }
                                        ListElement { text: "Right Channel"; value: "2" }
                                        ListElement { text: "Stereo"; value: "*" }
                                    }
                                    textRole: "text"
                                    onActivated: {
                                        zynqtgui.sketchpad.recordingChannel = recordingChannelComboModel.get(index).value
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                visible: sourceCombo.currentIndex >= 0 && sourceComboModel.get(sourceCombo.currentIndex).value === "internal-track"
                                QQC2.Label {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                                    Layout.alignment: Qt.AlignCenter
                                    enabled: parent.enabled
                                    text: qsTr("Source Track:")
                                }
                                Zynthian.ComboBox {
                                    id: channelCombo

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.alignment: Qt.AlignCenter
                                    model: zynqtgui.sketchpad.song.channelsModel
                                    textRole: "name"
                                    textPrefix: "Track "
                                    currentIndex: -1 // Current index will be set by selectedChannelChanged handler
                                    onActivated: {
                                        zynqtgui.sketchpad.selectedTrackId = index
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.minimumHeight: Layout.preferredHeight
                                    checked: zynqtgui.sketchpad.recordSolo === false
                                    text: qsTr("Play All Enabled Tracks")
                                    onClicked: {
                                        zynqtgui.sketchpad.recordSolo = false;
                                    }
                                }
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.minimumHeight: Layout.preferredHeight
                                    checked: zynqtgui.sketchpad.recordSolo === true
                                    text: qsTr("Solo %1").arg(channelCombo.currentText)
                                    onClicked: {
                                        zynqtgui.sketchpad.recordSolo = true;
                                    }
                                }
                                QQC2.Button {
                                    visible: false // Keep it invisible until implemented
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.minimumHeight: Layout.preferredHeight
                                    checked: false // which thing
                                    text: qsTr("No Playback")
                                    onClicked: {
                                        // magic stuff what?!
                                    }
                                }
                            }
                        }
                        ColumnLayout {
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                QQC2.Label {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                                    text: qsTr("Midi Source:")
                                }
                                Zynthian.ComboBox {
                                    id: midiSourceCombo
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    currentIndex: 0
                                    model: Zynthbox.MidiRouter.model.midiInSources
                                    textRole: "text"
                                }
                            }
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.minimumHeight: Layout.preferredHeight
                                    checked: _private.midiSoloTrack === false
                                    text: qsTr("Play All Enabled Tracks")
                                    onClicked: {
                                        _private.midiSoloTrack = false;
                                    }
                                }
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.minimumHeight: Layout.preferredHeight
                                    checked: _private.midiSoloTrack === true
                                    text: root.selectedChannel ? qsTr("Solo Track %1").arg(root.selectedChannel.name) : ""
                                    onClicked: {
                                        _private.midiSoloTrack = true;
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.minimumHeight: Layout.preferredHeight
                                    checked: _private.armRecording === false
                                    text: qsTr("Record Immediately")
                                    onClicked: {
                                        _private.armRecording = false;
                                    }
                                    opacity: 0 // TODO Implement arm-to-record
                                    enabled: false
                                }
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.minimumHeight: Layout.preferredHeight
                                    checked: _private.armRecording === true
                                    text: qsTr("Wait For First Note")
                                    onClicked: {
                                        _private.armRecording = true;
                                    }
                                    opacity: 0 // TODO Implement arm-to-record
                                    enabled: false
                                }
                            }
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                RowLayout {
                                    Layout.fillWidth: true
                                    Zynthian.PlayGridButton {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        icon.name: "list-remove-symbolic"
                                        icon.width: 24
                                        icon.height: 24
                                        enabled: _private.selectedPattern && _private.selectedPattern.stepLength > _private.selectedPattern.nextStepLengthStep(_private.selectedPattern.stepLength, -1)
                                        onClicked: {
                                            _private.stepLengthDown();
                                        }
                                    }
                                    QQC2.Label {
                                        id:noteLengthLabel
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        horizontalAlignment: Text.AlignHCenter
                                        text: _private.selectedPattern ? qsTr("Step Length: %1").arg(_private.selectedPattern.stepLengthName(_private.selectedPattern.stepLength)) : ""
                                    }
                                    Zynthian.PlayGridButton {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        icon.name: "list-add-symbolic"
                                        icon.width: 24
                                        icon.height: 24
                                        icon.color: Kirigami.Theme.textColor
                                        enabled: _private.selectedPattern && _private.selectedPattern.stepLength < _private.selectedPattern.nextStepLengthStep(_private.selectedPattern.stepLength, 1)
                                        onClicked: {
                                            _private.stepLengthUp();
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                                    Zynthian.PlayGridButton {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                        icon.name: "list-remove-symbolic"
                                        icon.width: 24
                                        icon.height: 24
                                        enabled: _private.selectedPattern && _private.selectedPattern.liveRecordingQuantizingAmount > 0
                                        onClicked: {
                                            _private.patternQuantizingAmountDown();
                                        }
                                    }
                                    QQC2.Label {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredHeight: noteLengthLabel.height
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        horizontalAlignment: Text.AlignHCenter
                                        fontSizeMode: Text.Fit
                                        minimumPointSize: 6
                                        wrapMode: Text.NoWrap
                                        text: _private.selectedPattern
                                            ? _private.selectedPattern.liveRecordingQuantizingAmount === 0
                                                ? qsTr("Quantize To Step")
                                                : qsTr("Quantize To: %1").arg(_private.selectedPattern.stepLengthName(_private.selectedPattern.liveRecordingQuantizingAmount))
                                            : ""
                                        MultiPointTouchArea {
                                            anchors.fill: parent
                                            touchPoints: [
                                                TouchPoint {
                                                    id: patternQuantizingAmountSlidePoint;
                                                    property double increment: 1
                                                    property double slideIncrement: 0.1
                                                    property double upperBound: 1536
                                                    property double lowerBound: 0
                                                    property var currentValue: undefined
                                                    onPressedChanged: {
                                                        if (pressed) {
                                                            currentValue = _private.selectedPattern.liveRecordingQuantizingAmount;
                                                        }
                                                    }
                                                    onYChanged: {
                                                        if (pressed && currentValue !== undefined) {
                                                            var delta = (patternQuantizingAmountSlidePoint.x - patternQuantizingAmountSlidePoint.startX) * patternQuantizingAmountSlidePoint.slideIncrement;
                                                            _private.selectedPattern.liveRecordingQuantizingAmount = Math.min(Math.max(currentValue + delta, patternQuantizingAmountSlidePoint.lowerBound), patternQuantizingAmountSlidePoint.upperBound);
                                                        }
                                                    }
                                                }
                                            ]
                                        }
                                    }
                                    Zynthian.PlayGridButton {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                        icon.name: "list-add-symbolic"
                                        icon.width: 24
                                        icon.height: 24
                                        enabled: _private.selectedPattern && _private.selectedPattern.liveRecordingQuantizingAmount < 1536
                                        onClicked: {
                                            _private.patternQuantizingAmountUp();
                                        }
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                                    Zynthian.PlayGridButton {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                        icon.name: "list-remove-symbolic"
                                        icon.width: 24
                                        icon.height: 24
                                        enabled: _private.selectedPattern && _private.selectedPattern.patternLength > _private.selectedPattern.width
                                        onClicked: {
                                            _private.patternLengthDown();
                                        }
                                    }
                                    QQC2.Label {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredHeight: noteLengthLabel.height
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        horizontalAlignment: Text.AlignHCenter
                                        fontSizeMode: Text.Fit
                                        minimumPointSize: 6
                                        wrapMode: Text.NoWrap
                                        text: _private.selectedPattern
                                              ? _private.selectedPattern.availableBars * _private.selectedPattern.width === _private.selectedPattern.patternLength
                                                ? qsTr("Pattern Length: %1 Bars").arg(_private.selectedPattern.availableBars)
                                                : qsTr("Pattern Length: %1.%2 Bars").arg(_private.selectedPattern.availableBars - 1).arg(_private.selectedPattern.patternLength - ((_private.selectedPattern.availableBars - 1) * _private.selectedPattern.width))
                                        : ""
                                        MultiPointTouchArea {
                                            anchors.fill: parent
                                            touchPoints: [
                                                TouchPoint {
                                                    id: patternLengthSlidePoint;
                                                    property double increment: 1
                                                    property double slideIncrement: 0.2
                                                    property double upperBound: _private.selectedPattern ? _private.selectedPattern.bankLength * _private.selectedPattern.width : 128
                                                    property double lowerBound: 1
                                                    property var currentValue: undefined
                                                    onPressedChanged: {
                                                        if (pressed) {
                                                            currentValue = _private.selectedPattern.patternLength;
                                                        }
                                                    }
                                                    onYChanged: {
                                                        if (pressed && currentValue !== undefined) {
                                                            var delta = (patternLengthSlidePoint.x - patternLengthSlidePoint.startX) * patternLengthSlidePoint.slideIncrement;
                                                            _private.selectedPattern.patternLength = Math.min(Math.max(currentValue + delta, patternLengthSlidePoint.lowerBound), patternLengthSlidePoint.upperBound);
                                                        }
                                                    }
                                                }
                                            ]
                                        }
                                    }

                                    Zynthian.PlayGridButton {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                        icon.name: "list-add-symbolic"
                                        icon.width: 24
                                        icon.height: 24
                                        enabled: _private.selectedPattern && _private.selectedPattern.patternLength < (_private.selectedPattern.bankLength * _private.selectedPattern.width)
                                        onClicked: {
                                            _private.patternLengthUp();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                RowLayout { // Post Recording Preview section
                    id: recordingSectionLayout
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                    Layout.maximumHeight: Layout.preferredHeight
                    Layout.minimumHeight: Layout.preferredHeight
                    spacing: root.spacing

                    QQC2.Control {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        // Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        padding: 1

                        background: Item {

                            Rectangle {
                                visible: !svgBg2.fromCurrentTheme
                                anchors.fill: parent
                                border.width: 1
                                border.color: "#ff999999"
                                radius: 4
                                color: "#222222"
                            }

                            PlasmaCore.FrameSvgItem {
                                id: svgBg2
                                anchors.fill: parent
                                readonly property bool highlighted: false

                                imagePath: "widgets/statusinfo_background"
                                colorGroup: PlasmaCore.Theme.ViewColorGroup
                                prefix: svgBg2.highlighted ? ["focus", ""] : ""
                            }
                        }

                        contentItem: Item {
                            id: patternVisualiserItem

                            clip: true

                            layer.enabled: true
                            layer.effect: OpacityMask
                            {
                                maskSource: Rectangle
                                {
                                    width: patternVisualiserItem.width
                                    height: patternVisualiserItem.height
                                    radius: 4
                                }
                            }
                            Zynthbox.WaveFormItem {
                                anchors.fill: parent
                                color: Kirigami.Theme.textColor
                                visible: recordingTypeSettingsStack.currentIndex === 0
                                start: 0
                                end: length
                                source: {
                                    if (zynqtgui.sketchpad.isRecording) {
                                        return "audioLevelsChannel:/ports"
                                    } else if (_private.selectedClip != null && !_private.selectedClip.isEmpty) {
                                        return _private.selectedClip.path
                                    } else {
                                        return ""
                                    }
                                }
                            }
                            Image {
                                id: patternVisualiser

                                visible: _private.selectedPattern !== null && recordingTypeSettingsStack.currentIndex === 1

                                anchors {
                                    fill: parent
                                    // margins: Kirigami.Units.smallSpacing
                                }
                                smooth: false
                                asynchronous: true
                                Timer {
                                    id: patternVisualiserThumbnailUpdater
                                    interval: 10; repeat: false; running: false;
                                    onTriggered: {
                                        patternVisualiser.source = _private.selectedPattern.thumbnailUrl;
                                    }
                                }
                                Connections {
                                    target: _private.selectedPattern
                                    onThumbnailUrlChanged: {
                                        patternVisualiserThumbnailUpdater.restart();
                                    }
                                }
                                Connections {
                                    target: _private
                                    onSelectedPatternChanged: {
                                        patternVisualiserThumbnailUpdater.restart();
                                    }
                                }
                                Rectangle { // Progress
                                    anchors {
                                        top: parent.top
                                        bottom: parent.bottom
                                    }
                                    visible: patternVisualiser.visible && _private.selectedPattern ? _private.selectedPattern.isPlaying : false
                                    color: Kirigami.Theme.highlightColor
                                    width: Math.max(1, Math.floor(widthFactor)) // this way the progress rect is the same width as a step
                                    property double widthFactor: visible ? parent.width / (_private.selectedPattern.width * _private.selectedPattern.bankLength) : 1
                                    x: visible ? _private.selectedPattern.bankPlaybackPosition * widthFactor : 0
                                }
                                QQC2.Label {
                                    anchors {
                                        top: parent.top
                                        right: parent.right
                                        margins: Kirigami.Units.smallSpacing
                                        rightMargin: patternVisualiser.visible ? parent.width - (_private.selectedPattern.patternLength * (parent.width / (_private.selectedPattern.width * _private.selectedPattern.bankLength))) : 0
                                    }
                                    text: patternVisualiser.visible ? "%1s".arg(patternBarsToSeconds(_private.selectedPattern.patternLength, _private.selectedPattern.stepLength, Zynthbox.SyncTimer.bpm).toFixed(2)) : ""
                                    function patternBarsToSeconds(patternSteps, noteLength, bpm) {
                                        // Set up the loop points in the new recording
                                        let patternSubbeatToTickMultiplier = (Zynthbox.SyncTimer.getMultiplier() / 32);
                                        // Reset this to beats (rather than pattern subbeats)
                                        let patternDurationInBeats = patternSteps * noteLength / patternSubbeatToTickMultiplier;
                                        let patternDurationInSeconds = Zynthbox.SyncTimer.subbeatCountToSeconds(bpm, patternDurationInBeats * patternSubbeatToTickMultiplier);
                                        return patternDurationInSeconds;
                                    }
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.largeSpacing
                                spacing: Kirigami.Units.largeSpacing
                                opacity: 0.7

                                Rectangle {
                                    property real audioLevel: {
                                        if (root.visible && root.selectedChannel != null) {
                                            if (zynqtgui.sketchpad.recordingSource.startsWith("internal")) {
                                                return Zynthbox.AudioLevels.channels[root.selectedChannel.id]
                                            } else if (zynqtgui.sketchpad.recordingSource === "external") {
                                                return Zynthbox.AudioLevels.captureA
                                            } else {
                                                return -100
                                            }
                                        } else {
                                            return -100
                                        }
                                    }
                                    Layout.preferredWidth: parent.width * Zynthian.CommonUtils.interp(audioLevel, -100, 20, 0, 1)
                                    Layout.minimumWidth: Layout.preferredWidth
                                    Layout.maximumWidth: Layout.preferredWidth
                                    Layout.fillHeight: true
                                    color: Kirigami.Theme.highlightColor
                                    radius: 100
                                }
                                Rectangle {
                                    property real audioLevel: {
                                        if (root.visible && root.selectedChannel != null) {
                                            if (zynqtgui.sketchpad.recordingSource.startsWith("internal")) {
                                                return Zynthbox.AudioLevels.channels[root.selectedChannel.id]
                                            } else if (zynqtgui.sketchpad.recordingSource === "external") {
                                                return Zynthbox.AudioLevels.captureB
                                            } else {
                                                return -100
                                            }
                                        } else {
                                            return -100
                                        }
                                    }
                                    Layout.preferredWidth: parent.width * Zynthian.CommonUtils.interp(audioLevel, -100, 20, 0, 1)
                                    Layout.minimumWidth: Layout.preferredWidth
                                    Layout.maximumWidth: Layout.preferredWidth
                                    Layout.fillHeight: true
                                    color: Kirigami.Theme.highlightColor
                                    radius: 100
                                }
                            }
                        }
                    }

                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        icon.name: "edit-clear-symbolic"
                        icon.color: Kirigami.Theme.textColor
                        onClicked: {
                            switch(recordingTypeSettingsStack.currentIndex) {
                            case 0: // Audio Recording
                                applicationWindow().confirmClearClip(_private.selectedClip);
                                if (_private.selectedClip.path == null) {
                                    _private.mostRecentlyRecordedClip = null;
                                }
                                break;
                            case 1: // MIDI Recording
                                if (_private.selectedPattern.hasNotes) {
                                    applicationWindow().confirmClearPattern(root.selectedChannel, _private.selectedPattern);
                                }
                                break;
                            default:
                                // Audio Recording has three options:
                                // - Clear slot and delete recording
                                // - Clear slot and leave recording
                                // - Don't clear
                                break;
                            }
                        }
                    }
                }
            }
            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                Layout.minimumWidth: Layout.preferredWidth
                Layout.rightMargin: root.spacing
                spacing: root.spacing
                QQC2.Button {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 18
                    icon.name: zynqtgui.sketchpad.isRecording ? "media-playback-stop" : "media-record-symbolic"
                    onClicked: {
                        zynqtgui.callable_ui_action_simple("SWITCH_RECORD");
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.minimumHeight: recordingSectionLayout.height
                    Layout.maximumHeight: recordingSectionLayout.height
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                    icon.name: "view-grid-symbolic"
                    onClicked: {
                        zynqtgui.callable_ui_action_simple("SHOW_KEYBOARD");
                    }
                }
            }
        }
        QQC2.Button {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            text: qsTr("Close")
            onClicked: {
                root.close()
            }
        }
    }
}
