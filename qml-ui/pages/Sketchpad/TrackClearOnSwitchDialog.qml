/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

A dialog which will optionally display itself when switching between types and warn about destructive changes

Copyright (C) 2026 Dan Leinir Turthra Jensen <admin@leinir.dk>

******************************************************************************

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of
the License, or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

For a full copy of the GNU General Public License see the LICENSE.txt file.

******************************************************************************
*/

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.7 as Kirigami


import io.zynthbox.ui 1.0 as ZUI

import io.zynthbox.components 1.0 as Zynthbox

ZUI.DialogQuestion {
    id: component
    function switchTrackType(track, newTrackType) {
        _private.selectedTrack = track;
        _private.newTrackType = newTrackType;
        _private.hasUnusedSamples = false;
        // When switching track type, make sure that we warn about destructive actions before performing them
        _private.shouldWarn = false;
        // console.log(_private.selectedTrack.trackType, newTrackType, _private.selectedTrack.channelHasSynth, _private.selectedTrack.channelHasFx);
        // For tracks which don't have synths on them (any non-synth track), get rid of the synths
        if (_private.selectedTrack.trackType === "synth" && newTrackType !== "synth" && _private.selectedTrack.channelHasSynth) {
            _private.shouldWarn = true;
        }
        // For any tracks which don't use the standard fx, get rid of those
        // TODO External does use the standard fx... so should we just let people leave them? But then we should probably always show them as well...
        if (["synth", "sample-trig"].includes(_private.selectedTrack.trackType) && ["sample-loop", "external"].includes(newTrackType) && _private.selectedTrack.channelHasFx) {
            _private.shouldWarn = true;
        }
        // For non-sample-trig tracks, the second row is unused and shouldn't be there
        if (_private.selectedTrack.trackType === "sample-trig" && newTrackType !== "sample-trig") {
            for (let sampleIndex = Zynthbox.Plugin.sketchpadSlotCount - 1; sampleIndex < Zynthbox.Plugin.sketchpadSlotCount * 2; ++sampleIndex) {
                if (_private.selectedTrack.samples[sampleIndex].isEmpty === false) {
                    _private.hasUnusedSamples = true;
                    _private.shouldWarn = true;
                    break;
                }
            }
        }
        // For non-synth and non-sample-trig types, we don't use any samples at all, and should also be getting rid of the first row
        if (["synth", "sample-trig"].includes(_private.selectedTrack.trackType) && ["sample-loop", "external"].includes(newTrackType)) {
            for (let sampleIndex = 0; sampleIndex < Zynthbox.Plugin.sketchpadSlotCount; ++sampleIndex) {
                if (_private.selectedTrack.samples[sampleIndex].isEmpty === false) {
                    _private.hasUnusedSamples = true;
                    _private.shouldWarn = true;
                    break;
                }
            }
        }
        // TODO Also warn about sample-loop loops
        if (_private.shouldWarn) {
            component.open();
        } else {
            component.accept();
        }
    }

    property var cuiaCallback: function(cuia) {
        var returnValue = component.opened;
        // console.log("TrackClearOnSwitchDialog cuia:", cuia);
        switch (cuia) {
        case "KNOB3_UP":
            returnValue = true;
            break;
        case "KNOB3_DOWN":
            returnValue = true;
            break;
        case "SWITCH_BACK_RELEASED":
            component.reject();
            returnValue = true;
            break;
        case "SWITCH_SELECT_RELEASED":
            component.accept();
            returnValue = true;
            break;
        }
        return returnValue;
    }
    rejectText: qsTr("Abort")
    acceptText: qsTr("Remove & Switch")
    title: qsTr("Unused Things on Track %1").arg(_private.selectedTrack ? _private.selectedTrack.name : "")
    width: Kirigami.Units.gridUnit * 30
    height: Kirigami.Units.gridUnit * 24

    onAccepted: {
        // Apply the switch suggested by the bits in _private
        if (_private.selectedTrack.trackType !== _private.newTrackType) {
            if (_private.shouldWarn) {
                // Clean up if there's anything that would end up unused (since we have been asked to just do that if we got to here)
                zynqtgui.start_loading_with_message("Cleaning up track...");
                if (_private.selectedTrack.trackType === "synth" && _private.newTrackType !== "synth" && _private.selectedTrack.channelHasSynth) {
                    // Remove all the synths on the track
                    for (let synthIndex = 0; synthIndex < Zynthbox.Plugin.sketchpadSlotCount; ++synthIndex) {
                        let chainedSound = _private.selectedTrack.chainedSounds[synthIndex];
                        if (chainedSound > -1) {
                            _private.selectedTrack.remove_and_unchain_sound(chainedSound);
                        }
                    }
                }
                if (["synth", "sample-trig"].includes(_private.selectedTrack.trackType) && ["sample-loop", "external"].includes(_private.newTrackType) && _private.selectedTrack.channelHasFx) {
                    // Remove the standard effects
                    for (let fxIndex = 0; fxIndex < Zynthbox.Plugin.sketchpadSlotCount; ++fxIndex) {
                        if (_private.selectedTrack.chainedFx[fxIndex]) {
                            _private.selectedTrack.removeFxFromChain(fxIndex);
                        }
                    }
                }
                if (_private.selectedTrack.trackType === "sample-trig" && _private.newTrackType !== "sample-trig") {
                    // Remove unused samples
                    for (let sampleIndex = Zynthbox.Plugin.sketchpadSlotCount - 1; sampleIndex < Zynthbox.Plugin.sketchpadSlotCount * 2; ++sampleIndex) {
                        if (_private.selectedTrack.samples[sampleIndex].isEmpty === false) {
                            _private.selectedTrack.samples[sampleIndex].clear();
                        }
                    }
                }
                if (["synth", "sample-trig"].includes(_private.selectedTrack.trackType) && ["sample-loop", "external"].includes(_private.newTrackType)) {
                    // Remove (more) unused samples
                    for (let sampleIndex = 0; sampleIndex < Zynthbox.Plugin.sketchpadSlotCount; ++sampleIndex) {
                        if (_private.selectedTrack.samples[sampleIndex].isEmpty === false) {
                            _private.selectedTrack.samples[sampleIndex].clear();
                        }
                    }
                }
            }
            // If the old track type doesn't allow for the current track style, switch to one that is allowed
            // That is, sample-trig can have any type, but synth only allows everything and 5columns, and the others only allow everything
            if (_private.selectedTrack.trackType === "sample-trig" && _private.newTrackType === "synth" && ["everything", "one-to-one"].includes(_private.selectedTrack.trackStyle) === false) {
                _private.selectedTrack.trackStyle = "everything";
            }
            if (_private.selectedTrack.trackType === "sample-trig" && _private.selectedTrack.trackStyle !== "everything") {
                _private.selectedTrack.trackStyle = "everything";
            }
            // Now set the new track type
            _private.selectedTrack.trackType = _private.newTrackType;
            switch (_private.newTrackType) {
                case "synth":
                    pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("synth", 0, false);
                    break;
                case "sample-trig":
                    pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sample", 0, false);
                    break;
                case "sample-loop":
                    pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sketch", 0, false);
                    break;
                case "external":
                    pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("external", 0, false);
                    break;
            }
            if (_private.shouldWarn) {
                zynqtgui.stop_loading();
            }
        }
    }

    property QtObject _private: QtObject {
            // id: _private
            property QtObject selectedTrack
            property string newTrackType
            property bool hasUnusedSamples: false
            property bool shouldWarn: false
        }
    text: {
        // TODO When we get sample-loop back... we'll need to ensure we make that a bit more properly clear (switching to we'll have to clean out everything, similarly from)
        let theText = "<p>" + qsTr("Switching the track to %1 means the following items will be unused, and will need removing.").arg(_private.selectedTrack.trackTypeLabel(_private.newTrackType)) + "</p>";
        if (_private.newTrackType !== "synth" && _private.selectedTrack.channelHasSynth) {
            theText = theText + "<br><p><b>" + qsTr("Synths:") + "</b><br> " + qsTr("You have at least one synth engine on the track. While they would not produce sound, they would still be using some amount of processing power.") + "</p>";
        }
        if (_private.newTrackType === "sample-loop" && _private.selectedTrack.channelHasFx) {
            theText = theText + "<br><p><b>" + qsTr("Effects:") + "</b><br> " + qsTr("You have effects set up on the track. While they would not affect the sound of your audio loops, they would still be using some amount of processing power.") + "</p>";
        }
        if (_private.hasUnusedSamples) {
            theText = theText + "<br><p><b>" + qsTr("Samples:") + "</b><br> " + qsTr("You have at least one superfluous sample, which would clutter up your jam.") + "</p>";
        }
        theText = theText + "<br><p>" + qsTr("If you would like to remove these from your track, and then switch to %1, click on Remove & Switch, otherwise you can abort the change and clean up yourself.").arg(_private.selectedTrack.trackTypeLabel(_private.newTrackType)) + "</p>";
        return theText;
    }
}
