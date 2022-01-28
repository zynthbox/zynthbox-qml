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
    signal cuiaNavUp();
    signal cuiaNavDown();
    signal cuiaNavBack();
    signal cuiaSelect();

    title: qsTr("Zynthiloops")
    screenId: "zynthiloops"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8
    backAction.visible: false
    onSongChanged: {
        console.log("Song Changed :", song)

        // Reset focus to song cell
        songCell.focus = true
        bottomBar.controlType = BottomBar.ControlType.Song;
        bottomBar.controlObj = root.song;
    }

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
            id: sceneActionBtn
            text: qsTr("Scenes")
            checkable: true
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
           /* text: zynthian.zynthiloops.isMetronomeRunning ? qsTr("Stop") : qsTr("Start")
            onTriggered: {
                if (zynthian.zynthiloops.isMetronomeRunning) {
                    Zynthian.CommonUtils.stopMetronomeAndPlayback();
                } else {
                    Zynthian.CommonUtils.startMetronomeAndPlayback();
                }
            }*/
           enabled: false
        },
        Kirigami.Action {
            id: mixerActionBtn
            text: qsTr("Mixer")
            checkable: true
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

        if (bottomBar.filePickerDialog.opened) {
            return bottomBar.filePickerDialog.cuiaCallback(cuia);
        }

        if (bottomBar.tabbedView.activeItem.cuiaCallback != null) {
            return bottomBar.tabbedView.activeItem.cuiaCallback(cuia);
        }

        return false;
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
            var sequence = ZynQuick.PlayGridManager.getSequenceModel("Global");
            sequence.song = zynthian.zynthiloops.song;
            sequence.clear();

            for (var i=0; i<5; i++) {
                var pattern = sequence.get(i);
                pattern.enabled = false;
            }
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

        //Try to fit exactly 12 cells + a header cell
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
        rootFolder: "/zynthian/zynthian-my-data/sketches"
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
                selectedTrackOutline.x = Qt.binding(function() { return partsHeaderRow.mapToItem(content, partsHeaderRepeater.itemAt(zynthian.session_dashboard.selectedTrack).x, 0).x })
                selectedTrackOutline.y = Qt.binding(function() { return partsHeaderRow.mapToItem(content, 0, partsHeaderRepeater.itemAt(zynthian.session_dashboard.selectedTrack).y).y })
            }
        }

        Rectangle {
            id: selectedTrackOutline
            width: privateProps.headerWidth
            height: privateProps.headerHeight*3 + loopGrid.columnSpacing*2
            color: "#2affffff"
            z: 100
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
                        subText: qsTr("Scene %1").arg(root.song.scenesModel.getScene(root.song.scenesModel.selectedSceneIndex).name)
                        // subText: "BPM: " + root.song.bpm
                        // subSubText: qsTr("Scale: %1").arg(root.song.selectedScale)

                        textSize: 11
                        subTextSize: 9
                        subSubTextSize: 0

                        onPressed: {
                            bottomBar.controlType = BottomBar.ControlType.Song;
                            bottomBar.controlObj = root.song;

                            if (mixerActionBtn.checked) {
                                bottomStack.currentIndex = 0
                                mixerActionBtn.checked = false
                            }
                        }

                    }

                    RowLayout {
                    // ListView {
                        id: partsHeaderRow

                        Layout.fillWidth: true
                        Layout.fillHeight: true

//                        clip: true
                        spacing: 1
//                        contentX: loopGridFlickable.contentX
//                        orientation: Qt.Horizontal
//                        boundsBehavior: Flickable.StopAtBounds

                        Repeater {
                            id: partsHeaderRepeater
                            model: root.song.tracksModel

                            delegate: TableHeader {
                                text: model.track.name
                                subText: model.track.connectedPattern >= 0
                                          ? "Pat. " + (model.track.connectedPattern+1)
                                          : ""
                                color: Kirigami.Theme.backgroundColor

                                width: privateProps.headerWidth
                                height: ListView.view.height

                                onPressed: {
                                    if (bottomBar.controlObj !== model.track) {
                                        // Set current selected track
                                        bottomBar.controlType = BottomBar.ControlType.Track;
                                        bottomBar.controlObj = model.track;

                                        zynthian.session_dashboard.selectedTrack = index;

                                        sceneActionBtn.checked = false;
                                        mixerActionBtn.checked = true;
                                        bottomStack.currentIndex = 1;
                                    } else {
                                        // Current selected track is already set. open sounds dialog

                                        if (bottomBar.tabbedView.activeItem.resetModel) {
                                            // Reset model to load new changes if any
                                            bottomBar.tabbedView.activeItem.resetModel();
                                        } else {
                                            console.error("TrackViewSoundsBar is not loaded !!! Cannot reset model")
                                        }

                                        if (mixerActionBtn.checked) {
                                            bottomStack.currentIndex = 0
                                            mixerActionBtn.checked = false
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
                }
                // END HEADER ROW

                RowLayout {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    spacing: 1

                    ListView {
                        id: tracksHeaderColumns

                        Layout.preferredWidth: privateProps.headerWidth + 8
                        Layout.maximumWidth: privateProps.headerWidth + 8
                        Layout.fillHeight: true

                        clip: true
                        spacing: 1
                        contentY: loopGridFlickable.contentY
                        boundsBehavior: Flickable.StopAtBounds

                        model: root.song.partsModel

                        delegate: TableHeader {
                            text: part.name
                            // subText: qsTr("%L1 Bar").arg(model.part.length)

                            width: ListView.view.width
                            height: privateProps.headerHeight

                            onPressed: {
                                bottomBar.controlType = BottomBar.ControlType.Part;
                                bottomBar.controlObj = model.part;

                                if (mixerActionBtn.checked) {
                                    bottomStack.currentIndex = 0
                                    mixerActionBtn.checked = false
                                }
                            }

                            Kirigami.Icon {
                                width: 14
                                height: 14
                                color: "white"
                                anchors {
                                    right: parent.right
                                    top: parent.top
                                }

                                source: "media-playback-start"
                                visible: model.part.isPlaying
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

                        contentX: partsHeaderRow.contentX - partsHeaderRow.originX
                        contentY: tracksHeaderColumns.contentY

                        GridLayout {
                            id: loopGrid
                            rows: root.song.partsModel.count
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
                                        isPlaying: {
                                            if (track.connectedPattern < 0) {
                                                return model.clip.isPlaying;
                                            } else {
                                                var patternIsPlaying = false;
                                                var sequence = ZynQuick.PlayGridManager.getSequenceModel("Global");
                                                if (sequence && sequence.isPlaying) {
                                                    var pattern = sequence.get(track.connectedPattern);
                                                    /*if (pattern.isEmpty) {
                                                        return false
                                                    } else */if ((model.clip.col === 0 && pattern.bank !== "I")
                                                        || (model.clip.col === 1 && pattern.bank !== "II")) {
                                                        return false
                                                    } else if (sequence.soloPattern > -1) {
                                                        patternIsPlaying = (sequence.soloPattern == track.connectedPattern)
                                                    } else if (pattern) {
                                                        patternIsPlaying = pattern.enabled
                                                    }
                                                }
                                                return patternIsPlaying && model.clip.inCurrentScene;
                                            }
                                        }

                                        highlighted: bottomBar.controlObj === model.clip

                                        backgroundColor: {
                                            var pattern = null;
                                            var hasNotes = false;
                                            try {
                                                pattern = ZynQuick.PlayGridManager.getSequenceModel("Global").get(track.connectedPattern);
                                                hasNotes = pattern.lastModified > -1 ? pattern.bankHasNotes(model.clip.col) : pattern.bankHasNotes(model.clip.col)
                                            } catch(err) {}

                                            if (model.clip.inCurrentScene) {
                                                return "#3381d4fa";
                                            } else if ((track.connectedPattern >= 0 && hasNotes)
                                                || (model.clip.path && model.clip.path.length > 0)) {
                                                return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.02)
                                            } else {
                                                return Qt.rgba(0, 0, 0, 1);
                                            }
                                        }

                                        property QtObject sequence: track.connectedPattern >= 0 ? ZynQuick.PlayGridManager.getSequenceModel("Global") : null
                                        property QtObject pattern: sequence ? sequence.get(track.connectedPattern) : null

                                        Layout.preferredWidth: privateProps.cellWidth
                                        Layout.maximumWidth: privateProps.cellWidth
                                        Layout.preferredHeight: privateProps.cellHeight
                                        Layout.maximumHeight: privateProps.cellHeight

                                        onPressed: {
                                            zynthian.session_dashboard.selectedTrack = track.id;

                                            if (track.connectedPattern >= 0) {
                                                bottomBar.controlType = BottomBar.ControlType.Pattern;
                                                bottomBar.controlObj = model.clip;
                                            } else {
                                                bottomBar.controlType = BottomBar.ControlType.Clip;
                                                bottomBar.controlObj = model.clip;
                                            }


                                            if (dblTimer.running || sceneActionBtn.checked) {
                                                root.song.scenesModel.toggleClipInCurrentScene(model.clip);

                                                if (track.connectedPattern >= 0) {
                                                    var seq = ZynQuick.PlayGridManager.getSequenceModel("Global").get(track.connectedPattern);
                                                    seq.bank = model.clip.col === 0 ? "A" : "B";
                                                    seq.enabled = model.clip.inCurrentScene;

                                                    console.log("Clip Row :", model.clip.row, ", Enabled :", seq.enabled);
                                                }
                                            }
                                            dblTimer.restart()

                                            if (mixerActionBtn.checked) {
                                                bottomStack.currentIndex = 0
                                                mixerActionBtn.checked = false
                                            }
                                        }
                                        Timer { //FIXME: why onDoubleClicked doesn't work
                                            id: dblTimer
                                            interval: 200
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
                Layout.preferredHeight: Kirigami.Units.gridUnit * 15
                Layout.fillWidth: true
                Layout.fillHeight: false

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
        }
    }
}
