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

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.ScreenPage {
    id: root

    property bool isVisible: ["layer", "fixed_layers", "main_layers_view", "layers_for_channel", "bank", "preset"].indexOf(zynqtgui.current_screen_id) >= 0
    property QtObject selectedChannel: zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId)

    onSelectedChannelChanged: {
        layerChangeThrottle.restart();
    }
    Timer {
        id: layerChangeThrottle
        interval: 10; running: false; repeat: false;
        onTriggered: {
            zynqtgui.layers_for_channel.activate_index(0)
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
            text: "Save Sound"
            onTriggered: {
                zynqtgui.show_screen("sound_categories")
                applicationWindow().pageStack.getPage("sound_categories").showSaveSoundDialog()
            }
        },
//        Kirigami.Action {
//            text: qsTr("Sounds")
////            Kirigami.Action {
////                text: middleColumnStack.currentIndex === 0 ? qsTr("Show Mixer") : qsTr("Hide Mixer")
////                onTriggered: {
////                    middleColumnStack.currentIndex = middleColumnStack.currentIndex === 0 ? 1 : 0;
////                }
////            }
//            Kirigami.Action {
//                text: qsTr("Load Sound...")
//                onTriggered: {
//                    pickerDialog.mode = "sound";
//                    pickerDialog.open();
//                }
//            }
//            Kirigami.Action {
//                text: qsTr("Save Sound...")
//                enabled: zynqtgui.fixed_layers.current_index_valid
//                onTriggered: {
//                    saveDialog.mode = "sound";
//                    saveDialog.open();
//                }
//            }
//            Kirigami.Action {
//                text: qsTr("Get New Sounds...")
//                onTriggered: zynqtgui.show_modal("sound_downloader")
//            }
//            //Kirigami.Action {
//                //text: qsTr("Get New Soundfonts...")
//                //onTriggered: zynqtgui.show_modal("soundfont_downloader")
//            //}
//            /*Kirigami.Action {
//                text: qsTr("Load Soundset...")
//                onTriggered: {
//                    pickerDialog.mode = "soundset";
//                    pickerDialog.open();
//                }
//            }
//            Kirigami.Action {
//                text: qsTr("Save Soundset...")
//                onTriggered: {
//                    saveDialog.mode = "soundset";
//                    saveDialog.open();
//                }
//            }
//            Kirigami.Action {
//                text: qsTr("Get New Soundsets...")
//                onTriggered: zynqtgui.show_modal("soundset_downloader")
//            }*/
//            /*Kirigami.Action {
//                text: qsTr("Clear Sounds")
//                enabled: zynqtgui.fixed_layers.current_index_valid
//                onTriggered: zynqtgui.fixed_layers.ask_clear_visible_range()
//            }*/
//            /*Kirigami.Action {
//                text: qsTr("Clear All")
//                onTriggered: zynqtgui.layer.ask_reset()
//            }*/
//        },
//        Kirigami.Action {
//            text: qsTr("Slot")
//            Kirigami.Action {
//                text: qsTr("Synths")
//                onTriggered: {
//                    zynqtgui.layer.page_after_layer_creation = "layers_for_channel";
//                    zynqtgui.layer.select_engine(zynqtgui.fixed_layers.active_midi_channel)
//                }
//            }
//            Kirigami.Action {
//                text: qsTr("Remove Synth")
//                enabled: zynqtgui.fixed_layers.current_index_valid
//                onTriggered: zynqtgui.layer.ask_remove_current_layer()
//            }
//            Kirigami.Action {
//                // Disable this entry as per #299
//                visible: false
//                text: qsTr("Effect Layer")
//                onTriggered: {
//                    zynqtgui.layer.new_effect_layer(zynqtgui.fixed_layers.active_midi_channel)
//                }
//            }
//            Kirigami.Action {
//                text: qsTr("Audio-FX")
//                enabled: zynqtgui.fixed_layers.current_index_valid
//                onTriggered: {
//                    zynqtgui.layer_options.show(); //FIXME: that show() method should change name
//                    zynqtgui.current_screen_id = "layer_effects";
//                }
//            }
//            Kirigami.Action {
//                text: qsTr("Remove All Audio-FX")
//                enabled: zynqtgui.fixed_layers.current_index_valid
//                onTriggered: {
//                    zynqtgui.layer_effects.fx_reset()
//                }
//            }
//            Kirigami.Action {
//                text: qsTr("MIDI-FX")
//                enabled: zynqtgui.fixed_layers.current_index_valid
//                onTriggered: {
//                    zynqtgui.layer_options.show() //FIXME: that show() method should change name
//                    zynqtgui.current_screen_id = "layer_midi_effects";
//                }
//            }
//            Kirigami.Action {
//                text: qsTr("Remove All MIDI-FX")
//                enabled: zynqtgui.fixed_layers.current_index_valid
//                onTriggered: {
//                    zynqtgui.layer_midi_effects.fx_reset()
//                }
//            }
//        },
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
        layerSetupDialog.reject(); // Close the new layer popup at any keyboard interaction

//        if (saveDialog.opened) {
//            return saveDialog.cuiaCallback(cuia);
//        } else if (pickerDialog.opened) {
//            return pickerDialog.cuiaCallback(cuia);
//        }

        // Call cuiaCallback of current selectorView
        var selectorCuiaReturnVal = false
        switch(zynqtgui.current_screen_id) {
            case "layers_for_channel":
                selectorCuiaReturnVal = layersView.cuiaCallback(cuia)
                break
            case "bank":
                selectorCuiaReturnVal = bankView.cuiaCallback(cuia)
                break
            case "preset":
                selectorCuiaReturnVal = presetView.cuiaCallback(cuia)
                break
        }
        if (selectorCuiaReturnVal == true) {
            // If selected view returns true, return from here as well since CUIA event is already handled
            return true
        } else {
            var midiChannel = zynqtgui.layers_for_channel.selector_list.getMetadataByIndex(layersView.currentIndex).midi_channel

            // Since CUIA event is not handled by selector view, handle it here
            switch (cuia) {
                case "SCREEN_LAYER":
                case "SCREEN_PRESET":
                    // Switch to Sounds page when library page is open and F2 is pressed again
                    zynqtgui.show_screen("sound_categories")
                    return true;
                case "SWITCH_SELECT_SHORT":
                    if (zynqtgui.current_screen_id == "layers_for_channel" && !zynqtgui.fixed_layers.current_index_valid) {
                        layerSetupDialog.open();
                        return true
                    } else if (zynqtgui.fixed_layers.current_index_valid) {
                        zynqtgui.preset.current_is_favorite = !zynqtgui.preset.current_is_favorite;
                    }
                    return false
                case "SWITCH_SELECT_BOLD":
                    if (zynqtgui.fixed_layers.current_index_valid) {
                        zynqtgui.control.single_effect_engine = null;
                        zynqtgui.current_screen_id = "control";
                        return true
                    }
                    return false
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
                    zynqtgui.current_screen_id = "layers_for_channel";
                    zynqtgui.go_back();
                    return true;
                case "KNOB0_TOUCHED":
                    if (!applicationWindow().osd.opened) {
                        pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlot.value], 0)
                    }
                    return true;
                case "KNOB0_UP":
                    pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlot.value], 1)
                    return true;
                case "KNOB0_DOWN":
                    pageManager.getPage("sketchpad").updateSelectedChannelLayerVolume(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlot.value], -1)
                    return true;
                case "KNOB1_TOUCHED":
                    if (!applicationWindow().osd.opened) {
                        pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(0, root.selectedChannel.selectedSlot.value)
                    }
                    return true;
                case "KNOB1_UP":
                    pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(1, root.selectedChannel.selectedSlot.value)
                    return true;
                case "KNOB1_DOWN":
                    pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerCutoff(-1, root.selectedChannel.selectedSlot.value)
                    return true;
                case "KNOB2_TOUCHED":
                    if (!applicationWindow().osd.opened) {
                        pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(0, root.selectedChannel.selectedSlot.value)
                    }
                    return true;
                case "KNOB2_UP":
                    pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(1, root.selectedChannel.selectedSlot.value)
                    return true;
                case "KNOB2_DOWN":
                    pageManager.getPage("sketchpad").updateSelectedChannelSlotLayerResonance(-1, root.selectedChannel.selectedSlot.value)
                    return true;
                case "SCREEN_EDIT_CONTEXTUAL":
                    if (zynqtgui.fixed_layers.current_index_valid) {
                        zynqtgui.show_screen("control")
                    } else {
                        applicationWindow().showMessageDialog(qsTr("Selected slot is empty. Cannot open edit page."), 2000)
                    }
                    return true;
                default:
                    return false;
            }
        }
    }


    property var screenIds: ["layers_for_channel", "bank", "preset"]
    //property var screenTitles: [qsTr("Layers"), qsTr("Banks (%1)").arg(zynqtgui.bank.effective_count), qsTr("Presets (%1)").arg(zynqtgui.preset.effective_count)]
    previousScreen: "main"
    onCurrentScreenIdRequested: {
        //don't remove modal screens
        if (zynqtgui.current_modal_screen_id.length === 0) {
            zynqtgui.current_screen_id = screenId;
        }
    }
    Connections {
        id: pageChangeHandler
        target: zynqtgui
        onCurrent_screen_idChanged: handlePageChange(zynqtgui.current_screen_id)

        function handlePageChange(page) {
            if (root.screenIds.includes(zynqtgui.current_screen_id)) {
                bankView.forceViewPosition(true)
                presetView.forceViewPosition(true)
            } else {
                zynqtgui.preset.show_only_favorites = false
            }
        }
    }

    contentItem: RowLayout {
        id: layout

        // FIXME : Find a way to correctly expand the columns equally with filLWidth property instead of using manually calculated width value
        property real columnWidth: width / children.length - spacing/2

        spacing: Kirigami.Units.gridUnit

        ColumnLayout {
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: layout.columnWidth
            Zynthian.LibraryPagePicker {
                id: libraryPagePicker
                Layout.fillWidth: true
                libraryName: "synths"
                selectedChannel: root.selectedChannel
            }
            Zynthian.SelectorView {
                id: layersView
                Layout.fillWidth: true
                Layout.fillHeight: true
                screenId: "layers_for_channel"
                // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                active: zynqtgui.isBootingComplete
                autoActivateIndexOnChange: true

                onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                onItemActivated: {
                    if (root.selectedChannel.selectedSlot.value === index) {
                        pageManager.getPage("sketchpad").bottomStack.tracksBar.activateSlot("synth", index);
                    } else {
                        pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("synth", index);
                    }
                    root.itemActivated(screenId, index);
                }
                onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)

                Component.onCompleted: {
                    layersView.background.highlighted = Qt.binding(function() { return zynqtgui.current_screen_id === screenId })
                }
                delegate: Zynthian.SelectorDelegate {
                    id: delegate
                    screenId: layersView.screenId
                    selector: layersView.selector
                    readonly property int ownIndex: index
                    highlighted: zynqtgui.current_screen_id === layersView.screenId
                    onCurrentScreenIdRequested: layersView.currentScreenIdRequested(screenId)
                    onItemActivated: layersView.itemActivated(screenId, index)
                    onItemActivatedSecondary: layersView.itemActivatedSecondary(screenId, index)
                    //visible: (model.display === "-" && y+layersView.view.originY < layersView.view.height) ||
                     //   layersView.selectedChannel.chainedSounds.indexOf(index) !== -1
                    /*layersView.selectedChannel.connectedSound == index || model.metadata.midi_cloned_to.indexOf(layersView.selectedChannel.connectedSound) !== -1*/
                    height: layersView.view.height/5
                    onClicked: {
                        if (!zynqtgui.fixed_layers.current_index_valid) {
                            // layerSetupDialog.open();
                            delegate.selector.activate_index(index);
                        }
                    }
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
                                Binding { // Optimization
                                    target: mainLabel
                                    property: "text"
                                    delayed: true
                                    value: mainLabel.visible
                                        ? (model.metadata ? "%1 - %2".arg(index + 1).arg(model.display) : "")
                                        : ""
//                                    value: mainLabel.visible
//                                        ? (model.metadata ? model.metadata.midi_channel + 1 + " - " + model.display : "")
//                                        : ""
                                }
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
                                text: zynqtgui.isBootingComplete && root.isVisible ? constructText() : ""
                            }
                            QQC2.Button {
                                icon.name: "configure"
                                // visible: model.display != "-"
                                visible: false // Hide configure button for now
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
                                            zynqtgui.layer.select_engine(model.metadata.midi_channel);
                                        }
                                    }
                                    QQC2.MenuItem {
                                        width: parent.width
                                        text: qsTr("Range && Transpose...")
                                        onClicked: {
                                            optionsMenu.close();
                                            delegate.clicked();
                                            zynqtgui.current_modal_screen_id = "midi_key_range";
                                        }
                                    }
                                    QQC2.MenuItem {
                                        width: parent.width
                                        text: qsTr("Add Audio FX...")
                                        onClicked: {
                                            optionsMenu.close();
                                            delegate.clicked();
                                            zynqtgui.layer_options.show();
                                            zynqtgui.current_screen_id = "layer_effects";
                                        }
                                    }
                                    QQC2.MenuItem {
                                        width: parent.width
                                        text: qsTr("Add Midi FX...")
                                        onClicked: {
                                            optionsMenu.close();
                                            delegate.clicked();
                                            zynqtgui.layer_options.show();
                                            zynqtgui.current_screen_id = "layer_midi_effects";
                                        }
                                    }
                                    QQC2.MenuItem {
                                        width: parent.width
                                        text: qsTr("Layer Options...")
                                        onClicked: {
                                            optionsMenu.close();
                                            delegate.clicked();
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
                        RowLayout {
                            id: fxLayout
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            /* QQC2.Label {
                                text: "|"
                                opacity: (model.metadata.midi_channel >= 5 && model.metadata.midi_channel <= 9) || model.metadata.midi_cloned
                            }*/
                            QQC2.Label {
                                Layout.fillWidth: true
                                font.pointSize: mainLabel.font.pointSize * 0.9
                                Binding {
                                    property: "text"
                                    value: model.metadata && model.metadata.effects_label.length > 0 ? model.metadata.effects_label : "- -"
                                    delayed: true
                                }
                                elide: Text.ElideRight
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                        Rectangle {
                            Layout.preferredWidth: parent.width * Zynthbox.Plugin.synthPassthroughClients[model.metadata.midi_channel].dryGainHandler.gainAbsolute
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                            visible: root.selectedChannel.checkIfLayerExists(model.metadata.midi_channel)
                            color: Kirigami.Theme.highlightColor
                            opacity: 0.7
                        }
                    }
                }
            }
        }
        StackLayout {
            id: middleColumnStack
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: layout.columnWidth
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                RowLayout {
                    Layout.fillWidth: true
                    Layout.minimumHeight: libraryPagePicker.height
                    Layout.maximumHeight: libraryPagePicker.height
                    Kirigami.Heading {
                        id: banksHeading
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                        level: 2
                        text: visible ? qsTr("Banks (%1)").arg(zynqtgui.bank.effective_count) : "";
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    QQC2.Button {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                        text: qsTr("All Favorites")
                        checked: zynqtgui.preset.show_only_favorites
                        onClicked: {
                            zynqtgui.preset.show_only_favorites = !zynqtgui.preset.show_only_favorites
                            bankView.forceViewPosition(true)
                            presetView.forceViewPosition(true)
                        }
                    }
                }
                Zynthian.SelectorView {
                    id: bankView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    screenId: "bank"
                    autoActivateIndexOnChange: true

                    // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                    active: zynqtgui.isBootingComplete
                    onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                    onItemActivated: root.itemActivated(screenId, index)
                    onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
                    Component.onCompleted: {
                        bankView.background.highlighted = Qt.binding(function() { return zynqtgui.current_screen_id === screenId })
                    }
                    delegate: Zynthian.SelectorDelegate {
                        text: model.display === "None" ? qsTr("Single Presets") : model.display
                        screenId: bankView.screenId
                        selector: bankView.selector
                        // Show highlight frame only if current bank name matches selected one
                        // background.visible: zynqtgui.bank.current_index >= 0 && zynqtgui.curLayer != null && model.display == zynqtgui.curLayer.bankName
                        background.visible: {
                            // Bind to current_index as well as bankName. This ensures the selected frame is correctly updated.
                            // Do not use index to check when showing favorites as it ignores the case where current index might not be the selected preset since the list got filtered
                            // It also ignores the case when selecting a preset to be a favorite but not switching to it
                            return zynqtgui.bank.current_index >= 0 && zynqtgui.curLayer != null && model.display == zynqtgui.curLayer.bankName

                            // if (zynqtgui.preset.show_only_favorites) {
                            // } else {
                            //     // When not showing favorites, bind to current_index and check if delegate's index is the same
                            //     // This will result in faster displaying highlighted frame when changed
                            //     return zynqtgui.bank.current_index == index
                            // }
                        }
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
                    Layout.minimumHeight: libraryPagePicker.height
                    Layout.maximumHeight: libraryPagePicker.height
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
                            model: zynqtgui.isBootingComplete && visible ? zynqtgui.layers_for_channel.volumeControllers : []
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
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: layout.columnWidth
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumHeight: libraryPagePicker.height
                Layout.maximumHeight: libraryPagePicker.height
                Kirigami.Heading {
                    id: presetHeading
                    level: 2
                    text: visible ? qsTr("Presets (%1)").arg(zynqtgui.preset.effective_count) : "";
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                }
                Item {
                    Layout.fillWidth: true
                }
                QQC2.Button {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                    text: qsTr("FAV Presets")
                    checked: zynqtgui.preset.show_only_favorites
                    onClicked: {
                        zynqtgui.preset.show_only_favorites = !zynqtgui.preset.show_only_favorites
                        bankView.forceViewPosition(true)
                        presetView.forceViewPosition(true)
                    }
                }
            }
            Zynthian.SelectorView {
                id: presetView
                // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the page, which is very slow
                active: zynqtgui.isBootingComplete
                implicitHeight: 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                screenId: "preset"
                autoActivateIndexOnChange: true
                onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                onItemActivated: root.itemActivated(screenId, index)
                onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
                onIconClicked: {
                    // if (presetView.selector.current_index != index) {
                    //     presetView.selector.current_index = index;
                    //     presetView.selector.activate_index(index);
                    // }
                    // zynqtgui.preset.current_is_favorite = !zynqtgui.preset.current_is_favorite;
                }
                Component.onCompleted: {
                    presetView.background.highlighted = Qt.binding(function() { return zynqtgui.current_screen_id === screenId })
                }
                delegate: Zynthian.SelectorDelegate {
                    screenId: presetView.screenId
                    selector: presetView.selector
                    // Show highlight frame only if current preset name matches selected one
                    background.visible: {
                        // When showing favorites, bind to current_index as well as presetName. This ensures the selected frame is correctly updated.
                        // Do not use index to check when showing favorites as it ignores the case where current index might not be the selected preset since the list got filtered
                        // It also ignores the case when selecting a preset to be a favorite but not switching to it
                        return zynqtgui.preset.current_index >= 0 && zynqtgui.curLayer != null && model.display == zynqtgui.curLayer.presetName

                        // if (zynqtgui.preset.show_only_favorites) {

                        // } else {
                        //     // When not showing favorites, bind to current_index and check if delegate's index is the same
                        //     // This will result in faster displaying highlighted frame when changed
                        //     return zynqtgui.preset.current_index == index
                        // }
                    }
                    onCurrentScreenIdRequested: presetView.currentScreenIdRequested(screenId)
                    onItemActivated: presetView.itemActivated(screenId, index)
                    onItemActivatedSecondary: presetView.itemActivatedSecondary(screenId, index)
                    onIconClicked: {
                        zynqtgui.preset.setFavorite(index, !model.metadata.is_favorite)
                        zynqtgui.current_screen_id = "preset";

                        presetView.iconClicked(screenId, index)
                    }
                }
            }
        }
    }

    Connections {
        target: applicationWindow()
        property int lastCurrentIndex
        property bool currentIndexWasValid
        onRequestOpenLayerSetupDialog: layerSetupDialog.open()
        onRequestCloseLayerSetupDialog: layerSetupDialog.reject()
    }

    Zynthian.Dialog {
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
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    visible: root.selectedChannel.checkIfLayerExists(zynqtgui.active_midi_channel)
                    text: qsTr("Change preset")
                    onClicked: {
                        zynqtgui.current_screen_id = "preset"

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
                        zynqtgui.show_modal("sound_categories")

                        layerSetupDialog.accept();
                        applicationWindow().layerSetupDialogLoadSoundClicked();
                    }
                }
                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    visible: root.selectedChannel.checkIfLayerExists(zynqtgui.active_midi_channel)
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    visible: root.selectedChannel.checkIfLayerExists(zynqtgui.active_midi_channel)
                    text: qsTr("Remove Synth")
                    onClicked: {
                        layerSetupDialog.accept();
                        if (root.selectedChannel.checkIfLayerExists(zynqtgui.active_midi_channel)) {
                            root.selectedChannel.remove_and_unchain_sound(zynqtgui.active_midi_channel)
                        }
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
                        zynqtgui.layer.page_after_layer_creation = zynqtgui.current_screen_id;
                        zynqtgui.layer.select_engine(zynqtgui.fixed_layers.index_to_midi(zynqtgui.fixed_layers.current_index))
                        layerSetupDialog.accept();
                    }
                }
            }
        }
    }

//        Zynthian.FilePickerDialog {
//            id: saveDialog
//            property string mode: "sound"

//            conflictMessageLabel.visible: saveDialog.mode === "soundset" ? zynqtgui.layer.soundset_file_exists(fileNameToSave) : zynqtgui.layer.layer_file_exists(fileNameToSave);
//            headerText: saveDialog.mode === "soundset" ? qsTr("Save a Soundset file") : qsTr("Save a Sound file")
//            rootFolder: "/zynthian/zynthian-my-data/"
//            noFilesMessage: saveDialog.mode === "soundset" ? qsTr("No Soundsets present") : qsTr("No sounds present")
//            folderModel {
//                nameFilters: [saveDialog.mode === "soundset" ? "*.soundset" : "*.*.sound"]
//            }
//            onVisibleChanged: folderModel.folder = rootFolder + (saveDialog.mode === "soundset" ? "soundsets/my-soundsets/" : "sounds/my-sounds/")

//            filePropertiesComponent: Flow {
//                Repeater {
//                    id: infoRepeater
//                    model: saveDialog.currentFileInfo
//                        ? (saveDialog.mode === "soundset"
//                            ? zynqtgui.layer.soundset_metadata_from_file(saveDialog.currentFileInfo.filePath)
//                            : zynqtgui.layer.sound_metadata_from_file(saveDialog.currentFileInfo.filePath))
//                        : []
//                    delegate: QQC2.Label {
//                        width: modelData.preset_name ? parent.width - 10 : implicitWidth
//                        elide: Text.ElideRight
//                        font.pointSize: modelData.preset_name ? Kirigami.Theme.font.pointSize : 9
//                        text: {
//                            var name = modelData.name;
//                            if (modelData.preset_name) {
//                                name = "• " + name + ">" + modelData.preset_name;
//                            } else {
//                                name = "    " + name;
//                            }
//                            return name;
//                        }
//                    }
//                }
//            }

//            filesListView.delegate: Kirigami.BasicListItem {
//                width: ListView.view.width
//                highlighted: ListView.isCurrentItem

//                property bool isCurrentItem: ListView.isCurrentItem
//                onIsCurrentItemChanged: {
//                    if (isCurrentItem) {
//                        saveDialog.currentFileInfo = model;
//                    }
//                }
//                label: model.fileName
//                icon: model.fileIsDir ? "folder" : "emblem-music-symbolic"
//                QQC2.Label {
//                    visible: saveDialog.mode === "sound"
//                    text: {
//                        let parts = model.fileName.split(".");
//                        if (parts.length < 2) {
//                            return ""
//                        }
//                        let num = Number(parts[1])
//                        if (num < 2) {
//                            return ""
//                        } else {
//                            return qsTr("%1 Synths").arg(num);
//                        }
//                    }
//                }
//                onClicked: saveDialog.filesListView.selectItem(model)
//            }

//            onAccepted: {
//                console.log(saveDialog.selectedFile.filePath);
//                if (mode === "soundset") {
//                    zynqtgui.layer.save_soundset_to_file(saveDialog.selectedFile.filePath);
//                } else { //Sound
//                    zynqtgui.layer.save_curlayer_to_file(saveDialog.selectedFile.filePath);
//                }
//            }

//            saveMode: true
//        }

//        Zynthian.FilePickerDialog {
//            id: pickerDialog
//            parent: root
//            property string mode: "sound"

//            headerText: pickerDialog.mode === "soundset" ? qsTr("Pick a Soundset file") : qsTr("Pick a Sound file")
//            rootFolder: "/zynthian/zynthian-my-data/"
//            folderModel {
//                nameFilters: [(pickerDialog.mode === "soundset" ? "*.soundset" : "*.*." + pickerDialog.mode)]
//            }

//            filePropertiesComponent: Flow {
//                Repeater {
//                    id: infoRepeater
//                    model: pickerDialog.currentFileInfo
//                        ? (pickerDialog.mode === "soundset"
//                            ? zynqtgui.layer.soundset_metadata_from_file(pickerDialog.currentFileInfo.filePath)
//                            : zynqtgui.layer.sound_metadata_from_file(pickerDialog.currentFileInfo.filePath))
//                        : []
//                    delegate: QQC2.Label {
//                        width: modelData.preset_name ? parent.width - 10 : implicitWidth
//                        elide: Text.ElideRight
//                        font.pointSize: modelData.preset_name ? Kirigami.Theme.font.pointSize : 9
//                        text: {
//                            var name = modelData.name;
//                            if (modelData.preset_name) {
//                                name = "• " + name + ">" + modelData.preset_name;
//                            } else {
//                                name = "    " + name;
//                            }
//                            return name;
//                        }
//                    }
//                }
//            }

//            onVisibleChanged: folderModel.folder = rootFolder + (pickerDialog.mode === "soundset" ? "soundsets/" : "sounds/")
//            filesListView.delegate: Kirigami.BasicListItem {
//                width: ListView.view.width
//                highlighted: ListView.isCurrentItem

//                property bool isCurrentItem: ListView.isCurrentItem
//                onIsCurrentItemChanged: {
//                    if (isCurrentItem) {
//                        pickerDialog.currentFileInfo = model;
//                    }
//                }
//                label: model.fileName
//                icon: model.fileIsDir ? "folder" : "emblem-music-symbolic"
//                QQC2.Label {
//                    visible: pickerDialog.mode === "sound"
//                    text: {
//                        let parts = model.fileName.split(".");
//                        if (parts.length < 2) {
//                            return ""
//                        }
//                        let num = Number(parts[1])
//                        if (num < 2) {
//                            return ""
//                        } else {
//                            return qsTr("%1 Synths").arg(num);
//                        }
//                    }
//                }
//                onClicked: pickerDialog.filesListView.selectItem(model)
//            }
//            onAccepted: {
//                console.log(pickerDialog.selectedFile.filePath);
//                if (pickerDialog.mode === "soundset") {
//                    zynqtgui.layer.load_soundset_from_file(pickerDialog.selectedFile.filePath)
//                } else {
//                    //zynqtgui.layer.load_layer_from_file(pickerDialog.selectedFile.filePath)
//                    layerReplaceDialog.sourceChannels = zynqtgui.layer.load_layer_channels_from_file(pickerDialog.selectedFile.filePath);
//                    if (layerReplaceDialog.sourceChannels.length > 1) {
//                        layerReplaceDialog.fileToLoad = pickerDialog.selectedFile.filePath;
//                        layerReplaceDialog.open();
//                    } else {
//                        let map = {}
//                        map[layerReplaceDialog.sourceChannels[0].toString()] = zynqtgui.fixed_layers.index_to_midi(zynqtgui.fixed_layers.current_index);
//                        zynqtgui.layer.load_layer_from_file(pickerDialog.selectedFile.filePath, map);
//                    }
//                }
//                zynqtgui.bank.show_top_sounds = false;
//                pickerDialog.accept()
//            }
//        }

//        Zynthian.LayerReplaceDialog {
//            id: layerReplaceDialog
//            parent: root.parent
//            modal: true
//            x: Math.round(parent.width/2 - width/2)
//            y: Math.round(parent.height/2 - height/2)
//            height: contentItem.implicitHeight + header.implicitHeight + footer.implicitHeight + topMargin + bottomMargin + Kirigami.Units.smallSpacing
//            footerLeftPadding: saveDialog.leftPadding
//            footerRightPadding: saveDialog.rightPadding
//            footerBottomPadding: saveDialog.bottomPadding
//        }
}
