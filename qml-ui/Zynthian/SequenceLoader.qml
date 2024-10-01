/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Component providing load/save UI for sequences and patterns

Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import QtGraphicalEffects 1.0
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Item {
    id: component
    property bool opened: sequenceFilePicker.opened || loadedSequenceOptionsPicker.opened || loadedPatternOptionsPicker.opened || trackPicker.opened
    property int topPadding: Kirigami.Units.largeSpacing
    property int leftPadding: Kirigami.Units.largeSpacing
    property int rightPadding: Kirigami.Units.largeSpacing
    property int bottomPadding: Kirigami.Units.largeSpacing

    /**
     * \brief Load a sequence from a file into a named sequence (loads into the global sequence if none is specified)
     * @param sequenceName The name of the sequence you wish to load data into (if it already exists, it will be cleared first)
     */
    function loadSequenceFromFile(sequenceName) {
        if (sequenceName == undefined || sequenceName == "") {
            sequenceFilePicker.sequenceName = zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongName;
        } else {
            sequenceFilePicker.sequenceName = sequenceName;
        }
        sequenceFilePicker.patternName = "";
        sequenceFilePicker.saveMode = false;
        sequenceFilePicker.open();
    }

    /**
     * \brief Save a sequence to file (if unspecified, save the global sequence)
     * @param sequenceName The sequence you wish to save
     */
    function saveSequenceToFile(sequenceName) {
        if (sequenceName == undefined || sequenceName == "") {
            sequenceFilePicker.sequenceName = zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongName;
        } else {
            sequenceFilePicker.sequenceName = sequenceName;
        }
        sequenceFilePicker.patternName = "";
        sequenceFilePicker.saveMode = true;
        sequenceFilePicker.open();
    }

    /**
     * \brief Save a pattern to file (otherwise the currently selected pattern on the global sequence will be saved)
     * @param patternName The name of the pattern you wish to save
     */
    function savePatternToFile(patternName) {
        if (patternName == undefined || patternName == "") {
            var sequence = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName);
            if (sequence.activePattern > -1) {
                sequenceFilePicker.patternName = sequence.activePatternObject.objectName;
            }
        } else {
            sequenceFilePicker.patternName = patternName;
        }
        sequenceFilePicker.sequenceName = "";
        sequenceFilePicker.saveMode = true;
        sequenceFilePicker.open();
    }

    property var cuiaCallback: function(cuia) {
        var result = false;

        if (sequenceFilePicker.opened) {
            result = sequenceFilePicker.cuiaCallback(cuia);
        }

        if (!result) {
            switch(cuia) {
                case "SWITCH_SELECT_SHORT":
                case "SWITCH_SELECT_BOLD":
                case "SWITCH_SELECT_LONG":
                    if (loadedSequenceOptionsPicker.opened) {
                        loadedSequenceOptionsPicker.accept();
                        result = true;
                    } else if (loadedPatternOptionsRepeater.opened) {
                        loadedPatternOptionsRepeater.accept();
                        result = true;
                    } else if (trackPicker.opened) {
                        trackPicker.close();
                        result = true;
                    }
                    break;
                case "SWITCH_BACK_SHORT":
                case "SWITCH_BACK_BOLD":
                case "SWITCH_BACK_LONG":
                    if (loadedSequenceOptionsPicker.opened) {
                        loadedSequenceOptionsPicker.reject();
                        result = true;
                    } else if (loadedPatternOptionsRepeater.opened) {
                        loadedPatternOptionsRepeater.reject();
                        result = true;
                    } else if (trackPicker.opened) {
                        trackPicker.close();
                        result = true;
                    }
                    break;
                default:
                    break;
            }
        }

        return result;
    }

    Zynthian.FilePickerDialog {
        id: sequenceFilePicker
        property string sequenceName
        property string patternName;
        autoExtension: sequenceName != "" ? "/metadata.sequence.json" : ".pattern.json"
        headerText: {
            if (saveMode) {
                if (sequenceName != "") {
                    return qsTr("Save Sequence");
                } else {
                    return qsTr("Save Pattern");
                }
            } else {
                return qsTr("Load Sequence or Pattern");
            }
        }
        rootFolder: "/zynthian/zynthian-my-data/"
        onVisibleChanged: {
            if (saveMode) {
                folderModel.folder = rootFolder + "sequences/my-sequences/";
            } else {
                folderModel.folder = rootFolder + "sequences/";
            }
        }
        property QtObject currentFileObject;
        folderModel {
            nameFilters: ["*.pattern.json", "*.sequence.json"]
        }
        filePropertiesComponent: sequenceFilePicker.currentFileObject === null
            ? null
            : sequenceFilePicker.currentFileObject.hasOwnProperty("activePattern")
                ? sequenceFileInfoComponent
                : patternFileInfoComponent
        onCurrentFileInfoChanged: {
            // Should we be deleting the sequences and patterns we're getting here?
            if (sequenceFilePicker.currentFileInfo) {
                if (sequenceFilePicker.currentFileInfo.fileName.endsWith(".sequence.json")) {
                    sequenceFilePicker.currentFileObject = Zynthbox.PlayGridManager.getSequenceModel(sequenceFilePicker.currentFileInfo.filePath);
                    sequenceFilePicker.currentFileObject.load(sequenceFilePicker.currentFileInfo.filePath);
                } else if (sequenceFilePicker.currentFileInfo.fileName.endsWith(".pattern.json")) {
                    sequenceFilePicker.currentFileObject = Zynthbox.PlayGridManager.getPatternModel(sequenceFilePicker.currentFileInfo.filePath);
                    Zynthbox.PlayGridManager.setModelFromJsonFile(sequenceFilePicker.currentFileObject, sequenceFilePicker.currentFileInfo.filePath);
                } else {
                    sequenceFilePicker.currentFileObject = null;
                }
            } else {
                sequenceFilePicker.currentFileObject = null;
            }
        }
        Component {
            id: sequenceFileInfoComponent
            ColumnLayout {
                QQC2.Label {
                    Layout.fillWidth: true
                    text: qsTr("Sequence");
                }
                Item { Layout.fillWidth: true; Layout.minimumHeight: Kirigami.Units.smallSpacing;  Layout.maximumHeight: Kirigami.Units.smallSpacing; }
                Repeater {
                    model: sequenceFilePicker.currentFileObject
                    delegate: patternFileInfoComponent
                }
                Item { Layout.fillWidth: true; Layout.fillHeight: true; }
            }
        }
        // TODO Identify identical layers and match them up so we only assign the same Sound once
        Component {
            id: patternFileInfoComponent
            ColumnLayout {
                Layout.fillWidth: true
                property var soundInfo: [];
                QQC2.Label {
                    Layout.fillWidth: true
                    text: qsTr("Pattern %1").arg(model.index + 1);
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    visible: false
                    text: qsTr("Sound (%1)").arg(soundInfo ? (soundInfo.length === 1 ? qsTr("1 Layer") : qsTr("%1 Layers").arg(soundInfo.length)) : "0");
                }
                Repeater {
                    model: soundInfo
                    delegate: QQC2.Label {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: modelData["preset_name"].length > 0
                            ? "• %1 (%2)".arg(modelData["name"]).arg(modelData["preset_name"])
                            : "• %1".arg(modelData["name"])
                    }
                }
                Item { visible: model.pattern === undefined; Layout.fillWidth: true; Layout.fillHeight: true; }
            }
        }
        filesListView.delegate: Kirigami.BasicListItem {
            // This function is required by cuiaCallback in FilePickerDialog to allow SWITCH_SELECT to work
            function selectItem() {
                sequenceFilePicker.filesListView.selectItem(model)
            }
            width: ListView.view.width
            highlighted: ListView.isCurrentItem
            property bool isCurrentItem: ListView.isCurrentItem
            onIsCurrentItemChanged: {
                if (isCurrentItem) {
                    sequenceFilePicker.currentFileInfo = model;
                }
            }
            label: model.fileName
            icon: model.fileIsDir ? "folder" : "audio-midi"
            onClicked: sequenceFilePicker.filesListView.selectItem(model)
        }
        property string mostRecentlyPicked;
        onAccepted: {
            if (saveMode) {
                if (mostRecentlyPicked) {
                    if (sequenceName != "") {
                        var sequence = Zynthbox.PlayGridManager.getSequenceModel(sequenceFilePicker.sequenceName);
                        sequence.save(mostRecentlyPicked + "/metadata.sequence.json", true); // Explicitly export-only to this location
                    } else if (patternName != "") {
                        var saveFileName = mostRecentlyPicked;
                        if (!saveFileName.endsWith(".pattern.json")) {
                            saveFileName = saveFileName + ".pattern.json";
                        }
                        var pattern = Zynthbox.PlayGridManager.getPatternModel(sequenceFilePicker.patternName);
                        if (pattern) {
                            pattern.exportToFile(saveFileName);
                        }
                    }
                }
            } else {
                if (sequenceFilePicker.currentFileObject.hasOwnProperty("activePattern")) {
                    // If this is a sequence, load a full sequence...
                    loadedSequenceOptionsPicker.loadedSequence = sequenceFilePicker.currentFileObject;
                    loadedSequenceOptionsPicker.open();
                } else {
                    // otherwise, load a single pattern
                    loadedPatternOptionsPicker.loadedPattern = sequenceFilePicker.currentFileObject;
                    loadedPatternOptionsPicker.open();
                }
            }
        }
        onAccepted: {
            mostRecentlyPicked = sequenceFilePicker.selectedFile.filePath;
        }
    }

    Zynthian.Dialog {
        id: loadedSequenceOptionsPicker
        property QtObject loadedSequence
        width: component.Window.width - Kirigami.Units.largeSpacing * 2
        height: Math.round(component.Window.height * 0.8)
        z: 999999999
        modal: true
        header: Kirigami.Heading {
            text: qsTr("Loading Sequence: Pick Pattern Options")
            font.pointSize: 16
            Layout.leftMargin: 12
            Layout.topMargin: 12
        }
        contentItem: ColumnLayout {
            property bool singlePatternImport: false
            Repeater {
                id: loadedSequenceOptionsRepeater
                model: loadedSequenceOptionsPicker.loadedSequence
                delegate: patternOptions
            }
        }
        footer: QQC2.Control {
            leftPadding: component.leftPadding
            topPadding: Kirigami.Units.smallSpacing
            rightPadding: component.rightPadding
            bottomPadding: component.bottomPadding
            contentItem: RowLayout {
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    text: qsTr("Cancel")
                    onClicked: loadedSequenceOptionsPicker.close()
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    text: qsTr("Load && Apply")
                    onClicked: loadedSequenceOptionsPicker.accept()
                }
            }
        }
        function clear() {
            loadedSequence = null;
        }
        onRejected: {
            clear();
        }
        onAccepted: {
            applyLoadedSequence(loadedSequenceOptionsRepeater);
            clear();
        }
    }

    Zynthian.Dialog {
        id: loadedPatternOptionsPicker
        property QtObject loadedPattern
        width: component.Window.width - Kirigami.Units.largeSpacing * 2
        height: Math.round(component.Window.height * 0.3)
        z: 999999999
        modal: true
        header: Kirigami.Heading {
            text: qsTr("Loading Pattern: Pick Options")
            font.pointSize: 16
            Layout.leftMargin: 12
            Layout.topMargin: 12
        }
        contentItem: ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            property bool singlePatternImport: true
            Repeater {
                id: loadedPatternOptionsRepeater
                model: loadedPatternOptionsPicker.loadedPattern ? [loadedPatternOptionsPicker.loadedPattern] : []
                delegate: patternOptions
            }
        }
        footer: QQC2.Control {
            leftPadding: component.leftPadding
            topPadding: Kirigami.Units.smallSpacing
            rightPadding: component.rightPadding
            bottomPadding: component.bottomPadding
            contentItem: RowLayout {
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    text: qsTr("Cancel")
                    onClicked: loadedPatternOptionsPicker.close()
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    text: qsTr("Load and Apply")
                    onClicked: loadedPatternOptionsPicker.accept()
                }
            }
        }
        function clear() {
            loadedPattern = null;
        }
        onRejected: {
            clear();
        }
        onAccepted: {
            applyLoadedSequence(loadedPatternOptionsRepeater);
            clear();
        }
    }

    function applyLoadedSequence(repeaterObject) {
        var globalSequence = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName);
        if (repeaterObject.model.hasOwnProperty("patterns")) {
            // Then it's a sequence, and we should apply all the options from the sequence as well (even if it's not much)
            var sequenceModel = repeaterObject.model;
            globalSequence.activePattern = sequenceModel.activePattern;
        }
        for (var patternIndex = 0; patternIndex < repeaterObject.count; patternIndex++) {
            var theItem = repeaterObject.itemAt(patternIndex);
            // Only import a pattern object that is actually enabled
            if (theItem.importPattern) {
                // As we're importing to the global sequence, operate on the pattern in the appropriate position
                var importToPattern = globalSequence.getByClipId(theItem.targetTrackIndex, theItem.targetClipIndex);
                console.log("Importing", theItem.patternObject, "into", importToPattern);

                // Now apply our loaded pattern onto the global one
                importToPattern.cloneOther(theItem.patternObject);
            }
        }
    }

    Component {
        id: patternOptions
        ColumnLayout {
            id: patternOptionsRoot
            Layout.fillWidth: true
            property QtObject patternObject: model.pattern === undefined ? modelData : model.pattern
            property bool importPattern: patternObject.enabled
            property bool importSound: false
            property int targetTrackIndex: -1
            property QtObject targetTrack: zynqtgui.sketchpad.song.channelsModel.getChannel(patternOptionsRoot.targetTrackIndex)
            property int targetClipIndex: -1
            property var soundInfo: []
            Component.onCompleted: {
                targetTrackIndex = zynqtgui.sketchpad.selectedTrackId;
                targetClipIndex = parent.singlePatternImport ? targetTrack.selectedClip : model.index;
            }
            RowLayout {
                Layout.fillWidth: true
                QQC2.CheckBox {
                    visible: patternOptionsRoot.parent.singlePatternImport === false
                    checked: patternOptionsRoot.importPattern
                    onClicked: {
                        patternOptionsRoot.importPattern = !patternOptionsRoot.importPattern
                    }
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    enabled: patternOptionsRoot.importPattern
                    text: "Pattern " + (model.index + 1)
                }
                QQC2.Button {
                    id: importToTrack
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    text: patternOptionsRoot.targetTrackIndex > -1 && patternOptionsRoot.targetTrackIndex < 10
                        ? qsTr("Import to Track %1").arg(patternOptionsRoot.targetTrack.name)
                        : qsTr("Pick Channel Association")
                    enabled: patternOptionsRoot.importPattern
                    property bool pickingTrack: false
                    onClicked: {
                        pickingTrack = true;
                        trackPicker.targetTrackIndex = patternOptionsRoot.targetTrackIndex;
                        trackPicker.open()
                    }
                    Connections {
                        target: trackPicker;
                        onVisibleChanged: {
                            if (importToTrack.pickingTrack === true && trackPicker.visible === false && patternOptionsRoot.targetTrackIndex !== trackPicker.targetTrackIndex) {
                                patternOptionsRoot.targetTrackIndex = trackPicker.targetTrackIndex;
                                importToTrack.pickingTrack = false;
                                // TODO Should we maybe set the sound destination to whereever the channel is pointed if that's a thing already, or...?
                            }
                        }
                    }
                }
                QQC2.ComboBox {
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 1
                    enabled: patternOptionsRoot.importPattern
                    model: ["Slot a", "Slot b", "Slot c", "Slot d", "Slot e"]
                    currentIndex: patternOptionsRoot.targetClipIndex
                    onCurrentIndexChanged: {
                        console.log(patternOptionsRoot.patternObject, patternOptionsRoot.targetClipIndex, currentIndex);
                        if (currentIndex > -1) {
                            patternOptionsRoot.targetClipIndex = currentIndex;
                        }
                    }
                    popup.z: 1999999999
                }
            }
        }
    }

    Zynthian.Popup {
        id: trackPicker
        y: component.mapFromGlobal(0, Math.round(component.Window.height/2 - height/2)).y
        x: component.mapFromGlobal(Math.round(component.Window.width/2 - width/2), 0).x
        width: component.Window.width
        height: Math.round(component.Window.height * 0.8)
        z: 1999999999
        property int targetTrackIndex: -1
        ColumnLayout {
            anchors.fill: parent
            Kirigami.Heading {
                Layout.fillWidth: true
                text: qsTr("Pick Track To Import Pattern Into")
            }
            GridLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                columns: 4
                Repeater {
                    model: zynqtgui.sketchpad.song.channelsModel
                    delegate: Zynthian.PlayGridButton {
                        Layout.fillWidth: true
                        Layout.preferredWidth: trackPicker.width / 4
                        Layout.fillHeight: true
                        text: qsTr("Import to:\nTrack %1").arg(model.name)
                        onClicked: {
                            trackPicker.targetTrackIndex = model.id
                            trackPicker.close();
                        }
                    }
                }
            }
            Zynthian.ActionBar {
                Layout.fillWidth: true
                currentPage: Item {
                    property QtObject backAction: Kirigami.Action {
                        text: "Back"
                        onTriggered: {
                            trackPicker.close();
                        }
                    }
                    property list<QtObject> contextualActions: [
                        Kirigami.Action {},
                        Kirigami.Action {},
                        Kirigami.Action {}
                    ]
                }
            }
        }
    }
}
