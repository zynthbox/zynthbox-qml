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

    property bool isVisible: ["layer", "fixed_layers", "main_layers_view", "layers_for_track", "bank", "preset"].indexOf(zynthian.current_screen_id) >= 0

    backAction: Kirigami.Action {
        text: qsTr("Back")
        onTriggered: zynthian.current_screen_id = "zynthiloops"
    }
    contextualActions: [
        Kirigami.Action {
            text: qsTr("Sounds")
            Kirigami.Action {
                text: middleColumnStack.currentIndex === 0 ? qsTr("Show Mixer") : qsTr("Hide Mixer")
                onTriggered: {
                    middleColumnStack.currentIndex = middleColumnStack.currentIndex === 0 ? 1 : 0;
                }
            }
            Kirigami.Action {
                text: qsTr("Load Sound...")
                onTriggered: {
                    pickerDialog.mode = "sound";
                    pickerDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Save Sound...")
                enabled: zynthian.fixed_layers.current_index_valid
                onTriggered: {
                    saveDialog.mode = "sound";
                    saveDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Get New Sounds...")
                onTriggered: zynthian.show_modal("sound_downloader")
            }
            //Kirigami.Action {
                //text: qsTr("Get New Soundfonts...")
                //onTriggered: zynthian.show_modal("soundfont_downloader")
            //}
            /*Kirigami.Action {
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
                text: qsTr("Get New Soundsets...")
                onTriggered: zynthian.show_modal("soundset_downloader")
            }*/
            /*Kirigami.Action {
                text: qsTr("Clear Sounds")
                enabled: zynthian.fixed_layers.current_index_valid
                onTriggered: zynthian.fixed_layers.ask_clear_visible_range()
            }*/
            /*Kirigami.Action {
                text: qsTr("Clear All")
                onTriggered: zynthian.layer.ask_reset()
            }*/
        },
        Kirigami.Action {
            text: qsTr("Slot")
            Kirigami.Action {
                text: qsTr("Synths")
                onTriggered: {
                    zynthian.layer.page_after_layer_creation = "layers_for_track";
                    zynthian.layer.select_engine(zynthian.fixed_layers.active_midi_channel)
                }
            }
            Kirigami.Action {
                text: qsTr("Remove Synth")
                enabled: zynthian.fixed_layers.current_index_valid
                onTriggered: zynthian.layer.ask_remove_current_layer()
            }
            Kirigami.Action {
                // Disable this entry as per #299
                visible: false
                text: qsTr("Effect Layer")
                onTriggered: {
                    zynthian.layer.new_effect_layer(zynthian.fixed_layers.active_midi_channel)
                }
            }
            Kirigami.Action {
                text: qsTr("Audio-FX")
                enabled: zynthian.fixed_layers.current_index_valid
                onTriggered: {
                    zynthian.layer_options.show(); //FIXME: that show() method should change name
                    zynthian.current_screen_id = "layer_effects";
                }
            }
            Kirigami.Action {
                text: qsTr("Remove All Audio-FX")
                enabled: zynthian.fixed_layers.current_index_valid
                onTriggered: {
                    zynthian.layer_effects.fx_reset()
                }
            }
            Kirigami.Action {
                text: qsTr("MIDI-FX")
                enabled: zynthian.fixed_layers.current_index_valid
                onTriggered: {
                    zynthian.layer_options.show() //FIXME: that show() method should change name
                    zynthian.current_screen_id = "layer_midi_effects";
                }
            }
            Kirigami.Action {
                text: qsTr("Remove All MIDI-FX")
                enabled: zynthian.fixed_layers.current_index_valid
                onTriggered: {
                    zynthian.layer_midi_effects.fx_reset()
                }
            }
        },
        Kirigami.Action {
            text: qsTr("Edit")
            onTriggered: {
                zynthian.control.single_effect_engine = null;
                zynthian.current_screen_id = "control";
            }
        }
    ]


    cuiaCallback: function(cuia) {
        let currentScreenIndex = root.screenIds.indexOf(zynthian.current_screen_id);
        layerSetupDialog.reject(); // Close the new layer popup at any keyboard interaction

        switch (cuia) {
        case "SWITCH_SELECT_SHORT":
            if (zynthian.current_screen_id == "layers_for_track" && !zynthian.fixed_layers.current_index_valid) {
                layerSetupDialog.open();
                return true
            } else if (zynthian.fixed_layers.current_index_valid) {
                zynthian.preset.current_is_favorite = !zynthian.preset.current_is_favorite;
            }
            return false
        case "SWITCH_SELECT_BOLD":
            if (zynthian.fixed_layers.current_index_valid) {
                zynthian.control.single_effect_engine = null;
                zynthian.current_screen_id = "control";
                return true
            }
            return false
        case "NAVIGATE_LEFT":
            var newIndex = Math.max(0, currentScreenIndex - 1);
            zynthian.current_screen_id = root.screenIds[newIndex];
            return true;
        case "NAVIGATE_RIGHT":
            var newIndex = Math.min(root.screenIds.length - 1, currentScreenIndex + 1);
            zynthian.current_screen_id = root.screenIds[newIndex];
            return true;
        case "SWITCH_BACK_SHORT":
        case "SWITCH_BACK_BOLD":
        case "SWITCH_BACK_LONG":
            zynthian.current_screen_id = "layers_for_track";
            zynthian.go_back();
            return true;
        default:
            return false;
        }
    }


    property var screenIds: ["layers_for_track", "bank", "preset"]
    //property var screenTitles: [qsTr("Layers"), qsTr("Banks (%1)").arg(zynthian.bank.effective_count), qsTr("Presets (%1)").arg(zynthian.preset.effective_count)]
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
            RowLayout {
                Layout.fillWidth: true
                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 2
                    text: qsTr("Track %1 Sounds").arg(zynthian.session_dashboard.selectedTrack+1)
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                    Layout.preferredHeight: favModeButton.height
                }
            }
            Zynthian.SelectorView {
                id: layersView
                Layout.fillWidth: true
                Layout.fillHeight: true
                screenId: "layers_for_track"

                property QtObject selectedTrack: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)

                onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                onItemActivated: root.itemActivated(screenId, index)
                onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
                delegate: Zynthian.SelectorDelegate {
                    id: delegate
                    screenId: layersView.screenId
                    selector: layersView.selector
                    readonly property int ownIndex: index
                    highlighted: zynthian.current_screen_id === layersView.screenId
                    onCurrentScreenIdRequested: layersView.currentScreenIdRequested(screenId)
                    onItemActivated: layersView.itemActivated(screenId, index)
                    onItemActivatedSecondary: layersView.itemActivatedSecondary(screenId, index)
                    //visible: (model.display === "-" && y+layersView.view.originY < layersView.view.height) ||
                     //   layersView.selectedTrack.chainedSounds.indexOf(index) !== -1
                    /*layersView.selectedTrack.connectedSound == index || model.metadata.midi_cloned_to.indexOf(layersView.selectedTrack.connectedSound) !== -1*/
                    height: layersView.view.height/5
                    onClicked: {
                        if (!zynthian.fixed_layers.current_index_valid) {
                            layerSetupDialog.open();
                            delegate.selector.activate_index(index);
                        }
                    }
                    function toggleCloned() {
                        if (model.metadata.midi_cloned) {
                            zynthian.layer.remove_clone_midi(model.metadata.midi_channel, model.metadata.midi_channel + 1);
                            zynthian.layer.remove_clone_midi(model.metadata.midi_channel + 1, model.metadata.midi_channel);
                        } else {
                            zynthian.layer.clone_midi(model.metadata.midi_channel, model.metadata.midi_channel + 1);
                            zynthian.layer.clone_midi(model.metadata.midi_channel + 1, model.metadata.midi_channel);
                        }
                        zynthian.layer.ensure_contiguous_cloned_layers();
                    }
                    contentItem: ColumnLayout {
                        RowLayout {
                            QQC2.Label {
                                id: mainLabel
                                Layout.fillWidth: true
                                text: visible
                                    ? (model.metadata ? model.metadata.midi_channel + 1 + " - " + model.display : "")
                                    : ""
                                elide: Text.ElideRight
                            }
                            QQC2.Label {
                                function constructText() {
                                    let text = "";
                                    if (model.metadata && model.metadata.note_high < 60) {
                                        text = "L";
                                    } else if (model.metadata && model.metadata.note_low >= 60) {
                                        text = "H";
                                    }
                                    if (model.metadata && model.metadata.octave_transpose !== 0) {
                                        if (model.metadata.octave_transpose > 0) {
                                            text += "+"
                                        }
                                        text += model.metadata.octave_transpose;
                                    }
                                    return text;
                                }
                                text: visible ? constructText() : ""
                            }
                            QQC2.Button {
                                icon.name: "configure"
                                visible: model.display != "-"
                                onClicked: {
                                    //delegate.clicked();
                                    optionsMenu.open();
                                }
                                QQC2.Menu {
                                    id: optionsMenu
                                    y: parent.height
                                    modal: true
                                    dim: false
                                    QQC2.MenuItem {
                                        width: parent.width
                                        text: qsTr("Change Synth...")
                                        onClicked: {
                                            optionsMenu.close();
                                            delegate.clicked();
                                            zynthian.layer.select_engine(model.metadata.midi_channel);
                                        }
                                    }
                                    QQC2.MenuItem {
                                        width: parent.width
                                        text: qsTr("Range && Transpose...")
                                        onClicked: {
                                            optionsMenu.close();
                                            delegate.clicked();
                                            zynthian.current_modal_screen_id = "midi_key_range";
                                        }
                                    }
                                    QQC2.MenuItem {
                                        width: parent.width
                                        text: qsTr("Add Audio FX...")
                                        onClicked: {
                                            optionsMenu.close();
                                            delegate.clicked();
                                            zynthian.layer_options.show();
                                            zynthian.current_screen_id = "layer_effects";
                                        }
                                    }
                                    QQC2.MenuItem {
                                        width: parent.width
                                        text: qsTr("Add Midi FX...")
                                        onClicked: {
                                            optionsMenu.close();
                                            delegate.clicked();
                                            zynthian.layer_options.show();
                                            zynthian.current_screen_id = "layer_midi_effects";
                                        }
                                    }
                                    QQC2.MenuItem {
                                        width: parent.width
                                        text: qsTr("Layer Options...")
                                        onClicked: {
                                            optionsMenu.close();
                                            delegate.clicked();
                                            let oldCurrent_screen_id = zynthian.current_screen_id;
                                            delegate.selector.current_index = delegate.ownIndex;
                                            delegate.selector.activate_index_secondary(delegate.ownIndex);
                                            delegate.itemActivatedSecondary(delegate.screenId, delegate.ownIndex);
                                            if (zynthian.current_screen_id === oldCurrent_screen_id) {
                                                delegate.currentScreenIdRequested(screenId);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            id: fxLayout
                            implicitWidth: fxLayout.implicitWidth
                            implicitHeight: fxLayout.implicitHeight
                            Layout.fillWidth: true

                            /* QQC2.Label {
                                text: "|"
                                opacity: (model.metadata.midi_channel >= 5 && model.metadata.midi_channel <= 9) || model.metadata.midi_cloned
                            }*/
                            QQC2.Label {
                                Layout.fillWidth: true
                                font.pointSize: mainLabel.font.pointSize * 0.9
                                text: model.metadata && model.metadata.effects_label.length > 0 ? model.metadata.effects_label : "- -"
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
        StackLayout {
            id: middleColumnStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: 1
            Layout.preferredWidth: 1
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                RowLayout {
                    Kirigami.Heading {
                        id: banksHeading
                        Layout.fillWidth: true
                        level: 2
                        text: visible ? qsTr("Banks (%1)").arg(zynthian.bank.effective_count) : "";
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                    }
                    QQC2.Button {
                        id: favModeButton
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
                    id: bankView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    screenId: "bank"
                    onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                    onItemActivated: root.itemActivated(screenId, index)
                    onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
                    delegate: Zynthian.SelectorDelegate {
                        text: model.display === "None" ? qsTr("Single Presets") : model.display
                        screenId: bankView.screenId
                        selector: bankView.selector
                        highlighted: zynthian.current_screen_id === bankView.screenId
                        onCurrentScreenIdRequested: bankView.currentScreenIdRequested(screenId)
                        onItemActivated: bankView.itemActivated(screenId, index)
                        onItemActivatedSecondary: bankView.itemActivatedSecondary(screenId, index)
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                RowLayout {
                    Layout.fillWidth: true
                    Kirigami.Heading {
                        Layout.fillWidth: true
                        level: 2
                        text: qsTr("Mixer")
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                    }
                    QQC2.Button {
                        text: qsTr("Close")
                        onClicked: middleColumnStack.currentIndex = 0
                    }
                }
                Zynthian.Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentItem: ColumnLayout {
                        spacing: 0
                        Repeater {
                            model: root.isVisible ? zynthian.layers_for_track.volume_controls : []
                            delegate: ColumnLayout {
                                Layout.preferredHeight: parent.height/5
                                spacing: Kirigami.Units.largeSpacing
                                enabled: modelData.value_max > 0
                                QQC2.Slider {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Kirigami.Units.gridUnit
                                    enabled: modelData.controllable
                                    onVisibleChanged: modelData.refresh()
                                    value: modelData.value
                                    orientation: Qt.Horizontal
                                    stepSize: modelData.step_size
                                    from: modelData.value_min
                                    to: modelData.value_max
                                    onMoved: {
                                        modelData.value = value;
                                    }
                                }
                                QQC2.Label {
                                    Layout.alignment: Qt.AlignCenter
                                    opacity: modelData.value_max > 0
                                    text: {
                                        // Heuristic: convert the values from 0-127 to 0-100
                                        if (modelData.value_min === 0 && modelData.value_max === 127) {
                                            return Math.round(100 * (modelData.value / 127));
                                        } else if (modelData.value_min === 0 && modelData.value_max === 1) {
                                            return Math.round(100 * modelData.value);
                                        } else if (modelData.value_min === 0 && modelData.value_max === 200) {
                                            return Math.round(100 * (modelData.value / 200));
                                        } else {
                                            return modelData.value;
                                        }
                                    }
                                }
                            }
                        }
                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: 1
            Layout.preferredWidth: 1
            RowLayout {
                Kirigami.Heading {
                    id: presetHeading
                    Layout.fillWidth: true
                    level: 2
                    text: visible ? qsTr("Presets (%1)").arg(zynthian.preset.effective_count) : "";
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                }
                QQC2.Button {
                    id: favToggleButton
                    icon.name: zynthian.preset.current_is_favorite ? "starred-symbolic" : "non-starred-symbolic"
                    text: qsTr("Toggle")
                    LayoutMirroring.enabled: true
                    LayoutMirroring.childrenInherit: true
                    onClicked: {
                        zynthian.preset.current_is_favorite = !zynthian.preset.current_is_favorite;
                        zynthian.current_screen_id = "preset";
                    }
                    MouseArea { //HACK: try to enlarge hit area a bit, probably useless
                        anchors {
                            fill: parent
                            leftMargin: -16
                            topMargin: -16
                            rightMargin: -16
                        }
                        onClicked: {
                            zynthian.preset.current_is_favorite = !zynthian.preset.current_is_favorite;
                            zynthian.current_screen_id = "preset";
                        }
                    }
                }
            }
            Zynthian.SelectorView {
                id: presetView
                implicitHeight: 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                screenId: "preset"
                onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                onItemActivated: root.itemActivated(screenId, index)
                onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
            }
        }


        Connections {
            target: zynthian
            onActive_midi_channelChanged: presetSyncPosTimer.restart()
        }
        Timer {
            id: presetSyncPosTimer
            interval: 100
            onTriggered: {
                presetView.view.positionViewAtIndex(presetView.view.currentIndex, ListView.SnapPosition)
                presetView.view.contentY-- //HACK: workaround for Qt 5.11 ListView sometimes not reloading its items after positionViewAtIndex
                presetView.view.forceLayout()
            }
        }
        Connections {
            target: applicationWindow()
            property int lastCurrentIndex
            property bool currentIndexWasValid
            onRequestOpenLayerSetupDialog: layerSetupDialog.open()
            onRequestCloseLayerSetupDialog: layerSetupDialog.reject()
        }

        QQC2.Dialog {
            id: layerSetupDialog
            parent: applicationWindow().contentItem
            x: Math.round(parent.width/2 - width/2)
            y: Math.round(parent.height/2 - height/2)
            height: footer.implicitHeight + topMargin + bottomMargin
            modal: true

            onAccepted: {
                applicationWindow().layerSetupDialogAccepted();
            }
            onRejected: {
                applicationWindow().layerSetupDialogRejected();
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
                        text: qsTr("Pick a Synth")
                        onClicked: {
                            layerSetupDialog.accept();
                            newSynthWorkaroundTimer.restart();
                            applicationWindow().layerSetupDialogNewSynthClicked();
                        }
                    }
                    QQC2.Button {
                        property QtObject selectedTrack: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        visible: selectedTrack.checkIfLayerExists(zynthian.active_midi_channel)
                        text: qsTr("Change preset")
                        onClicked: {
                            zynthian.current_screen_id = "preset"

                            layerSetupDialog.accept();
                            applicationWindow().layerSetupDialogChangePresetClicked();
                        }
                    }
                    QQC2.Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        text: qsTr("Load A Sound")
                        onClicked: {
//                            pickerDialog.mode = "sound";
//                            pickerDialog.open();
                            zynthian.show_modal("sound_categories")

                            layerSetupDialog.accept();
                            applicationWindow().layerSetupDialogLoadSoundClicked();
                        }
                    }
                    // As per #299 Hide "Pick Existing.." from new synth popup
                    /*QQC2.Button {
                        id: pickExistingButton
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        text: qsTr("Pick Existing...")
                        onClicked: {
                            applicationWindow().openSoundsDialog();
                            layerSetupDialog.accept();
                            applicationWindow().layerSetupDialogPickSoundClicked();
                        }
                    }*/
                    Timer { //HACK why is this necessary?
                        id: newSynthWorkaroundTimer
                        interval: 200
                        onTriggered: {
                            zynthian.layer.page_after_layer_creation = zynthian.current_screen_id;
                            zynthian.layer.select_engine(zynthian.fixed_layers.index_to_midi(zynthian.fixed_layers.current_index))
                            layerSetupDialog.accept();
                        }
                    }
                }
            }
        }

        Zynthian.FilePickerDialog {
            id: saveDialog
            property string mode: "sound"

            conflictMessageLabel.visible: saveDialog.mode === "soundset" ? zynthian.layer.soundset_file_exists(fileNameToSave) : zynthian.layer.layer_file_exists(fileNameToSave);
            headerText: saveDialog.mode === "soundset" ? qsTr("Save a Soundset file") : qsTr("Save a Sound file")
            rootFolder: "/zynthian/zynthian-my-data/"
            noFilesMessage: saveDialog.mode === "soundset" ? qsTr("No Soundsets present") : qsTr("No sounds present")
            folderModel {
                nameFilters: [saveDialog.mode === "soundset" ? "*.soundset" : "*.*.sound"]
            }
            onVisibleChanged: folderModel.folder = rootFolder + (saveDialog.mode === "soundset" ? "soundsets/my-soundsets/" : "sounds/my-sounds/")

            filePropertiesComponent: Flow {
                Repeater {
                    id: infoRepeater
                    model: saveDialog.currentFileInfo
                        ? (saveDialog.mode === "soundset"
                            ? zynthian.layer.soundset_metadata_from_file(saveDialog.currentFileInfo.filePath)
                            : zynthian.layer.sound_metadata_from_file(saveDialog.currentFileInfo.filePath))
                        : []
                    delegate: QQC2.Label {
                        width: modelData.preset_name ? parent.width - 10 : implicitWidth
                        elide: Text.ElideRight
                        font.pointSize: modelData.preset_name ? Kirigami.Theme.font.pointSize : 9
                        text: {
                            var name = modelData.name;
                            if (modelData.preset_name) {
                                name = "• " + name + ">" + modelData.preset_name;
                            } else {
                                name = "    " + name;
                            }
                            return name;
                        }
                    }
                }
            }

            filesListView.delegate: Kirigami.BasicListItem {
                width: ListView.view.width
                highlighted: ListView.isCurrentItem

                property bool isCurrentItem: ListView.isCurrentItem
                onIsCurrentItemChanged: {
                    if (isCurrentItem) {
                        saveDialog.currentFileInfo = model;
                    }
                }
                label: model.fileName
                icon: model.fileIsDir ? "folder" : "emblem-music-symbolic"
                QQC2.Label {
                    visible: saveDialog.mode === "sound"
                    text: {
                        let parts = model.fileName.split(".");
                        if (parts.length < 2) {
                            return ""
                        }
                        let num = Number(parts[1])
                        if (num < 2) {
                            return ""
                        } else {
                            return qsTr("%1 Synths").arg(num);
                        }
                    }
                }
                onClicked: saveDialog.filesListView.selectItem(model)
            }

            onFileSelected: {
                console.log(file.filePath);
                if (mode === "soundset") {
                    zynthian.layer.save_soundset_to_file(file.filePath);
                } else { //Sound
                    zynthian.layer.save_curlayer_to_file(file.filePath);
                }
            }

            saveMode: true
        }

        Zynthian.FilePickerDialog {
            id: pickerDialog
            parent: root
            property string mode: "sound"

            headerText: pickerDialog.mode === "soundset" ? qsTr("Pick a Soundset file") : qsTr("Pick a Sound file")
            rootFolder: "/zynthian/zynthian-my-data/"
            folderModel {
                nameFilters: [(pickerDialog.mode === "soundset" ? "*.soundset" : "*.*." + pickerDialog.mode)]
            }

            filePropertiesComponent: Flow {
                Repeater {
                    id: infoRepeater
                    model: pickerDialog.currentFileInfo
                        ? (pickerDialog.mode === "soundset"
                            ? zynthian.layer.soundset_metadata_from_file(pickerDialog.currentFileInfo.filePath)
                            : zynthian.layer.sound_metadata_from_file(pickerDialog.currentFileInfo.filePath))
                        : []
                    delegate: QQC2.Label {
                        width: modelData.preset_name ? parent.width - 10 : implicitWidth
                        elide: Text.ElideRight
                        font.pointSize: modelData.preset_name ? Kirigami.Theme.font.pointSize : 9
                        text: {
                            var name = modelData.name;
                            if (modelData.preset_name) {
                                name = "• " + name + ">" + modelData.preset_name;
                            } else {
                                name = "    " + name;
                            }
                            return name;
                        }
                    }
                }
            }

            onVisibleChanged: folderModel.folder = rootFolder + (pickerDialog.mode === "soundset" ? "soundsets/" : "sounds/")
            filesListView.delegate: Kirigami.BasicListItem {
                width: ListView.view.width
                highlighted: ListView.isCurrentItem

                property bool isCurrentItem: ListView.isCurrentItem
                onIsCurrentItemChanged: {
                    if (isCurrentItem) {
                        pickerDialog.currentFileInfo = model;
                    }
                }
                label: model.fileName
                icon: model.fileIsDir ? "folder" : "emblem-music-symbolic"
                QQC2.Label {
                    visible: pickerDialog.mode === "sound"
                    text: {
                        let parts = model.fileName.split(".");
                        if (parts.length < 2) {
                            return ""
                        }
                        let num = Number(parts[1])
                        if (num < 2) {
                            return ""
                        } else {
                            return qsTr("%1 Synths").arg(num);
                        }
                    }
                }
                onClicked: pickerDialog.filesListView.selectItem(model)
            }
            onFileSelected: {
                console.log(file.filePath);
                if (pickerDialog.mode === "soundset") {
                    zynthian.layer.load_soundset_from_file(file.filePath)
                } else {
                    //zynthian.layer.load_layer_from_file(file.filePath)
                    layerReplaceDialog.sourceChannels = zynthian.layer.load_layer_channels_from_file(file.filePath);
                    if (layerReplaceDialog.sourceChannels.length > 1) {
                        layerReplaceDialog.fileToLoad = file.filePath;
                        layerReplaceDialog.open();
                    } else {
                        let map = {}
                        map[layerReplaceDialog.sourceChannels[0].toString()] = zynthian.fixed_layers.index_to_midi(zynthian.fixed_layers.current_index);
                        zynthian.layer.load_layer_from_file(file.filePath, map);
                    }
                }
                zynthian.bank.show_top_sounds = false;
                pickerDialog.accept()
            }
        }

        Zynthian.LayerReplaceDialog {
            id: layerReplaceDialog
            parent: root.parent
            modal: true
            x: Math.round(parent.width/2 - width/2)
            y: Math.round(parent.height/2 - height/2)
            height: contentItem.implicitHeight + header.implicitHeight + footer.implicitHeight + topMargin + bottomMargin + Kirigami.Units.smallSpacing
            footerLeftPadding: saveDialog.leftPadding
            footerRightPadding: saveDialog.rightPadding
            footerBottomPadding: saveDialog.bottomPadding
        }
    }
}


