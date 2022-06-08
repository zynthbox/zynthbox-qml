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
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls.Styles 1.4

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick
import JuceGraphics 1.0

Rectangle {
    id: root

    readonly property QtObject song: zynthian.zynthiloops.song
    readonly property QtObject selectedTrack: applicationWindow().selectedTrack
    property QtObject sequence: root.selectedTrack ? ZynQuick.PlayGridManager.getSequenceModel(zynthian.zynthiloops.song.scenesModel.selectedMixName) : null
    property QtObject pattern: root.sequence && root.selectedTrack ? root.sequence.getByPart(root.selectedTrack.id, root.selectedTrack.selectedPart) : null


    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    function cuiaCallback(cuia) {
        var returnValue = false;
        if (bouncePopup.opened) {
            returnValue = bouncePopup.cuiaCallback(cuia);
        } if (externalMidiChannelPicker.opened) {
            returnValue = externalMidiChannelPicker.cuiaCallback(cuia);
        } else {
            switch (cuia) {
                case "SWITCH_TRACKS_MOD_SHORT":
                    returnValue = true;
                    break;

                case "NAVIGATE_LEFT":
                    if (zynthian.session_dashboard.selectedTrack > 0) {
                        zynthian.session_dashboard.selectedTrack -= 1;
                    }
                    returnValue = true;
                    break;

                case "NAVIGATE_RIGHT":
                    if (zynthian.session_dashboard.selectedTrack < 9) {
                        zynthian.session_dashboard.selectedTrack += 1;
                    }
                    returnValue = true;
                    break;

                case "SELECT_UP":
                    if (root.selectedTrack.trackAudioType === "sample-trig") {
                        if (root.selectedTrack.selectedSlotRow > 0) {
                            root.selectedTrack.selectedSlotRow -= 1;
                        }
                        returnValue = true;
                    }
                    break;

                case "SELECT_DOWN":
                    if (root.selectedTrack.trackAudioType === "sample-trig") {
                        if (root.selectedTrack.selectedSlotRow < 4) {
                            root.selectedTrack.selectedSlotRow += 1;
                        }
                        returnValue = true;
                    }
                    break;
            }
        }
        return returnValue;
    }

    QtObject {
        id: privateProps

        //Try to fit exactly 12 mixers + a master mixer
        property int cellWidth: (tableLayout.width - loopGrid.columnSpacing)/13
    }

    QQC2.Popup {
        id: trackKeyZoneSetup
        parent: QQC2.Overlay.overlay
        y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
        x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
        exit: null; enter: null; // Disable the enter and exit transition animations. TODO This really wants doing somewhere central...
        modal: true
        focus: true
        TrackKeyZoneSetup {
            anchors.fill: parent
            implicitWidth: root.width
            implicitHeight: root.height
            readonly property QtObject song: zynthian.zynthiloops.song
            selectedTrack: song ? song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack) : null
        }
    }

    BouncePopup {
        id: bouncePopup
    }
    ExternalMidiChannelPicker {
        id: externalMidiChannelPicker
    }

    GridLayout {
        rows: 1
        anchors.fill: parent

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true

            QQC2.ButtonGroup {
                buttons: tabButtons.children
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

                    BottomStackTabs {
                        id: buttonsColumn
                        Layout.minimumWidth: privateProps.cellWidth*1.5 + 6
                        Layout.maximumWidth: privateProps.cellWidth*1.5 + 6
                        Layout.bottomMargin: 5
                        Layout.fillHeight: true
                    }

                    ColumnLayout {
                        id: contentColumn
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: Kirigami.Units.gridUnit / 2

                        RowLayout {
                            id: tabButtons
                            Layout.fillWidth: true
                            Layout.fillHeight: false

                            EditableHeader {
                                Layout.minimumWidth: parent.width / 4
                                Layout.maximumWidth: parent.width / 4
                                property QtObject controlObj: root.selectedTrack
                                property int controlType: BottomBar.ControlType.Track

                                text: qsTr("TRACK: %1").arg(controlObj ? controlObj.name : "")
                            }

                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                                Layout.fillHeight: false
                                checkable: true
                                checked: root.selectedTrack.trackAudioType === "synth"
                                text: qsTr("Synth")
                                onClicked: root.selectedTrack.trackAudioType = "synth"
                            }
                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                                Layout.fillHeight: false
                                checkable: true
                                checked: root.selectedTrack.trackAudioType === "sample-trig" ||
                                         root.selectedTrack.trackAudioType === "sample-slice"
                                text: qsTr("Samples")
                                onClicked: root.selectedTrack.trackAudioType = "sample-trig"
                            }
                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                                Layout.fillHeight: false
                                checkable: true
                                checked: root.selectedTrack.trackAudioType === "sample-loop"
                                text: qsTr("Loop")
                                onClicked: root.selectedTrack.trackAudioType = "sample-loop"
                            }
                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                                Layout.fillHeight: false
                                checkable: true
                                checked: root.selectedTrack.trackAudioType === "external"
                                text: qsTr("External")
                                onClicked: root.selectedTrack.trackAudioType = "external"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Kirigami.Units.gridUnit

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5

                                RowLayout {
                                    anchors.fill: parent

                                    RowLayout {
                                        visible: root.selectedTrack.trackAudioType === "sample-trig" ||
                                                 root.selectedTrack.trackAudioType === "sample-slice"
                                        Layout.fillHeight: true
                                        spacing: 0

                                        QQC2.Button {
                                            Layout.fillHeight: true
                                            text: "Trig"
                                            checked: root.selectedTrack && root.selectedTrack.trackAudioType === "sample-trig"
                                            onClicked: {
                                                root.selectedTrack.trackAudioType = "sample-trig"
                                            }
                                        }
                                        QQC2.Button {
                                            Layout.fillHeight: true
                                            text: "Slice"
                                            checked: root.selectedTrack && root.selectedTrack.trackAudioType === "sample-slice"
                                            onClicked: {
                                                root.selectedTrack.trackAudioType = "sample-slice"
                                            }
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    RowLayout {
                                        Layout.fillHeight: true
                                        visible: root.selectedTrack.trackAudioType === "external"

                                        QQC2.Button {
                                            Layout.fillHeight: true
                                            text: qsTr("External Midi Channel: %1").arg(root.selectedTrack ? (root.selectedTrack.externalMidiChannel > -1 ? root.selectedTrack.externalMidiChannel + 1 : root.selectedTrack.id + 1) : "")
                                            onClicked: {
                                                externalMidiChannelPicker.pickChannel(root.selectedTrack);
                                            }
                                        }
                                        Item {
                                            Layout.fillWidth: false
                                            Layout.fillHeight: false
                                            Layout.preferredWidth: Kirigami.Units.gridUnit
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillHeight: true
                                        visible: root.selectedTrack.trackAudioType === "sample-trig"

                                        QQC2.Label {
                                            Layout.fillHeight: true
                                            text: "Auto Split:"
                                        }
                                        RowLayout {
                                            Layout.fillHeight: true
                                            spacing: 0
                                            QQC2.Button {
                                                Layout.fillHeight: true
                                                text: "Off"
                                                checked: root.selectedTrack && root.selectedTrack.keyZoneMode === "all-full"
                                                onClicked: {
                                                    root.selectedTrack.keyZoneMode = "all-full";
                                                }
                                            }
                                            QQC2.Button {
                                                Layout.fillHeight: true
                                                text: "Auto"
                                                checked: root.selectedTrack && root.selectedTrack.keyZoneMode === "split-full"
                                                onClicked: {
                                                    root.selectedTrack.keyZoneMode = "split-full";
                                                }
                                            }
                                            QQC2.Button {
                                                Layout.fillHeight: true
                                                text: "Narrow"
                                                checked: root.selectedTrack && root.selectedTrack.keyZoneMode === "split-narrow"
                                                onClicked: {
                                                    root.selectedTrack.keyZoneMode = "split-narrow";
                                                }
                                            }
                                        }
                                        QQC2.Button {
                                            Layout.fillHeight: true
                                            icon.name: "timeline-use-zone-on"
                                            onClicked: {
                                                trackKeyZoneSetup.open();
                                            }
                                        }
                                        Item {
                                            Layout.fillWidth: false
                                            Layout.fillHeight: false
                                            Layout.preferredWidth: Kirigami.Units.gridUnit
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillHeight: true
                                        visible: root.selectedTrack.trackAudioType === "sample-trig" ||
                                                 root.selectedTrack.trackAudioType === "sample-slice" ||
                                                 root.selectedTrack.trackAudioType === "synth"
                                        QQC2.Button {
                                            Layout.fillHeight: true
                                            text: "Bounce To Loop"
                                            onClicked: {
                                                bouncePopup.bounce(zynthian.zynthiloops.song.scenesModel.selectedMixName, root.selectedTrack);
                                            }
                                        }
                                        Item {
                                            Layout.fillWidth: false
                                            Layout.fillHeight: false
                                            Layout.preferredWidth: Kirigami.Units.gridUnit
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                                Repeater {
                                    model: visible
                                    ? (root.selectedTrack.trackAudioType === "synth"
                                            ? root.selectedTrack.chainedSoundsNames
                                            : root.selectedTrack.trackAudioType === "sample-trig" ||
                                              root.selectedTrack.trackAudioType === "sample-slice"
                                                ? root.selectedTrack.samples
                                                : root.selectedTrack.trackAudioType === "sample-loop"
                                                    ? [root.selectedTrack.clipsModel.getClip(zynthian.zynthiloops.song.scenesModel.selectedMixIndex), null, null, null, null]
                                                    : [])
                                    : null

                                    delegate: Rectangle {
                                        property bool highlighted: root.selectedTrack.selectedSlotRow === index

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                                        border.color: highlighted ? Kirigami.Theme.highlightColor : "transparent"
                                        border.width: 2
                                        color: "transparent"
                                        radius: 4

                                        Rectangle {
                                            id: delegate

                                            property QtObject volumeControlObj: zynthian.layers_for_track.volume_controls[index]
                                            property real volumePercent: volumeControlObj
                                                                            ? (volumeControlObj.value - volumeControlObj.value_min)/(volumeControlObj.value_max - volumeControlObj.value_min)
                                                                            : 0

                                            anchors.fill: parent
                                            anchors.margins: 4

                                            Kirigami.Theme.inherit: false
                                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                            color: Kirigami.Theme.backgroundColor

                                            border.color: "#ff999999"
                                            border.width: 1
                                            radius: 4

                                            // For loop and slice modes only first slot is visible.
                                            // For other modes all slots are visible
                                            enabled: root.selectedTrack.trackAudioType === "sample-loop" ||
                                                     root.selectedTrack.trackAudioType === "sample-slice"
                                                        ? index === 0
                                                        : true
                                            opacity: enabled ? 1 : 0

                                            Rectangle {
                                                width: parent.width * delegate.volumePercent
                                                anchors {
                                                    left: parent.left
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                }
                                                visible: root.selectedTrack.trackAudioType === "synth" &&
                                                         synthNameLabel.text.trim().length > 0

                                                color: Kirigami.Theme.highlightColor
                                            }

                                            QQC2.Label {
                                                id: synthNameLabel
                                                anchors {
                                                    verticalCenter: parent.verticalCenter
                                                    left: parent.left
                                                    right: parent.right
                                                    leftMargin: Kirigami.Units.gridUnit*0.5
                                                    rightMargin: Kirigami.Units.gridUnit*0.5
                                                }
                                                horizontalAlignment: Text.AlignLeft
                                                text: root.selectedTrack.trackAudioType === "synth"
                                                        ? modelData
                                                        : (root.selectedTrack.trackAudioType === "sample-trig" ||
                                                          root.selectedTrack.trackAudioType === "sample-slice" ||
                                                          root.selectedTrack.trackAudioType === "sample-loop") &&
                                                          modelData
                                                            ? modelData.path.split("/").pop()
                                                            : ""

                                                elide: "ElideRight"
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    if (index !== root.selectedTrack.selectedSlotRow) {
                                                        root.selectedTrack.selectedSlotRow = index
                                                    } else {
                                                        bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: Kirigami.Units.gridUnit / 2

                                // Take 3/5 th of available width
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                                    color: "#222222"
                                    border.width: 1
                                    border.color: "#ff999999"
                                    radius: 4

                                    WaveFormItem {
                                        property QtObject clip: root.selectedTrack.trackAudioType === "sample-loop"
                                                                    ? root.selectedTrack.clipsModel.getClip(zynthian.zynthiloops.song.scenesModel.selectedMixIndex)
                                                                    : root.selectedTrack.samples[root.selectedTrack.selectedSlotRow]

                                        anchors.fill: parent
                                        color: Kirigami.Theme.textColor
                                        source: clip ? clip.path : ""

                                        visible: (root.selectedTrack.trackAudioType === "sample-trig" ||
                                                  root.selectedTrack.trackAudioType === "sample-slice" ||
                                                  root.selectedTrack.trackAudioType === "sample-loop") &&
                                                 clip && clip.path && clip.path.length > 0

                                        // Mask for wave part before start
                                        Rectangle {
                                            anchors {
                                                top: parent.top
                                                bottom: parent.bottom
                                                left: parent.left
                                                right: startLoopLine.left
                                            }
                                            color: "#99000000"
                                        }

                                        // Mask for wave part after
                                        Rectangle {
                                            anchors {
                                                top: parent.top
                                                bottom: parent.bottom
                                                left: endLoopLine.right
                                                right: parent.right
                                            }
                                            color: "#99000000"
                                        }

                                        // Start loop line
                                        Rectangle {
                                            id: startLoopLine
                                            anchors {
                                                top: parent.top
                                                bottom: parent.bottom
                                            }
                                            color: Kirigami.Theme.positiveTextColor
                                            opacity: 0.6
                                            width: Kirigami.Units.smallSpacing
                                            x: (parent.clip.startPosition / parent.clip.duration) * parent.width
                                        }

                                        // End loop line
                                        Rectangle {
                                            id: endLoopLine
                                            anchors {
                                                top: parent.top
                                                bottom: parent.bottom
                                            }
                                            color: Kirigami.Theme.neutralTextColor
                                            opacity: 0.6
                                            width: Kirigami.Units.smallSpacing
                                            x: ((((60/zynthian.zynthiloops.song.bpm) * parent.clip.length) / parent.clip.duration) * parent.width) + ((parent.clip.startPosition / parent.clip.duration) * parent.width)
                                        }

                                        // Progress line
                                        Rectangle {
                                            anchors {
                                                top: parent.top
                                                bottom: parent.bottom
                                            }
                                            visible: root.visible && parent.clip.isPlaying
                                            color: Kirigami.Theme.highlightColor
                                            width: Kirigami.Units.smallSpacing
                                            x: visible ? parent.clip.progress/parent.clip.duration * parent.width : 0
                                        }

                                        // SamplerSynth progress dots
                                        Repeater {
                                            property QtObject cppClipObject: parent.visible ? ZynQuick.PlayGridManager.getClipById(parent.clip.cppObjId) : null;
                                            model: (root.visible && root.selectedTrack.trackAudioType === "sample-slice" || root.selectedTrack.trackAudioType === "sample-trig") && cppClipObject
                                                ? cppClipObject.playbackPositions
                                                : 0
                                            delegate: Item {
                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    rotation: 45
                                                    color: Kirigami.Theme.highlightColor
                                                    width: Kirigami.Units.largeSpacing
                                                    height:  Kirigami.Units.largeSpacing
                                                    scale: 0.5 + model.positionGain
                                                }
                                                anchors.verticalCenter: parent.verticalCenter
                                                x: Math.floor(model.positionProgress * parent.width)
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (root.selectedTrack.trackAudioType === "sample-loop") {
                                                var clip = root.selectedTrack.clipsModel.getClip(zynthian.zynthiloops.song.scenesModel.selectedMixIndex)

                                                if (clip && clip.path && clip.path.length > 0) {
                                                    bottomStack.bottomBar.controlType = BottomBar.ControlType.Pattern;
                                                    bottomStack.bottomBar.controlObj = root.selectedTrack.clipsModel.getClip(zynthian.zynthiloops.song.scenesModel.selectedMixIndex);
                                                    bottomStack.slotsBar.bottomBarButton.checked = true;
                                                    bottomStack.bottomBar.waveEditorAction.trigger();
                                                }
                                            } else {
                                                var clip = root.selectedTrack.samples[root.selectedTrack.selectedSlotRow]

                                                if (clip && clip.path && clip.path.length > 0) {
                                                    bottomStack.bottomBar.controlType = BottomBar.ControlType.Track;
                                                    bottomStack.bottomBar.controlObj = root.selectedTrack;
                                                    bottomStack.slotsBar.bottomBarButton.checked = true;
                                                    bottomStack.bottomBar.trackWaveEditorAction.trigger();
                                                }
                                            }
                                        }
                                    }
                                }

                                // Take remaining available width
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2

                                    border.width: 1
                                    border.color: "#ff999999"
                                    radius: 4
                                    color: "#222222"
                                    clip: true

                                    Image {
                                        id: patternVisualiser

                                        visible: root.selectedTrack &&
                                                 root.selectedTrack.connectedPattern >= 0 &&
                                                 (root.selectedTrack.trackAudioType === "synth" ||
                                                  root.selectedTrack.trackAudioType === "external" ||
                                                  root.selectedTrack.trackAudioType === "sample-trig" ||
                                                  root.selectedTrack.trackAudioType === "sample-slice")

                                        anchors {
                                            fill: parent
                                            centerIn: parent
                                            topMargin: 3
                                            leftMargin: 3
                                            rightMargin: 3
                                            bottomMargin: 2
                                        }
                                        smooth: false
                                        source: root.pattern ? root.pattern.thumbnailUrl : ""
                                        Rectangle { // Progress
                                            anchors {
                                                top: parent.top
                                                bottom: parent.bottom
                                            }
                                            visible: root.visible &&
                                                     root.sequence &&
                                                     root.sequence.isPlaying &&
                                                     root.pattern &&
                                                     root.pattern.enabled
                                            color: Kirigami.Theme.highlightColor
                                            width: widthFactor // this way the progress rect is the same width as a step
                                            property double widthFactor: visible && root.pattern ? parent.width / (root.pattern.width * root.pattern.bankLength) : 1
                                            x: visible && root.pattern ? root.pattern.bankPlaybackPosition * widthFactor : 0
                                        }
                                        MouseArea {
                                            anchors.fill:parent
                                            onClicked: {
                                                var screenBack = zynthian.current_screen_id;
                                                zynthian.current_modal_screen_id = "playgrid";
                                                zynthian.forced_screen_back = "zynthiloops";
                                                ZynQuick.PlayGridManager.setCurrentPlaygrid("playgrid", ZynQuick.PlayGridManager.sequenceEditorIndex);
                                                var sequence = ZynQuick.PlayGridManager.getSequenceModel(zynthian.zynthiloops.song.scenesModel.selectedMixName);
                                                sequence.setActiveTrack(root.selectedTrack.id, root.selectedTrack.selectedPart);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
