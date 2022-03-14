/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian slots bar page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Marco MArtin <mart@kde.org>

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
import org.kde.kirigami 2.6 as Kirigami
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls.Styles 1.4

//import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

Rectangle {
    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_SELECT_SHORT":
                bottomBar.controlType = BottomBar.ControlType.Track;
                bottomBar.controlObj = zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack);

                bottomStack.currentIndex = 0;
                mixerActionBtn.checked = false;

                return true;

            case "NAVIGATE_LEFT":
                if (zynthian.session_dashboard.selectedTrack > 0) {
                    zynthian.session_dashboard.selectedTrack -= 1;
                }

                return true;

            case "NAVIGATE_RIGHT":
                if (zynthian.session_dashboard.selectedTrack < 9) {
                    zynthian.session_dashboard.selectedTrack += 1;
                }

                return true;
        }

        return false;
    }

    function selectConnectedSound() {
        if (root.selectedSlotRowItem.track.connectedSound >= 0) {
            zynthian.fixed_layers.activate_index(root.selectedSlotRowItem.track.connectedSound);

            if (root.selectedSlotRowItem.track.connectedPattern >= 0) {
                var pattern = ZynQuick.PlayGridManager.getSequenceModel("Scene "+zynthian.zynthiloops.song.scenesModel.selectedSceneName).get(root.selectedSlotRowItem.track.connectedPattern);
                pattern.midiChannel = root.selectedSlotRowItem.track.connectedSound;
            }
        }
    }

    // When enabled, listen for layer popup rejected to re-select connected sound if any
    Connections {
        id: layerPopupRejectedConnections
        enabled: false
        target: applicationWindow()
        onLayerSetupDialogRejected: {
            console.log("Layer Popup Rejected");

            selectConnectedSound();
            layerPopupRejectedConnections.enabled = false;
        }
    }
    //NOTE: enable this if shouldn't switch to library
    Connections {
        id: backToSelection
        target: zynthian.layer
        enabled: false
        property string screenToGetBack: "session_dashboard"
        onLayer_created: {
            zynthian.current_modal_screen_id = screenToGetBack
            backToSelection.enabled = false
            backToSelectionTimer.restart()
        }
    }
    Timer {
        id: backToSelectionTimer
        interval: 250
        onTriggered: {
            zynthian.current_modal_screen_id = backToSelection.screenToGetBack
        }
    }

    Connections {
        id: currentScreenConnection
        property string oldScreen: "session_dashboard"
        target: zynthian
        onCurrent_screen_idChanged: {
            if (oldScreen === "engine") {
                backToSelection.enabled = false
            }
            oldScreen = zynthian.current_screen_id
        }
    }

    // When enabled, listen for sound dialog rejected to re-select connected sound if any
    Connections {
        id: soundsDialogRejectedConnections
        enabled: false
        target: applicationWindow()
        onSoundsDialogAccepted: {
            console.log("Sounds Dialog Accepted");
            soundsDialogRejectedConnections.enabled = false;
        }
        onSoundsDialogRejected: {
            console.log("Sounds Dialog Rejected");

            selectConnectedSound();
            soundsDialogRejectedConnections.enabled = false;
        }
    }

    Connections {
        target: applicationWindow()
        onLayerSetupDialogLoadSoundClicked: {
            // Disable Rejected handler as popup is accepted
            layerPopupRejectedConnections.enabled = false;
        }
        onLayerSetupDialogNewSynthClicked: {
            // Disable Rejected handler as popup is accepted
            layerPopupRejectedConnections.enabled = false;
        }
        onLayerSetupDialogPickSoundClicked: {
            console.log("Sound Dialog Opened");

            // Enable Sounds dialog rejected handler to select sound if any on close
            soundsDialogRejectedConnections.enabled = true;

            // Disable Rejected handler as popup is accepted
            layerPopupRejectedConnections.enabled = false;
        }
    }

    QtObject {
        id: privateProps

        //Try to fit exactly 12 mixers + a master mixer
        property int cellWidth: (tableLayout.width - loopGrid.columnSpacing)/13
    }

    GridLayout {
        id: root
        rows: 1
        anchors.fill: parent
        anchors.topMargin: Kirigami.Units.gridUnit*0.3

        readonly property QtObject song: zynthian.zynthiloops.song
        property QtObject selectedSlotRowItem

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true

            Kirigami.Heading {
                visible: false
                text: qsTr("Slots : %1").arg(song.name)
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 1

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 1

                    QQC2.ButtonGroup {
                        buttons: buttonsColumn.children
                    }

                    ColumnLayout {
                        id: buttonsColumn
                        Layout.preferredWidth: privateProps.cellWidth + 6
                        Layout.maximumWidth: privateProps.cellWidth + 6
                        Layout.bottomMargin: 5
                        Layout.fillHeight: true

                        QQC2.Button {
                            id: synthsButton
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            checkable: true
                            checked: true
                            text: qsTr("Synths")
                        }

                        QQC2.Button {
                            id: samplesButton
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            checkable: true
                            text: qsTr("Samples")
                        }

                        QQC2.Button {
                            id: fxButton
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            checkable: true
                            text: qsTr("FX")
                        }
                    }

                    Kirigami.Separator {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: "#ff31363b"
                    }

                    ListView {
                        id: tracksSlotsRow

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        clip: true
                        spacing: 0
                        orientation: Qt.Horizontal
                        boundsBehavior: Flickable.StopAtBounds

                        model: root.song.tracksModel

                        delegate: Rectangle {
                            id: trackDelegate

                            property bool highlighted: index === zynthian.session_dashboard.selectedTrack
                            property int selectedRow: 0
                            property int trackIndex: index
                            property QtObject track: zynthian.zynthiloops.song.tracksModel.getTrack(index)

                            width: privateProps.cellWidth
                            height: ListView.view.height
                            color: highlighted ? "#22ffffff" : "transparent"
                            radius: 2
                            border.width: 1
                            border.color: highlighted ? Kirigami.Theme.highlightColor : "transparent"

                            onHighlightedChanged: {
                                if (highlighted) {
                                    root.selectedSlotRowItem = trackDelegate
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.topMargin: 4
                                spacing: 0

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.topMargin: Kirigami.Units.gridUnit * 0.7
                                    Layout.bottomMargin: Kirigami.Units.gridUnit * 0.7
                                    spacing: Kirigami.Units.gridUnit * 0.7

                                    Repeater {
                                        model: 5
                                        delegate: Item {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.leftMargin: 4
                                            Layout.rightMargin: 4

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    if (zynthian.session_dashboard.selectedTrack !== trackDelegate.trackIndex ||
                                                        trackDelegate.selectedRow !== index) {
                                                        tracksSlotsRow.currentIndex = index
                                                        trackDelegate.selectedRow = index
                                                        zynthian.session_dashboard.selectedTrack = trackDelegate.trackIndex;
                                                    }
                                                }
                                                z: 10
                                            }

                                            Rectangle {
                                                property string text: synthsButton.checked && trackDelegate.track.chainedSounds[index] > -1 && trackDelegate.track.checkIfLayerExists(trackDelegate.track.chainedSounds[index])
                                                                        ? trackDelegate.track.getLayerNameByMidiChannel(trackDelegate.track.chainedSounds[index]).split(">")[0]
                                                                        : fxButton.checked && trackDelegate.track.chainedSounds[index] > -1 && trackDelegate.track.checkIfLayerExists(trackDelegate.track.chainedSounds[index])
                                                                            ? trackDelegate.track.getEffectsNameByMidiChannel(trackDelegate.track.chainedSounds[index])
                                                                            : samplesButton.checked && trackDelegate.track.samples[index].path
                                                                                ? trackDelegate.track.samples[index].path.split("/").pop()
                                                                                : ""

                                                clip: true
                                                anchors.centerIn: parent
                                                width: parent.width
                                                height: Kirigami.Units.gridUnit * 1.5

                                                Kirigami.Theme.inherit: false
                                                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                                color: Kirigami.Theme.backgroundColor

                                                border.color: trackDelegate.highlighted && trackDelegate.selectedRow === index ? Kirigami.Theme.highlightColor : "#ff999999"
                                                border.width: 1
                                                radius: 4

                                                QQC2.Label {
                                                    anchors {
                                                        verticalCenter: parent.verticalCenter
                                                        left: parent.left
                                                        leftMargin: 10
                                                        right: parent.right
                                                        rightMargin: 10
                                                    }
                                                    font.pointSize: 10
                                                    elide: "ElideRight"
                                                    text: parent.text
                                                }
                                            }
                                        }
                                    }
                                }

                                Kirigami.Separator {
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 1
                                    color: "#ff31363b"
                                    visible: index !== root.song.tracksModel.count-1 && !highlighted
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignTop
                        Layout.leftMargin: 2
                        Layout.preferredWidth: privateProps.cellWidth*2 - 10
                        Layout.bottomMargin: 5

                        QQC2.Label {
                            Layout.fillWidth: false
                            Layout.fillHeight: false
                            Layout.alignment: Qt.AlignHCenter
                            font.pointSize: 14
                            text: qsTr("T%1-Slot%2")
                                    .arg(zynthian.session_dashboard.selectedTrack + 1)
                                    .arg(root.selectedSlotRowItem.selectedRow + 1)
                        }
                        QQC2.Label {
                            Layout.fillWidth: false
                            Layout.fillHeight: false
                            Layout.alignment: Qt.AlignHCenter
                            visible: synthsButton.checked
                            font.pointSize: 12
                            text: qsTr("Synth")
                        }
                        QQC2.Label {
                            Layout.fillWidth: false
                            Layout.fillHeight: false
                            Layout.alignment: Qt.AlignHCenter
                            font.pointSize: 12
                            visible: fxButton.checked
                            text: qsTr("Fx")
                        }
                        QQC2.Label {
                            Layout.fillWidth: false
                            Layout.fillHeight: false
                            Layout.alignment: Qt.AlignHCenter
                            font.pointSize: 12
                            visible: samplesButton.checked
                            text: qsTr("Sample")
                        }

                        Kirigami.Separator {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: 1
                        }

                        Rectangle {
                            clip: true
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: detailsText.height + 20
                            Layout.alignment: Qt.AlignHCenter

                            Kirigami.Theme.inherit: false
                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                            color: Kirigami.Theme.backgroundColor

                            border.color: "#ff999999"
                            border.width: 1
                            radius: 4

                            QQC2.Label {
                                id: detailsText
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    leftMargin: 10
                                    right: parent.right
                                    rightMargin: 10
                                }
                                wrapMode: "WrapAnywhere"
                                font.pointSize: 10
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (synthsButton.checked) {
                                        // Clicked entry is synth

                                        var chainedSound = root.selectedSlotRowItem.track.chainedSounds[root.selectedSlotRowItem.selectedRow]

                                        if (root.selectedSlotRowItem.track.checkIfLayerExists(chainedSound)) {
                                            // Handle Click
                                            zynthian.layer.page_after_layer_creation = "layers_for_track";
                                            zynthian.fixed_layers.activate_index(chainedSound);
                                            zynthian.layer.select_engine(chainedSound);
                                        } else if (!root.selectedSlotRowItem.track.createChainedSoundInNextFreeLayer(root.selectedSlotRowItem.selectedRow)) {
                                            noFreeSlotsPopup.open();
                                        } else {
                                            // Enable layer popup rejected handler to re-select connected sound if any
                                            layerPopupRejectedConnections.enabled = true;

                                            zynthian.layer.page_after_layer_creation = "session_dashboard";
                                            applicationWindow().requestOpenLayerSetupDialog();
                                            //this depends on requirements
                                            backToSelection.screenToGetBack = zynthian.current_screen_id;
                                            backToSelection.enabled = true;

                                            if (root.selectedSlotRowItem.track.connectedPattern >= 0) {
                                                var pattern = ZynQuick.PlayGridManager.getSequenceModel("Scene "+zynthian.zynthiloops.song.scenesModel.selectedSceneName).get(root.selectedSlotRowItem.track.connectedPattern);
                                                pattern.midiChannel = root.selectedSlotRowItem.track.connectedSound;
                                            }
                                        }
                                    } else if (fxButton.checked) {
                                        // Clicked entry is fx
                                        var chainedSound = root.selectedSlotRowItem.track.chainedSounds[root.selectedSlotRowItem.selectedRow]

                                        zynthian.fixed_layers.activate_index(chainedSound)
                                        zynthian.layer_options.show();
                                        var screenBack = zynthian.current_screen_id;
                                        zynthian.current_screen_id = "layer_effects";
                                        root.openBottomDrawerOnLoad = true;
                                        zynthian.forced_screen_back = screenBack;
                                    } else if (samplesButton.checked) {
                                        // Clicked entry is samples
                                        samplePickerPopup.open()
                                    }
                                }
                            }
                        }

                        Connections {
                            target: bottomStack
                            onCurrentIndexChanged: detailsTextTimer.restart()
                        }
                        Connections {
                            enabled: bottomStack.currentIndex === 2
                            target: zynthian.session_dashboard
                            onSelectedTrackChanged: detailsTextTimer.restart()
                        }
                        Connections {
                            enabled: bottomStack.currentIndex === 2 && root.selectedSlotRowItem != null && root.selectedSlotRowItem.track != null
                            target: root.selectedSlotRowItem
                            onSelectedRowChanged: detailsTextTimer.restart()
                        }
                        Connections {
                            enabled: bottomStack.currentIndex === 2 && root.selectedSlotRowItem != null && root.selectedSlotRowItem.track != null
                            target: root.selectedSlotRowItem.track
                            onChainedSoundsChanged: detailsTextTimer.restart()
                            onSamplesChanged: detailsTextTimer.restart()
                        }
                        Connections {
                            enabled: bottomStack.currentIndex === 2
                            target: synthsButton
                            onCheckedChanged: detailsTextTimer.restart()
                        }
                        Connections {
                            enabled: bottomStack.currentIndex === 2
                            target: fxButton
                            onCheckedChanged: detailsTextTimer.restart()
                        }
                        Connections {
                            enabled: bottomStack.currentIndex === 2
                            target: samplesButton
                            onCheckedChanged: detailsTextTimer.restart()
                        }

                        Timer {
                            id: detailsTextTimer
                            interval: 0
                            repeat: false
                            onTriggered: {
                                console.log("### Updating details timer ")
                                detailsText.text = root.selectedSlotRowItem
                                                    ? synthsButton.checked && root.selectedSlotRowItem.track.chainedSounds[root.selectedSlotRowItem.selectedRow] > -1 && root.selectedSlotRowItem.track.checkIfLayerExists(root.selectedSlotRowItem.track.chainedSounds[root.selectedSlotRowItem.selectedRow])
                                                        ? root.selectedSlotRowItem.track.getLayerNameByMidiChannel(root.selectedSlotRowItem.track.chainedSounds[root.selectedSlotRowItem.selectedRow]).split(">")[0]
                                                        : fxButton.checked && root.selectedSlotRowItem.track.chainedSounds[root.selectedSlotRowItem.selectedRow] > -1 && root.selectedSlotRowItem.track.checkIfLayerExists(root.selectedSlotRowItem.track.chainedSounds[root.selectedSlotRowItem.selectedRow])
                                                            ? root.selectedSlotRowItem.track.getEffectsNameByMidiChannel(root.selectedSlotRowItem.track.chainedSounds[root.selectedSlotRowItem.selectedRow])
                                                            : samplesButton.checked && root.selectedSlotRowItem.track.samples[root.selectedSlotRowItem.selectedRow].path
                                                                ? root.selectedSlotRowItem.track.samples[root.selectedSlotRowItem.selectedRow].path.split("/").pop()
                                                                : ""
                                                    : ""
                            }
                        }
                    }

                    Kirigami.Separator {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: "#ff31363b"
                    }
                }
            }
        }
    }

    QQC2.Popup {
        id: noFreeSlotsPopup
        x: Math.round(parent.width/2 - width/2)
        y: Math.round(parent.height/2 - height/2)
        width: Kirigami.Units.gridUnit*12
        height: Kirigami.Units.gridUnit*4
        modal: true

        QQC2.Label {
            width: parent.width
            height: parent.height
            horizontalAlignment: "AlignHCenter"
            verticalAlignment: "AlignVCenter"
            text: qsTr("No free slots remaining")
            font.italic: true
        }
    }

    QQC2.Popup {
        id: samplePickerPopup

        x: Math.round(parent.width/2 - width/2)
        y: Math.round(parent.height/2 - height/2)
        width: Kirigami.Units.gridUnit*12
        modal: true

        ColumnLayout {
            anchors.fill: parent

            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignCenter
                text: qsTr("Pick sample for slot")

                onClicked: {
                }
            }

            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignCenter
                text: qsTr("Pick bank for track")

                onClicked: {
                }
            }
        }
    }
}
