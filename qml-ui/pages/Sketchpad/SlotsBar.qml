/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian slots bar page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Marco MArtin <mart@kde.org>

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
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls.Styles 1.4

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Rectangle {
    id: root

    property alias bottomBarButton: bottomBarButton
    property alias channelButton: channelButton
    property alias mixerButton: mixerButton
    property alias partButton: partButton
    property alias synthsButton: synthsButton
    property alias samplesButton: samplesButton
    property alias fxButton: fxButton
    property alias soundCombinatorButton: soundCombinatorButton
    property bool songMode: false;//zynqtgui.sketchpad.song.sketchesModel.songMode
    property bool displaySceneButtons: zynqtgui.sketchpad.displaySceneButtons

    readonly property QtObject song: zynqtgui.sketchpad.song
    readonly property QtObject selectedChannel: applicationWindow().selectedChannel

    // FIXME : Sample picker dialog was having issues when selecting sample for channel T6-T10
    //         Find a proper solution and see if selectedChannel can be used for all cases instead of this
    property QtObject selectedSlotRowItem

    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    function cuiaCallback(cuia) {
        var selectedMidiChannel = root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow]

        switch (cuia) {
            case "SWITCH_SELECT_SHORT":
                handleItemClick()

                return true;

            case "NAVIGATE_LEFT":
                if (zynqtgui.session_dashboard.selectedChannel > 0) {
                    zynqtgui.session_dashboard.selectedChannel -= 1;
                }

                return true;

            case "NAVIGATE_RIGHT":
                if (zynqtgui.session_dashboard.selectedChannel < 9) {
                    zynqtgui.session_dashboard.selectedChannel += 1;
                }

                return true;

            case "SELECT_UP":
                if (root.selectedSlotRowItem.channel.selectedSlotRow > 0) {
                    root.selectedSlotRowItem.channel.selectedSlotRow -= 1
                }

                return true;

            case "SELECT_DOWN":
                if (root.selectedSlotRowItem.channel.selectedSlotRow < 4) {
                    root.selectedSlotRowItem.channel.selectedSlotRow += 1
                }

                return true;

            // Set respective selected row when button 1-5 is pressed or 6(mod)+1-5 is pressed
            case "CHANNEL_1":
            case "CHANNEL_6":
                root.selectedSlotRowItem.channel.selectedSlotRow = 0
                handleItemClick()
                return true

            case "CHANNEL_2":
            case "CHANNEL_7":
                root.selectedSlotRowItem.channel.selectedSlotRow = 1
                handleItemClick()
                return true

            case "CHANNEL_3":
            case "CHANNEL_8":
                root.selectedSlotRowItem.channel.selectedSlotRow = 2
                handleItemClick()
                return true

            case "CHANNEL_4":
            case "CHANNEL_9":
                root.selectedSlotRowItem.channel.selectedSlotRow = 3
                handleItemClick()
                return true

            case "CHANNEL_5":
            case "CHANNEL_10":
                root.selectedSlotRowItem.channel.selectedSlotRow = 4
                handleItemClick()
                return true
            case "KNOB0_UP":
                if (root.synthsButton.checked) {
                    pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(selectedMidiChannel, 1)
                }
                return true;
            case "KNOB0_DOWN":
                if (root.synthsButton.checked) {
                    pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(selectedMidiChannel, -1)
                }
                return true;
            case "KNOB1_UP":
                if (root.synthsButton.checked) {
                    pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(1)
                }
                return true;
            case "KNOB1_DOWN":
                if (root.synthsButton.checked) {
                    pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(-1)
                }
                return true;
            case "KNOB2_UP":
                if (root.synthsButton.checked) {
                    pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(1)
                }
                return true;
            case "KNOB2_DOWN":
                if (root.synthsButton.checked) {
                    pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(-1)
                }
                return true;
        }

        return false;
    }

    function selectConnectedSound() {
        if (root.selectedSlotRowItem.channel.connectedSound >= 0) {
            zynqtgui.fixed_layers.activate_index(root.selectedSlotRowItem.channel.connectedSound);

            if (root.selectedSlotRowItem.channel.connectedPattern >= 0) {
                var pattern = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName).getByPart(root.selectedSlotRowItem.channel.id, root.selectedSlotRowItem.channel.selectedPart);
                pattern.midiChannel = root.selectedSlotRowItem.channel.connectedSound;
            }
        }
    }

    Connections {
        target: applicationWindow()
        onRequestSamplePicker: {
            samplePickerPopup.open();
        }
    }

    function handleItemClick(type) {
        // Type will be used to invoke the respective handler when
        // required from MixedChannelsViewBar or something else in future
        // This allows us to invoke specific handler frmo other page
        // when when the buttons are not checked
        if (!type) {
            type = ""
        }

        if (synthsButton.checked || type === "synth") {
            // Clicked entry is synth
            console.log("handleItemClick : Synth")

            var chainedSound = root.selectedSlotRowItem.channel.chainedSounds[root.selectedSlotRowItem.channel.selectedSlotRow]

            if (zynqtgui.backButtonPressed) {
                // Back is pressed. Clear Slot
                if (root.selectedSlotRowItem.channel.checkIfLayerExists(chainedSound)) {
                    root.selectedSlotRowItem.channel.remove_and_unchain_sound(chainedSound)
                }
            } else {
                layerSetupDialog.open()
            }
        } else if (fxButton.checked) {
            // Clicked entry is fx
            console.log("handleItemClick : FX")

            var chainedSound = root.selectedSlotRowItem.channel.chainedSounds[root.selectedSlotRowItem.channel.selectedSlotRow]

            if (zynqtgui.backButtonPressed) {
                // Back is pressed. Clear Slot
                if (root.selectedSlotRowItem.channel.checkIfLayerExists(chainedSound)) {
                    zynqtgui.start_loading()
                    zynqtgui.fixed_layers.activate_index(chainedSound)
                    zynqtgui.layer_effects.fx_reset_confirmed()
                    zynqtgui.stop_loading()
                }
            } else {
                zynqtgui.fixed_layers.activate_index(chainedSound)
                zynqtgui.layer_options.show();
                var screenBack = zynqtgui.current_screen_id;
                zynqtgui.current_screen_id = "layer_effects";
                root.openBottomDrawerOnLoad = true;
                zynqtgui.forced_screen_back = screenBack;
            }
        } else if (samplesButton.checked || type === "sample-trig" || type === "sample-slice") {
            // Clicked entry is samples
            console.log("handleItemClick : Samples")

            if (zynqtgui.backButtonPressed) {
                // Back is pressed. Clear Slot
                root.selectedSlotRowItem.channel.samples[root.selectedSlotRowItem.channel.selectedSlotRow].clear()
            } else {
                samplePickerPopup.open()
            }
        } else if (type === "sample-loop") {
            console.log("handleItemClick : Audio")

            var clip = root.selectedChannel.getClipsModelByPart(root.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex)

            if (zynqtgui.backButtonPressed) {
                clip.clear()
            } else {
                loopPickerDialog.folderModel.folder = clip.recordingDir
                loopPickerDialog.open()
            }
        } else if (type === "external") {
            console.log("handleItemClick : External")

            externalMidiChannelPicker.pickChannel(root.selectedChannel);
        }
    }
    
    GridLayout {
        rows: 1
        anchors.fill: parent

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true

            Kirigami.Heading {
                visible: false
                text: qsTr("Slots : %1").arg(song.name)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 1

                QQC2.ButtonGroup {
                    buttons: buttonsColumn.children
                }

                ColumnLayout {
                    id: buttonsColumn
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 6

                    //// INVISIBLE BUTTONS

                    QQC2.Button {
                        id: bottomBarButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        checked: bottomStack.currentIndex === 0
                        enabled: !root.songMode && !root.displaySceneButtons
                        text: qsTr("BottomBar")
                        visible: false
                        onCheckedChanged: {
                            if (checked) {
                                if (!root.songMode) {
                                    bottomStack.currentIndex = 0
                                    updateLedVariablesTimer.restart()
                                } else {
                                    partButton.checked = true
                                }
                            }
                        }
                    }

                    QQC2.Button {
                        id: mixerButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        enabled: !root.songMode && !root.displaySceneButtons
                        visible: false
                        text: qsTr("Mixer")
                        onCheckedChanged: {
                            if (checked) {
                                if (!root.songMode) {
                                    bottomStack.currentIndex = 1
                                    updateLedVariablesTimer.restart()
                                } else {
                                    partButton.checked = true
                                }
                            }
                        }
                    }

                    QQC2.Button {
                        id: soundCombinatorButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        enabled: !root.songMode && !root.displaySceneButtons
                        visible: false
                        text: qsTr("Sound Combinator")
                        onCheckedChanged: {
                            if (checked) {
                                if (!root.songMode) {
                                    bottomStack.currentIndex = 5
                                    updateLedVariablesTimer.restart()
                                } else {
                                    partButton.checked = true
                                }
                            }
                        }
                    }

                    //// END INVISIBLE BUTTONS

                    QQC2.Button {
                        id: channelButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        enabled: !root.songMode && !root.displaySceneButtons
                        text: qsTr("Channel")
                        onCheckedChanged: {
                            if (checked) {
                                if (!root.songMode) {
                                    bottomStack.currentIndex = 3
                                    updateLedVariablesTimer.restart()
                                } else {
                                    partButton.checked = true
                                }
                            }
                        }
                    }

                    QQC2.Button {
                        id: partButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        enabled: !root.songMode && !root.displaySceneButtons
                        text: qsTr("Clips")
                        onCheckedChanged: {
                            if (checked) {
                                bottomStack.currentIndex = 4
                                updateLedVariablesTimer.restart()
                            }
                        }
                    }

                    QQC2.Button {
                        id: synthsButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        enabled: !root.songMode && !root.displaySceneButtons
                        text: qsTr("Synths")
                        onCheckedChanged: {
                            if (checked) {
                                if (!root.songMode) {
                                    bottomStack.currentIndex = 2
                                    updateLedVariablesTimer.restart()
                                } else {
                                    partButton.checked = true
                                }
                            }
                        }
                    }

                    QQC2.Button {
                        id: samplesButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        enabled: !root.songMode && !root.displaySceneButtons
                        text: qsTr("Samples")
                        onCheckedChanged: {
                            if (checked) {
                                if (!root.songMode) {
                                    bottomStack.currentIndex = 2
                                    updateLedVariablesTimer.restart()
                                } else {
                                    partButton.checked = true
                                }
                            }
                        }
                    }

                    QQC2.Button {
                        id: fxButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        enabled: !root.songMode && !root.displaySceneButtons
                        text: qsTr("FX")
                        onCheckedChanged: {
                            if (checked) {
                                if (!root.songMode) {
                                    bottomStack.currentIndex = 2
                                    updateLedVariablesTimer.restart()
                                } else {
                                    partButton.checked = true
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    id: channelsSlotsRow

                    property int currentIndex: 0

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 1

                    Repeater {
                        model: root.song.channelsModel

                        delegate: Rectangle {
                            id: channelDelegate

                            property bool highlighted: false
                            Timer {
                                id: channelHighlightedThrottle
                                interval: 1; running: false; repeat: false;
                                onTriggered: {
                                    channelDelegate.highlighted = (index === zynqtgui.session_dashboard.selectedChannel);
                                }
                            }
                            Connections {
                                target: zynqtgui.session_dashboard
                                onSelected_channel_changed: channelHighlightedThrottle.restart()
                            }
                            // Make sure to highlight first column correctly after booting is complete
                            Connections {
                                target: zynqtgui
                                onIsBootingCompleteChanged: channelHighlightedThrottle.restart()
                            }
    //                            property int selectedRow: 0
                            property int channelIndex: index
                            property QtObject channel: zynqtgui.sketchpad.song.channelsModel.getChannel(index)

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: highlighted ? "#22ffffff" : "transparent"
                            border.width: 1
                            border.color: highlighted ? Kirigami.Theme.highlightColor : "transparent"

                            onHighlightedChanged: {
                                if (highlighted) {
                                    root.selectedSlotRowItem = channelDelegate
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.topMargin: 4
                                spacing: 0

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.topMargin: Kirigami.Units.gridUnit * 0.7
                                    Layout.bottomMargin: Kirigami.Units.gridUnit * 0.7
                                    spacing: Kirigami.Units.gridUnit * 0.7

                                    Repeater {
                                        model: 5
                                        delegate: Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.leftMargin: 4
                                            Layout.rightMargin: 4
                                            color: "transparent"
                                            border.width: 2
                                            border.color: channelDelegate.highlighted && channelDelegate.channel.selectedSlotRow === index ? Kirigami.Theme.highlightColor : "transparent"

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    if (zynqtgui.session_dashboard.selectedChannel !== channelDelegate.channelIndex ||
                                                        channelDelegate.channel.selectedSlotRow !== index) {
                                                        channelsSlotsRow.currentIndex = index
                                                        channelDelegate.channel.selectedSlotRow = index
                                                        zynqtgui.session_dashboard.selectedChannel = channelDelegate.channelIndex;
                                                    } else {
                                                        handleItemClick()
                                                    }
                                                }
                                                z: 10
                                            }

                                            Rectangle {
                                                property string text: synthsButton.checked && channelDelegate.channel.chainedSounds[index] > -1 && channelDelegate.channel.checkIfLayerExists(channelDelegate.channel.chainedSounds[index])
                                                                        ? channelDelegate.channel.getLayerNameByMidiChannel(channelDelegate.channel.chainedSounds[index]).split(">")[0]
                                                                        : fxButton.checked && channelDelegate.channel.chainedSounds[index] > -1 && channelDelegate.channel.checkIfLayerExists(channelDelegate.channel.chainedSounds[index])
                                                                            ? channelDelegate.channel.getEffectsNameByMidiChannel(channelDelegate.channel.chainedSounds[index])
                                                                            : samplesButton.checked && channelDelegate.channel.samples[index].path
                                                                                ? channelDelegate.channel.samples[index].path.split("/").pop()
                                                                                : ""

                                                clip: true
                                                anchors.centerIn: parent
                                                width: parent.width - 4
                                                height: Kirigami.Units.gridUnit * 1.5

                                                Kirigami.Theme.inherit: false
                                                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                                color: Kirigami.Theme.backgroundColor

                                                border.color: "#ff999999"
                                                border.width: 2
                                                radius: 4

                                                QQC2.Label {
                                                    anchors {
                                                        verticalCenter: parent.verticalCenter
                                                        left: parent.left
                                                        leftMargin: 10
                                                        right: parent.right
                                                        rightMargin: 10
                                                    }
                                                    font.pointSize: 10
                                                    elide: "ElideRight"
                                                    text: parent.text
                                                }
                                            }
                                        }
                                    }
                                }

                                Kirigami.Separator {
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 1
                                    color: "#ff31363b"
                                    visible: index !== root.song.channelsModel.count-1 && !highlighted
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: false
                    Layout.fillHeight: false
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 6
                    Layout.alignment: Qt.AlignTop

                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignHCenter
                        font.pointSize: 14
                        text: qsTr("Ch%1-Slot%2")
                                .arg(zynqtgui.session_dashboard.selectedChannel + 1)
                                .arg(root.selectedSlotRowItem ? root.selectedSlotRowItem.channel.selectedSlotRow + 1 : 0)
                    }
                    QQC2.Label {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignHCenter
                        visible: synthsButton.checked
                        font.pointSize: 12
                        text: qsTr("Synth")
                    }
                    QQC2.Label {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignHCenter
                        font.pointSize: 12
                        visible: fxButton.checked
                        text: qsTr("Fx")
                    }
                    QQC2.Label {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignHCenter
                        font.pointSize: 12
                        visible: samplesButton.checked
                        text: qsTr("Sample")
                    }

                    Kirigami.Separator {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: 1
                    }

                    Rectangle {
                        clip: true
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: detailsText.height + 20
                        Layout.alignment: Qt.AlignHCenter

                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: Kirigami.Theme.backgroundColor

                        border.color: "#ff999999"
                        border.width: 1
                        radius: 4

                        QQC2.Label {
                            id: detailsText
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                leftMargin: 10
                                right: parent.right
                                rightMargin: 10
                            }
                            wrapMode: "WrapAnywhere"
                            font.pointSize: 10
                            text: root.selectedSlotRowItem
                                      ? synthsButton.checked && root.selectedSlotRowItem.channel.chainedSounds[root.selectedSlotRowItem.channel.selectedSlotRow] > -1 && root.selectedSlotRowItem.channel.checkIfLayerExists(root.selectedSlotRowItem.channel.chainedSounds[root.selectedSlotRowItem.channel.selectedSlotRow])
                                          ? root.selectedSlotRowItem.channel.getLayerNameByMidiChannel(root.selectedSlotRowItem.channel.chainedSounds[root.selectedSlotRowItem.channel.selectedSlotRow]).split(">")[0]
                                          : fxButton.checked && root.selectedSlotRowItem.channel.chainedSounds[root.selectedSlotRowItem.channel.selectedSlotRow] > -1 && root.selectedSlotRowItem.channel.checkIfLayerExists(root.selectedSlotRowItem.channel.chainedSounds[root.selectedSlotRowItem.channel.selectedSlotRow])
                                              ? root.selectedSlotRowItem.channel.getEffectsNameByMidiChannel(root.selectedSlotRowItem.channel.chainedSounds[root.selectedSlotRowItem.channel.selectedSlotRow])
                                              : samplesButton.checked && root.selectedSlotRowItem.channel.samples[root.selectedSlotRowItem.channel.selectedSlotRow].path
                                                  ? root.selectedSlotRowItem.channel.samples[root.selectedSlotRowItem.channel.selectedSlotRow].path.split("/").pop()
                                                  : ""
                                      : ""
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                handleItemClick()
                            }
                        }
                    }

                    QQC2.Slider {
                        id: volumeSlider

                        property int chainedSound: root.selectedSlotRowItem ? root.selectedSlotRowItem.channel.chainedSounds[root.selectedSlotRowItem.channel.selectedSlotRow] : -1
                        property var volumeControlObject: zynqtgui.fixed_layers.volumeControllers[chainedSound]

                        orientation: Qt.Horizontal

                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5

                        visible: synthsButton.checked
                        enabled: chainedSound >= 0 &&
                                 (root.selectedSlotRowItem ? root.selectedSlotRowItem.channel.checkIfLayerExists(chainedSound) : false) &&
                                 volumeControlObject &&
                                 volumeControlObject.controllable
                        value: volumeControlObject ? volumeControlObject.value : 0
                        stepSize: volumeControlObject ? volumeControlObject.step_size : 1
                        from: volumeControlObject ? volumeControlObject.value_min : 0
                        to: volumeControlObject ? volumeControlObject.value_max : 1
                        onMoved: {
                            volumeControlObject.value = value;
                        }
                    }
                }
            }
        }
    }

    Zynthian.FilePickerDialog {
        id: samplePickerDialog
        parent: zlScreen.parent

        width: parent.width
        height: parent.height
        x: parent.x
        y: parent.y

        headerText: qsTr("%1-S%2 : Pick a sample")
                        .arg(root.selectedChannel.name)
                        .arg(root.selectedChannel.selectedSlotRow + 1)
        rootFolder: "/zynthian/zynthian-my-data"
        folderModel {
            nameFilters: ["*.wav"]
        }
        onFileSelected: {
            root.selectedChannel.set_sample(file.filePath, root.selectedChannel.selectedSlotRow)
        }
    }

    Zynthian.FilePickerDialog {
        id: bankPickerDialog
        parent: zlScreen.parent

        width: parent.width
        height: parent.height
        x: parent.x
        y: parent.y

        headerText: root.selectedSlotRowItem
                    ? qsTr("%1-S%2 : Pick a bank")
                        .arg(root.selectedSlotRowItem.channel.name)
                        .arg(root.selectedSlotRowItem.channel.selectedSlotRow + 1)
                    : ""
        rootFolder: "/zynthian/zynthian-my-data"
        folderModel {
            nameFilters: ["sample-bank.json"]
        }
        onFileSelected: {
            root.selectedSlotRowItem.channel.setBank(file.filePath)
        }
    }

    Zynthian.FilePickerDialog {
        id: loopPickerDialog
        parent: zlScreen.parent

        width: parent.width
        height: parent.height
        x: parent.x
        y: parent.y

        headerText: qsTr("%1 : Pick an audio file")
                        .arg(root.selectedChannel.name)
        rootFolder: "/zynthian/zynthian-my-data"
        folderModel {
            nameFilters: ["*.wav"]
        }
        onFileSelected: {
            root.selectedChannel.getClipsModelByPart(root.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex).path = file.filePath
        }
    }

    Zynthian.Popup {
        id: samplePickerPopup

        parent: QQC2.Overlay.overlay
        y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
        x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
        width: Kirigami.Units.gridUnit*12

        ColumnLayout {
            anchors.fill: parent

            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignCenter
                text: qsTr("Pick recording")

                onClicked: {
                    samplePickerDialog.folderModel.folder = root.selectedSlotRowItem.channel.recordingDir
                    samplePickerDialog.open()
                    samplePickerPopup.close()
                }
            }

            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignCenter
                text: qsTr("Pick sample")

                onClicked: {
                    samplePickerDialog.folderModel.folder = '/zynqtgui/zynqtgui-my-data/samples'
                    samplePickerDialog.open()
                    samplePickerPopup.close()
                }
            }

            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignCenter
                text: qsTr("Pick sample-bank")

                onClicked: {
                    bankPickerDialog.folderModel.folder = '/zynqtgui/zynqtgui-my-data/sample-banks'
                    bankPickerDialog.open()
                    samplePickerPopup.close()
                }
            }

            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignCenter
                text: qsTr("Download Samples")
                visible: false // Hide for now
                onClicked: {
                    zynqtgui.current_modal_screen_id = "sample_downloader"
                    samplePickerPopup.close()
                }
            }
        }
    }

    Zynthian.LayerSetupDialog {
        id: layerSetupDialog
    }

    ExternalMidiChannelPicker {
        id: externalMidiChannelPicker
    }
}
