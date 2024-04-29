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
    height: (Kirigami.Units.gridUnit * 4 * (_private.soundSourceDetails.length + 3)) + (Kirigami.Units.gridUnit * _private.sketchLacksPatternOrMidi.length * 2) + (Kirigami.Units.gridUnit * _private.sketchLacksSoundInfo.length * 2)
    function unbounce(sketchpadTrackId) {
        _private.sketchpadTrackId = sketchpadTrackId;
        component.open();
    }
    onAccepted: {
        if (_private.soundSourceSketch > -1) {
            _private.performUnbounce();
        } else {
            console.log("Can't unbounce if there's no selected sound source, so we should be disabling the accept button in that case... which we need the ability to do first.");
        }
    }
    title: qsTr("Unbounce Track?")
    acceptText: qsTr("Unbounce")
    acceptEnabled: (_private.soundSourceSketch > -1)
    rejectText: qsTr("Back")
    contentItem: ColumnLayout {
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: qsTr("Performing an unbounce on all sketches on Track %1. This will clear the track's existing sound setup, including synths, effects, and samples, and clear all notes from its patterns, as well as reset them to defaults. Please select your options below.").arg(_private.sketchpadTrackName)
            QtObject {
                id: _private
                property int sketchpadTrackId: -1
                property string sketchpadTrackName: sketchpadTrack ? sketchpadTrack.name : ""
                property QtObject sketchpadTrack: sketchpadTrackId > -1 ? zynqtgui.sketchpad.song.channelsModel.getChannel(sketchpadTrackId) : null
                property int soundSourceSketch: -1
                property var sketches: []
                onSketchpadTrackChanged: {
                    _private.soundSourceSketch = -1;
                    if (_private.sketchpadTrack) {
                        let newSketches = [];
                        for (let partIndex = 0; partIndex < 5; ++partIndex) {
                            let clip = _private.sketchpadTrack.getClipsModelByPart(partIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                            newSketches.push(clip);
                        }
                        _private.sketches = newSketches;
                    } else {
                        _private.sketches = [];
                    }
                }
                property var soundSourceDetails: []
                property var sketchLacksPatternOrMidi: []
                property var sketchLacksSoundInfo: []
                onSketchesChanged: {
                    // Go through all the sketches, and compare them to each other to work out what options we want to actually show:
                    // - If a sketch lacks pattern or midi recording information, make a note of this and warn
                    // - If a sketch lacks sound information entirely, warn that that sketch cannot be unbounced
                    // - If there is more than one type of sound setup in the sketches:
                    //   - Show the various sketches' sound descriptions (show the descriptions, and if more than one sketch is identical, collapse those options and list the sketches), require one is explicitly chosen
                    // - If there is only one sound setup for all the sketches, show that one description, perhaps still show popup to allow seeing more details
                    // - If there is already a sound setup on the track, warn about that (don't disallow unbouncing without doing this, just warn)
                    // - If there are patterns defined, warn that those will be overwritten (don't disallow unbouncing without doing this, just warn)
                    let newDetails = [];
                    _private.sketchLacksSoundInfo = [];
                    _private.sketchLacksPatternOrMidi = [];
                    let sketchSamples = [];
                    for (let sketchIndex = 0; sketchIndex < _private.sketches.length; ++sketchIndex) {
                        let sketch = _private.sketches[sketchIndex];
                        if (sketch.metadataAudioType.length > 0) {
                            if (sketch.metadataPatternJson.length > 0 || sketch._private.clip.metadataMidiRecording.length > 10) {
                                let soundSourceIndex = -1;
                                for (let detailIndex = 0; detailIndex < newDetails.length; ++detailIndex) {
                                    let otherSketch = newDetails[detailIndex].sketches[0];
                                    if (sketch.metadataAudioType === otherSketch.metadataAudioType) {
                                        let stillTheSame = false;
                                        if (sketch.metadataAudioType === "synth") {
                                            if (sketch.metadataActiveLayer === otherSketch.metadataActiveLayer) {
                                                stillTheSame = true;
                                            }
                                        } else if (sketch.metadataAudioType === "sample-trig" || sketch.metadataAudioType === "sample-slice") {
                                            if (sketch.metadataSamples === otherSketch.metadataSamples) {
                                                stillTheSame = true;
                                            }
                                        } else {
                                            _private.sketchLacksSoundInfo.push(sketch);
                                        }
                                        if (stillTheSame) {
                                            if (sketch.metadataRoutingStyle === otherSketch.metadataRoutingStyle && sketch.metadataAudioTypeSettings === otherSketch.metadataAudioTypeSettings) {
                                                // Then we've compared all the things that make the sounds the same,
                                                // so... now we can say this matches us, and bail out
                                                soundSourceIndex = detailIndex;
                                                break;
                                            }
                                        }
                                    }
                                }
                                if (soundSourceIndex === -1) {
                                    let sketchDetails = {
                                        "description": "",
                                        "sketches": [],
                                        "sketchId": sketchIndex
                                    };
                                    // Always show the synth/fx names
                                    let hasSynthSlotDetails = false;
                                    let synthSlotDetails = ["","","","",""];
                                    let fxSlotDetails = ["","","","",""];
                                    let layersData = zynqtgui.layer.sound_metadata_from_json(sketch.metadataActiveLayer);
                                    for (let layerIndex = 0; layerIndex < layersData.length; ++layerIndex) {
                                        let layerData = layersData[layerIndex];
                                        let layerDetails = qsTr("%1 (%2)").arg(layerData["name"]).arg(layerData["preset_name"]);
                                        if (layerData["engine_type"] === "MIDI Synth") {
                                            if (-1 < layerData["slot_index"] && layerData["slot_index"] < 5) {
                                                synthSlotDetails[layerData["slot_index"]] = layerDetails;
                                            } else {
                                                synthSlotDetails[layerIndex] = layerDetails;
                                            }
                                            hasSynthSlotDetails = true;
                                        } else if (layerData["engine_type"] === "Audio Effect") {
                                            if (-1 < layerData["slot_index"] && layerData["slot_index"] < 5) {
                                                fxSlotDetails[layerData["slot_index"]] = layerDetails;
                                            } else {
                                                fxSlotDetails[layerIndex - 5] = layerDetails;
                                            }
                                        } else {
                                            console.log("We apparently have an engine type we don't know about, this isn't at all right:", layerData["engine_type"]);
                                        }
                                    }
                                    // Only show the sample details if we've bounced sample-based tracks (as they're the source)
                                    let sampleSlotDetails = ["","","","",""];
                                    function createSlotDescriptions(slotDetails) {
                                        let createdDescription = "";
                                        let separator = "";
                                        for (let slotIndex = 0; slotIndex < slotDetails.length; ++slotIndex) {
                                            if (slotDetails[slotIndex].length > 0) {
                                                createdDescription = createdDescription + separator + "<b>[</b><i>" + (slotIndex + 1) + "</i> " + slotDetails[slotIndex] + "<b>]</b>";
                                            } else {
                                                createdDescription = createdDescription + separator + "<b>[</b><i>" + (slotIndex + 1) + "</i> " + qsTr("(empty)") + "<b>]</b>";
                                            }
                                            separator = " ";
                                        }
                                        return createdDescription;
                                    }
                                    if (sketch.metadataAudioType === "sample-trig" || sketch.metadataAudioType === "sample-slice") {
                                        let sampleMetadata = sketch.metadataSamples;
                                        for (let sampleSlotIndex = 0; sampleSlotIndex < 5; ++sampleSlotIndex) {
                                            sampleSlotDetails[sampleSlotIndex] = sampleMetadata[sampleSlotIndex]["filename"];
                                        }
                                        // The order of things: A header line, then the sound sources, then the fx they'll go through, and a warning about synths if they're there
                                        sketchDetails.description = qsTr("Samples: %1<br/>FX:%2").arg(createSlotDescriptions(sampleSlotDetails)).arg(createSlotDescriptions(fxSlotDetails));
                                        if (hasSynthSlotDetails) {
                                            sketchDetails.description = qsTr("%1<br/><i>Note:</i>Unbouncing this sketch will also result in the following new synths being added:<br/>%2").arg(sketchDetails.description).arg(createSlotDescriptions(synthSlotDetails));
                                        }
                                    } else {
                                        // The order of things: A header line, then the sound sources, then the fx they'll go through
                                        sketchDetails.description = qsTr("Synths: %1<br/>FX: %2").arg(createSlotDescriptions(synthSlotDetails)).arg(createSlotDescriptions(fxSlotDetails));
                                    }
                                    // There isn't a detail for this one already, so let's actually add that temporary one we used for comparison as a proper entry
                                    soundSourceIndex = newDetails.length;
                                    newDetails.push(sketchDetails);
                                }
                                // Add the sketch to the sketches already there
                                newDetails[soundSourceIndex].sketches.push(sketch);
                            } else {
                                _private.sketchLacksPatternOrMidi.push(sketch);
                            }
                        } else {
                            _private.sketchLacksSoundInfo.push(sketch);
                        }
                    }
                    for (let detailIndex = 0; detailIndex < newDetails.length; ++detailIndex) {
                        let sketchList = [];
                        for (let sketchIndex = 0; sketchIndex < newDetails[detailIndex].sketches.length; ++sketchIndex) {
                            sketchList.push(qsTr("Sketch %1").arg(newDetails[detailIndex].sketches[sketchIndex].part + 1));
                        }
                        // This is absolutely an anglicism... but not really sure what to do, we're using qsTr, does that know how to do proper i18n list stuff?
                        if (newDetails[detailIndex].sketches.length > 2) {
                            sketchList[sketchList.length - 1] = qsTr("and %1").arg(sketchList[sketchList.length - 1]);
                            newDetails[detailIndex].description = qsTr("<b>Use the sounds from %1</b><br/>%2").arg(sketchList.join(", ")).arg(newDetails[detailIndex].description);
                        } else {
                            newDetails[detailIndex].description = qsTr("<b>Use the sounds from %1</b><br/>%2").arg(sketchList.join(qsTr(" and "))).arg(newDetails[detailIndex].description);
                        }
                    }
                    _private.soundSourceDetails = newDetails;
                    if (_private.soundSourceDetails.length === 1) {
                        _private.soundSourceSketch = newDetails[0].sketchId;
                    } else {
                        _private.soundSourceSketch = -1;
                    }
                }
                function performUnbounce() {
                    // - Start long-running task
                    zynqtgui.start_loading();
                    zynqtgui.currentTaskMessage = qsTr("Unbouncing Track %1").arg(_private.sketchpadTrack.name);
                    // - eat all input if we're unbouncing
                    // - Clear samples
                    for (let sampleSlotIndex = 0;  sampleSlotIndex < 5; ++sampleSlotIndex) {
                        let sample = _private.sketchpadTrack.samples[sampleSlotIndex];
                        sample.clear();
                    }
                    // - Pick out the specific clip selected for sound source
                    let originSketch = _private.sketches[_private.soundSourceSketch];
                    //   - Set track channelAudioType to match ZYNTHBOX_AUDIO_TYPE (clip.metadataAudioType)
                    _private.sketchpadTrack.channelAudioType = originSketch.metadataAudioType;
                    //   - Set track channelRoutingStyle to match ZYNTHBOX_ROUTING_STYLE (clip.metadataRoutingStyle)
                    _private.sketchpadTrack.channelRoutingStyle = originSketch.metadataRoutingStyle;
                    //   - Set track setAudioTypeSettings to ZYNTHBOX_AUDIOTYPESETTINGS (clip.metadataAudioTypeSettings)
                    _private.sketchpadTrack.setAudioTypeSettings(originSketch.metadataAudioTypeSettings);
                    //   - setChannelSoundFromSnapshotJson to ZYNTHBOX_ACTIVE_LAYER (clip.metadataActiveLayer)
                    _private.sketchpadTrack.setChannelSoundFromSnapshotJson(originSketch.metadataActiveLayer);
                    //   - If channelAudioType is sample-trig or sample-slice: set samples to ZYNTHBOX_SAMPLES  (setChannelSamplesFromSnapshot(clip.metadataSamples))
                    if (_private.sketchpadTrack.channelAudioType === "sample-trig" || _private.sketchpadTrack.channelAudioType === "sample-slice") {
                        _private.sketchpadTrack.setChannelSamplesFromSnapshot(otherSketch.metadataSamples);
                    }
                    // - Run through the track's patterns
                    let sequence = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName);
                    let enabledAPart = false;
                    for (let partIndex = 0; partIndex < 5; ++partIndex) {
                        let pattern = sequence.getByPart(_private.sketchpadTrack.id, partIndex);
                    //   - Clear the existing pattern and reset it to defaults
                        pattern.resetPattern(true);
                        let partSketch = _private.sketches[partIndex];
                        // Disable the sketch we're unbouncing in favour of one of the destination slots
                        if (partSketch) {
                            partSketch.enabled = false;
                        }
                    //   - If there is a sketch at that position, and it has pattern data, fill up the part's pattern data from that sketch (ZYNTHBOX_PATTERN_JSON - setFromJson(clip.metadataPatternJson))
                        if (partSketch.metadataPatternJson !== null && partSketch.metadataPatternJson.length > 5) {
                            console.log("Replace the slot's pattern content with the stored pattern");
                            pattern.setFromJson(partSketch.metadataPatternJson)
                            if (enabledAPart === false) {
                                // If we've not already enabled something, enable the first thing we encounter
                                let destinationClip = _private.sketchpadTrack.getClipsModelByPart(partIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                                destinationClip.enabled = true;
                                enabledAPart = true;
                            }
                        } else if (partSketch.metadataMidiRecording !== null && partSketch.metadataMidiRecording.length > 10) {
                            console.log("Replace the slot's pattern content by reconstructing from recorded midi");
                            // Load the recording into the global recorder track
                            Zynthbox.MidiRecorder.loadTrackFromBase64Midi(partSketch.metadataMidiRecording, -1);
                            // Apply that newly loaded recording to the pattern
                            Zynthbox.MidiRecorder.applyToPattern(pattern);
                            if (enabledAPart === false) {
                                // If we've not already enabled something, enable the first thing we encounter
                                let destinationClip = _private.sketchpadTrack.getClipsModelByPart(partIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                                destinationClip.enabled = true;
                                enabledAPart = true;
                            }
                        } else {
                            console.log("Not adding in data for pattern, as no data exists for this part");
                        }
                    }
                    // - Clean up after ourselves
                    _private.sketchpadTrackId = -1;
                    // - End long-running task
                    zynqtgui.stop_loading();
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        Repeater {
            model: _private.soundSourceDetails
            delegate: Zynthian.PlayGridButton {
                id: soundSourceDelegate
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.minimumHeight: Kirigami.Units.gridUnit * 3
                property var soundSource: modelData
                checked: _private.soundSourceSketch === soundSourceDelegate.soundSource.sketchId
                onClicked: {
                    _private.soundSourceSketch = soundSourceDelegate.soundSource.sketchId;
                }
                contentItem: ColumnLayout {
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: Kirigami.Units.smallSpacing
                        text: soundSourceDelegate.soundSource.description
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            visible: _private.sketchLacksSoundInfo.length > 0
            wrapMode: Text.Wrap
            text: qsTr("Please note, the following sketches lack any sound information that we can use, and cannot be unbounced. Unbouncing will not remove their assignment, but once the track leaves Sketch mode, you will not be able to play them until you switch back to Sketch mode.");
        }
        Repeater {
            model: _private.sketchLacksSoundInfo
            delegate: QQC2.Label {
                Layout.fillWidth: true
                text: qsTr("* %1").arg(moduleData.filename)
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            visible: _private.sketchLacksPatternOrMidi.length > 0
            wrapMode: Text.Wrap
            text: qsTr("Please note, the following sketches lack pattern data and have no recorded midi information, and cannot be properly unbounced. Unbouncing will not remove their assignment, but once the track leaves Sketch mode, you will not be able to play them until you switch back to Sketch mode.");
        }
        Repeater {
            model: _private.sketchLacksPatternOrMidi
            delegate: QQC2.Label {
                Layout.fillWidth: true
                text: qsTr("* %1").arg(moduleData.filename)
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
