/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Sketch Unbouncer, for unbouncing sketches (write the sketch source into sound setup and pattern)

Copyright (C) 2023 Dan Leinir Turthra Jensen <admin@leinir.dk>

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

Zynthian.DialogQuestion {
    id: component
    width: Kirigami.Units.gridUnit * 40
    height: Kirigami.Units.gridUnit * 25
    function unbounce(clip, track, channel, slot) {
        _private.clip = clip;
        _private.switchDestination(track, channel, slot);
        component.open();

        // TODO store an offset when using a count-in start, offer to apply that (by default probably?)
        // - If start is > 0, offer to use apply that as an offset (by default probably)
        // - If a loop point is set, offer to use that as an offset (by default probably)
        // - If there's a loop-end point set, offer to use that as the end point
        // - If duration stops short of the clip length, also stop handling events then (by default)
        // TODO Maybe handle manually played extra bits of pattern, by allowing multiplying the duration if there's enough left? (max 8 bars)
    }
    onAccepted: {
        _private.performUnbounce();
    }
    title: qsTr("Unbounce Sketch?")
    acceptText: qsTr("Unbounce")
    rejectText: qsTr("Back")
    contentItem: ColumnLayout {
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: qsTr("Performing an unbounce may overwrite some of the existing things on Track %1. Untick the options you don't want to overwrite and then tap yes, or just tap no to not unbounce.").arg(_private.channel ? _private.channel.name + 1 : "")
            QtObject {
                id: _private
                property QtObject clip
                property string track
                property QtObject channel
                property int slot
                property QtObject audioSource: clip ? Zynthbox.PlayGridManager.getClipById(clip.cppObjId) : null
                property QtObject sequence: track !== "" ? Zynthbox.PlayGridManager.getSequenceModel(track) : null
                property QtObject pattern: sequence && channel ? sequence.getByPart(channel.id, slot) : null
                function switchDestination(track, channel, slot) {
                    _private.channel = null;
                    _private.track = track;
                    _private.slot = slot;
                    _private.channel = channel;

                    // If there's notes in the pattern, ask first
                    replacePattern.hasExistingData = _private.pattern !== null && _private.pattern.hasNotes;
                    replacePattern.sketchHasData = _private.clip !== null && ((_private.clip.metadata.midiRecording !== null && _private.clip.metadata.midiRecording.length > 10) || (_private.clip.metadata.patternJson !== null && _private.clip.metadata.patternJson.length > 5));
                    replacePattern.checked = !replacePattern.hasExistingData;
                    // If there is synth information in the sketch, ask first
                    replaceSounds.hasExistingData = _private.channel !== null && _private.channel.getChannelSoundSnapshotJson().length > 10;
                    replaceSounds.sketchHasData = _private.clip !== null && _private.clip.sketchContainsSound === true;
                    replaceSounds.checked = !replaceSounds.hasExistingData;
                    // If there is sample information in the sketch, ask first
                    replaceSamples.hasExistingData = _private.channel !== null && _private.channel.occupiedSampleSlotsCount > 0;
                    replaceSamples.sketchHasData = _private.clip !== null && _private.clip.sketchContainsSamples === true;
                    replaceSamples.checked = !replaceSamples.hasExistingData;
                }
                function performUnbounce() {
                    // Start long-running task
                    zynqtgui.start_loading();
                    zynqtgui.currentTaskMessage = qsTr("Unbouncing Sketch to Track %2").arg(_private.channel.name);
                    if (_private.clip.metadata.audioType === "sample-trig") {
                        console.log("Sketch was recorded via sample-trig, so switch to that");
                        _private.channel.trackType = "sample-trig";
                    } else if (_private.clip.metadata.audioType === "sample-slice") {
                        console.log("Sketch was recorded via sample-slice, so switch to that");
                        _private.channel.trackType = "sample-slice";
                    } else if (_private.clip.metadata.audioType === "sample-loop") {
                        console.log("Sketch was recorded via synth sounds (but was in loop mode), so switch to that");
                        _private.channel.trackType = "synth";
                    } else if (_private.clip.metadata.audioType === "synth") {
                        console.log("Sketch was recorded via synth sounds, so switch to that");
                        _private.channel.trackType = "synth";
                    } else {
                        console.log("Weird audio type:", _private.clip.metadata.audioType);
                    }
                    if (replacePattern.sketchHasData && replacePattern.checked) {
                        if (_private.clip.metadata.patternJson !== null && _private.clip.metadata.patternJson.length > 5) {
                            console.log("Replace the slot's pattern content with the stored pattern");
                            _private.pattern.setFromJson(_private.clip.metadata.patternJson)
                        } else if (_private.clip.metadata.midiRecording !== null && _private.clip.metadata.midiRecording.length > 10) {
                            console.log("Replace the slot's pattern content by reconstructing from recorded midi");
                            // Load the recording into the global recorder track
                            Zynthbox.MidiRecorder.loadTrackFromBase64Midi(_private.clip.metadata.midiRecording, -1);
                            // Apply that newly loaded recording to the pattern
                            Zynthbox.MidiRecorder.applyToPattern(_private.pattern);
                        } else {
                            console.log("Not adding in data for pattern, as no data exists for this part");
                        }
                    }
                    if (replaceSamples.sketchHasData && replaceSamples.checked) {
                        console.log("Replace the channel's sample selection");
                        _private.channel.setChannelSamplesFromSnapshot(_private.clip.metadata.samples);
                        _private.channel.samplePickingStyle = _private.clip.metadata.samplePickingStyle;
                    }
                    if (replaceSounds.sketchHasData && replaceSounds.checked) {
                        console.log("Replace the channel's current sound setup with what's stored in the sketch");
                        _private.channel.setChannelSoundFromSnapshotJson(_private.clip.metadata.soundSnapshot);
                        _private.channel.setAudioTypeSettings(_private.clip.metadata.audioTypeSettings);
                        _private.channel.audioRoutingStyle = _private.clip.metadata.routingStyle;
                    }
                    // In case we unbounced to a different sketchpad track, switch to that one
                    zynqtgui.sketchpad.selectedTrackId = _private.channel.id;
                    // Similarly, if we unbounced to another slot, update the current one there as well
                    _private.channel.selectedPart = _private.slot;
                    // Since we unbounced the thing, we should disable that in favour of the newly unbounced thing
                    _private.clip.enabled = false;
                    // Always enable the newly created thing, to avoid that "eh?" experience
                    let destinationClip = _private.channel.getClipsModelByPart(_private.slot).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                    destinationClip.enabled = true;

                    // Clear out ourselves
                    _private.clip = null;
                    _private.channel = null;
                    _private.slot = -1;
                    _private.track = "";
                    // End long-running task
                    zynqtgui.stop_loading();
                }
            }
        }
        Item { Layout.fillWidth: true; Layout.fillHeight: true; }
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 2
            text: qsTr("Destination Track")
        }
        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: 10
                delegate: Zynthian.PlayGridButton {
                    Layout.preferredWidth: Kirigami.Units.gridUnit
                    text: "T" + (index + 1)
                    checked: _private.channel ? _private.channel.id == index : false
                    onClicked: {
                        if (checked == false) {
                            _private.switchDestination(_private.track, zynqtgui.sketchpad.song.channelsModel.getChannel(index), _private.slot);
                        }
                    }
                }
            }
        }
        Item { Layout.fillWidth: true; Layout.fillHeight: true; }
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 2
            text: qsTr("Destination Pattern Slot")
        }
        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: 5
                delegate: Zynthian.PlayGridButton {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    text: "Pattern " + (index + 1)
                    checked: _private.slot == index
                    onClicked: {
                        if (checked == false) {
                            _private.switchDestination(_private.track, _private.channel, index);
                        }
                    }
                }
            }
        }
        QQC2.CheckBox {
            id: replacePattern
            text: qsTr("Apply Pattern")
            property bool hasExistingData
            property bool sketchHasData
            visible: sketchHasData
        }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: replacePattern.hasExistingData ? qsTr("Replace the pattern contents of clip %1 with what is stored in the sketch").arg(_private.slot + 1) : qsTr("Set the pattern contents of clip %1 to what is stored in the sketch (there's nothing there currently)").arg(_private.slot + 1)
            visible: replacePattern.visible
        }
        Item { Layout.fillWidth: true; Layout.fillHeight: true; }
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 2
            text: qsTr("Sound Setup Options")
        }
        QQC2.CheckBox {
            id: replaceSounds
            text: qsTr("Apply Synth and FX Setup")
            property bool hasExistingData
            property bool sketchHasData
            visible: sketchHasData
        }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: replaceSounds.hasExistingData ? qsTr("Replace the track's synth and effect setup with what is stored in the sketch") : qsTr("Load the synth and effect setup from the sketch into the track (there's nothing there currently)")
            visible: replaceSounds.visible
        }
        Item { Layout.fillWidth: true; Layout.fillHeight: true; }
        QQC2.CheckBox {
            id: replaceSamples
            text: qsTr("Apply Samples")
            property bool hasExistingData
            property bool sketchHasData
            visible: sketchHasData
        }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: replaceSamples.hasExistingData ? qsTr("Replace the track's sample selection with what is stored in the sketch") : qsTr("Load the sample selection from the sketch into the track (there's nothing there currently)")
            visible: replaceSamples.visible
        }
        Item { Layout.fillWidth: true; Layout.fillHeight: true; }
    }
}
