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
    function bounce(trackName, channel, clipIndex) {
        _private.trackName = trackName;
        if (channel === null) {
            _private.selectedChannel = zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId);
        } else {
            _private.selectedChannel = channel;
        }
        _private.selectedClipIndex = clipIndex;
        if (_private.selectedClipIndex > -1) {
            _private.bounceLevel = 2;
        } else {
            _private.selectedClipIndex = _private.selectedChannel.selectedClip;
            _private.bounceLevel = 1;
        }
        _private.sequence = Zynthbox.PlayGridManager.getSequenceModel(_private.trackName);
        _private.checkCanBounceTimer.restart();
        open();
    }

    parent: QQC2.Overlay.overlay
    height: Kirigami.Units.gridUnit * 25
    y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
    x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
    closePolicy: _private.bounceProgress === -1 ? (QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside) : QQC2.Popup.NoAutoClose

    function cuiaCallback(cuia) {
        var returnValue = root.opened;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
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

    contentItem: ColumnLayout {
        anchors.fill: parent
        implicitHeight: Kirigami.Units.gridUnit * 25
        implicitWidth: Kirigami.Units.gridUnit * 30
        Kirigami.Heading {
            Layout.fillWidth: true
            text: qsTr("Bounce To Sketch")
 
            QtObject {
                id: _private
                property string trackName
                property QtObject selectedChannel
                property int selectedClipIndex
                property double bounceProgress: -1

                property QtObject sequence: null
                property QtObject pattern: null

                property bool canBounce: false
                property string cannotBounceReason: ""
                onBounceLevelChanged: {
                    checkCanBounceTimer.restart();
                }
                property QtObject checkCanBounceTimer: Timer {
                    interval: 50; running: false; repeat: false;
                    onTriggered: {
                        if (_private.bounceLevel === 2) {
                            let pattern = _private.sequence.getByClipId(_private.selectedChannel.id, _private.selectedClipIndex);
                            if (pattern.hasNotes) {
                                checkSketchpadTrackSounds(_private.selectedChannel);
                            } else {
                                _private.canBounce = false;
                                _private.cannotBounceReason = qsTr("There are no notes in this clip's pattern, so there is nothing to bounce.");
                            }
                        } else if (_private.bounceLevel === 1) {
                            let atLeastOnePatternHasNotes = false;
                            for (let clipIndex = 0; clipIndex < Zynthbox.Plugin.sketchpadSlotCount; ++clipIndex) {
                                let pattern = _private.sequence.getByClipId(_private.selectedChannel.id, clipIndex);
                                if (pattern.hasNotes) {
                                    atLeastOnePatternHasNotes = true;
                                    break;
                                }
                            }
                            if (atLeastOnePatternHasNotes) {
                                checkSketchpadTrackSounds(_private.selectedChannel);
                            } else {
                                _private.canBounce = false;
                                _private.cannotBounceReason = qsTr("There are no notes in any of this track's patterns, so there is nothing to bounce.");
                            }
                        } else {
                            let atLeastOneTrackCanBounce = false;
                            for (let trackIndex = 0; trackIndex < 10; ++trackIndex) {
                                let sketchpadTrack = zynqtgui.sketchpad.song.channelsModel.getChannel(trackIndex);
                                let atLeastOnePatternHasNotes = false;
                                for (let clipIndex = 0; clipIndex < Zynthbox.Plugin.sketchpadSlotCount; ++clipIndex) {
                                    let pattern = _private.sequence.getByClipId(trackIndex, clipIndex);
                                    if (pattern.hasNotes) {
                                        atLeastOnePatternHasNotes = true;
                                        break;
                                    }
                                }
                                if (atLeastOnePatternHasNotes) {
                                    checkSketchpadTrackSounds(sketchpadTrack);
                                    if (_private.canBounce) {
                                        // At least one thing can be bounced, so pop out now
                                        atLeastOneTrackCanBounce = true;
                                        break;
                                    }
                                }
                            }
                            if (atLeastOneTrackCanBounce) {
                                _private.canBounce = true;
                            } else {
                                _private.canBounce = false;
                                _private.cannotBounceReason = qsTr("There is nothing in this sketchpad that needs bouncing. To be able to bounce, you will need to add notes to the patterns on tracks which have sounds defined (either synths, samples, or controlling and capturing an external device).");
                            }
                        }
                    }
                    function checkSketchpadTrackSounds(sketchpadTrack) {
                        if (sketchpadTrack.trackType === "synth") {
                            let hasSound = false;
                            for (let soundIndex = 0; soundIndex < sketchpadTrack.chainedSounds.length; ++soundIndex) {
                                if (sketchpadTrack.chainedSounds[soundIndex] > -1) {
                                    hasSound = true;
                                    break;
                                }
                            }
                            if (hasSound) {
                                _private.canBounce = true;
                            } else {
                                _private.canBounce = false;
                                for (var sampleIndex = 0; sampleIndex < 5; ++sampleIndex) {
                                    if (sketchpadTrack.samples[sampleIndex].cppObjId > -1) {
                                        hasSound = true;
                                        break;
                                    }
                                }
                                if (hasSound) {
                                    _private.canBounce = true;
                                } else {
                                    _private.canBounce = false;
                                    _private.cannotBounceReason = qsTr("There are no sounds on this track for yout clips to play to.");
                                }
                            }
                        } else if (sketchpadTrack.trackType === "sample-loop") {
                            _private.canBounce = false;
                            _private.cannotBounceReason = qsTr("This track is already a sketch, so it cannot be bounced further.");
                        } else if (sketchpadTrack.trackType === "external") {
                            if (sketchpadTrack.externalAudioSource.length > 0) {
                                _private.canBounce = true;
                            } else {
                                _private.canBounce = false;
                                _private.cannotBounceReason = qsTr("This track is set to control an external device, but is not set to capture any incoming audio, so there is no way we can bounce things.");
                            }
                        }
                    }
                }

                property bool isRecording: false
                property int cumulativeBeats
                // bounce levels: 0 for bouncing everything, 1 to bounce current track, 2 to bounce current track's current clip
                property int bounceLevel: 1
                property int previouslySelectedSegmentsModel: -1
                property var filePropertiesHelper: Helpers.FilePropertiesHelper { }
                property var clipDetails: []
                property var clipNames: ["a", "b", "c", "d", "e"];
                function performBounce() {
                    // Now everything is locked down, set up the temporary song that we'll be using to perform the playback
                    if (_private.sequence) {
                        // Logic for full-sketchpadTrack/full-sketchpad bouncing:
                        // - Go through all sketchpad tracks (if there is not one selected, otherwise just that one)
                        // - Go through all clips on each track (if there is not one selected, otherwise just that one)
                        // - Create information required to bounce each of these clips and add them to a list (clipDetails), except where the patterns have no notes defined (sorry to those intending to re-create 4'33'')
                        // - Create a new segments model (remembering what the previously selected one was, so we can restore that later)
                        // - Create a segment for each of the clips we built information for earlier, using segment_model's insert_clip and ensure_position functions
                        // - Using SyncTimer's time command bundling functionality
                        //   - add recording start and stop commands to the timer, according to the information built above
                        //   - also add an "all sound off" midi message at the same position as any recording-stop, to avoid any long tails bleeding into the next recording
                        // - Bounce progress done vya playback progress of the temporary "song"
                        // - Only do metadata writing once all recording is completed, to avoid unnecessary overhead (add in a "finishing up" message to tell the user about this, too)
                        let patternSubbeatToTickMultiplier = (Zynthbox.SyncTimer.getMultiplier() / 32);
                        let sceneIndices = { "T1": 0, "T2": 1, "T3": 2, "T4": 3, "T5": 4, "T6": 5, "T7": 6, "T8": 7, "T9": 8, "T10": 9};

                        // Put all of the clips we want to perform a bounce on into a big list
                        let sketchpadTracksToBounce = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
                        if (_private.bounceLevel > 0) {
                            sketchpadTracksToBounce = [_private.selectedChannel.id];
                        }
                        let clipsToBounce = [0, 1, 2, 3, 4];
                        if (_private.bounceLevel == 2) {
                            clipsToBounce = [_private.selectedClipIndex];
                        }
                        _private.clipDetails = [];
                        for (let sketchpadTrackIndex = 0; sketchpadTrackIndex < sketchpadTracksToBounce.length; ++sketchpadTrackIndex) {
                            let sketchpadTrackId = sketchpadTracksToBounce[sketchpadTrackIndex];
                            let sketchpadTrack = zynqtgui.sketchpad.song.channelsModel.getChannel(sketchpadTrackId);
                            if (sketchpadTrack.trackType === "synth" || (sketchpadTrack.trackType === "external" && sketchpadTrack.externalAudioSource.length > 0)) {
                                let soundIndication = "(unknown)";
                                if (sketchpadTrack.trackType === "synth") {
                                    for (var soundIndex = 0; soundIndex < 5; ++soundIndex) {
                                        if (sketchpadTrack.chainedSounds[soundIndex] > -1) {
                                            soundIndication = sketchpadTrack.connectedSoundName.replace(/([^a-z0-9]+)/gi, '-');
                                            break;
                                        }
                                    }
                                    if (soundIndication === "(unknown)") {
                                        for (var sampleIndex = 0; sampleIndex < 5; ++sampleIndex) {
                                            var clip = sketchpadTrack.samples[sampleIndex];
                                            if (clip.cppObjId > -1) {
                                                // We pick the name of whatever the first sample is here, just so we've got one
                                                soundIndication = clip.path.split("/").pop();
                                                soundIndication = soundIndication.substring(0, soundIndication.lastIndexOf("."));
                                                if (soundIndication.endsWith(".clip")) {
                                                    soundIndication = soundIndication.substring(0, soundIndication.length - 5);
                                                } else if (soundIndication.endsWith(".sketch")) {
                                                    soundIndication = soundIndication.substring(0, soundIndication.length - 7);
                                                }
                                                break;
                                            }
                                        }
                                    }
                                } else if (sketchpadTrack.trackType === "sample-loop") {
                                    for (var loopIndex = 0; loopIndex < Zynthbox.Plugin.sketchpadSlotCount; ++loopIndex) {
                                        var clip = sketchpadTrack.getClipsModelById(loopIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                                        if (clip.cppObjId > -1) {
                                            // We pick the name of whatever the first loop is here, just so we've got one
                                            soundIndication = clip.path.split("/").pop();
                                            soundIndication = soundIndication.substring(0, soundIndication.lastIndexOf("."));
                                            if (soundIndication.endsWith(".clip")) {
                                                soundIndication = soundIndication.substring(0, soundIndication.length - 5);
                                            } else if (soundIndication.endsWith(".sketch")) {
                                                soundIndication = soundIndication.substring(0, soundIndication.length - 7);
                                            }
                                            break;
                                        }
                                    }
                                } else {
                                    soundIndication = "external";
                                }
                                let previousStopRecordingPosition = 0;
                                for (let clipIndex = 0; clipIndex < clipsToBounce.length; ++clipIndex) {
                                    let pattern = _private.sequence.getByClipId(sketchpadTrackId, clipsToBounce[clipIndex]);
                                    if (pattern.hasNotes) {
                                        let patternDurationInPatternSubbeats = (pattern.patternLength * pattern.stepLength) / patternSubbeatToTickMultiplier;
                                        let patternRepeatCount = _private.patternRepeatCount; // How long are the tails expected (we just start with 1 here, until we work out how to properly expose this)
                                        let includeLeadin = _private.includeLeadin ? 1 : 0;
                                        let includeMainLoop = 1; // The main part can't be disabled anyway, so this is just a 1
                                        let includeFadeout = _private.includeFadeout ? 1 : 0;
                                        let recordingPrefix = zynqtgui.sketchpad.song.sketchpadFolder + "wav/clip" + (sketchpadTrackId + 1) + _private.clipNames[clipIndex];
                                        let recordingSuffix = "-" + soundIndication + ".sketch.wav";
                                        let theDetails = {
                                            "startPosition": previousStopRecordingPosition,
                                            "stopPlaybackPosition": previousStopRecordingPosition + (patternSubbeatToTickMultiplier * patternDurationInPatternSubbeats * patternRepeatCount * (includeLeadin + includeMainLoop)),
                                            "stopRecordingPosition": previousStopRecordingPosition + (patternSubbeatToTickMultiplier * patternDurationInPatternSubbeats * patternRepeatCount * (includeLeadin + includeMainLoop + includeFadeout)),
                                            "pattern": pattern,
                                            "sketchpadTrackId": sketchpadTrackId,
                                            "clipId": clipsToBounce[clipIndex],
                                            "sceneId": sceneIndices[_private.trackName],
                                            "trackType": sketchpadTrack.trackType,
                                            "recordingPrefix": recordingPrefix,
                                            "recordingSuffix": recordingSuffix,
                                            "recordingFilename": Zynthbox.AudioLevels.getTimestampedFilename(recordingPrefix, recordingSuffix)
                                        };
                                        _private.clipDetails.push(theDetails);
                                        previousStopRecordingPosition = theDetails["stopRecordingPosition"];
                                    }
                                }
                            }
                        }
                        if (_private.clipDetails.length > 0) {
                            // About to actually set off, so mark ourselves as extremely busy
                            _private.isRecording = true;
                            _private.bounceProgress = 0;
                            // Turn off all recording that might have been set up already (there shouldn't be any, but...)
                            for (let trackIndex = 0; trackIndex < 10; ++trackIndex) {
                                Zynthbox.AudioLevels.setChannelToRecord(trackIndex, false);
                            }
                            Zynthbox.AudioLevels.setRecordGlobalPlayback(false);
                            Zynthbox.AudioLevels.setShouldRecordPorts(false);
                            // Don't wait to schedule the start of recording into the future
                            // It used to be the case we needed to wait for playback to start and events being delivered for the first step, but that is no longer the case
                            // Leaving the variable here in case we need it later, and it causes no trouble, but if things just keep working as expected, it'd probably be
                            // worth just getting rid of it at some point.
                            let waitForStart = 0;
                            // Iterate over all the selected clips, and use segment_model's ability to just throw clips at it
                            // and ensure their positions exist across the entire given range to add the clips where they
                            // should go in the song
                            // Create a new song for us to use temporarily
                            _private.previouslySelectedSegmentsModel = zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModelIndex;
                            let newSegmentsModelIndex = zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.newSegmentsModel();
                            zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModelIndex = newSegmentsModelIndex;
                            for (let clipDetailsIndex = 0; clipDetailsIndex < _private.clipDetails.length; ++clipDetailsIndex) {
                                let details = _private.clipDetails[clipDetailsIndex];
                                let clip = zynqtgui.sketchpad.song.getClipById(details["sketchpadTrackId"], details["sceneId"], details["clipId"]);
                                // Add the clip itself
                                zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.insert_clip(clip, details["startPosition"] / Zynthbox.SyncTimer.getMultiplier(), details["stopPlaybackPosition"] / Zynthbox.SyncTimer.getMultiplier());
                                // Now just make sure there's also a matching position to keep playing and then stop the recording
                                let firstSegmentIndex = zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.ensure_split(details["startPosition"] / Zynthbox.SyncTimer.getMultiplier()) + 1;
                                let lastSegmentIndex = zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.ensure_split(details["stopRecordingPosition"] / Zynthbox.SyncTimer.getMultiplier());
                                // Pull out the two segments and plop commands into them...
                                // For the first segment, start the recording at the same time as the first segment begins
                                let firstSegment = zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.get_segment(firstSegmentIndex);
                                let startRecordingCommand = { "operation": 20, "parameter": 1, "parameter2": details["sketchpadTrackId"], "variantParameter": details["recordingFilename"] };
                                firstSegment.addTimerCommandBefore(startRecordingCommand);
                                // For the last segment, stop the recording and output stop-all-sounds on the track as that segment ends
                                let lastSegment = zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.get_segment(lastSegmentIndex);
                                let stopRecordingCommand = { "operation": 21, "parameter": 1, "parameter2": details["sketchpadTrackId"] };
                                lastSegment.addTimerCommandAfter(stopRecordingCommand);
                                // Ensure we're outputting a stop-all-sounds message on the track as well, so we can be sure that there's no long tails sneaking into the next recording on that track
                                for (let midichannel = 0; midichannel < 16; ++midichannel) {
                                    // Post timer commands for all these at the end of the last segment
                                    // Zynthbox.SyncTimer.scheduleTimerCommand(details["stopRecordingPosition"], 100, details["sketchpadTrackId"], 176 + midichannel, 120, undefined, -1);
                                    let stopNotesMessage = { "operation": 100, "parameter": details["sketchpadTrackId"], "parameter2": 176 + midichannel, "parameter3": 120, "parameter4": 0 };
                                    lastSegment.addTimerCommandAfter(stopNotesMessage);
                                }
                                console.log("Start", details["startPosition"], "stop playback", details["stopPlaybackPosition"], "stop recording", details["stopRecordingPosition"], "for file", details["recordingFilename"]);
                            }
                            // Schedule us to start playback one step back from the recordings (to allow playback to actually begin), in song mode, with no changes to start position and duration
                            Zynthbox.SyncTimer.scheduleStartPlayback(0, true, 0, 0)
                        } else {
                            console.log("Oh dear, there are no clips to bounce, so... no bouncing for you!");
                            // message box out that there's nothing to do like whaaaat?!
                            // e.g. "The options you have selected have resulted in there being nothing to bounce."
                            //FIXME Also we should endeavour to not end up here, really, just not let people push the bounce button if there's nothing to do (how do we reasonably do that without it getting expensive?)
                        }
                    }
                }
                property bool includeLeadin: true
                property bool includeLeadinInLoop: false
                property bool includeFadeout: true
                property bool includeFadeoutInLoop: false
                property int patternRepeatCount: 1
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
                property int totalDuration: zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.count > 0 ? Zynthbox.SyncTimer.getMultiplier() * zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.totalBeatDuration : 1
                interval: 50; repeat: true; running: false;
                onTriggered: {
                    // While recording, check each beat whether we have reached the end of playback, and once we have, and we are done recording and all that, pull things out and clean up
                    if (Zynthbox.PlayGridManager.metronomeActive == true) {
                        _private.bounceProgress = Math.min(1, Zynthbox.SegmentHandler.playhead / totalDuration);
                    } else if (Zynthbox.AudioLevels.isRecording == false) {
                        // Playback has stopped (we've reached the end of the song) - that means we should no longer be recording
                        _private.isRecording = false;
                        _private.bounceProgress = 1;
                        endOfRecordingTimer.stop();
                        // Save metadata into the newly created recordings
                        for (let clipDetailsIndex = 0; clipDetailsIndex < _private.clipDetails.length; ++clipDetailsIndex) {
                            let details = _private.clipDetails[clipDetailsIndex];
                            let filename = details["recordingFilename"];
                            console.log("Successfully recorded a new sound file into", filename, "- now building metadata");
                            let sketchpadTrack = zynqtgui.sketchpad.song.channelsModel.getChannel(details["sketchpadTrackId"]);
                            let pattern = details["pattern"];
                            var patternSubbeatToTickMultiplier = (Zynthbox.SyncTimer.getMultiplier() / 32);
                            let patternDurationInBeats = _private.patternRepeatCount * (pattern.patternLength * pattern.stepLength) / patternSubbeatToTickMultiplier;
                            let patternDurationInSeconds = Zynthbox.SyncTimer.subbeatCountToSeconds(Zynthbox.SyncTimer.bpm, patternDurationInBeats * patternSubbeatToTickMultiplier);
                            // Reset this to beats (rather than pattern subbeats)
                            patternDurationInBeats = patternDurationInBeats / 32;
                            // Set up the loop points in the new recording
                            let startPosition = 0.0; // This is in seconds
                            let loopDelta = 0.0; // This is in seconds
                            // TODO Loop point 2 would allow us to have a start-at-0, loop-from-first-round, loop-until-fadeout, stop-at-end option (for a very clean recording which does play-into-loop-with-fadeout for playback)
                            let loopDelta2 = 0.0; // This is in seconds - relative to stop point, any position further back than loopDelta would be ignored
                            let playbackLength = patternDurationInBeats; // This is in beats (not pattern subbeats)
                            if (_private.includeLeadin) {
                                // We start playback at the start of the recording, so we need to increase the playback duration to include both the main recording, and the leadin
                                playbackLength = playbackLength + patternDurationInBeats;
                                if (_private.includeLeadinInLoop) {
                                    // We have a leadin, that is included in the loop (not really a common case)
                                } else {
                                    // We have a lead-in, which is not included in the loop (so the loop start position is after the leadin)
                                    loopDelta = loopDelta + patternDurationInSeconds;
                                }
                            }
                            if (_private.includeFadeout) {
                                if (_private.includeFadeoutInLoop) {
                                    // We have a fadeout, and we want it included in the loop
                                    playbackLength = playbackLength + patternDurationInBeats;
                                } else {
                                    // We have a fadeout, that we do not want included in the loop
                                    loopDelta2 = loopDelta2 + patternDurationInSeconds;
                                    // Once we've got loopDelta2 implemented, uncomment this next line so we can have the tail
                                    // playbackLength = playbackLength + patternDurationInBeats;
                                }
                            }
                            // Set channel mode to loop
                            sketchpadTrack.trackType = "sample-loop";
                            console.log("New sample starts at", startPosition, "seconds, has a playback length of", playbackLength, "beats, with a pattern length of", patternDurationInSeconds, "s and loop that starts at", loopDelta, "seconds, second loop point", loopDelta2, "seconds back from the stop point, and a pattern length of", patternDurationInBeats, "beats");
                            // Set the newly recorded file as the current slot's loop clip
                            let sceneIndices = { "T1": 0, "T2": 1, "T3": 2, "T4": 3, "T5": 4, "T6": 5, "T7": 6, "T8": 7, "T9": 8, "T10": 9};
                            let clip = sketchpadTrack.getClipsModelById(details["clipId"]).getClip(details["sceneId"]);
                            clip.set_path(filename, false);
                            // Generate the initial metadata for the clip
                            clip.metadata.writeMetadataWithSoundData()
                            // The track type will be incorrect (as it will generate to whatever is currently true for the clip's track)
                            clip.metadata.audioType = details["trackType"];
                            // Set the loop points
                            let cppClipObj = Zynthbox.PlayGridManager.getClipById(clip.cppObjId);
                            cppClipObj.selectedSliceObject.startPositionSeconds = startPosition;
                            cppClipObj.selectedSliceObject.lengthBeats = playbackLength;
                            cppClipObj.selectedSliceObject.loopDeltaSeconds = loopDelta;
                            cppClipObj.selectedSliceObject.loopDelta2Seconds = loopDelta2;
                            // Make sure sketches timestretch in a high quality fashion by default
                            cppClipObj.selectedSliceObject.timeStretchStyle = Zynthbox.ClipAudioSource.TimeStretchBetter;
                            // Snap length to beat size if our pattern will actually fit inside such a thing (otherwise don't do that)
                            clip.metadata.snapLengthToBeat = (Math.floor(playbackLength) === playbackLength);
                            console.log("...and the clip says it is", cppClipObj.durationSeconds, "seconds long");
                        }

                        // Clean up the temporary segments model
                        let ourSegmentsModel = zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModelIndex;
                        zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModelIndex = _private.previouslySelectedSegmentsModel;
                        zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.removeSegmentsModel(ourSegmentsModel);
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
                        _private.includeLeadin = true;
                        _private.includeLeadinInLoop = false;
                        _private.includeFadeout = true;
                        _private.includeFadeoutInLoop = false;
                        _private.patternRepeatCount = 1;
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
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit / 2
            Zynthian.PlayGridButton {
                Layout.preferredWidth: Kirigami.Units.gridUnit
                enabled: _private.bounceProgress === -1
                checked: _private.bounceLevel === 0
                text: qsTr("Bounce Sketchpad")
                onClicked: {
                    _private.bounceLevel = 0;
                }
            }
            Zynthian.PlayGridButton {
                Layout.preferredWidth: Kirigami.Units.gridUnit
                enabled: _private.bounceProgress === -1
                checked: _private.bounceLevel === 1
                text: qsTr("Bounce Track")
                onClicked: {
                    _private.bounceLevel = 1;
                }
            }
            Zynthian.PlayGridButton {
                Layout.preferredWidth: Kirigami.Units.gridUnit
                enabled: _private.bounceProgress === -1
                checked: _private.bounceLevel === 2
                text: qsTr("Bounce Clip")
                onClicked: {
                    _private.bounceLevel = 2;
                }
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
            Layout.preferredWidth: Kirigami.Units.gridUnit * 30
            wrapMode: Text.Wrap
            verticalAlignment: Text.AlignTop
            text: _private.canBounce
                    ? _private.bounceLevel === 0
                        ? qsTr("Bounce the audio of all clips on all tracks which have something to bounce to sketches, put those bounced sketches into their equivalent clips, and set all the tracks that had things to bounce to Sketch mode.")
                        : _private.bounceLevel === 1
                            ? qsTr("Bounce the audio from all clips on track %1 to sketches, and assign those recordings as the sketches in their equivalent clips, and sets the track to Sketch mode.").arg(_private.selectedChannel ? _private.selectedChannel.name : "")
                            : qsTr("Bounce the audio from clip %1 on track %2 to a sketch, then put the bounced sketch into the equivalent sketch slot, and set the track to Sketch mode. Remember to bounce the rest of the clips if you want to keep those.").arg(_private.selectedClipIndex > -1 ? _private.clipNames[_private.selectedClipIndex] : "").arg(_private.selectedChannel ? _private.selectedChannel.name : "")
                    : _private.cannotBounceReason
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit
            Layout.preferredWidth: Kirigami.Units.gridUnit * 30
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: qsTr("To ensure your bounce handles long note sustains, you can increase the number of times the pattern is repeated for each of the loop sections here:")
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 30
                Layout.maximumHeight: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Kirigami.Units.gridUnit
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                Zynthian.PlayGridButton {
                    Layout.fillHeight: true
                    Layout.fillWidth: false
                    Layout.minimumWidth: Kirigami.Units.iconSizes.large
                    Layout.maximumWidth: Kirigami.Units.iconSizes.large
                    icon.name: "list-remove-symbolic"
                    enabled: _private.patternRepeatCount > 1
                    onClicked: {
                        _private.patternRepeatCount = _private.patternRepeatCount - 1;
                    }
                }
                QQC2.Label {
                    Layout.fillHeight: true
                    text: qsTr("Repeat pattern %1 times").arg(_private.patternRepeatCount)
                }
                Zynthian.PlayGridButton {
                    Layout.fillHeight: true
                    Layout.fillWidth: false
                    Layout.minimumWidth: Kirigami.Units.iconSizes.large
                    Layout.maximumWidth: Kirigami.Units.iconSizes.large
                    icon.name: "list-add-symbolic"
                    onClicked: {
                        _private.patternRepeatCount = _private.patternRepeatCount + 1;
                    }
                }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Kirigami.Units.gridUnit
            columns: 3
            Zynthian.PlayGridButton {
                Layout.preferredWidth: Kirigami.Units.gridUnit
                enabled: _private.bounceProgress === -1
                checked: _private.includeLeadin
                text: "Record Lead-in"
                onClicked: {
                    _private.includeLeadin = !_private.includeLeadin;
                }
            }
            Rectangle {
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                Layout.fillHeight: true
                QQC2.Label {
                    anchors.centerIn: parent
                    text: "Main Recording"
                }
                color: Kirigami.Theme.highlightColor
                border {
                    width: 1
                    color: Kirigami.Theme.textColor
                }
            }
            Zynthian.PlayGridButton {
                Layout.preferredWidth: Kirigami.Units.gridUnit
                enabled: _private.bounceProgress === -1
                checked: _private.includeFadeout
                text: "Record Fade-out"
                onClicked: {
                    _private.includeFadeout = !_private.includeFadeout;
                }
            }
            Zynthian.PlayGridButton {
                Layout.preferredWidth: Kirigami.Units.gridUnit
                checked: _private.includeLeadinInLoop
                enabled: _private.bounceProgress === -1 && _private.includeLeadin
                opacity: enabled ? 1 : 0.5
                text: "Include in loop"
                onClicked: {
                    _private.includeLeadinInLoop = !_private.includeLeadinInLoop;
                }
            }
            Rectangle {
                Layout.preferredWidth: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                Layout.fillHeight: true
                QQC2.Label {
                    anchors.centerIn: parent
                    text: "Main Loop"
                }
                color: Kirigami.Theme.highlightColor
                border {
                    width: 1
                    color: Kirigami.Theme.textColor
                }
            }
            Zynthian.PlayGridButton {
                Layout.preferredWidth: Kirigami.Units.gridUnit
                checked: _private.includeFadeoutInLoop
                enabled: _private.bounceProgress === -1 && _private.includeFadeout
                opacity: enabled ? 1 : 0.5
                text: "Include in loop"
                onClicked: {
                    _private.includeFadeoutInLoop = !_private.includeFadeoutInLoop;
                }
            }
        }
        QQC2.ProgressBar {
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 30
            opacity: _private.bounceProgress > -1 ? 1 : 0.3
            value: _private.bounceProgress
        }
        QQC2.Label {
            Layout.fillWidth: true
            visible: _private.bounceProgress === 1 ? 1 : 0
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Please wait, finishing up...");
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
                enabled: _private.canBounce && _private.bounceProgress === -1
                onClicked: {
                    _private.performBounce();
                }
            }
        }
    }
}
