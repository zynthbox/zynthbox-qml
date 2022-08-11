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
    readonly property QtObject song: zynthian.zynthiloops.song
    property QtObject selectedTrack: applicationWindow().selectedTrack
    property bool displaySceneButtons: zynthian.zynthiloops.displaySceneButtons
    property bool displaySketchButtons: false
    property bool songMode: zynthian.zynthiloops.song.mixesModel.songMode

    // Used to temporarily cache clip/track object to be copied
    property var copySourceObj: null

    // Used to temporarily store lsat clicked object by user
    property var lastSelectedObj: null

    title: qsTr("Zynthiloops")
    screenId: "zynthiloops"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8
    backAction.visible: false

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Sketch")

            Kirigami.Action {
                // Rename Save button as Save as for temp sketch
                text: root.song.isTemp ? qsTr("Save As") : qsTr("Save")
                onTriggered: {
                    if (root.song.isTemp) {
                        fileNameDialog.dialogType = "save";
                        fileNameDialog.fileName = "Sketch-1";
                        fileNameDialog.open();
                    } else {
                        zynthian.zynthiloops.saveSketch();
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
                    fileNameDialog.fileName = song.sketchFolderName;
                    fileNameDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Load Sketch")
                onTriggered: {
                    sketchPickerDialog.folderModel.folder = sketchPickerDialog.rootFolder;
                    sketchPickerDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("New Sketch")
                onTriggered: {
                    zynthian.zynthiloops.newSketch()
                }
            }
        },
        Kirigami.Action {
            text: qsTr("Mixer")
            checked: bottomStack.slotsBar.mixerButton.checked
            onTriggered: {
                if (bottomStack.slotsBar.mixerButton.checked) {
                    bottomStack.slotsBar.trackButton.checked = true
                } else {
                    bottomStack.slotsBar.mixerButton.checked = true
                }
            }
        },
        Kirigami.Action {
            text: qsTr("Sounds")
            onTriggered: zynthian.show_modal("sound_categories")
        },

        Kirigami.Action {
            text: "Get New Sketches"
            onTriggered: {
                zynthian.show_modal("sketch_downloader")
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

        if (sketchPickerDialog.opened) {
            return sketchPickerDialog.cuiaCallback(cuia);
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
                var selectedMidiChannel = root.selectedTrack.chainedSounds[root.selectedTrack.selectedSlotRow];
                if (root.selectedTrack.checkIfLayerExists(selectedMidiChannel)) {
                    zynthian.layer.selectPrevPreset(selectedMidiChannel);
                    infoBar.updateInfoBar();
                }
                return true;

            case "SELECT_DOWN":
                var selectedMidiChannel = root.selectedTrack.chainedSounds[root.selectedTrack.selectedSlotRow];
                if (root.selectedTrack.checkIfLayerExists(selectedMidiChannel)) {
                    zynthian.layer.selectNextPreset(selectedMidiChannel);
                    infoBar.updateInfoBar();
                }
                return true;

            case "MODE_SWITCH_SHORT":
            case "MODE_SWITCH_LONG":
            case "MODE_SWITCH_BOLD":
                if (zynthian.altButtonPressed) {
                    // Cycle between track, mixer, synths, samples, fx when alt button is not pressed
                    if (bottomStack.slotsBar.trackButton.checked) {
                        bottomStack.slotsBar.partButton.checked = true
                    } else if (bottomStack.slotsBar.partButton.checked) {
                        bottomStack.slotsBar.synthsButton.checked = true
                    } else if (bottomStack.slotsBar.synthsButton.checked) {
                        bottomStack.slotsBar.samplesButton.checked = true
                    } else if (bottomStack.slotsBar.samplesButton.checked) {
                        bottomStack.slotsBar.fxButton.checked = true
                    } else if (bottomStack.slotsBar.fxButton.checked) {
                        bottomStack.slotsBar.trackButton.checked = true
                    } else {
                        bottomStack.slotsBar.trackButton.checked = true
                    }

                    return true;
                } else {
//                    // Cycle through the trackAudioTypes when alt button is pressed
//                    if (root.selectedTrack.trackAudioType === "synth") {
//                        root.selectedTrack.trackAudioType = "sample-trig"
//                    } else if (root.selectedTrack.trackAudioType === "sample-trig") {
//                        root.selectedTrack.trackAudioType = "sample-slice"
//                    } else if (root.selectedTrack.trackAudioType === "sample-slice") {
//                        root.selectedTrack.trackAudioType = "sample-loop"
//                    } else if (root.selectedTrack.trackAudioType === "sample-loop") {
//                        // HACK
//                        // FIXME : When changing trackAudioType to external it somehow first gets selected to "synth"
//                        //         And then on changing the value 2nd time it finally changes to "external"
//                        //         Couldn't find any probable cause for the issue but forcefully setting to external twice
//                        //         seems to do temporarily solve the problem. But this issue needs to be fixed ASAP
//                        root.selectedTrack.trackAudioType = "external"
//                        root.selectedTrack.trackAudioType = "external"
//                    } else if (root.selectedTrack.trackAudioType === "external") {
//                        root.selectedTrack.trackAudioType = "synth"
//                    }

//                    // Toggle between Part and Track bar with FX Button
//                    if (!bottomStack.slotsBar.partButton.checked) {
//                        bottomStack.slotsBar.partButton.checked = true
//                    } else {
//                        bottomStack.slotsBar.trackButton.checked = true
//                    }

//                    return true;
                }

                return false;

            case "SCREEN_ADMIN":
                if (root.selectedTrack && root.selectedTrack.trackAudioType === "synth") {
                    var sound = root.selectedTrack.chainedSounds[root.selectedTrack.selectedSlotRow]

                    // when synth and slot is active, edit that sound or show popup when empty
                    if (sound >= 0 && root.selectedTrack.checkIfLayerExists(sound)) {
                        zynthian.fixed_layers.activate_index(sound)
                        zynthian.control.single_effect_engine = null;
                        zynthian.current_screen_id = "control";
                        zynthian.forced_screen_back = "zynthiloops"
                    } else {
                        bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                    }
                } else if (root.selectedTrack && ["sample-trig", "sample-slice"].indexOf(root.selectedTrack.trackAudioType) >= 0) {
                    var sample = root.selectedTrack.samples[root.selectedTrack.selectedSlotRow]

                    // when sample and slot is active, goto wave editor or show popup when empty
                    if (sample && sample.path && sample.path.length > 0) {
                        bottomStack.bottomBar.controlType = BottomBar.ControlType.Track;
                        bottomStack.bottomBar.controlObj = root.selectedTrack;
                        bottomStack.slotsBar.bottomBarButton.checked = true;
                        bottomStack.bottomBar.trackWaveEditorAction.trigger();
                    } else {
                        bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                    }
                } else if (root.selectedTrack && root.selectedTrack.trackAudioType === "sample-loop") {
                    var clip = root.selectedTrack.clipsModel.getClip(zynthian.zynthiloops.song.scenesModel.selectedSketchIndex)

                    // when loop and slot is active, goto wave editor or show popup when empty
                    if (clip && clip.path && clip.path.length > 0) {
                        bottomStack.bottomBar.controlType = BottomBar.ControlType.Pattern;
                        bottomStack.bottomBar.controlObj = root.selectedTrack.clipsModel.getClip(zynthian.zynthiloops.song.scenesModel.selectedSketchIndex);
                        bottomStack.slotsBar.bottomBarButton.checked = true;
                        bottomStack.bottomBar.waveEditorAction.trigger();
                    } else {
                        bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                    }
                } else {
                    // do nothing for other cases
                    return false
                }

                return true
        }

        // If cuia is not handled by any bottomBars or the switch block
        // call the common cuiaHandler
        return Zynthian.CommonUtils.cuiaHandler(cuia, root.selectedTrack, bottomStack)
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
                bottomBar.tabbedView.activeAction.page.search("TracksViewSoundsBar") >= 0 // Checks if current active page is sound combinator or not
            ) {
                zynthian.soundCombinatorActive = true;
            } else {
                zynthian.soundCombinatorActive = false;
            }

            // Check if sound combinator is active
            if (bottomStack.slotsBar.bottomBarButton.checked && // Checks if bottombar is visible
                bottomBar.tabbedView.activeAction.page.search("SamplesBar") >= 0 // Checks if current active page is samples bar
            ) {
                zynthian.trackSamplesBarActive = true;
            } else {
                zynthian.trackSamplesBarActive = false;
            }

            // Check if track wave editor bar is active
            if (bottomStack.slotsBar.bottomBarButton.checked && // Checks if bottombar is visible
                bottomBar.controlType === BottomBar.ControlType.Track && // Checks if track is selected
                bottomBar.tabbedView.activeAction.page.search("WaveEditorBar") >= 0 // Checks if current active page is wave editor or not
            ) {
                zynthian.trackWaveEditorBarActive = true;
            } else {
                zynthian.trackWaveEditorBarActive = false;
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

            if (bottomStack.slotsBar.trackButton.checked) {
                console.log("LED : Slots Track Bar active")
                zynthian.slotsBarTrackActive = true;
                zynthian.slotsBarPartActive = false;
                zynthian.slotsBarMixerActive = false;
                zynthian.slotsBarSynthsActive = false;
                zynthian.slotsBarSamplesActive = false;
                zynthian.slotsBarFxActive = false;
                // zynthian.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.mixerButton.checked) {
                console.log("LED : Slots Mixer Bar active")
                zynthian.slotsBarTrackActive = false;
                zynthian.slotsBarPartActive = false;
                zynthian.slotsBarMixerActive = true;
                zynthian.slotsBarSynthsActive = false;
                zynthian.slotsBarSamplesActive = false;
                zynthian.slotsBarFxActive = false;
                // zynthian.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.partButton.checked) {
                console.log("LED : Slots Part Bar active")
                zynthian.slotsBarTrackActive = false;
                zynthian.slotsBarPartActive = true;
                zynthian.slotsBarMixerActive = false;
                zynthian.slotsBarSynthsActive = false;
                zynthian.slotsBarSamplesActive = false;
                zynthian.slotsBarFxActive = false;
                // zynthian.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.synthsButton.checked) {
                console.log("LED : Slots Synths Bar active")
                zynthian.slotsBarTrackActive = false;
                zynthian.slotsBarPartActive = false;
                zynthian.slotsBarMixerActive = false;
                zynthian.slotsBarSynthsActive = true;
                zynthian.slotsBarSamplesActive = false;
                zynthian.slotsBarFxActive = false;
                // zynthian.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.samplesButton.checked) {
                console.log("LED : Slots Samples Bar active")
                zynthian.slotsBarTrackActive = false;
                zynthian.slotsBarPartActive = false;
                zynthian.slotsBarMixerActive = false;
                zynthian.slotsBarSynthsActive = false;
                zynthian.slotsBarSamplesActive = true;
                zynthian.slotsBarFxActive = false;
                // zynthian.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.fxButton.checked) {
                console.log("LED : Slots FX Bar active")
                zynthian.slotsBarTrackActive = false;
                zynthian.slotsBarPartActive = false;
                zynthian.slotsBarMixerActive = false;
                zynthian.slotsBarSynthsActive = false;
                zynthian.slotsBarSamplesActive = false;
                zynthian.slotsBarFxActive = true;
                // zynthian.soundCombinatorActive = false;
            } else if (bottomStack.slotsBar.soundCombinatorButton.checked) {
                console.log("LED : Slots FX Bar active")
                zynthian.slotsBarTrackActive = false;
                zynthian.slotsBarPartActive = false;
                zynthian.slotsBarMixerActive = false;
                zynthian.slotsBarSynthsActive = false;
                zynthian.slotsBarSamplesActive = false;
                zynthian.slotsBarFxActive = false;
                // zynthian.soundCombinatorActive = true;
            } else {
                console.log("LED : No Slots Bar active")
                zynthian.slotsBarTrackActive = false;
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
        target: zynthian.zynthiloops
        onSong_changed: {
            console.log("$$$ Song Changed :", song)

            bottomBar.controlType = BottomBar.ControlType.Song;
            bottomBar.controlObj = root.song;
            bottomStack.slotsBar.trackButton.checked = true
        }
    }

    Component.onCompleted: {
        applicationWindow().controlsVisible = true;
        bottomBar.controlType = BottomBar.ControlType.Song;
        bottomBar.controlObj = root.song;
        bottomStack.slotsBar.trackButton.checked = true
    }

    Component.onDestruction: {
        applicationWindow().controlsVisible = true;
    }

    QtObject {
        id: privateProps

        // Try to fit exactly 12 cells + a header cell
        // These 12 cells consists of 1 header column + 10 tracks columna + 2 cell empty space for buttons
        property int headerWidth: (tableLayout.width - loopGrid.columnSpacing*12)/13
        property int headerHeight: (tableLayout.height - loopGrid.rowSpacing*2)/3
        property int cellWidth: headerWidth
        property int cellHeight: headerHeight
    }

    Zynthian.SaveFileDialog {
        property string dialogType: "save"

        id: fileNameDialog
        visible: false

        headerText: {
            if (fileNameDialog.dialogType == "savecopy")
                return qsTr("Clone Sketch")
            else if (fileNameDialog.dialogType === "saveas")
                return qsTr("New version")
            else
                return qsTr("New Sketch")
        }
        conflictText: {
            if (dialogType == "savecopy")
                return qsTr("Sketch Exists")
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
                    && zynthian.zynthiloops.sketchExists(fileNameDialog.fileName)) {
                    // Sketch with name already exists
                    fileNameDialog.conflict = true;
                } else if (fileNameDialog.dialogType === "saveas"
                           && fileNameDialog.fileName.length > 0
                           && zynthian.zynthiloops.versionExists(fileNameDialog.fileName)) {
                    fileNameDialog.conflict = true;
                } else if (fileNameDialog.dialogType === "save"
                           && root.song.isTemp
                           && fileNameDialog.fileName.length > 0
                           && zynthian.zynthiloops.sketchExists(fileNameDialog.fileName)) {
                    fileNameDialog.conflict = true;
                } else {
                    fileNameDialog.conflict = false;
                }
            }
        }

        onAccepted: {
            console.log("Accepted")

            if (dialogType === "save") {
                zynthian.zynthiloops.createSketch(fileNameDialog.fileName)
            } else if (dialogType === "saveas") {
                root.song.name = fileNameDialog.fileName;
                zynthian.zynthiloops.saveSketch();
            } else if (dialogType === "savecopy") {
                zynthian.zynthiloops.saveCopy(fileNameDialog.fileName);
            }
        }
        onRejected: {
            console.log("Rejected")
        }
    }

    Zynthian.FilePickerDialog {
        id: sketchPickerDialog
        parent: root

        headerText: qsTr("Pick a sketch")
        rootFolder: "/zynthian/zynthian-my-data/sketches/"
        folderModel {
            nameFilters: ["*.sketch.json"]
        }
        onFileSelected: {
            console.log("Selected Sketch : " + file.fileName + "("+ file.filePath +")")
            zynthian.zynthiloops.loadSketch(file.filePath, false)
        }
    }

    contentItem : Item {
        id: content

        Connections {
            target: applicationWindow()
            onVisibleChanged: {
                selectedTrackOutlineTimer.restart()
            }
        }

        Timer {
            id: selectedTrackOutlineTimer
            repeat: false
            interval: 300
            onTriggered: {
                selectedTrackOutline.x = Qt.binding(function() { return tracksHeaderRow.mapToItem(content, tracksHeaderRepeater.itemAt(zynthian.session_dashboard.selectedTrack).x, 0).x })
                selectedTrackOutline.y = Qt.binding(function() { return tracksHeaderRow.mapToItem(content, 0, tracksHeaderRepeater.itemAt(zynthian.session_dashboard.selectedTrack).y).y })
                zynthian.zynthiloops.set_selector()
            }
        }

        Rectangle {
            id: selectedTrackOutline
            width: privateProps.headerWidth
            visible: !root.songMode

            // If scene selection buttons are visible, do not show outline over scene buttons
            height: (privateProps.headerHeight + loopGrid.columnSpacing) * (root.displaySceneButtons ? 1 : 2)
            color: "#2affffff"
            z: 100
        }

        ColumnLayout {
            anchors.fill: parent

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                color: Kirigami.Theme.backgroundColor

                RowLayout {
                    id: infoBar

                    property var clip: root.song.getClip(zynthian.session_dashboard.selectedTrack, zynthian.zynthiloops.song.scenesModel.selectedSketchIndex)
                    property int topLayerIndex: 0
                    property int topLayer: -1
                    property int selectedSoundSlot: zynthian.soundCombinatorActive
                                                    ? root.selectedTrack.selectedSlotRow
                                                    : root.selectedTrack.selectedSlotRow
                    property int selectedSoundSlotExists: clip.clipTrack.checkIfLayerExists(clip.clipTrack.chainedSounds[selectedSoundSlot])

                    width: parent.width - Kirigami.Units.gridUnit
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.gridUnit

                    onClipChanged: updateSoundNameTimer.restart()

                    function updateInfoBar() {
                        var layerIndex = -1;
                        var count = 0;

                        if (infoBar.clip) {
                            for (var i in infoBar.clip.clipTrack.chainedSounds) {
                                if (infoBar.clip.clipTrack.chainedSounds[i] >= 0 &&
                                    infoBar.clip.clipTrack.checkIfLayerExists(infoBar.clip.clipTrack.chainedSounds[i])) {
                                    if (layerIndex < 0) {
                                        layerIndex = i
                                    }
                                    count++;
                                }
                            }
                        }

                        layerLabel.layerIndex = layerIndex
                        infoBar.topLayerIndex = layerIndex
                        infoBar.topLayer = layerIndex == -1 ? -1 : infoBar.clip.clipTrack.chainedSounds[layerIndex]
                        layerLabel.layerCount = count
//                        infoBar.selectedChannel = zynthian.soundCombinatorActive
//                                                    ? infoBar.clip.clipTrack.chainedSounds[root.selectedTrack.selectedSlotRow]
//                                                    : infoBar.clip.clipTrack.connectedSound

                        infoBar.clip.clipTrack.updateChainedSoundsInfo()
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
                        onSelectedTrackChanged: {
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
                        target: infoBar.clip ? infoBar.clip.clipTrack : null
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
                        text: qsTr("T%1").arg(zynthian.session_dashboard.selectedTrack+1)

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log(infoBar.selectedSoundSlot, infoBar.topLayer, JSON.stringify(infoBar.clip.clipTrack.chainedSoundsInfo, null, 2))
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
                        text: qsTr("Slot %1 %2")
                                .arg(root.selectedTrack.selectedSlotRow + 1)
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
                        visible: infoBar.clip && infoBar.clip.clipTrack.trackAudioType === "synth"
                        text: visible
                                ? infoBar.selectedSoundSlotExists
                                    ? qsTr("Preset (%2/%3): %1")
                                        .arg(infoBar.clip.clipTrack.chainedSoundsInfo[infoBar.selectedSoundSlot].presetName)
                                        .arg(infoBar.clip.clipTrack.chainedSoundsInfo[infoBar.selectedSoundSlot].presetIndex+1)
                                        .arg(infoBar.clip.clipTrack.chainedSoundsInfo[infoBar.selectedSoundSlot].presetLength)
                                    : qsTr("Preset: --")
                                : ""
                    }
                    QQC2.Label {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignVCenter
                        visible: infoBar.clip && infoBar.clip.clipTrack.trackAudioType === "synth"
                        text: visible
                                ? infoBar.selectedSoundSlotExists
                                    ? qsTr("Bank: %1")
                                        .arg(infoBar.clip.clipTrack.chainedSoundsInfo[infoBar.selectedSoundSlot].bankName)
                                    : qsTr("Bank: --")
                                : ""
                    }
                    QQC2.Label {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignVCenter
                        visible: infoBar.clip && infoBar.clip.clipTrack.trackAudioType === "synth"
                        text: visible
                                ? infoBar.selectedSoundSlotExists
                                    ? qsTr("Synth: %1")
                                        .arg(infoBar.clip.clipTrack.chainedSoundsInfo[infoBar.selectedSoundSlot].synthName)
                                    : qsTr("Synth: --")
                                : ""
                    }
                    QQC2.Label {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignVCenter
                        visible: infoBar.clip && infoBar.clip.clipTrack.trackAudioType === "sample-loop"
                        // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                        text: zynthian.isBootingComplete ? qsTr("Clip: %1").arg(infoBar.clip && infoBar.clip.path && infoBar.clip.path.length > 0 ? infoBar.clip.path.split("/").pop() : "--") : ""
                    }
                    QQC2.Label {
                        property QtObject sample: infoBar.clip && infoBar.clip.clipTrack.samples[infoBar.clip.clipTrack.selectedSlotRow]
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignVCenter
                        visible: infoBar.clip && (infoBar.clip.clipTrack.trackAudioType === "sample-trig" ||
                                 infoBar.clip.clipTrack.trackAudioType === "sample-slice")
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
                        visible: infoBar.clip && infoBar.clip.clipTrack.trackAudioType === "synth"
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
                        Binding {
                            target: parent
                            property: "text"
                            delayed: true
                            value: qsTr("%1 %2")
                                .arg("T" + (zynthian.session_dashboard.selectedTrack+1))
                                .arg(infoBar.clip && infoBar.clip.inCurrentScene ? "(Active)" : "")
                        }
                    }
                }
            }

            ColumnLayout {
                id: tableLayout
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 1

                // HEADER ROW
                RowLayout {
                    id: variationsHeaderRow

                    Layout.fillWidth: true
                    Layout.preferredHeight: privateProps.headerHeight
                    Layout.maximumHeight: privateProps.headerHeight
                    spacing: 1

                    TableHeader {
                        id: songCell
                        Layout.preferredWidth: privateProps.headerWidth*1.5 + 8
                        Layout.maximumWidth: privateProps.headerWidth*1.5 + 8
                        Layout.fillHeight: true

                        highlightOnFocus: false
                        highlighted: !root.songMode && root.displaySketchButtons
                        text: root.song.name
                        subText: qsTr("Sketch S%1").arg(root.song.scenesModel.selectedSketchIndex + 1)

                        textSize: 10
                        subTextSize: 8

                        onPressed: {
                            if (!root.songMode) {
                                root.displaySketchButtons = !root.displaySketchButtons
                            }
                        }
                    }

                    Repeater {
                        // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                        model: zynthian.isBootingComplete
                                ? 10
                                : 0
                        delegate: TableHeader {
                            id: sceneHeaderDelegate

                            property QtObject track: root.song.tracksModel.getTrack(index)
                            property QtObject mix: root.song.mixesModel.getMix(index)

                            color: Kirigami.Theme.backgroundColor
                            active: root.songMode ? !sceneHeaderDelegate.mix.isEmpty : true

                            Layout.fillWidth: false
                            Layout.fillHeight: true
                            Layout.preferredWidth: privateProps.headerWidth

                            highlightOnFocus: false
                            highlighted: root.songMode
                                            ? sceneHeaderDelegate.mix.mixId === root.song.mixesModel.selectedMixIndex
                                            : root.displaySketchButtons
                                                ? root.song.scenesModel.selectedSketchIndex === index
                                                : zynthian.session_dashboard.selectedTrack === index

                            text: root.songMode
                                    ? sceneHeaderDelegate.mix.name
                                    : root.displaySketchButtons
                                        ? qsTr("S%1").arg(index+1)
                                        : ""
                            textSize: 10

                            onPressed: {
                                if (root.songMode) {
                                    root.song.mixesModel.selectedMixIndex = index
                                    root.lastSelectedObj = sceneHeaderDelegate.mix
                                } else if (root.displaySketchButtons) {
                                    root.lastSelectedObj = {
                                        className: "zynthiloops_sketch",
                                        sketchIndex: index
                                    }
                                    root.song.scenesModel.selectedSketchIndex = index
                                } else {
                                    // Always open Sound combinator when clicking any indicator cell
                                    zynthian.session_dashboard.selectedTrack = sceneHeaderDelegate.track.id
                                    Qt.callLater(function() {
                                        bottomStack.bottomBar.controlType = BottomBar.ControlType.Track
                                        bottomStack.bottomBar.controlObj = sceneHeaderDelegate.track

                                        bottomStack.slotsBar.bottomBarButton.checked = true
                                        // bottomStack.slotsBar.soundCombinatorButton.checked = true
                                    })
                                }
                            }

                            ColumnLayout {
                                anchors {
                                    centerIn: parent
                                    margins: Kirigami.Units.gridUnit
                                }
                                visible: !root.songMode &&
                                         !root.displaySketchButtons &&
                                         sceneHeaderDelegate.track.trackAudioType === "synth"

                                Repeater {
                                    id: synthsOccupiedIndicatorRepeater
                                    // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                                    model: zynthian.isBootingComplete ? sceneHeaderDelegate.track.occupiedSlots : 0

                                    delegate: Rectangle {
                                        width: 50
                                        height: 3
                                        radius: 100
                                        color: synthsOccupiedIndicatorRepeater.model[index] == null
                                                ? "transparent"
                                                : synthsOccupiedIndicatorRepeater.model[index]
                                                    ? "#ccbbbbbb"
                                                    : "#11ffffff"
                                    }
                                }
                            }

                            RowLayout {
                                anchors {
                                    centerIn: parent
                                    margins: Kirigami.Units.gridUnit
                                }
                                visible: !root.songMode &&
                                         !root.displaySketchButtons &&
                                         ["sample-trig", "sample-slice"].indexOf(sceneHeaderDelegate.track.trackAudioType) >= 0

                                Repeater {
                                    id: samplesOccupiedIndicatorRepeater
                                    // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                                    model: zynthian.isBootingComplete ? sceneHeaderDelegate.track.occupiedSlots : 0

                                    delegate: Rectangle {
                                        width: 3
                                        height: 40
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: 100
                                        color: samplesOccupiedIndicatorRepeater.model[index] == null
                                                ? "transparent"
                                                : samplesOccupiedIndicatorRepeater.model[index]
                                                    ? "#ccbbbbbb"
                                                    : "#11ffffff"
                                    }
                                }
                            }

                            QQC2.Label {
                                anchors.centerIn: parent
                                visible: !root.songMode &&
                                         !root.displaySketchButtons &&
                                         sceneHeaderDelegate.track.trackAudioType === "external"
                                text: qsTr("Midi %1").arg(sceneHeaderDelegate.track.externalMidiChannel > -1 ? sceneHeaderDelegate.track.externalMidiChannel + 1 : sceneHeaderDelegate.track.id + 1)
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: "#2affffff"
                                visible: !root.songMode &&
                                         !root.displaySketchButtons &&
                                         zynthian.session_dashboard.selectedTrack === index
                            }

                        }
                    }
                }

                RowLayout {
                    id: tracksHeaderRow

                    Layout.fillWidth: true
                    Layout.preferredHeight: privateProps.headerHeight
                    Layout.maximumHeight: privateProps.headerHeight

                    spacing: 1

                    TableHeader {
                        Layout.preferredWidth: privateProps.headerWidth*1.5 + 8
                        Layout.maximumWidth: privateProps.headerWidth*1.5 + 8
                        Layout.fillHeight: true

                        text: qsTr("Song Mode")

                        textSize: 11
                        subTextSize: 9
                        subSubTextSize: 0

                        highlightOnFocus: false
                        highlighted: root.songMode
                        opacity: root.songMode ? 1 : 0.3

                        onPressed: {
                            if (zynthian.zynthiloops.isMetronomeRunning) {
                                applicationWindow().showPassiveNotification("Cannot switch song mode when timer is running", 1500)
                            } else {
                                zynthian.zynthiloops.song.mixesModel.songMode = !zynthian.zynthiloops.song.mixesModel.songMode
                            }
                        }
                    }

                    Connections {
                        target: root.song.mixesModel.selectedMix.segmentsModel
                        onSelectedSegmentIndexChanged: {
                            // When selectedSegmentIndex changes (i.e. being set with Big Knob), adjust visible segments so that selected segment is brought into view
                            if (root.songMode) {
                                if (root.song.mixesModel.selectedMix.segmentsModel.selectedSegmentIndex > (tracksHeaderRepeater.segmentOffset+7)) {
                                    console.log("selected segment is outside visible segments on the right :", root.song.mixesModel.selectedMix.segmentsModel.selectedSegmentIndex, tracksHeaderRepeater.segmentOffset, Math.min(tracksHeaderRepeater.maximumSegmentOffset, root.song.mixesModel.selectedMix.segmentsModel.selectedSegmentIndex - 7))
                                    tracksHeaderRepeater.segmentOffset = Math.min(tracksHeaderRepeater.maximumSegmentOffset, root.song.mixesModel.selectedMix.segmentsModel.selectedSegmentIndex - 7)
                                } else if (root.song.mixesModel.selectedMix.segmentsModel.selectedSegmentIndex < tracksHeaderRepeater.segmentOffset) {
                                    console.log("selected segment is outside visible segments on the left :", root.song.mixesModel.selectedMix.segmentsModel.selectedSegmentIndex, tracksHeaderRepeater.segmentOffset, root.song.mixesModel.selectedMix.segmentsModel.selectedSegmentIndex)
                                    tracksHeaderRepeater.segmentOffset = root.song.mixesModel.selectedMix.segmentsModel.selectedSegmentIndex
                                }
                            }
                        }
                    }

                    // Display 10 header buttons which will show track header buttons when song mode is not active and segment buttons when song mode is active
                    Repeater {
                        id: tracksHeaderRepeater

                        // Should show arrows is True when segment count is greater than 10 and hence needs arrows to scroll
                        property bool shouldShowArrows: root.song.mixesModel.selectedMix.segmentsModel.count > 10
                        // Segment offset will determine what is the first segment to display when arrow keys are displayed
                        property int segmentOffset: 0
                        // Maximum segment offset allows the arrow keys to check if there are any more segments outside view
                        property int maximumSegmentOffset: root.song.mixesModel.selectedMix.segmentsModel.count - 10 + 2


                        // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                        model: zynthian.isBootingComplete
                                ? 10
                                : 0

                        delegate: TrackHeader2 {
                            id: trackHeaderDelegate

                            property bool startDrag: false
                            property point dragStartPosition
                            property int segmentOffsetAtDragStart

                            // Calculate current cell's segment index
                            // If arrow keys are visible, take into account that arrow keys will be visible no cells 0 and 9 respectively
                            property int thisSegmentIndex: index +
                                                           (tracksHeaderRepeater.shouldShowArrows ? tracksHeaderRepeater.segmentOffset : 0) + // Offset index if arrows are visible else 0
                                                           (tracksHeaderRepeater.shouldShowArrows ? -1 : 0) // if arrows are being displayed, display segment from 2nd slot onwards
                            // A little odd looking perhaps - we use the count changed signal here to ensure we refetch the segments when we add, remove, or otherwise change the model
                            property QtObject segment: root.song.mixesModel.selectedMix.segmentsModel.count > 0
                                                        ? root.song.mixesModel.selectedMix.segmentsModel.get_segment(trackHeaderDelegate.thisSegmentIndex)
                                                        : null

                            track: root.song.tracksModel.getTrack(index)
                            text: root.songMode
                                    ? root.song.mixesModel.selectedMix.segmentsModel.count > 10
                                        ? index === 0
                                            ? "<"
                                            : index === 9
                                                ? ">"
                                                : trackHeaderDelegate.segment
                                                    ? trackHeaderDelegate.segment.name
                                                    : ""
                                        : trackHeaderDelegate.segment
                                            ? trackHeaderDelegate.segment.name
                                            : ""
                                    : trackHeaderDelegate.track.name
                            active: {
                                if (root.songMode) {
                                    // If song mode is active, mark respective arrow key cell as active if there are segments outside view
                                    if (tracksHeaderRepeater.shouldShowArrows && index === 0 && tracksHeaderRepeater.segmentOffset > 0) {
                                        return true
                                    } else if (tracksHeaderRepeater.shouldShowArrows && index === 9 && tracksHeaderRepeater.segmentOffset < tracksHeaderRepeater.maximumSegmentOffset) {
                                        return true
                                    }

                                    // If song mode is active, mark segment cell as active if it has a segment
                                    if (trackHeaderDelegate.segment != null) {
                                        return true
                                    } else {
                                        return false
                                    }
                                } else {
                                    // If song mode is not active, mark all cell as active
                                    return true
                                }
                            }
                            synthDetailsVisible: !root.songMode

                            Connections {
                                target: trackHeaderDelegate.track
                                function updateKeyZones() {
                                    // all-full is the default, but "manual" is an option and we should leave things alone in that case, so that's this function's default
                                    var sampleSettings = [];
                                    if (trackHeaderDelegate.track.keyZoneMode == "all-full") {
                                        sampleSettings = [
                                            [0, 127, 0],
                                            [0, 127, 0],
                                            [0, 127, 0],
                                            [0, 127, 0],
                                            [0, 127, 0]
                                        ];
                                    } else if (trackHeaderDelegate.track.keyZoneMode == "split-full") {
                                        // auto-split keyzones: SLOT 4 c-1 - b1, SLOT 2 c1-b3, SLOT 1 c3-b5, SLOT 3 c5-b7, SLOT 5 c7-c9
                                        // root key transpose in semtitones: +48, +24 ,0 , -24, -48
                                        sampleSettings = [
                                            [48, 71, 0], // slot 1
                                            [24, 47, -24], // slot 2
                                            [72, 95, 24], // slot 3
                                            [0, 23, -48], // slot 4
                                            [96, 119, 48] // slot 5
                                        ];
                                    } else if (trackHeaderDelegate.track.keyZoneMode == "split-narrow") {
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
                                        for (var i = 0; i < trackHeaderDelegate.track.samples.length; ++i) {
                                            var sample = trackHeaderDelegate.track.samples[i];
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
                            subText: {
                                if (root.songMode) {
                                    if (!trackHeaderDelegate.segment || (trackHeaderDelegate.segment.barLength === 0 && trackHeaderDelegate.segment.beatLength === 0)) {
                                        return ""
                                    } else {
                                        return trackHeaderDelegate.segment.barLength + "." + trackHeaderDelegate.segment.beatLength
                                    }
                                } else {
                                    return null
                                }
                            }

                            subSubText: {
                                if (root.songMode) {
                                    return ""
                                } else if (trackHeaderDelegate.track.trackAudioType === "sample-loop") {
                                    return qsTr("Loop")
                                } else if (trackHeaderDelegate.track.trackAudioType === "sample-trig") {
                                    return qsTr("Smp: Trig")
                                } else if (trackHeaderDelegate.track.trackAudioType === "sample-slice") {
                                    return qsTr("Smp: Slice")
                                } else if (trackHeaderDelegate.track.trackAudioType === "synth") {
                                    return qsTr("Synth")
                                } else if (trackHeaderDelegate.track.trackAudioType === "external") {
                                    return qsTr("External")
                                }
                            }

                            subSubTextSize: 7

                            Binding {
                                target: trackHeaderDelegate
                                property: "color"
                                when: root.visible
                                delayed: true

                                value: {
                                    if (root.copySourceObj === model.track)
                                        return "#ff2196f3"
                                    else if (trackHeaderDelegate.track.trackAudioType === "synth" && trackHeaderDelegate.track.occupiedSlotsCount > 0)
                                        return "#66ff0000"
                                    else if (trackHeaderDelegate.track.trackAudioType === "sample-loop" && trackHeaderDelegate.track.sceneClip.path && trackHeaderDelegate.track.sceneClip.path.length > 0)
                                        return "#6600ff00"
                                    else if (trackHeaderDelegate.track.trackAudioType === "sample-trig" && trackHeaderDelegate.track.occupiedSlotsCount > 0)
                                        return "#66ffff00"
                                    else if (trackHeaderDelegate.track.trackAudioType === "sample-slice" && trackHeaderDelegate.track.occupiedSlotsCount > 0)
                                        return "#66ffff00"
                                    else if (trackHeaderDelegate.track.trackAudioType === "external")
                                        return "#998e24aa"
                                    else
                                        return "#66888888"
                                }
                            }

                            highlightOnFocus: false
                            highlighted: {
                                if (root.songMode) {
                                    // If song mode is active and arrow keys are visible, do not highlight arrow key cells
                                    if (tracksHeaderRepeater.shouldShowArrows && index === 0) {
                                        return false
                                    } else if (tracksHeaderRepeater.shouldShowArrows && index === 9) {
                                        return false
                                    }

                                    // If song mode is active and cell is not an arrow key, then highlight if selected segment is current cell
                                    return trackHeaderDelegate.thisSegmentIndex === root.song.mixesModel.selectedMix.segmentsModel.selectedSegmentIndex
                                } else {
                                    // If song mode is not active, highlight if current cell is selected track
                                    return index === zynthian.session_dashboard.selectedTrack
                                }
                            }

                            onPressed: {
                                if (root.songMode) {
                                    if (tracksHeaderRepeater.shouldShowArrows && index === 0) {
                                        // If song mode is active, clicking left arrow key cells should decrement segment offset to display out of view segments
                                        tracksHeaderRepeater.segmentOffset = Math.max(0, tracksHeaderRepeater.segmentOffset - 1)
                                    } else if (tracksHeaderRepeater.shouldShowArrows && index === 9) {
                                        // If song mode is active, clicking right arrow key cells should increment segment offset to display out of view segments
                                        tracksHeaderRepeater.segmentOffset = Math.min(tracksHeaderRepeater.maximumSegmentOffset, tracksHeaderRepeater.segmentOffset + 1)
                                    } else {
                                        // If song mode is active, clicking segment cells should activate that segment
                                        if (trackHeaderDelegate.segment) {
                                            root.song.mixesModel.selectedMix.segmentsModel.selectedSegmentIndex = trackHeaderDelegate.thisSegmentIndex
                                            root.lastSelectedObj = trackHeaderDelegate.segment
                                        }
                                    }
                                } else {
                                    // If song mode is not active, clicking on cells should activate that track
                                    root.lastSelectedObj = trackHeaderDelegate.track

                                    // Open MixedTracksViewBar and switch to track
                                    bottomStack.slotsBar.trackButton.checked = true

                                    // zynthian.session_dashboard.disableNextSoundSwitchTimer();
                                    zynthian.session_dashboard.selectedTrack = index;
                                    Qt.callLater(function() {
                                        bottomBar.controlType = BottomBar.ControlType.Track;
                                        bottomBar.controlObj = trackHeaderDelegate.track;
                                    })
                                }
                            }

                            onPressAndHold: {
                                //zynthian.track.trackId = trackHeaderDelegate.track.id
                                //zynthian.current_modal_screen_id = "track"
                                if (root.songMode) {
                                    startDrag = true
                                    dragStartPosition = Qt.point(pressX, pressY)
                                    segmentOffsetAtDragStart = tracksHeaderRepeater.segmentOffset
                                }
                            }
                            onReleased: {
                                if (root.songMode) {
                                    startDrag = false
                                }
                            }

                            onPressXChanged: {
                                if (startDrag) {
                                    var offset = Math.round((pressX-dragStartPosition.x)/trackHeaderDelegate.width)

                                    if (offset < 0) {
                                        tracksHeaderRepeater.segmentOffset = Math.min(tracksHeaderRepeater.maximumSegmentOffset, segmentOffsetAtDragStart + Math.abs(offset))
                                    } else {
                                        tracksHeaderRepeater.segmentOffset = Math.max(0, segmentOffsetAtDragStart - Math.abs(offset))
                                    }
                                }
                            }
                        }
                    }
                }
                // END HEADER ROW

                RowLayout {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    spacing: 1

                    ListView {
                        Layout.preferredWidth: privateProps.headerWidth*1.5 + 8
                        Layout.maximumWidth: privateProps.headerWidth*1.5 + 8
                        Layout.fillHeight: true

                        clip: true
                        spacing: 1
                        contentY: loopGridFlickable.contentY
                        boundsBehavior: Flickable.StopAtBounds

                        model: 1

                        delegate: TableHeader {
                            text: qsTr("Scene")
                            subText: root.song.scenesModel.selectedSceneName

                            width: ListView.view.width
                            height: privateProps.headerHeight

                            highlightOnFocus: false
                            highlighted: !root.songMode &&
                                         root.displaySceneButtons

                            onPressed: {
                                if (!root.songMode) {
                                    zynthian.zynthiloops.displaySceneButtons = !zynthian.zynthiloops.displaySceneButtons
                                }
                            }
                        }
                    }

                    Flickable {
                        id: loopGridFlickable

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: loopGrid.width
                        contentHeight: loopGrid.height

                        clip: true
                        flickableDirection: Flickable.HorizontalAndVerticalFlick
                        boundsBehavior: Flickable.StopAtBounds
                        QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
                            height: 4
                        }

                        GridLayout {
                            id: loopGrid
                            rows: 1
                            flow: GridLayout.TopToBottom
                            rowSpacing: 1
                            columnSpacing: 1

                            Repeater {
                                // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                                model: zynthian.isBootingComplete ? root.song.tracksModel : 0

                                delegate: Item {
                                    Layout.preferredWidth: privateProps.cellWidth
                                    Layout.maximumWidth: privateProps.cellWidth
                                    Layout.preferredHeight: privateProps.cellHeight
                                    Layout.maximumHeight: privateProps.cellHeight

                                    TableHeader {
                                        anchors.fill: parent
                                        visible: root.displaySceneButtons || root.songMode
                                        text: String.fromCharCode(65+index).toUpperCase()
                                        highlighted: !root.songMode &&
                                                     index === root.song.scenesModel.selectedSceneIndex
                                        highlightOnFocus: false
                                        onPressed: {
                                            if (root.songMode) {
                                                root.song.mixesModel.selectedMix.segmentsModel.selectedSegment.copyClipsFromScene(index)
                                            } else {
                                                Zynthian.CommonUtils.switchToScene(index);
                                            }
                                        }
                                    }

                                    ClipCell {
                                        id: clipCell

                                        anchors.fill: parent
                                        visible: !root.displaySceneButtons && !root.songMode

                                        backgroundColor: "#000000"
                                        onHighlightedChanged: {
                                            Qt.callLater(function () {
                                                //console.log("Clip : (" + track.sceneClip.row+", "+track.sceneClip.col+")", "Selected Track :"+ zynthian.session_dashboard.selectedTrack)

                                                // Switch to highlighted clip only if previous selected bottombar object was a clip/pattern
                                                if (highlighted && (bottomBar.controlType === BottomBar.ControlType.Pattern || bottomBar.controlType === BottomBar.ControlType.Clip)) {
                                                    if (track.connectedPattern >= 0) {
                                                        bottomBar.controlType = BottomBar.ControlType.Pattern;
                                                        bottomBar.controlObj = track.sceneClip;
                                                    } else {
                                                        bottomBar.controlType = BottomBar.ControlType.Clip;
                                                        bottomBar.controlObj = track.sceneClip;
                                                    }
                                                }
                                            });
                                        }

                                        Connections {
                                            target: track.sceneClip
                                            onInCurrentSceneChanged: colorTimer.restart()
                                            onPathChanged: colorTimer.restart()
                                            onIsPlayingChanged: colorTimer.restart()
                                        }
                                        Connections {
                                            target: track
                                            onConnectedPatternChanged: colorTimer.restart()
                                            onTrackAudioTypeChanged: colorTimer.restart()
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
                                            target: zynthian.zynthiloops
                                            onIsMetronomeRunningChanged: colorTimer.restart()
                                        }
                                        Connections {
                                            target: root.song.scenesModel
                                            onSelectedSketchIndexChanged: colorTimer.restart()
                                        }

                                        Timer {
                                            id: colorTimer
                                            interval: 10
                                            onTriggered: {
                                                // update color
                                                if (track.trackAudioType === "sample-loop" && track.sceneClip && track.sceneClip.inCurrentScene && track.sceneClip.path && track.sceneClip.path.length > 0) {
                                                    // In scene
                                                    clipCell.backgroundColor = "#3381d4fa";
                                                } /*else if (track.sceneClip && (!track.sceneClip.inCurrentScene && !root.song.scenesModel.isClipInScene(track.sceneClip, track.sceneClip.col))) {
                                                    // Not in scene
                                                    clipCell.backgroundColor = "#33f44336";
                                                }*/ else if ((track.connectedPattern >= 0 && clipCell.pattern.hasNotes)
                                                    || (track.trackAudioType === "sample-loop" && track.sceneClip.path && track.sceneClip.path.length > 0)) {
                                                    clipCell.backgroundColor =  Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.02)
                                                } else {
                                                    clipCell.backgroundColor =  Qt.rgba(0, 0, 0, 1);
                                                }

                                                // update isPlaying
                                                if (track.connectedPattern < 0) {
                                                    clipCell.isPlaying = track.sceneClip.isPlaying;
                                                } else {
                                                    var patternIsPlaying = false;
                                                    if (clipCell.sequence && clipCell.sequence.isPlaying) {
                                                        if (clipCell.sequence.soloPattern > -1) {
                                                            patternIsPlaying = (clipCell.sequence.soloPattern == track.connectedPattern)
                                                        } else if (clipCell.pattern) {
                                                            patternIsPlaying = clipCell.pattern.enabled
                                                        }
                                                    }
                                                    clipCell.isPlaying = patternIsPlaying && root.song.scenesModel.isClipInScene(track.sceneClip, track.sceneClip.col) && zynthian.zynthiloops.isMetronomeRunning;
                                                }
                                            }
                                        }

                                        // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                                        sequence: zynthian.isBootingComplete ? ZynQuick.PlayGridManager.getSequenceModel(zynthian.zynthiloops.song.scenesModel.selectedSketchName) : null
                                        pattern: track.connectedPattern >= 0 && sequence && !sequence.isLoading && sequence.count > 0 ? sequence.getByPart(track.id, track.selectedPart) : null

                                        onPressed: {
                                            root.lastSelectedObj = track.sceneClip

                                            // Directly switch to track instead of implementing muting on double click
                                            // as we probably wont need muting anymore. Muting is handled by partsBar
                                            // when  none of the parts are selected
                                            if (zynthian.session_dashboard.selectedTrack === track.id) {
                                                if (bottomStack.slotsBar.trackButton.checked) {
                                                    bottomStack.slotsBar.partButton.checked = true
                                                } else {
                                                    bottomStack.slotsBar.trackButton.checked = true
                                                }

                                            } else if (zynthian.session_dashboard.selectedTrack !== track.id) {
                                                bottomStack.slotsBar.trackButton.checked = true
                                            }
//                                                zynthian.session_dashboard.disableNextSoundSwitchTimer();
                                            zynthian.session_dashboard.selectedTrack = track.id;
                                            zynthian.zynthiloops.song.scenesModel.selectedSketchIndex = track.sceneClip.col

                                            Qt.callLater(function() {
                                                if (track.connectedPattern >= 0) {
                                                    bottomBar.controlType = BottomBar.ControlType.Pattern;
                                                    bottomBar.controlObj = track.sceneClip;
                                                } else {
                                                    bottomBar.controlType = BottomBar.ControlType.Clip;
                                                    bottomBar.controlObj = track.sceneClip;
                                                }
                                            })
                                        }
                                        onPressAndHold: {
                                            bottomStack.bottomBar.controlType = BottomBar.ControlType.Pattern;
                                            bottomStack.bottomBar.controlObj = track.sceneClip;
                                            bottomStack.slotsBar.bottomBarButton.checked = true;

                                            if (track.trackAudioType === "sample-loop") {
                                                if (track.sceneClip && track.sceneClip.path && track.sceneClip.path.length > 0) {
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

                    // Create a cell in top most header row
                    Item {
                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        Layout.preferredWidth: privateProps.headerWidth*1.5

                        // Create a rectangle with 2 header cell width and 3 cell height to cover the entire empty header space
                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            width: privateProps.headerWidth*1.5
                            height: privateProps.headerHeight*3 + 2 // 3 cell height + 2 spacing height in between
                            color: Kirigami.Theme.backgroundColor

                            // Copy/paste/clear buttons container
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 1

                                // Common copy button to set the object to copy
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: privateProps.cellHeight
                                    font.pointSize: 10
                                    enabled: root.lastSelectedObj && root.lastSelectedObj.className
                                    text: qsTr("Copy %1").arg(root.lastSelectedObj && root.lastSelectedObj.className
                                                              ? root.lastSelectedObj.className === "zynthiloops_clip"
                                                                ? qsTr("Clip")
                                                                : root.lastSelectedObj.className === "zynthiloops_track"
                                                                    ? qsTr("Track")
                                                                    : root.lastSelectedObj.className === "zynthiloops_sketch"
                                                                        ? qsTr("Sketch")
                                                                        : root.lastSelectedObj.className === "zynthiloops_part"
                                                                          ? qsTr("Part")
                                                                          : root.lastSelectedObj.className === "zynthiloops_segment"
                                                                            ? qsTr("Segment")
                                                                            : root.lastSelectedObj.className === "zynthiloops_mix"
                                                                              ? qsTr("Mix")
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
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: privateProps.cellHeight
                                    font.pointSize: 10
                                    text: qsTr("Cancel Copy")
                                    visible: root.copySourceObj != null
                                    onClicked: {
                                        root.copySourceObj = null
                                    }
                                }

                                // Common button to paste object
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: privateProps.cellHeight
                                    font.pointSize: 10
                                    enabled: {
                                        if (root.copySourceObj != null &&
                                            root.copySourceObj &&
                                            root.copySourceObj.className) {

                                            // Check if source and destination are same
                                            if (root.copySourceObj.className === "zynthiloops_clip" &&
                                                root.copySourceObj !== root.song.getClip(zynthian.session_dashboard.selectedTrack, zynthian.zynthiloops.song.scenesModel.selectedSketchIndex)) {
                                                return true
                                            } else if (root.copySourceObj.className === "zynthiloops_track" &&
                                                       root.copySourceObj.id !== zynthian.session_dashboard.selectedTrack) {
                                                return true
                                            } else if (root.copySourceObj.className === "zynthiloops_sketch" &&
                                                       root.copySourceObj.sketchIndex !== root.song.scenesModel.selectedSketchIndex) {
                                                return true
                                            } else if (root.copySourceObj.className === "zynthiloops_part" &&
                                                       root.copySourceObj.partClip !== root.lastSelectedObj.partClip &&
                                                       root.lastSelectedObj.className === "zynthiloops_part") {
                                               return true
                                            } else if (root.copySourceObj.className === "zynthiloops_segment" &&
                                                       root.copySourceObj !== root.lastSelectedObj &&
                                                       root.lastSelectedObj.className === "zynthiloops_segment" &&
                                                       root.copySourceObj.mixId === root.lastSelectedObj.mixId) {
                                               return true
                                            } else if (root.copySourceObj.className === "zynthiloops_mix" &&
                                                       root.copySourceObj !== root.lastSelectedObj &&
                                                       root.lastSelectedObj.className === "zynthiloops_mix") {
                                               return true
                                            }
                                        }

                                        return false
                                    }
                                    text: qsTr("Paste %1").arg(root.copySourceObj && root.copySourceObj.className
                                                                   ? root.copySourceObj.className === "zynthiloops_clip"
                                                                       ? qsTr("Clip")
                                                                       : root.copySourceObj.className === "zynthiloops_track"
                                                                           ? qsTr("Track")
                                                                           : root.copySourceObj.className === "zynthiloops_sketch"
                                                                               ? qsTr("Sketch")
                                                                               : root.lastSelectedObj.className === "zynthiloops_part"
                                                                                 ? qsTr("Part")
                                                                                 : root.lastSelectedObj.className === "zynthiloops_segment"
                                                                                   ? qsTr("Segment")
                                                                                   : root.lastSelectedObj.className === "zynthiloops_mix"
                                                                                     ? qsTr("Mix")
                                                                                     : ""
                                                                   : "")
                                    onClicked: {
                                        if (root.copySourceObj.className && root.copySourceObj.className === "zynthiloops_clip") {
                                            var sourceClip = root.copySourceObj
                                            var destClip = root.song.getClip(zynthian.session_dashboard.selectedTrack, zynthian.zynthiloops.song.scenesModel.selectedSketchIndex)

                                            // Copy Clip
                                            destClip.copyFrom(sourceClip)
                                            // Copy pattern
                                            var sourcePattern = ZynQuick.PlayGridManager.getSequenceModel("S"+(sourceClip.col + 1)).getByPart(sourceClip.clipTrack.id, sourceClip.clipTrack.selectedPart)
                                            var destPattern = ZynQuick.PlayGridManager.getSequenceModel("S"+(destClip.col + 1)).getByPart(destClip.clipTrack.id, destClip.clipTrack.selectedPart)
                                            destPattern.cloneOther(sourcePattern)

                                            root.copySourceObj = null
                                        } else if (root.copySourceObj.className && root.copySourceObj.className === "zynthiloops_track") {
                                            zynthian.start_loading()

                                            // Copy Track
                                            var sourceTrack = root.copySourceObj
                                            var destTrack = root.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)
                                            destTrack.copyFrom(sourceTrack)

                                            for (var part=0; part<5; part++) {
                                                for (var i=0; i<sourceTrack.clipsModel.count; i++) {
                                                    var sourceClip = sourceTrack.parts[part].getClip(i)
                                                    var destClip = destTrack.parts[part].getClip(i)
                                                    var sourcePattern = ZynQuick.PlayGridManager.getSequenceModel("S"+(sourceClip.col + 1)).getByPart(sourceClip.clipTrack.id, part)
                                                    var destPattern = ZynQuick.PlayGridManager.getSequenceModel("S"+(destClip.col + 1)).getByPart(destClip.clipTrack.id, part)

                                                    destPattern.cloneOther(sourcePattern)
                                                }
                                            }

                                            root.copySourceObj = null

                                            zynthian.stop_loading()
                                        } else if (root.copySourceObj.className && root.copySourceObj.className === "zynthiloops_sketch") {
                                            zynthian.start_loading()

                                            // Copy Sketch
                                            root.song.scenesModel.copySketch(root.copySourceObj.sketchIndex, root.song.scenesModel.selectedSketchIndex)

                                            for (var i=0; i<root.song.tracksModel.count; i++) {
                                                var track = root.song.tracksModel.getTrack(i)
                                                var sourcePattern = ZynQuick.PlayGridManager.getSequenceModel("S"+(root.copySourceObj.sketchIndex + 1)).getByPart(track.id, track.selectedPart)
                                                var destPattern = ZynQuick.PlayGridManager.getSequenceModel(root.song.scenesModel.selectedSketchName).getByPart(track.id, track.selectedPart)

                                                destPattern.cloneOther(sourcePattern)
                                            }

                                            root.copySourceObj = null

                                            zynthian.stop_loading()
                                        } else if (root.copySourceObj.className && root.copySourceObj.className === "zynthiloops_part") {
                                            var sourceClip = root.copySourceObj.partClip
                                            var destClip = root.lastSelectedObj.partClip

                                            // Copy Clip
                                            destClip.copyFrom(sourceClip)
                                            // Copy pattern
                                            var sourcePattern = ZynQuick.PlayGridManager.getSequenceModel("S"+(sourceClip.col + 1)).getByPart(sourceClip.clipTrack.id, sourceClip.clipTrack.selectedPart)
                                            var destPattern = ZynQuick.PlayGridManager.getSequenceModel("S"+(destClip.col + 1)).getByPart(destClip.clipTrack.id, destClip.clipTrack.selectedPart)
                                            destPattern.cloneOther(sourcePattern)

                                            root.copySourceObj = null
                                        } else if (root.copySourceObj.className && root.copySourceObj.className === "zynthiloops_segment") {
                                            root.lastSelectedObj.copyFrom(root.copySourceObj)
                                            root.copySourceObj = null
                                        } else if (root.copySourceObj.className && root.copySourceObj.className === "zynthiloops_mix") {
                                            root.lastSelectedObj.copyFrom(root.copySourceObj)
                                            root.copySourceObj = null
                                        }
                                    }
                                }

                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: privateProps.cellHeight
                                    font.pointSize: 10
                                    enabled: root.lastSelectedObj != null &&
                                             root.lastSelectedObj.className != null &&
                                             (root.lastSelectedObj.className === "zynthiloops_clip" ||
                                              root.lastSelectedObj.className === "zynthiloops_segment" ||
                                              root.lastSelectedObj.className === "zynthiloops_mix")
                                    text: qsTr("Clear")
                                    onClicked: {
                                        if (root.lastSelectedObj.clear) {
                                            root.lastSelectedObj.clear()
                                        }

                                        if (root.lastSelectedObj.className === "zynthiloops_clip") {
                                            // Try clearing pattern if exists.
                                            try {
                                                if (root.lastSelectedObj.clipTrack.connectedPattern >= 0) {
                                                    ZynQuick.PlayGridManager.getSequenceModel("S"+(root.song.scenesModel.selectedSketchIndex + 1)).getByPart(root.lastSelectedObj.clipTrack.id, root.lastSelectedObj.clipTrack.selectedPart).clear()
                                                }
                                            } catch(e) {}
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StackLayout {
                id: bottomStack

                property alias bottomBar: bottomBar
                property alias slotsBar: slotsBar

                Layout.preferredHeight: Kirigami.Units.gridUnit * 15
                Layout.fillWidth: true
                Layout.fillHeight: false
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

                MixedTracksViewBar {
                    id: mixedTracksViewBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                PartBar {
                    id: partBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onClicked: {
                        root.lastSelectedObj = {
                            className: "zynthiloops_part",
                            partClip: partBar.selectedPartClip
                        }
                    }
                }

                TracksViewSoundsBar {
                    id: soundCombinatorBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
