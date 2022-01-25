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
import org.zynthian.quick 1.0 as ZynQuick

Item {
    id: component

    /**
     * \brief Load a sequence from a file into a named sequence (loads into the global sequence if none is specified)
     * @param sequenceName The name of the sequence you wish to load data into (if it already exists, it will be cleared first)
     */
    function loadSequenceFromFile(sequenceName) {
        if (sequenceName == undefined || sequenceName == "") {
            sequenceFilePicker.sequenceName = "Global";
        } else {
            sequenceFilePicker.sequenceName = sequenceName;
        }
        sequenceFilePicker.saveMode = false;
        sequenceFilePicker.open();
    }

    /**
     * \brief Save a sequence to file (if unspecified, save the global sequence)
     * @param sequenceName The sequence you wish to save
     */
    function saveSequenceToFile(sequenceName) {
        if (sequenceName == "") {
            sequenceFilePicker.sequenceName = "Global";
        } else {
            sequenceFilePicker.sequenceName = sequenceName;
        }
        sequenceFilePicker.saveMode = true;
        sequenceFilePicker.open();
    }

    Zynthian.FilePickerDialog {
        id: sequenceFilePicker
        property string sequenceName
        rootFolder: "/zynthian/zynthian-my-data/"
        onVisibleChanged: folderModel.folder = rootFolder + "sequences/"
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
                    sequenceFilePicker.currentFileObject = ZynQuick.PlayGridManager.getSequenceModel(sequenceFilePicker.currentFileInfo.filePath);
                    sequenceFilePicker.currentFileObject.load(sequenceFilePicker.currentFileInfo.fileName);
                } else if (sequenceFilePicker.currentFileInfo.fileName.endsWith(".pattern.json")) {
                    sequenceFilePicker.currentFileObject = ZynQuick.PlayGridManager.getPatternModel(sequenceFilePicker.currentFileInfo.filePath);
                    ZynQuick.PlayGridManager.setModelFromJsonFile(sequenceFilePicker.currentFileObject, sequenceFilePicker.currentFileInfo.filePath);
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
                property string layerJson: model.pattern === undefined ? sequenceFilePicker.currentFileObject.layerData : model.pattern.layerData
                property var soundInfo: layerJson.length > 0 ? zynthian.layer.sound_metadata_from_json(layerJson) : [];
                QQC2.Label {
                    Layout.fillWidth: true
                    text: qsTr("Pattern %1").arg(model.index + 1);
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
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
        onFileSelected: {
            if (saveMode) {
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
    }

    QQC2.Dialog {
        id: loadedSequenceOptionsPicker
        property QtObject loadedSequence
        y: root.mapFromGlobal(0, Math.round(component.Window.height/2 - height/2)).y
        x: root.mapFromGlobal(Math.round(component.Window.width/2 - width/2), 0).x
        width: component.Window.width
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
            Repeater {
                id: loadedSequenceOptionsRepeater
                model: loadedSequenceOptionsPicker.loadedSequence
                delegate: patternOptions
            }
        }
        footer: QQC2.Control {
            leftPadding: root.leftPadding
            topPadding: Kirigami.Units.smallSpacing
            rightPadding: root.rightPadding
            bottomPadding: root.bottomPadding
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

    QQC2.Dialog {
        id: loadedPatternOptionsPicker
        property QtObject loadedPattern
        y: root.mapFromGlobal(0, Math.round(component.Window.height/2 - height/2)).y
        x: root.mapFromGlobal(Math.round(component.Window.width/2 - width/2), 0).x
        width: component.Window.width
        height: Math.round(component.Window.height * 0.3)
        z: 999999999
        modal: true
        header: Kirigami.Heading {
            text: qsTr("Loading Single Pattern: Pick Options")
            font.pointSize: 16
            Layout.leftMargin: 12
            Layout.topMargin: 12
        }
        contentItem: ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Repeater {
                id: loadedPatternOptionsRepeater
                model: [loadedPatternOptionsPicker.loadedPattern]
                delegate: patternOptions
            }
        }
        footer: QQC2.Control {
            leftPadding: root.leftPadding
            topPadding: Kirigami.Units.smallSpacing
            rightPadding: root.rightPadding
            bottomPadding: root.bottomPadding
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
                    text: qsTr("Load && Apply")
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
        if (repeaterObject.model.hasOwnProperty("patterns")) {
            // Then it's a sequence, and we should apply all the options from the sequence as well
            // basically import bpm?
            var sequenceModel = repeaterObject.model;
        }
        for (var i = 0; i < repeaterObject.count; i++) {
            var theItem = repeaterObject.itemAt(i);
            if (theItem.patternObject.enabled) {
                // Only import a pattern object that is actually enabled
                // Run through all other tracks, and un-associate with this index of pattern if one exists...
            }
        }
    }

    Component {
        id: patternOptions
        RowLayout {
            id: patternOptionsRoot
            Layout.fillWidth: true
            property QtObject patternObject: model.pattern === undefined ? modelData : model.pattern
            property var destinationChannels: []
            QQC2.CheckBox {
                id: importPattern
                checked: patternOptionsRoot.patternObject.enabled
                onClicked: {
                    patternOptionsRoot.patternObject.enabled = !patternOptionsRoot.patternObject.enabled
                }
            }
            QQC2.Label {
                // This likely wants to be nicer...
                text: "Pattern " + (model.index + 1)
                Layout.fillWidth: true
            }
            QQC2.CheckBox {
                id: importSoundCheck
                text: qsTr("Import Sound")
                enabled: patternOptionsRoot.patternObject.enabled && patternOptionsRoot.layerData !== ""
            }
            QQC2.Button {
                id: pickSoundDestination
                Layout.fillWidth: true
                text: qsTr("Pick Layer")
                enabled: patternOptionsRoot.patternObject.enabled && patternOptionsRoot.layerData !== ""
                property bool pickingLayer: false
                onClicked: {
                    pickingLayer = true;
                    layerReplacer.sourceChannels = zynthian.layer.load_layer_channels_from_json(patternOptionsRoot.patternObject.layerData);
                    layerReplacer.jsonToLoad = patternOptionsRoot.patternObject.layerData;
                    layerReplacer.open();
                }
                Connections {
                    target: layerReplacer
                    onAccepted: {
                        if (pickSoundDestination.pickingLayer) {
                            patternOptionsRoot.destinationChannels = layerReplacer.destinationChannels;
                            layerReplacer.clear();
                            pickSoundDestination.pickingLayer = false;
                        }
                    }
                }
            }
            QQC2.Button {
                id: importToTrack
                Layout.fillWidth: true
                text: qsTr("Import to Track %1").arg(patternOptionsRoot.patternObject.layer + 1)
                enabled: patternOptionsRoot.patternObject.enabled
                property bool pickingTrack: false
                onClicked: {
                    pickingTrack = true;
                    trackPicker.open()
                }
                Connections {
                    target: trackPicker;
                    onVisibleChanged: {
                        if (importToTrack.pickingTrack === true && trackPicker.visible === false && patternOptionsRoot.patternObject.layer !== trackPicker.associatedTrackIndex) {
                            patternOptionsRoot.patternObject.enabled = (trackPicker.associatedTrackIndex > -1);
                            patternOptionsRoot.patternObject.layer = trackPicker.associatedTrackIndex;
                            importToTrack.pickingTrack = false;
                        }
                    }
                }
            }
        }
    }

    Zynthian.LayerReplaceDialog {
        id: layerReplacer
        parent: root.parent
        modal: true
        y: root.mapFromGlobal(0, Math.round(component.Window.height/2 - height/2)).y
        x: root.mapFromGlobal(Math.round(component.Window.width/2 - width/2), 0).x
        height: contentItem.implicitHeight + header.implicitHeight + footer.implicitHeight + topMargin + bottomMargin + Kirigami.Units.smallSpacing
        z: 1999999999
        footerLeftPadding: saveDialog.leftPadding
        footerRightPadding: saveDialog.rightPadding
        footerBottomPadding: saveDialog.bottomPadding
    }
    QQC2.Popup {
        id: trackPicker
        modal: true
        y: root.mapFromGlobal(0, Math.round(component.Window.height/2 - height/2)).y
        x: root.mapFromGlobal(Math.round(component.Window.width/2 - width/2), 0).x
        width: component.Window.width
        height: Math.round(component.Window.height * 0.8)
        z: 1999999999
        property int associatedTrackIndex: -1
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
                    model: zynthian.zynthiloops.song.tracksModel
                    delegate: Zynthian.PlayGridButton {
                        Layout.fillWidth: true
                        Layout.preferredWidth: trackPicker.width / 4
                        Layout.fillHeight: true
                        text: model.track.connectedPattern > -1
                            ? qsTr("Replace pattern on:\nTrack %1").arg(model.id + 1)
                            : qsTr("Import to:\nTrack %1").arg(model.id + 1)
                        onClicked: {
                            trackPicker.associatedTrackIndex = model.id
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
                        Kirigami.Action {
                            text: qsTr("Unassign")
                            onTriggered: {
                                trackPicker.associatedTrackIndex = -1
                                trackPicker.close();
                            }
                        }
                    ]
                }
            }
        }
    }
}
