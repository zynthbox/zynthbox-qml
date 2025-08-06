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
import QtGraphicalEffects 1.0
import org.kde.plasma.core 2.0 as PlasmaCore

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

QQC2.Pane {
    id: root

    property alias bottomBarButton: bottomBarButton
    property alias channelButton: channelButton
    property alias mixerButton: mixerButton
    property alias clipsButton: clipsButton
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
    padding: 0
    background: null //for now it is no themeable

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
        case "TRACK_1":
            if (fxButton.checked) {
                root.selectedSlotRowItem.channel.selectedFxSlotRow = 0
            } else {
                root.selectedSlotRowItem.channel.selectedSlotRow = 0
            }
            handleItemClick()
            return true

        case "TRACK_2":
            if (fxButton.checked) {
                root.selectedSlotRowItem.channel.selectedFxSlotRow = 1
            } else {
                root.selectedSlotRowItem.channel.selectedSlotRow = 1
            }
            handleItemClick()
            return true

        case "TRACK_3":
            if (fxButton.checked) {
                root.selectedSlotRowItem.channel.selectedFxSlotRow = 2
            } else {
                root.selectedSlotRowItem.channel.selectedSlotRow = 2
            }
            handleItemClick()
            return true

        case "TRACK_4":
            if (fxButton.checked) {
                root.selectedSlotRowItem.channel.selectedFxSlotRow = 3
            } else {
                root.selectedSlotRowItem.channel.selectedSlotRow = 3
            }
            handleItemClick()
            return true

        case "TRACK_5":
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
        // required from TracksBar or something else in future
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

            if (zynqtgui.backButtonPressed) {
                // Back is pressed. Clear Slot
                root.selectedSlotRowItem.channel.removeSelectedFxFromChain()
            } else {
                fxSetupDialog.open()
            }
        } else if (type === "sketch-fx") {
            // Clicked entry is sketch fx
            console.log("handleItemClick : Sketch FX")

            if (zynqtgui.backButtonPressed) {
                // Back is pressed. Clear Slot
                root.selectedSlotRowItem.channel.removeSelectedSketchFxFromChain()
            } else {
                fxSetupDialog.open()
            }
        } else if (samplesButton.checked || type === "sample-trig") {
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

            var clip = root.selectedChannel.getClipsModelById(root.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)

            if (zynqtgui.backButtonPressed) {
                clip.clear()
            } else {
                sketchPickerPopup.open()
            }
        } else if (type === "external") {
            console.log("handleItemClick : External")
            switch (root.selectedChannel.selectedSlotRow) {
            case 0:
            default:
                externalAudioSourcePicker.pickChannel(root.selectedChannel);
                break;
            case 1:
                externalMidiChannelPicker.pickChannel(root.selectedChannel);
                break;
            case 2:
                externalMidiOutPicker.pickOutput(root.selectedChannel);
                break;
            }
        }
    }

    QQC2.ButtonGroup {
        buttons: buttonsColumn.children
    }

    contentItem: Item {
        ColumnLayout {
            anchors.fill: parent

            Kirigami.Heading {
                visible: false
                text: qsTr("Slots : %1").arg(song.name)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2

                ColumnLayout {
                    id: buttonsColumn
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 6
                    Layout.bottomMargin: 1 // Without this magic number, last button's border goes out of view
                    spacing: 1

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
                        id: clipsButton
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

                QQC2.Pane {

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: svgBg.inset.top

                    topPadding: svgBg.topPadding
                    bottomPadding: svgBg.bottomPadding
                    leftPadding: svgBg.leftPadding
                    rightPadding: svgBg.rightPadding

                    background: Item {
                        PlasmaCore.FrameSvgItem {
                            id: svgBg
                            visible: fromCurrentTheme
                            anchors.fill: parent

                            readonly property real leftPadding: fixedMargins.left
                            readonly property real rightPadding: fixedMargins.right
                            readonly property real topPadding: fixedMargins.top
                            readonly property real bottomPadding: fixedMargins.bottom

                            imagePath: "widgets/tracks-background"
                            colorGroup: PlasmaCore.Theme.ViewColorGroup
                        }
                    }

                    contentItem: Item {
                        id: slotsContainer

                        // layer.enabled: true
                        // layer.effect: OpacityMask
                        // {
                        //     maskSource: Rectangle
                        //     {
                        //         width: slotsContainer.width
                        //         height: slotsContainer.height
                        //         radius: 6
                        //     }
                        // }

                        RowLayout {
                            id: channelsSlotsRow
                            anchors.fill: parent
                            property int currentIndex: 0

                            spacing: 0

                            Repeater {
                                model: root.song.channelsModel

                                delegate: QQC2.Control {
                                    id: channelDelegate
                                    property bool highlighted: false
                                    //                            property int selectedRow: 0
                                    property int channelIndex: index
                                    property QtObject channel: model.channel

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    padding: Kirigami.Units.smallSpacing
                                    background: Item {
                                        Kirigami.Separator {
                                            height: parent.height
                                            anchors.left: parent.left
                                            visible: channelDelegate.channelIndex !== 0
                                            width: 1
                                            color: Qt.darker(Kirigami.Theme.backgroundColor, 1.5)
                                        }
                                        Rectangle {
                                            visible: !svgBg2.visible
                                            anchors.fill: parent
                                            color: highlighted ? "#22ffffff" : "transparent"
                                            border.width: 1
                                            border.color: highlighted ? Kirigami.Theme.highlightColor : "transparent"
                                        }
                                        PlasmaCore.FrameSvgItem {
                                            id: svgBg2
                                            visible: fromCurrentTheme && highlighted
                                            anchors.fill: parent

                                            readonly property real leftPadding: fixedMargins.left
                                            readonly property real rightPadding: fixedMargins.right
                                            readonly property real topPadding: fixedMargins.top
                                            readonly property real bottomPadding: fixedMargins.bottom

                                            imagePath: "widgets/column-delegate-background"
                                            prefix: channelDelegate.highlighted ? ["focus", ""] : ""
                                            colorGroup: PlasmaCore.Theme.ViewColorGroup
                                        }
                                    }

                                    Timer {
                                        id: channelHighlightedThrottle
                                        interval: 1; running: false; repeat: false;
                                        onTriggered: {
                                            channelDelegate.highlighted = (index === zynqtgui.sketchpad.selectedTrackId);
                                            if (channelDelegate.highlighted) {
                                                root.selectedSlotRowItem = channelDelegate;
                                            }
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
                                    // And once the song has completed loading
                                    Connections {
                                        target: zynqtgui.sketchpad.song
                                        onIsLoadingChanged: channelHighlightedThrottle.restart()
                                    }
                                    // And once the component is completed (which happens when loading sketchpads)
                                    Component.onCompleted: {
                                        channelHighlightedThrottle.restart();
                                    }

                                    onHighlightedChanged: {
                                        if (highlighted) {
                                            root.selectedSlotRowItem = channelDelegate;
                                        }
                                    }

                                    contentItem: TrackSlotsData {
                                        id: synthsRow
                                        columnSpacing: Kirigami.Units.gridUnit * 0.7
                                        channel: channelDelegate.channel
                                        slotData: {
                                            if (synthsButton.checked) {
                                                return channelDelegate.channel.synthSlotsData
                                            } else if (samplesButton.checked) {
                                                return channelDelegate.channel.sampleSlotsData
                                            } else if (fxButton.checked) {
                                                return channelDelegate.channel.fxSlotsData
                                            } else {
                                                return channelDelegate.channel.synthSlotsData // Fallback to synths when none of the tab buttons are checked
                                            }
                                        }
                                        slotType: {
                                            if (synthsButton.checked) {
                                                return "synth"
                                            } else if (samplesButton.checked) {
                                                return "sample-trig"
                                            } else if (fxButton.checked) {
                                                return "fx"
                                            } else {
                                                return "synth" // Fallback to synths when none of the tab buttons are checked
                                            }
                                        }
                                        orientation: Qt.Vertical
                                        showSlotTypeLabel: false
                                        dragEnabled: false
                                        singleClickEnabled: true
                                        doubleClickEnabled: false
                                        clickAndHoldEnabled: false
                                        onSlotClicked: {
                                            zynqtgui.sketchpad.selectedTrackId = channel.id
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 6
                    Layout.alignment: Qt.AlignTop
                    spacing: Kirigami.Units.mediumSpacing

                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        // Layout.alignment: Qt.AlignHCenter
                        // font.pointSize: 14
                        text: qsTr("Ch%1-Slot%2")
                        .arg(zynqtgui.sketchpad.selectedTrackId + 1)
                        .arg(root.selectedSlotRowItem ? root.selectedSlotRowItem.channel.selectedSlotRow + 1 : 0)
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        // Layout.alignment: Qt.AlignHCenter
                        visible: synthsButton.checked
                        font.pointSize: 10
                        text: qsTr("Synth")
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignHCenter
                        font.pointSize: 10
                        visible: fxButton.checked
                        text: qsTr("Fx")
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignHCenter
                        font.pointSize: 10
                        visible: samplesButton.checked
                        text: qsTr("Sample")
                    }

                    QQC2.Control {
                        clip: true
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: detailsText.height + 20
                        Layout.alignment: Qt.AlignHCenter

                        background: Item {

                            Rectangle {
                                visible: !svgBg3.visible
                                anchors.fill: parent
                                Kirigami.Theme.inherit: false
                                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                color: Kirigami.Theme.backgroundColor

                                border.color: "#ff999999"
                                border.width: 1
                                radius: 4
                            }

                            PlasmaCore.FrameSvgItem {
                                id: svgBg3
                                anchors.fill: parent
                                visible: fromCurrentTheme
                                readonly property bool highlighted: false
                                readonly property real leftPadding: margins.left
                                readonly property real rightPadding: margins.right
                                readonly property real topPadding: margins.top
                                readonly property real bottomPadding: margins.bottom

                                imagePath: "widgets/slots-delegate-background"
                                prefix: svgBg3.highlighted ? ["focus", ""] : ""
                                colorGroup: PlasmaCore.Theme.ButtonColorGroup
                            }
                        }

                        contentItem: MouseArea {
                            QQC2.Label {
                                id: detailsText
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    leftMargin: 10
                                    right: parent.right
                                    rightMargin: 10
                                }
                                wrapMode: Text.WrapAnywhere
                                font.pointSize: 8
                                text: {
                                    if (synthsButton.checked) {
                                        return root.selectedChannel.synthSlotsData[root.selectedChannel.selectedSlot.value]
                                    } else if (samplesButton.checked) {
                                        return root.selectedChannel.sampleSlotsData[root.selectedChannel.selectedSlot.value].filename
                                    } else if (fxButton.checked) {
                                        return root.selectedChannel.fxSlotsData[root.selectedChannel.selectedSlot.value]
                                    } else {
                                        return ""
                                    }
                                }
                            }

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

                    Item{
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }


    Zynthian.FilePickerDialog {
        id: samplePickerDialog
        parent: zlScreen.parent

        function pickSampleForSlot(slot, pickWhat) {
            samplePickerDialog.sampleSlot = slot;
            samplePickerDialog.clipToSave = root.selectedSlotRowItem.channel.samples[slot];
            samplePickerDialog.saveMode = (pickWhat === "save-location");
            if (pickWhat === "sample" || pickWhat === "save-location") {
                samplePickerDialog.folderModel.folder = samplePickerDialog.saveMode ? "/zynthian/zynthian-my-data/samples/my-samples" : "/zynthian/zynthian-my-data/samples";
                samplePickerDialog.folderModel.nameFilters = ["*.wav"];
            } else if (pickWhat === "sketch") {
                samplePickerDialog.folderModel.folder = samplePickerDialog.saveMode ? "/zynthian/zynthian-my-data/sketches/my-sketches" :  "/zynthian/zynthian-my-data/sketches";
                samplePickerDialog.folderModel.nameFilters = ["*.sketch.wav"];
            } else if (pickWhat === "recording") {
                samplePickerDialog.folderModel.folder = root.selectedSlotRowItem.channel.recordingDir;
                samplePickerDialog.folderModel.nameFilters = ["*.wav"];
            }
            samplePickerDialog.open();
            if (samplePickerDialog.saveMode) {
                // Use the clip's title - it will usually be the same as the
                // filename, but also we add the suffix later, and it looks
                // more "normal" if you then also use auto-name
                samplePickerDialog.fileNameToSave = samplePickerDialog.clipToSave.title;
            }
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
                let originalSuffix = clipToSave.path.split(".").slice(-1).join(".").toLowerCase();
                console.log("Testing", copyTo, "has the suffix", originalSuffix);
                if (copyTo.split(".").slice(-1).join(".").toLowerCase() != originalSuffix) {
                    console.log("It does not, append it");
                    copyTo = copyTo + "." + originalSuffix;
                }
                if (clipToSave.exportToFile(copyTo)) {
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
                loopPickerDialog.folderModel.folder = loopPickerDialog.saveMode ? "/zynthian/zynthian-my-data/sketches/my-sketches" :  "/zynthian/zynthian-my-data/sketches";
                loopPickerDialog.folderModel.nameFilters = ["*.sketch.wav"];
                loopPickerDialog.thingToPick = qsTr("Loop");
            } else if (pickWhat === "sample") {
                loopPickerDialog.folderModel.folder = loopPickerDialog.saveMode ? "/zynthian/zynthian-my-data/samples/my-samples" : "/zynthian/zynthian-my-data/samples";
                loopPickerDialog.folderModel.nameFilters = ["*.wav"];
                loopPickerDialog.thingToPick = qsTr("Sample");
            } else if (pickWhat === "recording") {
                loopPickerDialog.folderModel.folder = sketchPickerPopup.sketch.recordingDir;
                loopPickerDialog.folderModel.nameFilters = ["*.wav"];
                loopPickerDialog.thingToPick = qsTr("Recording");
            }
            loopPickerDialog.open();
            if (samplePickerDialog.saveMode) {
                // Use the clip's title - it will usually be the same as the
                // filename, but also we add the suffix later, and it looks
                // more "normal" if you then also use auto-name
                loopPickerDialog.fileNameToSave = loopPickerDialog.clipToSave.title;
            }
        }
        property QtObject theClip: null

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
        onAccepted: {
            if (loopPickerDialog.saveMode === true) {
                let copyTo = loopPickerDialog.selectedFile.filePath;
                let originalSuffix = loopPickerDialog.theClip.path.split(".").slice(-2).join(".").toLowerCase();
                console.log("Testing", copyTo, "has the suffix", originalSuffix);
                if (copyTo.split(".").slice(-2).join(".").toLowerCase() != originalSuffix) {
                    console.log("It does not, append it");
                    copyTo = copyTo + "." + originalSuffix;
                }
                if (loopPickerDialog.theClip.exportToFile(copyTo)) {
                    console.log("Successfully exported the clip with path name", loopPickerDialog.theClip.path, "to ", copyTo)
                } else {
                    console.log("Failed to export the clip with path name", loopPickerDialog.theClip.path, "to", copyTo)
                }
            } else {
                loopPickerDialog.theClip.importFromFile(loopPickerDialog.selectedFile.filePath);
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

    Zynthian.ActionPickerPopup {
        id: sketchPickerPopup
        objectName: "sketchPickerPopup"
        columns: 3
        rows: 3
        property QtObject sketch: root.selectedChannel && root.selectedChannel.selectedSlot.className === "TracksBar_sketchslot" ? root.selectedChannel.getClipsModelById(root.selectedChannel.selectedSlot.value).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex) : null
        actions: [
            QQC2.Action {
                text: qsTr("Save To Archive...")
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
                // TODO Return for 1.1
                enabled: false
                // text: qsTr("Unbounce...")
                // enabled: sketchPickerPopup.sketch && sketchPickerPopup.sketch.cppObjId !== -1 && shouldUnbounce
                property bool shouldUnbounce: sketchPickerPopup.sketch && sketchPickerPopup.sketch.metadata.audioType && sketchPickerPopup.sketch.metadata.audioType.length > 0
                onTriggered: {
                    sketchUnbouncer.unbounce(sketchPickerPopup.sketch, zynqtgui.sketchpad.song.scenesModel.selectedSequenceName, root.selectedChannel, root.selectedChannel.selectedSlot.value);
                }
            },
            QQC2.Action {
                text: qsTr("Pick Sample...")
                onTriggered: {
                    loopPickerDialog.pickLoopForClip(sketchPickerPopup.sketch, "sample");
                }
            },
            QQC2.Action {
                text: qsTr("Pick Loop...")
                onTriggered: {
                    loopPickerDialog.pickLoopForClip(sketchPickerPopup.sketch, "sketch");
                }
            },
            QQC2.Action {
                text: "Swap With Slot..."
                onTriggered: {
                    slotSwapperPopup.pickSlotToSwapWith(root.selectedChannel, "sketch", root.selectedChannel.selectedSlot.value);
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
        property QtObject sketch: root.selectedChannel && root.selectedChannel.selectedSlot.className === "TracksBar_sampleslot" ? root.selectedChannel.samples[root.selectedChannel.selectedSlot.value] : null
        columns: 3
        rows: 3
        actions: [
            QQC2.Action {
                text: qsTr("Save To Archive...")
                enabled: samplePickerPopup.sketch ? samplePickerPopup.sketch.cppObjId !== -1 : false
                onTriggered: {
                    samplePickerDialog.pickSampleForSlot(root.selectedChannel.selectedSlot.value, "save-location");
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
                // TODO Return for 1.1
                enabled: false
                // text: qsTr("Unbounce...")
                // enabled: (samplePickerPopup.sketch ? samplePickerPopup.sketch.cppObjId !== -1 : false) && shouldUnbounce
                property bool shouldUnbounce: samplePickerPopup.sketch && samplePickerPopup.sketch.metadata.audioType && samplePickerPopup.sketch.metadata.audioType.length > 0
                onTriggered: {
                    sketchUnbouncer.unbounce(samplePickerPopup.sketch, zynqtgui.sketchpad.song.scenesModel.selectedSequenceName, root.selectedChannel, root.selectedChannel.selectedSlot.value);
                }
            },
            QQC2.Action {
                text: qsTr("Edit Sample...")
                onTriggered: {
                    zynqtgui.callable_ui_action_simple("SCREEN_EDIT_CONTEXTUAL");
                }
            },
            QQC2.Action {
                // TODO Return for 1.1
                enabled: false
                // text: qsTr("Record...")
                onTriggered: {
                    applicationWindow().recordAudio();
                }
            },
            QQC2.Action {
                text: qsTr("Pick sample...")
                onTriggered: {
                    zynqtgui.callable_ui_action_simple("SCREEN_PRESET");
                }
            },
            QQC2.Action {
                text: "Swap with..."
                onTriggered: {
                    slotSwapperPopup.pickSlotToSwapWith(root.selectedChannel, "sample", root.selectedChannel.selectedSlot.value);
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
    Zynthian.ComboBox {
        id: externalMidiOutPicker
        visible: false
        function pickOutput(channel) {
            externalMidiOutPicker.channel = channel;
            for (let index = 0; index < Zynthbox.MidiRouter.model.midiOutSources.length; ++index) {
                let entry = Zynthbox.MidiRouter.model.midiOutSources[index];
                if (channel.externalSettings.midiOutDevice === "") {
                    if (entry.value === "external:ttymidi:MIDI") {
                        externalMidiOutPicker.selectIndex(index);
                        break;
                    }
                } else {
                    if (entry.value === channel.externalSettings.midiOutDevice) {
                        externalMidiOutPicker.selectIndex(index);
                        break;
                    }
                }
            }
            externalMidiOutPicker.onClicked();
        }
        property QtObject channel
        model: Zynthbox.MidiRouter.model.midiOutSources
        textRole: "text"
        onActivated: {
            if (index === -1) {
                externalMidiOutPicker.channel.externalSettings.midiOutDevice = "";
            } else {
                externalMidiOutPicker.channel.externalSettings.midiOutDevice = Zynthbox.MidiRouter.model.midiOutSources[index].value;
            }
        }
    }

    Zynthian.ActionPickerPopup {
        id: fxSetupDialog
        property var selectedFx: root.selectedChannel && root.selectedChannel.selectedSlot.className === "TracksBar_fxslot"
                                 ? root.selectedChannel.chainedFx[root.selectedChannel.selectedSlot.value]
                                 : root.selectedChannel && root.selectedChannel.selectedSlot.className === "TracksBar_sketchfxslot"
                                   ? root.selectedChannel.chainedSketchFx[root.selectedChannel.selectedSlot.value]
                                   : null

        actions: [
            Kirigami.Action {
                text: fxSetupDialog.selectedFx == null
                      ? qsTr("Pick FX")
                      : qsTr("Change FX")
                onTriggered: {
                    zynqtgui.forced_screen_back = "sketchpad"
                    zynqtgui.current_screen_id = "layer_effects"
                    zynqtgui.layer.page_after_layer_creation = "sketchpad"
                }
            },
            Kirigami.Action {
                text: qsTr("Change FX Preset")
                visible: fxSetupDialog.selectedFx != null
                onTriggered: {
                    zynqtgui.forced_screen_back = "sketchpad"
                    if (root.selectedChannel.selectedSlot.className == "TracksBar_fxslot") {
                        zynqtgui.current_screen_id = "effect_preset";
                    } else if (root.selectedChannel.selectedSlot.className == "TracksBar_sketchfxslot") {
                        zynqtgui.current_screen_id = "sketch_effect_preset";
                    }
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
                    if (root.selectedChannel.selectedSlot.className == "TracksBar_fxslot") {
                        root.requestSlotEqualizer(root.selectedChannel, "fx", root.selectedChannel.selectedSlot.value);
                    } else if (root.selectedChannel.selectedSlot.className == "TracksBar_sketchfxslot") {
                        root.requestSlotEqualizer(root.selectedChannel, "sketchfx", root.selectedChannel.selectedSlot.value);
                    }
                }
            },
            Kirigami.Action {
                text: qsTr("Swap with...")
                onTriggered: {
                    if (root.selectedChannel.selectedSlot.className == "TracksBar_fxslot") {
                        slotSwapperPopup.pickSlotToSwapWith(root.selectedChannel, "fx", root.selectedChannel.selectedSlot.value);
                    } else if (root.selectedChannel.selectedSlot.className == "TracksBar_sketchfxslot") {
                        slotSwapperPopup.pickSlotToSwapWith(root.selectedChannel, "sketch-fx", root.selectedChannel.selectedSlot.value);
                    }
                }
            },
            Kirigami.Action {
                text: "Set Input Overrides..."
                visible: fxSetupDialog.selectedFx != null
                onTriggered: {
                    if (root.selectedChannel.selectedSlot.className == "TracksBar_fxslot") {
                        slotInputPicker.pickSlotInputs(root.selectedChannel, "fx", root.selectedChannel.selectedSlot.value);
                    } else if (root.selectedChannel.selectedSlot.className == "TracksBar_sketchfxslot") {
                        // TODO : sketchFx
                    }
                }
            },
            Kirigami.Action {
                text: qsTr("Remove FX")
                visible: fxSetupDialog.selectedFx != null
                onTriggered: {
                    if (root.selectedChannel && root.selectedChannel.selectedSlot.className === "TracksBar_fxslot") {
                        root.selectedSlotRowItem.channel.removeSelectedFxFromChain()
                    } else if (root.selectedChannel && root.selectedChannel.selectedSlot.className === "TracksBar_sketchfxslot") {
                        root.selectedSlotRowItem.channel.removeSelectedSketchFxFromChain()
                    }
                }
            }
        ]
    }
}
