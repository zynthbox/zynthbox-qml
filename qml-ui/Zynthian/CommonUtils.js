.import org.zynthian.quick 1.0 as ZynQuick

function startMetronomeAndPlayback() {
    if (zynthian.sketchpad.song.sketchesModel.songMode) {
        if (zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.totalBeatDuration > 0) {
            ZynQuick.SegmentHandler.startPlayback(0, 0);
        }
    } else {
        console.log("Starting Metronome and Playback");
        for (var i = 0; i < 10; ++i) {
            var sequence = ZynQuick.PlayGridManager.getSequenceModel("T" + (i+1));
            if (sequence) {
                sequence.prepareSequencePlayback();
            } else {
                console.debug("Sequence could not be fetched, and playback could not be prepared");
            }
        }
        if (zynthian.sketchpad.clipToRecord) {
            ZynQuick.MidiRecorder.startRecording(ZynQuick.PlayGridManager.currentMidiChannel, true);
        }
        zynthian.sketchpad.startPlayback();
        console.log("Metronome and Playback Started");
    }
}

function stopMetronomeAndPlayback() {
    if (zynthian.sketchpad.song.sketchesModel.songMode) {
        zynthian.sketchpad.stopAllPlayback();
        ZynQuick.SegmentHandler.stopPlayback();
        zynthian.sketchpad.resetMetronome();
    } else {
        console.log("Stopping Metronome and Playback");
        for (var i = 0; i < 10; ++i) {
            var sequence = ZynQuick.PlayGridManager.getSequenceModel("T" + (i+1));
            if (sequence) {
                sequence.stopSequencePlayback();
            } else {
                console.log("Sequence could not be fetched, and playback could not be stopped");
            }
        }

        if (zynthian.sketchpad.isRecording) {
            ZynQuick.MidiRecorder.stopRecording()
            zynthian.sketchpad.lastRecordingMidi = ZynQuick.MidiRecorder.base64Midi()

            if (zynthian.sketchpad.recordingType === "audio") {
                zynthian.sketchpad.stopAudioRecording()
            } else {
                for (var clipIndex in zynthian.sketchpad.clipsToRecord) {
                    var clip = zynthian.sketchpad.clipsToRecord[clipIndex]

                    if (!clip.isChannelSample) {
                        var sequence = ZynQuick.PlayGridManager.getSequenceModel(zynthian.sketchpad.song.scenesModel.selectedTrackName)
                        var pattern = sequence.getByPart(clip.row, clip.part)

                        console.log("Applying pattern to", pattern, " for ", clip, clip.row, clip.col, clip.part)
                        ZynQuick.MidiRecorder.applyToPattern(pattern)
                    }
                }
            }

            zynthian.sketchpad.stopRecording()
        }

        zynthian.sketchpad.stopAllPlayback();
        zynthian.playgrid.stopMetronomeRequest();
        zynthian.song_arranger.stop();
        zynthian.sketchpad.resetMetronome();
        console.log("Metronome and Playback Stopped");
    }
}

function toggleLayerChaining(layer) {
    if (layer.metadata.midi_cloned) {
        zynthian.layer.remove_clone_midi(layer.metadata.midi_channel, layer.metadata.midi_channel + 1);
        zynthian.layer.remove_clone_midi(layer.metadata.midi_channel + 1, layer.metadata.midi_channel);
    } else {
        zynthian.layer.clone_midi(layer.metadata.midi_channel, layer.metadata.midi_channel + 1);
        zynthian.layer.clone_midi(layer.metadata.midi_channel + 1, layer.metadata.midi_channel);
    }
    zynthian.layer.ensure_contiguous_cloned_layers();
    zynthian.fixed_layers.show();
}

function switchToScene(index) {
    zynthian.sketchpad.song.scenesModel.selectedSceneIndex = index
}

function cuiaHandler(cuia, selectedChannel, bottomStack) {
    switch (cuia) {
        // Set respective selected row when button 1-5 is pressed or 6(mod)+1-5 is pressed
        // and invoke respective handler when channelAudioType is synth, trig or slice
        // Otherwise, when in loop mode, do not handle button to allow falling back to channel
        // selection
        case "CHANNEL_1":
        case "CHANNEL_6":
            if (selectedChannel.channelAudioType === "synth" ||
                selectedChannel.channelAudioType === "sample-loop" ||
                selectedChannel.channelAudioType === "sample-trig" ||
                selectedChannel.channelAudioType === "sample-slice") {
                selectedChannel.selectedSlotRow = 0
                bottomStack.slotsBar.handleItemClick(selectedChannel.channelAudioType)
                return true
            }

            return false

        case "CHANNEL_2":
        case "CHANNEL_7":
            if (selectedChannel.channelAudioType === "synth" ||
                selectedChannel.channelAudioType === "sample-loop" ||
                selectedChannel.channelAudioType === "sample-trig" ||
                selectedChannel.channelAudioType === "sample-slice") {
                selectedChannel.selectedSlotRow = 1
                bottomStack.slotsBar.handleItemClick(selectedChannel.channelAudioType)
                return true
            }

            return false

        case "CHANNEL_3":
        case "CHANNEL_8":
            if (selectedChannel.channelAudioType === "synth" ||
                selectedChannel.channelAudioType === "sample-loop" ||
                selectedChannel.channelAudioType === "sample-trig" ||
                selectedChannel.channelAudioType === "sample-slice") {
                selectedChannel.selectedSlotRow = 2
                bottomStack.slotsBar.handleItemClick(selectedChannel.channelAudioType)
                return true
            }

            return false

        case "CHANNEL_4":
        case "CHANNEL_9":
            if (selectedChannel.channelAudioType === "synth" ||
                selectedChannel.channelAudioType === "sample-loop" ||
                selectedChannel.channelAudioType === "sample-trig" ||
                selectedChannel.channelAudioType === "sample-slice") {
                selectedChannel.selectedSlotRow = 3
                bottomStack.slotsBar.handleItemClick(selectedChannel.channelAudioType)
                return true
            }

            return false

        case "CHANNEL_5":
        case "CHANNEL_10":
            if (selectedChannel.channelAudioType === "synth" ||
                selectedChannel.channelAudioType === "sample-loop" ||
                selectedChannel.channelAudioType === "sample-trig" ||
                selectedChannel.channelAudioType === "sample-slice") {
                selectedChannel.selectedSlotRow = 4
                bottomStack.slotsBar.handleItemClick(selectedChannel.channelAudioType)
                return true
            }

            return false
    }

    return false
}
