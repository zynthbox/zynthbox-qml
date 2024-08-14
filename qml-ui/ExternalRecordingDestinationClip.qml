/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

Copyright (C) 2021 Marco Martin <mart@kde.org>

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

import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

ColumnLayout {
    id: component
    objectName: "clipPickerClip"

    property bool isRecording: Zynthbox.AudioLevels.isRecording
    property QtObject recordingSample: null
    property string recordingFilename: ""
    function startRecording() {
        isRecording = true;
        component.recordingSample = component.selectedSample;
        var baseFolder = zynqtgui.sketchpad.song.channelsModel.getChannel(channelsList.currentIndex).bankDir;
        var recordingTimestamp = Zynthbox.Plugin.currentTimestamp();
        var fileNameFriendlyModuleName = zynqtgui.main.currentModuleName.replace(/[^a-z0-9]/gi, '_').toLowerCase();
        component.recordingFilename = baseFolder + "/" + recordingTimestamp + "_" + fileNameFriendlyModuleName + "_" + Zynthbox.SyncTimer.bpm + "-BPM.sketch.wav";
        Zynthbox.AudioLevels.clearRecordPorts();
        // If the current module is an alsa thing, don't use jack to record it and instead record using alsa
        if (zynqtgui.main.currentModuleRecordAlsa === true) {
            zynqtgui.main.start_recording_alsa();
        } else {
            // If the current module's recording ports are empty, record the system output
            if (zynqtgui.main.currentModuleRecordingPortsLeft === "" && zynqtgui.main.currentModuleRecordingPortsRight === "") {
                Zynthbox.AudioLevels.addRecordPort("system:playback_1", 0);
                Zynthbox.AudioLevels.addRecordPort("system:playback_2", 1);
            } else {
                var splitLeftPorts = zynqtgui.main.currentModuleRecordingPortsLeft.split(",");
                for (var i = 0; i < splitLeftPorts.length; ++i) {
                    Zynthbox.AudioLevels.addRecordPort(splitLeftPorts[i], 0);
                }
                var splitRightPorts = zynqtgui.main.currentModuleRecordingPortsRight.split(",");
                for (var i = 0; i < splitRightPorts.length; ++i) {
                    Zynthbox.AudioLevels.addRecordPort(splitRightPorts[i], 1);
                }
            }
            Zynthbox.AudioLevels.setRecordPortsFilenamePrefix(component.recordingFilename);
            Zynthbox.AudioLevels.shouldRecordPorts = true;
            Zynthbox.AudioLevels.startRecording();
        }
    }
    function stopRecording() {
        isRecording = false;
        if (zynqtgui.main.currentModuleRecordAlsa === true) {
            // If we've recorded using alsa, we'll need to move that file into its proper home before we attempt to set it on the clip
            zynqtgui.main.stop_recording_and_move(component.recordingFilename);
        } else {
            Zynthbox.AudioLevels.shouldRecordPorts = false;
            Zynthbox.AudioLevels.stopRecording();
        }
        component.recordingSample.set_path(component.recordingFilename, false);
        component.recordingSample = null;
    }
    property QtObject selectedSample: channelsList.currentItem && channelsList.currentItem.selectedSample ? channelsList.currentItem.selectedSample : null
    property QtObject selectedSampleCppObject: selectedSample === null ? null : Zynthbox.PlayGridManager.getClipById(selectedSample.cppObjId)

    Kirigami.Heading {
        Layout.fillWidth: true
        text: qsTr("Record Into A Sample Slot");
    }
    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: qsTr("Recordings from this module will be stored as the contents of the currently selected sample slot (it will follow the global selection, or you can pick it here). Each time you hit record, the existing contents of the slot will be replaced by the new recording. Note that this will happen without warning, and cannot be undone.")
    }
    GridView {
        id: channelsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        cellWidth: width / 2
        cellHeight: height / 5
        clip: true
        model: 10
        currentIndex: 0
        delegate: QQC2.ItemDelegate {
            width: GridView.view.cellWidth
            height: GridView.view.cellHeight
            property QtObject selectedSample: contentItem.selectedSample
            property int selectedSampleIndex: contentItem.selectedSampleIndex
            contentItem: RowLayout {
                id: delegate
                property QtObject channel: null
                property int channelIndex: index
                Binding {
                    target: delegate
                    property: "channel"
                    value: zynqtgui.sketchpad.song.channelsModel.getChannel(index)
                    when: component.visible
                    delayed: true
                }
                property int selectedSampleIndex: 0
                property QtObject selectedSample: channel && channel.samples ? channel.samples[selectedSampleIndex] : null
                property QtObject selectedSampleCppObject: selectedSample === null ? null : Zynthbox.PlayGridManager.getClipById(selectedSample.cppObjId)
                property int thisIndex: index
                QQC2.Label {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                    text: "Track " + (index+1)
                }
                Repeater {
                    model: 5
                    Zynthian.PlayGridButton {
                        property QtObject sample: delegate.channel && delegate.channel.samples ? delegate.channel.samples[index] : null
                        property QtObject sampleCppObject: sample === null ? null : Zynthbox.PlayGridManager.getClipById(sample.cppObjId)
                        Layout.preferredWidth: index === 0 ? Kirigami.Units.gridUnit * 5 : Kirigami.Units.gridUnit * 2
                        text: index === 0 ? "Sample " + (index+1) : (index+1)
                        icon.name: (sampleCppObject === null ? "empty" : "audio-x-generic")
                        checked: channelsList.currentIndex === delegate.thisIndex && delegate.selectedSampleIndex === index
                        function setCurrent() {
                            delegate.selectedSample = sample;
                            delegate.selectedSampleIndex = index;
                            channelsList.currentIndex = delegate.thisIndex;
                        }
                        property bool performCurrentCheck: false;
                        function checkCurrent() {
                            if (zynqtgui.sketchpad.selectedTrackId === delegate.channelIndex && delegate.channel != null && delegate.channel.selectedSlotRow === index) {
                                setCurrent();
                            }
                        }
                        Timer {
                            id: checkCurrentTimer
                            interval: 1; repeat: false; running: false;
                            onTriggered: {
                                if (root.visible) {
                                    checkCurrent();
                                } else {
                                    performCurrentCheck = true;
                                }
                            }
                        }
                        Connections {
                            target: zynqtgui.sketchpad
                            onSelected_track_id_changed: checkCurrentTimer.restart()
                        }
                        Connections {
                            target: delegate.channel
                            onSelectedSlotRowChanged: checkCurrentTimer.restart()
                        }
                        Connections {
                            target: root
                            onVisibleChanged: {
                                if (performCurrentCheck) {
                                    checkCurrent();
                                }
                            }
                        }
                        onClicked: {
                            zynqtgui.sketchpad.selectedTrackId = delegate.channelIndex;
                            delegate.channel.selectedSlotRow = index;
                        }
                    }
                }
            }
        }
    }
    Kirigami.AbstractCard {
        Layout.fillWidth: true
        header: Kirigami.Heading {
            text: channelsList.currentItem ? qsTr("Recording to sample %1 on Channel %2").arg(channelsList.currentItem.selectedSampleIndex + 1).arg(channelsList.currentIndex + 1) : ""
        }
        contentItem: ColumnLayout {
            RowLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    Layout.fillWidth: true
                    text: component.selectedSampleCppObject === null ? qsTr("No sample in selected slot. Hit Record to record something.") : qsTr("Current sample duration: %1 seconds").arg(component.selectedSample.duration.toFixed(2))
                }
                Zynthian.PlayGridButton {
                    property bool isPlaying: component.selectedSample && component.selectedSample.isPlaying
                    enabled: component.selectedSampleCppObject !== null
                    text: isPlaying ? qsTr("Stop") : qsTr("Play")
                    icon.name: isPlaying ? "media-playback-stop-symbolic" : "media-playback-start-symbolic"
                    onClicked: {
                        if (isPlaying) {
                            component.selectedSample.stop_audio();
                        } else {
                            component.selectedSample.play_audio(false);
                        }
                    }
                }
            }
            Zynthian.SampleVisualiser {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                sample: component.selectedSample
                trackType: root.selectedChannel.trackType
            }
        }
    }
}
