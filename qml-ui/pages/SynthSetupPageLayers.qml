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
        onTriggered: {}
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
                enabled: zynqtgui.main_layers_view.current_index_valid
                onTriggered: {
                    saveDialog.mode = "sound";
                    saveDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Get New Sounds...")
                onTriggered: zynqtgui.show_modal("sound_downloader")
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
                text: qsTr("Get New Soundsets...")
                onTriggered: zynqtgui.show_modal("soundset_downloader")
            }
            Kirigami.Action {
                text: qsTr("Clear Sound")
                enabled: zynqtgui.main_layers_view.current_index_valid
                onTriggered: zynqtgui.layer.ask_remove_current_layer()
            }
            Kirigami.Action {
                text: qsTr("Clear Block")
                enabled: zynqtgui.main_layers_view.current_index_valid
                onTriggered: zynqtgui.main_layers_view.ask_clear_visible_range()
            }
            Kirigami.Action {
                text: qsTr("Clear All")
                onTriggered: zynqtgui.layer.ask_reset()
            }
        },
        Kirigami.Action {
            text: qsTr("Slot")
            Kirigami.Action {
                text: qsTr("Synths")
                onTriggered: {
                    zynqtgui.layer.select_engine(zynqtgui.main_layers_view.active_midi_channel)
                }
            }
            Kirigami.Action {
                text: qsTr("Effect Layer")
                onTriggered: {
                    zynqtgui.layer.new_effect_layer(zynqtgui.main_layers_view.active_midi_channel)
                }
            }
            Kirigami.Action {
                text: qsTr("Audio-FX")
                enabled: zynqtgui.main_layers_view.current_index_valid
                onTriggered: {
                    zynqtgui.layer_options.show(); //FIXME: that show() method should change name
                    zynqtgui.current_screen_id = "layer_effects";
                }
            }
            Kirigami.Action {
                text: qsTr("Remove All Audio-FX")
                enabled: zynqtgui.main_layers_view.current_index_valid
                onTriggered: {
                    zynqtgui.layer_effects.fx_reset()
                }
            }
            Kirigami.Action {
                text: qsTr("MIDI-FX")
                enabled: zynqtgui.main_layers_view.current_index_valid
                onTriggered: {
                    zynqtgui.layer_options.show() //FIXME: that show() method should change name
                    zynqtgui.current_screen_id = "layer_midi_effects";
                }
            }
            Kirigami.Action {
                text: qsTr("Remove All MIDI-FX")
                enabled: zynqtgui.main_layers_view.current_index_valid
                onTriggered: {
                    zynqtgui.layer_midi_effects.fx_reset()
                }
            }
        },
        Kirigami.Action {
            text: qsTr("Edit")
            onTriggered: {
                zynqtgui.control.single_effect_engine = null;
                zynqtgui.current_screen_id = "control";
            }
        }
    ]


    cuiaCallback: function(cuia) {
        let currentScreenIndex = root.screenIds.indexOf(zynqtgui.current_screen_id);
        layerSetupDialog.close(); // Close the new layer popup at any keyboard interaction

        switch (cuia) {
        case "NAVIGATE_LEFT":
            var newIndex = Math.max(0, currentScreenIndex - 1);
            zynqtgui.current_screen_id = root.screenIds[newIndex];
            return true;
        case "NAVIGATE_RIGHT":
            var newIndex = Math.min(root.screenIds.length - 1, currentScreenIndex + 1);
            zynqtgui.current_screen_id = root.screenIds[newIndex];
            return true;
        case "SWITCH_BACK_SHORT":
        case "SWITCH_BACK_BOLD":
            zynqtgui.current_screen_id = "main_layers_view";
            zynqtgui.go_back();
            return true;
        default:
            return false;
        }
    }


    property var screenIds: ["main_layers_view", "bank", "preset"]
    //property var screenTitles: [qsTr("Layers"), qsTr("Banks (%1)").arg(zynqtgui.bank.effective_count), qsTr("Presets (%1)").arg(zynqtgui.preset.effective_count)]
    previousScreen: "main"
    onCurrentScreenIdRequested: {
        //don't remove modal screens
        if (zynqtgui.current_modal_screen_id.length === 0) {
            zynqtgui.current_screen_id = screenId;
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
                QQC2.Button {
                    Layout.fillWidth: true
                    implicitWidth: 1
                    text: qsTr("1 - 5")
                    checkable: true
                    checked: zynqtgui.main_layers_view.start_midi_chan === 0
                    autoExclusive: true
                    onToggled: {
                        if (checked) {
                            zynqtgui.main_layers_view.start_midi_chan = 0;
                            zynqtgui.main_layers_view.activate_index(0);
                        }
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    text: qsTr("6.x")
                    implicitWidth: 1
                    checkable: true
                    checked: zynqtgui.main_layers_view.start_midi_chan === 5
                    autoExclusive: true
                    onToggled: {
                        if (checked) {
                            zynqtgui.main_layers_view.start_midi_chan = 5;
                            zynqtgui.main_layers_view.activate_index(0);
                        }
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    text: qsTr("11-15")
                    implicitWidth: 1
                    checkable: true
                    checked: zynqtgui.main_layers_view.start_midi_chan === 10
                    autoExclusive: true
                    onToggled: {
                        if (checked) {
                            zynqtgui.main_layers_view.start_midi_chan = 10;
                            zynqtgui.main_layers_view.activate_index(0);
                        }
                    }
                }
                QQC2.Button {
                    implicitWidth: Math.round(parent.width/3.2)
                    text: "|"
                    enabled: zynqtgui.main_layers_view.start_midi_chan !== 5 && layersView.view.currentIndex < layersView.view.count - 1
                    onClicked: {
                        if (layersView.view.currentItem) {
                            layersView.view.currentItem.toggleCloned();
                        }
                    }
                }
            }
            Zynthian.SelectorView {
                id: layersView
                Layout.fillWidth: true
                Layout.fillHeight: true
                screenId: "main_layers_view"
                onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                onItemActivated: root.itemActivated(screenId, index)
                onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
                delegate: Zynthian.SelectorDelegate {
                    id: delegate
                    screenId: layersView.screenId
                    selector: layersView.selector
                    readonly property int ownIndex: index
                    highlighted: zynqtgui.current_screen_id === layersView.screenId
                    onCurrentScreenIdRequested: layersView.currentScreenIdRequested(screenId)
                    onItemActivated: layersView.itemActivated(screenId, index)
                    onItemActivatedSecondary: layersView.itemActivatedSecondary(screenId, index)
                    function toggleCloned() {
                        if (model.metadata.midi_cloned) {
                            zynqtgui.layer.remove_clone_midi(model.metadata.midi_channel, model.metadata.midi_channel + 1);
                            zynqtgui.layer.remove_clone_midi(model.metadata.midi_channel + 1, model.metadata.midi_channel);
                        } else {
                            zynqtgui.layer.clone_midi(model.metadata.midi_channel, model.metadata.midi_channel + 1);
                            zynqtgui.layer.clone_midi(model.metadata.midi_channel + 1, model.metadata.midi_channel);
                        }
                        zynqtgui.layer.ensure_contiguous_cloned_layers();
                    }
                    contentItem: ColumnLayout {
                        RowLayout {
                            QQC2.Label {
                                id: mainLabel
                                Layout.fillWidth: true
                                text: {
                                    let numPrefix = model.metadata.midi_channel + 1;
                                    if (numPrefix > 5 && numPrefix <= 10) {
                                        numPrefix = "6." + (numPrefix - 5);
                                    }
                                    return numPrefix + " - " + model.display;
                                }
                                elide: Text.ElideRight
                            }
                            QQC2.Label {
                                text: {
                                    let text = "";
                                    if (model.metadata.note_high < 60) {
                                        text = "L";
                                    } else if (model.metadata.note_low >= 60) {
                                        text = "H";
                                    }
                                    if (model.metadata.octave_transpose !== 0) {
                                        if (model.metadata.octave_transpose > 0) {
                                            text += "+"
                                        }
                                        text += model.metadata.octave_transpose;
                                    }
                                    return text;
                                }
                            }
                            QQC2.Button {
                                icon.name: "configure"
                                visible: model.display != "-"
                                onClicked: {
                                    delegate.clicked();
                                    optionsMenu.open();
                                }
                                QQC2.Menu {
                                    id: optionsMenu
                                    y: parent.height
                                    modal: true
                                    dim: false
                                    QQC2.MenuItem {
                                        width: parent.width
                                        text: qsTr("Range && Transpose...")
                                        onClicked: zynqtgui.current_modal_screen_id = "midi_key_range";
                                    }
                                    QQC2.MenuItem {
                                        width: parent.width
                                        text: qsTr("Add Audio FX...")
                                        onClicked: {
                                            zynqtgui.layer_options.show();
                                            zynqtgui.current_screen_id = "layer_effects";
                                        }
                                    }
                                    QQC2.MenuItem {
                                        width: parent.width
                                        text: qsTr("Add Midi FX...")
                                        onClicked: {
                                            zynqtgui.layer_options.show();
                                            zynqtgui.current_screen_id = "layer_midi_effects";
                                        }
                                    }
                                    QQC2.MenuItem {
                                        width: parent.width
                                        text: qsTr("Layer Options...")
                                        onClicked: {
                                            let oldCurrent_screen_id = zynqtgui.current_screen_id;
                                            delegate.selector.current_index = delegate.ownIndex;
                                            delegate.selector.activate_index_secondary(delegate.ownIndex);
                                            delegate.itemActivatedSecondary(delegate.screenId, delegate.ownIndex);
                                            if (zynqtgui.current_screen_id === oldCurrent_screen_id) {
                                                delegate.currentScreenIdRequested(screenId);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        MouseArea {
                            implicitWidth: fxLayout.implicitWidth
                            implicitHeight: fxLayout.implicitHeight
                            Layout.fillWidth: true
                            enabled: index < layersView.view.count - 1
                            Rectangle {
                                anchors {
                                    fill: parent
                                    margins: -Kirigami.Units.smallSpacing
                                }
                                radius: 3
                                color: layersView.currentIndex == index ? Kirigami.Theme.backgroundColor : Kirigami.Theme.highlightColor
                                opacity: parent.pressed ? 0.4 : 0
                            }
                            onPressAndHold: {
                                delegate.toggleCloned();
                                delegate.clicked();
                            }
                            onClicked: delegate.clicked();
                            RowLayout {
                                id: fxLayout
                                anchors.fill: parent
                                QQC2.Label {
                                    text: "|"
                                    opacity: (model.metadata.midi_channel >= 5 && model.metadata.midi_channel <= 9) || model.metadata.midi_cloned
                                }
                                QQC2.Label {
                                    Layout.fillWidth: true
                                    font.pointSize: mainLabel.font.pointSize * 0.9
                                    text: model.metadata.effects_label.length > 0 ? model.metadata.effects_label : "- -"
                                    elide: Text.ElideRight
                                }
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
                        Layout.fillWidth: true
                        level: 2
                        text: qsTr("Banks (%1)").arg(zynqtgui.bank.effective_count)
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                    }
                    QQC2.Button {
                        id: favModeButton
                        text: qsTr("Fav-Mode")
                        checkable: true
                        checked: zynqtgui.bank.show_top_sounds
                        onToggled: {
                            zynqtgui.bank.show_top_sounds = checked;
                            zynqtgui.current_screen_id = "bank";
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
                        text: model.display === "None" ? qsTr("Single") : model.display
                        screenId: bankView.screenId
                        selector: bankView.selector
                        highlighted: zynqtgui.current_screen_id === bankView.screenId
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
                            model: zynqtgui.main_layers_view.volumeControllers
                            delegate: ColumnLayout {
                                spacing: Kirigami.Units.largeSpacing
                                enabled: modelData.value_max > 0
                                QQC2.Slider {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Kirigami.Units.gridUnit
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
                    Layout.fillWidth: true
                    level: 2
                    text: qsTr("Presets (%1)").arg(zynqtgui.preset.effective_count)
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                }
                QQC2.Button {
                    id: favToggleButton
                    icon.name: zynqtgui.preset.current_is_favorite ? "starred-symbolic" : "non-starred-symbolic"
                    text: qsTr("Toggle")
                    LayoutMirroring.enabled: true
                    LayoutMirroring.childrenInherit: true
                    onClicked: {
                        zynqtgui.preset.current_is_favorite = !zynqtgui.preset.current_is_favorite;
                        zynqtgui.current_screen_id = "preset";
                    }
                    MouseArea { //HACK: try to enlarge hit area a bit, probably useless
                        anchors {
                            fill: parent
                            leftMargin: -16
                            topMargin: -16
                            rightMargin: -16
                        }
                        onClicked: {
                            zynqtgui.preset.current_is_favorite = !zynqtgui.preset.current_is_favorite;
                            zynqtgui.current_screen_id = "preset";
                        }
                    }
                }
            }
            Zynthian.SelectorView {
                id: presetView
                Layout.fillWidth: true
                Layout.fillHeight: true
                screenId: "preset"
                onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                onItemActivated: root.itemActivated(screenId, index)
                onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
            }
        }


        Connections {
            target: zynqtgui
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
            target: zynqtgui.main_layers_view
            onCurrent_index_validChanged: {
                if (!zynqtgui.main_layers_view.current_index_valid) {
                    if (zynqtgui.current_screen_id !== "layer" &&
                        zynqtgui.current_screen_id !== "fixed_layers" &&
                        zynqtgui.current_screen_id !== "main_layers_view" &&
                        zynqtgui.current_screen_id !== "bank" &&
                        zynqtgui.current_screen_id !== "confirm" &&
                        zynqtgui.current_screen_id !== "preset") {
                        layerSetupDialog.open();
                    }
                } else {
                    layerSetupDialog.close();
                }
            }
        }

        Zynthian.Dialog {
            id: layerSetupDialog
            parent: applicationWindow().contentItem
            x: Math.round(parent.width/2 - width/2)
            y: Math.round(parent.height/2 - height/2)
            height: footer.implicitHeight + topMargin + bottomMargin
            modal: true

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
                        onTriggered: zynqtgui.layer.select_engine(zynqtgui.main_layers_view.index_to_midi(zynqtgui.main_layers_view.current_index))

                    }
                }
            }
        }

        Zynthian.FilePickerDialog {
            id: saveDialog
            property string mode: "sound"

            conflictMessageLabel.visible: saveDialog.mode === "soundset" ? zynqtgui.layer.soundset_file_exists(fileNameToSave) : zynqtgui.layer.layer_file_exists(fileNameToSave);
            headerText: saveDialog.mode === "soundset" ? qsTr("Save a Soundset file") : qsTr("Save a Sound file")
            rootFolder: "/zynthian/zynthian-my-data/"
            noFilesMessage: saveDialog.mode === "soundset" ? qsTr("No Soundsets present") : qsTr("No sounds present")
            folderModel {
                nameFilters: [saveDialog.mode === "soundset" ? "*.soundset" : "*.*.sound"]
            }
            onVisibleChanged: folderModel.folder = rootFolder + (saveDialog.mode === "soundset" ? "soundsets/" : "sounds/")

            filePropertiesComponent: Flow {
                Repeater {
                    id: infoRepeater
                    model: saveDialog.currentFileInfo
                        ? (saveDialog.mode === "soundset"
                            ? zynqtgui.layer.soundset_metadata_from_file(saveDialog.currentFileInfo.fileName)
                            : zynqtgui.layer.sound_metadata_from_file(saveDialog.currentFileInfo.fileName))
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

            onAccepted: {
                console.log(saveDialog.selectedFile.filePath);
                if (mode === "soundset") {
                    zynqtgui.layer.save_soundset_to_file(saveDialog.selectedFile.fileName);
                } else { //Sound
                    zynqtgui.layer.save_curlayer_to_file(saveDialog.selectedFile.fileName);
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
                            ? zynqtgui.layer.soundset_metadata_from_file(pickerDialog.currentFileInfo.fileName)
                            : zynqtgui.layer.sound_metadata_from_file(pickerDialog.currentFileInfo.fileName))
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
            onAccepted: {
                console.log(pickerDialog.selectedFile.filePath);
                if (pickerDialog.mode === "soundset") {
                    zynqtgui.layer.load_soundset_from_file(pickerDialog.selectedFile.filePath)
                } else {
                    //zynqtgui.layer.load_layer_from_file(pickerDialog.selectedFile.filePath)
                    layerReplaceDialog.sourceChannels = zynqtgui.layer.load_layer_channels_from_file(pickerDialog.selectedFile.filePath);
                    if (layerReplaceDialog.sourceChannels.length > 1) {
                        layerReplaceDialog.fileToLoad = pickerDialog.selectedFile.filePath;
                        layerReplaceDialog.open();
                    } else {
                        let map = {}
                        map[layerReplaceDialog.sourceChannels[0].toString()] = zynqtgui.main_layers_view.index_to_midi(zynqtgui.main_layers_view.current_index);
                        zynqtgui.layer.load_layer_from_file(pickerDialog.selectedFile.filePath, map);
                    }
                }
                zynqtgui.bank.show_top_sounds = false;
                pickerDialog.accept()
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
                zynqtgui.layer.load_layer_from_file(fileToLoad, map);
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
                    text: qsTr("The selected sound has %1 layers: select %1 adjacent layers that should be replaced by them.").arg(layerReplaceDialog.sourceChannels.length)
                }
                Repeater {
                    id: channelReplaceRepeater
                    model: zynqtgui.main_layers_view.selector_list
                    delegate: QQC2.RadioButton {
                        id: delegate
                        enabled: channelReplaceRepeater.count - index >= layerReplaceDialog.sourceChannels.length
                        autoExclusive: true
                        onCheckedChanged: {
                            layerReplaceDialog.destinationChannels = [];
                            var i = 0;
                            let chan = model.metadata.midi_channel
                            for (i in layerReplaceDialog.sourceChannels) {
                                layerReplaceDialog.destinationChannels.push(chan);
                                chan++;
                            }
                            layerReplaceDialog.destinationChannelsChanged();
                            layerReplaceDialog.sourceChannelsChanged();
                        }
                        Connections {
                            target: layerReplaceDialog
                            onFileToLoadChanged: {
                                checked = false
                                checked = index === zynqtgui.main_layers_view.current_index
                            }
                        }
                        indicator.opacity: enabled
                        indicator.x: 0
                        contentItem: RowLayout {
                            Item {
                                Layout.preferredWidth: delegate.indicator.width
                            }
                            QQC2.CheckBox {
                                enabled: false
                                checked: layerReplaceDialog.destinationChannels.indexOf(model.metadata.midi_channel) !== -1
                            }
                            QQC2.Label {
                                text: {
                                    let numPrefix = model.metadata.midi_channel + 1;
                                    if (numPrefix > 5 && numPrefix <= 10) {
                                        numPrefix = "6." + (numPrefix - 5);
                                    }
                                    return numPrefix + " - " + model.display;
                                }
                            }
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


