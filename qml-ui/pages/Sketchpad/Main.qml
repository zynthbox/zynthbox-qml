/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>

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
import QtQuick.Window 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQml.Models 2.10
import org.kde.kirigami 2.4 as Kirigami
import org.zynthian.quick 1.0 as ZynQuick

import '../../Zynthian' 1.0 as Zynthian
import '../SessionDashboard'

Zynthian.ScreenPage {
    id: root

    property alias zlScreen: root
    property alias bottomStack: bottomStack
    readonly property QtObject song: zynthian.sketchpad.song
    property QtObject selectedChannel: applicationWindow().selectedChannel
    property bool displaySceneButtons: zynthian.sketchpad.displaySceneButtons
    property bool displayTrackButtons: false
    property bool songMode: zynthian.sketchpad.song.sketchesModel.songMode

    /*
    Used to temporarily store last clicked object by user
    If the clicked object is a QObject the object is stored otherwise the index is stored
    Structure : {
        "className": "sketch_track" | "sketch_part" | obj.className
        "value": QObject or int depending on the type of selected object
        "component": QML Component which was clicked to determine co-ordinates of lastSelectedSketchOutline
    }
    */
    property var lastSelectedObj: null
    /*
    Used to temporarily cache clip/channel object to be copied
    copySourceObj is copied from lastSelectedObj when copy button is clicked
    */
    property var copySourceObj: null

    title: qsTr("Sketchpad")
    screenId: "sketchpad"
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    backAction.visible: false

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Sketchpad")

            Kirigami.Action {
                // Rename Save button as Save as for temp sketchpad
                text: root.song.isTemp ? qsTr("Save As") : qsTr("Save")
                onTriggered: {
                    if (root.song.isTemp) {
                        fileNameDialog.dialogType = "save";
                        fileNameDialog.fileName = "Sketchpad-1";
                        fileNameDialog.open();
                    } else {
                        zynthian.sketchpad.saveSketchpad();
                    }
                }
            }
            Kirigami.Action {
                text: qsTr("Save As")
                visible: !root.song.isTemp
                onTriggered: {
                    fileNameDialog.dialogType = "saveas";
                    fileNameDialog.fileName = song.name;
                    fileNameDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Clone As")
                visible: !root.song.isTemp
                onTriggered: {
                    fileNameDialog.dialogType = "savecopy";
                    fileNameDialog.fileName = song.sketchpadFolderName;
                    fileNameDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Load Sketchpad")
                onTriggered: {
                    sketchpadPickerDialog.folderModel.folder = sketchpadPickerDialog.rootFolder;
                    sketchpadPickerDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("New Sketchpad")
                onTriggered: {
                    zynthian.sketchpad.newSketchpad()
                }
            }
        },
        Kirigami.Action {
            text: qsTr("Mixer")
            checked: bottomStack.slotsBar.mixerButton.checked
            onTriggered: {
                if (!root.songMode) {
                    if (bottomStack.slotsBar.mixerButton.checked) {
                        bottomStack.slotsBar.channelButton.checked = true
                    } else {
                        bottomStack.slotsBar.mixerButton.checked = true
                    }
                }
            }
        },
        Kirigami.Action {
            text: qsTr("Sounds")
            onTriggered: zynthian.show_modal("sound_categories")
        },

        Kirigami.Action {
            text: "Get New Sketchpads"
            onTriggered: {
                zynthian.show_modal("sketchpad_downloader")
            }
        }

        // Disable undo for now
        /*Kirigami.Action {
            text: qsTr("Undo")
            enabled: root.song.historyLength > 0
            visible: !root.song.isTemp
            onTriggered: {
                root.song.undo();
            }
        }*/
    ]

    cuiaCallback: function(cuia) {
        console.log("ZL Cuia Handler :", cuia)

        if (sketchpadPickerDialog.opened) {
            return sketchpadPickerDialog.cuiaCallback(cuia);
        }

        // Forward CUIA actions to bottomBar only when bottomBar is open
        if (bottomStack.currentIndex === 0) {
            if (bottomBar.tabbedView.activeItem.cuiaCallback != null) {
                if (bottomBar.tabbedView.activeItem.cuiaCallback(cuia)) {
                    return true;
                }
            }
        } else {
            if (bottomStack.itemAt(bottomStack.currentIndex).cuiaCallback != null) {
                if (bottomStack.itemAt(bottomStack.currentIndex).cuiaCallback(cuia)) {
                    return true;
                }
            }
        }

        switch (cuia) {
            case "SELECT_UP":
                var selectedMidiChannel = root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow];
                if (root.selectedChannel.checkIfLayerExists(selectedMidiChannel)) {
                    zynthian.layer.selectPrevPreset(selectedMidiChannel);
                    infoBar.updateInfoBar();
                }
                return true;

            case "SELECT_DOWN":
                var selectedMidiChannel = root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow];
                if (root.selectedChannel.checkIfLayerExists(selectedMidiChannel)) {
                    zynthian.layer.selectNextPreset(selectedMidiChannel);
                    infoBar.updateInfoBar();
                }
                return true;

            case "MODE_SWITCH_SHORT":
            case "MODE_SWITCH_LONG":
            case "MODE_SWITCH_BOLD":
                if (zynthian.altButtonPressed) {
                    // Cycle between channel, mixer, synths, samples, fx when alt button is not pressed
                    if (bottomStack.slotsBar.channelButton.checked) {
                        bottomStack.slotsBar.partButton.checked = true
                    } else if (bottomStack.slotsBar.partButton.checked) {
                        bottomStack.slotsBar.synthsButton.checked = true
                    } else if (bottomStack.slotsBar.synthsButton.checked) {
                        bottomStack.slotsBar.samplesButton.checked = true
                    } else if (bottomStack.slotsBar.samplesButton.checked) {
                        bottomStack.slotsBar.fxButton.checked = true
                    } else if (bottomStack.slotsBar.fxButton.checked) {
                        bottomStack.slotsBar.channelButton.checked = true
                    } else {
                        bottomStack.slotsBar.channelButton.checked = true
                    }

                    return true;
                } else {
//                    // Cycle through the channelAudioTypes when alt button is pressed
//                    if (root.selectedChannel.channelAudioType === "synth") {
//                        root.selectedChannel.channelAudioType = "sample-trig"
//                    } else if (root.selectedChannel.channelAudioType === "sample-trig") {
//                        root.selectedChannel.channelAudioType = "sample-slice"
//                    } else if (root.selectedChannel.channelAudioType === "sample-slice") {
//                        root.selectedChannel.channelAudioType = "sample-loop"
//                    } else if (root.selectedChannel.channelAudioType === "sample-loop") {
//                        // HACK
//                        // FIXME : When changing channelAudioType to external it somehow first gets selected to "synth"
//                        //         And then on changing the value 2nd time it finally changes to "external"
//                        //         Couldn't find any probable cause for the issue but forcefully setting to external twice
//                        //         seems to do temporarily solve the problem. But this issue needs to be fixed ASAP
//                        root.selectedChannel.channelAudioType = "external"
//                        root.selectedChannel.channelAudioType = "external"
//                    } else if (root.selectedChannel.channelAudioType === "external") {
//                        root.selectedChannel.channelAudioType = "synth"
//                    }

//                    // Toggle between Part and Channel bar with FX Button
//                    if (!bottomStack.slotsBar.partButton.checked) {
//                        bottomStack.slotsBar.partButton.checked = true
//                    } else {
//                        bottomStack.slotsBar.channelButton.checked = true
//                    }

//                    return true;
                }

                return false;

            case "SCREEN_ADMIN":
                if (root.selectedChannel && root.selectedChannel.channelAudioType === "synth") {
                    var sound = root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow]

                    // when synth and slot is active, edit that sound or show popup when empty
                    if (sound >= 0 && root.selectedChannel.checkIfLayerExists(sound)) {
                        zynthian.fixed_layers.activate_index(sound)
                        zynthian.control.single_effect_engine = null;
                        zynthian.current_screen_id = "control";
                        zynthian.forced_screen_back = "sketchpad"
                    } else {
                        bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                    }
                } else if (root.selectedChannel && ["sample-trig", "sample-slice"].indexOf(root.selectedChannel.channelAudioType) >= 0) {
                    var sample = root.selectedChannel.samples[root.selectedChannel.selectedSlotRow]

                    // when sample and slot is active, goto wave editor or show popup when empty
                    if (sample && sample.path && sample.path.length > 0) {
                        bottomStack.bottomBar.controlType = BottomBar.ControlType.Channel;
                        bottomStack.bottomBar.controlObj = root.selectedChannel;
                        bottomStack.slotsBar.bottomBarButton.checked = true;
                        bottomStack.bottomBar.channelWaveEditorAction.trigger();
                    } else {
                        bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                    }
                } else if (root.selectedChannel && root.selectedChannel.channelAudioType === "sample-loop") {
                    var clip = root.selectedChannel.clipsModel.getClip(zynthian.sketchpad.song.scenesModel.selectedTrackIndex)

                    // when loop and slot is active, goto wave editor or show popup when empty
                    if (clip && clip.path && clip.path.length > 0) {
                        bottomStack.bottomBar.controlType = BottomBar.ControlType.Pattern;
                        bottomStack.bottomBar.controlObj = root.selectedChannel.clipsModel.getClip(zynthian.sketchpad.song.scenesModel.selectedTrackIndex);
                        bottomStack.slotsBar.bottomBarButton.checked = true;
                        bottomStack.bottomBar.waveEditorAction.trigger();
                    } else {
                        bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                    }
                } else {
                    // do nothing for other cases
                    return false
                }

                return true
        }

        // If cuia is not handled by any bottomBars or the switch block
        // call the common cuiaHandler
        return Zynthian.CommonUtils.cuiaHandler(cuia, root.selectedChannel, bottomStack)
    }

    Connections {
        target: bottomBar.tabbedView
        onActiveActionChanged: updateLedVariablesTimer.restart()
    }

    Timer {
        id: updateLedVariablesTimer
        interval: 30
        repeat: false
        onTriggered: {
            // Check if song bar is active
            if (bottomStack.slotsBar.bottomBarButton.checked && // Checks if bottombar is visible
                bottomBar.tabbedView.activeAction.page.search("SongBar") >= 0 // Checks if current active page is sound combinator or not
            ) {
                zynthian.songBarActive = true;
            } else {
                zynthian.songBarActive = false;
            }

            // Check if sound combinator is active
            if (bottomStack.slotsBar.bottomBarButton.checked && // Checks if bottombar is visible
                bottomBar.tabbedView.activeAction.page.search("ChannelsViewSoundsBar") >= 0 // Checks if current active page is sound combinator or not
            ) {
                zynthian.soundCombinatorActive = true;
            } else {
                zynthian.soundCombinatorActive = false;
            }

            // Check if sound combinator is active
            if (bottomStack.slotsBar.bottomBarButton.checked && // Checks if bottombar is visible
                bottomBar.tabbedView.activeAction.page.search("SamplesBar") >= 0 // Checks if current active page is samples bar
            ) {
                zynthian.channelSamplesBarActive = true;
            } else {
                zynthian.channelSamplesBarActive = false;
            }

            // Check if channel wave editor bar is active
            if (bottomStack.slotsBar.bottomBarButton.checked && // Checks if bottombar is visible
                bottomBar.controlType === BottomBar.ControlType.Channel && // Checks if channel is selected
                bottomBar.tabbedView.activeAction.page.search("WaveEditorBar") >= 0 // Checks if current active page is wave editor or not
            ) {
                zynthian.channelWaveEditorBarActive = true;
            } else {
                zynthian.channelWaveEditorBarActive = false;
            }

            // Check if clip wave editor bar is active
            if (bottomStack.slotsBar.bottomBarButton.checked && // Checks if bottombar is visible
                (bottomBar.controlType === BottomBar.ControlType.Clip || bottomBar.controlType === BottomBar.ControlType.Pattern) && // Checks if clip/pattern is selected
                bottomBar.tabbedView.activeAction.page.search("WaveEditorBar") >= 0 // Checks if current active page is wave editor or not
            ) {
                zynthian.clipWaveEditorBarActive = true;
            } else {
                zynthian.clipWaveEditorBarActive = false;
            }

            if (bottomStack.slotsBar.channelButton.checked) {
                console.log("LED : Slots Channel Bar active")
                zynthian.slotsBarChannelActive = true;
                zynthian.slotsBarPartActive = false;
                zynthian.slotsBarMixerActive = false;
                zynthian.slotsBarSynthsActive = false;
                zynthian.slotsBarSamplesActive = false;
                zynthian.slotsBarFxActive = false;
                // zynthian.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.mixerButton.checked) {
                console.log("LED : Slots Mixer Bar active")
                zynthian.slotsBarChannelActive = false;
                zynthian.slotsBarPartActive = false;
                zynthian.slotsBarMixerActive = true;
                zynthian.slotsBarSynthsActive = false;
                zynthian.slotsBarSamplesActive = false;
                zynthian.slotsBarFxActive = false;
                // zynthian.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.partButton.checked) {
                console.log("LED : Slots Part Bar active")
                zynthian.slotsBarChannelActive = false;
                zynthian.slotsBarPartActive = true;
                zynthian.slotsBarMixerActive = false;
                zynthian.slotsBarSynthsActive = false;
                zynthian.slotsBarSamplesActive = false;
                zynthian.slotsBarFxActive = false;
                // zynthian.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.synthsButton.checked) {
                console.log("LED : Slots Synths Bar active")
                zynthian.slotsBarChannelActive = false;
                zynthian.slotsBarPartActive = false;
                zynthian.slotsBarMixerActive = false;
                zynthian.slotsBarSynthsActive = true;
                zynthian.slotsBarSamplesActive = false;
                zynthian.slotsBarFxActive = false;
                // zynthian.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.samplesButton.checked) {
                console.log("LED : Slots Samples Bar active")
                zynthian.slotsBarChannelActive = false;
                zynthian.slotsBarPartActive = false;
                zynthian.slotsBarMixerActive = false;
                zynthian.slotsBarSynthsActive = false;
                zynthian.slotsBarSamplesActive = true;
                zynthian.slotsBarFxActive = false;
                // zynthian.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.fxButton.checked) {
                console.log("LED : Slots FX Bar active")
                zynthian.slotsBarChannelActive = false;
                zynthian.slotsBarPartActive = false;
                zynthian.slotsBarMixerActive = false;
                zynthian.slotsBarSynthsActive = false;
                zynthian.slotsBarSamplesActive = false;
                zynthian.slotsBarFxActive = true;
                // zynthian.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.soundCombinatorButton.checked) {
                console.log("LED : Slots FX Bar active")
                zynthian.slotsBarChannelActive = false;
                zynthian.slotsBarPartActive = false;
                zynthian.slotsBarMixerActive = false;
                zynthian.slotsBarSynthsActive = false;
                zynthian.slotsBarSamplesActive = false;
                zynthian.slotsBarFxActive = false;
                // zynthian.soundCombinatorActive = true;
            } else {
                console.log("LED : No Slots Bar active")
                zynthian.slotsBarChannelActive = false;
                zynthian.slotsBarPartActive = false;
                zynthian.slotsBarMixerActive = false;
                zynthian.slotsBarSynthsActive = false;
                zynthian.slotsBarSamplesActive = false;
                zynthian.slotsBarFxActive = false;
                // zynthian.soundCombinatorActive = false;
            }
        }
    }

    Connections {
        target: zynthian.sketchpad
        onSong_changed: {
            console.log("$$$ Song Changed :", song)

            bottomBar.controlType = BottomBar.ControlType.Song;
            bottomBar.controlObj = root.song;
            bottomStack.slotsBar.channelButton.checked = true
        }
    }

    Component.onCompleted: {
        applicationWindow().controlsVisible = true;
        bottomBar.controlType = BottomBar.ControlType.Song;
        bottomBar.controlObj = root.song;
        bottomStack.slotsBar.channelButton.checked = true
    }

    Component.onDestruction: {
        applicationWindow().controlsVisible = true;
    }

    Zynthian.SaveFileDialog {
        property string dialogType: "save"

        id: fileNameDialog
        visible: false

        headerText: {
            if (fileNameDialog.dialogType == "savecopy")
                return qsTr("Clone Sketchpad")
            else if (fileNameDialog.dialogType === "saveas")
                return qsTr("New version")
            else
                return qsTr("New Sketchpad")
        }
        conflictText: {
            if (dialogType == "savecopy")
                return qsTr("Sketchpad Exists")
            else if (dialogType == "saveas")
                return qsTr("Version Exists")
            else
                return qsTr("Exists")
        }
        overwriteOnConflict: false

        onFileNameChanged: {
            console.log("File Name : " + fileName)
            fileCheckTimer.restart()
        }
        Timer {
            id: fileCheckTimer
            interval: 300
            onTriggered: {
                if (fileNameDialog.dialogType == "savecopy"
                    && fileNameDialog.fileName.length > 0
                    && zynthian.sketchpad.sketchpadExists(fileNameDialog.fileName)) {
                    // Sketchpad with name already exists
                    fileNameDialog.conflict = true;
                } else if (fileNameDialog.dialogType === "saveas"
                           && fileNameDialog.fileName.length > 0
                           && zynthian.sketchpad.versionExists(fileNameDialog.fileName)) {
                    fileNameDialog.conflict = true;
                } else if (fileNameDialog.dialogType === "save"
                           && root.song.isTemp
                           && fileNameDialog.fileName.length > 0
                           && zynthian.sketchpad.sketchpadExists(fileNameDialog.fileName)) {
                    fileNameDialog.conflict = true;
                } else {
                    fileNameDialog.conflict = false;
                }
            }
        }

        onAccepted: {
            console.log("Accepted")

            if (dialogType === "save") {
                zynthian.sketchpad.createSketchpad(fileNameDialog.fileName)
            } else if (dialogType === "saveas") {
                root.song.name = fileNameDialog.fileName;
                zynthian.sketchpad.saveSketchpad();
            } else if (dialogType === "savecopy") {
                zynthian.sketchpad.saveCopy(fileNameDialog.fileName);
            }
        }
        onRejected: {
            console.log("Rejected")
        }
    }

    Zynthian.FilePickerDialog {
        id: sketchpadPickerDialog
        parent: root

        headerText: qsTr("Pick a sketchpad")
        rootFolder: "/zynthian/zynthian-my-data/sketchpads/"
        folderModel {
            nameFilters: ["*.sketchpad.json"]
        }
        onFileSelected: {
            console.log("Selected Sketchpad : " + file.fileName + "("+ file.filePath +")")
            zynthian.sketchpad.loadSketchpad(file.filePath, false)
        }
    }

    function resetBottomBar(toggleBottomBar) {
        if (toggleBottomBar) {
            if (bottomStack.slotsBar.channelButton.checked) {
                bottomStack.slotsBar.partButton.checked = true
            } else {
                bottomStack.slotsBar.channelButton.checked = true
            }
        } else {
            bottomStack.slotsBar.channelButton.checked = true
        }
    }

    contentItem : Item {
        id: content

        Rectangle {
            id: lastSelectedObjIndicator

            visible: root.lastSelectedObj && root.lastSelectedObj.className === "sketchpad_part"
                        ? zynthian.slotsBarPartActive
                        : root.lastSelectedObj

            width: root.lastSelectedObj && root.lastSelectedObj.component ? root.lastSelectedObj.component.width + 8 : 0
            height: root.lastSelectedObj && root.lastSelectedObj.component ? root.lastSelectedObj.component.height + 8 : 0
            x: root.lastSelectedObj && root.lastSelectedObj.component ? root.lastSelectedObj.component.mapToItem(content, 0, 0).x - 4 : 0
            y: root.lastSelectedObj && root.lastSelectedObj.component ? root.lastSelectedObj.component.mapToItem(content, 0, 0).y - 4 : 0
            z: 1000
            border.width: 2
            border.color: Qt.rgba(255, 255, 255, 0.8)

            color: "transparent"
        }

        Rectangle {
            id: copySourceObjIndicator

            visible: root.copySourceObj && root.copySourceObj.className === "sketchpad_part"
                        ? zynthian.slotsBarPartActive
                        : root.copySourceObj

            width: root.copySourceObj && root.copySourceObj.component ? root.copySourceObj.component.width : 0
            height: root.copySourceObj && root.copySourceObj.component ? root.copySourceObj.component.height : 0
            x: root.copySourceObj && root.copySourceObj.component ? root.copySourceObj.component.mapToItem(content, 0, 0).x : 0
            y: root.copySourceObj && root.copySourceObj.component ? root.copySourceObj.component.mapToItem(content, 0, 0).y : 0
            z: 1000

            color: "#882196f3"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.bottomMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            InfoBar {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.leftMargin: Kirigami.Units.gridUnit * 0.5
                Layout.rightMargin: Kirigami.Units.gridUnit * 0.5
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: Kirigami.Units.gridUnit * 9
                spacing: 1

                ColumnLayout {
                    id: sketchpadSketchHeadersColumn
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    spacing: 1

                    TableHeader {
                        id: songCell
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        highlightOnFocus: false
                        highlighted: !root.songMode && root.displayTrackButtons
                        text: root.song.name
                        subText: qsTr("Track T%1").arg(root.song.scenesModel.selectedTrackIndex + 1)
                        onPressed: {
                            root.displayTrackButtons = !root.displayTrackButtons
                            zynthian.sketchpad.song.sketchesModel.songMode = false
                            zynthian.sketchpad.displaySceneButtons = false
                        }
                    }

                    TableHeader {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                        Layout.minimumHeight: Kirigami.Units.gridUnit * 3

                        text: qsTr("Song Mode")
                        highlightOnFocus: false
                        highlighted: root.songMode
                        onPressed: {
                            if (zynthian.sketchpad.isMetronomeRunning) {
                                applicationWindow().showPassiveNotification("Cannot switch song mode when timer is running", 1500)
                            } else {
                                zynthian.sketchpad.song.sketchesModel.songMode = !zynthian.sketchpad.song.sketchesModel.songMode
                                root.displayTrackButtons = false
                                zynthian.sketchpad.displaySceneButtons = false
                            }
                        }
                    }

                    TableHeader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        text: root.songMode ? qsTr("Sketch") : qsTr("Scene")
                        subText: root.songMode ? root.song.sketchesModel.selectedSketch.name : root.song.scenesModel.selectedSceneName
                        highlightOnFocus: false
                        highlighted: !root.songMode &&
                                     root.displaySceneButtons
                        onPressed: {
                            if (zynthian.sketchpad.displaySceneButtons) {
                                zynthian.sketchpad.displaySceneButtons = false
                            } else {
                                zynthian.sketchpad.displaySceneButtons = true
                                zynthian.sketchpad.song.sketchesModel.songMode = false
                                root.displayTrackButtons = false
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: sketchpadClipsColumn
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 1

                    // Should show arrows is True when segment count is greater than 10 and hence needs arrows to scroll
                    property bool shouldShowSegmentArrows: root.song.sketchesModel.selectedSketch.segmentsModel.count > 10
                    // Segment offset will determine what is the first segment to display when arrow keys are displayed
                    property int segmentOffset: 0
                    // Maximum segment offset allows the arrow keys to check if there are any more segments outside view
                    property int maximumSegmentOffset: root.song.sketchesModel.selectedSketch.segmentsModel.count - 10 + 2

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 1

                        Connections {
                            target: root.song.sketchesModel.selectedSketch.segmentsModel
                            onSelectedSegmentIndexChanged: {
                                // When selectedSegmentIndex changes (i.e. being set with Big Knob), adjust visible segments so that selected segment is brought into view
                                if (root.songMode) {
                                    if (root.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex > (sketchpadClipsColumn.segmentOffset+7)) {
                                        console.log("selected segment is outside visible segments on the right :", root.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex, sketchpadClipsColumn.segmentOffset, Math.min(sketchpadClipsColumn.maximumSegmentOffset, root.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex - 7))
                                        sketchpadClipsColumn.segmentOffset = Math.min(sketchpadClipsColumn.maximumSegmentOffset, root.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex - 7)
                                    } else if (root.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex < sketchpadClipsColumn.segmentOffset) {
                                        console.log("selected segment is outside visible segments on the left :", root.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex, sketchpadClipsColumn.segmentOffset, root.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex)
                                        sketchpadClipsColumn.segmentOffset = root.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex
                                    }
                                }
                            }
                        }

                        // Display 10 header buttons which will show channel header buttons when song mode is not active and segment buttons when song mode is active
                        Repeater {
                            id: channelsHeaderRepeater

                            // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                            model: zynthian.isBootingComplete
                                    ? 10
                                    : 0

                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TableHeader {
                                    id: trackHeaderDelegate

                                    property QtObject channel: root.song.channelsModel.getChannel(index)
                                    property QtObject sketch: root.song.sketchesModel.getSketch(index)

                                    visible: !root.songMode && root.displayTrackButtons
                                    anchors.fill: parent
                                    color: Kirigami.Theme.backgroundColor
                                    highlightOnFocus: false
                                    highlighted: root.displayTrackButtons
                                                    ? root.song.scenesModel.selectedTrackIndex === index
                                                    : ""

                                    text: root.displayTrackButtons
                                            ? qsTr("T%1").arg(index+1)
                                            : ""
                                    textSize: 10

                                    onPressed: {
                                        if (root.displayTrackButtons) {
                                            root.lastSelectedObj = {
                                                className: "sketchpad_track",
                                                value: index,
                                                component: trackHeaderDelegate
                                            }
                                            root.song.scenesModel.selectedTrackIndex = index
                                        }
                                    }
                                }

                                TableHeader {
                                    id: sketchHeaderDelegate

                                    property QtObject channel: root.song.channelsModel.getChannel(index)
                                    property QtObject sketch: root.song.sketchesModel.getSketch(index)

                                    visible: root.songMode
                                    color: Kirigami.Theme.backgroundColor
                                    active: !sketchHeaderDelegate.sketch.isEmpty

                                    anchors.fill: parent

                                    highlightOnFocus: false
                                    highlighted: sketchHeaderDelegate.sketch.sketchId === root.song.sketchesModel.selectedSketchIndex

                                    text: sketchHeaderDelegate.sketch.name
                                    textSize: 10

                                    onPressed: {
                                        root.song.sketchesModel.selectedSketchIndex = index
                                        root.lastSelectedObj = {
                                            className: sketchHeaderDelegate.sketch.className,
                                            value: sketchHeaderDelegate.sketch,
                                            component: sketchHeaderDelegate
                                        }
                                    }
                                }

                                ChannelHeader2 {
                                    id: channelHeaderDelegate
                                    visible: !root.songMode && !root.displayTrackButtons
                                    anchors.fill: parent

                                    channel: root.song.channelsModel.getChannel(index)
                                    text: channelHeaderDelegate.channel.name

                                    Connections {
                                        target: channelHeaderDelegate.channel
                                        function updateKeyZones() {
                                            // all-full is the default, but "manual" is an option and we should leave things alone in that case, so that's this function's default
                                            var sampleSettings = [];
                                            if (channelHeaderDelegate.channel.keyZoneMode == "all-full") {
                                                sampleSettings = [
                                                    [0, 127, 0],
                                                    [0, 127, 0],
                                                    [0, 127, 0],
                                                    [0, 127, 0],
                                                    [0, 127, 0]
                                                ];
                                            } else if (channelHeaderDelegate.channel.keyZoneMode == "split-full") {
                                                // auto-split keyzones: SLOT 4 c-1 - b1, SLOT 2 c1-b3, SLOT 1 c3-b5, SLOT 3 c5-b7, SLOT 5 c7-c9
                                                // root key transpose in semtitones: +48, +24 ,0 , -24, -48
                                                sampleSettings = [
                                                    [48, 71, 0], // slot 1
                                                    [24, 47, -24], // slot 2
                                                    [72, 95, 24], // slot 3
                                                    [0, 23, -48], // slot 4
                                                    [96, 119, 48] // slot 5
                                                ];
                                            } else if (channelHeaderDelegate.channel.keyZoneMode == "split-narrow") {
                                                // Narrow split puts the samples on the keys C4, D4, E4, F4, G4, and plays them as C4 on those notes
                                                sampleSettings = [
                                                    [60, 60, 0], // slot 1
                                                    [62, 62, 2], // slot 2
                                                    [64, 64, 4], // slot 3
                                                    [65, 65, 5], // slot 4
                                                    [67, 67, 7] // slot 5
                                                ];
                                            }
                                            if (sampleSettings.length > 0) {
                                                for (var i = 0; i < channelHeaderDelegate.channel.samples.length; ++i) {
                                                    var sample = channelHeaderDelegate.channel.samples[i];
                                                    var clip = ZynQuick.PlayGridManager.getClipById(sample.cppObjId);
                                                    if (clip && i < sampleSettings.length) {
                                                        clip.keyZoneStart = sampleSettings[i][0];
                                                        clip.keyZoneEnd = sampleSettings[i][1];
                                                        clip.rootNote = 60 + sampleSettings[i][2];
                                                    }
                                                }
                                            }
                                        }
                                        onKeyZoneModeChanged: updateKeyZones();
                                        onSamplesChanged: updateKeyZones();
                                    }
                                    subText: null
                                    subSubText: {
                                        if (channelHeaderDelegate.channel.channelAudioType === "sample-loop") {
                                            return qsTr("Loop")
                                        } else if (channelHeaderDelegate.channel.channelAudioType === "sample-trig") {
                                            return qsTr("Smp: Trig")
                                        } else if (channelHeaderDelegate.channel.channelAudioType === "sample-slice") {
                                            return qsTr("Smp: Slice")
                                        } else if (channelHeaderDelegate.channel.channelAudioType === "synth") {
                                            return qsTr("Synth")
                                        } else if (channelHeaderDelegate.channel.channelAudioType === "external") {
                                            return qsTr("External")
                                        }
                                    }

                                    subSubTextSize: 7

                                    Binding {
                                        target: channelHeaderDelegate
                                        property: "color"
                                        when: root.visible
                                        delayed: true

                                        value: {
                                            if (root.copySourceObj && root.copySourceObj.value === model.channel)
                                                return "#ff2196f3"
                                            else if (channelHeaderDelegate.channel.channelAudioType === "synth")
                                                return "#66ff0000"
                                            else if (channelHeaderDelegate.channel.channelAudioType === "sample-loop")
                                                return "#6600ff00"
                                            else if (channelHeaderDelegate.channel.channelAudioType === "sample-trig")
                                                return "#66ffff00"
                                            else if (channelHeaderDelegate.channel.channelAudioType === "sample-slice")
                                                return "#66ffff00"
                                            else if (channelHeaderDelegate.channel.channelAudioType === "external")
                                                return "#998e24aa"
                                            else
                                                return "#66888888"
                                        }
                                    }

                                    highlightOnFocus: false
                                    highlighted: index === zynthian.session_dashboard.selectedChannel // If song mode is not active, highlight if current cell is selected channel

                                    onPressed: {
                                        // If song mode is not active, clicking on cells should activate that channel
                                        root.lastSelectedObj = {
                                            className: channelHeaderDelegate.channel.className,
                                            value: channelHeaderDelegate.channel,
                                            component: channelHeaderDelegate
                                        }

                                        zynthian.session_dashboard.selectedChannel = index;

                                        // zynthian.session_dashboard.disableNextSoundSwitchTimer();

                                        Qt.callLater(function() {
                                            // Open MixedChannelsViewBar and switch to channel
                                            // bottomStack.slotsBar.channelButton.checked = true
                                            root.resetBottomBar(false)
                                            bottomBar.controlType = BottomBar.ControlType.Channel;
                                            bottomBar.controlObj = channelHeaderDelegate.channel;
                                        })
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 1

                        Repeater {
                            // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                            model: zynthian.isBootingComplete ? root.song.channelsModel : 0

                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TableHeader {
                                    anchors.fill: parent
                                    visible: !root.songMode && root.displaySceneButtons
                                    text: String.fromCharCode(65+index).toUpperCase()
                                    highlighted: !root.songMode &&
                                                 index === root.song.scenesModel.selectedSceneIndex
                                    highlightOnFocus: false
                                    onPressed: {
                                        if (root.songMode) {
                                            root.song.sketchesModel.selectedSketch.segmentsModel.selectedSegment.copyClipsFromScene(index)
                                        } else {
                                            Zynthian.CommonUtils.switchToScene(index);
                                        }
                                    }
                                }

                                TableHeader {
                                    id: segmentHeader

                                    property bool startDrag: false
                                    property point dragStartPosition
                                    property int segmentOffsetAtDragStart

                                    // Calculate current cell's segment index
                                    // If arrow keys are visible, take into account that arrow keys will be visible no cells 0 and 9 respectively
                                    property int thisSegmentIndex: index +
                                                                   (sketchpadClipsColumn.shouldShowSegmentArrows ? sketchpadClipsColumn.segmentOffset : 0) + // Offset index if arrows are visible else 0
                                                                   (sketchpadClipsColumn.shouldShowSegmentArrows ? -1 : 0) // if arrows are being displayed, display segment from 2nd slot onwards
                                    // A little odd looking perhaps - we use the count changed signal here to ensure we refetch the segments when we add, remove, or otherwise change the model
                                    property QtObject segment: root.song.sketchesModel.selectedSketch.segmentsModel.count > 0
                                                                ? root.song.sketchesModel.selectedSketch.segmentsModel.get_segment(segmentHeader.thisSegmentIndex)
                                                                : null

                                    visible: root.songMode
                                    anchors.fill: parent
                                    text: root.song.sketchesModel.selectedSketch.segmentsModel.count > 10
                                              ? index === 0
                                                  ? "<"
                                                  : index === 9
                                                      ? ">"
                                                      : segmentHeader.segment
                                                          ? segmentHeader.segment.name
                                                          : ""
                                              : segmentHeader.segment
                                                  ? segmentHeader.segment.name
                                                  : ""
                                    subText: {
                                        if (root.song.sketchesModel.selectedSketch.segmentsModel.count > 10 && (index === 0 || index === 9)) {
                                            return " "
                                        } else if (!segmentHeader.segment || (segmentHeader.segment.barLength === 0 && segmentHeader.segment.beatLength === 0)) {
                                            return " "
                                        } else {
                                            return segmentHeader.segment.barLength + "." + segmentHeader.segment.beatLength
                                        }
                                    }

                                    textSize: 10
                                    subTextSize: 9

                                    active: {
                                        // If song mode is active, mark respective arrow key cell as active if there are segments outside view
                                        if (sketchpadClipsColumn.shouldShowSegmentArrows && index === 0 && sketchpadClipsColumn.segmentOffset > 0) {
                                            return true
                                        } else if (sketchpadClipsColumn.shouldShowSegmentArrows && index === 9 && sketchpadClipsColumn.segmentOffset < sketchpadClipsColumn.maximumSegmentOffset) {
                                            return true
                                        }

                                        // If song mode is active, mark segment cell as active if it has a segment
                                        if (segmentHeader.segment != null) {
                                            return true
                                        } else {
                                            return false
                                        }
                                    }

                                    highlightOnFocus: false
                                    highlighted: {
                                        // If song mode is active and arrow keys are visible, do not highlight arrow key cells
                                        if (sketchpadClipsColumn.shouldShowSegmentArrows && index === 0) {
                                            return false
                                        } else if (sketchpadClipsColumn.shouldShowSegmentArrows && index === 9) {
                                            return false
                                        }

                                        // If song mode is active and cell is not an arrow key, then highlight if selected segment is current cell
                                        return segmentHeader.thisSegmentIndex === root.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex
                                    }

                                    onPressed: {
                                        if (sketchpadClipsColumn.shouldShowSegmentArrows && index === 0) {
                                            // If song mode is active, clicking left arrow key cells should decrement segment offset to display out of view segments
                                            sketchpadClipsColumn.segmentOffset = Math.max(0, sketchpadClipsColumn.segmentOffset - 1)
                                        } else if (sketchpadClipsColumn.shouldShowSegmentArrows && index === 9) {
                                            // If song mode is active, clicking right arrow key cells should increment segment offset to display out of view segments
                                            sketchpadClipsColumn.segmentOffset = Math.min(sketchpadClipsColumn.maximumSegmentOffset, sketchpadClipsColumn.segmentOffset + 1)
                                        } else {
                                            // If song mode is active, clicking segment cells should activate that segment
                                            if (segmentHeader.segment) {
                                                root.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex = segmentHeader.thisSegmentIndex
                                                root.lastSelectedObj = {
                                                    className: segmentHeader.segment.className,
                                                    value: segmentHeader.segment,
                                                    component: segmentHeader
                                                }
                                            }
                                        }
                                    }
                                    onPressAndHold: {
                                        segmentHeader.startDrag = true
                                        segmentHeader.dragStartPosition = Qt.point(pressX, pressY)
                                        segmentHeader.segmentOffsetAtDragStart = sketchpadClipsColumn.segmentOffset
                                    }
                                    onReleased: {
                                        startDrag = false
                                    }
                                    onPressXChanged: {
                                        if (startDrag) {
                                            var offset = Math.round((pressX-dragStartPosition.x)/segmentHeader.width)

                                            if (offset < 0) {
                                                sketchpadClipsColumn.segmentOffset = Math.min(sketchpadClipsColumn.maximumSegmentOffset, segmentHeader.segmentOffsetAtDragStart + Math.abs(offset))
                                            } else {
                                                sketchpadClipsColumn.segmentOffset = Math.max(0, segmentHeader.segmentOffsetAtDragStart - Math.abs(offset))
                                            }
                                        }
                                    }
                                }

                                ClipCell {
                                    id: clipCell

                                    anchors.fill: parent
                                    visible: !root.songMode && !root.displaySceneButtons

                                    backgroundColor: "#000000"
                                    onHighlightedChanged: {
                                        Qt.callLater(function () {
                                            //console.log("Clip : (" + channel.sceneClip.row+", "+channel.sceneClip.col+")", "Selected Channel :"+ zynthian.session_dashboard.selectedChannel)

                                            // Switch to highlighted clip only if previous selected bottombar object was a clip/pattern
//                                            if (highlighted && (bottomBar.controlType === BottomBar.ControlType.Pattern || bottomBar.controlType === BottomBar.ControlType.Clip)) {
//                                                if (channel.connectedPattern >= 0) {
//                                                    bottomBar.controlType = BottomBar.ControlType.Pattern;
//                                                    bottomBar.controlObj = channel.sceneClip;
//                                                } else {
//                                                    bottomBar.controlType = BottomBar.ControlType.Clip;
//                                                    bottomBar.controlObj = channel.sceneClip;
//                                                }
//                                            }
                                        });
                                    }

                                    Connections {
                                        target: channel.sceneClip
                                        onInCurrentSceneChanged: colorTimer.restart()
                                        onPathChanged: colorTimer.restart()
                                        onIsPlayingChanged: colorTimer.restart()
                                    }
                                    Connections {
                                        target: channel
                                        onConnectedPatternChanged: colorTimer.restart()
                                        onChannelAudioTypeChanged: colorTimer.restart()
                                        onClipsModelChanged: colorTimer.restart()
                                    }
                                    Connections {
                                        target: clipCell.pattern
                                        onLastModifiedChanged: colorTimer.restart()
                                        onEnabledChanged: colorTimer.restart()
                                    }
                                    Connections {
                                        target: clipCell.sequence
                                        onIsPlayingChanged: colorTimer.restart()
                                    }
                                    Connections {
                                        target: zynthian.sketchpad
                                        onIsMetronomeRunningChanged: colorTimer.restart()
                                    }
                                    Connections {
                                        target: root.song.scenesModel
                                        onSelectedTrackIndexChanged: colorTimer.restart()
                                    }

                                    Timer {
                                        id: colorTimer
                                        interval: 10
                                        onTriggered: {
                                            // update color
//                                                if (channel.channelAudioType === "sample-loop" && channel.sceneClip && channel.sceneClip.inCurrentScene && channel.sceneClip.path && channel.sceneClip.path.length > 0) {
//                                                    // In scene
//                                                    clipCell.backgroundColor = "#3381d4fa";
//                                                } /*else if (channel.sceneClip && (!channel.sceneClip.inCurrentScene && !root.song.scenesModel.isClipInScene(channel.sceneClip, channel.sceneClip.col))) {
//                                                    // Not in scene
//                                                    clipCell.backgroundColor = "#33f44336";
//                                                }*/ else if ((channel.connectedPattern >= 0 && clipCell.pattern.hasNotes)
//                                                    || (channel.channelAudioType === "sample-loop" && channel.sceneClip.path && channel.sceneClip.path.length > 0)) {
//                                                    clipCell.backgroundColor =  Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.02)
//                                                } else {
//                                                    clipCell.backgroundColor =  Qt.rgba(0, 0, 0, 1);
//                                                }

                                            // update isPlaying
                                            if (channel.connectedPattern < 0) {
                                                clipCell.isPlaying = channel.sceneClip.isPlaying;
                                            } else {
                                                var patternIsPlaying = false;
                                                if (clipCell.sequence && clipCell.sequence.isPlaying) {
                                                    if (clipCell.sequence.soloPattern > -1) {
                                                        patternIsPlaying = (clipCell.sequence.soloPattern == channel.connectedPattern)
                                                    } else if (clipCell.pattern) {
                                                        patternIsPlaying = clipCell.pattern.enabled
                                                    }
                                                }
                                                clipCell.isPlaying = patternIsPlaying && root.song.scenesModel.isClipInScene(channel.sceneClip, channel.sceneClip.col) && zynthian.sketchpad.isMetronomeRunning;
                                            }
                                        }
                                    }

                                    // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                                    sequence: zynthian.isBootingComplete ? ZynQuick.PlayGridManager.getSequenceModel(zynthian.sketchpad.song.scenesModel.selectedTrackName) : null
                                    pattern: channel.connectedPattern >= 0 && sequence && !sequence.isLoading && sequence.count > 0 ? sequence.getByPart(channel.id, channel.selectedPart) : null

                                    onPressed: {
                                        var toggleBottomBar = false
                                        root.lastSelectedObj = {
                                            className: channel.sceneClip.className,
                                            value: channel.sceneClip,
                                            component: clipCell
                                        }

                                        if (zynthian.session_dashboard.selectedChannel === channel.id) {
                                            toggleBottomBar = true
                                        } else {
                                            zynthian.session_dashboard.selectedChannel = channel.id;
                                            zynthian.sketchpad.song.scenesModel.selectedTrackIndex = channel.sceneClip.col
                                        }

                                        Qt.callLater(function() {
                                            root.resetBottomBar(toggleBottomBar)
                                            // zynthian.session_dashboard.disableNextSoundSwitchTimer();

                                            if (channel.connectedPattern >= 0) {
                                                bottomBar.controlType = BottomBar.ControlType.Pattern;
                                                bottomBar.controlObj = channel.sceneClip;
                                            } else {
                                                bottomBar.controlType = BottomBar.ControlType.Clip;
                                                bottomBar.controlObj = channel.sceneClip;
                                            }
                                        })
                                    }
                                    onPressAndHold: {
                                        bottomStack.bottomBar.controlType = BottomBar.ControlType.Pattern;
                                        bottomStack.bottomBar.controlObj = channel.sceneClip;
                                        bottomStack.slotsBar.bottomBarButton.checked = true;

                                        if (channel.channelAudioType === "sample-loop") {
                                            if (channel.sceneClip && channel.sceneClip.path && channel.sceneClip.path.length > 0) {
                                                bottomStack.bottomBar.waveEditorAction.trigger();
                                            } else {
                                                bottomStack.bottomBar.recordingAction.trigger();
                                            }
                                        } else {
                                            bottomStack.bottomBar.patternAction.trigger();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: sketchpadCopyPasteButtonsColumn
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    spacing: 1

                    // Common copy button to set the object to copy
                    TableHeader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        highlightOnFocus: false
                        font.pointSize: 10
                        enabled: root.lastSelectedObj && root.lastSelectedObj.className
                        text: qsTr("Copy %1").arg(root.lastSelectedObj && root.lastSelectedObj.className
                                                  ? root.lastSelectedObj.className === "sketchpad_clip"
                                                    ? qsTr("Clip")
                                                    : root.lastSelectedObj.className === "sketchpad_channel"
                                                        ? qsTr("Channel")
                                                        : root.lastSelectedObj.className === "sketchpad_track"
                                                            ? qsTr("Track")
                                                            : root.lastSelectedObj.className === "sketchpad_part"
                                                              ? qsTr("Part")
                                                              : root.lastSelectedObj.className === "sketchpad_segment"
                                                                ? qsTr("Segment")
                                                                : root.lastSelectedObj.className === "sketchpad_sketch"
                                                                  ? qsTr("Sketch")
                                                                  : ""
                                                  : "")
                        visible: root.copySourceObj == null
                        onClicked: {
                            // Check and set copy source object from bottombar as bottombar
                            // controlObj is the current focused/selected object by user

                            root.copySourceObj = root.lastSelectedObj
                            console.log("Copy", root.copySourceObj)
                        }
                    }

                    // Common cancel button to cancel copy
                    TableHeader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        highlightOnFocus: false
                        font.pointSize: 10
                        text: qsTr("Cancel Copy")
                        visible: root.copySourceObj != null
                        onPressed: {
                            root.copySourceObj = null
                        }
                    }

                    // Common button to paste object
                    TableHeader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        highlightOnFocus: false
                        font.pointSize: 10
                        enabled: {
                            if (root.copySourceObj != null &&
                                root.copySourceObj.value &&
                                root.copySourceObj.className) {

                                // Check if source and destination are same
                                if (root.copySourceObj.className === "sketchpad_clip" &&
                                    root.copySourceObj.value !== root.song.getClip(zynthian.session_dashboard.selectedChannel, zynthian.sketchpad.song.scenesModel.selectedTrackIndex) &&
                                    root.lastSelectedObj.className === "sketchpad_clip") {
                                    return true
                                } else if (root.copySourceObj.className === "sketchpad_channel" &&
                                           root.copySourceObj.value.id !== zynthian.session_dashboard.selectedChannel &&
                                           root.lastSelectedObj.className === "sketchpad_channel") {
                                    return true
                                } else if (root.copySourceObj.className === "sketchpad_track" &&
                                           root.copySourceObj.value !== root.song.scenesModel.selectedTrackIndex &&
                                           root.lastSelectedObj.className === "sketchpad_track") {
                                    return true
                                } else if (root.copySourceObj.className === "sketchpad_part" &&
                                           root.copySourceObj.value !== root.lastSelectedObj.value &&
                                           root.lastSelectedObj.className === "sketchpad_part") {
                                   return true
                                } else if (root.copySourceObj.className === "sketchpad_segment" &&
                                           root.copySourceObj.value !== root.lastSelectedObj.value &&
                                           root.lastSelectedObj.className === "sketchpad_segment" &&
                                           root.copySourceObj.value.sketchId === root.lastSelectedObj.value.sketchId) {
                                   return true
                                } else if (root.copySourceObj.className === "sketchpad_sketch" &&
                                           root.copySourceObj.value !== root.lastSelectedObj.value &&
                                           root.lastSelectedObj.className === "sketchpad_sketch") {
                                   return true
                                }
                            }

                            return false
                        }
                        text: qsTr("Paste %1").arg(root.copySourceObj && root.copySourceObj.className
                                                       ? root.copySourceObj.className === "sketchpad_clip"
                                                           ? qsTr("Clip")
                                                           : root.copySourceObj.className === "sketchpad_channel"
                                                               ? qsTr("Channel")
                                                               : root.copySourceObj.className === "sketchpad_track"
                                                                   ? qsTr("Track")
                                                                   : root.copySourceObj.className === "sketchpad_part"
                                                                     ? qsTr("Part")
                                                                     : root.copySourceObj.className === "sketchpad_segment"
                                                                       ? qsTr("Segment")
                                                                       : root.copySourceObj.className === "sketchpad_sketch"
                                                                         ? qsTr("Sketch")
                                                                         : ""
                                                       : "")
                        onPressed: {
                            if (root.copySourceObj.className && root.copySourceObj.className === "sketchpad_clip") {
                                var sourceClip = root.copySourceObj.value
                                var destClip = root.song.getClip(zynthian.session_dashboard.selectedChannel, zynthian.sketchpad.song.scenesModel.selectedTrackIndex)

                                // Copy Clip
                                destClip.copyFrom(sourceClip)
                                // Copy pattern
                                var sourcePattern = ZynQuick.PlayGridManager.getSequenceModel("T"+(sourceClip.col + 1)).getByPart(sourceClip.clipChannel.id, sourceClip.clipChannel.selectedPart)
                                var destPattern = ZynQuick.PlayGridManager.getSequenceModel("T"+(destClip.col + 1)).getByPart(destClip.clipChannel.id, destClip.clipChannel.selectedPart)
                                destPattern.cloneOther(sourcePattern)

                                root.copySourceObj = null
                            } else if (root.copySourceObj.className && root.copySourceObj.className === "sketchpad_channel") {
                                zynthian.start_loading()

                                // Copy Channel
                                var sourceChannel = root.copySourceObj.value
                                var destChannel = root.song.channelsModel.getChannel(zynthian.session_dashboard.selectedChannel)
                                destChannel.copyFrom(sourceChannel)

                                for (var part=0; part<5; part++) {
                                    for (var i=0; i<sourceChannel.clipsModel.count; i++) {
                                        var sourceClip = sourceChannel.parts[part].getClip(i)
                                        var destClip = destChannel.parts[part].getClip(i)
                                        var sourcePattern = ZynQuick.PlayGridManager.getSequenceModel("T"+(sourceClip.col + 1)).getByPart(sourceClip.clipChannel.id, part)
                                        var destPattern = ZynQuick.PlayGridManager.getSequenceModel("T"+(destClip.col + 1)).getByPart(destClip.clipChannel.id, part)

                                        destPattern.cloneOther(sourcePattern)
                                    }
                                }

                                root.copySourceObj = null

                                zynthian.stop_loading()
                            } else if (root.copySourceObj.className && root.copySourceObj.className === "sketchpad_track") {
                                zynthian.start_loading()

                                // Copy Track
                                root.song.scenesModel.copyTrack(root.copySourceObj.value, root.song.scenesModel.selectedTrackIndex)

                                for (var i=0; i<root.song.channelsModel.count; i++) {
                                    var channel = root.song.channelsModel.getChannel(i)
                                    var sourcePattern = ZynQuick.PlayGridManager.getSequenceModel("T"+(root.copySourceObj.value + 1)).getByPart(channel.id, channel.selectedPart)
                                    var destPattern = ZynQuick.PlayGridManager.getSequenceModel(root.song.scenesModel.selectedTrackName).getByPart(channel.id, channel.selectedPart)

                                    destPattern.cloneOther(sourcePattern)
                                }

                                root.copySourceObj = null

                                zynthian.stop_loading()
                            } else if (root.copySourceObj.className && root.copySourceObj.className === "sketchpad_part") {
                                var sourceClip = root.copySourceObj.value
                                var destClip = root.lastSelectedObj.value

                                // Copy Clip
                                destClip.copyFrom(sourceClip)
                                // Copy pattern
                                var sourcePattern = ZynQuick.PlayGridManager.getSequenceModel("T"+(sourceClip.col + 1)).getByPart(sourceClip.clipChannel.id, sourceClip.clipChannel.selectedPart)
                                var destPattern = ZynQuick.PlayGridManager.getSequenceModel("T"+(destClip.col + 1)).getByPart(destClip.clipChannel.id, destClip.clipChannel.selectedPart)
                                destPattern.cloneOther(sourcePattern)

                                root.copySourceObj = null
                            } else if (root.copySourceObj.className && root.copySourceObj.className === "sketchpad_segment") {
                                root.lastSelectedObj.value.copyFrom(root.copySourceObj.value)
                                root.copySourceObj = null
                            } else if (root.copySourceObj.className && root.copySourceObj.className === "sketchpad_sketch") {
                                root.lastSelectedObj.value.copyFrom(root.copySourceObj.value)
                                root.copySourceObj = null
                            }
                        }
                    }

                    TableHeader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        highlightOnFocus: false
                        font.pointSize: 10
                        enabled: root.lastSelectedObj != null &&
                                 root.lastSelectedObj.className != null &&
                                 (root.lastSelectedObj.className === "sketchpad_clip" ||
                                  root.lastSelectedObj.className === "sketchpad_segment" ||
                                  root.lastSelectedObj.className === "sketchpad_sketch")
                        text: qsTr("Clear")
                        onPressed: {
                            if (root.lastSelectedObj.value.clear) {
                                root.lastSelectedObj.value.clear()
                            }

                            if (root.lastSelectedObj.className === "sketchpad_clip") {
                                // Try clearing pattern if exists.
                                try {
                                    if (root.lastSelectedObj.value.connectedPattern >= 0) {
                                        ZynQuick.PlayGridManager.getSequenceModel("T"+(root.song.scenesModel.selectedTrackIndex + 1)).getByPart(root.lastSelectedObj.value.id, root.lastSelectedObj.value.selectedPart).clear()
                                    }
                                } catch(e) {}
                            }
                        }
                    }
                }
            }

            StackLayout {
                id: bottomStack

                property alias bottomBar: bottomBar
                property alias slotsBar: slotsBar

                Layout.fillWidth: true
                Layout.fillHeight: true
                onCurrentIndexChanged: updateLedVariablesTimer.restart()

                BottomBar {
                    id: bottomBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                MixerBar {
                    id: mixerBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                SlotsBar {
                    id: slotsBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                MixedChannelsViewBar {
                    id: mixedChannelsViewBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                PartBar {
                    id: partBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onClicked: {
                        root.lastSelectedObj = {
                            className: "sketchpad_part",
                            value: partBar.selectedPartClip,
                            component: partBar.selectedComponent
                        }
                    }
                }

                ChannelsViewSoundsBar {
                    id: soundCombinatorBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
