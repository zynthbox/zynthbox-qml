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

import QtQuick 2.15
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
                zynqtgui.sketchpad.selectedTrackId = Zynthian.CommonUtils.clamp(zynqtgui.sketchpad.selectedTrackId - 1, 0, Zynthbox.Plugin.sketchpadTrackCount - 1)
                return true;

            case "NAVIGATE_RIGHT":
                zynqtgui.sketchpad.selectedTrackId = Zynthian.CommonUtils.clamp(zynqtgui.sketchpad.selectedTrackId + 1, 0, Zynthbox.Plugin.sketchpadTrackCount - 1)
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
                if (fxButton.checked) {
                    root.selectedSlotRowItem.channel.selectedFxSlotRow = 0
                } else {
                    root.selectedSlotRowItem.channel.selectedSlotRow = 0
                }
                handleItemClick()
                return true

            case "CHANNEL_2":
            case "CHANNEL_7":
                if (fxButton.checked) {
                    root.selectedSlotRowItem.channel.selectedFxSlotRow = 1
                } else {
                    root.selectedSlotRowItem.channel.selectedSlotRow = 1
                }
                handleItemClick()
                return true

            case "CHANNEL_3":
            case "CHANNEL_8":
                if (fxButton.checked) {
                    root.selectedSlotRowItem.channel.selectedFxSlotRow = 2
                } else {
                    root.selectedSlotRowItem.channel.selectedSlotRow = 2
                }
                handleItemClick()
                return true

            case "CHANNEL_4":
            case "CHANNEL_9":
                if (fxButton.checked) {
                    root.selectedSlotRowItem.channel.selectedFxSlotRow = 3
                } else {
                    root.selectedSlotRowItem.channel.selectedSlotRow = 3
                }
                handleItemClick()
                return true

            case "CHANNEL_5":
            case "CHANNEL_10":
                if (fxButton.checked) {
                    root.selectedSlotRowItem.channel.selectedFxSlotRow = 4
                } else {
                    root.selectedSlotRowItem.channel.selectedSlotRow = 4
                }
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
        }
    }

    function pickSlotToSwapWith(channel, slotType, slotIndex) {
        slotSwapperPopup.pickSlotToSwapWith(channel, slotType, slotIndex);
    }

    function openSlotInputPicker(channel, slotType, slotIndex) {
        slotInputPicker.pickSlotInputs(channel, slotType, slotIndex);
    }

    function requestChannelKeyZoneSetup() {
        channelKeyZoneSetup.open();
    }

    function requestSlotEqualizer(channel, slotType, slotIndex) {
        slotEqualizer.showEqualizer(channel, slotType, slotIndex);
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
        } else if (fxButton.checked || type === "fx") {
            // Clicked entry is fx
            console.log("handleItemClick : FX")

//            var chainedSound = root.selectedSlotRowItem.channel.chainedSounds[root.selectedSlotRowItem.channel.selectedFxSlotRow]

            if (zynqtgui.backButtonPressed) {
//                // Back is pressed. Clear Slot
                root.selectedSlotRowItem.channel.removeSelectedFxFromChain()
//                if (root.selectedSlotRowItem.channel.checkIfLayerExists(chainedSound)) {
//                    zynqtgui.start_loading()
//                    zynqtgui.fixed_layers.activate_index(chainedSound)
//                    zynqtgui.layer_effects.fx_reset_confirmed()
//                    zynqtgui.stop_loading()
//                }
            } else {
                fxSetupDialog.open()
//                zynqtgui.fixed_layers.activate_index(chainedSound)
//                zynqtgui.layer_options.show();
//                var screenBack = zynqtgui.current_screen_id;
//                zynqtgui.current_screen_id = "layer_effects";
//                root.openBottomDrawerOnLoad = true;
//                zynqtgui.forced_screen_back = screenBack;
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

            var clip = root.selectedChannel.getClipsModelByPart(root.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)

            if (zynqtgui.backButtonPressed) {
                clip.clear()
            } else {
                sketchPickerPopup.open()
            }
        } else if (type === "external") {
            console.log("handleItemClick : External")
            switch (root.selectedChannel.selectedSlotRow) {
                case 0:
                    externalAudioSourcePicker.pickChannel(root.selectedChannel);
                    break;
                case 1:
                default:
                    externalMidiChannelPicker.pickChannel(root.selectedChannel);
                    break;
            }
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
                        enabled: !root.displaySceneButtons
                        text: qsTr("BottomBar")
                        visible: false
                        onCheckedChanged: {
                            if (checked) {
                                bottomStack.currentIndex = 0
                                updateLedVariablesTimer.restart()
                            }
                        }
                    }

                    QQC2.Button {
                        id: mixerButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        enabled: !root.displaySceneButtons
                        visible: false
                        text: qsTr("Mixer")
                        onCheckedChanged: {
                            if (checked) {
                                bottomStack.currentIndex = 1
                                updateLedVariablesTimer.restart()
                            }
                        }
                    }

                    QQC2.Button {
                        id: soundCombinatorButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        enabled: !root.displaySceneButtons
                        visible: false
                        text: qsTr("Sound Combinator")
                        onCheckedChanged: {
                            if (checked) {
                                bottomStack.currentIndex = 5
                                updateLedVariablesTimer.restart()
                            }
                        }
                    }

                    //// END INVISIBLE BUTTONS

                    QQC2.Button {
                        id: channelButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        enabled: !root.displaySceneButtons
                        text: qsTr("Track")
                        onCheckedChanged: {
                            if (checked) {
                                bottomStack.currentIndex = 3
                                updateLedVariablesTimer.restart()
                            }
                        }
                    }

                    QQC2.Button {
                        id: partButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        enabled: !root.displaySceneButtons
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
                        enabled: !root.displaySceneButtons
                        text: qsTr("Synths")
                        onCheckedChanged: {
                            if (checked) {
                                bottomStack.currentIndex = 2
                                updateLedVariablesTimer.restart()
                            }
                        }
                    }

                    QQC2.Button {
                        id: samplesButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        enabled: !root.displaySceneButtons
                        text: qsTr("Samples")
                        onCheckedChanged: {
                            if (checked) {
                                bottomStack.currentIndex = 2
                                updateLedVariablesTimer.restart()
                            }
                        }
                    }

                    QQC2.Button {
                        id: fxButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        enabled: !root.displaySceneButtons
                        text: qsTr("FX")
                        onCheckedChanged: {
                            if (checked) {
                                bottomStack.currentIndex = 2
                                updateLedVariablesTimer.restart()
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
                                    channelDelegate.highlighted = (index === zynqtgui.sketchpad.selectedTrackId);
                                }
                            }
                            Connections {
                                target: zynqtgui.sketchpad
                                onSelected_track_id_changed: channelHighlightedThrottle.restart()
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
                                            border.color: channelDelegate.highlighted &&
                                                          ((!fxButton.checked && channelDelegate.channel.selectedSlotRow === index) || (fxButton.checked && channelDelegate.channel.selectedFxSlotRow === index))
                                                            ? Kirigami.Theme.highlightColor
                                                            : "transparent"

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    if (zynqtgui.sketchpad.selectedTrackId !== channelDelegate.channelIndex ||
                                                        ((!fxButton.checked && channelDelegate.channel.selectedSlotRow !== index) || (fxButton.checked && channelDelegate.channel.selectedFxSlotRow !== index))) {
                                                        channelsSlotsRow.currentIndex = index
                                                        if (fxButton.checked) {
                                                            channelDelegate.channel.selectedFxSlotRow = index
                                                        } else {
                                                            channelDelegate.channel.selectedSlotRow = index
                                                        }

                                                        zynqtgui.sketchpad.selectedTrackId = channelDelegate.channelIndex;
                                                    } else {
                                                        handleItemClick()
                                                    }
                                                }
                                                z: 10
                                            }

                                            Rectangle {
                                                property string text: synthsButton.checked && channelDelegate.channel.chainedSounds[index] > -1 && channelDelegate.channel.checkIfLayerExists(channelDelegate.channel.chainedSounds[index])
                                                                        ? channelDelegate.channel.getLayerNameByMidiChannel(channelDelegate.channel.chainedSounds[index]).split(">")[0]
                                                                        : fxButton.checked
                                                                            ? channelDelegate.channel.chainedFxNames[index]
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
                                .arg(zynqtgui.sketchpad.selectedTrackId + 1)
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
                                          : fxButton.checked
                                              ? root.selectedSlotRowItem.channel.chainedFxNames[root.selectedSlotRowItem.channel.selectedFxSlotRow]
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
                        property QtObject synthPassthroughClient: chainedSound > -1 ? Zynthbox.Plugin.synthPassthroughClients[chainedSound] : null

                        orientation: Qt.Horizontal

                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5

                        visible: synthsButton.checked
                        enabled: chainedSound >= 0 &&
                                 (root.selectedSlotRowItem ? root.selectedSlotRowItem.channel.checkIfLayerExists(chainedSound) : false)
                        value: synthPassthroughClient ? synthPassthroughClient.dryAmount : 0
                        stepSize: 0.01
                        from: 0
                        to: 1
                        onMoved: {
                            root.selectedChannel.set_passthroughValue("synthPassthrough", root.selectedSlotRow, "dryAmount", value);
                        }
                    }

                    QQC2.Button {
                        Layout.fillWidth: true
                        text: qsTr("Swap with...")
                        onClicked: {
                            let swapType = "unknown";
                            if (synthsButton.checked) {
                                swapType = "synth";
                            } else if (fxButton.checked) {
                                swapType = "fx";
                            } else if (samplesButton.checked) {
                                swapType = "sample";
                            }
                            bottomStack.slotsBar.pickSlotToSwapWith(root.selectedSlotRowItem.channel, swapType, root.selectedSlotRowItem.channel.selectedSlotRow);
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

        function pickSampleForSlot(slot, pickWhat) {
            samplePickerDialog.sampleSlot = slot;
            samplePickerDialog.clipToSave = root.selectedSlotRowItem.channel.samples[slot];
            samplePickerDialog.saveMode = (pickWhat === "save-location");
            if (pickWhat === "sample" || pickWhat === "save-location") {
                samplePickerDialog.folderModel.folder = "/zynthian/zynthian-my-data/samples/my-samples";
                samplePickerDialog.folderModel.nameFilters = ["*.wav"];
            } else if (pickWhat === "sketch") {
                samplePickerDialog.folderModel.folder = "/zynthian/zynthian-my-data/sketches";
                samplePickerDialog.folderModel.nameFilters = ["*.sketch.wav"];
            } else if (pickWhat === "recording") {
                samplePickerDialog.folderModel.folder = root.selectedSlotRowItem.channel.recordingDir;
                samplePickerDialog.folderModel.nameFilters = ["*.wav"];
            }
            samplePickerDialog.open();
        }
        property int sampleSlot: -1

        headerText: saveMode
            ? qsTr("Pick Save Location For %1-S%2")
                .arg(root.selectedChannel.name)
                .arg(sampleSlot + 1)
            : qsTr("%1-S%2 : Pick a sample")
                .arg(root.selectedChannel.name)
                .arg(sampleSlot + 1)
        rootFolder: "/zynthian/zynthian-my-data"
        folderModel {
            nameFilters: ["*.wav"]
        }
        property QtObject clipToSave
        onAccepted: {
            if (samplePickerDialog.saveMode === true) {
                let copyTo = samplePickerDialog.selectedFile.filePath;
                let originalSuffix = clipToSave.path.split(".").slice(-1).toString().toLowerCase();
                console.log("Testing", copyTo, "has the suffix", originalSuffix);
                if (copyTo.split(".").slice(-1).toString().toLowerCase() != originalSuffix) {
                    console.log("It does not, append it");
                    copyTo = copyTo + "." + originalSuffix;
                }
                if (clipToSave.copyTo(copyTo)) {
                    console.log("Successfully copied the clip with path name", clipToSave.path, "to ", copyTo)
                } else {
                    console.log("Failed to copy the clip with path name", clipToSave.path, "to", copyTo)
                }
            } else {
                // TODO Handle mp3/ogg/whatnot - juce supports reading it, but we don't really handle that great...
                root.selectedChannel.set_sample(samplePickerDialog.selectedFile.filePath, samplePickerDialog.sampleSlot)
            }
        }
    }

    Zynthian.FilePickerDialog {
        id: loopPickerDialog
        parent: zlScreen.parent

        function pickLoopForClip(clip, pickWhat) {
            loopPickerDialog.theClip = clip;
            loopPickerDialog.saveMode = (pickWhat === "save-location");
            if (pickWhat === "sketch" || pickWhat === "save-location") {
                loopPickerDialog.folderModel.folder = "/zynthian/zynthian-my-data/sketches";
                loopPickerDialog.folderModel.nameFilters = ["*.sketch.wav"];
                loopPickerDialog.thingToPick = qsTr("Sketch");
            } else if (pickWhat === "sample") {
                loopPickerDialog.folderModel.folder = "/zynthian/zynthian-my-data/samples";
                loopPickerDialog.folderModel.nameFilters = ["*.wav"];
                loopPickerDialog.thingToPick = qsTr("Sample");
            } else if (pickWhat === "recording") {
                loopPickerDialog.folderModel.folder = sketchPickerPopup.sketch.recordingDir;
                loopPickerDialog.folderModel.nameFilters = ["*.wav"];
                loopPickerDialog.thingToPick = qsTr("Recording");
            }
            loopPickerDialog.open();
        }
        property QtObject theClip: null

        width: parent.width
        height: parent.height
        x: parent.x
        y: parent.y

        headerText: saveMode
            ? qsTr("Pick Save Location For %1%2")
                .arg(root.selectedChannel.name)
                .arg(root.selectedChannel.selectedSlotRow + 1)
            : qsTr("%1%2 : Pick a %3")
                .arg(root.selectedChannel.name)
                .arg(root.selectedChannel.selectedSlotRow + 1)
                .arg(thingToPick)
        property string thingToPick: ""
        rootFolder: "/zynthian/zynthian-my-data"
        folderModel {
            nameFilters: ["*.sketch.wav"]
        }
        onFileSelected: {
            if (loopPickerDialog.saveMode === true) {
                let copyTo = loopPickerDialog.selectedFile.filePath;
                let originalSuffix = loopPickerDialog.theClip.path.split(".").slice(-2).toString().toLowerCase();
                console.log("Testing", copyTo, "has the suffix", originalSuffix);
                if (copyTo.split(".").slice(-2).toString().toLowerCase() != originalSuffix) {
                    console.log("It does not, append it");
                    copyTo = copyTo + "." + originalSuffix;
                }
                if (loopPickerDialog.theClip.copyTo(copyTo)) {
                    console.log("Successfully copied the clip with path name", loopPickerDialog.theClip.path, "to ", copyTo)
                } else {
                    console.log("Failed to copy the clip with path name", loopPickerDialog.theClip.path, "to", copyTo)
                }
            } else {
                loopPickerDialog.theClip.path = file.filePath;
                loopPickerDialog.theClip.enabled = true;
            }
        }
    }

    SlotSwapperPopup {
        id: slotSwapperPopup
    }

    SlotInputPicker {
        id: slotInputPicker
    }

    ChannelKeyZoneSetup {
        id: channelKeyZoneSetup
    }

    // Zynthian.FilePickerDialog {
    //     id: bankPickerDialog
    //     parent: zlScreen.parent
    //
    //     width: parent.width
    //     height: parent.height
    //     x: parent.x
    //     y: parent.y
    //
    //     headerText: root.selectedSlotRowItem
    //                 ? qsTr("%1-S%2 : Pick a bank")
    //                     .arg(root.selectedSlotRowItem.channel.name)
    //                     .arg(root.selectedSlotRowItem.channel.selectedSlotRow + 1)
    //                 : ""
    //     rootFolder: "/zynthian/zynthian-my-data"
    //     folderModel {
    //         nameFilters: ["sample-bank.json"]
    //     }
    //     onFileSelected: {
    //         root.selectedSlotRowItem.channel.setBank(file.filePath)
    //     }
    // }

    Zynthian.ActionPickerPopup {
        id: sketchPickerPopup
        objectName: "sketchPickerPopup"
        columns: 3
        rows: 3
        property QtObject sketch: root.selectedChannel.getClipsModelByPart(root.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
        actions: [
            QQC2.Action {
                text: qsTr("Save A Copy...")
                enabled: sketchPickerPopup.sketch && sketchPickerPopup.sketch.cppObjId !== -1
                onTriggered: {
                    loopPickerDialog.pickLoopForClip(sketchPickerPopup.sketch, "save-location");
                }
            },
            QQC2.Action {
                text: qsTr("Remove")
                enabled: sketchPickerPopup.sketch && sketchPickerPopup.sketch.cppObjId !== -1
                onTriggered: {
                    sketchPickerPopup.sketch && sketchPickerPopup.sketch.clear();
                }
            },
            QQC2.Action {
                text: qsTr("Unbounce...")
                enabled: sketchPickerPopup.sketch && sketchPickerPopup.sketch.cppObjId !== -1 && shouldUnbounce
                property bool shouldUnbounce: sketchPickerPopup.sketch && sketchPickerPopup.sketch.metadata.audioType && sketchPickerPopup.sketch.metadata.audioType.length > 0
                onTriggered: {
                    sketchUnbouncer.unbounce(sketchPickerPopup.sketch, zynqtgui.sketchpad.song.scenesModel.selectedSequenceName, root.selectedChannel, root.selectedChannel.selectedSlotRow);
                }
            },
            QQC2.Action {
                text: qsTr("Pick Recording...")
                onTriggered: {
                    loopPickerDialog.pickLoopForClip(sketchPickerPopup.sketch, "recording");
                }
            },
            QQC2.Action {
                text: qsTr("Pick Sample...")
                onTriggered: {
                    loopPickerDialog.pickLoopForClip(sketchPickerPopup.sketch, "sample");
                }
            },
            QQC2.Action {
                text: qsTr("Pick Sketch...")
                onTriggered: {
                    loopPickerDialog.pickLoopForClip(sketchPickerPopup.sketch, "sketch");
                }
            },
            QQC2.Action {
                text: "Swap With..."
                onTriggered: {
                    slotSwapperPopup.pickSlotToSwapWith(root.selectedChannel, "sketch", root.selectedChannel.selectedSlotRow);
                }
            },
            QQC2.Action {
                text: "Equalizer..."
                enabled: sketchPickerPopup.sketch && sketchPickerPopup.sketch.cppObjId !== -1
                onTriggered: {
                    root.requestSlotEqualizer(root.selectedChannel, "sketch", sketchPickerPopup.sketch.cppObjId);
                }
            },
            QQC2.Action {
                text: qsTr("Download Sketches...")
                onTriggered: {
                    zynqtgui.current_modal_screen_id = "sketch_downloader"
                }
            }
        ]
    }

    Zynthian.ActionPickerPopup {
        id: samplePickerPopup
        objectName: "samplePickerPopup"
        property QtObject sketch: root.selectedSlotRowItem && root.selectedSlotRowItem.channel ? root.selectedSlotRowItem.channel.samples[root.selectedSlotRowItem.channel.selectedSlotRow] : null
        columns: 3
        rows: 3
        actions: [
            QQC2.Action {
                text: qsTr("Save A Copy...")
                enabled: samplePickerPopup.sketch ? samplePickerPopup.sketch.cppObjId !== -1 : false
                onTriggered: {
                    samplePickerDialog.pickSampleForSlot(root.selectedChannel.selectedSlotRow, "save-location");
                }
            },
            QQC2.Action {
                text: qsTr("Remove")
                enabled: samplePickerPopup.sketch ? samplePickerPopup.sketch.cppObjId !== -1 : false
                onTriggered: {
                    samplePickerPopup.sketch.clear()
                }
            },
            QQC2.Action {
                text: qsTr("Unbounce...")
                enabled: (samplePickerPopup.sketch ? samplePickerPopup.sketch.cppObjId !== -1 : false) && shouldUnbounce
                property bool shouldUnbounce: samplePickerPopup.sketch && samplePickerPopup.sketch.metadata.audioType && samplePickerPopup.sketch.metadata.audioType.length > 0
                onTriggered: {
                    sketchUnbouncer.unbounce(samplePickerPopup.sketch, zynqtgui.sketchpad.song.scenesModel.selectedSequenceName, root.selectedChannel, root.selectedChannel.selectedSlotRow);
                }
            },
            QQC2.Action {
                text: qsTr("Pick recording")
                onTriggered: {
                    samplePickerDialog.pickSampleForSlot(root.selectedChannel.selectedSlotRow, "recording");
                }
            },
            QQC2.Action {
                text: qsTr("Pick sample")
                onTriggered: {
                    samplePickerDialog.pickSampleForSlot(root.selectedChannel.selectedSlotRow, "sample");
                }
            },
            QQC2.Action {
                text: qsTr("Pick sketch")
                onTriggered: {
                    samplePickerDialog.pickSampleForSlot(root.selectedChannel.selectedSlotRow, "sketch");
                }
            },
            QQC2.Action {
                text: "Swap with..."
                onTriggered: {
                    slotSwapperPopup.pickSlotToSwapWith(root.selectedChannel, "sample", root.selectedChannel.selectedSlotRow);
                }
            },
            QQC2.Action {
                text: "Equalizer..."
                enabled: samplePickerPopup.sketch ? samplePickerPopup.sketch.cppObjId !== -1 : false
                onTriggered: {
                    root.requestSlotEqualizer(root.selectedChannel, "sample", samplePickerPopup.sketch.cppObjId);
                }
            },
            QQC2.Action {
                text: qsTr("Download Sketches")
                onTriggered: {
                    zynqtgui.current_modal_screen_id = "sketch_downloader";
                }
            }
        ]
    }

    SketchUnbouncer {
        id: sketchUnbouncer
    }

    Zynthian.LayerSetupDialog {
        id: layerSetupDialog
        onRequestSlotPicker: function(channel, slotType, slotIndex) {
            slotSwapperPopup.pickSlotToSwapWith(channel, slotType, slotIndex);
        }
        onRequestSlotInputPicker: function(channel, slotType, slotIndex) {
            slotInputPicker.pickSlotInputs(channel, slotType, slotIndex);
        }
        onRequestChannelKeyZoneSetup: function() {
            channelKeyZoneSetup.open();
        }
        onRequestSlotEqualizer: function(channel, slotType, slotIndex) {
            slotEqualizer.showEqualizer(channel, slotType, slotIndex);
        }
    }

    SlotEqualizer {
        id: slotEqualizer
    }

    ExternalAudioSourcePicker {
        id: externalAudioSourcePicker
    }
    ExternalMidiChannelPicker {
        id: externalMidiChannelPicker
    }

    Zynthian.ActionPickerPopup {
        id: fxSetupDialog
        property var selectedFx: root.selectedSlotRowItem && root.selectedSlotRowItem.channel ? root.selectedSlotRowItem.channel.chainedFx[root.selectedSlotRowItem.channel.selectedFxSlotRow] : null

        actions: [
            Kirigami.Action {
                text: fxSetupDialog.selectedFx == null
                        ? qsTr("Pick FX")
                        : qsTr("Change FX")
                onTriggered: {
                    zynqtgui.forced_screen_back = "sketchpad"
                    zynqtgui.current_screen_id = "effect_types"
                    zynqtgui.layer.page_after_layer_creation = "sketchpad"
                }
            },
            Kirigami.Action {
                text: qsTr("Change FX Preset")
                visible: fxSetupDialog.selectedFx != null
                onTriggered: {
                    zynqtgui.forced_screen_back = "sketchpad"
                    zynqtgui.current_screen_id = "effect_preset"
                    zynqtgui.layer.page_after_layer_creation = "sketchpad"
                }
            },
            Kirigami.Action {
                text: qsTr("Edit FX")
                visible: fxSetupDialog.selectedFx != null
                onTriggered: {
                    zynqtgui.show_screen("control")
                }
            },
            Kirigami.Action {
                text: "Equalizer..."
                visible: fxSetupDialog.selectedFx != null
                onTriggered: {
                    root.requestSlotEqualizer(root.selectedChannel, "fx", root.selectedChannel.selectedSlotRow);
                }
            },
            Kirigami.Action {
                text: qsTr("Swap with...")
                onTriggered: {
                    slotSwapperPopup.pickSlotToSwapWith(root.selectedChannel, "fx", root.selectedChannel.selectedSlotRow);
                }
            },
            Kirigami.Action {
                text: "Set Input Overrides..."
                visible: fxSetupDialog.selectedFx != null
                onTriggered: {
                    slotInputPicker.pickSlotInputs(root.selectedChannel, "fx", root.selectedChannel.selectedSlotRow);
                }
            },
            Kirigami.Action {
                text: qsTr("Remove FX")
                visible: fxSetupDialog.selectedFx != null
                onTriggered: {
                    root.selectedSlotRowItem.channel.removeSelectedFxFromChain()
                }
            }
        ]
    }
}
