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
                        folderListView.currentIndex = Math.max(-1, folderListView.currentIndex - 1);
                        break;
                    case 2:
                        filesListView.currentIndex = Math.max(-1, filesListView.currentIndex - 1);
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
    contentItem: ColumnLayout {
        id: layout
        spacing: Kirigami.Units.gridUnit

        RowLayout {
            Layout.fillWidth: true
            Kirigami.Heading {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                level: 2
                text: qsTr("Track %1 Samples").arg(zynqtgui.sketchpad.selectedTrackId+1)
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.bottom
                    }
                    height: Kirigami.Units.smallSpacing
                    visible: _private.selectedColumn === 0
                    color: parent.color
                }
            }
            Kirigami.Heading {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                level: 2
                text: qsTr("Folders")
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.bottom
                    }
                    height: Kirigami.Units.smallSpacing
                    visible: _private.selectedColumn === 1
                    color: parent.color
                }
            }
            Kirigami.Heading {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                level: 2
                text: qsTr("Samples In Folder")
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.bottom
                    }
                    height: Kirigami.Units.smallSpacing
                    visible: _private.selectedColumn === 2
                    color: parent.color
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Zynthian.Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                ColumnLayout {
                    anchors.fill: parent
                    Repeater {
                        model: Zynthbox.Plugin.sketchpadSlotCount
                        delegate: Zynthian.BasicDelegate {
                            id: clipDelegate
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            onClicked: {
                                if (component.selectedChannel.trackType === "sample-loop") {
                                    pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sketch", model.index);
                                } else {
                                    pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sample", model.index);
                                }
                            }
                            checked: index === zynqtgui.sketchpad.lastSelectedObj.value
                            property QtObject clip: component.selectedChannel
                                ? component.selectedChannel.trackType === "sample-loop"
                                    ? component.selectedChannel.getClipsModelById(index).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                                    : component.selectedChannel.samples[index]
                                : null
                            property QtObject cppClipObject: clipDelegate.clip && clipDelegate.clip.hasOwnProperty("cppObjId")
                                ? Zynthbox.PlayGridManager.getClipById(clipDelegate.clip.cppObjId)
                                : null
                            property bool clipHasWav: clipDelegate.clip && !clipDelegate.isEmpty
                            contentItem: ColumnLayout {
                                RowLayout {
                                    QQC2.Label {
                                        id: mainLabel
                                        Layout.fillWidth: true
                                        text: clipDelegate.clipHasWav ? clipDelegate.clip.path.split("/").pop() : ""
                                        elide: Text.ElideRight
                                    }
                                }
                                Zynthbox.WaveFormItem {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: Kirigami.Theme.textColor
                                    source: clipDelegate.cppClipObject ? "clip:/%1".arg(clipDelegate.cppClipObject.id) : ""
                                    start: clipDelegate.cppClipObject ? clipDelegate.cppClipObject.selectedSliceObject.startPositionSeconds : 0
                                    end: clipDelegate.cppClipObject ? clipDelegate.cppClipObject.selectedSliceObject.startPositionSeconds + clipDelegate.cppClipObject.selectedSliceObject.lengthSeconds : 0
                                    visible: clipDelegate.clipHasWav
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
                ListView {
                    id: folderListView
                    anchors.fill: parent
                    model: component.selectedChannel && component.selectedChannel.trackType === "sample-loop"
                        ? _private.filePropertiesHelper.getSubdirectoryList("/zynthian/zynthian-my-data/sketches")
                        : _private.filePropertiesHelper.getSubdirectoryList("/zynthian/zynthian-my-data/samples")
                    onModelChanged: {
                        currentIndex = 1;
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
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
            Zynthian.Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                ListView {
                    id: filesListView
                    anchors.fill: parent
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
                            filesListView.currentIndex = model.index;
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
                                    source: "folder-music-symbolic"
                                }
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: folderDelegate.text
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
