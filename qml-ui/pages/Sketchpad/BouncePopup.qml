/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian audio bounce popup control

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

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox
import Helpers 1.0 as Helpers

Zynthian.Popup {
    id: root
    function bounce(trackName, channel, partIndex) {
        _private.trackName = trackName;
        _private.selectedChannel = channel;
        _private.partIndex = partIndex;
        open();
    }

    parent: QQC2.Overlay.overlay
    y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
    x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
    closePolicy: _private.bounceProgress === -1 ? (QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside) : QQC2.Popup.NoAutoClose

    function cuiaCallback(cuia) {
        var returnValue = root.opened;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                root.close();
                returnValue = true;
                break;
        case "SWITCH_SELECT_SHORT":
            _private.performBounce();
            returnValue = true;
            break;
        }
        return returnValue;
    }

    ColumnLayout {
        implicitHeight: Kirigami.Units.gridUnit * 40
        implicitWidth: Kirigami.Units.gridUnit * 30
        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Bounce To Audio"
 
            QtObject {
                id: _private
                property string trackName
                property QtObject selectedChannel
                property int partIndex
                property double bounceProgress: -1

                property QtObject sequence: null
                property QtObject pattern: null
                property int previousSolo
                property int patternDurationInMS
                property int patternDurationInBeats
                property int recordingDurationInMS
                property int playbackStopDurationInMS
                property int recordingDurationInBeats
                property int playbackStopDurationInBeats
                property bool isRecording: false
                property int cumulativeBeats
                property int previouslySelectedSegmentsModel: -1
                property var filePropertiesHelper: Helpers.FilePropertiesHelper { }
                function performBounce() {
                    // Now everything is locked down, set up the temporary song that we'll be using to perform the playback
                    _private.sequence = Zynthbox.PlayGridManager.getSequenceModel(_private.trackName)
                    if (_private.sequence) {
                        _private.pattern = _private.sequence.getByPart(_private.selectedChannel.connectedPattern, _private.selectedChannel.selectedPart);
                        if (_private.pattern) {
                            _private.bounceProgress = 0;
                            console.log("Bouncing on channel with ID", _private.selectedChannel.id)
                            // Create a new song for us to use temporarily
                            _private.previouslySelectedSegmentsModel = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModelIndex;
                            let newSegmentsModelIndex = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.newSegmentsModel();
                            zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModelIndex = newSegmentsModelIndex;
                            // Assemble the duration of time we want to be recording for
                            var noteLengths = { 1: 32, 2: 16, 3: 8, 4: 4, 5: 2, 6: 1 }
                            var patternSubbeatToTickMultiplier = (Zynthbox.SyncTimer.getMultiplier() / 32);
                            _private.patternDurationInBeats = _private.pattern.width * _private.pattern.availableBars * noteLengths[_private.pattern.noteLength];
                            let patternDurationBar = Math.floor(_private.patternDurationInBeats / 128);
                            let patternDurationBeat = Math.floor((_private.patternDurationInBeats - (patternDurationBar * 128)) / 32);
                            let patternDurationTick =  (_private.patternDurationInBeats - (patternDurationBar * 128 + patternDurationBeat * 32)) * patternSubbeatToTickMultiplier;
                            let songDuration = _private.patternDurationInBeats * patternSubbeatToTickMultiplier;
                            // Set the length of the new sketch's default segment to the duration of the pattern to bounce, and set the segment to play that pattern
                            let segment = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.get_segment(0);
                            let sceneIndices = { "T1": 0, "T2": 1, "T3": 2, "T4": 3, "T5": 4, "T6": 5, "T7": 6, "T8": 7, "T9": 8, "T10": 9};
                            let clip = _private.selectedChannel.getClipsModelByPart(_private.partIndex).getClip(sceneIndices[_private.trackName]);
                            console.log("Adding the clip", clip, clip.col, clip.part, "to the first segment", segment);
                            segment.addClip(clip);
                            segment.barLength = patternDurationBar;
                            segment.beatLength = patternDurationBeat;
                            segment.tickLength = patternDurationTick;
                            if (_private.includeFadeout) {
                                // Add the fadeout to the song as an empty segment (of we have a fadeout) (after segment 0)
                                let segment = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.new_segment(1);
                                segment.barLength = patternDurationBar;
                                segment.beatLength = patternDurationBeat;
                                segment.tickLength = patternDurationTick;
                                songDuration = songDuration + _private.patternDurationInBeats * patternSubbeatToTickMultiplier;
                            }
                            if (_private.includeLeadin) {
                                // Add the leadin to the song as a segment, and set the segment to play that pattern (if we have a leadin) (as a new segment 0)
                                let segment = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.new_segment(0);
                                segment.barLength = patternDurationBar;
                                segment.beatLength = patternDurationBeat;
                                segment.tickLength = patternDurationTick;
                                segment.addClip(clip);
                                songDuration = songDuration + _private.patternDurationInBeats * patternSubbeatToTickMultiplier;
                            }
                            // Now we're ready to get under way, mark ourselves as very extremely busy
                            _private.isRecording = true;
                            // Set up to record (with a useful filename, and just the channel we want)
                            Zynthbox.AudioLevels.setChannelToRecord(_private.selectedChannel.id, true);
                            Zynthbox.AudioLevels.setChannelFilenamePrefix(_private.selectedChannel.id, zynqtgui.sketchpad.get_channel_recording_filename(_private.selectedChannel));
                            // Schedule us to start audio recording two ticks into the future
                            // Four ticks because we need to wait for...
                            // - the start command to be interpreted
                            // - song mode to set playback on for the first segment
                            // - the first events from that segment to be submitted for playback
                            // - the note actually hitting the synth and making noises
                            let waitForStart = 4;
                            Zynthbox.AudioLevels.scheduleStartRecording(waitForStart);
                            // Schedule us to start midi recording at the same point
                            Zynthbox.MidiRecorder.scheduleStartRecording(waitForStart, _private.selectedChannel.id);
                            // Schedule us to start playback one step back from the recordings (to allow playback to actually begin), in song mode, with no changes to start position and duration
                            Zynthbox.SyncTimer.scheduleStartPlayback(0, true, 0, 0)
                            // Schedule us to stop recording at the end of the song (duration)
                            console.log("Schedule stopping both midi and audio recordings in", songDuration + waitForStart, "ticks");
                            Zynthbox.AudioLevels.scheduleStopRecording(songDuration + waitForStart);
                            Zynthbox.MidiRecorder.scheduleStopRecording(songDuration + waitForStart, _private.selectedChannel.id);
                        }
                    }
                }
                property bool includeLeadin: false
                property bool includeLeadinInLoop: false
                property bool includeFadeout: false
                property bool includeFadeoutInLoop: false
            }
            Connections {
                target: Zynthbox.AudioLevels
                enabled: _private.isRecording
                onIsRecordingChanged: {
                    if (Zynthbox.AudioLevels.isRecording) {
                        endOfRecordingTimer.start();
                    }
                }
            }
            Timer {
                id: endOfRecordingTimer
                // enabled: _private.isRecording
                // target: Zynthbox.PlayGridManager
                property int totalDuration: zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count > 0 ? Zynthbox.PlayGridManager.syncTimer.getMultiplier() * zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.totalBeatDuration : 1
                interval: 50; repeat: true; running: false;
                onTriggered: {
                    // While recording, check each beat whether we have reached the end of playback, and once we have, and we are done recording and all that, pull things out and clean up
                    _private.bounceProgress = Math.min(1, Zynthbox.SegmentHandler.playhead / totalDuration);
                    if (Zynthbox.PlayGridManager.metronomeActive == false && Zynthbox.MidiRecorder.isRecording == false &&  Zynthbox.AudioLevels.isRecording == false) {
                        // Playback has stopped (we've reached the end of the song) - that means we should no longer be recording
                        _private.isRecording = false;
                        endOfRecordingTimer.stop();
                        // Save metadata into the newly created recordings
                        let recordingFilenames = Zynthbox.AudioLevels.recordingFilenames();
                        let filenameIndex = _private.selectedChannel.id + 2;
                        let filename = recordingFilenames[filenameIndex];
                        if (filename.length > 0) {
                            console.log("Successfully recorded a new sound file into", filename, "- now building metadata");
                            let metadata = {
                                "ZYNTHBOX_BPM": Zynthbox.SyncTimer.bpm
                            };
                            if (_private.selectedChannel) { // by all rights this should not be possible, but... best safe
                                metadata["ZYNTHBOX_ACTIVELAYER"] = _private.selectedChannel.getChannelSoundSnapshotJson(); // The layer setup which produced the sounds in this recording
                                metadata["ZYNTHBOX_AUDIO_TYPE"] = _private.selectedChannel.channelAudioType; // The audio type of this channel
                                if (_private.selectedChannel.channelAudioType === "sample-trig" || _private.selectedChannel.channelAudioType === "sample-slice") {
                                    // Store the sample data, if we've been playing in a patterny sample mode
                                    metadata["ZYNTHBOX_SAMPLES"] = _private.selectedChannel.getChannelSampleSnapshot(); // Store the samples that made this recording happen in a serialised fashion (similar to the base64 midi recording)
                                }
                            }
                            metadata["ZYNTHBOX_MIDI_RECORDING"] = Zynthbox.MidiRecorder.base64TrackMidi(filenameIndex - 2);
                            // Set up the loop points in the new recording
                            let noteLengths = { 1: 32, 2: 16, 3: 8, 4: 4, 5: 2, 6: 1 }
                            var patternSubbeatToTickMultiplier = (Zynthbox.SyncTimer.getMultiplier() / 32);
                            // Reset this to beats (rather than pattern subbeats)
                            let patternDurationInBeats = _private.pattern.width * _private.pattern.availableBars * noteLengths[_private.pattern.noteLength];
                            let patternDurationInMS = Zynthbox.SyncTimer.subbeatCountToSeconds(Zynthbox.SyncTimer.bpm, patternDurationInBeats * patternSubbeatToTickMultiplier) * 1000;
                            patternDurationInBeats = patternDurationInBeats / 32;
                            let startPosition = 0.0; // This is in seconds
                            let loopDelta = 0.0; // This is in beats (not pattern subbeats)
                            // TODO Loop point 2 would allow us to have a start-at-0, loop-from-first-round, loop-until-fadeout, stop-at-end option (for a very clean recording which does play-into-loop-with-fadeout for playback)
                            let loopDelta2 = 0.0; // This is in beats (not pattern subbeats) - relative to stop point, any position further back than loopDelta would be ignored
                            let playbackLength = patternDurationInBeats; // This is in beats (not pattern subbeats)
                            if (_private.includeLeadin) {
                                if (_private.includeLeadinInLoop) {
                                    // We have a leadin, that is included in the loop (not really a common case)
                                    playbackLength = playbackLength + patternDurationInBeats;
                                } else {
                                    // We have a lead-in, which is not included in the loop (so the loop start position is after the leadin)
                                    loopDelta = loopDelta + patternDurationInBeats;
                                }
                            }
                            if (_private.includeFadeout) {
                                if (_private.includeFadeoutInLoop) {
                                    // We have a fadeout, and we want it included in the loop
                                    playbackLength = playbackLength + patternDurationInBeats;
                                } else {
                                    // We have a fadeout, that we do not want included in the loop
                                    loopDelta2 = loopDelta2 + patternDurationInBeats;
                                    // Once we've got loopDelta2 implemented, uncomment this next line so we can have the tail
                                    // playbackLength = playbackLength + patternDurationInBeats;
                                }
                            }
                            metadata["ZYNTHBOX_STARTPOSITION"] = startPosition;
                            metadata["ZYNTHBOX_LENGTH"] = playbackLength;
                            metadata["ZYNTHBOX_LOOPDELTA"] = loopDelta;
                            metadata["ZYNTHBOX_LOOPDELTA2"] = loopDelta2;
                            // Snap length to beat size if our pattern will actually fit inside such a thing (otherwise don't do that)
                            metadata["ZYNTHBOX_SNAP_LENGTH_TO_BEAT"] = (Math.floor(playbackLength) === playbackLength);
                            // Actually write the metadata to the recording
                            _private.filePropertiesHelper.writeMetadata(filename, metadata);
                            console.log("Wrote metadata:", JSON.stringify(metadata));
                            console.log("New sample starts at", startPosition, "seconds, has a playback length of", playbackLength, "beats, with a pattern length of", patternDurationInMS, "ms and loop that starts at", loopDelta, "second loop point", loopDelta2, "beats back from the stop point, and a pattern length of", patternDurationInBeats, "beats");
                        } else {
                            console.log("Failed to get recording!");
                        }
                        // Set the newly recorded file as the current slot's loop clip
                        let sceneIndices = { "T1": 0, "T2": 1, "T3": 2, "T4": 3, "T5": 4, "T6": 5, "T7": 6, "T8": 7, "T9": 8, "T10": 9};
                        let clip = _private.selectedChannel.getClipsModelByPart(_private.partIndex).getClip(sceneIndices[_private.trackName]);
                        clip.set_path(filename, true);
                        console.log("...and the clip says it is", clip.duration, "seconds long");
                        // Set channel mode to loop
                        _private.selectedChannel.channelAudioType = "sample-loop";
                        // Clean up the temporary segments model
                        let ourSegmentsModel = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModelIndex;
                        zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModelIndex = _private.previouslySelectedSegmentsModel;
                        zynqtgui.sketchpad.song.sketchesModel.selectedSketch.removeSegmentsModel(ourSegmentsModel);
                        // Close out and we're done
                        root.close();
                        // Just reset back to -1 so we're ready to bounce again
                        _private.bounceProgress = -1;
                    }
                }
            }
            Connections {
                target: root
                onOpenedChanged: {
                    if (!root.opened) {
                        _private.includeLeadin = false;
                        _private.includeLeadinInLoop = false;
                        _private.includeFadeout = false;
                        _private.includeFadeoutInLoop = false;
                    }
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 1
            Layout.maximumHeight: 1
            color: Kirigami.Theme.textColor
            opacity: 0.5
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 30
            wrapMode: Text.Wrap
            text: "Bounce the audio from the pattern in " + (_private.selectedChannel ? _private.selectedChannel.name : "") + " to a wave file, assign that recording as the channel's loop sample, and set the channel to loop mode.";
        }
        QQC2.CheckBox {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Include lead-in"
            checked: _private.includeLeadin
            onClicked: { _private.includeLeadin = !_private.includeLeadin; }
        }
        QQC2.CheckBox {
            Layout.fillWidth: true
            Layout.fillHeight: true
            enabled: _private.includeLeadin
            opacity: enabled ? 1 : 0.5
            text: "Include lead-in in loop"
            checked: _private.includeLeadinInLoop
            onClicked: { _private.includeLeadinInLoop = !_private.includeLeadinInLoop; }
        }
        QQC2.CheckBox {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Include fade-out"
            checked: _private.includeFadeout
            onClicked: { _private.includeFadeout = !_private.includeFadeout; }
        }
        QQC2.CheckBox {
            Layout.fillWidth: true
            Layout.fillHeight: true
            enabled: _private.includeFadeout
            opacity: enabled ? 1 : 0.5
            text: "Include fade-out in loop"
            checked: _private.includeFadeoutInLoop
            onClicked: { _private.includeFadeoutInLoop = !_private.includeFadeoutInLoop; }
        }
        QQC2.ProgressBar {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 30
            opacity: _private.bounceProgress > -1 ? 1 : 0.3
            value: _private.bounceProgress
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 1
            Layout.maximumHeight: 1
            color: Kirigami.Theme.textColor
            opacity: 0.5
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                text: "Close"
                enabled: _private.bounceProgress === -1
                onClicked: {
                    root.close();
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                text: "Bounce"
                enabled: _private.bounceProgress === -1
                onClicked: {
                    _private.performBounce();
                }
            }
        }
    }
}
