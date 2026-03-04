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
    id: root
    function switchTrackType(track, newTrackType) {
        _private.selectedTrack = track;
        _private.newTrackType = newTrackType;
        _private.hasUnusedSamples = false;
        // When switching track type
        let shouldWarn = false;
        // If we are switching to a track type which would cause some fields to be hidden, we need to warn people of that as well
        // console.log(_private.selectedTrack.trackType, newTrackType, _private.selectedTrack.channelHasSynth, _private.selectedTrack.channelHasFx);
        if (_private.selectedTrack.trackType === "synth" && newTrackType !== "synth" && _private.selectedTrack.channelHasSynth) {
            shouldWarn = true;
        }
        if (_private.selectedTrack.trackType === "synth" && ["sample-loop", "external"].includes(newTrackType) && _private.selectedTrack.channelHasFx) {
            shouldWarn = true;
        }
        if (_private.selectedTrack.trackType === "sample-trig" && newTrackType !== "sample-trig") {
            for (let sampleIndex = Zynthbox.Plugin.sketchpadSlotCount - 1; sampleIndex < Zynthbox.Plugin.sketchpadSlotCount * 2; ++sampleIndex) {
                if (_private.selectedTrack.samples[sampleIndex].isEmpty === false) {
                    _private.hasUnusedSamples = true;
                    shouldWarn = true;
                    break;
                }
            }
        }
        if (["synth", "sample-trig"].includes(_private.selectedTrack.trackType) && ["sample-loop", "external"].includes(newTrackType)) {
            for (let sampleIndex = 0; sampleIndex < Zynthbox.Plugin.sketchpadSlotCount * 2; ++sampleIndex) {
                console.log("Sample at index", sampleIndex, "is empty", _private.selectedTrack.samples[sampleIndex].isEmpty)
                if (_private.selectedTrack.samples[sampleIndex].isEmpty === false) {
                    _private.hasUnusedSamples = true;
                    shouldWarn = true;
                    break;
                }
            }
        }
        if (shouldWarn) {
            root.open();
        } else {
            root.accept();
        }
    }

    property var cuiaCallback: function(cuia) {
        var returnValue = root.opened;
        // console.log("TrackClearOnSwitchDialog cuia:", cuia);
        switch (cuia) {
        case "KNOB3_UP":
            returnValue = true;
            break;
        case "KNOB3_DOWN":
            returnValue = true;
            break;
        case "SWITCH_BACK_RELEASED":
            root.reject();
            returnValue = true;
            break;
        case "SWITCH_SELECT_RELEASED":
            root.accept();
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
            // First clean up if there's anything that would end up unused (since we have been asked to just do that if we got to here)
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
        }
    }

    // contentItem: ColumnLayout {
    property QtObject _private: QtObject {
            // id: _private
            property QtObject selectedTrack
            property string newTrackType
            property bool hasUnusedSamples: false
        }
        // QQC2.Label {
            // // TODO When we get sample-loop back... we'll need to ensure we make that a bit more properly clear (switching to we'll have to clean out everything, similarly from)
        // }
    // }
    text: {
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
