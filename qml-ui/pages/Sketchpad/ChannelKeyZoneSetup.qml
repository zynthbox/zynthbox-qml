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
    width: Kirigami.Units.gridUnit * 50
    height: Kirigami.Units.gridUnit * 20
    property QtObject selectedChannel: null

    title: selectedChannel ? qsTr("Set up keyzones on Track %1").arg(selectedChannel.name) : ""
    acceptText: qsTr("Back")
    rejectText: ""

    property var cuiaCallback: function(cuia) {
        let returnValue = true;
        let clipObj = null;
        switch (cuia) {
            case "KNOB0_UP":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    if (component.selectedChannel.trackType === "synth") {
                        clipObj = component.selectedChannel.chainedSoundsKeyzones[component.selectedChannel.selectedSlotRow];
                    } else {
                        component.selectedChannel.keyZoneMode = "manual";
                        clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId).selectedSliceObject;
                    }
                    clipObj.keyZoneStart = Math.min(clipObj.keyZoneStart + 1, 127);
                }
                break;
            case "KNOB0_DOWN":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    if (component.selectedChannel.trackType === "synth") {
                        clipObj = component.selectedChannel.chainedSoundsKeyzones[component.selectedChannel.selectedSlotRow];
                    } else {
                        component.selectedChannel.keyZoneMode = "manual";
                        clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId).selectedSliceObject;
                    }
                    clipObj.keyZoneStart = Math.max(clipObj.keyZoneStart - 1, -1);
                }
                break;
            case "KNOB1_UP":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    if (component.selectedChannel.trackType === "synth") {
                        clipObj = component.selectedChannel.chainedSoundsKeyzones[component.selectedChannel.selectedSlotRow];
                    } else {
                        component.selectedChannel.keyZoneMode = "manual";
                        clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId).selectedSliceObject;
                    }
                    clipObj.keyZoneEnd = Math.min(clipObj.keyZoneEnd + 1, 127);
                }
                break;
            case "KNOB1_DOWN":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    if (component.selectedChannel.trackType === "synth") {
                        clipObj = component.selectedChannel.chainedSoundsKeyzones[component.selectedChannel.selectedSlotRow];
                    } else {
                        component.selectedChannel.keyZoneMode = "manual";
                        clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId).selectedSliceObject;
                    }
                    clipObj.keyZoneEnd = Math.max(clipObj.keyZoneEnd - 1, -1);
                }
                break;
            case "KNOB2_UP":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    if (component.selectedChannel.trackType === "synth") {
                        clipObj = component.selectedChannel.chainedSoundsKeyzones[component.selectedChannel.selectedSlotRow];
                    } else {
                        component.selectedChannel.keyZoneMode = "manual";
                        clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId).selectedSliceObject;
                    }
                    clipObj.rootNote = Math.min(clipObj.rootNote + 1, 127);
                }
                break;
            case "KNOB2_DOWN":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    if (component.selectedChannel.trackType === "synth") {
                        clipObj = component.selectedChannel.chainedSoundsKeyzones[component.selectedChannel.selectedSlotRow];
                    } else {
                        component.selectedChannel.keyZoneMode = "manual";
                        clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId).selectedSliceObject;
                    }
                    clipObj.rootNote = Math.max(clipObj.rootNote - 1, 0);
                }
                break;
            case "KNOB3_UP":
            case "NAVIGATE_RIGHT":
                component.selectedChannel.selectedSlotRow = Math.min(component.selectedChannel.selectedSlotRow + 1, 4);
                break;
            case "KNOB3_DOWN":
            case "NAVIGATE_LEFT":
                component.selectedChannel.selectedSlotRow = Math.max(component.selectedChannel.selectedSlotRow - 1, 0);
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
        Timer {
            id: keyZoneSetupSelectedChannelThrottle
            interval: 1; running: false; repeat: false;
            onTriggered: {
                component.selectedChannel = zynqtgui.sketchpad.song ? zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId) : null;
            }
        }
        Connections {
            target: zynqtgui.sketchpad
            onSelected_track_id_changed: keyZoneSetupSelectedChannelThrottle.restart()
        }
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            Item {
                Layout.fillWidth: true
            }
            QQC2.Label {
                visible: component.selectedChannel ? component.selectedChannel.trackType === "sample-trig" || component.selectedChannel.trackType === "sample-loop" : false
                text: "Manual"
                Rectangle {
                    visible: component.selectedChannel && component.selectedChannel.keyZoneMode == "manual";
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 2
                    color: Kirigami.Theme.highlightColor
                }
            }
            // QQC2.Button {
            //     visible: component.selectedChannel.trackType === "synth"
            //     text: "Split Evenly"
            //     onClicked: {
            //          This should split the space evenly between the slots, but also... this will likely work a bit weirdly for more than two slots, which would usually be more a case of layering + splitting, and we can't reasonably guess at that... but maybe we don't care?
            //     }
            // }
            Repeater {
                model: 5
                QQC2.Button {
                    property var channelSample: visible ? component.selectedChannel && component.selectedChannel.samples && component.selectedChannel.samples[index] : undefined
                    property int engineMidiChannel: component.selectedChannel ? component.selectedChannel.chainedSounds[index] : -1
                    property QtObject clipObj: component.selectedChannel && component.selectedChannel.trackType === "synth"
                        ? engineMidiChannel > -1 && component.selectedChannel.checkIfLayerExists(engineMidiChannel) ? component.selectedChannel.chainedSoundsKeyzones[index] : null
                        : channelSample ? Zynthbox.PlayGridManager.getClipById(channelSample.cppObjId) : null
                    property QtObject keyZoneContainer: component.selectedChannel && component.selectedChannel.trackType === "synth" ? clipObj : (clipObj === null ? null : clipObj.selectedSliceObject)
                    enabled: clipObj !== null
                    text: (index === 0 ? "Disable slot " : "") + (index + 1)
                    onClicked: {
                        if (component.selectedChannel.trackType === "sample-trig" || component.selectedChannel.trackType === "sample-loop") {
                            component.selectedChannel.keyZoneMode = "manual";
                        }
                        keyZoneContainer.keyZoneStart = -1;
                        keyZoneContainer.keyZoneEnd = -1;
                        keyZoneContainer.rootNote = -1;
                        component.selectedChannel.selectedSlotRow = index;
                    }
                }
            }
            Repeater {
                model: 5
                QQC2.Button {
                    property var channelSample: visible ? component.selectedChannel && component.selectedChannel.samples && component.selectedChannel.samples[index] : undefined
                    property int engineMidiChannel: component.selectedChannel ? component.selectedChannel.chainedSounds[index] : -1
                    property QtObject clipObj: component.selectedChannel && component.selectedChannel.trackType === "synth"
                        ? engineMidiChannel > -1 && component.selectedChannel.checkIfLayerExists(engineMidiChannel) ? component.selectedChannel.chainedSoundsKeyzones[index] : null
                        : channelSample ? Zynthbox.PlayGridManager.getClipById(channelSample.cppObjId) : null
                    property QtObject keyZoneContainer: component.selectedChannel && component.selectedChannel.trackType === "synth" ? clipObj : (clipObj === null ? null : clipObj.selectedSliceObject)
                    enabled: clipObj !== null
                    text: (index === 0 ? "Assign full width to slot " : "") + (index + 1)
                    onClicked: {
                        if (component.selectedChannel.trackType === "sample-trig" || component.selectedChannel.trackType === "sample-loop") {
                            component.selectedChannel.keyZoneMode = "manual";
                        }
                        keyZoneContainer.keyZoneStart = 0;
                        keyZoneContainer.keyZoneEnd = 127;
                        keyZoneContainer.rootNote = 60;
                        component.selectedChannel.selectedSlotRow = index;
                    }
                }
            }
            Rectangle {
                visible: component.selectedChannel ? component.selectedChannel.trackType === "sample-trig" || component.selectedChannel.trackType === "sample-loop" : false
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                Layout.margins: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.disabledTextColor
            }
            QQC2.Label {
                text: "Auto"
                visible: component.selectedChannel ? component.selectedChannel.trackType === "sample-trig" || component.selectedChannel.trackType === "sample-loop" : false
            }
            QQC2.Button {
                text: "All Full"
                visible: component.selectedChannel ? component.selectedChannel.trackType === "sample-trig" || component.selectedChannel.trackType === "sample-loop" : false
                checked: component.selectedChannel && component.selectedChannel.keyZoneMode == "all-full";
                onClicked: {
                    if (component.selectedChannel) {
                        component.selectedChannel.keyZoneMode = "all-full";
                    }
                }
            }
            QQC2.Button {
                text: "Split Full"
                visible: component.selectedChannel ? component.selectedChannel.trackType === "sample-trig" || component.selectedChannel.trackType === "sample-loop" : false
                checked: component.selectedChannel && component.selectedChannel.keyZoneMode == "split-full";
                onClicked: {
                    if (component.selectedChannel) {
                        component.selectedChannel.keyZoneMode = "split-full";
                    }
                }
            }
            QQC2.Button {
                text: "Split Narrow"
                visible: component.selectedChannel ? component.selectedChannel.trackType === "sample-trig" || component.selectedChannel.trackType === "sample-loop" : false
                checked: component.selectedChannel && component.selectedChannel.keyZoneMode == "split-narrow";
                onClicked: {
                    if (component.selectedChannel) {
                        component.selectedChannel.keyZoneMode = "split-narrow";
                    }
                }
            }
        }
        Item {
            Layout.preferredHeight: parent.height * 2 / 3
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Math.floor(((parent.height / 6) - 5) / 2)
            property double positioningHelp: width / 100
            Repeater {
                model: 5
                delegate: Item {
                    id: sampleKeyzoneDelegate
                    property var channelSample: component.selectedChannel ? component.selectedChannel.samples && component.selectedChannel.samples[index] : null
                    property int engineMidiChannel: component.selectedChannel ? component.selectedChannel.chainedSounds[index] : -1
                    property QtObject clipObj: component.selectedChannel && component.selectedChannel.trackType === "synth"
                        ? engineMidiChannel > -1 && component.selectedChannel.checkIfLayerExists(engineMidiChannel) ? component.selectedChannel.chainedSoundsKeyzones[index] : null
                        : channelSample ? Zynthbox.PlayGridManager.getClipById(channelSample.cppObjId) : null
                    property QtObject keyZoneContainer: component.selectedChannel && component.selectedChannel.trackType === "synth" ? clipObj : (clipObj === null ? null : clipObj.selectedSliceObject)
                    height: parent.height;
                    width: 1
                    property bool isCurrent: component.selectedChannel ? component.selectedChannel.selectedSlotRow === index : false
                    z: isCurrent ? 99 : 0
                    property color lineColor: isCurrent ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    property Item pianoKeyItem: keyZoneContainer ? pianoKeysRepeater.itemAt(keyZoneContainer.keyZoneStart) : null
                    property Item pianoKeyEndItem: keyZoneContainer ? pianoKeysRepeater.itemAt(keyZoneContainer.keyZoneEnd) : null
                    property Item pianoRootNoteItem: keyZoneContainer ? pianoKeysRepeater.itemAt(keyZoneContainer.rootNote) : null
                    x: clipObj && pianoKeyItem ? pianoKeyItem.x + (pianoKeyItem.width / 2) : (pianoKeysRepeater.itemAt(0) ? -Math.floor(pianoKeysRepeater.itemAt(0).width / 2) : 0)
                    opacity: clipObj ? 1 : 0.3
                    QQC2.Label {
                        id: sampleLabel
                        anchors {
                            bottom: sampleHandle.verticalCenter
                            bottomMargin: 1
                            left: sampleHandle.right
                            leftMargin: 1
                        }
                        text: "Slot " + (index + 1)
                        width: paintedWidth
                        height: paintedHeight
                        font.pixelSize: Math.floor((parent.height / 6) - 5)
                    }
                    Rectangle {
                        id: sampleHandle
                        anchors {
                            top: parent.top
                            topMargin: index * (parent.height / 6)
                            horizontalCenter: parent.horizontalCenter
                        }
                        height: Kirigami.Units.largeSpacing * 2
                        width: height
                        radius: height / 2
                        color: Kirigami.Theme.backgroundColor
                        border {
                            width: 2
                            color: sampleKeyzoneDelegate.lineColor
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
                            topMargin: index * (parent.height / 6)
                        }
                        x: pianoKeyItem && pianoKeyEndItem ? pianoKeyEndItem.x - pianoKeyItem.x - Kirigami.Units.largeSpacing : sampleHandle.x
                        height: Kirigami.Units.largeSpacing * 2
                        width: height
                        radius: height / 2
                        color: Kirigami.Theme.backgroundColor
                        border {
                            width: 2
                            color: sampleKeyzoneDelegate.lineColor
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
                                progressDots.playbackPositions = component.visible && sampleKeyzoneDelegate.clipObj
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
                        x: pianoKeyItem && pianoRootNoteItem ? pianoRootNoteItem.x - pianoKeyItem.x : sampleHandle.x
                        visible: sampleKeyzoneDelegate.isCurrent && sampleKeyzoneDelegate.keyZoneContainer && sampleKeyzoneDelegate.keyZoneContainer.rootNote > -1 && sampleKeyzoneDelegate.keyZoneContainer.rootNote < 128
                        Rectangle {
                            anchors {
                                topMargin: -height
                                centerIn: parent
                            }
                            color: sampleKeyzoneDelegate.lineColor
                            height: Kirigami.Units.largeSpacing * 2
                            width: height
                            radius: height / 2
                            QQC2.Label {
                                anchors.centerIn: parent
                                font.pixelSize: Kirigami.Units.largeSpacing
                                color: Kirigami.Theme.highlightedTextColor
                                text: "C4"
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
