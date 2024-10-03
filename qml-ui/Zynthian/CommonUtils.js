.import io.zynthbox.components 1.0 as Zynthbox

function startMetronomeAndPlayback() {
    if (Zynthbox.SyncTimer.timerRunning) {
        console.log("Start was requested while we were playing, not going to try and start");
    } else {
        // Contextually work out whether we should start in song mode or not
        // Logic is that alt+play starts song mode playback everywhere, except for when the song manager
        // page is shown, where we invert that logic and allow you to start in not song mode using
        // alt+play and play on its own starts playback in song mode.
        var playInSongMode = false;
        if (zynqtgui.forceSongMode === true) {
            playInSongMode = true;
            zynqtgui.forceSongMode = false;
        } else if (zynqtgui.current_screen_id === "song_manager") {
            if (zynqtgui.altButtonPressed === false) {
                playInSongMode = true;
            }
        } else if (zynqtgui.altButtonPressed) {
            playInSongMode = true;
        }

        if (zynqtgui.sketchpad.ongoingCountIn > 0) {
            zynqtgui.sketchpad.ongoingCountIn = 0;
            Zynthbox.SyncTimer.startWithCountin(zynqtgui.sketchpad.countInBars, playInSongMode);
        } else {
            if (playInSongMode) {
                Zynthbox.SyncTimer.scheduleStartPlayback(0, true, 0, 0);
            } else {
                Zynthbox.SyncTimer.scheduleStartPlayback(0);
            }
        }
    }
}

function stopMetronomeAndPlayback() {
    if (Zynthbox.SyncTimer.timerRunning) {
        if (zynqtgui.metronomeButtonPressed) {
            // Schedule a stop at the end of the current bar
            Zynthbox.SyncTimer.scheduleStopPlayback(Zynthbox.SyncTimer.delayFor(Zynthbox.SyncTimer.CurrentBarEndPosition));
            // console.log("Stopping playback after", Zynthbox.SyncTimer.delayFor(Zynthbox.SyncTimer.CurrentBarEndPosition), "ticks, based on position", Zynthbox.SyncTimer.CurrentBarEndPosition, "meaning the next bar is at", Zynthbox.SyncTimer.cumulativeBeat() + Zynthbox.SyncTimer.delayFor(Zynthbox.SyncTimer.CurrentBarEndPosition) + 1);
        } else {
            Zynthbox.SyncTimer.scheduleStopPlayback(0);
        }
    } else {
        console.log("Stop was requested while already stopped, not scheduling a stop");
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

/**
 * Position some position (from 0 through 1) in a window at the same
 * relative position inside the new position given by the start and
 * end points (given as relative positions from 0 through 1 based on
 * the logical start and end points of the position's original window)
 */
function fitInWindow(originalX, windowStart, windowEnd) {
    let movedX = originalX - windowStart;
    let windowSize = windowEnd - windowStart;
    let windowRatio = windowSize / 1;
    return movedX / windowRatio;
}
