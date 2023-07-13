/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Sketch Unbouncer, for unbouncing sketches (write the sketch source into sound setup and pattern)

Copyright (C) 2023 Dan Leinir Turthra Jensen <admin@leinir.dk>

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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami
import Zynthian 1.0 as Zynthian

Zynthian.DialogQuestion {
    id: component
    function unbounce(clip, channel, slot) {
        _private.clip = clip;
        _private.channel = channel;
        _private.slot = slot;


        // If there's notes in the pattern, ask first
        // If there is synth information in the sketch, ask first
        // If there is sample information in the sketch, ask first
        // All the above should be one question, not multiple popups (ask to be safe, but don't be obnoxious)
        if (replaceSounds.visible || replaceSamples.visible || replacePattern.visible) {
            component.open();
        } else {
            performUnbounce();
        }
    }
    onAccepted: {
        _private.performUnbounce();
    }
    title: qsTr("Unbounce Sketch?")
    contentItem: ColumnLayout {
        QQC2.Label {
            Layout.fillWidth: true
            text: qsTr("Performing this unbounce will overwrite some of the existing things. Untick the ones you don't want to overwrite and then tap yes, or just tap no to not unbounce.")
            QtObject {
                id: _private
                property QtObject clip
                property QtObject channel
                property int slot
                property QtObject audioSource: clip ? Zynthian.PlayGridManager.getClipById(clip.cppObjId) : null
                property QtObject sequence: channel ? Zynthbox.PlayGridManager.getSequenceModel("T" + channel.id) : null
                property QtObject pattern: sequence && channel ? sequence.getByPart(channel.id, slot) : null
                function performUnbounce() {
                    if (clip.metadataAudioType === "sample-trig") {
                        root.selectedChannel.channelAudioType = "sample-trig";
                    } else if (clip.metadataAudioType === "synth") {
                        root.selectedChannel.channelAudioType = "synth";
                    }
                    if (replaceSamples.checked) {
                        channel.setChannelSamplesFromSnapshot(clip.metadataSamples);
                    }
                }
            }
        }
        QQC2.CheckBox {
            id: replacePattern
            text: qsTr("Replace pattern contents of clip %2 with what's in the sketch").arg(_private.slot)
            visible: pattern && pattern.hasNotes && _private.clip && _private.clip.metadataMidiRecording != null && _private.clip.metadataMidiRecording.length > 10
        }
        QQC2.CheckBox {
            id: replaceSounds
            text: qsTr("Replace the track's synth and effect setup with the sketch")
            visible: _private.channel && _private.channel.getChannelSoundSnapshotJson().length > 0 && _private.clip && _private.clip.sketchContainsSound
        }
        QQC2.CheckBox {
            id: replaceSamples
            text: qsTr("Replace the track's sample selection with what's contained in the sketch")
            visible: _private.channel && _private.channel.occupiedSampleSlotsCount > 0 && _private.clip && _private.clip.sketchContainsSamples
        }
    }
}
