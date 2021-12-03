.import org.zynthian.quick 1.0 as ZynQuick

function startMetronomeAndPlayback() {
    console.log("Starting Metronome and Playback");
    var sequence = ZynQuick.PlayGridManager.getSequenceModel("Global");
    if (sequence) {
        sequence.startSequencePlayback();
    } else {
        console.debug("Sequence could not be fetched, and playback could not be started");
    }
    zynthian.zynthiloops.startPlayback();
    console.log("Metronome and Playback Started");
}

function stopMetronomeAndPlayback() {
    console.log("Stopping Metronome and Playback");
    var sequence = ZynQuick.PlayGridManager.getSequenceModel("Global");
    if (sequence) {
        sequence.stopSequencePlayback();
    } else {
        console.log("Sequence could not be fetched, and playback could not be started");
    }
    zynthian.zynthiloops.stopAllPlayback();
    zynthian.zynthiloops.stopRecording();
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
