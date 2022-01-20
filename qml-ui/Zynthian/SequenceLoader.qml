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
        filePropertiesComponent: sequenceFilePicker.currentFileObject === null
            ? null
            : sequenceFilePicker.currentFileObject.hasOwnProperty("activePattern")
                ? sequenceFileInfoComponent
                : patternFileInfoComponent
        onCurrentFileInfoChanged: {
            // Should we be deleting the sequences and patterns we're getting here?
            if (sequenceFilePicker.currentFileInfo) {
                if (sequenceFilePicker.currentFileInfo.fileName.endsWith(".sequence.json")) {
                    sequenceFilePicker.currentFileObject = ZynQuick.PlayGridManager.getSequenceModel(sequenceFilePicker.currentFileInfo.fileName);
                    sequenceFilePicker.currentFileObject.load(sequenceFilePicker.currentFileInfo.fileName);
                } else if (sequenceFilePicker.currentFileInfo.fileName.endsWith(".pattern.json")) {
                    // Not yet... We need to be able to fetch and use orphaned patterns, otherwise this ends up weird...
                    // sequenceFilePicker.currentFileObject = ZynQuick.PlayGridManager.getPatternModel(sequenceFilePicker.currentFileInfo.fileName);
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
                    text: qsTr("Sequence");
                }
                Repeater {
                    model: sequenceFilePicker.currentFileObject
                    delegate: patternFileInfoComponent
                }
            }
        }
        Component {
            id: patternFileInfoComponent
            ColumnLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    text: qsTr("Pattern");
                }
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
        parent: component.parent
        modal: true
        x: Math.round(parent.width/2 - width/2)
        y: Math.round(parent.height/2 - height/2)
        height: contentItem.implicitHeight + header.implicitHeight + footer.implicitHeight + topMargin + bottomMargin + Kirigami.Units.smallSpacing
        header: Kirigami.Heading {
            text: qsTr("Loading Sequence: Pick Pattern Options")
        }
        contentItem: ColumnLayout {
            Repeater {
                model: loadedSequenceOptionsPicker.loadedSequence
                delegate: patternOptions
            }
        }
        footer: QQC2.Control {
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
            clear();
        }
    }

    QQC2.Dialog {
        id: loadedPatternOptionsPicker
        property QtObject loadedPattern
        parent: component.parent
        modal: true
        x: Math.round(parent.width/2 - width/2)
        y: Math.round(parent.height/2 - height/2)
        height: contentItem.implicitHeight + header.implicitHeight + footer.implicitHeight + topMargin + bottomMargin + Kirigami.Units.smallSpacing
        header: Kirigami.Heading {
            text: qsTr("Loading Single Pattern: Pick Options")
        }
        contentItem: ColumnLayout {
            Repeater {
                model: [loadedPatternOptionsPicker.loadedPattern]
                delegate: patternOptions
            }
        }
        footer: QQC2.Control {
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
            clear();
        }
    }

    Component {
        id: patternOptions
        RowLayout {
            property QtObject patternObject: modelData
            QQC2.CheckBox {
                id: importPattern
                checked: modelData.enabled
                onClicked: {
                    modelData.enabled = !modelData.enabled
                }
            }
            QQC2.Label {
                // This likely wants to be nicer...
                text: "Pattern " + (model.index + 1)
            }
            QQC2.CheckBox {
                id: importSoundCheck
            }
            QQC2.Button {
                id: pickSoundDestination
            }
            QQC2.ComboBox {
                id: importToTrack
            }
        }
    }
}
