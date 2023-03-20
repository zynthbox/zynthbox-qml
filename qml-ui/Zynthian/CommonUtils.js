.import org.zynthian.quick 1.0 as ZynQuick

function startMetronomeAndPlayback() {
    // Contextually work out whether we should start in song mode or not
    // Logic is that alt+play starts song mode playback everywhere, except for when the song manager
    // page is shown, where we invert that logic and allow you to start in not song mode using
    // alt+play and play on its own starts playback in song mode.
    var playInSongMode = false;
    if (zynthian.current_screen_id === "song_manager") {
        if (zynthian.altButtonPressed === false) {
            playInSongMode = true;
        }
    } else if (zynthian.altButtonPressed) {
        playInSongMode = true;
    }
    zynthian.sketchpad.song.sketchesModel.songMode = playInSongMode;

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
        zynthian.callable_ui_action("ALL_NOTES_OFF")
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
        zynthian.callable_ui_action("ALL_NOTES_OFF")
        zynthian.playgrid.stopMetronomeRequest();
        zynthian.song_arranger.stop();
        zynthian.sketchpad.resetMetronome();
        console.log("Metronome and Playback Stopped");
    }
    zynthian.sketchpad.song.sketchesModel.songMode = false;
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

// Method to instantiate a component from URL
// Returns the created object
function instantiateComponent(url, params) {
    console.log("Instantiating component :", url)

    var start = Date.now()
    var component = Qt.createComponent(url);
    var obj = component.createObject(applicationWindow(), params)
    var end = Date.now()

    console.log("Time to load " + url + " : " + (end - start) + "ms")

    if (component.errorString() != "") {
        console.log("Error instantiating component", url, ":", component.errorString());
    } else {
        console.log("Component object created :", url)
    }
    
    return obj
}
