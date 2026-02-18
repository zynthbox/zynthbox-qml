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

import io.zynthbox.ui 1.0 as ZUI

import io.zynthbox.components 1.0 as Zynthbox

ZUI.ScreenPage {
    id: component

    background: Rectangle 
    {
        color: Kirigami.Theme.backgroundColor
        opacity: 0.4
    }

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
                        filesListView.selectFile(selectedClip.metadata.originalPath, true);
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
            text: qsTr("Load Sound")
            onTriggered: {
                zynqtgui.show_screen("sound_categories")
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
        switch (_private.selectedColumn) {
            case 0:
                returnValue = clipsListView.cuiaCallback(cuia);
                break;
            case 1:
                returnValue = folderListView.cuiaCallback(cuia);
                break;
            case 2:
                returnValue = filesListView.cuiaCallback(cuia);
                break;
            default:
                break;
        }
        if (returnValue === false) {
            switch (cuia) {
                case "SCREEN_LAYER":
                case "SCREEN_PRESET":
                    // Switch to Sounds page when library page is open and F2 is pressed again
                    zynqtgui.show_screen("sound_categories")
                    returnValue = true;
                    break;
                case "SWITCH_SELECT_RELEASED":
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
                    if (component.selectedChannel.trackType === "sample-loop") {
                        pageManager.getPage("sketchpad").updateSelectedSketchGain(0, component.selectedChannel.selectedSlot.value);
                    } else {
                        pageManager.getPage("sketchpad").updateSelectedSampleGain(0, component.selectedChannel.selectedSlot.value);
                    }
                    returnValue = true;
                    break;
                case "KNOB0_RELEASED":
                    returnValue = true;
                    break;
                case "KNOB0_UP":
                    if (component.selectedChannel.trackType === "sample-loop") {
                        pageManager.getPage("sketchpad").updateSelectedSketchGain(1, component.selectedChannel.selectedSlot.value);
                    } else {
                        pageManager.getPage("sketchpad").updateSelectedSampleGain(1, component.selectedChannel.selectedSlot.value);
                    }
                    returnValue = true;
                    break;
                case "KNOB0_DOWN":
                    if (component.selectedChannel.trackType === "sample-loop") {
                        pageManager.getPage("sketchpad").updateSelectedSketchGain(-1, component.selectedChannel.selectedSlot.value);
                    } else {
                        pageManager.getPage("sketchpad").updateSelectedSampleGain(-1, component.selectedChannel.selectedSlot.value);
                    }
                    returnValue = true;
                    break;
                case "SWITCH_ARROW_LEFT_RELEASED":
                    _private.selectedColumn = Math.max(0, _private.selectedColumn - 1);
                    returnValue = true;
                    break;
                case "SWITCH_ARROW_RIGHT_RELEASED":
                    if (_private.selectedColumn == 2) {
                        // Then we just kind of... use this as a "play" button style thing for testing samples (toggle the preview playback for whatever is currently selected)
                        if (filesListView.selector.current_index > -1) {
                            filesListView.currentItem.doPreview();
                        }
                    } else {
                        _private.selectedColumn = Math.min(_private.maxColumn, _private.selectedColumn + 1);
                    }
                    returnValue = true;
                    break;
            }
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
    ZUI.ActionPickerPopup {
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
                    ? (component.selectedChannel.trackType === "sample-loop" && component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).isEmpty) || (component.selectedChannel.trackType !== "sample-loop" && component.selectedChannel.samples[slotIndex].isEmpty)
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
                    ? (component.selectedChannel.trackType === "sample-loop" && component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).isEmpty) || (component.selectedChannel.trackType !== "sample-loop" && component.selectedChannel.samples[slotIndex].isEmpty)
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
                    ? (component.selectedChannel.trackType === "sample-loop" && component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).isEmpty) || (component.selectedChannel.trackType !== "sample-loop" && component.selectedChannel.samples[slotIndex].isEmpty)
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
                    ? (component.selectedChannel.trackType === "sample-loop" && component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).isEmpty) || (component.selectedChannel.trackType !== "sample-loop" && component.selectedChannel.samples[slotIndex].isEmpty)
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
                    ? (component.selectedChannel.trackType === "sample-loop" && component.selectedChannel.getClipsModelById(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex).isEmpty) || (component.selectedChannel.trackType !== "sample-loop" && component.selectedChannel.samples[slotIndex].isEmpty)
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
            Kirigami.Action {
                property int slotIndex: 5
                visible: component.selectedChannel && component.selectedChannel.trackType === "sample-trig"
                text: sampleSlotAssigner.opened
                    ? component.selectedChannel.samples[slotIndex].isEmpty
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
            Kirigami.Action {
                property int slotIndex: 6
                visible: component.selectedChannel && component.selectedChannel.trackType === "sample-trig"
                text: sampleSlotAssigner.opened
                    ? component.selectedChannel.samples[slotIndex].isEmpty
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
            Kirigami.Action {
                property int slotIndex: 7
                visible: component.selectedChannel && component.selectedChannel.trackType === "sample-trig"
                text: sampleSlotAssigner.opened
                    ? component.selectedChannel.samples[slotIndex].isEmpty
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
            Kirigami.Action {
                property int slotIndex: 8
                visible: component.selectedChannel && component.selectedChannel.trackType === "sample-trig"
                text: sampleSlotAssigner.opened
                    ? component.selectedChannel.samples[slotIndex].isEmpty
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
            Kirigami.Action {
                property int slotIndex: 9
                visible: component.selectedChannel && component.selectedChannel.trackType === "sample-trig"
                text: sampleSlotAssigner.opened
                    ? component.selectedChannel.samples[slotIndex].isEmpty
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
    contentItem: Item {
        RowLayout {
            id: layout

            anchors.fill: parent
            spacing: Kirigami.Units.gridUnit

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent
                    ZUI.LibraryPagePicker {
                        id: libraryPagePicker
                        Layout.fillWidth: true
                        libraryName: "samples"
                        selectedChannel: component.selectedChannel
                    }
                    ZUI.SelectorView {
                        id: clipsListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                        highlighted: _private.selectedColumn === 0
                        // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                        active: zynqtgui.isBootingComplete
                        autoActivateIndexOnChange: true
                        qmlSelector: ZUI.SelectorWrapper {
                            selector_list: component.selectedChannel && component.selectedChannel.trackType === "sample-trig" ? 2 * Zynthbox.Plugin.sketchpadSlotCount : Zynthbox.Plugin.sketchpadSlotCount
                            current_index: component.selectedChannel && component.selectedChannel.selectedSlot && clipsListView.view.count > 0 ? (component.selectedChannel.selectedSlot.className === "TracksBar_sampleslot" ? component.selectedChannel.selectedSlot.value : component.selectedChannel.selectedSlot.value + Zynthbox.Plugin.sketchpadSlotCount) : -1
                        }
                        onCurrentItemChanged: {
                            if (currentItem && currentItem.clip.metadata.originalPath != "") {
                                filesListView.selectFile(currentItem.clip.metadata.originalPath, false);
                            }
                        }
                        onItemActivated: {
                            if (_private.selectedColumn != 0) {
                                _private.selectedColumn = 0;
                            }
                            qmlSelector.current_index = index;
                            if (component.selectedChannel.selectedSlot.value === index) {
                                if (component.selectedChannel.trackType === "sample-loop") {
                                    pageManager.getPage("sketchpad").bottomStack.tracksBar.activateSlot("sketch", component.selectedChannel.selectedSlot.value);
                                } else {
                                    pageManager.getPage("sketchpad").bottomStack.tracksBar.activateSlot("sample", component.selectedChannel.selectedSlot.value);
                                }
                            } else {
                                if (component.selectedChannel.trackType === "sample-loop") {
                                    pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sketch", index, false);
                                } else {
                                    pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("sample", index, false);
                                }
                            }
                        }
                        delegate: ZUI.SelectorDelegate {
                            id: clipDelegate
                            height: component.selectedChannel && component.selectedChannel.trackType === "sample-trig" ? clipsListView.view.height/10 : clipsListView.view.height/5
                            enabled: true
                            // highlighted: component.selectedChannel && model.index === component.selectedChannel.selectedSlot.value
                            property QtObject clip: component.selectedChannel
                                ? component.selectedChannel.trackType === "sample-loop"
                                    ? component.selectedChannel.getClipsModelById(index).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                                    : component.selectedChannel.samples[index]
                                : null
                            property QtObject cppClipObject: clipDelegate.clip && clipDelegate.clip.hasOwnProperty("cppObjId")
                                ? Zynthbox.PlayGridManager.getClipById(clipDelegate.clip.cppObjId)
                                : null
                            property bool clipHasWav: clipDelegate.clip && !clipDelegate.clip.isEmpty
                            selector: clipsListView.selector
                            onItemActivated: clipsListView.itemActivated(screenId, index)
                            onItemActivatedSecondary: clipsListView.itemActivatedSecondary(screenId, index)
                            contentItem: ColumnLayout {
                                RowLayout {
                                    QQC2.Label {
                                        id: mainLabel
                                        Layout.fillWidth: true
                                        text: "%1 - %2".arg(model.index + 1).arg(clipDelegate.clipHasWav ? clipDelegate.clip.path.split("/").pop() : qsTr("-"))
                                        elide: Text.ElideMiddle
                                    }
                                }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Rectangle {
                                        anchors.fill: parent
                                        color: "#222222"
                                        border.width: 1
                                        border.color: "#ff999999"
                                        radius: 4
                                        visible: waveformItem.visible
                                    }
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
                                                x: visible ? Math.floor(ZUI.CommonUtils.fitInWindow(progressEntry.progress, waveformItem.relativeStart, waveformItem.relativeEnd) * parent.width) : 0
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

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumHeight: libraryPagePicker.height
                        Layout.maximumHeight: libraryPagePicker.height
                        spacing: Kirigami.Units.gridUnit
                        Kirigami.Heading {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            level: 2
                            text: qsTr("Folders")
                            Kirigami.Theme.inherit: false
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                        }
                        // The header items want to be rowlayouts, so we can add buttons in later, should we want to
                    }
                    ZUI.SelectorView {
                        id: folderListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                        highlighted: _private.selectedColumn === 1
                        onCurrentItemChanged: {
                            if (folderListView.currentItem) {
                                folderModel.folder = encodeURIComponent(folderListView.currentItem.folder);
                            }
                        }
                        // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                        active: zynqtgui.isBootingComplete
                        autoActivateIndexOnChange: true
                        onItemActivated: {
                            if (_private.selectedColumn != 1) {
                                _private.selectedColumn = 1;
                            }
                            qmlSelector.current_index = index;
                        }
                        qmlSelector: ZUI.SelectorWrapper {
                            selector_list: component.selectedChannel && component.selectedChannel.trackType === "sample-loop"
                                ? _private.filePropertiesHelper.getOnlySubdirectoriesList(["/zynthian/zynthian-my-data/sketches", "/zynthian/zynthian-my-data/samples"])
                                : _private.filePropertiesHelper.getOnlySubdirectoriesList(["/zynthian/zynthian-my-data/samples", "/zynthian/zynthian-my-data/sketches"])
                            onSelector_listChanged: {
                                current_index = 0;
                            }
                        }
                        delegate: ZUI.SelectorDelegate {
                            id: folderDelegate
                            width: ListView.view.width
                            height: Kirigami.Units.iconSizes.medium
                            enabled: true
                            text: modelData.subpath
                            readonly property string folder: modelData.path
                            selector: folderListView.selector
                            onItemActivated: folderListView.itemActivated(screenId, index)
                            onItemActivatedSecondary: folderListView.itemActivatedSecondary(screenId, index)
                            contentItem: RowLayout {
                                Item {
                                    Layout.fillHeight: true
                                    Layout.minimumWidth: height
                                    Layout.maximumWidth: height
                                    Kirigami.Icon {                                
                                        anchors.centerIn: parent
                                        implicitHeight: 22
                                        implicitWidth: 22
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
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumHeight: libraryPagePicker.height
                        Layout.maximumHeight: libraryPagePicker.height
                        spacing: Kirigami.Units.gridUnit
                        Kirigami.Heading {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            level: 2
                            text: qsTr("Samples In Folder")
                            Kirigami.Theme.inherit: false
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                        }
                    }
                    ZUI.SelectorView {
                        id: filesListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                        highlighted: _private.selectedColumn === 2
                        function selectFile(theFile, changeColumn) {
                            let pathSplit = theFile.lastIndexOf("/");
                            let path = theFile.slice(0, pathSplit);
                            let filename = theFile.slice(pathSplit + 1);
                            // Select the folder in the middle column, if it exists
                            for (let index = 0; index < folderListView.model.length; ++index) {
                                if (folderListView.model[index].path == path) {
                                    folderListView.qmlSelector.current_index = index;
                                    break;
                                }
                            }
                            // Force set the folder to the new path, and then start the timer for re-selecting
                            // Yes, i realise we *could* wait for the signal to fire, but if it fires too rapidly,
                            // we would miss it, and this is safer... not that i like it all that much
                            folderModel.folder = encodeURIComponent(path);
                            selectFileAfterLoadingTimer.selectThisFile = Qt.resolvedUrl(theFile);
                            selectFileAfterLoadingTimer.changeColumn = changeColumn;
                            selectFileAfterLoadingTimer.start();
                        }
                        Timer {
                            id: selectFileAfterLoadingTimer
                            property string selectThisFile: ""
                            property bool changeColumn: false
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
                                        if (selectFileAfterLoadingTimer.changeColumn) {
                                            _private.selectedColumn = 2;
                                        }
                                        filesListView.mostRecentlyActivatedIndex = -1;
                                        // A touch of juggling to ensure we don't change columns just from activating the thing...
                                        let currentSelectedColumn = _private.selectedColumn;
                                        filesListView.selector.activate_index(indexOfFile);
                                        _private.selectedColumn = currentSelectedColumn;
                                        filesListView.view.positionViewAtIndex(filesListView.selector.current_index, ListView.Center);
                                    }
                                }
                            }
                        }
                        // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                        active: zynqtgui.isBootingComplete
                        autoActivateIndexOnChange: true
                        property int mostRecentlyActivatedIndex: -1
                        onItemActivated: {
                            if (_private.selectedColumn != 2) {
                                _private.selectedColumn = 2;
                            }
                            if (filesListView.mostRecentlyActivatedIndex === index) {
                                sampleSlotAssigner.assignToSlot(currentItem.filePath);
                            }
                            filesListView.mostRecentlyActivatedIndex = index;
                        }
                        qmlSelector: ZUI.SelectorWrapper {
                            selector_list: Zynthbox.FolderListModel {
                                id: folderModel
                                caseSensitive: false
                                showDirs: false
                                showDotAndDotDot: false
                                sortCaseSensitive: false
                                nameFilters: [ "*.wav" ]
                                folder: "/zynthian/zynthian-my-data"
                                onFolderChanged: {
                                    filesListView.mostRecentlyActivatedIndex = -1;
                                    filesListView.selector.current_index = 0;
                                }
                            }
                            onItemActivated: {
                                filesListView.itemActivated(screenId, index);
                            }
                        }
                        delegate: ZUI.SelectorDelegate {
                            id: fileDelegate
                            width: ListView.view.width
                            height: Kirigami.Units.iconSizes.large
                            enabled: true
                            selector: filesListView.selector
                            text: model.fileName
                            readonly property string filePath: model.filePath
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
                                    if (filesListView.selector.current_index != model.index) {
                                        filesListView.selector.current_index = model.index;
                                    }
                                    _private.filePropertiesHelper.filePath = model.filePath;
                                    _private.filePropertiesHelper.playPreview();
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
}
