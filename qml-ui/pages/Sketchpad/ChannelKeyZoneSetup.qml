/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

KeyZone setup component for Sketchpad Channels

Copyright (C) 2022 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import io.zynthbox.components 1.0 as Zynthbox
Zynthian.DialogQuestion {
    id: component
    x: 0
    y: 0
    width: applicationWindow().width + thisIsCheating
    height: applicationWindow().height + thisIsCheating
    property int thisIsCheating: 0
    readonly property QtObject song: zynqtgui.sketchpad.song
    property QtObject selectedChannel: null

    title: selectedChannel ? qsTr("Set up keyzones on Track %1").arg(selectedChannel.name) : ""
    acceptText: qsTr("Back")
    rejectText: ""

    onOpenedChanged: {
        if (component.opened) {
            // In the wildly unlikely case we've not got a channel set yet, fix that
            if (component.selectedChannel == null) {
                zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId);
            }
            // If the selected slot is not either a synth or sample slot, fix that
            if (["TracksBar_synthslot", "TracksBar_sampleslot"].includes(component.selectedChannel.selectedSlot.className) == false) {
                let tracksBar = pageManager.getPage("sketchpad").bottomStack.tracksBar;
                tracksBar.switchToSlot("synth", 0, true);
                tracksBar.pickFirstAndBestSlot(true);
            }
        }
    }

    property var cuiaCallback: function(cuia) {
        let returnValue = true;
        let clipObj = null;
        switch (cuia) {
            case "KNOB0_UP":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    if (component.selectedChannel.selectedSlot.className === "TracksBar_synthslot") {
                        clipObj = component.selectedChannel.chainedSoundsKeyzones[component.selectedChannel.selectedSlotRow];
                    } else {
                        clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId).selectedSliceObject;
                    }
                    clipObj.keyZoneStart = Math.min(clipObj.keyZoneStart + 1, 127);
                    component.selectedChannel.keyZoneMode = "manual";
                }
                break;
            case "KNOB0_DOWN":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    if (component.selectedChannel.selectedSlot.className === "TracksBar_synthslot") {
                        clipObj = component.selectedChannel.chainedSoundsKeyzones[component.selectedChannel.selectedSlotRow];
                    } else {
                        clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId).selectedSliceObject;
                    }
                    clipObj.keyZoneStart = Math.max(clipObj.keyZoneStart - 1, -1);
                    component.selectedChannel.keyZoneMode = "manual";
                }
                break;
            case "KNOB1_UP":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    if (component.selectedChannel.selectedSlot.className === "TracksBar_synthslot") {
                        clipObj = component.selectedChannel.chainedSoundsKeyzones[component.selectedChannel.selectedSlotRow];
                    } else {
                        clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId).selectedSliceObject;
                    }
                    clipObj.keyZoneEnd = Math.min(clipObj.keyZoneEnd + 1, 127);
                    component.selectedChannel.keyZoneMode = "manual";
                }
                break;
            case "KNOB1_DOWN":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    if (component.selectedChannel.selectedSlot.className === "TracksBar_synthslot") {
                        clipObj = component.selectedChannel.chainedSoundsKeyzones[component.selectedChannel.selectedSlotRow];
                    } else {
                        clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId).selectedSliceObject;
                    }
                    clipObj.keyZoneEnd = Math.max(clipObj.keyZoneEnd - 1, -1);
                    component.selectedChannel.keyZoneMode = "manual";
                }
                break;
            case "KNOB2_UP":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    if (component.selectedChannel.selectedSlot.className === "TracksBar_synthslot") {
                        clipObj = component.selectedChannel.chainedSoundsKeyzones[component.selectedChannel.selectedSlotRow];
                    } else {
                        clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId).selectedSliceObject;
                    }
                    clipObj.rootNote = Math.min(clipObj.rootNote + 1, 127);
                    component.selectedChannel.keyZoneMode = "manual";
                }
                break;
            case "KNOB2_DOWN":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    if (component.selectedChannel.selectedSlot.className === "TracksBar_synthslot") {
                        clipObj = component.selectedChannel.chainedSoundsKeyzones[component.selectedChannel.selectedSlotRow];
                    } else {
                        clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId).selectedSliceObject;
                    }
                    clipObj.rootNote = Math.max(clipObj.rootNote - 1, 0);
                    component.selectedChannel.keyZoneMode = "manual";
                }
                break;
            case "KNOB3_UP":
            case "NAVIGATE_RIGHT":
                // Move between synth and sample slots (so just rotate between those two, not others)
                if (component.selectedChannel) {
                    let tracksBar = pageManager.getPage("sketchpad").bottomStack.tracksBar;
                    if (component.selectedChannel.selectedSlot.value === 4) {
                        if (component.selectedChannel.selectedSlot.className === "TracksBar_synthslot") {
                            tracksBar.switchToSlot("sample", 0, true);
                        } else {
                            tracksBar.switchToSlot("synth", 0, true);
                        }
                    } else {
                        tracksBar.pickNextSlot(true);
                    }
                    component.thisIsCheating = 1;
                    component.thisIsCheating = 0;
                }
                break;
            case "KNOB3_DOWN":
            case "NAVIGATE_LEFT":
                // Move between synth and sample slots (so just rotate between those two, not others)
                if (component.selectedChannel) {
                    let tracksBar = pageManager.getPage("sketchpad").bottomStack.tracksBar;
                    if (component.selectedChannel.selectedSlot.value === 0) {
                        if (component.selectedChannel.selectedSlot.className === "TracksBar_synthslot") {
                            tracksBar.switchToSlot("sample", 4, true);
                        } else {
                            tracksBar.switchToSlot("synth", 4, true);
                        }
                    } else {
                        tracksBar.pickPreviousSlot(true);
                    }
                    component.thisIsCheating = 1;
                    component.thisIsCheating = 0;
                }
                break;
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_SELECT_SHORT":
                component.accept();
                break;
        }
        return returnValue;
    }

    contentItem: ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        spacing: 0
        RowLayout {
            id: currentSlotControls
            Layout.fillWidth: true
            property int index: component.selectedChannel ? component.selectedChannel.selectedSlot.value : 0
            property var channelSample: component.selectedChannel && component.selectedChannel.selectedSlot.className === "TracksBar_sampleslot" ? component.selectedChannel.samples && component.selectedChannel.samples[index] : null
            property int engineMidiChannel: component.selectedChannel && component.selectedChannel.selectedSlot.className === "TracksBar_synthslot" ? component.selectedChannel.chainedSounds[index] : -1
            property QtObject clipObj: component.selectedChannel && component.selectedChannel.selectedSlot.className === "TracksBar_synthslot"
                ? engineMidiChannel > -1 && component.selectedChannel.checkIfLayerExists(engineMidiChannel) ? component.selectedChannel.chainedSoundsKeyzones[index] : null
                : channelSample ? Zynthbox.PlayGridManager.getClipById(channelSample.cppObjId) : null
            property QtObject keyZoneContainer: component.selectedChannel
                ? component.selectedChannel.selectedSlot.className === "TracksBar_synthslot"
                    ? (clipObj === undefined ? null : clipObj)
                    : (clipObj === null || clipObj.selectedSliceObject === undefined ? null : clipObj.selectedSliceObject)
                : null
            Item {
                Layout.fillWidth: true
                Timer {
                    id: keyZoneSetupSelectedChannelThrottle
                    interval: 1; running: false; repeat: false;
                    onTriggered: {
                        component.selectedChannel = zynqtgui.sketchpad.song ? zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId) : null;
                    }
                }
                Connections {
                    target: applicationWindow()
                    onSelectedChannelChanged: keyZoneSetupSelectedChannelThrottle.restart()
                }
                Component.onCompleted: {
                    keyZoneSetupSelectedChannelThrottle.restart()
                }
                Connections {
                    target: component.song
                    onIsLoadingChanged: {
                        if (component.song.isLoading == false) {
                            keyZoneSetupSelectedChannelThrottle.restart();
                        }
                    }
                }
                Connections {
                    target: component
                    onSongChanged: {
                        keyZoneSetupSelectedChannelThrottle.restart();
                    }
                }
            }
            QQC2.Label {
                text: component.selectedChannel
                    ? component.selectedChannel.selectedSlot.className === "TracksBar_synthslot"
                        ? "Synth %1".arg(currentSlotControls.index + 1)
                        : "Sample %1".arg(currentSlotControls.index + 1)
                    : ""
            }
            QQC2.Button {
                enabled: currentSlotControls.keyZoneContainer !== null
                text: "Disable"
                onClicked: {
                    currentSlotControls.keyZoneContainer.keyZoneStart = -1;
                    currentSlotControls.keyZoneContainer.keyZoneEnd = -1;
                    component.selectedChannel.keyZoneMode = "manual";
                }
            }
            QQC2.Button {
                enabled: currentSlotControls.keyZoneContainer !== null
                text: "Assign Full Width"
                onClicked: {
                    currentSlotControls.keyZoneContainer.keyZoneStart = 0;
                    currentSlotControls.keyZoneContainer.keyZoneEnd = 127;
                    component.selectedChannel.keyZoneMode = "manual";
                }
            }
            QQC2.Button {
                enabled: currentSlotControls.keyZoneContainer !== null
                text: "Assign To Lower Split"
                onClicked: {
                    currentSlotControls.keyZoneContainer.keyZoneStart = 0;
                    currentSlotControls.keyZoneContainer.keyZoneEnd = 60;
                    component.selectedChannel.keyZoneMode = "manual";
                }
            }
            QQC2.Button {
                enabled: currentSlotControls.keyZoneContainer !== null
                text: "Assign To Upper Split"
                onClicked: {
                    currentSlotControls.keyZoneContainer.keyZoneStart = 61;
                    currentSlotControls.keyZoneContainer.keyZoneEnd = 127;
                    component.selectedChannel.keyZoneMode = "manual";
                }
            }
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                Layout.margins: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.disabledTextColor
            }
            QQC2.Label {
                text: "All:"
            }
            QQC2.Button {
                text: "Set To Full"
                checked: component.selectedChannel && component.selectedChannel.keyZoneMode == "all-full";
                onClicked: {
                    if (component.selectedChannel) {
                        component.selectedChannel.keyZoneMode = "all-full";
                    }
                }
            }
            QQC2.Button {
                text: "Split Full"
                checked: component.selectedChannel && component.selectedChannel.keyZoneMode == "split-full";
                onClicked: {
                    if (component.selectedChannel) {
                        component.selectedChannel.keyZoneMode = "split-full";
                    }
                }
            }
            QQC2.Button {
                text: "Split Narrow"
                checked: component.selectedChannel && component.selectedChannel.keyZoneMode == "split-narrow";
                onClicked: {
                    if (component.selectedChannel) {
                        component.selectedChannel.keyZoneMode = "split-narrow";
                    }
                }
            }
            QQC2.Button {
                text: "Manual"
                checked: component.selectedChannel && component.selectedChannel.keyZoneMode == "manual";
                onClicked: {
                    if (component.selectedChannel) {
                        component.selectedChannel.keyZoneMode = "manual";
                    }
                }
            }
        }
        Item {
            Layout.preferredHeight: parent.height * 2 / 3
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Math.floor(((parent.height / 6) - 5) / 2)
            // property double positioningHelp: width / 100
            Repeater {
                id: slotTypeRepeater
                // This is the number of slots we're displaying, plus one for spacing (so the root note display has somewhere to live)
                readonly property int totalDisplayRowCount: 11
                model: 2
                Repeater {
                    id: slotRepeater
                    readonly property string slotType: index === 0 ? "TracksBar_synthslot" : "TracksBar_sampleslot"
                    readonly property int slotTypeIndex: index
                    model: 5
                    delegate: Item {
                        id: sampleKeyzoneDelegate
                        property var channelSample: component.selectedChannel && slotRepeater.slotType === "TracksBar_sampleslot" ? component.selectedChannel.samples && component.selectedChannel.samples[index] : null
                        property int engineMidiChannel: component.selectedChannel && slotRepeater.slotType === "TracksBar_synthslot" ? component.selectedChannel.chainedSounds[index] : -1
                        property QtObject clipObj: component.selectedChannel && slotRepeater.slotType === "TracksBar_synthslot"
                            ? engineMidiChannel > -1 && component.selectedChannel.checkIfLayerExists(engineMidiChannel) ? component.selectedChannel.chainedSoundsKeyzones[index] : null
                            : channelSample ? Zynthbox.PlayGridManager.getClipById(channelSample.cppObjId) : null
                        property QtObject keyZoneContainer: component.selectedChannel
                            ? slotRepeater.slotType === "TracksBar_synthslot"
                                ? (clipObj === undefined ? null : clipObj)
                                : (clipObj === null || clipObj.selectedSliceObject === undefined ? null : clipObj.selectedSliceObject)
                            : null
                        readonly property int combinedIndex: (slotRepeater.slotTypeIndex * 5) + index;
                        height: parent.height;
                        width: 1
                        property bool isCurrent: component.selectedChannel ? component.selectedChannel.selectedSlot.className === slotRepeater.slotType && component.selectedChannel.selectedSlot.value === index : false
                        z: isCurrent ? 99 : 0
                        property color lineColor: isCurrent ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                        property Item pianoKeyItem: keyZoneContainer ? pianoKeysRepeater.itemAt(keyZoneContainer.keyZoneStart) : null
                        property Item pianoKeyEndItem: keyZoneContainer ? pianoKeysRepeater.itemAt(keyZoneContainer.keyZoneEnd) : null
                        property Item pianoRootNoteItem: keyZoneContainer ? pianoKeysRepeater.itemAt(keyZoneContainer.rootNote) : null
                        x: clipObj && pianoKeyItem ? pianoKeyItem.x + (pianoKeyItem.width / 2) : 0 //(pianoKeysRepeater.itemAt(0) ? -Math.floor(pianoKeysRepeater.itemAt(0).width / 2) : 0)
                        opacity: clipObj ? 1 : 0.3
                        QQC2.Label {
                            id: sampleLabel
                            anchors {
                                bottom: sampleHandle.verticalCenter
                                bottomMargin: 1
                                left: sampleHandle.right
                                leftMargin: 1
                            }
                            text: slotRepeater.slotType === "TracksBar_synthslot" ? "Synth " + (index + 1) : "Sample " + (index + 1)
                            width: paintedWidth
                            height: paintedHeight
                            font.pixelSize: Math.floor((parent.height / slotTypeRepeater.totalDisplayRowCount) - 10)
                        }
                        Rectangle {
                            id: sampleHandle
                            anchors {
                                top: parent.top
                                topMargin: sampleKeyzoneDelegate.combinedIndex * (parent.height / slotTypeRepeater.totalDisplayRowCount)
                                horizontalCenter: parent.horizontalCenter
                            }
                            height: Kirigami.Units.largeSpacing * 2
                            width: height
                            radius: height / 2
                            color: sampleKeyzoneDelegate.isCurrent ? sampleKeyzoneDelegate.lineColor : Kirigami.Theme.backgroundColor
                            border {
                                width: 2
                                color: sampleKeyzoneDelegate.lineColor
                            }
                            QQC2.Label {
                                anchors.centerIn: parent
                                font.pixelSize: parent.height * 0.5
                                color: sampleKeyzoneDelegate.isCurrent ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                text: sampleKeyzoneDelegate.keyZoneContainer ? Zynthbox.KeyScales.midiNoteName(sampleKeyzoneDelegate.keyZoneContainer.keyZoneStart) : ""
                            }
                        }
                        Rectangle {
                            anchors {
                                top: sampleHandle.bottom;
                                bottom: parent.bottom;
                                horizontalCenter: sampleHandle.horizontalCenter
                            }
                            width: 2
                            color: sampleKeyzoneDelegate.lineColor
                        }
                        Rectangle {
                            id: sampleEndHandle
                            anchors {
                                top: parent.top
                                topMargin: sampleKeyzoneDelegate.combinedIndex * (parent.height / slotTypeRepeater.totalDisplayRowCount)
                            }
                            x: pianoKeyEndItem ? (pianoKeyEndItem.x - sampleKeyzoneDelegate.x) + (pianoKeyEndItem.isSharpKey ? -(sampleEndHandle.width / 2) : 0) : sampleHandle.x
                            height: Kirigami.Units.largeSpacing * 2
                            width: height
                            radius: height / 2
                            color: sampleKeyzoneDelegate.isCurrent ? sampleKeyzoneDelegate.lineColor : Kirigami.Theme.backgroundColor
                            border {
                                width: 2
                                color: sampleKeyzoneDelegate.lineColor
                            }
                            QQC2.Label {
                                anchors.centerIn: parent
                                font.pixelSize: parent.height * 0.5
                                color: sampleKeyzoneDelegate.isCurrent ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                text: sampleKeyzoneDelegate.keyZoneContainer ? Zynthbox.KeyScales.midiNoteName(sampleKeyzoneDelegate.keyZoneContainer.keyZoneEnd) : ""
                            }
                        }
                        Rectangle {
                            anchors {
                                top: sampleEndHandle.bottom
                                bottom: parent.bottom
                                horizontalCenter: sampleEndHandle.horizontalCenter
                            }
                            width: 2
                            color: sampleKeyzoneDelegate.lineColor
                        }
                        Rectangle {
                            anchors {
                                top: sampleHandle.verticalCenter
                                left: sampleHandle.right
                                right: sampleEndHandle.left
                            }
                            height: 2
                            color: sampleKeyzoneDelegate.lineColor
                        }
                        Row {
                            anchors {
                                top: sampleHandle.verticalCenter
                                topMargin: 3
                                left: sampleHandle.right
                            }
                            spacing: 0
                            Timer {
                                id: dotFetcher
                                interval: 1; running: false; repeat: false;
                                onTriggered: {
                                    progressDots.playbackPositions = component.visible && sampleKeyzoneDelegate.clipObj && sampleKeyzoneDelegate.clipObj.playbackPositions !== undefined
                                        ? sampleKeyzoneDelegate.clipObj.playbackPositions
                                        : null
                                }
                            }
                            Connections {
                                target: component
                                onVisibleChanged: dotFetcher.restart()
                            }
                            Connections {
                                target: sampleKeyzoneDelegate
                                onClipObjChanged: dotFetcher.restart()
                            }
                            Repeater {
                                id: progressDots
                                model: Zynthbox.Plugin.clipMaximumPositionCount
                                property QtObject playbackPositions: null
                                delegate: Item {
                                    property QtObject progressEntry: progressDots.playbackPositions ? progressDots.playbackPositions.positions[model.index] : null
                                    visible: progressEntry && progressEntry.id > -1
                                    height: 5
                                    width: 5
                                    Rectangle {
                                        anchors.centerIn: parent
                                        rotation: 45
                                        height: 4
                                        width: 4
                                        color: sampleKeyzoneDelegate.lineColor
                                        scale: progressEntry ? 0.5 + progressEntry.gain : 1
                                    }
                                }
                            }
                        }
                        Item {
                            anchors {
                                bottom: parent.bottom
                                bottomMargin: Kirigami.Units.largeSpacing
                            }
                            height: 1
                            width: 1
                            x: pianoRootNoteItem ? (pianoRootNoteItem.x - sampleKeyzoneDelegate.x) + (pianoRootNoteItem.width / 2) : sampleHandle.x
                            visible: sampleKeyzoneDelegate.isCurrent && sampleKeyzoneDelegate.keyZoneContainer && sampleKeyzoneDelegate.keyZoneContainer.rootNote > -1 && sampleKeyzoneDelegate.keyZoneContainer.rootNote < 128
                            Rectangle {
                                anchors {
                                    topMargin: -height
                                    centerIn: parent
                                }
                                color: sampleKeyzoneDelegate.lineColor
                                height: Kirigami.Units.largeSpacing * 2
                                width: 2
                                QQC2.Label {
                                    anchors {
                                        horizontalCenter: parent.horizontalCenter
                                        bottom: parent.top
                                    }
                                    font.pixelSize: Kirigami.Units.largeSpacing
                                    color: Kirigami.Theme.textColor
                                    text: "Root Note: %1".arg(visible ? Zynthbox.KeyScales.midiNoteName(sampleKeyzoneDelegate.keyZoneContainer.rootNote) : "")
                                    Rectangle {
                                        anchors {
                                            horizontalCenter: parent.horizontalCenter
                                            top: parent.bottom
                                        }
                                        width: parent.paintedWidth
                                        height: 2
                                        color: sampleKeyzoneDelegate.lineColor
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        Item {
            id: pianoKeysContainer
            Layout.preferredHeight: parent.height / 3
            Layout.fillWidth: true
            Layout.fillHeight: true
            Rectangle {
                anchors.fill: parent
                color: "white"
            }
            RowLayout {
                anchors.fill: parent
                spacing: 0
                Repeater {
                    id: pianoKeysRepeater
                    model: 128
                    delegate: Item {
                        id: pianoKeyDelegate
                        property QtObject note: component.selectedChannel ? Zynthbox.PlayGridManager.getNote(model.index, component.selectedChannel.id) : null
                        property var sharpMidiNotes: [1, 3, 6, 8, 10];
                        property bool isSharpKey: sharpMidiNotes.indexOf(model.index % 12) > -1;
                        property bool previousIsSharpKey: sharpMidiNotes.indexOf((model.index - 1) % 12) > -1;
                        Layout.fillWidth: isSharpKey ? false : true
                        Layout.fillHeight: true
                        Rectangle {
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                topMargin: parent.previousIsSharpKey ? (parent.height * 3 / 5) : 0
                            }
                            width: 1
                            color: "black"
                        }
                        Rectangle {
                            visible: parent.isSharpKey
                            anchors {
                                top: parent.top
                                horizontalCenter: parent.horizontalCenter
                            }
                            color: "black"
                            width: pianoKeysContainer.width / 100
                            height: parent.height * 3 / 5
                            Rectangle {
                                visible: pianoKeyDelegate.isSharpKey && pianoKeyDelegate.note ? pianoKeyDelegate.note.isPlaying : false
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                height: width
                                radius: width / 2
                                color: Kirigami.Theme.focusColor
                            }
                        }
                        Rectangle {
                            visible: parent.isSharpKey === false && pianoKeyDelegate.note ? pianoKeyDelegate.note.isPlaying : false
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                leftMargin: 1
                                rightMargin: 0
                                bottomMargin: 1
                            }
                            height: width
                            radius: width / 2
                            color: Kirigami.Theme.focusColor
                        }
                        QQC2.Label {
                            visible: model.index % 12 === 0
                            anchors {
                                fill: parent
                                leftMargin: 2
                                rightMargin: 0
                            }
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignBottom
                            text: pianoKeyDelegate.note ? pianoKeyDelegate.note.octave - 1 : ""
                            font.pixelSize: width
                            color: "silver"
                        }
                    }
                }
            }
        }
    }
}
