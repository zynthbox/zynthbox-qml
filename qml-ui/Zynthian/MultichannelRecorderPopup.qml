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
        for (var channelIndex = 0; channelIndex < 10; ++channelIndex) {
            // Work out which channels we want to default-enable (that is, all channels which have things that are likely to be making a noise)
            var shouldRecord = false;
            var channel = song.channelsModel.getChannel(channelIndex);
            if (channel.channelAudioType === "synth") {
                for (var soundIndex = 0; soundIndex < 5; ++soundIndex) {
                    if (channel.chainedSounds[soundIndex] > -1) {
                        shouldRecord = true;
                        break;
                    }
                }
            } else if (channel.channelAudioType === "sample-loop") {
                for (var loopIndex = 0; loopIndex < 10; ++loopIndex) {
                    if (channel.clipsModel.getClip(loopIndex).cppObjId > -1) {
                        shouldRecord = true;
                        break;
                    }
                }
            } else if (channel.channelAudioType === "sample-trig" || channel.channelAudioType === "sample-slice") {
                for (var sampleIndex = 0; sampleIndex < 5; ++sampleIndex) {
                    if (channel.samples[sampleIndex].cppObjId > -1) {
                        shouldRecord = true;
                        break;
                    }
                }
            } else {
                // Assume external channels shouldn't be recorded, as they are not going to make internal noises
            }
            ZL.AudioLevels.setChannelToRecord(channelIndex, shouldRecord);
        }
        if (song.mixesModel.songMode) {
            leadinSpin.value = 0;
            fadeoutSpin.value = 8;
        } else {
            // No song mode, just play the current scene, with the longest pattern duration as the duration
            var sequence = ZynQuick.PlayGridManager.getSequenceModel(song.scenesModel.selectedSketchName)
            var longestPatternDuration = 0;
            // Assemble the duration of time we want to be recording for
            var noteLengths = { 1: 32, 2: 16, 3: 8, 4: 4, 5: 2, 6: 1 }
            for (var channelIndex = 0; channelIndex < 10; ++channelIndex) {
                for (var partIndex = 0; partIndex < 5; ++partIndex) {
                    var pattern = sequence.getByPart(channelIndex, partIndex);
                    var patternDuration = pattern.width * pattern.availableBars * noteLengths[pattern.noteLength];
                    if (patternDuration > longestPatternDuration) {
                        longestPatternDuration = patternDuration;
                    }
                }
            }
            leadinSpin.value = 4;
            songDurationSpin.value = longestPatternDuration;
            fadeoutSpin.value = 4;
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
        implicitHeight: Kirigami.Units.gridUnit * 48
        implicitWidth: Kirigami.Units.gridUnit * 64
        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Record Song"
            QtObject {
                id: _private
                property double recordingProgress: -1
                property QtObject song

                property int songDurationInTicks: song && song.mixesModel.songMode
                    ? ZynQuick.PlayGridManager.syncTimer.getMultiplier() * song.mixesModel.selectedMix.segmentsModel.totalBeatDuration
                    : ZynQuick.PlayGridManager.syncTimer.getMultiplier() * songDurationSpin.value
                property int leadinDurationInTicks: leadinSpin.value * ZynQuick.PlayGridManager.syncTimer.getMultiplier()
                property int fadeoutDurationInTicks: fadeoutSpin.value * ZynQuick.PlayGridManager.syncTimer.getMultiplier()

                property bool isRecording: false
                property int cumulativeBeats
                function startRecording() {
                    _private.recordingProgress = 0;
                    // Set the filenames for each channel (never mind whether they're being recorded or not, it doesn't hurt)
                    var date = new Date();
                    var baseRecordingLocation = _private.song.sketchpadFolder + "exports/exported-" + date.getFullYear() + date.getMonth() + date.getDate() + "-" + date.getHours() + date.getMinutes();
                    ZL.AudioLevels.setGlobalPlaybackFilenamePrefix(baseRecordingLocation + "/song-");
                    baseRecordingLocation = baseRecordingLocation + "/channel-";
                    for (var channelIndex = 0; channelIndex < 10; ++channelIndex) {
                        var channel = _private.song.channelsModel.getChannel(channelIndex);
                        var soundIndication = "(unknown)";
                        if (channel.channelAudioType === "synth") {
                            for (var soundIndex = 0; soundIndex < 5; ++soundIndex) {
                                if (channel.chainedSounds[soundIndex] > -1) {
                                    soundIndication = channel.connectedSoundName.replace(/([^a-z0-9]+)/gi, '-');
                                    break;
                                }
                            }
                        } else if (channel.channelAudioType === "sample-loop") {
                            for (var loopIndex = 0; loopIndex < 10; ++loopIndex) {
                                var clip = channel.clipsModel.getClip(loopIndex);
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
                        } else if (channel.channelAudioType === "sample-trig" || channel.channelAudioType === "sample-slice") {
                            for (var sampleIndex = 0; sampleIndex < 5; ++sampleIndex) {
                                var clip = channel.samples[sampleIndex];
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
                        console.log("Setting channel", channelIndex, "filename prefix to", baseRecordingLocation + (channelIndex + 1) + "-" + soundIndication);
                        ZL.AudioLevels.setChannelFilenamePrefix(channelIndex, baseRecordingLocation + (channelIndex + 1) + "-" + soundIndication);
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
                interval: ZynQuick.PlayGridManager.syncTimer.subbeatCountToSeconds(zynthian.sketchpad.song.bpm, _private.leadinDurationInTicks) * 1000
                onTriggered: {
                    console.log("Starting playback after", interval);
                    Zynthian.CommonUtils.startMetronomeAndPlayback();
                }
            }
            Timer {
                id: recordingStopper
                repeat: false; running: false;
                interval: ZynQuick.PlayGridManager.syncTimer.subbeatCountToSeconds(zynthian.sketchpad.song.bpm, _private.fadeoutDurationInTicks) * 1000
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
                        for (var channelIndex = 0; channelIndex < 10; ++channelIndex) {
                            // Disable recording for all channels, otherwise we'll just end up recording things when we don't want to
                            ZL.AudioLevels.setChannelToRecord(channelIndex, false);
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
                    text: qsTr("Channel:")
                }
                QQC2.Label {
                    Layout.fillHeight: true
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
            ColumnLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    Layout.fillWidth: true
                    text: "Song"
                    horizontalAlignment: Text.AlignHCenter
                }
                QQC2.CheckBox {
                    Layout.fillWidth: true
                    enabled: !_private.isRecording
                    checked: ZL.AudioLevels.recordGlobalPlayback
                    onClicked: ZL.AudioLevels.recordGlobalPlayback = !ZL.AudioLevels.recordGlobalPlayback
                }
            }
            Repeater {
                model: _private.song ? 10 : 0
                ColumnLayout {
                    id: channelDelegate
                    Layout.fillWidth: true
                    property int channelIndex: model.index
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: "Ch" + (channelDelegate.channelIndex + 1)
                        horizontalAlignment: Text.AlignHCenter
                    }
                    QQC2.CheckBox {
                        Layout.fillWidth: true
                        enabled: !_private.isRecording
                        checked: ZL.AudioLevels.channelsToRecord[channelDelegate.channelIndex]
                        onClicked: ZL.AudioLevels.setChannelToRecord(channelDelegate.channelIndex, !ZL.AudioLevels.channelsToRecord[channelDelegate.channelIndex])
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
                QQC2.BusyIndicator {
                    anchors {
                        left: parent.right
                        leftMargin: Kirigami.Units.smallSpacing
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: height
                    visible: running
                    running: recordingPlaybackStarter.running
                }
            }
            QQC2.SpinBox{
                id: songDurationSpin
                Layout.fillWidth: true
                visible: _private.song && !_private.song.mixesModel.songMode
                Kirigami.FormData.label: qsTr("Recording duration in beats:")
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
                QQC2.BusyIndicator {
                    anchors {
                        left: parent.right
                        leftMargin: Kirigami.Units.smallSpacing
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: height
                    visible: running
                    running: recordingStopper.running
                }
            }
        }
        QQC2.ProgressBar {
            id: recordingProgressBar
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 30
            visible: _private.song && !_private.song.mixesModel.songMode
            opacity: _private.recordingProgress > -1 ? 1 : 0.3
            value: _private.recordingProgress
        }
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit
            visible: _private.song && _private.song.mixesModel.songMode && segmentsRepeater.count > 0
            Row {
                id: songProgressRow
                anchors.fill: parent
                spacing: 0
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                Repeater {
                    id: segmentsRepeater
                    property double totalDuration: _private.song ? ZynQuick.PlayGridManager.syncTimer.getMultiplier() * _private.song.mixesModel.selectedMix.segmentsModel.totalBeatDuration : 0
                    model: component.visible && totalDuration > 0 ? _private.song.mixesModel.selectedMix.segmentsModel : 0
                    delegate: Item {
                        id: segmentDelegate
                        property QtObject segment: model.segment
                        property double duration: ZynQuick.PlayGridManager.syncTimer.getMultiplier() * (segmentDelegate.segment.barLength * 4 + segmentDelegate.segment.beatLength)
                        width: parent.width * (segmentDelegate.duration / segmentsRepeater.totalDuration)
                        height: parent.height
                        Rectangle {
                            anchors {
                                fill: parent;
                                margins: 1
                            }
                            border {
                                width: 1
                                color: Kirigami.Theme.focusColor
                            }
                            color: Kirigami.Theme.backgroundColor
                        }
                    }
                }
            }
            Item {
                anchors {
                    top: parent.top
                    topMargin: -2
                    bottom: parent.bottom
                    bottomMargin: -2
                    left: parent.left
                    leftMargin: component.visible ? songProgressRow.width * (ZynQuick.SegmentHandler.playhead / segmentsRepeater.totalDuration) : 0
                }
                width: 1
                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: 3
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: Kirigami.Theme.focusColor
                }
            }
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
