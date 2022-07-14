/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Song Player Page

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

import libzl 1.0 as ZL
import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

QQC2.Popup {
    id: component

    /**
     * \brief Main function for opening the dialog (use this instead of open())
     * @param song The zl.song object for the dialog to operate on
     */
    function recordSong(song) {
        for (var trackIndex = 0; trackIndex < 10; ++trackIndex) {
            // Work out which tracks we want to default-enable (that is, all tracks which have things that are likely to be making a noise)
            var shouldRecord = false;
            var track = song.tracksModel.getTrack(trackIndex);
            if (track.trackAudioType === "synth") {
                for (var soundIndex = 0; soundIndex < 5; ++soundIndex) {
                    if (track.chainedSounds[soundIndex] > -1) {
                        shouldRecord = true;
                        break;
                    }
                }
            } else if (track.trackAudioType === "sample-loop") {
                for (var loopIndex = 0; loopIndex < 10; ++loopIndex) {
                    if (track.clipsModel.getClip(loopIndex).cppObjId > -1) {
                        shouldRecord = true;
                        break;
                    }
                }
            } else if (track.trackAudioType === "sample-trig" || track.trackAudioType === "sample-slice") {
                for (var sampleIndex = 0; sampleIndex < 5; ++sampleIndex) {
                    if (track.samples[sampleIndex].cppObjId > -1) {
                        shouldRecord = true;
                        break;
                    }
                }
            } else {
                // Assume external tracks shouldn't be recorded, as they are not going to make internal noises
            }
            ZL.AudioLevels.setTrackToRecord(trackIndex, shouldRecord);
        }
        if (song.mixesModel.songMode) {
            // Song mode enabled, play the full song
            songDurationSpin.value = ZynQuick.PlayGridManager.syncTimer.getMultiplier() * zynthian.zynthiloops.song.mixesModel.selectedMix.segmentsModel.totalBeatDuration;
        } else {
            // No song mode, just play the current scene, with the longest pattern duration as the duration
            var sequence = ZynQuick.PlayGridManager.getSequenceModel(song.scenesModel.selectedSketchName)
            var longestPatternDuration = 0;
            // Assemble the duration of time we want to be recording for
            var noteLengths = { 1: 32, 2: 16, 3: 8, 4: 4, 5: 2, 6: 1 }
            for (var trackIndex = 0; trackIndex < 10; ++trackIndex) {
                for (var partIndex = 0; partIndex < 5; ++partIndex) {
                    var pattern = sequence.getByPart(trackIndex, partIndex);
                    var patternDuration = pattern.width * pattern.availableBars * noteLengths[pattern.noteLength];
                    if (patternDuration > longestPatternDuration) {
                        longestPatternDuration = patternDuration;
                    }
                }
            }
            songDurationSpin.value = longestPatternDuration;
        }
        _private.song = song;
        open();
    }

    function cuiaCallback(cuia) {
        var returnValue = false;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                component.close();
                returnValue = true;
                break;
        case "SWITCH_SELECT_SHORT":
            _private.startRecording();
            returnValue = true;
            break;
        }
        return returnValue;
    }
    exit: null; enter: null; // Disable the enter and exit transition animations. TODO This really wants doing somewhere central...
    modal: true
    focus: true
    parent: QQC2.Overlay.overlay
    y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
    x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
    closePolicy: _private.recordingProgress === -1 ? (QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside) : QQC2.Popup.NoAutoClose
    ColumnLayout {
        implicitHeight: Kirigami.Units.gridUnit * 40
        implicitWidth: Kirigami.Units.gridUnit * 60
        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Record Song"
            QtObject {
                id: _private
                property double recordingProgress: -1
                property QtObject song

                property int songDurationInTicks: songDurationSpin.value * ZynQuick.PlayGridManager.syncTimer.getMultiplier()
                property int leadinDurationInTicks: leadinSpin.value * ZynQuick.PlayGridManager.syncTimer.getMultiplier()
                property int fadeoutDurationInTicks: fadeoutSpin.value * ZynQuick.PlayGridManager.syncTimer.getMultiplier()

                property bool isRecording: false
                property int cumulativeBeats
                function startRecording() {
                    _private.recordingProgress = 0;
                    // Set the filenames for each track (never mind whether they're being recorded or not, it doesn't hurt)
                    var date = new Date();
                    var baseRecordingLocation = _private.song.sketchFolder + "exports/exported-" + date.getFullYear() + date.getMonth() + date.getDate() + "-" + date.getHours() + date.getMinutes() + "/track-";
                    for (var trackIndex = 0; trackIndex < 10; ++trackIndex) {
                        var track = _private.song.tracksModel.getTrack(trackIndex);
                        var soundIndication = "(unknown)";
                        if (track.trackAudioType === "synth") {
                            for (var soundIndex = 0; soundIndex < 5; ++soundIndex) {
                                if (track.chainedSounds[soundIndex] > -1) {
                                    soundIndication = track.connectedSoundName.replace(/([^a-z0-9]+)/gi, '-');
                                    break;
                                }
                            }
                        } else if (track.trackAudioType === "sample-loop") {
                            for (var loopIndex = 0; loopIndex < 10; ++loopIndex) {
                                var clip = track.clipsModel.getClip(loopIndex);
                                if (clip.cppObjId > -1) {
                                    // We pick the name of whatever the first loop is here, just so we've got one
                                    soundIndication = clip.path.split("/").pop();
                                    soundIndication = soundIndication.substring(0, soundIndication.lastIndexOf("."));
                                    if (soundIndication.endsWith(".clip")) {
                                        soundIndication = soundIndication.substring(0, soundIndication.length - 5);
                                    }
                                    break;
                                }
                            }
                        } else if (track.trackAudioType === "sample-trig" || track.trackAudioType === "sample-slice") {
                            for (var sampleIndex = 0; sampleIndex < 5; ++sampleIndex) {
                                var clip = track.samples[sampleIndex];
                                if (clip.cppObjId > -1) {
                                    // We pick the name of whatever the first sample is here, just so we've got one
                                    soundIndication = clip.path.split("/").pop();
                                    soundIndication = soundIndication.substring(0, soundIndication.lastIndexOf("."));
                                    if (soundIndication.endsWith(".clip")) {
                                        soundIndication = soundIndication.substring(0, soundIndication.length - 5);
                                    }
                                    break;
                                }
                            }
                        } else {
                            soundIndication = "external";
                        }
                        console.log("Setting track", trackIndex, "filename prefix to", baseRecordingLocation + (trackIndex + 1) + "-" + soundIndication);
                        ZL.AudioLevels.setTrackFilenamePrefix(trackIndex, baseRecordingLocation + (trackIndex + 1) + "-" + soundIndication);
                    }
                    // Start the recording
                    ZL.AudioLevels.startRecording();
                    _private.cumulativeBeats = 0;
                    if (_private.leadinDurationInTicks > 0) {
                        // If we've got a lead-in, start the playback starter
                        console.log("Starting recording playback starter");
                        recordingPlaybackStarter.start();
                    } else {
                        // If we've not got a lead-in, just start playback immediately
                        console.log("No lead-in, just starting playback");
                        Zynthian.CommonUtils.startMetronomeAndPlayback();
                    }
                    _private.isRecording = true;
                }
                function stopRecording() {
                    _private.isRecording = false;
                    _private.recordingProgress = -1;
                    // stop both the timers just in case
                    recordingPlaybackStarter.stop();
                    recordingStopper.stop();
                    // Actually stop recording
                    ZL.AudioLevels.stopRecording();
                    _private.isRecording = false;
                    if (ZynQuick.PlayGridManager.metronomeActive) {
                        // Stop the playback, again, in case this was called by someone else (like the close button)
                        Zynthian.CommonUtils.stopMetronomeAndPlayback();
                    }
                }
            }
            Timer {
                id: recordingPlaybackStarter
                repeat: false; running: false;
                interval: ZynQuick.PlayGridManager.syncTimer.subbeatCountToSeconds(zynthian.zynthiloops.song.bpm, _private.leadinDurationInTicks) * 1000
                onTriggered: {
                    console.log("Starting playback after", interval);
                    Zynthian.CommonUtils.startMetronomeAndPlayback();
                }
            }
            Timer {
                id: recordingStopper
                repeat: false; running: false;
                interval: ZynQuick.PlayGridManager.syncTimer.subbeatCountToSeconds(zynthian.zynthiloops.song.bpm, _private.fadeoutDurationInTicks) * 1000
                onTriggered: {
                    console.log("Stopping the recording after", interval);
                    _private.stopRecording();
                }
            }
            Connections {
                enabled: _private.isRecording
                target: ZynQuick.PlayGridManager
                onMetronomeBeat128thChanged: {
                    _private.cumulativeBeats = _private.cumulativeBeats + 1;
                    if (_private.songDurationInTicks > _private.cumulativeBeats) {
                        // set progress based on what the thing is actually doing
                        _private.recordingProgress = _private.cumulativeBeats/_private.songDurationInTicks;
                    } else if (_private.songDurationInTicks === _private.cumulativeBeats) {
                        // Stop all the playback
                        Zynthian.CommonUtils.stopMetronomeAndPlayback();
                        // Set progress back to 0, so we get a little spinny time while it fades out
                        _private.recordingProgress = 0;
                        if (_private.fadeoutDurationInTicks > 0) {
                            // If there is a fadeout duration, start the recording stopper timer
                            console.log("Starting the recording stopper");
                            recordingStopper.start();
                        } else {
                            console.log("No fade-out, stopping recording immediately");
                            // Otherwise, just stop recording now
                            _private.stopRecording();
                            // Close out and we're done
                            root.close();
                        }
                    } else {
                        if (ZynQuick.PlayGridManager.metronomeBeat128th > 0) {
                            // we're in fade-out, and for some reason we're still going...
                            console.log("Stopped playback already, but apparently we're still going?");
                        }
                    }
                }
            }
            Connections {
                target: component
                onOpenedChanged: {
                    if (!component.opened) {
                        _private.song = null;
                        for (var trackIndex = 0; trackIndex < 10; ++trackIndex) {
                            // Disable recording for all tracks, otherwise we'll just end up recording things when we don't want to
                            ZL.AudioLevels.setTrackToRecord(trackIndex, false);
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                QQC2.Label {
                    Layout.fillWidth: true
                    text: qsTr("Track:")
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    text: qsTr("Record:")
                }
            }
            Rectangle {
                Layout.fillHeight: true
                Layout.maximumWidth: 1
                color: Kirigami.Theme.textColor
                opacity: 0.3
            }
            Repeater {
                model: _private.song ? 10 : 0
                ColumnLayout {
                    id: trackDelegate
                    Layout.fillWidth: true
                    property int trackIndex: model.index
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: "T" + (trackDelegate.trackIndex + 1)
                        horizontalAlignment: Text.AlignHCenter
                    }
                    QQC2.CheckBox {
                        Layout.fillWidth: true
                        enabled: !_private.isRecording
                        checked: ZL.AudioLevels.tracksToRecord[trackDelegate.trackIndex]
                        onClicked: ZL.AudioLevels.setTrackToRecord(trackDelegate.trackIndex, !ZL.AudioLevels.tracksToRecord[trackDelegate.trackIndex])
                    }
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.maximumHeight: 1
            color: Kirigami.Theme.textColor
            opacity: 0.3
        }
        Kirigami.FormLayout {
            Layout.fillWidth: true
            QQC2.SpinBox{
                id: leadinSpin
                Layout.fillWidth: true
                Kirigami.FormData.label: qsTr("Lead-in in beats:")
                enabled: !_private.isRecording
                value: 4
                from: 0
                to: 128
            }
            QQC2.SpinBox{
                id: songDurationSpin
                Layout.fillWidth: true
                Kirigami.FormData.label: qsTr("Song length in beats (temporary measure, will be auto-determined later):")
                enabled: !_private.isRecording
                value: 32
                from: 0
                to: 32768
            }
            QQC2.SpinBox {
                id: fadeoutSpin
                Layout.fillWidth: true
                Kirigami.FormData.label: qsTr("Fade-out in beats:")
                enabled: !_private.isRecording
                value: 4
                from: 0
                to: 128
            }
        }
        QQC2.ProgressBar {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 30
            opacity: _private.recordingProgress > -1 ? 1 : 0.3
            value: _private.recordingProgress
        }
        RowLayout {
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            QQC2.Button {
                text: _private.isRecording ? qsTr("Stop Recording") : qsTr("Record Song")
                onClicked: {
                    if (_private.isRecording) {
                        _private.stopRecording();
                    } else {
                        _private.startRecording();
                    }
                }
            }
            QQC2.Button {
                text: qsTr("Close")
                enabled: !_private.isRecording
                onClicked: {
                    component.close();
                }
            }
        }
    }
}
