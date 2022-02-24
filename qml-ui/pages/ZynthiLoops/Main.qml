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

Zynthian.ScreenPage {
    property alias zlScreen: root

    id: root

    readonly property QtObject song: zynthian.zynthiloops.song
    property QtObject selectedTrack: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)

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
                        fileNameDialog.fileName = zynthian.zynthiloops.song.suggestedName ? zynthian.zynthiloops.song.suggestedName : "Sketch-1";
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
            id: sceneActionBtn
            text: qsTr("Scenes")
            checkable: true
            onCheckedChanged: updateLedVariablesTimer.restart()
            onTriggered: {
                mixerActionBtn.checked = false;

                if (!checked) {
                    bottomStack.currentIndex = 2;
                } else {
                    bottomStack.currentIndex = 0;
                }
            }
        },
        Kirigami.Action {
            id: mixerActionBtn
            text: qsTr("Mixer")
            checkable: true
            onCheckedChanged: updateLedVariablesTimer.restart()
            onTriggered: {
                sceneActionBtn.checked = false;

                if (!checked) {
                    // Open Mixer
                     zynthian.zynthiloops.startMonitorMasterAudioLevels();
                    bottomStack.currentIndex = 1;
                } else {
                    // Close Mixer
                     zynthian.zynthiloops.stopMonitorMasterAudioLevels();
                    bottomStack.currentIndex = 0;
                }
            }
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

        // Forward CUIA actions to bottomBar only when bottomBar is open
        if (bottomStack.currentIndex === 0) {
            if (bottomBar.filePickerDialog.opened) {
                if (bottomBar.filePickerDialog.cuiaCallback(cuia)) {
                    return true;
                }
            }

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
                var selectedMidiChannel = root.selectedTrack.chainedSounds[zynthian.session_dashboard.selectedSoundRow];
                if (root.selectedTrack.checkIfLayerExists(selectedMidiChannel)) {
                    zynthian.layer.selectPrevPreset(selectedMidiChannel);
                }
                return true;

            case "SELECT_DOWN":
                var selectedMidiChannel = root.selectedTrack.chainedSounds[zynthian.session_dashboard.selectedSoundRow];
                if (root.selectedTrack.checkIfLayerExists(selectedMidiChannel)) {
                    zynthian.layer.selectNextPreset(selectedMidiChannel);
                }
                return true;

            case "MODE_SWITCH_SHORT":
            case "MODE_SWITCH_LONG":
            case "MODE_SWITCH_BOLD":
                if (mixerActionBtn.checked) {
                    bottomBar.controlType = BottomBar.ControlType.Track;
                    bottomBar.controlObj = zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack);
                    
                    bottomStack.currentIndex = 0;
                    mixerActionBtn.checked = false;
                } else {
                    sceneActionBtn.checked = false;
                    mixerActionBtn.checked = true;
                    bottomStack.currentIndex = 1;
                }
                return true;
        }

        return false;
    }

    Timer {
        id: updateLedVariablesTimer
        interval: 100
        repeat: false
        onTriggered: {
            // Check and set proper variables

            // Check if sound combinator is active
            if (bottomStack.currentIndex == 0 && // Checks if bottombar is visible
                bottomBar.tabbedView.activeAction.page.search("TracksViewSoundsBar") >= 0 && // Checks if current active page is sound combinator or not
                sceneActionBtn.checked == false && // Checks if scenes button is unchecked
                mixerActionBtn.checked == false) // Checks if mixer button is unchecked
            {
                zynthian.soundCombinatorActive = true;
            } else {
                zynthian.soundCombinatorActive = false;
            }
        }
    }

    Connections {
        target: zynthian
        onCurrent_screen_idChanged: {
            // Select connected sound of selected track if not already selected
            if (zynthian.current_screen_id === "zynthiloops"
                && bottomBar.controlType !== BottomBar.ControlType.Track) {
                sceneActionBtn.checked = false;
                mixerActionBtn.checked = true;
                bottomStack.currentIndex = 1;
                bottomBar.controlObj = root.song;
            }
        }
    }

    Connections {
        target: zynthian.zynthiloops
        onNewSketchLoaded: {
            /*var sequence = ZynQuick.PlayGridManager.getSequenceModel("Global");
            sequence.song = zynthian.zynthiloops.song;
            sequence.clear();

            for (var i=0; i<5; i++) {
                var pattern = sequence.get(i);
                pattern.enabled = false;
            }*/
        }
        onLongTaskStarted: {
            longTaskOverlay.open = true;
        }
        onLongTaskEnded: {
            longTaskOverlay.open = false;
        }
        onSong_changed: {
            console.log("$$$ Song Changed :", song)

            // Reset focus to song cell
            songCell.focus = true
            songCell.focus = false
            bottomBar.controlType = BottomBar.ControlType.Song;
            bottomBar.controlObj = root.song;
            mixerActionBtn.checked = true;
            sceneActionBtn.checked = false;
            bottomStack.currentIndex = 1;
        }
    }

    Component.onCompleted: {
        applicationWindow().controlsVisible = true;
        bottomBar.controlType = BottomBar.ControlType.Song;
        bottomBar.controlObj = root.song;
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
            zynthian.zynthiloops.loadSketch(file.filePath)
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
            interval: 1000
            onTriggered: {
                selectedTrackOutline.x = Qt.binding(function() { return tracksHeaderRow.mapToItem(content, tracksHeaderRepeater.itemAt(zynthian.session_dashboard.selectedTrack).x, 0).x })
                selectedTrackOutline.y = Qt.binding(function() { return tracksHeaderRow.mapToItem(content, 0, tracksHeaderRepeater.itemAt(zynthian.session_dashboard.selectedTrack).y).y })
            }
        }

        Rectangle {
            id: selectedTrackOutline
            width: privateProps.headerWidth
            height: privateProps.headerHeight*2 + loopGrid.columnSpacing*2
            color: "#2affffff"
            z: 100
        }

        Zynthian.ModalLoadingOverlay {
            id: longTaskOverlay
            parent: applicationWindow().contentItem.parent
            anchors.fill: parent
            z: 9999999
            open: false
        }

        ColumnLayout {
            anchors.fill: parent

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
                        Layout.preferredWidth: privateProps.headerWidth + 8
                        Layout.maximumWidth: privateProps.headerWidth + 8
                        Layout.fillHeight: true

                        text: root.song.name
//                        subText: qsTr("Scene %1").arg(root.song.scenesModel.getScene(root.song.scenesModel.selectedSceneIndex).name)
                        // subText: "BPM: " + root.song.bpm
                        // subSubText: qsTr("Scale: %1").arg(root.song.selectedScale)

                        textSize: 11
//                        subTextSize: 9
//                        subSubTextSize: 0

                        onPressed: {
                            // If Mixer is not open, open mixer first
                            if (bottomStack.currentIndex !== 1) {
                                bottomStack.currentIndex = 1
                                mixerActionBtn.checked = true;
                                sceneActionBtn.checked = false;

                                return;
                            }

                            bottomBar.controlType = BottomBar.ControlType.Song;
                            bottomBar.controlObj = root.song;

                            if (mixerActionBtn.checked) {
                                bottomStack.currentIndex = 0
                                mixerActionBtn.checked = false
                            }
                        }
                    }

                    Repeater {
                        model: root.song.scenesModel
                        delegate: TableHeader {
                            id: sceneHeaderDelegate
                            text: model.scene.name
                            color: Kirigami.Theme.backgroundColor

                            Layout.fillWidth: false
                            Layout.fillHeight: true
                            Layout.preferredWidth: privateProps.headerWidth

                            highlightOnFocus: false
                            highlighted: root.song.scenesModel.selectedSceneIndex === index

                            onPressed: {
                                // If Mixer is not open, open mixer first
                                if (bottomStack.currentIndex !== 1) {
                                    bottomStack.currentIndex = 1
                                    mixerActionBtn.checked = true;
                                    sceneActionBtn.checked = false;

                                    return;
                                }

                                Zynthian.CommonUtils.switchToScene(index);
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: "#2affffff"
                                visible: root.song.scenesModel.selectedSceneIndex === index
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
                        Layout.preferredWidth: privateProps.headerWidth + 8
                        Layout.maximumWidth: privateProps.headerWidth + 8
                        Layout.fillHeight: true

                        text: qsTr("Scene %1").arg(root.song.scenesModel.getScene(root.song.scenesModel.selectedSceneIndex).name)

                        textSize: 11
                        subTextSize: 9
                        subSubTextSize: 0

                        highlightOnFocus: false
                        highlighted: false

                        onPressed: {
                        }
                    }

                    Repeater {
                        id: tracksHeaderRepeater
                        model: root.song.tracksModel

                        delegate: TableHeader {
                            text: model.track.name

                            // hide "Pat.1" info in the track header cells, as Track 1 will be Pat.1, to T10 - Pat.10
//                            subText: model.track.connectedPattern >= 0
//                                      ? "Pat. " + (model.track.connectedPattern+1)
//                                      : ""
                            subSubText: model.track.trackAudioType.toUpperCase()
                            color: Kirigami.Theme.backgroundColor

                            width: privateProps.headerWidth
                            height: ListView.view.height

                            highlightOnFocus: false
                            highlighted: index === zynthian.session_dashboard.selectedTrack

                            onPressed: {
                                // If Mixer is not open, open mixer first and switch to track
                                if (bottomStack.currentIndex !== 1) {
                                    bottomStack.currentIndex = 1
                                    mixerActionBtn.checked = true;
                                    sceneActionBtn.checked = false;

                                    zynthian.session_dashboard.disableNextSoundSwitchTimer();
                                    zynthian.session_dashboard.selectedTrack = index;
                                    bottomBar.controlType = BottomBar.ControlType.Track;
                                    bottomBar.controlObj = model.track;

                                    return;
                                }

                                if (index !== zynthian.session_dashboard.selectedTrack &&
                                    bottomBar.controlObj !== model.track) {
                                    // Set current selected track
                                    bottomBar.controlType = BottomBar.ControlType.Track;
                                    bottomBar.controlObj = model.track;

                                    zynthian.session_dashboard.disableNextSoundSwitchTimer();
                                    zynthian.session_dashboard.selectedTrack = index;

                                    sceneActionBtn.checked = false;
                                    mixerActionBtn.checked = true;
                                    bottomStack.currentIndex = 1;
                                } else {
                                    // Current selected track is already set. open sounds dialog

                                    bottomBar.controlType = BottomBar.ControlType.Track;
                                    bottomBar.controlObj = model.track;

                                    if (bottomBar.tabbedView.activeItem.resetModel) {
                                        // Reset model to load new changes if any
                                        bottomBar.tabbedView.activeItem.resetModel();
                                    } else {
                                        console.error("TrackViewSoundsBar is not loaded !!! Cannot reset model")
                                    }

                                    if (mixerActionBtn.checked) {
                                        bottomStack.currentIndex = 0
                                        mixerActionBtn.checked = false
                                    } else {
                                        sceneActionBtn.checked = false;
                                        mixerActionBtn.checked = true;
                                        bottomStack.currentIndex = 1;
                                    }
                                }
                            }

                            onPressAndHold: {
                                zynthian.track.trackId = model.track.id
                                //zynthian.current_modal_screen_id = "track"
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
                        Layout.preferredWidth: privateProps.headerWidth + 8
                        Layout.maximumWidth: privateProps.headerWidth + 8
                        Layout.fillHeight: true

                        clip: true
                        spacing: 1
                        contentY: loopGridFlickable.contentY
                        boundsBehavior: Flickable.StopAtBounds

                        model: 1

                        delegate: TableHeader {
                            text: "Clips"

                            width: ListView.view.width
                            height: privateProps.headerHeight

                            highlightOnFocus: false
                            highlighted: false
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
                                model: root.song.tracksModel

                                delegate: Repeater {
                                    property int rowIndex: index

                                    model: track.clipsModel

                                    delegate: ClipCell {
                                        id: clipCell

                                        Component.onCompleted: {
                                            console.log("^^^ Clip Cell Created :", rowIndex, index)
                                        }
                                        Component.onDestruction: {
                                            console.log("$$$ Clip Cell Destroyed :", rowIndex, index)
                                        }

                                        backgroundColor: "#000000"
                                        highlightColor: !highlighted && model.clip.inCurrentScene && model.clip.path && model.clip.path.length > 0
                                                            ? Qt.rgba(255,255,255,0.6)
                                                            : highlighted
                                                                ? model.clip.inCurrentScene
                                                                    ? Kirigami.Theme.highlightColor
                                                                    : "#aaf44336"
                                                                : "transparent"
                                        highlighted: model.clip.row === zynthian.session_dashboard.selectedTrack && model.clip.col === zynthian.zynthiloops.selectedClipCol // bottomBar.controlObj === model.clip
                                        onHighlightedChanged: {
                                            console.log("Clip : (" + model.clip.row+", "+model.clip.col+")", "Selected Track :", zynthian.session_dashboard.selectedTrack)

                                            if (highlighted) {
                                                if (track.connectedPattern >= 0) {
                                                    bottomBar.controlType = BottomBar.ControlType.Pattern;
                                                    bottomBar.controlObj = model.clip;
                                                } else {
                                                    bottomBar.controlType = BottomBar.ControlType.Clip;
                                                    bottomBar.controlObj = model.clip;
                                                }
                                            }
                                        }

                                        Connections {
                                            target: model.clip
                                            onInCurrentSceneChanged: colorTimer.restart()
                                            onPathChanged: colorTimer.restart()
                                            onIsPlayingChanged: colorTimer.restart()
                                        }
                                        Connections {
                                            target: track
                                            onConnectedPatternChanged: colorTimer.restart()
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

                                        Timer {
                                            id: colorTimer
                                            interval: 50
                                            onTriggered: {
                                                // update color
                                                var hasNotes = false;
                                                try {
                                                    hasNotes = clipCell.pattern.bankHasNotes(0)
                                                } catch(err) {}

                                                if (model.clip.inCurrentScene && model.clip.path && model.clip.path.length > 0) {
                                                    // In scene
                                                    clipCell.backgroundColor = "#3381d4fa";
                                                } else if (!model.clip.inCurrentScene && !root.song.scenesModel.isClipInScene(model.clip, model.clip.col)) {
                                                    // Not in scene
                                                    clipCell.backgroundColor = "#33f44336";
                                                } else if ((track.connectedPattern >= 0 && hasNotes)
                                                    || (model.clip.path && model.clip.path.length > 0)) {
                                                    clipCell.backgroundColor =  Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.02)
                                                } else {
                                                    clipCell.backgroundColor =  Qt.rgba(0, 0, 0, 1);
                                                }

                                                // update isPlaying
                                                if (track.connectedPattern < 0) {
                                                    clipCell.isPlaying = model.clip.isPlaying;
                                                } else {
                                                    var patternIsPlaying = false;
                                                    if (clipCell.sequence && clipCell.sequence.isPlaying) {
                                                        /*if (pattern.isEmpty) {
                                                            return false
                                                        } else if ((model.clip.col === 0 && pattern.bank !== "I")
                                                            || (model.clip.col === 1 && pattern.bank !== "II")) {
                                                            clipCell.isPlaying = false
                                                        } else */if (clipCell.sequence.soloPattern > -1) {
                                                            patternIsPlaying = (clipCell.sequence.soloPattern == track.connectedPattern)
                                                        } else if (clipCell.pattern) {
                                                            patternIsPlaying = clipCell.pattern.enabled
                                                        }
                                                    }
                                                    clipCell.isPlaying = patternIsPlaying && root.song.scenesModel.isClipInScene(model.clip, model.clip.col) && zynthian.zynthiloops.isMetronomeRunning;
                                                }
                                            }
                                        }

                                        property QtObject sequence: track.connectedPattern >= 0 ? ZynQuick.PlayGridManager.getSequenceModel("Scene "+zynthian.zynthiloops.song.scenesModel.selectedSceneName) : null
                                        property QtObject pattern: sequence ? sequence.get(track.connectedPattern) : null

                                        visible: model.clip.col === zynthian.zynthiloops.selectedClipCol
                                        Layout.preferredWidth: model.clip.col !== zynthian.zynthiloops.selectedClipCol ? 0 : privateProps.cellWidth
                                        Layout.maximumWidth: model.clip.col !== zynthian.zynthiloops.selectedClipCol ? 0 : privateProps.cellWidth
                                        Layout.preferredHeight: model.clip.col !== zynthian.zynthiloops.selectedClipCol ? 0 : privateProps.cellHeight
                                        Layout.maximumHeight: model.clip.col !== zynthian.zynthiloops.selectedClipCol ? 0 : privateProps.cellHeight

                                        onPressed: {
                                            if (dblTimer.running || sceneActionBtn.checked) {
                                                root.song.scenesModel.toggleClipInCurrentScene(model.clip);

                                                if (track.connectedPattern >= 0) {
                                                    var seq = ZynQuick.PlayGridManager.getSequenceModel("Scene "+zynthian.zynthiloops.song.scenesModel.selectedSceneName).get(track.connectedPattern);
                                                    seq.bank = model.clip.col === 0 ? "A" : "B";
                                                    seq.enabled = model.clip.inCurrentScene;

                                                    console.log("Clip Row :", model.clip.row, ", Enabled :", seq.enabled);
                                                }
                                                dblTimer.stop()
                                                return
                                            }
                                            dblTimer.restart()

                                            // If Mixer is not open, open mixer first and switch to track
                                            if (bottomStack.currentIndex !== 1) {
                                                bottomStack.currentIndex = 1
                                                mixerActionBtn.checked = true;
                                                sceneActionBtn.checked = false;
                                                dblTimer.stop();

                                                zynthian.session_dashboard.disableNextSoundSwitchTimer();
                                                zynthian.session_dashboard.selectedTrack = rowIndex;

                                                return;
                                            }
                                        }
                                        Timer { //FIXME: why onDoubleClicked doesn't work
                                            id: dblTimer
                                            interval: 200
                                            onTriggered: {
                                                if (zynthian.session_dashboard.selectedTrack === track.id
                                                    && mixerActionBtn.checked) {
                                                    bottomStack.currentIndex = 0
                                                    mixerActionBtn.checked = false
                                                } else if (zynthian.session_dashboard.selectedTrack !== track.id) {
                                                    sceneActionBtn.checked = false;
                                                    mixerActionBtn.checked = true;
                                                    bottomStack.currentIndex = 1;
                                                }

                                                zynthian.session_dashboard.disableNextSoundSwitchTimer();
                                                zynthian.session_dashboard.selectedTrack = track.id;
                                                zynthian.zynthiloops.selectedClipCol = model.clip.col

                                                if (track.connectedPattern >= 0) {
                                                    bottomBar.controlType = BottomBar.ControlType.Pattern;
                                                    bottomBar.controlObj = model.clip;
                                                } else {
                                                    bottomBar.controlType = BottomBar.ControlType.Clip;
                                                    bottomBar.controlObj = model.clip;
                                                }
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
                        Layout.preferredWidth: privateProps.headerWidth*2

                        // Create a rectangle with 2 header cell width and 3 cell height to cover the entire empty header space
                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            width: privateProps.headerWidth*2
                            height: privateProps.headerHeight*3 + 2 // 3 cell height + 2 spacing height in between
                            color: Kirigami.Theme.backgroundColor

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 1

                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: privateProps.cellHeight
                                    text: qsTr("Copy")
                                }

                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: privateProps.cellHeight
                                    text: qsTr("Paste")
                                }

                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: privateProps.cellHeight
                                    text: qsTr("Delete")
                                }
                            }
                        }
                    }
                }
            }

            StackLayout {
                id: bottomStack
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

                ScenesBar {
                    id: scenesBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                color: Kirigami.Theme.backgroundColor

                RowLayout {
                    id: infoBar

                    property var clip: root.song.getClip(zynthian.session_dashboard.selectedTrack, zynthian.zynthiloops.selectedClipCol)
                    property string synthName: ""

                    width: parent.width - Kirigami.Units.gridUnit
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.gridUnit

                    onClipChanged: updateSoundNameTimer.restart()

                    function updateSoundName() {
                        var layerIndex = -1;
                        var count = 0;
                        for (var i in infoBar.clip.clipTrack.chainedSounds) {
                            if (infoBar.clip.clipTrack.chainedSounds[i] >= 0 &&
                                infoBar.clip.clipTrack.checkIfLayerExists(i)) {
                                if (layerIndex < 0) {
                                    layerIndex = i
                                }

                                count++;
                            }
                        }

                        layerLabel.layerIndex = layerIndex
                        layerLabel.layerCount = count

                        for (var id in infoBar.clip.clipTrack.chainedSounds) {
                            if (infoBar.clip.clipTrack.chainedSounds[id] >= 0 &&
                                infoBar.clip.clipTrack.checkIfLayerExists(infoBar.clip.clipTrack.chainedSounds[id])) {
                                var soundName = zynthian.fixed_layers.selector_list.getDisplayValue(infoBar.clip.clipTrack.chainedSounds[id]).split(">");
                                infoBar.synthName = soundName[0] ? soundName[0].trim() : "";
                                break;
                            }

                            // If sound not connected, set text to none
                            infoBar.synthName = "<none>"
                        }
                    }

                    Timer {
                        id: updateSoundNameTimer
                        repeat: false
                        interval: 1000
                        onTriggered: infoBar.updateSoundName()
                    }

                    Connections {
                        target: zynthian.fixed_layers
                        onList_updated: {
                            updateSoundNameTimer.restart()
                        }
                    }

                    Connections {
                        target: infoBar.clip.clipTrack
                        onChainedSoundsChanged: {
                            updateSoundNameTimer.restart()
                        }
                    }

                    QQC2.Label {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignVCenter
                        text: qsTr("T%1").arg(zynthian.session_dashboard.selectedTrack+1)
                    }
                    QQC2.Label {
                        id: layerLabel

                        property int layerIndex: -1
                        property int layerCount: 0

                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignVCenter
                        text: qsTr("Layer %1 %2")
                                .arg(layerIndex >= 0 ? layerIndex+1 : "<none>")
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
                        text: qsTr("Preset: %1").arg(zynthian.zynthiloops.selectedPresetName === "-" ? "<none>" : zynthian.zynthiloops.selectedPresetName)
                    }
                    QQC2.Label {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignVCenter
                        text: qsTr("Bank: %1").arg(zynthian.bank.selector_list.getDisplayValue(zynthian.bank.current_index))
                    }
                    QQC2.Label {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignVCenter
                        text: qsTr("Synth: %1").arg(infoBar.synthName)
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
                    }
                    QQC2.Label {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignVCenter
                        text: qsTr("%1 %2")
                                .arg(infoBar.clip.name)
                                .arg(infoBar.clip.inCurrentScene ? "(Active)" : "")
                    }
                }
            }
        }
    }
}
