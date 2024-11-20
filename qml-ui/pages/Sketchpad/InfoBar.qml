/* -*- coding: utf-8 -*-
 * *****************************************************************************
 * ZYNTHIAN PROJECT: Zynthian Qt GUI
 * 
 * Zynthian Sketchpad info bar page
 * 
 * Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
 * 
 ******************************************************************************
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * For a full copy of the GNU General Public License see the LICENSE.txt file.
 * 
 ******************************************************************************
 */

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

RowLayout {
    id: infoBar
    
    property var clip: null
    Timer {
        id: clipThrottle
        interval: 1; running: false; repeat: false;
        onTriggered: {
            infoBar.clip = root.song.getClip(zynqtgui.sketchpad.selectedTrackId, zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
        }
    }
    Connections {
        target: zynqtgui.sketchpad
        onSelected_track_id_changed: {
            updateSoundNameTimer.restart()
            clipThrottle.restart()
        }
    }
    Connections {
        target: zynqtgui.sketchpad.song.scenesModel
        onSelected_sketchpad_song_index_changed: clipThrottle.restart()
    }
    Component.onCompleted: {
        clipThrottle.restart();
    }
    property int topLayerIndex: 0
    property int topLayer: -1
    property int selectedSoundSlot: zynqtgui.soundCombinatorActive
    ? root.selectedChannel.selectedSlotRow
    : root.selectedChannel.selectedSlotRow
    property int selectedSoundSlotExists: clip.clipChannel.checkIfLayerExists(clip.clipChannel.chainedSounds[selectedSoundSlot])
    property var soundInfo: clip ? clip.clipChannel.chainedSoundsInfo[infoBar.selectedSoundSlot] : []
    
    spacing: Kirigami.Units.gridUnit    
    onClipChanged: updateSoundNameTimer.restart()
    
    function updateInfoBar() {
        var layerIndex = -1;
        var count = 0;
        
        if (infoBar.clip) {
            for (var i in infoBar.clip.clipChannel.chainedSounds) {
                if (infoBar.clip.clipChannel.chainedSounds[i] >= 0 && infoBar.clip.clipChannel.checkIfLayerExists(infoBar.clip.clipChannel.chainedSounds[i])) {
                    if (layerIndex < 0) {
                        layerIndex = i
                    }
                    count++;
                }
            }
        }
        
        layerLabel.layerIndex = layerIndex
        infoBar.topLayerIndex = layerIndex
        infoBar.topLayer = layerIndex == -1 ? -1 : infoBar.clip.clipChannel.chainedSounds[layerIndex]
        layerLabel.layerCount = count
        //                        infoBar.selectedChannel = zynqtgui.soundCombinatorActive
        //                                                    ? infoBar.clip.clipChannel.chainedSounds[root.selectedChannel.selectedSlotRow]
        //                                                    : infoBar.clip.clipChannel.connectedSound

        if (infoBar.clip) {
            infoBar.clip.clipChannel.updateChainedSoundsInfo()
        }
    }

    Timer {
        id: updateSoundNameTimer
        repeat: false
        interval: 10
        onTriggered: infoBar.updateInfoBar()
    }
    
    Connections {
        target: zynqtgui.fixed_layers
        onList_updated: {
            updateSoundNameTimer.restart()
        }
    }
    
    Connections {
        target: zynqtgui.bank
        onList_updated: {
            updateSoundNameTimer.restart()
        }
    }
    
    Connections {
        target: infoBar.clip ? infoBar.clip.clipChannel : null
        onChainedSoundsChanged: {
            updateSoundNameTimer.restart()
        }
        onSelectedSlotRowChanged: {
            updateSoundNameTimer.restart()
        }
    }
    
    QQC2.Label {
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignVCenter
        font.pointSize: 10
        text: qsTr("%1").arg(root.selectedChannel.name)
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                console.log(infoBar.selectedSoundSlot, infoBar.topLayer, JSON.stringify(infoBar.clip.clipChannel.chainedSoundsInfo, null, 2))
            }
        }
    }
    QQC2.Label {
        id: layerLabel
        
        property int layerIndex: -1
        property int layerCount: 0
        
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignVCenter
        font.pointSize: 10
        text: qsTr("Slot %1 %2")
                .arg(root.selectedChannel.selectedSlotRow + 1)
                .arg(layerIndex >= 0
                        ? layerCount > 0
                            ? "(+" + (layerCount-1) + ")"
                            : 0
                        : "")
    }
    QQC2.Label {
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignVCenter
        visible: infoBar.clip && infoBar.clip.clipChannel.trackType === "synth"
        font.pointSize: 10
        text: visible
                ? infoBar.selectedSoundSlotExists
                    ? qsTr("Preset (%2/%3): %1")
                        .arg(infoBar.soundInfo.presetName)
                        .arg(infoBar.soundInfo.presetIndex+1)
                        .arg(infoBar.soundInfo.presetLength)
                    : qsTr("Preset: --")
                : ""
    }
    QQC2.Label {
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignVCenter
        visible: infoBar.clip && infoBar.clip.clipChannel.trackType === "synth"
        font.pointSize: 10
        text: visible
                ? infoBar.selectedSoundSlotExists
                    ? qsTr("Bank: %1").arg(infoBar.soundInfo.bankName)
                    : qsTr("Bank: --")
                : ""
    }
    QQC2.Label {
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignVCenter
        visible: infoBar.clip && infoBar.clip.clipChannel.trackType === "synth"
        font.pointSize: 10
        text: visible
                ? infoBar.selectedSoundSlotExists
                    ? qsTr("Synth: %1").arg(infoBar.soundInfo.synthName)
                    : qsTr("Synth: --")
                : ""
    }
    QQC2.Label {
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignVCenter
        visible: infoBar.clip && infoBar.clip.clipChannel.trackType === "sample-loop"
        font.pointSize: 10
        // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
        text: zynqtgui.isBootingComplete ? qsTr("Clip: %1").arg(infoBar.clip && infoBar.clip.filename && infoBar.clip.filename.length > 0 ? infoBar.clip.filename : "--") : ""
    }
    QQC2.Label {
        property QtObject sample: infoBar.clip && infoBar.clip.clipChannel.samples[infoBar.clip.clipChannel.selectedSlotRow]
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignVCenter
        visible: infoBar.clip && infoBar.clip.clipChannel.trackType === "sample-trig"
        font.pointSize: 10
        // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
        text: zynqtgui.isBootingComplete ? qsTr("Sample (1): %1").arg(sample && sample.filename.length > 0 ? sample.filename : "--") : ""
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    QQC2.Button {
        property var clip: applicationWindow().selectedChannel.getClipsModelById(applicationWindow().selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)

        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
        Layout.alignment: Qt.AlignVCenter
        checkable: true
        visible: clip.clipChannel.trackType == "sample-loop"
        checked: clip.enabled
        text: clip.enabled ? qsTr("Disable Clip") : qsTr("Enable Clip")
        onToggled: {
            clip.enabled = !clip.enabled
        }
    }
    
    QQC2.Button {
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
        Layout.alignment: Qt.AlignVCenter
        icon.name: checked ? "starred-symbolic" : "non-starred-symbolic"
        checkable: true
        visible: infoBar.clip && infoBar.clip.clipChannel.trackType === "synth"
        // Bind to current index to properly update when preset changed from other screen
        checked: zynqtgui.preset.current_index && zynqtgui.preset.current_is_favorite
        onToggled: {
            zynqtgui.preset.current_is_favorite = checked
        }
    }
    // QQC2.Label {
    //     Layout.fillWidth: false
    //     Layout.fillHeight: false
    //     Layout.alignment: Qt.AlignVCenter
    //     font.pointSize: 10
    //     visible: false
    //     Binding {
    //         property: "text"
    //         delayed: true
    //         value: qsTr("%1 %2")
    //                 .arg("T" + (zynqtgui.sketchpad.selectedTrackId+1))
    //                 .arg(infoBar.clip && infoBar.clip.inCurrentScene ? "(Active)" : "")
    //     }
    // }
} 
