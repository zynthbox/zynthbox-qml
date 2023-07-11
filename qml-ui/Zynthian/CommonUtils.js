.import io.zynthbox.components 1.0 as Zynthbox

function startMetronomeAndPlayback() {
    // Contextually work out whether we should start in song mode or not
    // Logic is that alt+play starts song mode playback everywhere, except for when the song manager
    // page is shown, where we invert that logic and allow you to start in not song mode using
    // alt+play and play on its own starts playback in song mode.
    var playInSongMode = false;
    if (zynqtgui.current_screen_id === "song_manager") {
        if (zynqtgui.altButtonPressed === false) {
            playInSongMode = true;
        }
    } else if (zynqtgui.altButtonPressed) {
        playInSongMode = true;
    }

    if (playInSongMode) {
        if (zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.totalBeatDuration > 0) {
            Zynthbox.SegmentHandler.startPlayback(0, 0);
        }
    } else {
        console.log("Starting Metronome and Playback");
        for (var i = 0; i < 10; ++i) {
            var sequence = Zynthbox.PlayGridManager.getSequenceModel("T" + (i+1));
            if (sequence) {
                sequence.prepareSequencePlayback();
            } else {
                console.debug("Sequence could not be fetched, and playback could not be prepared");
            }
        }
        if (zynqtgui.sketchpad.clipToRecord) {
            Zynthbox.MidiRecorder.startRecording(Zynthbox.PlayGridManager.currentMidiChannel, true);
        }
        zynqtgui.sketchpad.startPlayback();
        console.log("Metronome and Playback Started");
    }
}

function stopMetronomeAndPlayback() {
    if (Zynthbox.SegmentHandler.songMode) {
        zynqtgui.sketchpad.stopAllPlayback();
        zynqtgui.callable_ui_action("ALL_NOTES_OFF")
        Zynthbox.SegmentHandler.stopPlayback();
        zynqtgui.sketchpad.resetMetronome();
    } else {
        console.log("Stopping Metronome and Playback");
        for (var i = 0; i < 10; ++i) {
            var sequence = Zynthbox.PlayGridManager.getSequenceModel("T" + (i+1));
            if (sequence) {
                sequence.stopSequencePlayback();
            } else {
                console.log("Sequence could not be fetched, and playback could not be stopped");
            }
        }

        if (zynqtgui.sketchpad.isRecording) {
            Zynthbox.MidiRecorder.stopRecording()
            zynqtgui.sketchpad.lastRecordingMidi = Zynthbox.MidiRecorder.base64TrackMidi(Zynthbox.PlayGridManager.currentMidiChannel)

            if (zynqtgui.sketchpad.recordingType === "audio") {
                zynqtgui.sketchpad.stopAudioRecording()
            } else {
                for (var clipIndex in zynqtgui.sketchpad.clipsToRecord) {
                    var clip = zynqtgui.sketchpad.clipsToRecord[clipIndex]

                    if (!clip.isChannelSample) {
                        var sequence = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName)
                        var pattern = sequence.getByPart(clip.row, clip.part)

                        console.log("Applying pattern to", pattern, " for ", clip, clip.row, clip.col, clip.part)
                        Zynthbox.MidiRecorder.applyToPattern(pattern)
                    }
                }
            }

            zynqtgui.sketchpad.stopRecording()
        }

        zynqtgui.sketchpad.stopAllPlayback();
        zynqtgui.callable_ui_action("ALL_NOTES_OFF")
        zynqtgui.playgrid.stopMetronomeRequest();
        zynqtgui.song_arranger.stop();
        zynqtgui.sketchpad.resetMetronome();
        console.log("Metronome and Playback Stopped");
    }
}

function toggleLayerChaining(layer) {
    if (layer.metadata.midi_cloned) {
        zynqtgui.layer.remove_clone_midi(layer.metadata.midi_channel, layer.metadata.midi_channel + 1);
        zynqtgui.layer.remove_clone_midi(layer.metadata.midi_channel + 1, layer.metadata.midi_channel);
    } else {
        zynqtgui.layer.clone_midi(layer.metadata.midi_channel, layer.metadata.midi_channel + 1);
        zynqtgui.layer.clone_midi(layer.metadata.midi_channel + 1, layer.metadata.midi_channel);
    }
    zynqtgui.layer.ensure_contiguous_cloned_layers();
    zynqtgui.fixed_layers.show();
}

function switchToScene(index) {
    zynqtgui.sketchpad.song.scenesModel.selectedSceneIndex = index
}

/**
 * A helper method to clamp a value between a range
 *
 * @arg val Value to clamp
 * @arg min Minumum value of the range
 * @arg max Maximum value of the range
 * @return Returns value clamped between min and max
 */
function clamp(val, min, max) {
    return Math.max(min, Math.min(max, val))
}

/**
 * A helper method to interporalte a value between from a range to another range
 *
 * @arg num Number to interpolate
 * @arg in_min Minumum value of the input range
 * @arg in_max Maximum value of the input range
 * @arg out_min Minumum value of the output range
 * @arg out_max Maximum value of the output range
 * @return Returns interpolated value
 */
function interp(num, in_min, in_max, out_min, out_max) {
  return (num - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

// Method to instantiate a component from URL
// Returns the created object
function instantiateComponent(url, params) {
    var start = Date.now()
    var component = Qt.createComponent(url);
    var obj = component.createObject(applicationWindow(), params)
    var end = Date.now()
    
    return {
        ttl: end - start,
        url: url,
        params: params,
        errorString: component.errorString(),
        pageObject: obj
    }
}
