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
import "pages/Sketchpad" as Sketchpad

Kirigami.AbstractApplicationWindow {
    id: root

    readonly property Item currentPage: pageStack.currentItem
    readonly property Item playGrids: playGridsRepeater

    property bool headerVisible: true
    property var channels: [
        zynthian.sketchpad.song.channelsModel.getChannel(0),
        zynthian.sketchpad.song.channelsModel.getChannel(1),
        zynthian.sketchpad.song.channelsModel.getChannel(2),
        zynthian.sketchpad.song.channelsModel.getChannel(3),
        zynthian.sketchpad.song.channelsModel.getChannel(4),
        zynthian.sketchpad.song.channelsModel.getChannel(5),
        zynthian.sketchpad.song.channelsModel.getChannel(6),
        zynthian.sketchpad.song.channelsModel.getChannel(7),
        zynthian.sketchpad.song.channelsModel.getChannel(8),
        zynthian.sketchpad.song.channelsModel.getChannel(9),
    ]
    property QtObject selectedChannel: {
        return root.channels[0]
    }
    property var cuiaCallback: function(cuia) {
        var result = false;
        
        // Since VK is not a Zynthian Menu/Popup/Drawer, CUIA events are not sent implicitly
        // If the virtual keyboard is open, pass CUIA events explicitly
        if (virtualKeyboardLoader.item && virtualKeyboardLoader.item.visible) {
            result = virtualKeyboardLoader.item.cuiaCallback(cuia);
        }
        
        return result
    }

    property QtObject sequence: ZynQuick.PlayGridManager.getSequenceModel(zynthian.sketchpad.song.scenesModel.selectedTrackName)

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
    onWidthChanged: width = screen.width
    onHeightChanged: height = screen.height
    pageStack: pageManager
    header: RowLayout {            
        spacing: 0
        Zynthian.BreadcrumbButton {
            id: menuButton
            icon.name: "application-menu"
            icon.color: customTheme.Kirigami.Theme.textColor
            padding: Kirigami.Units.largeSpacing*1.5
            rightPadding: Kirigami.Units.largeSpacing*1.5
            property string oldPage: "sketchpad"
            property string oldModalPage: "sketchpad"
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
            Layout.minimumWidth: Kirigami.Units.gridUnit * 6
            Layout.maximumWidth: Kirigami.Units.gridUnit * 6
            padding: Kirigami.Units.largeSpacing*1.5
            rightPadding: Kirigami.Units.largeSpacing*1.5
            font.pointSize: 11
            onClicked: {
                // print(zynthian.sketchpad.song.scenesModel.getScene(zynthian.sketchpad.song.scenesModel.selectedTrackIndex).name)
                //zynthian.current_modal_screen_id = 'sketchpad'
                tracksMenu.open()
            }
            //onPressAndHold: zynthian.current_screen_id = 'main'
            // highlighted: zynthian.current_screen_id === 'sketchpad'

            ColumnLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Kirigami.Units.largeSpacing*1.5
                spacing: 0

                QQC2.Label {
                    Layout.alignment: Qt.AlignHCenter
                    font.pointSize: 10
                    text: zynthian.sketchpad.song.name
                }

                QQC2.Label {
                    Layout.alignment: Qt.AlignHCenter
                    font.pointSize: 10
                    text: zynthian.sketchpad.song.scenesModel.selectedTrackName + "ˬ"
                }
            }


            Zynthian.Menu {
                id: tracksMenu
                y: parent.height
                modal: true
                dim: false
                Repeater {
                    model: 10
                    delegate: QQC2.MenuItem {
                        text: qsTr("Track T%1").arg(index+1)
                        width: parent.width
                        font.pointSize: 11
                        onClicked: {
                            tracksMenu.close();
                            zynthian.sketchpad.song.scenesModel.selectedTrackIndex = index;
                        }
                        highlighted: zynthian.sketchpad.song.scenesModel.selectedTrackIndex === index
                    }
                }
            }
        }
    /* Zynthian.BreadcrumbButton {
            icon.color: customTheme.Kirigami.Theme.textColor
            text: qsTr("1-6")
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
            rightPadding: Kirigami.Units.largeSpacing*2
            onClicked: {
                zynthian.current_screen_id = 'session_dashboard';
                zynthian.session_dashboard.visibleChannelsStart = 0;
                zynthian.session_dashboard.visibleChannelsEnd = 5;
            }
        }
        Zynthian.BreadcrumbButton {
            icon.color: customTheme.Kirigami.Theme.textColor
            text: qsTr("7-12")
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
            rightPadding: Kirigami.Units.largeSpacing*2
            onClicked: {
                zynthian.current_screen_id = 'session_dashboard';
                zynthian.session_dashboard.visibleChannelsStart = 6;
                zynthian.session_dashboard.visibleChannelsEnd = 11;
            }
        }*/
        Zynthian.BreadcrumbButton {
            id: sceneButton
            icon.color: customTheme.Kirigami.Theme.textColor
            text: qsTr("Scene %1 ˬ").arg(zynthian.sketchpad.song.scenesModel.selectedSceneName)
            Layout.maximumWidth: Kirigami.Units.gridUnit * 6
            rightPadding: Kirigami.Units.largeSpacing*2
            font.pointSize: 11
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

            Zynthian.Menu {
                id: scenesMenu
                y: parent.height
                modal: true
                dim: false
                Repeater {
                    model: 10
                    delegate: QQC2.MenuItem {
                        text: qsTr("Scene %1").arg(String.fromCharCode(index+65).toUpperCase())
                        width: parent.width
                        font.pointSize: 11
                        onClicked: {
                            scenesMenu.close();
                            switchTimer.index = index;
                            switchTimer.restart();
                        }
                        highlighted: zynthian.sketchpad.song.scenesModel.selectedSceneIndex === index
//                             implicitWidth: menuItemLayout.implicitWidth + leftPadding + rightPadding
                    }
                }
            }
        }
        Zynthian.BreadcrumbButton {
            id: channelButton
            icon.color: customTheme.Kirigami.Theme.textColor
            text: qsTr("Channel %1 ˬ")
                    .arg(zynthian.session_dashboard.selectedChannel+1)
            Layout.maximumWidth: Kirigami.Units.gridUnit * 6
            rightPadding: Kirigami.Units.largeSpacing*2
            font.pointSize: 11
            onClicked: channelsMenu.visible = true
            Zynthian.Menu {
                id: channelsMenu
                y: parent.height
                modal: true
                dim: false
                Component.onCompleted: zynthian.fixed_layers.layers_count = 15;
                Repeater {
                    model: zynthian.sketchpad.song.channelsModel
                    delegate: QQC2.MenuItem {
                        text: qsTr("Channel %1").arg(index + 1)
                        width: parent.width
                        //visible: index >= zynthian.session_dashboard.visibleChannelsStart && index <= zynthian.session_dashboard.visibleChannelsEnd
                        //height: visible ? implicitHeight : 0
                        onClicked: {
                            zynthian.session_dashboard.selectedChannel = index;
                        }
                        highlighted: zynthian.session_dashboard.selectedChannel === index
//                             implicitWidth: menuItemLayout.implicitWidth + leftPadding + rightPadding
                    }
                }
            }
        }
        Zynthian.BreadcrumbButton {
            id: samplesButton

            property QtObject selectedSample: root.selectedChannel.samples[root.selectedChannel.selectedSlotRow]

            icon.color: customTheme.Kirigami.Theme.textColor
            text: qsTr("Sample %1 ˬ %2")
                    .arg(root.selectedChannel.selectedSlotRow + 1)
                    .arg(selectedSample && selectedSample.path && selectedSample.path.length > 0 ? "" : ": none")
            Layout.maximumWidth: Kirigami.Units.gridUnit * 11
            rightPadding: Kirigami.Units.largeSpacing*2
            font.pointSize: 11
            onClicked: samplesMenu.visible = true
            visible: ["sample-trig", "sample-slice"].indexOf(root.selectedChannel.channelAudioType) >= 0

            Zynthian.Menu {
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
                            root.selectedChannel.selectedSlotRow = index
                        }
                        highlighted: root.selectedChannel.selectedSlotRow === index
                    }
                }
            }
        }
        Zynthian.BreadcrumbButton {
            id: sampleLoopButton

            property QtObject clip: zynthian.sketchpad.song.getClip(zynthian.session_dashboard.selectedChannel, zynthian.sketchpad.song.scenesModel.selectedTrackIndex)

            icon.color: customTheme.Kirigami.Theme.textColor
            text: qsTr("%1").arg(clip && clip.path ? clip.path.split("/").pop() : "")
            Layout.maximumWidth: Kirigami.Units.gridUnit * 10
            rightPadding: Kirigami.Units.largeSpacing*2
            font.pointSize: 11
            visible: root.selectedChannel.channelAudioType === "sample-loop" &&
                    clip && clip.path && clip.path.length >= 0
        }
        Zynthian.BreadcrumbButton {
            id: synthButton
            icon.color: customTheme.Kirigami.Theme.textColor
            Layout.maximumWidth: Kirigami.Units.gridUnit * 6
            rightPadding: Kirigami.Units.largeSpacing*2
            font.pointSize: 11
            visible: root.selectedChannel.channelAudioType === "synth"

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

                if (root.selectedChannel) {
                    for (var id in root.selectedChannel.chainedSounds) {
                        if (root.selectedChannel.chainedSounds[id] >= 0 &&
                            root.selectedChannel.checkIfLayerExists(root.selectedChannel.chainedSounds[id])) {
                            text = zynthian.fixed_layers.selector_list.getDisplayValue(root.selectedChannel.chainedSounds[id]).split(">")[0]// + "ˬ"; TODO re-enable when this will open the popup again
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
            Layout.maximumWidth: Kirigami.Units.gridUnit * 6
            rightPadding: Kirigami.Units.largeSpacing*2
            font.pointSize: 11

            // Open synth edit page whjen preset button is clicked
            onClicked: {
                if (root.selectedChannel) {
                    zynthian.fixed_layers.activate_index(root.selectedChannel.connectedSound)
                    zynthian.control.single_effect_engine = null;
                    zynthian.current_screen_id = "control";
                    zynthian.forced_screen_back = "sketchpad"
                }
            }

            visible: root.selectedChannel.channelAudioType === "synth"

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

                if (root.selectedChannel) {
                    for (var id in root.selectedChannel.chainedSounds) {
                        if (root.selectedChannel.chainedSounds[id] >= 0 &&
                            root.selectedChannel.checkIfLayerExists(root.selectedChannel.chainedSounds[id])) {
                            text = zynthian.fixed_layers.selector_list.getDisplayValue(root.selectedChannel.chainedSounds[id]);
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
                    return false //screensLayer.depth > 2
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
            font.pointSize: 11
        }
        Zynthian.BreadcrumbButton {
            icon.color: customTheme.Kirigami.Theme.textColor
            text: "EDIT"
            visible: zynthian.current_screen_id === "control"
            Layout.maximumWidth: Kirigami.Units.gridUnit * 4
            rightPadding: Kirigami.Units.largeSpacing*2
            font.pointSize: 11
        }
        Item {
            Layout.fillWidth: true
        }

        QQC2.Button {
            id: globalRecordButton
            Layout.preferredWidth: Kirigami.Units.gridUnit*4
            Layout.preferredHeight: Kirigami.Units.gridUnit*2
            property QtObject currentSequence: ZynQuick.PlayGridManager.getSequenceModel(zynthian.sketchpad.song.scenesModel.selectedTrackName)
            onClicked: {
                if (zynthian.current_screen_id === "playgrid") {
                    zynthian.callable_ui_action("START_RECORD");
                } else {
                    // handle live-recording-is-going state here, otherwise you might turn it
                    // on in the sequencer, then head out, and try and turn it off and it just
                    // opens the recording popup, which isn't what you'd be after
                    if (globalRecordButton.currentSequence.activePatternObject && globalRecordButton.currentSequence.activePatternObject.recordLive) {
                        globalRecordButton.currentSequence.activePatternObject.recordLive = false;
                        if (ZynQuick.PlayGridManager.metronomeActive) {
                            Zynthian.CommonUtils.stopMetronomeAndPlayback();
                        }
                    } else {
                        applicationWindow().openRecordingPopup();
                    }
                }
            }

            Kirigami.Icon {
                width: Kirigami.Units.gridUnit
                height: width
                anchors.centerIn: parent
                source: "media-record-symbolic"
                color: globalRecordButton.currentSequence.activePatternObject && globalRecordButton.currentSequence.activePatternObject.recordLive
                    ? "#ff5cf436" // A green with the same values as the red audio record colour below
                    : zynthian.sketchpad.isRecording ? "#fff44336" : "white"
            }
        }
        QQC2.Button {
            Layout.preferredWidth: Kirigami.Units.gridUnit*4
            Layout.preferredHeight: Kirigami.Units.gridUnit*2
            onClicked: {
                if (zynthian.sketchpad.isMetronomeRunning) {
                    Zynthian.CommonUtils.stopMetronomeAndPlayback();
                } else {
                    Zynthian.CommonUtils.startMetronomeAndPlayback();
                }
            }

            Kirigami.Icon {
                width: Kirigami.Units.gridUnit
                height: width
                anchors.centerIn: parent
                source: zynthian.sketchpad.isMetronomeRunning ? "media-playback-stop" : "media-playback-start"
                color: "white"
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

    // Listen to selected_channel_changed signal to
    Connections {
        target: zynthian.session_dashboard
        onSelected_channel_changed: root.selectedChannel = root.channels[zynthian.session_dashboard.selectedChannel]
    }

    PageManager {
        id: pageManager
        anchors.fill: parent
    }

    CustomTheme {
        id: customTheme
        Component.onCompleted: {
            // Force write config file after QML engine starts loading main page to load theme correctly
            // Without this force write, bullseye doesn't load previously selected theme from plasmarc
            zynthian.theme_chooser.select_action(zynthian.theme_chooser.current_index)
        }
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

    Zynthian.DialogQuestion {
        id: confirmDialog
        text: zynthian.confirm.text
        onAccepted: zynthian.confirm.accept()
        onRejected: zynthian.confirm.reject()
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
        visible: zynthian.sketchpad.countInBars > 0 &&
                 zynthian.sketchpad.ongoingCountIn > 0 &&
                 zynthian.sketchpad.isRecording
        z: 9999999
        color: "#cc000000"

        RowLayout {
            anchors.centerIn: parent
            QQC2.Label {
                font.pointSize: 35
                text: zynthian.sketchpad.ongoingCountIn
            }
            QQC2.Label {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 8
                text: "/" + (4 - zynthian.sketchpad.currentBeat)
            }
        }
    }
    
    Rectangle {
        id: splashOverlay
        parent: root.contentItem.parent
        anchors.fill: parent
        color: "#ff000000"
        z: 9999999
        visible: !zynthian.splashStopped

        // Display currentTaskMessage on splashOverlay as it overlaps bootlog
        // window before main window is displayed before splash is hidden
        QQC2.Label {
            width: parent.width
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50
            horizontalAlignment: Qt.AlignHCenter
            font.pointSize: 12
            color: "white"
            text: zynthian.currentTaskMessage
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
        onPassiveNotificationChanged: {
            applicationWindow().showPassiveNotification(zynthian.passiveNotification, 1500)
        }
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
        onTaskMessage: {
            Qt.callLater(function() {
                zynthian.playgrid.setCurrentTaskMessage(message);
            })
        }
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

    Sketchpad.RecordingPopup {
        id: recordingPopup
    }

    Zynthian.Drawer {
        id: miniPlayGridDrawer
        width: root.width
        height: root.height * 0.66
        edge: Qt.BottomEdge
        modal: false
        interactive: !opened

        contentItem: MiniPlayGrid {}
    }

    Zynthian.Drawer {
        id: slotSelectionDrawer
        width: Kirigami.Units.gridUnit * 24
        height: root.height
        edge: Qt.LeftEdge
        dragMargin: Kirigami.Units.gridUnit * 0.9
        modal: true

        property var cuiaCallback: function(cuia) {
            var returnVal = false

            switch (cuia) {
                // Set respective selected row when button 1-5 is pressed or 6(mod)+1-5 is pressed
                // and invoke respective handler when channelAudioType is synth, trig or slice
                // Otherwise, when in loop mode, do not handle button to allow falling back to channel
                // selection
                case "CHANNEL_1":
                case "CHANNEL_6":
                    if (root.selectedChannel.channelAudioType === "synth" ||
                        root.selectedChannel.channelAudioType === "sample-loop" ||
                        root.selectedChannel.channelAudioType === "sample-trig" ||
                        root.selectedChannel.channelAudioType === "sample-slice") {
                        root.selectedChannel.selectedSlotRow = 0
                        pageManager.getPage("sketchpad").bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                        returnVal = true
                    }

                    break

                case "CHANNEL_2":
                case "CHANNEL_7":
                    if (root.selectedChannel.channelAudioType === "synth" ||
                        root.selectedChannel.channelAudioType === "sample-loop" ||
                        root.selectedChannel.channelAudioType === "sample-trig" ||
                        root.selectedChannel.channelAudioType === "sample-slice") {
                        root.selectedChannel.selectedSlotRow = 1
                        pageManager.getPage("sketchpad").bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                        returnVal = true
                    }

                    break

                case "CHANNEL_3":
                case "CHANNEL_8":
                    if (root.selectedChannel.channelAudioType === "synth" ||
                        root.selectedChannel.channelAudioType === "sample-loop" ||
                        root.selectedChannel.channelAudioType === "sample-trig" ||
                        root.selectedChannel.channelAudioType === "sample-slice") {
                        root.selectedChannel.selectedSlotRow = 2
                        pageManager.getPage("sketchpad").bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                        returnVal = true
                    }

                    break

                case "CHANNEL_4":
                case "CHANNEL_9":
                    if (root.selectedChannel.channelAudioType === "synth" ||
                        root.selectedChannel.channelAudioType === "sample-loop" ||
                        root.selectedChannel.channelAudioType === "sample-trig" ||
                        root.selectedChannel.channelAudioType === "sample-slice") {
                        root.selectedChannel.selectedSlotRow = 3
                        pageManager.getPage("sketchpad").bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                        returnVal = true
                    }

                    break

                case "CHANNEL_5":
                case "CHANNEL_10":
                    if (root.selectedChannel.channelAudioType === "synth" ||
                        root.selectedChannel.channelAudioType === "sample-loop" ||
                        root.selectedChannel.channelAudioType === "sample-trig" ||
                        root.selectedChannel.channelAudioType === "sample-slice") {
                        root.selectedChannel.selectedSlotRow = 4
                        pageManager.getPage("sketchpad").bottomStack.slotsBar.handleItemClick(root.selectedChannel.channelAudioType)
                        returnVal = true
                    }

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
            property real margin: Kirigami.Units.gridUnit * 1.5

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Kirigami.Units.gridUnit * 0.5
                    topMargin: Kirigami.Units.gridUnit * 2
                    bottomMargin: Kirigami.Units.gridUnit * 2
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

                        anchors.fill: parent
                        anchors.margins: slotSelectionDelegate.margin
                        anchors.bottomMargin: Kirigami.Units.gridUnit * 3
                        spacing: slotSelectionDelegate.margin

                        QQC2.Label {
                            Layout.alignment: Qt.AlignCenter
                            text: qsTr("Channels")
                        }

                        Repeater {
                            model: 5
                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Sketchpad.ChannelHeader2 {
                                    id: channelHeaderDelegate

                                    property int channelDelta: 0

                                    anchors.fill: parent
                                    channel: zynthian.sketchpad.song.channelsModel.getChannel(index + channelHeaderDelegate.channelDelta)
                                    text: channelHeaderDelegate.channel.name
                                    subText: null
                                    subSubText: {
                                        if (channelHeaderDelegate.channel.channelAudioType === "sample-loop") {
                                            return qsTr("Audio")
                                        } else if (channelHeaderDelegate.channel.channelAudioType === "sample-trig") {
                                            return qsTr("Smp: Trig")
                                        } else if (channelHeaderDelegate.channel.channelAudioType === "sample-slice") {
                                            return qsTr("Smp: Slice")
                                        } else if (channelHeaderDelegate.channel.channelAudioType === "synth") {
                                            return qsTr("Synth")
                                        } else if (channelHeaderDelegate.channel.channelAudioType === "external") {
                                            return qsTr("External")
                                        }
                                    }
                                    subSubTextSize: 7
                                    highlightColor: "white"

                                    Binding {
                                        target: channelHeaderDelegate
                                        property: "color"
                                        when: root.visible
                                        delayed: true

                                        value: {
                                            if (channelHeaderDelegate.channel.channelAudioType === "synth")
                                                return "#66ff0000"
                                            else if (channelHeaderDelegate.channel.channelAudioType === "sample-loop")
                                                return "#6600ff00"
                                            else if (channelHeaderDelegate.channel.channelAudioType === "sample-trig")
                                                return "#66ffff00"
                                            else if (channelHeaderDelegate.channel.channelAudioType === "sample-slice")
                                                return "#66ffff00"
                                            else if (channelHeaderDelegate.channel.channelAudioType === "external")
                                                return "#998e24aa"
                                            else
                                                return "#66888888"
                                        }
                                    }

                                    highlightOnFocus: false
                                    highlighted: (index + channelHeaderDelegate.channelDelta) === zynthian.session_dashboard.selectedChannel // If song mode is not active, highlight if current cell is selected channel

                                    onPressed: {
                                        zynthian.session_dashboard.selectedChannel = index + channelHeaderDelegate.channelDelta;
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
                        id: slotsColumn2

                        anchors.fill: parent
                        anchors.margins: slotSelectionDelegate.margin
                        anchors.bottomMargin: Kirigami.Units.gridUnit * 3
                        spacing: slotSelectionDelegate.margin

                        QQC2.Label {
                            Layout.alignment: Qt.AlignCenter
                            text: qsTr("Channels")
                        }

                        Repeater {
                            model: 5
                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Sketchpad.ChannelHeader2 {
                                    id: channelHeaderDelegate2

                                    property int channelDelta: 5

                                    anchors.fill: parent
                                    channel: zynthian.sketchpad.song.channelsModel.getChannel(index + channelHeaderDelegate2.channelDelta)
                                    text: channelHeaderDelegate2.channel.name
                                    subText: null
                                    subSubText: {
                                        if (channelHeaderDelegate2.channel.channelAudioType === "sample-loop") {
                                            return qsTr("Audio")
                                        } else if (channelHeaderDelegate2.channel.channelAudioType === "sample-trig") {
                                            return qsTr("Smp: Trig")
                                        } else if (channelHeaderDelegate2.channel.channelAudioType === "sample-slice") {
                                            return qsTr("Smp: Slice")
                                        } else if (channelHeaderDelegate2.channel.channelAudioType === "synth") {
                                            return qsTr("Synth")
                                        } else if (channelHeaderDelegate2.channel.channelAudioType === "external") {
                                            return qsTr("External")
                                        }
                                    }
                                    subSubTextSize: 7
                                    highlightColor: "white"

                                    Binding {
                                        target: channelHeaderDelegate2
                                        property: "color"
                                        when: root.visible
                                        delayed: true

                                        value: {
                                            if (channelHeaderDelegate2.channel.channelAudioType === "synth")
                                                return "#66ff0000"
                                            else if (channelHeaderDelegate2.channel.channelAudioType === "sample-loop")
                                                return "#6600ff00"
                                            else if (channelHeaderDelegate2.channel.channelAudioType === "sample-trig")
                                                return "#66ffff00"
                                            else if (channelHeaderDelegate2.channel.channelAudioType === "sample-slice")
                                                return "#66ffff00"
                                            else if (channelHeaderDelegate2.channel.channelAudioType === "external")
                                                return "#998e24aa"
                                            else
                                                return "#66888888"
                                        }
                                    }

                                    highlightOnFocus: false
                                    highlighted: (index + channelHeaderDelegate2.channelDelta) === zynthian.session_dashboard.selectedChannel // If song mode is not active, highlight if current cell is selected channel

                                    onPressed: {
                                        zynthian.session_dashboard.selectedChannel = index + channelHeaderDelegate2.channelDelta;
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
                            text: qsTr("Clips")
                        }

                        Sketchpad.PartBarDelegate {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            channel: slotSelectionDelegate.visible ? root.selectedChannel : null
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
                        if (clipPickerMenu.visible) {
                            clipPickerMenu.hide();
                        } else {
                            clipPickerMenu.show();
                        }
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
                    text: clipPickerView.isRecording ? qsTr("STOP RECORDING") : qsTr("START RECORDING")
                    onClicked: {
                        if (clipPickerView.isRecording) {
                            clipPickerView.stopRecording();
                        } else {
                            clipPickerView.startRecording();
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

    Zynthian.OnScreenDisplay { }

    Window {
        id: clipPickerMenu
        visible: false;
        width: root.width
        height: root.height - root.footer.height
        x: 0
        y: 0
        flags: Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
        RowLayout {
            anchors {
                fill: parent
                margins: Kirigami.Units.smallSpacing
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: qsTr("File")
                    onClicked: clipPickerView.currentItem = clipPickerComponentFile
                    checked: clipPickerView.currentItem.objectName === "clipPickerFile"
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: qsTr("Sample Slot")
                    onClicked: clipPickerView.currentItem = clipPickerComponentClip
                    checked: clipPickerView.currentItem.objectName === "clipPickerClip"
                }
            }
            Item {
                id: clipPickerView

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 16

                property bool isRecording: currentItem ? currentItem.isRecording : false
                function startRecording() {
                    currentItem.startRecording();
                }
                function stopRecording() {
                    currentItem.stopRecording();
                }

                property Item currentItem: clipPickerComponentFile
                ExternalRecordingDestinationFile {
                    id: clipPickerComponentFile
                    visible: clipPickerMenu.visible && clipPickerView.currentItem.objectName === objectName
                    anchors.fill: parent
                }
                ExternalRecordingDestinationClip {
                    id: clipPickerComponentClip
                    visible:  clipPickerMenu.visible && clipPickerView.currentItem.objectName === objectName
                    anchors.fill: parent
                }
            }
        }
    }
}
