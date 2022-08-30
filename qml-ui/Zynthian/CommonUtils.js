.import org.zynthian.quick 1.0 as ZynQuick

function startMetronomeAndPlayback() {
    if (zynthian.zynthiloops.song.mixesModel.songMode) {
        if (zynthian.zynthiloops.song.mixesModel.selectedMix.segmentsModel.totalBeatDuration > 0) {
            ZynQuick.SegmentHandler.startPlayback(0, 0);
        }
    } else {
        console.log("Starting Metronome and Playback");
        for (var i = 0; i < 10; ++i) {
            var sequence = ZynQuick.PlayGridManager.getSequenceModel("S" + (i+1));
            if (sequence) {
                sequence.prepareSequencePlayback();
            } else {
                console.debug("Sequence could not be fetched, and playback could not be prepared");
            }
        }
        if (zynthian.zynthiloops.clipToRecord) {
            ZynQuick.MidiRecorder.startRecording(ZynQuick.PlayGridManager.currentMidiChannel, true);
        }
        zynthian.zynthiloops.startPlayback();
        console.log("Metronome and Playback Started");
    }
}

function stopMetronomeAndPlayback() {
    if (zynthian.zynthiloops.song.mixesModel.songMode) {
        zynthian.zynthiloops.stopAllPlayback();
        ZynQuick.SegmentHandler.stopPlayback();
        zynthian.zynthiloops.resetMetronome();
    } else {
        console.log("Stopping Metronome and Playback");
        for (var i = 0; i < 10; ++i) {
            var sequence = ZynQuick.PlayGridManager.getSequenceModel("S" + (i+1));
            if (sequence) {
                sequence.stopSequencePlayback();
            } else {
                console.log("Sequence could not be fetched, and playback could not be stopped");
            }
        }

        if (zynthian.zynthiloops.isRecording) {
            ZynQuick.MidiRecorder.stopRecording()
            zynthian.zynthiloops.lastRecordingMidi = ZynQuick.MidiRecorder.base64Midi()

            if (zynthian.zynthiloops.recordingType === "audio") {
                zynthian.zynthiloops.stopAudioRecording()
            } else {
                for (var clipIndex in zynthian.zynthiloops.clipsToRecord) {
                    var clip = zynthian.zynthiloops.clipsToRecord[clipIndex]

                    if (!clip.isChannelSample) {
                        var sequence = ZynQuick.PlayGridManager.getSequenceModel(zynthian.zynthiloops.song.scenesModel.selectedSketchName)
                        var pattern = sequence.getByPart(clip.row, clip.part)

                        console.log("Applying pattern to", pattern, " for ", clip, clip.row, clip.col, clip.part)
                        ZynQuick.MidiRecorder.applyToPattern(pattern)
                    }
                }
            }

            zynthian.zynthiloops.stopRecording()
        }

        zynthian.zynthiloops.stopAllPlayback();
        zynthian.playgrid.stopMetronomeRequest();
        zynthian.song_arranger.stop();
        zynthian.zynthiloops.resetMetronome();
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
    zynthian.zynthiloops.song.scenesModel.selectedSceneIndex = index
}

function cuiaHandler(cuia, selectedChannel, bottomStack) {
    switch (cuia) {
        // Set respective selected row when button 1-5 is pressed or 6(mod)+1-5 is pressed
        // and invoke respective handler when channelAudioType is synth, trig or slice
        // Otherwise, when in loop mode, do not handle button to allow falling back to channel
        // selection
        case "CHANNEL_1":
        case "CHANNEL_6":
            if (selectedChannel.channelAudioType === "sample-loop") {
                if (selectedChannel.connectedPattern >= 0) {
                    bottomStack.bottomBar.setControlObjByType(selectedChannel.sceneClip, "pattern")
                } else {
                    bottomStack.bottomBar.setControlObjByType(selectedChannel.sceneClip, "clip")
                }

                bottomStack.bottomBar.filePickerDialog.folderModel.folder = bottomStack.bottomBar.controlObj.recordingDir;
                bottomStack.bottomBar.filePickerDialog.open();
                bottomStack.bottomBar.filePickerDialog.open();

                return true
            } else if (selectedChannel.channelAudioType === "synth" ||
                selectedChannel.channelAudioType === "sample-trig" ||
                selectedChannel.channelAudioType === "sample-slice") {
                bottomStack.slotsBar.selectedSlotRowItem.channel.selectedSlotRow = 0
                bottomStack.slotsBar.handleItemClick(selectedChannel.channelAudioType)
                return true
            }

            return false

        case "CHANNEL_2":
        case "CHANNEL_7":
            if (selectedChannel.channelAudioType === "sample-loop") {
                return true
            } else if (selectedChannel.channelAudioType === "synth" ||
                selectedChannel.channelAudioType === "sample-trig" ||
                selectedChannel.channelAudioType === "sample-slice") {
                bottomStack.slotsBar.selectedSlotRowItem.channel.selectedSlotRow = 1
                bottomStack.slotsBar.handleItemClick(selectedChannel.channelAudioType)
                return true
            }

            return false

        case "CHANNEL_3":
        case "CHANNEL_8":
            if (selectedChannel.channelAudioType === "sample-loop") {
                return true
            } else if (selectedChannel.channelAudioType === "synth" ||
                selectedChannel.channelAudioType === "sample-trig" ||
                selectedChannel.channelAudioType === "sample-slice") {
                bottomStack.slotsBar.selectedSlotRowItem.channel.selectedSlotRow = 2
                bottomStack.slotsBar.handleItemClick(selectedChannel.channelAudioType)
                return true
            }

            return false

        case "CHANNEL_4":
        case "CHANNEL_9":
            if (selectedChannel.channelAudioType === "sample-loop") {
                return true
            } else if (selectedChannel.channelAudioType === "synth" ||
                selectedChannel.channelAudioType === "sample-trig" ||
                selectedChannel.channelAudioType === "sample-slice") {
                bottomStack.slotsBar.selectedSlotRowItem.channel.selectedSlotRow = 3
                bottomStack.slotsBar.handleItemClick(selectedChannel.channelAudioType)
                return true
            }

            return false

        case "CHANNEL_5":
        case "CHANNEL_10":
            if (selectedChannel.channelAudioType === "sample-loop") {
                return true
            } else if (selectedChannel.channelAudioType === "synth" ||
                selectedChannel.channelAudioType === "sample-trig" ||
                selectedChannel.channelAudioType === "sample-slice") {
                bottomStack.slotsBar.selectedSlotRowItem.channel.selectedSlotRow = 4
                bottomStack.slotsBar.handleItemClick(selectedChannel.channelAudioType)
                return true
            }

            return false
    }

    return false
}
