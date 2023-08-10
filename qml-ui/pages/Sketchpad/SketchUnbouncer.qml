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
    height: Kirigami.Units.gridUnit * 25
    function unbounce(clip, track, channel, slot) {
        _private.track = track;
        _private.slot = slot;
        _private.channel = channel;
        _private.clip = clip;

        // TODO store pattern settings in sketches, and when restoring, apply those as well (note length, available bars)
        // - "The current pattern settings don't match what was used to create the sketch - adjust to match the sketch?"
        // TODO store an offset when using a count-in start, offer to apply that (by default probably?)
        // - If start is > 0, offer to use apply that as an offset (by default probably)
        // - If a loop point is set, offer to use that as an offset (by default probably)
        // - If there's a loop-end point set, offer to use that as the end point
        // - If duration stops short of the clip length, also stop handling events then (by default)
        // TODO Maybe handle manually played extra bits of pattern, by allowing multiplying the duration if there's enough left? (max 8 bars)

        // If there's notes in the pattern, ask first
        replacePattern.hasExistingData = _private.pattern !== null && _private.pattern.hasNotes;
        replacePattern.sketchHasData = _private.clip !== null && _private.clip.metadataMidiRecording !== null && _private.clip.metadataMidiRecording.length > 10;
        replacePattern.checked = !replacePattern.hasExistingData;
        // If there is synth information in the sketch, ask first
        replaceSounds.hasExistingData = _private.channel !== null && _private.channel.getChannelSoundSnapshotJson().length > 10;
        replaceSounds.sketchHasData = _private.clip !== null && _private.clip.sketchContainsSound === true;
        replaceSounds.checked = !replaceSounds.hasExistingData;
        // If there is sample information in the sketch, ask first
        replaceSamples.hasExistingData = _private.channel !== null && _private.channel.occupiedSampleSlotsCount > 0;
        replaceSamples.sketchHasData = _private.clip !== null && _private.clip.sketchContainsSamples === true;
        replaceSamples.checked = !replaceSamples.hasExistingData;
        // All the above should be one question, not multiple popups (ask to be safe, but don't be obnoxious)
        if (replaceSounds.checked && replaceSamples.checked && replacePattern.checked) {
            console.log("Nothing that we'd overwrite, just unbounce");
            _private.performUnbounce();
        } else {
            console.log("Unbounce requested, show options");
            component.open();
        }
    }
    onAccepted: {
        _private.performUnbounce();
    }
    title: qsTr("Unbounce Sketch?")
    contentItem: ColumnLayout {
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: qsTr("Performing this unbounce will overwrite some of the existing things on track %1. Untick the ones you don't want to overwrite and then tap yes, or just tap no to not unbounce.").arg(_private.track)
            QtObject {
                id: _private
                property QtObject clip
                property string track
                property QtObject channel
                property int slot
                property QtObject audioSource: clip ? Zynthbox.PlayGridManager.getClipById(clip.cppObjId) : null
                // onAudioSourceChanged: console.log("Audio source:", audioSource)
                property QtObject sequence: track !== "" ? Zynthbox.PlayGridManager.getSequenceModel(track) : null
                // onSequenceChanged: console.log("Sequence:", sequence)
                property QtObject pattern: sequence && channel ? sequence.getByPart(channel.id, slot) : null
                // onPatternChanged: console.log("Pattern:", pattern, "from channel and part", channel.id, slot)
                function performUnbounce() {
                    if (clip.metadataAudioType === "sample-trig") {
                        console.log("Sketch was recorded via sample-trig, so switch to that");
                        _private.channel.channelAudioType = "sample-trig";
                    } else if (clip.metadataAudioType === "synth") {
                        console.log("Sketch was recorded via synth sounds, so switch to that");
                        _private.channel.channelAudioType = "synth";
                    } else {
                        console.log("Weird audio type:", clip.metadataAudioType);
                    }
                    if (replacePattern.sketchHasData && replacePattern.checked) {
                        console.log("Replace the slot's pattern content");
                        // Load the recording into the global recorder track
                        Zynthbox.MidiRecorder.loadTrackFromBase64Midi(_private.clip.metadataMidiRecording, -1);
                        // Apply that newly loaded recording to the pattern
                        Zynthbox.MidiRecorder.applyToPattern(_private.pattern);
                    }
                    if (replaceSamples.sketchHasData && replaceSamples.checked) {
                        console.log("Replace the channel's sample selection");
                        _private.channel.setChannelSamplesFromSnapshot(clip.metadataSamples);
                    }
                    if (replaceSounds.sketchHasData && replaceSounds.checked) {
                        console.log("Replace the channel's current sound setup with what's stored in the sketch");
                        _private.channel.setChannelSoundFromSnapshotJson(_private.clip.metadataActiveLayer)
                    }
                    _private.clip = null;
                }
            }
        }
        Item { Layout.fillWidth: true; Layout.fillHeight: true; }
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
