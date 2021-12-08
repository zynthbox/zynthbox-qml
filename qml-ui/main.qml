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

import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import "pages" as Pages
import "pages/SessionDashboard" as SessionDashboard

Kirigami.AbstractApplicationWindow {
    id: root

    readonly property PageScreenMapping pageScreenMapping: PageScreenMapping {}
    readonly property Item currentPage: {
        if (zynthian.current_screen_id === "main" || zynthian.current_screen_id === "session_dashboard") {
            return dashboardLayer.currentItem;
        } else if (modalScreensLayer.depth > 0) {
            return modalScreensLayer.currentItem;
        } else {
            return screensLayer.currentItem
        }
    }
    onCurrentPageChanged: zynthian.current_qml_page = currentPage

    property bool headerVisible: true
    property QtObject selectedTrack: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)

    function showConfirmationDialog() {
        confirmDialog.open()
    }
    function hideConfirmationDialog() {
        confirmDialog.close()
    }
    function openSoundsDialog() {
        soundsDialog.open();
    }
    Component.onCompleted: {
        root.showFullScreen()
    }

    signal requestOpenLayerSetupDialog()
    signal requestCloseLayerSetupDialog()
    signal layerSetupDialogAccepted()
    signal layerSetupDialogRejected()
    signal layerSetupDialogLoadSoundClicked()
    signal layerSetupDialogNewSynthClicked()
    signal layerSetupDialogPickSoundClicked()
    signal soundsDialogAccepted()
    signal soundsDialogRejected()

    width: screen.width
    height: screen.height

    header: RowLayout {
            spacing: 0
            Zynthian.BreadcrumbButton {
                id: homeButton
                icon.name: "go-home"
                icon.color: customTheme.Kirigami.Theme.textColor
                text: zynthian.zynthiloops.song.name
                Layout.maximumWidth: Kirigami.Units.gridUnit * 14
                padding: Kirigami.Units.largeSpacing*1.5
                rightPadding: Kirigami.Units.largeSpacing*1.5
                onClicked: {
                    zynthian.current_screen_id = 'session_dashboard'
                    // print(zynthian.zynthiloops.song.scenesModel.getScene(zynthian.zynthiloops.song.scenesModel.selectedSceneIndex).name)
                }
                onPressAndHold: zynthian.current_screen_id = 'main'
                highlighted: zynthian.current_screen_id === 'session_dashboard'
            }
            Zynthian.BreadcrumbButton {
                icon.color: customTheme.Kirigami.Theme.textColor
                text: qsTr("1-6")
                Layout.maximumWidth: Kirigami.Units.gridUnit * 14
                rightPadding: Kirigami.Units.largeSpacing*2
                onClicked: {
                    zynthian.current_screen_id = 'session_dashboard';
                    zynthian.session_dashboard.visibleTracksStart = 0;
                    zynthian.session_dashboard.visibleTracksEnd = 5;
                }
            }
            Zynthian.BreadcrumbButton {
                icon.color: customTheme.Kirigami.Theme.textColor
                text: qsTr("7-12")
                Layout.maximumWidth: Kirigami.Units.gridUnit * 14
                rightPadding: Kirigami.Units.largeSpacing*2
                onClicked: {
                    zynthian.current_screen_id = 'session_dashboard';
                    zynthian.session_dashboard.visibleTracksStart = 6;
                    zynthian.session_dashboard.visibleTracksEnd = 11;
                }
            }
            /*Zynthian.BreadcrumbButton {
                id: sceneButton
                icon.color: customTheme.Kirigami.Theme.textColor
                text: qsTr("Scene %2")
                        .arg(zynthian.zynthiloops.song.scenesModel.getScene(zynthian.zynthiloops.song.scenesModel.selectedSceneIndex).name)
                Layout.maximumWidth: Kirigami.Units.gridUnit * 14
                rightPadding: Kirigami.Units.largeSpacing*2
            }*/
            Zynthian.BreadcrumbButton {
                id: trackButton
                icon.color: customTheme.Kirigami.Theme.textColor
                text: qsTr("Track %1 ˬ")
                        .arg(zynthian.session_dashboard.selectedTrack+1)
                Layout.maximumWidth: Kirigami.Units.gridUnit * 14
                rightPadding: Kirigami.Units.largeSpacing*2
                onClicked: tracksMenu.visible = true
                QQC2.Menu {
                    id: tracksMenu
                    y: parent.height
                    modal: true
                    dim: false
                    Component.onCompleted: zynthian.fixed_layers.layers_count = 15;
                    Repeater {
                        model: zynthian.zynthiloops.song.tracksModel
                        delegate: QQC2.MenuItem {
                            text: qsTr("Track %1").arg(index + 1)
                            width: parent.width
                            //visible: index >= zynthian.session_dashboard.visibleTracksStart && index <= zynthian.session_dashboard.visibleTracksEnd
                            //height: visible ? implicitHeight : 0
                            onClicked: {
                                zynthian.session_dashboard.selectedTrack = index;
                            }
                            highlighted: zynthian.session_dashboard.selectedTrack === index
                            implicitWidth: menuItemLayout.implicitWidth + leftPadding + rightPadding
                        }
                    }
                }
            }
            Zynthian.BreadcrumbButton {
                id: synthButton
                icon.color: customTheme.Kirigami.Theme.textColor
                Layout.maximumWidth: Kirigami.Units.gridUnit * 14
                rightPadding: Kirigami.Units.largeSpacing*2
                onClicked: {
                    // As per #399, open library instead
                    // soundsDialog.visible = true
                    zynthian.current_screen_id = "preset"
                }

                text: {
                    synthButton.updateSoundName();
                }

                Connections {
                    target: zynthian.fixed_layers
                    onList_updated: {
                        synthButton.updateSoundName();
                    }
                }

                Connections {
                    target: track
                    onChainedSoundsChanged: {
                        synthButton.updateSoundName();
                    }
                }

                function updateSoundName() {
                    var text = "";

                    for (var id in root.selectedTrack.chainedSounds) {
                        if (root.selectedTrack.chainedSounds[id] >= 0 &&
                            root.selectedTrack.checkIfLayerExists(root.selectedTrack.chainedSounds[id])) {
                            text = zynthian.fixed_layers.selector_list.getDisplayValue(root.selectedTrack.chainedSounds[id]).split(">")[0] + "ˬ";
                            break;
                        }
                    }

                    synthButton.text = text == "" ? qsTr("Sounds") : text;
                }

                SessionDashboard.SoundsDialog {
                    id: soundsDialog
                    width: Screen.width
                    height: Screen.height - synthButton.height - Kirigami.Units.gridUnit
                    onVisibleChanged: {
                        x = synthButton.mapFromGlobal(0, 0).x
                        y = synthButton.height + Kirigami.Units.smallSpacing
                    }
                }
            }
            Zynthian.BreadcrumbButton {
                id: presetButton
                icon.color: customTheme.Kirigami.Theme.textColor
                Layout.maximumWidth: Kirigami.Units.gridUnit * 14
                rightPadding: Kirigami.Units.largeSpacing*2
                onClicked: zynthian.current_screen_id = "preset"

                text: {
                    presetButton.updateSoundName();
                }

                Connections {
                    target: zynthian.fixed_layers
                    onList_updated: {
                        presetButton.updateSoundName();
                    }
                }

                Connections {
                    target: track
                    onChainedSoundsChanged: {
                        presetButton.updateSoundName();
                    }
                }

                function updateSoundName() {
                    var text = "";

                    for (var id in root.selectedTrack.chainedSounds) {
                        if (root.selectedTrack.chainedSounds[id] >= 0 &&
                            root.selectedTrack.checkIfLayerExists(root.selectedTrack.chainedSounds[id])) {
                            text = zynthian.fixed_layers.selector_list.getDisplayValue(root.selectedTrack.chainedSounds[id]);
                            text = text.split(">")[1] ? text.split(">")[1] : i18n("Presets")
                            break;
                        }
                    }

                    presetButton.text = text == "" ? qsTr("Presets") : text;
                }
            }
            Zynthian.BreadcrumbButton {
                icon.color: customTheme.Kirigami.Theme.textColor
                text: {
                    switch (effectScreen) {
                    case "layer_midi_effects":
                    case "midi_effect_types":
                    case "layer_midi_effect_chooser":
                        return "MIDI FX";
                    default:
                        "Audio FX";
                    }
                }
                visible: {
                    switch (zynthian.current_screen_id) {
                    case "layer_effects":
                    case "effect_types":
                    case "layer_effect_chooser":
                    case "layer_midi_effects":
                    case "midi_effect_types":
                    case "layer_midi_effect_chooser":
                        return true;
                    default:
                        return screensLayer.depth > 2
                    }
                }
                property string effectScreen: ""
                readonly property string screenId: zynthian.current_screen_id
                onScreenIdChanged: {
                    switch (zynthian.current_screen_id) {
                    case "layer_effects":
                    case "effect_types":
                    case "layer_effect_chooser":
                    case "layer_midi_effects":
                    case "midi_effect_types":
                    case "layer_midi_effect_chooser":
                        effectScreen = zynthian.current_screen_id;
                    default:
                        break;
                    }
                }
                onClicked: zynthian.current_screen_id = effectScreen
                Layout.maximumWidth: Kirigami.Units.gridUnit * 14
                rightPadding: Kirigami.Units.largeSpacing*2
            }
            Zynthian.BreadcrumbButton {
                icon.color: customTheme.Kirigami.Theme.textColor
                text: "EDIT"
                visible: zynthian.current_screen_id === "control"
                Layout.maximumWidth: Kirigami.Units.gridUnit * 14
                rightPadding: Kirigami.Units.largeSpacing*2
            }
            /*Zynthian.BreadcrumbButton {
                id: layersButton
                text: {
                    if (zynthian.engine.midi_channel !== null && zynthian.current_screen_id === 'engine') {
                        if (zynthian.engine.midi_channel > 10) {
                            return "7." + (zynthian.engine.midi_channel - 10) + "ˬ";
                        } else if (zynthian.engine.midi_channel > 5) {
                            return  "6." + (zynthian.engine.midi_channel - 5) + "ˬ";
                        } else {
                            return zynthian.engine.midi_channel + 1 + "ˬ";
                        }
                    } else if (zynthian.main_layers_view.selector_path_element > 5 && zynthian.main_layers_view.selector_path_element <= 10) {
                        return "6." + (zynthian.main_layers_view.selector_path_element - 5) + "ˬ";
                    } else {
                        return (zynthian.active_midi_channel + 1) + "ˬ";
                    }
                }
                onTextChanged: zynthian.fixed_layers.start_midi_chan = 0;
                onClicked: layersMenu.visible = true
                highlighted: zynthian.current_screen_id === 'layer' || zynthian.current_screen_id === 'fixed_layers' || zynthian.current_screen_id === 'main_layers_view'
                QQC2.Menu {
                    id: layersMenu
                    y: parent.height
                    modal: true
                    dim: false
                    Component.onCompleted: zynthian.fixed_layers.layers_count = 15;
                    Repeater {
                        model: zynthian.fixed_layers.selector_list
                        delegate: QQC2.MenuItem {
                            height: visible ? implicitHeight : 0
                            visible: zynthian.main_layers_view.active_midi_channel < 10
                                    ? index < 10
                                    : index >= 10
                            //enabled: index < 5 || model.display.indexOf("- -") === -1
                            text: ""
                            //index === 6 ? qsTr("6 - T-RACK:") + model.display : (index > 6 ? "                  " +model.display : model.display )
                            width: parent.width
                            onClicked: {
                                zynthian.fixed_layers.activate_index(index);
                                zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack).connectedSound = index;
                            }
                            highlighted: zynthian.main_layers_view.active_midi_channel === model.metadata.midi_channel
                            implicitWidth: menuItemLayout.implicitWidth + leftPadding + rightPadding
                            contentItem: RowLayout {
                                id: menuItemLayout
                                QQC2.Label {
                                    Layout.alignment: Qt.AlignLeft
                                    Layout.maximumWidth: implicitWidth
                                    text: qsTr("6 - T-RACK:")
                                    visible: model.metadata.midi_channel >= 5 && model.metadata.midi_channel < 10
                                    opacity: index === 5
                                }
                                QQC2.Label {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignLeft
                                    text: {
                                        let numPrefix = model.metadata.midi_channel + 1;
                                        if (numPrefix > 5 && numPrefix <= 10) {
                                            numPrefix = "6." + (numPrefix - 5);
                                        }
                                        return numPrefix + " - " + model.display
                                    }
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
                            }
                        }
                    }
                }
            }*/
        Item {
            Layout.fillWidth: true
        }
        Zynthian.StatusInfo {}
    }
    pageStack: screensLayer
    ScreensLayer {
        id: screensLayer
        parent: root.contentItem
        anchors.fill: parent
        initialItem: root.pageScreenMapping.pageForScreen('fixed_layers')
    }

    ModalScreensLayer {
        id: modalScreensLayer
        anchors.fill: parent
    }

    DashboardScreensLayer {
        id: dashboardLayer
        anchors.fill: parent
        visible: root.footer.height > 0 //HACK
    }


    CustomTheme {
        id: customTheme
    }

    background: Rectangle {
        Kirigami.Theme.inherit: false
        // TODO: this should eventually go to Window and the panels to View
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    Instantiator {
        model: zynthian.keybinding.key_sequences_model
        delegate: Shortcut {
            sequence: model.display
            context: Qt.ApplicationShortcut
            onActivated: zynthian.process_keybinding_shortcut(model.display)
            onActivatedAmbiguously: zynthian.process_keybinding_shortcut(model.display)
        }
    }

    QQC2.Dialog {
        id: confirmDialog
        x: root.width / 2 - width / 2
        y: root.height / 2 - height / 2
        dim: true
        modal: true
        width: Math.round(Math.max(implicitWidth, root.width * 0.8))
        height: Math.round(Math.max(implicitHeight, root.height * 0.8))
        contentItem: Kirigami.Heading {
            level: 2
            text: zynthian.confirm.text
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        onAccepted: zynthian.confirm.accept()
        onRejected: zynthian.confirm.reject()
        footer: QQC2.Control {
            leftPadding: confirmDialog.leftPadding
            topPadding: Kirigami.Units.largeSpacing
            rightPadding: confirmDialog.rightPadding
            bottomPadding: confirmDialog.bottomPadding
            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing
                QQC2.Button {
                    implicitWidth: 1
                    Layout.fillWidth: true
                    text: qsTr("No")
                    onClicked: confirmDialog.reject()
                }
                QQC2.Button {
                    implicitWidth: 1
                    Layout.fillWidth: true
                    text: qsTr("Yes")
                    onClicked: confirmDialog.accept()
                }
            }
        }
    }

    Zynthian.ModalLoadingOverlay {
        parent: root.contentItem.parent
        anchors.fill: parent
        z: 9999999
    }

    footer: Zynthian.ActionBar {
        z: 999999
        currentPage: root.currentPage
        visible: root.controlsVisible
       // height: Math.max(implicitHeight, Kirigami.Units.gridUnit * 3)
    }

    Loader {
        parent: root.contentItem.parent
        z: Qt.inputMethod.visible ? 99999999 : 1
        anchors {
            left: parent.left
            bottom: parent.bottom
            right: parent.right
            //bottomMargin: -root.footer.height
        }
        height: Math.min(parent.height / 2, Math.max(parent.height/3, Kirigami.Units.gridUnit * 15))
        source: "./VirtualKeyboard.qml"
    }

    Connections {
        target: zynthian
        onMiniPlayGridToggle: miniPlayGridDrawer.visible = !miniPlayGridDrawer.visible
    }
    QQC2.Drawer {
        id: miniPlayGridDrawer
        width: root.width
        height: Kirigami.Units.gridUnit * 10
        edge: Qt.BottomEdge
        modal: false

        contentItem: MiniPlayGrid {}
    }

    Window {
        id: panel
        width: screen.width
        height: root.footer.height
        x: 0
        y: screen.height - height
        flags: Qt.WindowDoesNotAcceptFocus
        visible: !root.active
        QQC2.ToolBar {
            anchors.fill: parent
            position: QQC2.ToolBar.Footer
            contentItem: RowLayout {
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitWidth: 1
                    text: qsTr("CLOSE")
                    onClicked: {
                        clipPickerMenu.visible = false;
                        zynthian.close_current_window();
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitWidth: 1
                    enabled: false
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitWidth: 1
                    text: qsTr("RECORDING DESTINATION")
                    onClicked: {
                        clipPickerMenu.visible = !clipPickerMenu.visible;
                    }
                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            margins: Kirigami.Units.largeSpacing
                        }
                        parent: parent.background
                        height: Kirigami.Units.smallSpacing
                        color: Kirigami.Theme.highlightColor
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitWidth: 1
                    enabled: true
                    text: zynthian.main.isRecording ? qsTr("STOP RECORDING") : qsTr("START RECORDING")
                    onClicked: {
                        if (zynthian.main.isRecording) {
                            zynthian.main.stop_recording();
                        } else {
                            zynthian.main.start_recording();
                        }
                    }
                }
            }
        }
        onVisibleChanged: {
            if (visible) {
                zynthian.register_panel(panel);
                zynthian.stop_loading();
                // panel.width = panel.screen.width
                //TODO: necessary?
                //panel.y = panel.screen.height - height
            }
        }
    }
    Window {
        id: clipPickerMenu
        visible: false;
        width: screen.width / 2
        height: screen.height / 2
        x: screen.width - width
        y: screen.height - height
        flags: Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
        Zynthian.TabbedControlView {
            anchors {
                fill: parent;
                margins: Kirigami.Units.smallSpacing;
            }
            visibleFocusRects: false
            minimumTabsCount: 2

            property QQC2.StackView stack

            tabActions: [
                Zynthian.TabbedControlViewAction {
                    text: qsTr("File")
                    page: Qt.resolvedUrl("ExternalRecordingDestinationFile.qml")
                },
                Zynthian.TabbedControlViewAction {
                    text: qsTr("Clip")
                    page: Qt.resolvedUrl("ExternalRecordingDestinationClip.qml")
                }
            ]
        }
    }
}
