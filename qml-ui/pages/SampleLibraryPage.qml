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

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Qt.labs.folderlistmodel 2.15

import Helpers 1.0 as Helpers
import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.ScreenPage {
    id: component

    property bool isVisible: ["sample_library"].indexOf(zynqtgui.current_screen_id) >= 0
    property QtObject selectedChannel: null
    Timer {
        id: selectedChannelThrottle
        interval: 1; running: false; repeat: false;
        onTriggered: {
            component.selectedChannel = null;
            component.selectedChannel = applicationWindow().selectedChannel;
        }
    }
    Connections {
        target: applicationWindow()
        onSelectedChannelChanged: selectedChannelThrottle.restart()
    }
    Connections {
        target: zynqtgui.sketchpad
        onSongChanged: selectedChannelThrottle.restart()
    }
    Connections {
        target: zynqtgui.sketchpad.song
        onIsLoadingChanged: selectedChannelThrottle.restart()
    }
    Component.onCompleted: {
        selectedChannelThrottle.restart()
    }

    property bool focusSampleNextTimeWeAreVisible: false
    onSelectedChannelChanged: {
        if (component.isVisible == false) {
            component.focusSampleNextTimeWeAreVisible = true;
        }
    }
    Connections {
        target: component.selectedChannel ? component.selectedChannel.selectedSlot : null
        enabled: component.isVisible == false
        onValueChanged: {
            component.focusSampleNextTimeWeAreVisible = true;
        }
    }
    onIsVisibleChanged: {
        if (component.focusSampleNextTimeWeAreVisible) {
            component.focusSampleNextTimeWeAreVisible = false;
            if (component.selectedChannel) {
                let selectedClip = component.selectedChannel.trackType === "sample-loop"
                    ? component.selectedChannel.getClipsModelById(component.selectedChannel.selectedSlot.value).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                    : component.selectedChannel.samples[component.selectedChannel.selectedSlot.value]
                if (selectedClip.path == "") {
                    // - If there is nothing in the selected slot, select the middle column
                    _private.selectedColumn = 1;
                } else {
                    // - If there is something in the selected slot, select the right-hand column, select the path for the currently selected sample in the centre column, and select that sample in the right hand column
                    _private.selectedColumn = 2;
                    // This check probably could be removed at some point, but for now we'll have a bunch of slots filled where there isn't an original path set
                    if (selectedClip.metadata.originalPath !== "") {
                        filesListView.selectFile(selectedClip.metadata.originalPath);
                    }
                }
            }
        }
    }

    backAction: Kirigami.Action {
        text: qsTr("Back")
        onTriggered: zynqtgui.current_screen_id = "sketchpad"
    }
    contextualActions: [
        Kirigami.Action {
            text: qsTr("Sounds")
            onTriggered: {
                // FIXME
                // Do not immediately show sound_cateopries page as it starts a long task which in turn
                // does a processEvents call causing some discomfort. Instead start loading sounds from next tick
                Qt.callLater(function() { zynqtgui.show_modal("sound_categories") })
            }
        },
        Kirigami.Action {
            text: qsTr("Favorites")
            checkable: true
            checked: zynqtgui.sample_library.show_only_favorites
            onToggled: {
                zynqtgui.sample_library.show_only_favorites = checked
            }
        },
        Kirigami.Action {
            text: qsTr("Edit")
            onTriggered: {
                zynqtgui.show_modal("channel_wave_editor");
            }
        }
    ]
    previousScreen: "main"
    onCurrentScreenIdRequested: {
        //don't remove modal screens
        if (zynqtgui.current_modal_screen_id.length === 0) {
            zynqtgui.current_screen_id = screenId;
        }
    }

    cuiaCallback: function(cuia) {
        let returnValue = false;
        switch (cuia) {
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
                switch (_private.selectedColumn) {
                    case 0:
                        if (component.selectedChannel.trackType === "sample-loop") {
                            pageManager.getPage("sketchpad").bottomStack.tracksBar.activateSlot("sketch", component.selectedChannel.selectedSlot.value);
                        } else {
                            pageManager.getPage("sketchpad").bottomStack.tracksBar.activateSlot("sample", component.selectedChannel.selectedSlot.value);
                        }
                        break;
                    case 1:
                        _private.selectedColumn = 2;
                        break;
                    case 2:
                        filesListView.currentItem.onClicked();
                        break;
                }
                returnValue = true;
                break;
            case "KNOB0_TOUCHED":
                switch (_private.selectedColumn) {
                    case 0:
                        if (component.selectedChannel.trackType === "sample-loop") {
                            pageManager.getPage("sketchpad").updateSelectedSketchGain(0, component.selectedChannel.selectedSlot.value);
                        } else {
                            pageManager.getPage("sketchpad").updateSelectedSampleGain(0, component.selectedChannel.selectedSlot.value);
                        }
                        break;
                    case 1:
                        break;
                    case 2:
                        break;
                }
                returnValue = true;
                break;
            case "KNOB0_RELEASED":
                returnValue = true;
                break;
            case "KNOB0_UP":
                switch (_private.selectedColumn) {
                    case 0:
                        if (component.selectedChannel.trackType === "sample-loop") {
                            pageManager.getPage("sketchpad").updateSelectedSketchGain(1, component.selectedChannel.selectedSlot.value);
                        } else {
                            pageManager.getPage("sketchpad").updateSelectedSampleGain(1, component.selectedChannel.selectedSlot.value);
                        }
                        break;
                    case 1:
                        break;
                    case 2:
                        break;
                }
                returnValue = true;
                break;
            case "KNOB0_DOWN":
                switch (_private.selectedColumn) {
                    case 0:
                        if (component.selectedChannel.trackType === "sample-loop") {
                            pageManager.getPage("sketchpad").updateSelectedSketchGain(-1, component.selectedChannel.selectedSlot.value);
                        } else {
                            pageManager.getPage("sketchpad").updateSelectedSampleGain(-1, component.selectedChannel.selectedSlot.value);
                        }
                        break;
                    case 1:
                        break;
                    case 2:
                        break;
                }
                returnValue = true;
                break;
            case "SELECT_DOWN":
            case "KNOB3_UP":
                switch (_private.selectedColumn) {
                    case 0:
                        if (component.selectedChannel.trackType === "sample-loop") {
                            pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sketch", Math.min(Zynthbox.Plugin.sketchpadSlotCount - 1, component.selectedChannel.selectedSlot.value + 1));
                        } else {
                            pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sample", Math.min(Zynthbox.Plugin.sketchpadSlotCount - 1, component.selectedChannel.selectedSlot.value + 1));
                        }
                        break;
                    case 1:
                        folderListView.currentIndex = Math.min(folderListView.count - 1, folderListView.currentIndex + 1);
                        break;
                    case 2:
                        filesListView.currentIndex = Math.min(filesListView.count - 1, filesListView.currentIndex + 1);
                        break;
                }
                returnValue = true;
                break;
            case "SELECT_UP":
            case "KNOB3_DOWN":
                switch (_private.selectedColumn) {
                    case 0:
                        if (component.selectedChannel.trackType === "sample-loop") {
                            pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sketch", Math.max(0, component.selectedChannel.selectedSlot.value - 1));
                        } else {
                            pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sample", Math.max(0, component.selectedChannel.selectedSlot.value - 1));
                        }
                        break;
                    case 1:
                        folderListView.currentIndex = Math.max(0, folderListView.currentIndex - 1);
                        break;
                    case 2:
                        filesListView.currentIndex = Math.max(0, filesListView.currentIndex - 1);
                        break;
                }
                returnValue = true;
                break;
            case "NAVIGATE_LEFT":
                _private.selectedColumn = Math.max(0, _private.selectedColumn - 1);
                returnValue = true;
                break;
            case "NAVIGATE_RIGHT":
                if (_private.selectedColumn == 2) {
                    // Then we just kind of... use this as a "play" button style thing for testing samples (toggle the preview playback for whatever is currently selected)
                    if (filesListView.currentIndex > -1) {
                        filesListView.currentItem.doPreview();
                    }
                } else {
                    _private.selectedColumn = Math.min(_private.maxColumn, _private.selectedColumn + 1);
                }
                returnValue = true;
                break;
        }
        return returnValue;
    }

    QtObject {
        id: _private
        property int selectedColumn: 1
        readonly property int maxColumn: 2
        property QtObject filePropertiesHelper: Helpers.FilePropertiesHelper {
            filePath: "/zynthian/zynthian-my-data"
        }
    }
    Zynthian.ActionPickerPopup {
        id: sampleSlotAssigner
        objectName: ""
        rows: 5
        function assignToSlot(samplePathName) {
            sampleSlotAssigner.pathName = samplePathName;
            sampleSlotAssigner.open();
            sampleSlotAssigner.currentIndex = component.selectedChannel.selectedSlot.value;
        }
        property string pathName: ""
        actions: [
            QQC2.Action {
                property int slotIndex: 0
                text: sampleSlotAssigner.opened
                    ? (component.selectedChannel.trackType === "sample-loop" && component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).isEmpty) || component.selectedChannel.samples[slotIndex].isEmpty
                        ? qsTr("Assign To\nSlot %1").arg(slotIndex + 1)
                        : qsTr("Replace Sample\nIn Slot %1").arg(slotIndex + 1)
                    : ""
                onTriggered: {
                    if (component.selectedChannel.trackType === "sample-loop") {
                        component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).importFromFile(sampleSlotAssigner.pathName);
                    } else {
                        component.selectedChannel.set_sample(sampleSlotAssigner.pathName, slotIndex);
                    }
                }
            },
            QQC2.Action {
                property int slotIndex: 1
                text: sampleSlotAssigner.opened
                    ? (component.selectedChannel.trackType === "sample-loop" && component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).isEmpty) || component.selectedChannel.samples[slotIndex].isEmpty
                        ? qsTr("Assign To\nSlot %1").arg(slotIndex + 1)
                        : qsTr("Replace Sample\nIn Slot %1").arg(slotIndex + 1)
                    : ""
                onTriggered: {
                    if (component.selectedChannel.trackType === "sample-loop") {
                        component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).importFromFile(sampleSlotAssigner.pathName);
                    } else {
                        component.selectedChannel.set_sample(sampleSlotAssigner.pathName, slotIndex);
                    }
                }
            },
            QQC2.Action {
                property int slotIndex: 2
                text: sampleSlotAssigner.opened
                    ? (component.selectedChannel.trackType === "sample-loop" && component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).isEmpty) || component.selectedChannel.samples[slotIndex].isEmpty
                        ? qsTr("Assign To\nSlot %1").arg(slotIndex + 1)
                        : qsTr("Replace Sample\nIn Slot %1").arg(slotIndex + 1)
                    : ""
                onTriggered: {
                    if (component.selectedChannel.trackType === "sample-loop") {
                        component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).importFromFile(sampleSlotAssigner.pathName);
                    } else {
                        component.selectedChannel.set_sample(sampleSlotAssigner.pathName, slotIndex);
                    }
                }
            },
            QQC2.Action {
                property int slotIndex: 3
                text: sampleSlotAssigner.opened
                    ? (component.selectedChannel.trackType === "sample-loop" && component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).isEmpty) || component.selectedChannel.samples[slotIndex].isEmpty
                        ? qsTr("Assign To\nSlot %1").arg(slotIndex + 1)
                        : qsTr("Replace Sample\nIn Slot %1").arg(slotIndex + 1)
                    : ""
                onTriggered: {
                    if (component.selectedChannel.trackType === "sample-loop") {
                        component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).importFromFile(sampleSlotAssigner.pathName);
                    } else {
                        component.selectedChannel.set_sample(sampleSlotAssigner.pathName, slotIndex);
                    }
                }
            },
            QQC2.Action {
                property int slotIndex: 4
                text: sampleSlotAssigner.opened
                    ? (component.selectedChannel.trackType === "sample-loop" && component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).isEmpty) || component.selectedChannel.samples[slotIndex].isEmpty
                        ? qsTr("Assign To\nSlot %1").arg(slotIndex + 1)
                        : qsTr("Replace Sample\nIn Slot %1").arg(slotIndex + 1)
                    : ""
                onTriggered: {
                    if (component.selectedChannel.trackType === "sample-loop") {
                        component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).importFromFile(sampleSlotAssigner.pathName);
                    } else {
                        component.selectedChannel.set_sample(sampleSlotAssigner.pathName, slotIndex);
                    }
                }
            }
        ]
    }
    contentItem: ColumnLayout {
        id: layout
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit
            spacing: Kirigami.Units.gridUnit
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                visible: component.selectedChannel && component.selectedChannel.trackType !== "sample-loop"
                onClicked: {
                    applicationWindow().libraryTypePicker.open();
                }
                contentItem: Kirigami.Heading {
                    level: 2
                    text: component.selectedChannel
                        ? qsTr("Track %1 Samples").arg(zynqtgui.sketchpad.selectedTrackId+1)
                        : ""
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                visible: component.selectedChannel && component.selectedChannel.trackType === "sample-loop"
                onClicked: {
                    applicationWindow().libraryTypePicker.open();
                }
                contentItem: Kirigami.Heading {
                    level: 2
                    text: component.selectedChannel
                        ? qsTr("Track %1 Loops").arg(zynqtgui.sketchpad.selectedTrackId+1)
                        : ""
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                }
            }
            Kirigami.Heading {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                level: 2
                text: qsTr("Folders")
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
            }
            Kirigami.Heading {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                level: 2
                text: qsTr("Samples In Folder")
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 14
            spacing: Kirigami.Units.gridUnit
            Zynthian.Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                highlighted: _private.selectedColumn === 0
                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.smallSpacing
                    }
                    Repeater {
                        model: Zynthbox.Plugin.sketchpadSlotCount
                        delegate: Zynthian.Card {
                            id: clipDelegate
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            highlighted: component.selectedChannel && model.index === component.selectedChannel.selectedSlot.value
                            property QtObject clip: component.selectedChannel
                                ? component.selectedChannel.trackType === "sample-loop"
                                    ? component.selectedChannel.getClipsModelById(index).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                                    : component.selectedChannel.samples[index]
                                : null
                            property QtObject cppClipObject: clipDelegate.clip && clipDelegate.clip.hasOwnProperty("cppObjId")
                                ? Zynthbox.PlayGridManager.getClipById(clipDelegate.clip.cppObjId)
                                : null
                            property bool clipHasWav: clipDelegate.clip && !clipDelegate.clip.isEmpty
                            contentItem: Item {
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (component.selectedChannel.selectedSlot.value === model.index) {
                                            if (component.selectedChannel.trackType === "sample-loop") {
                                                pageManager.getPage("sketchpad").bottomStack.tracksBar.activateSlot("sketch", component.selectedChannel.selectedSlot.value);
                                            } else {
                                                pageManager.getPage("sketchpad").bottomStack.tracksBar.activateSlot("sample", component.selectedChannel.selectedSlot.value);
                                            }
                                        } else {
                                            if (component.selectedChannel.trackType === "sample-loop") {
                                                pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sketch", model.index, false);
                                            } else {
                                                pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sample", model.index, false);
                                            }
                                            if (clipDelegate.clip.metadata.originalPath != "") {
                                                filesListView.selectFile(clipDelegate.clip.metadata.originalPath);
                                            }
                                        }
                                    }
                                }
                                ColumnLayout {
                                    anchors.fill: parent
                                    RowLayout {
                                        QQC2.Label {
                                            id: mainLabel
                                            Layout.fillWidth: true
                                            text: "%1 - %2".arg(model.index + 1).arg(clipDelegate.clipHasWav ? clipDelegate.clip.path.split("/").pop() : qsTr("Empty Slot"))
                                            elide: Text.ElideMiddle
                                        }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: "#222222"
                                        border.width: 1
                                        border.color: "#ff999999"
                                        radius: 4
                                        Zynthbox.WaveFormItem {
                                            id: waveformItem
                                            anchors {
                                                fill: parent
                                                margins: 1
                                            }
                                            color: Kirigami.Theme.textColor
                                            source: clipDelegate.cppClipObject ? "clip:/%1".arg(clipDelegate.cppClipObject.id) : ""
                                            start: clipDelegate.cppClipObject ? clipDelegate.cppClipObject.selectedSliceObject.startPositionSeconds : 0
                                            end: clipDelegate.cppClipObject ? clipDelegate.cppClipObject.selectedSliceObject.startPositionSeconds + clipDelegate.cppClipObject.selectedSliceObject.lengthSeconds : 0
                                            readonly property real relativeStart: waveformItem.start / waveformItem.length
                                            readonly property real relativeEnd: waveformItem.end / waveformItem.length
                                            visible: clipDelegate.clipHasWav
                                            // SamplerSynth progress dots
                                            Timer {
                                                id: dotFetcher
                                                interval: 1; repeat: false; running: false;
                                                onTriggered: {
                                                    progressDots.playbackPositions = component.visible && clipDelegate.cppClipObject
                                                        ? clipDelegate.cppClipObject.playbackPositions
                                                        : null
                                                }
                                            }
                                            Connections {
                                                target: component
                                                onVisibleChanged: dotFetcher.restart();
                                            }
                                            Connections {
                                                target: component.selectedChannel
                                                onTrack_type_changed: dotFetcher.restart();
                                            }
                                            Connections {
                                                target: clipDelegate
                                                onCppClipObjectChanged: dotFetcher.restart();
                                            }
                                            Repeater {
                                                id: progressDots
                                                model: Zynthbox.Plugin.clipMaximumPositionCount
                                                property QtObject playbackPositions: null
                                                delegate: Item {
                                                    property QtObject progressEntry: progressDots.playbackPositions ? progressDots.playbackPositions.positions[model.index] : null
                                                    visible: progressEntry && progressEntry.id > -1
                                                    Rectangle {
                                                        anchors.centerIn: parent
                                                        rotation: 45
                                                        color: Kirigami.Theme.highlightColor
                                                        width: Kirigami.Units.largeSpacing
                                                        height:  Kirigami.Units.largeSpacing
                                                        scale: progressEntry ? 0.5 + progressEntry.gain : 1
                                                    }
                                                    anchors {
                                                        top: parent.verticalCenter
                                                        topMargin: progressEntry ? progressEntry.pan * (parent.height / 2) : 0
                                                    }
                                                    x: visible ? Math.floor(Zynthian.CommonUtils.fitInWindow(progressEntry.progress, waveformItem.relativeStart, waveformItem.relativeEnd) * parent.width) : 0
                                                }
                                            }
                                        }
                                        Rectangle {
                                            anchors {
                                                left: parent.left
                                                bottom: parent.bottom
                                            }
                                            width: clipDelegate.cppClipObject ? parent.width * clipDelegate.cppClipObject.selectedSliceObject.gainHandler.gainAbsolute : 0
                                            height: Kirigami.Units.gridUnit * 0.5
                                            color: Kirigami.Theme.highlightColor
                                            opacity: 0.7
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Zynthian.Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                highlighted: _private.selectedColumn === 1
                ListView {
                    id: folderListView
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.smallSpacing
                    }
                    model: component.selectedChannel && component.selectedChannel.trackType === "sample-loop"
                        ? _private.filePropertiesHelper.getOnlySubdirectoryList("/zynthian/zynthian-my-data/sketches")
                        : _private.filePropertiesHelper.getOnlySubdirectoryList("/zynthian/zynthian-my-data/samples")
                    onModelChanged: {
                        currentIndex = 0;
                    }
                    onCurrentItemChanged: {
                        if (folderListView.currentItem) {
                            folderModel.folder = folderListView.currentItem.folder;
                        }
                    }
                    delegate: Zynthian.BasicDelegate {
                        id: folderDelegate
                        width: ListView.view.width
                        height: Kirigami.Units.iconSizes.large
                        text: modelData.subpath
                        readonly property string folder: modelData.path
                        onClicked: {
                            if (_private.selectedColumn != 1) {
                                _private.selectedColumn = 1;
                            }
                            folderListView.currentIndex = model.index;
                        }
                        contentItem: RowLayout {
                            Layout.fillWidth: true
                            Item {
                                Layout.fillHeight: true
                                Layout.minimumWidth: height
                                Layout.maximumWidth: height
                                Kirigami.Icon {
                                    anchors {
                                        fill: parent
                                        margins: Kirigami.Units.smallSpacing
                                    }
                                    source: "file-library-symbolic"
                                }
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: folderDelegate.text
                                elide: Text.ElideLeft
                            }
                        }
                    }
                }
            }
            Zynthian.Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                highlighted: _private.selectedColumn === 2
                ListView {
                    id: filesListView
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.smallSpacing
                    }
                    clip: true
                    highlightMoveDuration: 0
                    highlightMoveVelocity: 0
                    function selectFile(theFile) {
                        let pathSplit = theFile.lastIndexOf("/");
                        let path = theFile.slice(0, pathSplit);
                        let filename = theFile.slice(pathSplit + 1);
                        // Select the folder in the middle column, if it exists
                        for (let index = 0; index < folderListView.model.length; ++index) {
                            if (folderListView.model[index].path == path) {
                                folderListView.currentIndex = index;
                                break;
                            }
                        }
                        // Force set the folder to the new path, and then start the timer for re-selecting
                        // Yes, i realise we *could* wait for the signal to fire, but if it fires too rapidly,
                        // we would miss it, and this is safer... not that i like it all that much
                        folderModel.folder = path;
                        selectFileAfterLoadingTimer.selectThisFile = Qt.resolvedUrl(theFile);
                        selectFileAfterLoadingTimer.start();
                    }
                    Timer {
                        id: selectFileAfterLoadingTimer
                        property string selectThisFile: ""
                        interval: 50; repeat: true; running: false;
                        onTriggered: {
                            if (selectThisFile === "") {
                                selectFileAfterLoadingTimer.stop();
                            } else if (folderModel.status == FolderListModel.Ready) {
                                selectFileAfterLoadingTimer.stop();
                                // Now the data's loaded, select the file in the right hand column, if it exists
                                let indexOfFile = folderModel.indexOf(selectFileAfterLoadingTimer.selectThisFile);
                                if (indexOfFile > -1) {
                                    // Select the right-hand column if the file did exist, otherwise just leave the middle column selected
                                    _private.selectedColumn = 2;
                                    filesListView.currentIndex = indexOfFile;
                                    filesListView.positionViewAtIndex(filesListView.currentIndex, ListView.Center)
                                }
                            }
                        }
                    }
                    model: FolderListModel {
                        id: folderModel
                        caseSensitive: false
                        showDirs: false
                        showDotAndDotDot: false
                        sortCaseSensitive: false
                        nameFilters: [ "*.wav" ]
                        folder: "/zynthian/zynthian-my-data"
                        onStatusChanged: {
                            if (folderModel.status == FolderListModel.Ready) {
                                if (folderModel.count === 0) {
                                    filesListView.currentIndex = -1;
                                } else {
                                    filesListView.currentIndex = 0;
                                }
                            }
                        }
                    }
                    delegate: Zynthian.BasicDelegate {
                        id: fileDelegate
                        width: ListView.view.width
                        height: Kirigami.Units.iconSizes.large
                        text: model.fileName
                        readonly property bool previewIsPlayingForThisEntry: (_private.filePropertiesHelper.previewClip && _private.filePropertiesHelper.previewClip.isPlaying && _private.filePropertiesHelper.filePath == model.filePath) ? true : false
                        function doPreview() {
                            if (fileDelegate.previewIsPlayingForThisEntry) {
                                _private.filePropertiesHelper.stopPreview();
                            } else {
                                if (_private.filePropertiesHelper.previewClip && _private.filePropertiesHelper.previewClip.isPlaying) {
                                    // In this case it's playing for something else, so we need to stop that first before we switch to playing for us...
                                    _private.filePropertiesHelper.stopPreview();
                                }
                                if (_private.selectedColumn != 2) {
                                    _private.selectedColumn = 2;
                                }
                                if (filesListView.currentIndex != model.index) {
                                    filesListView.currentIndex = model.index;
                                }
                                _private.filePropertiesHelper.filePath = model.filePath;
                                _private.filePropertiesHelper.playPreview();
                            }
                        }
                        onClicked: {
                            if (_private.selectedColumn != 2) {
                                _private.selectedColumn = 2;
                            }
                            if (filesListView.currentIndex != model.index) {
                                filesListView.currentIndex = model.index;
                            } else {
                                sampleSlotAssigner.assignToSlot(model.filePath);
                            }
                        }
                        contentItem: ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            RowLayout {
                                spacing: 0
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Item {
                                    Layout.fillHeight: true
                                    Layout.minimumWidth: height
                                    Layout.maximumWidth: height
                                    Kirigami.Icon {
                                        anchors {
                                            fill: parent
                                            margins: Kirigami.Units.smallSpacing
                                        }
                                        source: "folder-music-symbolic"
                                    }
                                }
                                QQC2.Label {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: fileDelegate.text
                                    fontSizeMode: Text.Fit
                                    minimumPointSize: 5
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }
                                Item {
                                    Layout.fillHeight: true
                                    Layout.minimumWidth: height
                                    Layout.maximumWidth: height
                                    Kirigami.Icon {
                                        anchors {
                                            fill: parent
                                            margins: Kirigami.Units.smallSpacing
                                        }
                                        source: fileDelegate.previewIsPlayingForThisEntry ? "media-playback-stop" : "media-playback-start"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            fileDelegate.doPreview();
                                        }
                                    }
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.minimumHeight: 1
                                Layout.maximumHeight: 1
                                Rectangle {
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        bottom: parent.bottom
                                    }
                                    width: fileDelegate.previewIsPlayingForThisEntry ? parent.width * (_private.filePropertiesHelper.previewClip.position) : 0
                                    color: Kirigami.Theme.textColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
