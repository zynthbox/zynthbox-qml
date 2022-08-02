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
import org.zynthian.quick 1.0 as ZynQuick
import "pages" as Pages
import "pages/SessionDashboard" as SessionDashboard
import "pages/ZynthiLoops" as Zynthiloops

Kirigami.AbstractApplicationWindow {
    id: root

    readonly property PageScreenMapping pageScreenMapping: PageScreenMapping {}
    readonly property Item currentPage: {
        if (zynthian.current_screen_id === "main" || zynthian.current_screen_id === "zynthiloops") {
            return dashboardLayer.currentItem;
        } else if (modalScreensLayer.depth > 0) {
            return modalScreensLayer.currentItem;
        } else {
            return screensLayer.currentItem
        }
    }
    readonly property Item playGrids: playGridsRepeater
    property bool headerVisible: true
    property var tracks: [
        zynthian.zynthiloops.song.tracksModel.getTrack(0),
        zynthian.zynthiloops.song.tracksModel.getTrack(1),
        zynthian.zynthiloops.song.tracksModel.getTrack(2),
        zynthian.zynthiloops.song.tracksModel.getTrack(3),
        zynthian.zynthiloops.song.tracksModel.getTrack(4),
        zynthian.zynthiloops.song.tracksModel.getTrack(5),
        zynthian.zynthiloops.song.tracksModel.getTrack(6),
        zynthian.zynthiloops.song.tracksModel.getTrack(7),
        zynthian.zynthiloops.song.tracksModel.getTrack(8),
        zynthian.zynthiloops.song.tracksModel.getTrack(9),
    ]
    property QtObject selectedTrack: {
        return root.tracks[0]
    }
    property var cuiaCallback: function(cuia) {
        var result = false;

        // If the virtual keyboard is open, pass thins directly to that
        if (virtualKeyboardLoader.item && virtualKeyboardLoader.item.visible) {
            result = virtualKeyboardLoader.item.cuiaCallback(cuia);
        } else if (slotSelectionDrawer.opened) {
            result = slotSelectionDrawer.cuiaCallback(cuia);
        } else if (cuia.startsWith("SWITCH_BACK")) {
            if (tracksMenu.visible) {
                tracksMenu.visible = false;
                result = true;
            } else if (scenesMenu.visible) {
                scenesMenu.visible = false;
                result = true;
            } else if (samplesMenu.visible) {
                samplesMenu.visible = false;
                result = true;
            } else if (zynthian.globalPopupOpened) {
                zynthian.globalPopupOpened = false;
                result = true;
            }
        }

        return result;
    }

    property QtObject sequence: ZynQuick.PlayGridManager.getSequenceModel(zynthian.zynthiloops.song.scenesModel.selectedSketchName)

    signal requestOpenLayerSetupDialog()
    signal requestCloseLayerSetupDialog()
    signal layerSetupDialogAccepted()
    signal layerSetupDialogRejected()
    signal layerSetupDialogLoadSoundClicked()
    signal layerSetupDialogNewSynthClicked()
    signal layerSetupDialogChangePresetClicked()
    signal layerSetupDialogPickSoundClicked()
    signal soundsDialogAccepted()
    signal soundsDialogRejected()

    function showConfirmationDialog() { confirmDialog.open() }
    function hideConfirmationDialog() { confirmDialog.close() }
    function openSoundsDialog() { soundsDialog.open() }
    function openRecordingPopup() { recordingPopup.open() }

    visible: false
    flags: Qt.WindowStaysOnBottomHint|Qt.FramelessWindowHint
    minimumWidth: screen.width
    minimumHeight: screen.height
    onCurrentPageChanged: zynthian.current_qml_page = currentPage
    Component.onCompleted: displayWindowTimer.start()
    onWidthChanged: width = screen.width
    onHeightChanged: height = screen.height
    pageStack: screensLayer
    header: RowLayout {
        spacing: 0
        Zynthian.BreadcrumbButton {
            id: menuButton
            icon.name: "application-menu"
            icon.color: customTheme.Kirigami.Theme.textColor
            padding: Kirigami.Units.largeSpacing*1.5
            rightPadding: Kirigami.Units.largeSpacing*1.5
            property string oldPage: "zynthiloops"
            property string oldModalPage: "zynthiloops"
            onClicked: {
                if (zynthian.current_screen_id === 'main') {
                    if (oldModalPage !== "") {
                        zynthian.current_modal_screen_id = oldModalPage;
                    } else if (oldPage !== "") {
                        zynthian.current_screen_id = oldPage;
                    }
                } else {
                    if (zynthian.current_screen_id === "control") {
                        oldModalPage = "";
                        oldPage = "preset"
                    } else {
                        oldModalPage = zynthian.current_modal_screen_id;
                        oldPage = zynthian.current_screen_id;
                    }
                    zynthian.current_screen_id = 'main';
                }
            }
            highlighted: zynthian.current_screen_id === 'main'
        }
        Zynthian.BreadcrumbButton {
            id: homeButton
            text: zynthian.zynthiloops.song.name
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
            padding: Kirigami.Units.largeSpacing*1.5
            rightPadding: Kirigami.Units.largeSpacing*1.5
            onClicked: {
                zynthian.current_modal_screen_id = 'zynthiloops'
                // print(zynthian.zynthiloops.song.scenesModel.getScene(zynthian.zynthiloops.song.scenesModel.selectedSketchIndex).name)
            }
            //onPressAndHold: zynthian.current_screen_id = 'main'
            highlighted: zynthian.current_screen_id === 'zynthiloops'
        }
       /* Zynthian.BreadcrumbButton {
            icon.color: customTheme.Kirigami.Theme.textColor
            text: qsTr("1-6")
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
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
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
            rightPadding: Kirigami.Units.largeSpacing*2
            onClicked: {
                zynthian.current_screen_id = 'session_dashboard';
                zynthian.session_dashboard.visibleTracksStart = 6;
                zynthian.session_dashboard.visibleTracksEnd = 11;
            }
        }*/
        Zynthian.BreadcrumbButton {
            id: sceneButton
            icon.color: customTheme.Kirigami.Theme.textColor
            text: qsTr("Scene %1 ˬ").arg(zynthian.zynthiloops.song.scenesModel.selectedSceneName)
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
            rightPadding: Kirigami.Units.largeSpacing*2
            onClicked: scenesMenu.visible = true

            Timer {
                id: switchTimer

                property int index

                interval: 100
                repeat: false
                onTriggered: {
                    Zynthian.CommonUtils.switchToScene(index)
                }
            }

            QQC2.Menu {
                id: scenesMenu
                y: parent.height
                modal: true
                dim: false
                Repeater {
                    model: 10
                    delegate: QQC2.MenuItem {
                        text: qsTr("Scene %1").arg(String.fromCharCode(index+65).toUpperCase())
                        width: parent.width
                        onClicked: {
                            scenesMenu.close();
                            switchTimer.index = index;
                            switchTimer.restart();
                        }
                        highlighted: zynthian.zynthiloops.song.scenesModel.selectedSceneIndex === index
//                             implicitWidth: menuItemLayout.implicitWidth + leftPadding + rightPadding
                    }
                }
            }
        }
        Zynthian.BreadcrumbButton {
            id: trackButton
            icon.color: customTheme.Kirigami.Theme.textColor
            text: qsTr("Track %1 ˬ")
                    .arg(zynthian.session_dashboard.selectedTrack+1)
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
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
//                             implicitWidth: menuItemLayout.implicitWidth + leftPadding + rightPadding
                    }
                }
            }
        }
        Zynthian.BreadcrumbButton {
            id: samplesButton

            property QtObject selectedSample: root.selectedTrack.samples[root.selectedTrack.selectedSlotRow]

            icon.color: customTheme.Kirigami.Theme.textColor
            text: qsTr("Sample %1 ˬ %2")
                    .arg(root.selectedTrack.selectedSlotRow + 1)
                    .arg(selectedSample && selectedSample.path && selectedSample.path.length > 0 ? "" : ": none")
            Layout.maximumWidth: Kirigami.Units.gridUnit * 11
            rightPadding: Kirigami.Units.largeSpacing*2
            onClicked: samplesMenu.visible = true
            visible: ["sample-trig", "sample-slice"].indexOf(root.selectedTrack.trackAudioType) >= 0

            QQC2.Menu {
                id: samplesMenu
                y: parent.height
                modal: true
                dim: false
                Repeater {
                    model: 5
                    delegate: QQC2.MenuItem {
                        text: qsTr("Sample %1").arg(index + 1)
                        width: parent.width
                        onClicked: {
                            root.selectedTrack.selectedSlotRow = index
                        }
                        highlighted: root.selectedTrack.selectedSlotRow === index
                    }
                }
            }
        }
        Zynthian.BreadcrumbButton {
            id: sampleLoopButton

            property QtObject clip: zynthian.zynthiloops.song.getClip(zynthian.session_dashboard.selectedTrack, zynthian.zynthiloops.song.scenesModel.selectedSketchIndex)

            icon.color: customTheme.Kirigami.Theme.textColor
            text: qsTr("%1").arg(clip && clip.path ? clip.path.split("/").pop() : "")
            Layout.maximumWidth: Kirigami.Units.gridUnit * 10
            rightPadding: Kirigami.Units.largeSpacing*2
            visible: root.selectedTrack.trackAudioType === "sample-loop" &&
                     clip && clip.path && clip.path.length >= 0
        }
        Zynthian.BreadcrumbButton {
            id: synthButton
            icon.color: customTheme.Kirigami.Theme.textColor
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
            rightPadding: Kirigami.Units.largeSpacing*2
            visible: root.selectedTrack.trackAudioType === "synth"

            // Open preset screen on clicking this synth button
            onClicked: zynthian.current_screen_id = "preset"

            text: {
                synthButton.updateSoundName();
            }

            Connections {
                target: zynthian.fixed_layers
                onList_updated: {
                    synthButton.updateSoundName();
                }
            }

            function updateSoundName() {
                var text = "";

                if (root.selectedTrack) {
                    for (var id in root.selectedTrack.chainedSounds) {
                        if (root.selectedTrack.chainedSounds[id] >= 0 &&
                            root.selectedTrack.checkIfLayerExists(root.selectedTrack.chainedSounds[id])) {
                            text = zynthian.fixed_layers.selector_list.getDisplayValue(root.selectedTrack.chainedSounds[id]).split(">")[0]// + "ˬ"; TODO re-enable when this will open the popup again
                            break;
                        }
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
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
            rightPadding: Kirigami.Units.largeSpacing*2

            // Open synth edit page whjen preset button is clicked
            onClicked: {
                if (root.selectedTrack) {
                    zynthian.fixed_layers.activate_index(root.selectedTrack.connectedSound)
                    zynthian.control.single_effect_engine = null;
                    zynthian.current_screen_id = "control";
                    zynthian.forced_screen_back = "zynthiloops"
                }
            }

            visible: root.selectedTrack.trackAudioType === "synth"

            text: {
                presetButton.updateSoundName();
            }

            Connections {
                target: zynthian.fixed_layers
                onList_updated: {
                    presetButton.updateSoundName();
                }
            }

            function updateSoundName() {
                var text = "";

                if (root.selectedTrack) {
                    for (var id in root.selectedTrack.chainedSounds) {
                        if (root.selectedTrack.chainedSounds[id] >= 0 &&
                            root.selectedTrack.checkIfLayerExists(root.selectedTrack.chainedSounds[id])) {
                            text = zynthian.fixed_layers.selector_list.getDisplayValue(root.selectedTrack.chainedSounds[id]);
                            text = text.split(">")[1] ? text.split(">")[1] : i18n("Presets")
                            break;
                        }
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
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
            rightPadding: Kirigami.Units.largeSpacing*2
        }
        Zynthian.BreadcrumbButton {
            icon.color: customTheme.Kirigami.Theme.textColor
            text: "EDIT"
            visible: zynthian.current_screen_id === "control"
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
            rightPadding: Kirigami.Units.largeSpacing*2
        }
        Item {
            Layout.fillWidth: true
        }


        QQC2.Button {
            Layout.preferredWidth: Kirigami.Units.gridUnit*4
            Layout.preferredHeight: Kirigami.Units.gridUnit*2
            enabled: !zynthian.zynthiloops.isMetronomeRunning
            onClicked: {
                Zynthian.CommonUtils.startMetronomeAndPlayback();
            }

            Kirigami.Icon {
                width: Kirigami.Units.gridUnit
                height: width
                anchors.centerIn: parent
                source: "media-playback-start"
                color: parent.enabled ? "white" : "#99999999"
            }
        }
        QQC2.Button {
            Layout.preferredWidth: Kirigami.Units.gridUnit*4
            Layout.preferredHeight: Kirigami.Units.gridUnit*2
            enabled: zynthian.zynthiloops.isMetronomeRunning
            onClicked: {
                Zynthian.CommonUtils.stopMetronomeAndPlayback();
            }

            Kirigami.Icon {
                width: Kirigami.Units.gridUnit
                height: width
                anchors.centerIn: parent
                source: "media-playback-stop"
                color: parent.enabled ? "white" : "#99999999"
            }
        }

        Zynthian.StatusInfo {}
    }
    background: Rectangle {
        Kirigami.Theme.inherit: false
        // TODO: this should eventually go to Window and the panels to View
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }
    footer: Zynthian.ActionBar {
        z: 999999
        currentPage: root.currentPage
        visible: root.controlsVisible
       // height: Math.max(implicitHeight, Kirigami.Units.gridUnit * 3)
    }

    Timer {
        id: displayWindowTimer
        // This interval makes sure to wait until all the pages are cached before showing window
        interval: 100
        repeat: false
        onTriggered: {
            zynthian.stop_splash();
        }
    }

    // Listen to selected_track_changed signal to
    Connections {
        target: zynthian.session_dashboard
        onSelected_track_changed: root.selectedTrack = root.tracks[zynthian.session_dashboard.selectedTrack]
    }

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

    Zynthian.ModalLoadingOverlay {
        id: alternateLoadingOverlay
        parent: root.contentItem.parent
        anchors.fill: parent
        open: false
        z: 9999999

        QQC2.Label {
            width: parent.width * 0.4
            text: zynthian.currentTaskMessage
            horizontalAlignment: "AlignHCenter"
            x: parent.width/2 - width/2
            y: parent.height - height - Kirigami.Units.gridUnit * 4
        }
    }

    Rectangle {
        id: countInOverlay
        parent: root.contentItem.parent
        anchors.fill: parent
        visible: zynthian.zynthiloops.countInBars > 0 &&
                 zynthian.zynthiloops.ongoingCountIn > 0 &&
                 zynthian.zynthiloops.isRecording
        z: 9999999
        color: "#cc000000"

        RowLayout {
            anchors.centerIn: parent
            QQC2.Label {
                font.pointSize: 35
                text: zynthian.zynthiloops.ongoingCountIn
            }
            QQC2.Label {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 8
                text: "/" + (4 - zynthian.zynthiloops.currentBeat)
            }
        }
    }

    Loader {
        id: virtualKeyboardLoader
        parent: root.contentItem.parent
        z: Qt.inputMethod.visible ? 99999999 : 1
        anchors.fill: parent
        source: "./VirtualKeyboard.qml"
    }

    Connections {
        target: zynthian
        onMiniPlayGridToggle: miniPlayGridDrawer.visible = !miniPlayGridDrawer.visible
        onRun_start_metronome_and_playback: Zynthian.CommonUtils.startMetronomeAndPlayback()
        onRun_stop_metronome_and_playback: Zynthian.CommonUtils.stopMetronomeAndPlayback()
        onDisplayMainWindow: {
            root.minimumWidth = root.screen.width;
            root.minimumHeight = root.screen.height;
            root.showNormal();
            root.visibility = Window.Windowed;
        }
        onDisplayRecordingPopup: recordingPopup.open()
        onOpenLeftSidebar: slotSelectionDrawer.open()
        onCloseLeftSidebar: slotSelectionDrawer.close()
    }

    Connections {
        target: zynthian
        onLongTaskStarted: {
            alternateLoadingOverlay.open = true;
        }
        onLongTaskEnded: {
            alternateLoadingOverlay.open = false;
        }
    }

    Connections {
        target: ZynQuick.PlayGridManager
        onTaskMessage: zynthian.playgrid.setCurrentTaskMessage(message);
    }
    Repeater {
        id: playGridsRepeater
        model: ZynQuick.PlayGridManager.playgrids
        Loader {
            id:playGridLoader
            source: modelData + "/main.qml"
            onLoaded: {
                playGridLoader.item.setId(modelData);
            }
        }
    }

    Zynthiloops.RecordingPopup {
        id: recordingPopup
    }

    QQC2.Drawer {
        id: miniPlayGridDrawer
        width: root.width
        height: root.height * 0.66
        edge: Qt.BottomEdge
        modal: false
        interactive: !opened

        contentItem: MiniPlayGrid {}
    }

    QQC2.Drawer {
        id: slotSelectionDrawer
        width: Kirigami.Units.gridUnit * 16
        height: root.height
        edge: Qt.LeftEdge
        dragMargin: Kirigami.Units.gridUnit * 0.9
        modal: true

        property var cuiaCallback: function(cuia) {
            var clip
            var returnVal = false

            switch (cuia) {
                case "TRACK_1":
                case "TRACK_6":
                    clip = root.selectedTrack.getClipsModelByPart(0).getClip(zynthian.zynthiloops.song.scenesModel.selectedSketchIndex)
                    clip.enabled = !clip.enabled

                    returnVal = true
                    break

                case "TRACK_2":
                case "TRACK_7":
                    clip = root.selectedTrack.getClipsModelByPart(1).getClip(zynthian.zynthiloops.song.scenesModel.selectedSketchIndex)
                    clip.enabled = !clip.enabled

                    returnVal = true
                    break

                case "TRACK_3":
                case "TRACK_8":
                    clip = root.selectedTrack.getClipsModelByPart(2).getClip(zynthian.zynthiloops.song.scenesModel.selectedSketchIndex)
                    clip.enabled = !clip.enabled

                    returnVal = true
                    break

                case "TRACK_4":
                case "TRACK_9":
                    clip = root.selectedTrack.getClipsModelByPart(3).getClip(zynthian.zynthiloops.song.scenesModel.selectedSketchIndex)
                    clip.enabled = !clip.enabled

                    returnVal = true
                    break

                case "TRACK_5":
                case "TRACK_10":
                    clip = root.selectedTrack.getClipsModelByPart(4).getClip(zynthian.zynthiloops.song.scenesModel.selectedSketchIndex)
                    clip.enabled = !clip.enabled

                    returnVal = true
                    break

                case "SWITCH_BACK_SHORT":
                    slotSelectionDrawer.close()

                    returnVal = true
                    break
            }

            return returnVal;
        }

        onOpened: {
            zynthian.leftSidebarActive = true
        }
        onClosed: {
            zynthian.leftSidebarActive = false
        }
        Component.onCompleted: {
            zynthian.leftSidebar = slotSelectionDrawer
        }

        background: Item {
        }
        contentItem: Item {
            id: slotSelectionDelegate
            property real margin: Kirigami.Units.gridUnit * 1

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Kirigami.Units.gridUnit * 0.5
                    topMargin: Kirigami.Units.gridUnit * 4
                    bottomMargin: Kirigami.Units.gridUnit * 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#222222"
                    radius: 6
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                          Kirigami.Theme.textColor.g,
                                          Kirigami.Theme.textColor.b,
                                          0.2)
                    border.width: 1

                    ColumnLayout {
                        id: slotsColumn
                        property bool slotsColumnVisible: slotSelectionDrawer.visible && ["synth", "sample-trig", "sample-slice"].indexOf(root.selectedTrack.trackAudioType) >= 0

                        anchors.fill: parent
                        anchors.margins: slotSelectionDelegate.margin
                        spacing: slotSelectionDelegate.margin

                        QQC2.Label {
                            Layout.alignment: Qt.AlignCenter
                            visible: slotsColumn.slotsColumnVisible
                            text: root.selectedTrack.trackAudioType === "synth"
                                    ? qsTr("Synth Slots")
                                    : ["sample-trig", "sample-slice"].indexOf(root.selectedTrack.trackAudioType) >= 0
                                        ? qsTr("Sample Slots")
                                        : ""
                        }

                        Repeater {
                            model: slotsColumn.slotsColumnVisible
                                    ? 5
                                    : 0
                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                QQC2.Button {
                                    id: slotsColumnDelegate
                                    property string soundName: root.selectedTrack.chainedSoundsNames[index]

                                    width: parent.width
                                    height: Kirigami.Units.gridUnit * 3
                                    anchors.centerIn: parent
                                    text: index + 1
                                    onClicked: {
                                        root.selectedTrack.selectedSlotRow = index
                                        dashboardLayer.pageCache["zynthiloops"].bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                                    }

                                    Rectangle {
                                        height: Kirigami.Units.gridUnit * 0.7
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        color: "#99888888"
                                        visible: root.selectedTrack.trackAudioType === "synth" &&
                                                 synthName.text &&
                                                 synthName.text.length > 0

                                        QQC2.Label {
                                            id: synthName
                                            anchors.fill: parent
                                            elide: "ElideRight"
                                            horizontalAlignment: "AlignHCenter"
                                            verticalAlignment: "AlignVCenter"
                                            font.pointSize: 7
                                            text: slotsColumnDelegate.soundName.length > 0
                                                    ? slotsColumnDelegate.soundName.split(" > ")[0]
                                                    : ""
                                        }
                                    }

                                    Rectangle {
                                        height: Kirigami.Units.gridUnit * 0.7
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        color: "#99888888"
                                        visible: root.selectedTrack.trackAudioType === "synth" &&
                                                 presetName.text &&
                                                 presetName.text.length > 0

                                        QQC2.Label {
                                            id: presetName
                                            anchors.fill: parent
                                            elide: "ElideRight"
                                            horizontalAlignment: "AlignHCenter"
                                            verticalAlignment: "AlignVCenter"
                                            font.pointSize: 7
                                            text: slotsColumnDelegate.soundName.length > 0
                                                    ? slotsColumnDelegate.soundName.split(" > ")[1]
                                                        ? slotsColumnDelegate.soundName.split(" > ")[1]
                                                        : ""
                                                    : ""
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#222222"
                    radius: 6
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                          Kirigami.Theme.textColor.g,
                                          Kirigami.Theme.textColor.b,
                                          0.2)
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: slotSelectionDelegate.margin
                        spacing: slotSelectionDelegate.margin

                        QQC2.Label {
                            Layout.alignment: Qt.AlignCenter
                            text: qsTr("Parts")
                        }

                        Zynthiloops.PartBarDelegate {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            track: slotSelectionDelegate.visible ? root.selectedTrack : null
                        }
                    }
                }
            }
        }
    }

    Window {
        id: panel
        width: screen.width
        height: root.footer.height
        x: 0
        y: screen.height - height
        flags: Qt.WindowDoesNotAcceptFocus

        // Initially set to false as this value will be set after an interval
        // when UI loads for the first time
        visible: false

        /**
          * This Connections object triggers a timer to display the external window control panel
          * after an interval when UI loads for the first time
          * This prevent displaying the panel for a brief moment before UI loads for the first time after boot.
          */
        Connections {
            id: rootVisibilityConnections
            target: root
            onVisibleChanged: panelVisibilityTimer.restart()
            onActiveChanged: panelVisibilityTimer.restart()
        }

        Timer {
            id: panelVisibilityTimer
            interval: 5000
            repeat: false
            onTriggered: {
                /**
                  * Disable the connections object as it is no longer required to trigger
                  * this timer. Once the timer is triggered, visible property of panel is bound to
                  * the dependendant properties.
                  */
                rootVisibilityConnections.enabled = false
                panel.visible = Qt.binding(function() { return root.visible && !root.active })
            }
        }

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
                    id: recordingDestinationButton
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
                        parent: recordingDestinationButton.background
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
                    preload: true
                },
                Zynthian.TabbedControlViewAction {
                    text: qsTr("Clip")
                    page: Qt.resolvedUrl("ExternalRecordingDestinationClip.qml")
                    preload: true
                }
            ]
        }
    }

//    Window {
//        id: bootLogWindow
//        visible: true
//        flags: Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint
//        width: 200
//        height: 200

//        Rectangle {
//            anchors.fill: parent
//            color: "#2196f3"

//            QQC2.Label {
//                anchors {
//                    left: parent.left
//                    right: parent.right
//                    bottom: parent.bottom
//                }
//                horizontalAlignment: "AlignHCenter"
//                text: zynthian.currentTaskMessage
//            }
//        }
//    }
}
