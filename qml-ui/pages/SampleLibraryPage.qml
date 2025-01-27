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
                            pageManager.getPage("sketchpad").bottomStack.tracksBar.activateSlot("sketch", zynqtgui.sketchpad.lastSelectedObj.value);
                        } else {
                            pageManager.getPage("sketchpad").bottomStack.tracksBar.activateSlot("sample", zynqtgui.sketchpad.lastSelectedObj.value);
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
            case "SELECT_DOWN":
            case "KNOB3_UP":
                switch (_private.selectedColumn) {
                    case 0:
                        if (component.selectedChannel.trackType === "sample-loop") {
                            pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sketch", Math.min(Zynthbox.Plugin.sketchpadSlotCount - 1, zynqtgui.sketchpad.lastSelectedObj.value + 1));
                        } else {
                            pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sample", Math.min(Zynthbox.Plugin.sketchpadSlotCount - 1, zynqtgui.sketchpad.lastSelectedObj.value + 1));
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
                            pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sketch", Math.max(0, zynqtgui.sketchpad.lastSelectedObj.value - 1));
                        } else {
                            pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sample", Math.max(0, zynqtgui.sketchpad.lastSelectedObj.value - 1));
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
                _private.selectedColumn = Math.min(_private.maxColumn, _private.selectedColumn + 1);
                returnValue = true;
                break;
        }
        return returnValue;
    }

    QtObject {
        id: _private
        property int selectedColumn: 0
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
            sampleSlotAssigner.currentIndex = zynqtgui.sketchpad.lastSelectedObj.value;
        }
        property string pathName: ""
        property QtObject sketch: component.selectedChannel.getClipsModelById(component.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
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
                        component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).path = sampleSlotAssigner.pathName;
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
                        component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).path = sampleSlotAssigner.pathName;
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
                        component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).path = sampleSlotAssigner.pathName;
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
                        component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).path = sampleSlotAssigner.pathName;
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
                        component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).path = sampleSlotAssigner.pathName;
                    } else {
                        component.selectedChannel.set_sample(sampleSlotAssigner.pathName, slotIndex);
                    }
                }
            }
        ]
    }
    contentItem: ColumnLayout {
        id: layout
        spacing: Kirigami.Units.gridUnit

        RowLayout {
            Layout.fillWidth: true
            Kirigami.Heading {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                level: 2
                text: component.selectedChannel
                                ? component.selectedChannel.trackType === "sample-loop"
                                    ? qsTr("Track %1 Sketches").arg(zynqtgui.sketchpad.selectedTrackId+1)
                                    : qsTr("Track %1 Samples").arg(zynqtgui.sketchpad.selectedTrackId+1)
                                : ""
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
            }
            Kirigami.Heading {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                level: 2
                text: qsTr("Folders")
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
            }
            Kirigami.Heading {
                Layout.fillWidth: true
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
                            highlighted: model.index === zynqtgui.sketchpad.lastSelectedObj.value
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
                                        if (zynqtgui.sketchpad.lastSelectedObj.value === model.index) {
                                            if (component.selectedChannel.trackType === "sample-loop") {
                                                pageManager.getPage("sketchpad").bottomStack.tracksBar.activateSlot("sketch", zynqtgui.sketchpad.lastSelectedObj.value);
                                            } else {
                                                pageManager.getPage("sketchpad").bottomStack.tracksBar.activateSlot("sample", zynqtgui.sketchpad.lastSelectedObj.value);
                                            }
                                        } else {
                                            if (component.selectedChannel.trackType === "sample-loop") {
                                                pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sketch", model.index);
                                            } else {
                                                pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sample", model.index);
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
                                            elide: Text.ElideRight
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
                                            anchors {
                                                fill: parent
                                                margins: 1
                                            }
                                            color: Kirigami.Theme.textColor
                                            source: clipDelegate.cppClipObject ? "clip:/%1".arg(clipDelegate.cppClipObject.id) : ""
                                            start: clipDelegate.cppClipObject ? clipDelegate.cppClipObject.selectedSliceObject.startPositionSeconds : 0
                                            end: clipDelegate.cppClipObject ? clipDelegate.cppClipObject.selectedSliceObject.startPositionSeconds + clipDelegate.cppClipObject.selectedSliceObject.lengthSeconds : 0
                                            visible: clipDelegate.clipHasWav
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
                        id: folderDelegate
                        width: ListView.view.width
                        height: Kirigami.Units.iconSizes.large
                        text: model.fileName
                        onClicked: {
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
                                    text: folderDelegate.text
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
                                        source: _private.filePropertiesHelper.previewClip && _private.filePropertiesHelper.previewClip.isPlaying ? "media-playback-stop" : "media-playback-start"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (_private.filePropertiesHelper.previewClip && _private.filePropertiesHelper.previewClip.isPlaying) {
                                                _private.filePropertiesHelper.stopPreview();
                                            } else {
                                                _private.filePropertiesHelper.filePath = model.filePath;
                                                _private.filePropertiesHelper.playPreview();
                                            }
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
                                    width: _private.filePropertiesHelper.previewClip ? parent.width * (_private.filePropertiesHelper.previewClip.position) : 0
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
