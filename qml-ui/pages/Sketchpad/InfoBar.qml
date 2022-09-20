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
    
    property var clip: root.song.getClip(zynthian.session_dashboard.selectedChannel, zynthian.sketchpad.song.scenesModel.selectedTrackIndex)
    property int topLayerIndex: 0
    property int topLayer: -1
    property int selectedSoundSlot: zynthian.soundCombinatorActive
    ? root.selectedChannel.selectedSlotRow
    : root.selectedChannel.selectedSlotRow
    property int selectedSoundSlotExists: clip.clipChannel.checkIfLayerExists(clip.clipChannel.chainedSounds[selectedSoundSlot])
    
    spacing: Kirigami.Units.gridUnit    
    onClipChanged: updateSoundNameTimer.restart()
    
    function updateInfoBar() {
        var layerIndex = -1;
        var count = 0;
        
        if (infoBar.clip) {
            for (var i in infoBar.clip.clipChannel.chainedSounds) {
                if (infoBar.clip.clipChannel.chainedSounds[i] >= 0 &&
                    infoBar.clip.clipChannel.checkIfLayerExists(infoBar.clip.clipChannel.chainedSounds[i])) {
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
        //                        infoBar.selectedChannel = zynthian.soundCombinatorActive
        //                                                    ? infoBar.clip.clipChannel.chainedSounds[root.selectedChannel.selectedSlotRow]
        //                                                    : infoBar.clip.clipChannel.connectedSound
        
        infoBar.clip.clipChannel.updateChainedSoundsInfo()
    }
    
    Timer {
        id: updateSoundNameTimer
        repeat: false
        interval: 10
        onTriggered: infoBar.updateInfoBar()
    }
    
    Connections {
        target: zynthian.fixed_layers
        onList_updated: {
            updateSoundNameTimer.restart()
        }
    }
    
    Connections {
        target: zynthian.session_dashboard
        onSelectedChannelChanged: {
            updateSoundNameTimer.restart()
        }
    }
    
    Connections {
        target: zynthian.bank
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
        visible: infoBar.clip && infoBar.clip.clipChannel.channelAudioType === "synth"
        font.pointSize: 10
        text: visible
                ? infoBar.selectedSoundSlotExists
                    ? qsTr("Preset (%2/%3): %1")
                        .arg(infoBar.clip.clipChannel.chainedSoundsInfo[infoBar.selectedSoundSlot].presetName)
                        .arg(infoBar.clip.clipChannel.chainedSoundsInfo[infoBar.selectedSoundSlot].presetIndex+1)
                        .arg(infoBar.clip.clipChannel.chainedSoundsInfo[infoBar.selectedSoundSlot].presetLength)
                    : qsTr("Preset: --")
                : ""
    }
    QQC2.Label {
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignVCenter
        visible: infoBar.clip && infoBar.clip.clipChannel.channelAudioType === "synth"
        font.pointSize: 10
        text: visible
                ? infoBar.selectedSoundSlotExists
                    ? qsTr("Bank: %1").arg(infoBar.clip.clipChannel.chainedSoundsInfo[infoBar.selectedSoundSlot].bankName)
                    : qsTr("Bank: --")
                : ""
    }
    QQC2.Label {
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignVCenter
        visible: infoBar.clip && infoBar.clip.clipChannel.channelAudioType === "synth"
        font.pointSize: 10
        text: visible
                ? infoBar.selectedSoundSlotExists
                    ? qsTr("Synth: %1").arg(infoBar.clip.clipChannel.chainedSoundsInfo[infoBar.selectedSoundSlot].synthName)
                    : qsTr("Synth: --")
                : ""
    }
    QQC2.Label {
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignVCenter
        visible: infoBar.clip && infoBar.clip.clipChannel.channelAudioType === "sample-loop"
        font.pointSize: 10
        // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
        text: zynthian.isBootingComplete ? qsTr("Clip: %1").arg(infoBar.clip && infoBar.clip.path && infoBar.clip.path.length > 0 ? infoBar.clip.path.split("/").pop() : "--") : ""
    }
    QQC2.Label {
        property QtObject sample: infoBar.clip && infoBar.clip.clipChannel.samples[infoBar.clip.clipChannel.selectedSlotRow]
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignVCenter
        visible: infoBar.clip && (infoBar.clip.clipChannel.channelAudioType === "sample-trig" ||
                 infoBar.clip.clipChannel.channelAudioType === "sample-slice")
        font.pointSize: 10
        // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
        text: zynthian.isBootingComplete ? qsTr("Sample (1): %1").arg(sample && sample.path.length > 0 ? sample.path.split("/").pop() : "--") : ""
    }
    
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
    
    QQC2.Button {
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
        Layout.alignment: Qt.AlignVCenter
        icon.name: checked ? "starred-symbolic" : "non-starred-symbolic"
        checkable: true
        visible: infoBar.clip && infoBar.clip.clipChannel.channelAudioType === "synth"
        // Bind to current index to properly update when preset changed from other screen
        checked: zynthian.preset.current_index && zynthian.preset.current_is_favorite
        onToggled: {
            zynthian.preset.current_is_favorite = checked
        }
    }
    QQC2.Label {
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignVCenter
        font.pointSize: 10
        visible: false
        Binding {
            target: parent
            property: "text"
            delayed: true
            value: qsTr("%1 %2")
                    .arg("T" + (zynthian.session_dashboard.selectedChannel+1))
                    .arg(infoBar.clip && infoBar.clip.inCurrentScene ? "(Active)" : "")
        }
    }
} 
