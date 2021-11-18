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
