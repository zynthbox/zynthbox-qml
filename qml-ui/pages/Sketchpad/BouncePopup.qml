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
import org.zynthian.quick 1.0 as ZynQuick

QQC2.Popup {
    id: root
    function bounce(sketchName, channel) {
        _private.sketchName = sketchName;
        _private.selectedChannel = channel;
        open();
    }

    exit: null; enter: null; // Disable the enter and exit transition animations. TODO This really wants doing somewhere central...
    modal: true
    focus: true
    parent: QQC2.Overlay.overlay
    y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
    x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
    closePolicy: _private.bounceProgress === -1 ? (QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside) : QQC2.Popup.NoAutoClose

    function cuiaCallback(cuia) {
        var returnValue = false;
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
            text: "Bounce To Loop"
 
            QtObject {
                id: _private
                property string sketchName
                property QtObject selectedChannel
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
                function performBounce() {
                    _private.bounceProgress = 0;
                    // Now everything is locked down, set up the sequence to do stuff for us (and store a few things so we can revert it as well)
                    _private.sequence = ZynQuick.PlayGridManager.getSequenceModel(_private.sketchName);
                    if (_private.sequence) {
                        _private.pattern = sequence.getByPart(_private.selectedChannel.connectedPattern, _private.selectedChannel.selectedPart);
                        if (_private.pattern) {
                            // If there's currently a pattern set to be solo, let's remember that
                            _private.previousSolo = _private.sequence.soloPattern;
                            // Now, set the pattern we're wanting to record as solo
                            _private.sequence.soloPattern = _private.selectedChannel.connectedPattern;
                            // Assemble the duration of time we want to be recording for
                            var noteLengths = { 1: 32, 2: 16, 3: 8, 4: 4, 5: 2, 6: 1 }
                            _private.patternDurationInBeats = _private.pattern.width * _private.pattern.availableBars * noteLengths[_private.pattern.noteLength];
                            var beatMultiplier = ZynQuick.PlayGridManager.syncTimer.getMultiplier();
                            var beatsPerMinute = zynthian.sketchpad.song.bpm;
                            _private.patternDurationInMS = ZynQuick.PlayGridManager.syncTimer.subbeatCountToSeconds(beatsPerMinute, _private.patternDurationInBeats) * 1000;
                            _private.recordingDurationInMS = _private.patternDurationInMS;
                            _private.recordingDurationInBeats = _private.patternDurationInBeats;
                            if (_private.includeLeadin) {
                                _private.recordingDurationInMS = _private.recordingDurationInMS + patternDurationInMS;
                                _private.recordingDurationInBeats = _private.recordingDurationInBeats + _private.patternDurationInBeats;
                            }
                            if (_private.selectedChannel.channelAudioType === "synth") {
                                _private.playbackStopDurationInBeats = _private.recordingDurationInBeats - ZynQuick.PlayGridManager.syncTimer.scheduleAheadAmount;
                                //_private.playbackStopDurationInMS = _private.recordingDurationInMS - (ZynQuick.PlayGridManager.syncTimer.subbeatCountToSeconds(beatsPerMinute, ZynQuick.PlayGridManager.syncTimer.scheduleAheadAmount) * 1000);
                                _private.playbackStopDurationInMS = _private.recordingDurationInMS - (ZynQuick.PlayGridManager.syncTimer.subbeatCountToSeconds(beatsPerMinute, 6) * 1000);
                            } else {
                                _private.playbackStopDurationInBeats = _private.recordingDurationInBeats;
                                _private.playbackStopDurationInMS = _private.recordingDurationInMS;
                            }
                            if (_private.includeFadeout) {
                                _private.recordingDurationInBeats = _private.recordingDurationInBeats + _private.patternDurationInBeats;
                                _private.recordingDurationInMS = _private.recordingDurationInMS + patternDurationInMS;
                            }
                            // Startrecordingandplaythethingletsgo!
                            _private.cumulativeBeats = 0;
                            _private.isRecording = true;
                            var sceneIndices = { "S1": 0, "S2": 1, "S3": 2, "S4": 3, "S5": 4, "S6": 5, "S7": 6, "S8": 7, "S9": 8, "S10": 9};
                            var clip = _private.selectedChannel.clipsModel.getClip(sceneIndices[_private.sketchName]);
                            zynthian.sketchpad.recordingSource = "internal"
                            zynthian.sketchpad.recordingChannel = ""
                            clip.queueRecording();
                            ZynQuick.MidiRecorder.startRecording(_private.pattern.midiChannel, true);
                            _private.sequence.startSequencePlayback();
                        }
                    }
                }
                property bool includeLeadin: false
                property bool includeLeadinInLoop: false
                property bool includeFadeout: false
                property bool includeFadeoutInLoop: false
            }
            Connections {
                enabled: _private.isRecording
                target: ZynQuick.PlayGridManager
                onMetronomeBeat128thChanged: {
                    _private.cumulativeBeats = _private.cumulativeBeats + 1;
                    if (_private.recordingDurationInBeats > _private.cumulativeBeats) {
                        // set progress based on what the thing is actually doing
                        _private.bounceProgress = _private.cumulativeBeats/_private.recordingDurationInBeats;
                        if (_private.playbackStopDurationInBeats < _private.cumulativeBeats) {
                            console.log("Fadeout reached, disconnecting playback at cumulative beat position", _private.cumulativeBeats);
                            _private.sequence.disconnectSequencePlayback();
                            // Minor hackery, this just ensure the above only happens once
                            _private.playbackStopDurationInBeats = _private.recordingDurationInBeats;
                        }
                    } else {
                        _private.isRecording = false;
                        _private.bounceProgress = 0;
                        var clip = zynthian.sketchpad.clipToRecord;
                        if (clip) {
                            ZynQuick.MidiRecorder.stopRecording();
                            clip.stopRecording();
                            clip.metadataMidiRecording = ZynQuick.MidiRecorder.base64Midi();
                        }
                        zynthian.sketchpad.stopAllPlayback();
                        _private.sequence.stopSequencePlayback();
                        ZynQuick.PlayGridManager.stopMetronome();
                        zynthian.song_arranger.stop();
                        zynthian.sketchpad.resetMetronome();
                        // Reset solo to whatever it was before we started working
                        _private.sequence.soloPattern = _private.previousSolo;
                        // Work out where the start and end points should be for the loop
                        var startTime = 0; // startTime is in seconds
                        var loopLength = _private.patternDurationInBeats; // loop length is in numbers of beats
                        if (_private.includeLeadin) {
                            if (_private.includeLeadinInLoop) {
                                // Leave the start point at 0 and just increase the loopLength by the pattern duration
                                loopLength = loopLength + _private.patternDurationInBeats;
                            } else {
                                // Leave the loopLength alone and just move the start point
                                startTime = startTime + _private.patternDurationInMS;
                            }
                        }
                        if (_private.includeFadeout && _private.includeFadeoutInLoop) {
                            // Whatever the start time is, end time should be moved by the pattern loopLength
                            loopLength = loopLength + _private.patternDurationInBeats;
                        }
                        while (clip.duration == 0) {
                            // wait a moment before we go on...
                            console.log("No clip duration yet...");
                        }
                        console.log("New sample is", _private.recordingDurationInMS, "ms long, with a pattern length of", _private.patternDurationInMS, "and loop that starts at", startTime, "and", loopLength, "beats long, and the clip says it is", clip.duration, "seconds long");
                        // Snap length to beat size if our pattern will actually fit inside such a thing (otherwise don't do that)
                        if (loopLength % ZynQuick.PlayGridManager.syncTimer.getMultiplier() === 0) {
                            clip.snapLengthToBeat = true;
                        } else {
                            clip.snapLengthToBeat = false;
                        }
                        // Set the new sample's start and end points
                        clip.startPosition = (startTime / 1000) + Math.max(0, clip.duration - (_private.recordingDurationInMS / 1000));
                        clip.length = loopLength / ZynQuick.PlayGridManager.syncTimer.getMultiplier();
                        // Set channel mode to loop
                        _private.selectedChannel.channelAudioType = "sample-loop";
                        // Close out and we're done
                        root.close();
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
            Layout.fillHeight: true
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
