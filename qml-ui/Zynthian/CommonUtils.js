.import org.zynthian.quick 1.0 as ZynQuick

function startMetronomeAndPlayback() {
    console.log("Starting Metronome and Playback");
    for (var i = 0; i < mixNames.length; ++i) {
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

function stopMetronomeAndPlayback() {
    console.log("Stopping Metronome and Playback");
    for (var i = 0; i < mixNames.length; ++i) {
        var sequence = ZynQuick.PlayGridManager.getSequenceModel("S" + (i+1));
        if (sequence) {
            sequence.stopSequencePlayback();
        } else {
            console.log("Sequence could not be fetched, and playback could not be stopped");
        }
    }

    if (zynthian.zynthiloops.clipToRecord) {
        ZynQuick.MidiRecorder.stopRecording()
        var clip = zynthian.zynthiloops.clipToRecord
        clip.stopRecording()
        clip.metadataMidiRecording = ZynQuick.MidiRecorder.base64Midi()
        ZynQuick.MidiRecorder.loadFromBase64Midi(clip.metadataMidiRecording)
    }

    zynthian.zynthiloops.stopAllPlayback();
//    zynthian.zynthiloops.stopRecording();
    zynthian.playgrid.stopMetronomeRequest();
    zynthian.song_arranger.stop();
    zynthian.zynthiloops.resetMetronome();
    console.log("Metronome and Playback Stopped");
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

function cuiaHandler(cuia, selectedTrack, bottomStack) {
    switch (cuia) {
        // Set respective selected row when button 1-5 is pressed or 6(mod)+1-5 is pressed
        // and invoke respective handler when trackAudioType is synth, trig or slice
        // Otherwise, when in loop mode, do not handle button to allow falling back to track
        // selection
        case "TRACK_1":
        case "TRACK_6":
            if (selectedTrack.trackAudioType === "sample-loop") {
                if (selectedTrack.connectedPattern >= 0) {
                    bottomStack.bottomBar.setControlObjByType(selectedTrack.sceneClip, "pattern")
                } else {
                    bottomStack.bottomBar.setControlObjByType(selectedTrack.sceneClip, "clip")
                }

                bottomStack.bottomBar.filePickerDialog.folderModel.folder = bottomStack.bottomBar.controlObj.recordingDir;
                bottomStack.bottomBar.filePickerDialog.open();
                bottomStack.bottomBar.filePickerDialog.open();

                return true
            } else if (selectedTrack.trackAudioType === "synth" ||
                selectedTrack.trackAudioType === "sample-trig" ||
                selectedTrack.trackAudioType === "sample-slice") {
                bottomStack.slotsBar.selectedSlotRowItem.track.selectedSlotRow = 0
                bottomStack.slotsBar.handleItemClick(selectedTrack.trackAudioType)
                return true
            }

            return false

        case "TRACK_2":
        case "TRACK_7":
            if (selectedTrack.trackAudioType === "sample-loop") {
                return true
            } else if (selectedTrack.trackAudioType === "synth" ||
                selectedTrack.trackAudioType === "sample-trig" ||
                selectedTrack.trackAudioType === "sample-slice") {
                bottomStack.slotsBar.selectedSlotRowItem.track.selectedSlotRow = 1
                bottomStack.slotsBar.handleItemClick(selectedTrack.trackAudioType)
                return true
            }

            return false

        case "TRACK_3":
        case "TRACK_8":
            if (selectedTrack.trackAudioType === "sample-loop") {
                return true
            } else if (selectedTrack.trackAudioType === "synth" ||
                selectedTrack.trackAudioType === "sample-trig" ||
                selectedTrack.trackAudioType === "sample-slice") {
                bottomStack.slotsBar.selectedSlotRowItem.track.selectedSlotRow = 2
                bottomStack.slotsBar.handleItemClick(selectedTrack.trackAudioType)
                return true
            }

            return false

        case "TRACK_4":
        case "TRACK_9":
            if (selectedTrack.trackAudioType === "sample-loop") {
                return true
            } else if (selectedTrack.trackAudioType === "synth" ||
                selectedTrack.trackAudioType === "sample-trig" ||
                selectedTrack.trackAudioType === "sample-slice") {
                bottomStack.slotsBar.selectedSlotRowItem.track.selectedSlotRow = 3
                bottomStack.slotsBar.handleItemClick(selectedTrack.trackAudioType)
                return true
            }

            return false

        case "TRACK_5":
        case "TRACK_10":
            if (selectedTrack.trackAudioType === "sample-loop") {
                return true
            } else if (selectedTrack.trackAudioType === "synth" ||
                selectedTrack.trackAudioType === "sample-trig" ||
                selectedTrack.trackAudioType === "sample-slice") {
                bottomStack.slotsBar.selectedSlotRowItem.track.selectedSlotRow = 4
                bottomStack.slotsBar.handleItemClick(selectedTrack.trackAudioType)
                return true
            }

            return false
    }

    return false
}
