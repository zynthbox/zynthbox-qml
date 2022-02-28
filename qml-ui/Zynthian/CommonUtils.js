.import org.zynthian.quick 1.0 as ZynQuick

function startMetronomeAndPlayback() {
    console.log("Starting Metronome and Playback");
    var sequence = ZynQuick.PlayGridManager.getSequenceModel("Scene " + zynthian.zynthiloops.song.scenesModel.selectedSceneName);
    if (sequence) {
        // First, explicitly turn off any Patterns which are not assigned a Track - otherwise
        // we'll end up confusing people by playing back stuff where we don't know where the
        // notes should be going, and that just wouldn't be cool.
        for (var j = 0; j < sequence.rowCount(); ++j) {
            var pattern = sequence.get(j);
            var foundIndex = -1;
            for(var i = 0; i < zynthian.zynthiloops.song.tracksModel.count; ++i) {
                var track = zynthian.zynthiloops.song.tracksModel.getTrack(i);
                if (track && track.connectedPattern === j) {
                    foundIndex = i;
                    break;
                }
            }
            if (foundIndex === -1) {
                pattern.enabled = false;
            }
        }
        sequence.prepareSequencePlayback();
    } else {
        console.debug("Sequence could not be fetched, and playback could not be prepared");
    }
    zynthian.zynthiloops.startPlayback();
    console.log("Metronome and Playback Started");
}

function stopMetronomeAndPlayback() {
    console.log("Stopping Metronome and Playback");
    var sequence = ZynQuick.PlayGridManager.getSequenceModel("Scene " + zynthian.zynthiloops.song.scenesModel.selectedSceneName);
    if (sequence) {
        sequence.stopSequencePlayback();
    } else {
        console.log("Sequence could not be fetched, and playback could not be stopped");
    }

    if (zynthian.zynthiloops.clipToRecord) {
        var clip = zynthian.zynthiloops.clipToRecord
        clip.stopRecording()
        zynthian.zynthiloops.song.scenesModel.addClipToCurrentScene(clip)
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
    var sceneTimer = new Timer();
    sceneTimer.interval = 0;
    sceneTimer.repeat = false;
    sceneTimer.triggered.connect(function () {
        var sequence = ZynQuick.PlayGridManager.getSequenceModel("Scene " + zynthian.zynthiloops.song.scenesModel.selectedSceneName);
        if (sequence) {
            sequence.disconnectSequencePlayback();
        } else {
            console.log("Sequence could not be fetched, and playback could not be stopped");
        }

        zynthian.zynthiloops.song.scenesModel.stopScene(zynthian.zynthiloops.song.scenesModel.selectedSceneIndex);
        zynthian.zynthiloops.song.scenesModel.selectedSceneIndex = index;
        zynthian.zynthiloops.selectedClipCol = index;

        sequence = ZynQuick.PlayGridManager.getSequenceModel("Scene " + zynthian.zynthiloops.song.scenesModel.selectedSceneName);
        if (sequence) {
            sequence.prepareSequencePlayback();
        } else {
            console.log("Sequence could not be fetched, and playback could not be stopped");
        }
    })
    sceneTimer.start();
}

function Timer() {
    return Qt.createQmlObject("import QtQuick 2.0; Timer {}", root);
}
