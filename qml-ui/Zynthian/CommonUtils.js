.import org.zynthian.quick 1.0 as ZynQuick

function startMetronomeAndPlayback() {
    zynthian.zynthiloops.startPlayback();
    ZynQuick.PlayGridManager.getSequenceModel("Global").startSequencePlayback();
}

function stopMetronomeAndPlayback() {
    zynthian.zynthiloops.stopAllPlayback();
    ZynQuick.PlayGridManager.getSequenceModel("Global").stopSequencePlayback();
    zynthian.playgrid.stopMetronomeRequest();
    zynthian.song_arranger.stop();
    zynthian.zynthiloops.resetMetronome();
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
}
