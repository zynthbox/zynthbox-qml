/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian recording popup

Copyright (C) 2024 Anupam Basak <anupam.basak27@gmail.com>

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
import QtQml 2.15
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian

Zynthian.Popup {
    id: root
    property QtObject selectedChannel: null
    spacing: Kirigami.Units.gridUnit * 0.5

    Timer {
        id: selectedChannelThrottle
        interval: 1; running: false; repeat: false;
        onTriggered: {
            root.selectedChannel = zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.session_dashboard.selectedChannel)
        }
    }
    Connections {
        target: zynqtgui.session_dashboard
        onSelected_channel_changed: selectedChannelThrottle.restart()
    }
    property var cuiaCallback: function(cuia) {
        var returnValue = false;
        switch (cuia) {
            case "CHANNEL_1":
            case "CHANNEL_2":
            case "CHANNEL_3":
            case "CHANNEL_4":
            case "CHANNEL_5":
            case "NAVIGATE_LEFT":
            case "NAVIGATE_RIGHT":
            case "SELECT_UP":
            case "SELECT_DOWN":
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
            case "SWITCH_SELECT_LONG":
            case "MODE_SWITCH_SHORT":
            case "MODE_SWITCH_BOLD":
            case "MODE_SWITCH_LONG":
            case "KNOB0_TOUCHED":
            case "KNOB0_RELEASED":
            case "KNOB1_UP":
            case "KNOB1_DOWN":
            case "KNOB1_TOUCHED":
            case "KNOB1_RELEASED":
            case "KNOB2_UP":
            case "KNOB2_DOWN":
            case "KNOB2_TOUCHED":
            case "KNOB2_RELEASED":
            case "KNOB3_UP":
            case "KNOB3_DOWN":
            case "KNOB3_TOUCHED":
            case "KNOB3_RELEASED":
                returnValue = true;
                break
            case "KNOB0_UP":
                Zynthbox.SyncTimer.bpm = Zynthbox.SyncTimer.bpm + 1;
                returnValue = true;
                break;
            case "KNOB0_DOWN":
                Zynthbox.SyncTimer.bpm = Zynthbox.SyncTimer.bpm - 1;
                returnValue = true;
                break;

            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                root.close();
                returnValue = true;
                break;
            case "START_RECORD":
                if (zynqtgui.sketchpad.recordingType === "midi") {
                    // Only handle the recording work here if we're recording midi, as audio recording is handled by python logic
                    if (_private.selectedPattern.recordLive) {
                        _private.selectedPattern.liveRecordingSource = midiSourceCombo.model.get(midiSourceCombo.currentIndex).value;
                        _private.selectedPattern.recordLive = false;
                        Zynthian.CommonUtils.stopMetronomeAndPlayback();
                        zynqtgui.sketchpad.isRecording = false;
                    } else {
                        zynqtgui.sketchpad.isRecording = true;
                        _private.selectedPattern.recordLive = true;
                        if (countIn.value > 0) {
                            Zynthbox.SyncTimer.startWithCountin(countIn.value);
                        } else {
                            Zynthian.CommonUtils.startMetronomeAndPlayback();
                        }
                    }
                    returnValue = true;
                }
                break;
        }

        return returnValue;
    }

    parent: QQC2.Overlay.overlay
    y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
    x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
    closePolicy: zynqtgui.sketchpad.isRecording ? QQC2.Popup.NoAutoClose : (QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside)
    width: parent.width * 0.99
    height: parent.height * 0.97
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    onSelectedChannelChanged: {
        if (root.selectedChannel.channelAudioType === "external") {
            zynqtgui.sketchpad.recordingSource = "external"
            zynqtgui.sketchpad.recordingChannel = "*"
        } else {
            zynqtgui.sketchpad.recordingSource = "internal"
        }

        // Reset source combo model to selected value when channel changes
        for (var i=0; i<sourceComboModel.count; i++) {
            if (sourceComboModel.get(i).value === zynqtgui.sketchpad.recordingSource) {
                sourceCombo.currentIndex = i
                break
            }
        }

        for (var i=0; i<recordingChannelComboModel.count; i++) {
            if (recordingChannelComboModel.get(i).value === zynqtgui.sketchpad.recordingChannel) {
                recordingChannelCombo.currentIndex = i
                break
            }
        }
    }
    onOpened: {
        zynqtgui.recordingPopupActive = true

        // Set selectedChannel if not already set
        if (root.selectedChannel == null) {
            selectedChannelThrottle.restart()
        }

        // Ensure that the solo state is restored when we close, but also that it matches what (if any) was set in the dialogue previously
        _private.soloChannelOnOpen = zynqtgui.sketchpad.song.playChannelSolo;
        _private.updateSoloState();
    }
    onClosed: {
        if (zynqtgui.sketchpad.song.playChannelSolo !== _private.soloChannelOnOpen) {
            zynqtgui.sketchpad.song.playChannelSolo = _private.soloChannelOnOpen;
        }
        zynqtgui.recordingPopupActive = false
    }
    contentItem: ColumnLayout {
        anchors.fill: parent
        spacing: root.spacing

        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.leftMargin: root.spacing
            Layout.topMargin: root.spacing
            text: root.selectedChannel && _private.selectedPattern ? qsTr("Record into Clip %1%2 on Track %3").arg(root.selectedChannel.id + 1).arg(_private.selectedPattern.partName).arg(root.selectedChannel.name) : ""
            QtObject {
                id: _private
                readonly property double preferredRowHeight: Kirigami.Units.gridUnit * 2.3
                property QtObject selectedClip: root.selectedChannel ? root.selectedChannel.getClipsModelByPart(root.selectedChannel.selectedSlotRow).getClip(root.selectedChannel.id) : null
                property QtObject selectedSequence: root.selectedChannel ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName) : null
                property QtObject selectedPattern: sequence && root.selectedChannel ? sequence.getByPart(root.selectedChannel.id, root.selectedChannel.selectedPart) : null
                property bool midiSoloTrack: false
                property int soloChannelOnOpen: -1
                property bool armRecording: false
                onMidiSoloTrackChanged: {
                    _private.updateSoloState();
                }
                function updateSoloState() {
                    if (root.visible) {
                        if (zynqtgui.sketchpad.recordingType === "midi" && _private.midiSoloTrack) {
                            zynqtgui.sketchpad.song.playChannelSolo = root.selectedChannel.id;
                        } else {
                            zynqtgui.sketchpad.song.playChannelSolo = -1;
                        }
                    }
                }
            }
            Connections {
                target: zynqtgui.sketchpad
                onRecordingTypeChanged: {
                    _private.updateSoloState();
                }
            }
        }
        Kirigami.Separator {
            Layout.fillWidth: true
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                enabled: zynqtgui.sketchpad.isRecording === false
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: root.spacing

                RowLayout { // Common Settings Section
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                    Layout.maximumHeight: Layout.preferredHeight
                    Layout.minimumHeight: Layout.preferredHeight

                    Zynthian.Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        contentItem: ColumnLayout {
                            QQC2.Switch {
                                Layout.fillHeight: true
                                Layout.alignment: Qt.AlignCenter
                                // Explicitly set indicator implicitWidth otherwise the switch size is too small
                                indicator.implicitWidth: Kirigami.Units.gridUnit * 3
                                checked: zynqtgui.sketchpad.metronomeEnabled
                                onToggled: {
                                    zynqtgui.sketchpad.metronomeEnabled = checked
                                }
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignBottom
                                wrapMode: QQC2.Label.WordWrap
                                horizontalAlignment: QQC2.Label.AlignHCenter
                                text: "Metronome"
                            }
                        }
                    }
                    Zynthian.Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        contentItem: ColumnLayout {
                            RowLayout {
                                id: countIn
                                property int from: 0
                                property int to: 4
                                property int value: zynqtgui.sketchpad.countInBars

                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignCenter
                                onValueChanged: {
                                    if (zynqtgui.sketchpad.countInBars != countIn.value) {
                                        zynqtgui.sketchpad.countInBars = countIn.value;
                                    }
                                }

                                QQC2.Button {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                                    Layout.preferredHeight: width
                                    icon.name: "list-remove-symbolic"
                                    enabled: countIn.value > countIn.from
                                    onClicked: {
                                        countIn.value = Zynthian.CommonUtils.clamp(countIn.value-1, countIn.from, countIn.to)
                                    }
                                }
                                Rectangle {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                    Kirigami.Theme.inherit: false
                                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                    color: Kirigami.Theme.backgroundColor
                                    border.color: "#ff999999"
                                    border.width: 1
                                    radius: 4

                                    QQC2.Label {
                                        anchors.centerIn: parent
                                        text: countIn.value == 0
                                            ? qsTr("Off")
                                            : countIn.value == 1
                                                ? qsTr("1 bar")
                                                : qsTr("%1 Bars").arg(countIn.value)
                                    }
                                }
                                QQC2.Button {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                                    Layout.preferredHeight: width
                                    icon.name: "list-add-symbolic"
                                    enabled: countIn.value < countIn.to
                                    onClicked: {
                                        countIn.value = Zynthian.CommonUtils.clamp(countIn.value+1, countIn.from, countIn.to)
                                    }
                                }
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignBottom
                                wrapMode: QQC2.Label.WordWrap
                                horizontalAlignment: QQC2.Label.AlignHCenter
                                text: "Count In (Bars)"
                            }
                        }
                    }
                    Zynthian.Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        contentItem: RowLayout {
                            Item { Layout.fillHeight: true; Layout.fillWidth: true; }
                            QQC2.Label {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                text: qsTr("BPM:")
                            }
                            Zynthian.SketchpadDial {
                                Layout.fillHeight: true
                                controlObj: Zynthbox.SyncTimer
                                controlProperty: "bpm"
                                fineTuneButtonsVisible: false
                                dial {
                                    stepSize: 1
                                    from: 50
                                    to: 200
                                }
                            }
                            Item { Layout.fillHeight: true; Layout.fillWidth: true; }
                        }
                    }
                }
                ColumnLayout { // Recording Type Specific Settings Section
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 10
                    Layout.topMargin: root.spacing

                    RowLayout {
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                            Layout.preferredHeight: _private.preferredRowHeight
                            checked: zynqtgui.sketchpad.recordingType === "audio"
                            text: qsTr("Record Audio")
                            onClicked: {
                                zynqtgui.sketchpad.recordingType = "audio"
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                            Layout.preferredHeight: _private.preferredRowHeight
                            checked: zynqtgui.sketchpad.recordingType === "midi"
                            text: qsTr("Record Midi")
                            onClicked: {
                                zynqtgui.sketchpad.recordingType = "midi"
                            }
                        }
                    }
                    StackLayout {
                        id: recordingTypeSettingsStack
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: {
                            if (zynqtgui.sketchpad.recordingType === "audio") {
                                return 0
                            } else if (zynqtgui.sketchpad.recordingType === "midi") {
                                return 1
                            } else {
                                return -1
                            }
                        }

                        ColumnLayout {
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                QQC2.Label {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                                    Layout.alignment: Qt.AlignCenter
                                    enabled: parent.enabled
                                    text: qsTr("Source Channel")
                                }
                                Zynthian.ComboBox {
                                    id: channelCombo

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.alignment: Qt.AlignCenter
                                    model: ListModel {
                                        id: channelComboModel

                                        ListElement { text: "Track 1"; value: 0 }
                                        ListElement { text: "Track 2"; value: 1 }
                                        ListElement { text: "Track 3"; value: 2 }
                                        ListElement { text: "Track 4"; value: 3 }
                                        ListElement { text: "Track 5"; value: 4 }
                                        ListElement { text: "Track 6"; value: 5 }
                                        ListElement { text: "Track 7"; value: 6 }
                                        ListElement { text: "Track 8"; value: 7 }
                                        ListElement { text: "Track 9"; value: 8 }
                                        ListElement { text: "Track 10"; value: 9 }
                                    }
                                    textRole: "text"
                                    currentIndex: visible ? zynqtgui.session_dashboard.selectedChannel : -1
                                    onActivated: {
                                        zynqtgui.session_dashboard.selectedChannel = channelComboModel.get(index).value
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.minimumHeight: Layout.preferredHeight
                                    checked: zynqtgui.sketchpad.recordSolo === false
                                    text: qsTr("Play All Enabled Tracks")
                                    onClicked: {
                                        zynqtgui.sketchpad.recordSolo = false;
                                    }
                                }
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.minimumHeight: Layout.preferredHeight
                                    checked: zynqtgui.sketchpad.recordSolo === true
                                    text: root.selectedChannel ? qsTr("Solo Track %1").arg(root.selectedChannel.name) : ""
                                    onClicked: {
                                        zynqtgui.sketchpad.recordSolo = true;
                                    }
                                }
                                QQC2.Button {
                                    visible: false // Keep it invisible until implemented
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.minimumHeight: Layout.preferredHeight
                                    checked: false // which thing
                                    text: root.selectedChannel ? qsTr("No Playback").arg(root.selectedChannel.name) : ""
                                    onClicked: {
                                        // magic stuff what?!
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                QQC2.Label {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                                    Layout.alignment: Qt.AlignCenter
                                    text: qsTr("Audio Source")
                                }
                                Zynthian.ComboBox {
                                    id: sourceCombo

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.alignment: Qt.AlignCenter
                                    model: ListModel {
                                        id: sourceComboModel

                                        ListElement { text: "Internal (Active Track)"; value: "internal-track" }
                                        ListElement { text: "Internal (Master Output)"; value: "internal-master" }
                                        ListElement { text: "External (Audio In)"; value: "external" }
                                    }
                                    currentIndex: 0
                                    textRole: "text"
                                    onActivated: {
                                        if (sourceComboModel.get(index).value === "internal-track") {
                                            zynqtgui.sketchpad.recordingSource = "internal"
                                            zynqtgui.sketchpad.recordMasterOutput = false
                                        } else if (sourceComboModel.get(index).value === "internal-master") {
                                            zynqtgui.sketchpad.recordingSource = "internal"
                                            zynqtgui.sketchpad.recordMasterOutput = true
                                        } else if (sourceComboModel.get(index).value === "external") {
                                            zynqtgui.sketchpad.recordingSource = "external"
                                            zynqtgui.sketchpad.recordMasterOutput = false
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                visible: zynqtgui.sketchpad.recordingSource === "external"
                                QQC2.Label {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                                    Layout.alignment: Qt.AlignCenter
                                    text: qsTr("Recording Source")
                                }
                                Zynthian.ComboBox {
                                    id: recordingChannelCombo

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.alignment: Qt.AlignCenter
                                    model: ListModel {
                                        id: recordingChannelComboModel

                                        ListElement { text: "Left Channel"; value: "1" }
                                        ListElement { text: "Right Channel"; value: "2" }
                                        ListElement { text: "Stereo"; value: "*" }
                                    }
                                    textRole: "text"
                                    onActivated: {
                                        zynqtgui.sketchpad.recordingChannel = recordingChannelComboModel.get(index).value
                                    }
                                }
                            }
                        }
                        ColumnLayout {
                            // TODO : Implement midi recording and add midi settings here
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                QQC2.Label {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                                    text: qsTr("Source:")
                                }
                                Zynthian.ComboBox {
                                    id: midiSourceCombo
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    currentIndex: 0
                                    model: ListModel {
                                        id: midiSourcesModel
                                        ListElement { text: "Current Track"; value: "sketchpadTrack:-1" } // -1 is the internal shorthand used for the current track basically everywhere
                                        ListElement { text: "Track 1"; value: "sketchpadTrack:0"; hardwareRow: -1 }
                                        ListElement { text: "Track 2"; value: "sketchpadTrack:1"; hardwareRow: -1 }
                                        ListElement { text: "Track 3"; value: "sketchpadTrack:2"; hardwareRow: -1 }
                                        ListElement { text: "Track 4"; value: "sketchpadTrack:3"; hardwareRow: -1 }
                                        ListElement { text: "Track 5"; value: "sketchpadTrack:4"; hardwareRow: -1 }
                                        ListElement { text: "Track 6"; value: "sketchpadTrack:5"; hardwareRow: -1 }
                                        ListElement { text: "Track 7"; value: "sketchpadTrack:6"; hardwareRow: -1 }
                                        ListElement { text: "Track 8"; value: "sketchpadTrack:7"; hardwareRow: -1 }
                                        ListElement { text: "Track 9"; value: "sketchpadTrack:8"; hardwareRow: -1 }
                                        ListElement { text: "Track 10"; value: "sketchpadTrack:9"; hardwareRow: -1 }
                                    }
                                    textRole: "text"
                                    Zynthbox.FilterProxy {
                                        id: hardwareInputDevices
                                        sourceModel: Zynthbox.MidiRouter.model
                                        filterRole: Zynthbox.MidiRouterDeviceModel.IsHardwareDeviceRole
                                        filterBoolean: true
                                    }
                                    Component.onCompleted: {
                                        for (let newRow = 0; newRow < hardwareInputDevices.count; ++newRow) {
                                            midiSourcesModel.append({
                                                "text": hardwareInputDevices.data(hardwareInputDevices.index(newRow, 0), Zynthbox.MidiRouterDeviceModel.HumanNameRole),
                                                "value": "external:" + hardwareInputDevices.data(hardwareInputDevices.index(newRow, 0), Zynthbox.MidiRouterDeviceModel.HardwareIdRole),
                                                "hardwareRow": newRow
                                            });
                                            // console.log("Adding device", hardwareInputDevices.data(hardwareInputDevices.index(newRow, 0), Zynthbox.MidiRouterDeviceModel.HumanNameRole), "for row", newRow);
                                        }
                                    }
                                    Connections {
                                        target: hardwareInputDevices
                                        onRowsInserted: {
                                            for (let newRow = first; newRow < last + 1; ++newRow) {
                                                let addEntry = true;
                                                for (let ourIndex = 0; ourIndex < midiSourcesModel.count; ++ourIndex) {
                                                    let ourEntry = midiSourcesModel.get(ourIndex);
                                                    if (ourEntry.hardwareRow === newRow) {
                                                        addEntry = false;
                                                        break;
                                                    }
                                                }
                                                if (addEntry) {
                                                    midiSourcesModel.append({
                                                        "text": hardwareInputDevices.data(hardwareInputDevices.index(newRow, 0), Zynthbox.MidiRouterDeviceModel.HumanNameRole),
                                                        "value": "external:" + hardwareInputDevices.data(hardwareInputDevices.index(newRow, 0), Zynthbox.MidiRouterDeviceModel.HardwareIdRole),
                                                        "hardwareRow": newRow
                                                    });
                                                    // console.log("Adding device", hardwareInputDevices.data(hardwareInputDevices.index(newRow, 0), Zynthbox.MidiRouterDeviceModel.HumanNameRole), "for row", newRow);
                                                }
                                            }
                                        }
                                        onRowsRemoved: {
                                            for (let removedRow = first; removedRow < last + 1; ++removedRow) {
                                                for (let ourIndex = 0; ourIndex < midiSourcesModel.count; ++ourIndex) {
                                                    let ourEntry = midiSourcesModel.get(ourIndex);
                                                    if (ourEntry.hardwareRow === removedRow) {
                                                        midiSourcesModel.remove(ourIndex);
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                        onDataChanged: {
                                            for (let changedRow = topLeft.row; changedRow < bottomRight.row + 1; ++changedRow) {
                                                for (let ourIndex = 0; ourIndex < midiSourcesModel.count; ++ourIndex) {
                                                    let ourEntry = midiSourcesModel.get(ourIndex);
                                                    if (ourEntry.hardwareRow === changedRow) {
                                                        midiSourcesModel.set(ourIndex, {
                                                            "text": hardwareInputDevices.data(hardwareInputDevices.index(changedRow, 0), Zynthbox.MidiRouterDeviceModel.HumanNameRole),
                                                            "value": "external:" + hardwareInputDevices.data(hardwareInputDevices.index(changedRow, 0), Zynthbox.MidiRouterDeviceModel.HardwareIdRole),
                                                            "hardwareRow": changedRow
                                                        });
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.minimumHeight: Layout.preferredHeight
                                    checked: _private.midiSoloTrack === false
                                    text: qsTr("Play All Enabled Tracks")
                                    onClicked: {
                                        _private.midiSoloTrack = false;
                                    }
                                }
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.minimumHeight: Layout.preferredHeight
                                    checked: _private.midiSoloTrack === true
                                    text: root.selectedChannel ? qsTr("Solo Track %1").arg(root.selectedChannel.name) : ""
                                    onClicked: {
                                        _private.midiSoloTrack = true;
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.minimumHeight: Layout.preferredHeight
                                    checked: _private.armRecording === false
                                    text: qsTr("Record Immediately")
                                    onClicked: {
                                        _private.armRecording = false;
                                    }
                                    opacity: 0 // TODO Implement arm-to-record
                                    enabled: false
                                }
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: _private.preferredRowHeight
                                    Layout.minimumHeight: Layout.preferredHeight
                                    checked: _private.armRecording === true
                                    text: qsTr("Wait For First Note")
                                    onClicked: {
                                        _private.armRecording = true;
                                    }
                                    opacity: 0 // TODO Implement arm-to-record
                                    enabled: false
                                }
                            }
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                QQC2.Label {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                                    text: qsTr("Step Length:")
                                }
                                QQC2.Button {
                                    Layout.fillWidth: true; Layout.preferredHeight: _private.preferredRowHeight; Layout.minimumHeight: Layout.preferredHeight
                                    checked: _private.selectedPattern ? _private.selectedPattern.noteLength === 1 : false
                                    text: qsTr("1")
                                    onClicked: { _private.selectedPattern.noteLength = 1; }
                                }
                                QQC2.Button {
                                    Layout.fillWidth: true; Layout.preferredHeight: _private.preferredRowHeight; Layout.minimumHeight: Layout.preferredHeight
                                    checked: _private.selectedPattern ? _private.selectedPattern.noteLength === 2 : false
                                    text: qsTr("1/2")
                                    onClicked: { _private.selectedPattern.noteLength = 2; }
                                }
                                QQC2.Button {
                                    Layout.fillWidth: true; Layout.preferredHeight: _private.preferredRowHeight; Layout.minimumHeight: Layout.preferredHeight
                                    checked: _private.selectedPattern ? _private.selectedPattern.noteLength === 3 : false
                                    text: qsTr("1/4")
                                    onClicked: { _private.selectedPattern.noteLength = 3; }
                                }
                                QQC2.Button {
                                    Layout.fillWidth: true; Layout.preferredHeight: _private.preferredRowHeight; Layout.minimumHeight: Layout.preferredHeight
                                    checked: _private.selectedPattern ? _private.selectedPattern.noteLength === 4 : false
                                    text: qsTr("1/8")
                                    onClicked: { _private.selectedPattern.noteLength = 4; }
                                }
                                QQC2.Button {
                                    Layout.fillWidth: true; Layout.preferredHeight: _private.preferredRowHeight; Layout.minimumHeight: Layout.preferredHeight
                                    checked: _private.selectedPattern ? _private.selectedPattern.noteLength === 5 : false
                                    text: qsTr("1/16")
                                    onClicked: { _private.selectedPattern.noteLength = 5; }
                                }
                                QQC2.Button {
                                    Layout.fillWidth: true; Layout.preferredHeight: _private.preferredRowHeight; Layout.minimumHeight: Layout.preferredHeight
                                    checked: _private.selectedPattern ? _private.selectedPattern.noteLength === 6 : false
                                    text: qsTr("1/32")
                                    onClicked: { _private.selectedPattern.noteLength = 6; }
                                }
                                QQC2.Label {
                                    Layout.preferredWidth: _private.preferredRowHeight
                                    text: qsTr("notes")
                                }
                            }
                            RowLayout {
                                Layout.fillHeight: true; Layout.fillWidth: true
                                Layout.preferredHeight: _private.preferredRowHeight
                                QQC2.Label {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                                    text: qsTr("Pattern Length:")
                                }
                                Repeater {
                                    model: 8
                                    QQC2.Button {
                                        Layout.fillWidth: true; Layout.preferredHeight: _private.preferredRowHeight; Layout.minimumHeight: Layout.preferredHeight
                                        checked: _private.selectedPattern ? _private.selectedPattern.availableBars === model.index + 1 : false
                                        text: (model.index + 1)
                                        onClicked: { _private.selectedPattern.availableBars = model.index + 1; }
                                    }
                                }
                                QQC2.Label {
                                    Layout.preferredWidth: _private.preferredRowHeight
                                    text: qsTr("bars")
                                }
                            }
                        }
                    }
                }
                RowLayout { // Post Recording Preview section
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                    Layout.maximumHeight: Layout.preferredHeight
                    Layout.minimumHeight: Layout.preferredHeight
                    spacing: root.spacing

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#222222"
                        border.width: 1
                        border.color: "#ff999999"
                        radius: 4

                        Zynthbox.WaveFormItem {
                            anchors.fill: parent
                            color: Kirigami.Theme.textColor
                            visible: recordingTypeSettingsStack.currentIndex === 0
                            source: "audioLevelsChannel:/ports"
                        }
                        Image {
                            id: patternVisualiser

                            visible: recordingTypeSettingsStack.currentIndex === 1

                            anchors {
                                fill: parent
                                margins: Kirigami.Units.smallSpacing
                            }
                            smooth: false
                            asynchronous: true
                            source: _private.selectedPattern ? _private.selectedPattern.thumbnailUrl : ""
                            Rectangle { // Progress
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                visible: patternVisualiser.visible &&
                                            _private.selectedSequence &&
                                            _private.selectedSequence.isPlaying &&
                                            _private.selectedPattern
                                color: Kirigami.Theme.highlightColor
                                width: widthFactor // this way the progress rect is the same width as a step
                                property double widthFactor: visible && _private.selectedPattern ? parent.width / (_private.selectedPattern.width * _private.selectedPattern.bankLength) : 1
                                x: visible && _private.selectedPattern ? _private.selectedPattern.bankPlaybackPosition * widthFactor : 0
                            }
                            QQC2.Label {
                                anchors {
                                    top: parent.top
                                    right: parent.right
                                    margins: Kirigami.Units.smallSpacing
                                    rightMargin: patternVisualiser.visible ? parent.width * (8 - _private.selectedPattern.availableBars) / 8 : 0
                                }
                                text: patternVisualiser.visible ? "%1s".arg(patternBarsToSeconds(_private.selectedPattern.availableBars, _private.selectedPattern.noteLength, Zynthbox.SyncTimer.bpm).toFixed(2)) : ""
                                function patternBarsToSeconds(patternBars, noteLength, bpm) {
                                    // Set up the loop points in the new recording
                                    let noteLengths = { 1: 32, 2: 16, 3: 8, 4: 4, 5: 2, 6: 1 }
                                    let patternSubbeatToTickMultiplier = (Zynthbox.SyncTimer.getMultiplier() / 32);
                                    // Reset this to beats (rather than pattern subbeats)
                                    let patternDurationInBeats = patternBars * _private.selectedPattern.width * noteLengths[noteLength];
                                    let patternDurationInSeconds = Zynthbox.SyncTimer.subbeatCountToSeconds(bpm, patternDurationInBeats * patternSubbeatToTickMultiplier);
                                    return patternDurationInSeconds;
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.largeSpacing
                            spacing: Kirigami.Units.largeSpacing
                            opacity: 0.7

                            Rectangle {
                                property real audioLevel: {
                                    if (root.visible && root.selectedChannel != null) {
                                        if (zynqtgui.sketchpad.recordingSource === "internal") {
                                            return Zynthbox.AudioLevels.channels[root.selectedChannel.id]
                                        } else if (zynqtgui.sketchpad.recordingSource === "external") {
                                            return Zynthbox.AudioLevels.captureA
                                        } else {
                                            return -100
                                        }
                                    } else {
                                        return -100
                                    }
                                }
                                Layout.preferredWidth: parent.width * Zynthian.CommonUtils.interp(audioLevel, -100, 20, 0, 1)
                                Layout.minimumWidth: Layout.preferredWidth
                                Layout.maximumWidth: Layout.preferredWidth
                                Layout.fillHeight: true
                                color: Kirigami.Theme.highlightColor
                                radius: 100
                            }
                            Rectangle {
                                property real audioLevel: {
                                    if (root.visible && root.selectedChannel != null) {
                                        if (zynqtgui.sketchpad.recordingSource === "internal") {
                                            return Zynthbox.AudioLevels.channels[root.selectedChannel.id]
                                        } else if (zynqtgui.sketchpad.recordingSource === "external") {
                                            return Zynthbox.AudioLevels.captureB
                                        } else {
                                            return -100
                                        }
                                    } else {
                                        return -100
                                    }
                                }
                                Layout.preferredWidth: parent.width * Zynthian.CommonUtils.interp(audioLevel, -100, 20, 0, 1)
                                Layout.minimumWidth: Layout.preferredWidth
                                Layout.maximumWidth: Layout.preferredWidth
                                Layout.fillHeight: true
                                color: Kirigami.Theme.highlightColor
                                radius: 100
                            }
                        }
                    }

                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        icon.name: "edit-clear-symbolic"
                        icon.color: "#ffffffff"
                        onClicked: {
                            switch(recordingTypeSettingsStack.currentIndex) {
                                case 1: // MIDI Recording
                                    if (_private.selectedPattern.hasNotes) {
                                        applicationWindow().confirmClearPattern(root.selectedChannel, _private.selectedPattern);
                                    }
                                    break;
                                case 0: // Audio Recording
                                default:
                                    // Audio Recording has three options:
                                    // - Clear slot and delete recording
                                    // - Clear slot and leave recording
                                    // - Don't clear
                                    break;
                            }
                        }
                    }
                }
            }
            QQC2.Button {
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                Layout.minimumWidth: Layout.preferredWidth
                Layout.rightMargin: root.spacing
                icon.name: zynqtgui.sketchpad.isRecording ? "media-playback-stop" : "media-record-symbolic"
                onClicked: {
                    zynqtgui.callable_ui_action("START_RECORD")
                }
            }
        }
        QQC2.Button {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            text: qsTr("Close")
            onClicked: {
                root.close()
            }
        }
    }
}
