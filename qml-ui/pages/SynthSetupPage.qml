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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian

Zynthian.ScreenPage {
    id: root
    backAction: Kirigami.Action {
        text: qsTr("Back")
        onTriggered: zynthian.current_screen_id = "main"
    }
    contextualActions: [
        Kirigami.Action {
            text: qsTr("Sounds")
            Kirigami.Action {
                text: qsTr("Load Sound...")
                onTriggered: {
                    pickerDialog.mode = "sound";
                    pickerDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Save Sound...")
                onTriggered: {
                    saveDialog.mode = "sound";
                    saveDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Load Soundset...")
                onTriggered: {
                    pickerDialog.mode = "soundset";
                    pickerDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Save Soundset...")
                onTriggered: {
                    saveDialog.mode = "soundset";
                    saveDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Clear Sound")
                onTriggered: zynthian.layer.ask_remove_current_layer()
            }
            Kirigami.Action {
                text: qsTr("Clear All")
                onTriggered: zynthian.layer.ask_reset()
            }
        },
        Kirigami.Action {
            text: qsTr("Pick")
            Kirigami.Action {
                text: qsTr("Synths")
                onTriggered: zynthian.layer.select_engine(zynthian.fixed_layers.index_to_midi(zynthian.fixed_layers.current_index))
            }
            Kirigami.Action {
                text: qsTr("Audio-FX")
                onTriggered: {
                    zynthian.layer_options.show(); //FIXME: that show() method should change name
                    zynthian.current_screen_id = "layer_effects";
                }
            }
        },
        Kirigami.Action {
            text: qsTr("Edit")
            onTriggered: zynthian.current_screen_id = "control"
        }
    ]


    cuiaCallback: function(cuia) {
        let currentScreenIndex = root.screenIds.indexOf(zynthian.current_screen_id);
        switch (cuia) {
        case "NAVIGATE_LEFT":
            var newIndex = Math.max(0, currentScreenIndex - 1);
            zynthian.current_screen_id = root.screenIds[newIndex];
            return true;
        case "NAVIGATE_RIGHT":
            var newIndex = Math.min(root.screenIds.length - 1, currentScreenIndex + 1);
            zynthian.current_screen_id = root.screenIds[newIndex];
            return true;
        default:
            return false;
        }
    }


    property var screenIds: ["fixed_layers", "bank", "preset"]
    //property var screenTitles: [qsTr("Layers"), qsTr("Banks (%1)").arg(zynthian.bank.selector_list.count), qsTr("Presets (%1)").arg(zynthian.preset.selector_list.count)]
    previousScreen: "main"
    onCurrentScreenIdRequested: {
        //don't remove modal screens
        if (zynthian.current_modal_screen_id.length === 0) {
            zynthian.current_screen_id = screenId;
        }
    }

    contentItem: RowLayout {
        id: layout
        spacing: Kirigami.Units.gridUnit

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            // NOTE: this is to make fillWidth always partition the space in equal sizes
            implicitWidth: 1
            Layout.preferredWidth: 1
            Kirigami.Heading {
                level: 2
                Layout.preferredHeight: favToggleButton.height // HACK
                text: qsTr("Layers")
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
            }
            Zynthian.SelectorView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                screenId: "fixed_layers"
                onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                onItemActivated: root.itemActivated(screenId, index)
                onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: 1
            Layout.preferredWidth: 1
            RowLayout {
                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 2
                    text: qsTr("Banks (%1)").arg(zynthian.bank.selector_list.count)
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                }
                QQC2.Button {
                    text: qsTr("Fav-Mode")
                    checkable: true
                    checked: zynthian.bank.show_top_sounds
                    onToggled: {
                        zynthian.bank.show_top_sounds = checked;
                        zynthian.current_screen_id = "bank";
                    }
                }
            }
            Zynthian.SelectorView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                screenId: "bank"
                onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                onItemActivated: root.itemActivated(screenId, index)
                onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: 1
            Layout.preferredWidth: 1
            RowLayout {
                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 2
                    text: qsTr("Presets (%1)").arg(zynthian.preset.selector_list.count)
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                }
                QQC2.Button {
                    id: favToggleButton
                    icon.name: checked ? "starred-symbolic" : "non-starred-symbolic"
                    text: qsTr("Toggle")
                    LayoutMirroring.enabled: true
                    LayoutMirroring.childrenInherit: true
                    checkable: true
                    checked: zynthian.preset.current_is_favorite
                    onToggled: {
                        zynthian.preset.current_is_favorite = checked;
                        zynthian.current_screen_id = "preset";
                    }
                }
            }
            Zynthian.SelectorView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                screenId: "preset"
                onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                onItemActivated: root.itemActivated(screenId, index)
                onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
            }
        }


        Connections {
            target: zynthian.fixed_layers
            onCurrent_index_validChanged: {
                if (!zynthian.fixed_layers.current_index_valid) {
                    layerSetupDialog.open();
                }
            }
        }

        QQC2.Dialog {
            id: layerSetupDialog
            parent: applicationWindow().contentItem
            x: Math.round(parent.width/6 - width/2)
            y: Math.round(parent.height/2 - height/2)
            height: footer.implicitHeight + topMargin + bottomMargin
            modal: true
            Connections {
                target: root
                onIndexValidChanged: {
                    if (!zynthian.fixed_layers.current_index_valid) {
                        layerSetupDialog.open();
                    }
                }
            }

            footer: QQC2.Control {
                leftPadding: layerSetupDialog.leftPadding
                topPadding: layerSetupDialog.topPadding
                rightPadding: layerSetupDialog.rightPadding
                bottomPadding: layerSetupDialog.bottomPadding
                contentItem: ColumnLayout {
                    QQC2.Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        text: qsTr("Load A Sound...")
                        onClicked: {
                            layerSetupDialog.close();
                            pickerDialog.mode = "sound";
                            pickerDialog.open();
                        }
                    }
                    QQC2.Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        text: qsTr("New Synth...")
                        onClicked: {
                            layerSetupDialog.close();
                            newSynthWorkaroundTimer.restart()
                        }
                    }
                    Timer { //HACK why is this necessary?
                        id: newSynthWorkaroundTimer
                        interval: 200
                        onTriggered: zynthian.layer.select_engine(zynthian.fixed_layers.index_to_midi(zynthian.fixed_layers.current_index))

                    }
                }
            }
        }

        QQC2.Dialog {
            id: saveDialog
            property string mode: "sound"
            parent: root.parent
            header: Kirigami.Heading {
                text: saveDialog.mode === "soundset" ? qsTr("Save Soundset As...") : qsTr("Save Sound As...")
            }
            modal: true
            z: 999999999
            x: Math.round(parent.width/2 - width/2)
            y: Qt.inputMethod.visible ? Math.round(parent.height/5) : Math.round(parent.height/2 - height/2)
            width: Kirigami.Units.gridUnit * 15
            height: Kirigami.Units.gridUnit * 8
            onAccepted: {
                if (mode === "soundset") {
                    zynthian.layer.save_soundset_to_file(fileName.text);
                } else { //Sound
                    zynthian.layer.save_curlayer_to_file(fileName.text);
                }
            }
            onVisibleChanged : {
                cancelSaveButton.forceActiveFocus();
                if (visible) {
                    delayKeyboardTimer.restart()
                } else {
                    fileName.text = "";
                }
            }
            Timer {
                id: delayKeyboardTimer
                interval: 300
                onTriggered: {
                    fileName.forceActiveFocus();
                    Qt.inputMethod.visible = true;
                }
            }
            contentItem: ColumnLayout {
                QQC2.TextField {
                    id: fileName
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.6)
                    onAccepted: {
                        if (fileName.text.length > 0) {
                            saveDialog.accept();
                        }
                    }
                    onTextChanged: fileCheckTimer.restart()
                    Timer {
                        id: fileCheckTimer
                        interval: 300
                        onTriggered: {
                            if (saveDialog.mode === "soundset") {
                                conflictRow.visible = zynthian.layer.soundset_file_exists(fileName.text);
                            } else {
                                conflictRow.visible = zynthian.layer.layer_file_exists(fileName.text);
                            }
                        }
                    }
                }
                RowLayout {
                    id: conflictRow
                    visible: false
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: qsTr("File exists")
                    }
                }
            }
            footer: QQC2.Control {
                leftPadding: saveDialog.leftPadding
                topPadding: Kirigami.Units.smallSpacing
                rightPadding: saveDialog.rightPadding
                bottomPadding: saveDialog.bottomPadding
                contentItem: RowLayout {
                    Layout.fillWidth: true
                    QQC2.Button {
                        id: cancelSaveButton
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        text: qsTr("Cancel")
                        onClicked: {
                                saveDialog.close();
                            }
                        }
                    QQC2.Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        text: conflictRow.visible ? qsTr("Overwrite") : qsTr("Save")
                        enabled: fileName.text.length > 0
                        onClicked: {
                            if (fileName.text.length > 0) {
                                saveDialog.accept();
                            }
                        }
                    }
                }
            }
        }
        QQC2.Dialog {
            id: pickerDialog
            parent: root.parent
            modal: true
            property string mode: "sound"
            header: Kirigami.Heading {
                text: pickerDialog.mode === "soundset" ? qsTr("Pick a Soundset file") : qsTr("Pick a Sound file")
            }
            x: Math.round(parent.width/2 - width/2)
            y: Math.round(parent.height/2 - height/2)
            width: Math.round(parent.width * 0.8)
            height: Math.round(parent.height * 0.8)
            contentItem: QQC2.ScrollView {
                contentItem: ListView {
                    model: FolderListModel {
                        id: folderModel
                        nameFilters: ["*.json"]
                        folder: pickerDialog.mode === "soundset" ? "/zynthian/zynthian-my-data/soundsets/" : "/zynthian/zynthian-my-data/sounds/"
                    }
                    delegate: Kirigami.BasicListItem {
                        label: model.fileName
                        onClicked: {
                            if (pickerDialog.mode === "soundset") {
                                zynthian.layer.load_soundset_from_file(model.fileName)
                            } else {
                                //zynthian.layer.load_layer_from_file(model.fileName)
                                layerReplaceDialog.sourceChannels = zynthian.layer.load_layer_channels_from_file(model.fileName);
                                if (layerReplaceDialog.sourceChannels.length > 1) {
                                    layerReplaceDialog.fileToLoad = model.fileName;
                                    layerReplaceDialog.open();
                                } else {
                                    let map = {}
                                    map[layerReplaceDialog.sourceChannels[0].toString()] = zynthian.fixed_layers.index_to_midi(zynthian.fixed_layers.current_index);
                                    zynthian.layer.load_layer_from_file(model.fileName, map);
                                }
                            }
                            pickerDialog.accept()
                        }
                    }
                }
            }
        }
        QQC2.Dialog {
            id: layerReplaceDialog
            parent: root.parent
            modal: true
            x: Math.round(parent.width/2 - width/2)
            y: Math.round(parent.height/2 - height/2)
            height: contentItem.implicitHeight + header.implicitHeight + footer.implicitHeight + topMargin + bottomMargin + Kirigami.Units.smallSpacing
            property var sourceChannels: []
            property var destinationChannels: []
            property string fileToLoad
            function clear () {
                sourceChannels = [];
                destinationChannels = [];
                fileToLoad = "";
            }
            onAccepted: {
                if (sourceChannels.length !== destinationChannels.length) {
                    return;
                }
                let map = {};
                var i = 0;
                for (i in sourceChannels) {
                    map[sourceChannels[i]] = destinationChannels[i];
                }
                for (i in map) {
                    print("Mapping midi channel " + i + " to " + map[i]);
                }
                zynthian.layer.load_layer_from_file(fileToLoad, map);
                clear();
            }
            onRejected: {
                clear();
            }
            header: Kirigami.Heading {
                text: qsTr("Pick Layers To Replace")
            }
            contentItem: ColumnLayout {
                QQC2.Label {
                    text: qsTr("The selected sound has %1 layers: select layers that should be replaced by them.").arg(layerReplaceDialog.sourceChannels.length)
                }
                Repeater {
                    model: zynthian.fixed_layers.selector_list
                    delegate: QQC2.CheckBox {
                        text: model.display
                        visible: index < 5
                        enabled: checked || layerReplaceDialog.destinationChannels.length < layerReplaceDialog.sourceChannels.length
                        opacity: enabled ? 1 : 0.4

                        onCheckedChanged: {
                            let destIdx = layerReplaceDialog.destinationChannels.indexOf(index);
                            if (checked) {
                                if (destIdx === -1) {
                                    layerReplaceDialog.destinationChannels.push(index);
                                    layerReplaceDialog.destinationChannelsChanged();
                                }
                            } else {
                                if (destIdx !== -1) {
                                    layerReplaceDialog.destinationChannels.splice(destIdx, 1);
                                    layerReplaceDialog.destinationChannelsChanged();
                                }
                            }
                        }
                        Connections {
                            target: layerReplaceDialog
                            onFileToLoadChanged: checked = index === zynthian.fixed_layers.current_index
                        }
                    }
                }
            }
            footer: QQC2.Control {
                leftPadding: saveDialog.leftPadding
                topPadding: Kirigami.Units.smallSpacing
                rightPadding: saveDialog.rightPadding
                bottomPadding: saveDialog.bottomPadding
                contentItem: RowLayout {
                    QQC2.Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        text: qsTr("Cancel")
                        onClicked: layerReplaceDialog.close()
                    }
                    QQC2.Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        enabled: layerReplaceDialog.destinationChannels.length === layerReplaceDialog.sourceChannels.length
                        text: qsTr("Load && Replace")
                        onClicked: layerReplaceDialog.accept()
                    }
                }
            }
        }
    }
}


