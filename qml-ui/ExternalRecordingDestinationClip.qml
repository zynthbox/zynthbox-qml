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
import libzl 1.0 as ZL
import org.zynthian.quick 1.0 as ZynQuick
import JuceGraphics 1.0

ColumnLayout {
    id: component
    objectName: "clipPickerClip"

    property bool isRecording: ZL.AudioLevels.isRecording
    property QtObject recordingSample: null
    property string recordingFilename: ""
    function startRecording() {
        isRecording = true;
        component.recordingSample = component.selectedSample;
        var baseFolder = zynthian.sketchpad.song.channelsModel.getChannel(channelsList.currentIndex).bankDir;
        var date = new Date();
        var recordingTimestamp = date.toLocaleString(Qt.locale(), "yyyyMMdd-HHmm");
        var fileNameFriendlyModuleName = zynthian.main.currentModuleName.replace(/[^a-z0-9]/gi, '_').toLowerCase();
        component.recordingFilename = baseFolder + "/" + recordingTimestamp + "_" + fileNameFriendlyModuleName + "_" + zynthian.sketchpad.song.bpm + "-BPM.clip.wav";
        ZL.AudioLevels.clearRecordPorts();
        // If the current module is an alsa thing, don't use jack to record it and instead record using alsa
        if (zynthian.main.currentModuleRecordAlsa === true) {
            zynthian.main.start_recording_alsa();
        } else {
            // If the current module's recording ports are empty, record the system output
            if (zynthian.main.currentModuleRecordingPortsLeft === "" && zynthian.main.currentModuleRecordingPortsRight === "") {
                ZL.AudioLevels.addRecordPort("system:playback_1", 0);
                ZL.AudioLevels.addRecordPort("system:playback_2", 1);
            } else {
                var splitLeftPorts = zynthian.main.currentModuleRecordingPortsLeft.split(",");
                for (var i = 0; i < splitLeftPorts.length; ++i) {
                    ZL.AudioLevels.addRecordPort(splitLeftPorts[i], 0);
                }
                var splitRightPorts = zynthian.main.currentModuleRecordingPortsRight.split(",");
                for (var i = 0; i < splitRightPorts.length; ++i) {
                    ZL.AudioLevels.addRecordPort(splitRightPorts[i], 1);
                }
            }
            ZL.AudioLevels.setRecordPortsFilenamePrefix(component.recordingFilename);
            ZL.AudioLevels.shouldRecordPorts = true;
            ZL.AudioLevels.startRecording();
        }
    }
    function stopRecording() {
        isRecording = false;
        if (zynthian.main.currentModuleRecordAlsa === true) {
            // If we've recorded using alsa, we'll need to move that file into its proper home before we attempt to set it on the clip
            zynthian.main.stop_recording_and_move(component.recordingFilename);
        } else {
            ZL.AudioLevels.shouldRecordPorts = false;
            ZL.AudioLevels.stopRecording();
        }
        component.recordingSample.set_path(component.recordingFilename, false);
        component.recordingSample = null;
    }
    property QtObject selectedSample: channelsList.currentItem && channelsList.currentItem.selectedSample ? channelsList.currentItem.selectedSample : null
    property QtObject selectedSampleCppObject: selectedSample === null ? null : ZynQuick.PlayGridManager.getClipById(selectedSample.cppObjId)

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
                    value: zynthian.sketchpad.song.channelsModel.getChannel(index)
                    when: component.visible
                    delayed: true
                }
                property int selectedSampleIndex: 0
                property QtObject selectedSample: channel && channel.samples ? channel.samples[selectedSampleIndex] : null
                property QtObject selectedSampleCppObject: selectedSample === null ? null : ZynQuick.PlayGridManager.getClipById(selectedSample.cppObjId)
                property int thisIndex: index
                QQC2.Label {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                    text: "Channel " + (index+1)
                }
                Repeater {
                    model: 5
                    Zynthian.PlayGridButton {
                        property QtObject sample: delegate.channel && delegate.channel.samples ? delegate.channel.samples[index] : null
                        property QtObject sampleCppObject: sample === null ? null : ZynQuick.PlayGridManager.getClipById(sample.cppObjId)
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
                            if (zynthian.session_dashboard.selectedChannel === delegate.channelIndex && delegate.channel.selectedSlotRow === index) {
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
                            target: zynthian.session_dashboard
                            onSelectedChannelChanged: checkCurrentTimer.restart()
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
                            zynthian.session_dashboard.selectedChannel = delegate.channelIndex;
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
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                clip: true
                Rectangle {
                    anchors.fill: parent
                    color: "#222222"
                    border.width: 1
                    border.color: "#ff999999"
                    radius: 4
                }
                WaveFormItem {
                    anchors.fill: parent
                    color: Kirigami.Theme.textColor
                    Binding {
                        target: parent
                        property: "source"
                        value: component.selectedSample ? component.selectedSample.path : ""
                        when: parent.visible
                        delayed: true
                    }

                    visible: component.visible && component.selectedSample && component.selectedSample.path && component.selectedSample.path.length > 0

                    // Mask for wave part before start
                    Rectangle {
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: parent.left
                            right: startLoopLine.left
                        }
                        color: "#99000000"
                    }

                    // Mask for wave part after
                    Rectangle {
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: endLoopLine.right
                            right: parent.right
                        }
                        color: "#99000000"
                    }

                    // Start loop line
                    Rectangle {
                        id: startLoopLine
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                        }
                        color: Kirigami.Theme.positiveTextColor
                        opacity: 0.6
                        width: Kirigami.Units.smallSpacing
                        x: component.selectedSample ? (component.selectedSample.startPosition / component.selectedSample.duration) * parent.width : 0
                    }

                    // End loop line
                    Rectangle {
                        id: endLoopLine
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                        }
                        color: Kirigami.Theme.neutralTextColor
                        opacity: 0.6
                        width: Kirigami.Units.smallSpacing
                        x: component.selectedSample ? ((((60/zynthian.sketchpad.song.bpm) * component.selectedSample.length) / component.selectedSample.duration) * parent.width) + ((component.selectedSample.startPosition / component.selectedSample.duration) * parent.width) : 0
                    }

                    // Progress line
                    Rectangle {
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                        }
                        visible: root.visible && component.selectedSample.isPlaying
                        color: Kirigami.Theme.highlightColor
                        width: Kirigami.Units.smallSpacing
                        x: visible ? component.selectedSample.progress/component.selectedSample.duration * parent.width : 0
                    }

                    // SamplerSynth progress dots
                    Repeater {
                        property QtObject cppClipObject: parent.visible ? ZynQuick.PlayGridManager.getClipById(component.selectedSample.cppObjId) : null;
                        model: (root.visible && root.selectedChannel.channelAudioType === "sample-slice" || root.selectedChannel.channelAudioType === "sample-trig") && cppClipObject
                            ? cppClipObject.playbackPositions
                            : 0
                        delegate: Item {
                            Rectangle {
                                anchors.centerIn: parent
                                rotation: 45
                                color: Kirigami.Theme.highlightColor
                                width: Kirigami.Units.largeSpacing
                                height:  Kirigami.Units.largeSpacing
                                scale: 0.5 + model.positionGain
                            }
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.floor(model.positionProgress * parent.width)
                        }
                    }
                }
            }
        }
    }
}
