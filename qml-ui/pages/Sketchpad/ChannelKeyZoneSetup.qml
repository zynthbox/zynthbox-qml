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

    title: selectedChannel ? qsTr("Set up key zones for Sample mode on Track %1").arg(selectedChannel.name) : ""
    acceptText: qsTr("Back")
    rejectText: ""

    property var cuiaCallback: function(cuia) {
        let returnValue = true;
        let clipObj = null;
        switch (cuia) {
            case "KNOB0_UP":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    component.selectedChannel.keyZoneMode = "manual";
                    clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId);
                    clipObj.keyZoneStart = Math.min(clipObj.keyZoneStart + 1, 127);
                }
                break;
            case "KNOB0_DOWN":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    component.selectedChannel.keyZoneMode = "manual";
                    clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId);
                    clipObj.keyZoneStart = Math.max(clipObj.keyZoneStart - 1, -1);
                }
                break;
            case "KNOB1_UP":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    component.selectedChannel.keyZoneMode = "manual";
                    clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId);
                    clipObj.keyZoneEnd = Math.min(clipObj.keyZoneEnd + 1, 127);
                }
                break;
            case "KNOB1_DOWN":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    component.selectedChannel.keyZoneMode = "manual";
                    clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId);
                    clipObj.keyZoneEnd = Math.max(clipObj.keyZoneEnd - 1, -1);
                }
                break;
            case "KNOB2_UP":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    component.selectedChannel.keyZoneMode = "manual";
                    clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId);
                    clipObj.rootNote = Math.min(clipObj.rootNote + 1, 127);
                }
                break;
            case "KNOB2_DOWN":
                if (component.selectedChannel && -1 < component.selectedChannel.selectedSlotRow && component.selectedChannel.selectedSlotRow < 5) {
                    component.selectedChannel.keyZoneMode = "manual";
                    clipObj = Zynthbox.PlayGridManager.getClipById(component.selectedChannel.samples[component.selectedChannel.selectedSlotRow].cppObjId);
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
            case "SWITCH_BACK_LONG":
            case "SWITCH_SELECT_SHORT":
                component.accept();
                break;
        }
        return returnValue;
    }

    ColumnLayout {
        Timer {
            id: keyZoneSetupSelectedChannelThrottle
            interval: 1; running: false; repeat: false;
            onTriggered: {
                component.selectedChannel = zynqtgui.sketchpad.song ? zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.session_dashboard.selectedChannel) : null;
            }
        }
        Connections {
            target: zynqtgui.session_dashboard
            onSelected_channel_changed: keyZoneSetupSelectedChannelThrottle.restart()
        }
        anchors {
            fill: parent
            margins: Kirigami.Units.largeSpacing
        }
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            Item {
                Layout.fillWidth: true
            }
            QQC2.Label {
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
            Repeater {
                model: 5
                QQC2.Button {
                    property var channelSample: visible ? component.selectedChannel && component.selectedChannel.samples && component.selectedChannel.samples[index] : undefined
                    property QtObject clipObj: channelSample ? Zynthbox.PlayGridManager.getClipById(channelSample.cppObjId) : null;
                    enabled: clipObj !== null
                    text: (index === 0 ? "Assign full width to sample " : "") + (index + 1)
                    onClicked: {
                        // Reset all keyzones to 0-127
                        component.selectedChannel.keyZoneMode = "manual";
                        if (component.selectedChannel) {
                            for (var i = 0; i < component.selectedChannel.samples.length; ++i) {
                                var sample = component.selectedChannel.samples[i];
                                if (sample) {
                                    var clip = Zynthbox.PlayGridManager.getClipById(sample.cppObjId);
                                    if (clip) {
                                        // -1 is not a true midi key, but as this is "just" data storage,
                                        // we can use it to effectively disable a sample entirely
                                        clip.keyZoneStart = -1;
                                        clip.keyZoneEnd = -1;
                                        clip.rootNote = -1;
                                    }
                                }
                            }
                        }
                        clipObj.keyZoneStart = 0;
                        clipObj.keyZoneEnd = 127;
                        clipObj.rootNote = 60;
                        component.selectedChannel.selectedSlotRow = index;
                    }
                }
            }
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                Layout.margins: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.disabledTextColor
            }
            QQC2.Label {
                text: "Auto"
            }
            QQC2.Button {
                text: "All Full"
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
                    property QtObject clipObj: channelSample ? Zynthbox.PlayGridManager.getClipById(channelSample.cppObjId) : null;
                    Connections {
                        target: clipObj
                        onKeyZoneStartChanged: zynqtgui.sketchpad.song.schedule_save()
                        onKeyZoneEndChanged: zynqtgui.sketchpad.song.schedule_save()
                        onRootNoteChanged: zynqtgui.sketchpad.song.schedule_save()
                    }
                    height: parent.height;
                    width: 1
                    property bool isCurrent: component.selectedChannel ? component.selectedChannel.selectedSlotRow === index : false
                    z: isCurrent ? 99 : 0
                    property color lineColor: isCurrent ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    property Item pianoKeyItem: clipObj ? pianoKeysRepeater.itemAt(clipObj.keyZoneStart) : null
                    property Item pianoKeyEndItem: clipObj ? pianoKeysRepeater.itemAt(clipObj.keyZoneEnd) : null
                    property Item pianoRootNoteItem: clipObj ? pianoKeysRepeater.itemAt(clipObj.rootNote) : null
                    x: clipObj && pianoKeyItem ? pianoKeyItem.x + (pianoKeyItem.width / 2) : -Math.floor(pianoKeysRepeater.itemAt(0).width / 2)
                    opacity: clipObj ? 1 : 0.3
                    QQC2.Label {
                        id: sampleLabel
                        anchors {
                            bottom: sampleHandle.verticalCenter
                            bottomMargin: 1
                            left: sampleHandle.right
                            leftMargin: 1
                        }
                        text: "Sample " + (index + 1)
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
                        x: pianoKeyItem && pianoKeyEndItem ? pianoKeyEndItem.x - pianoKeyItem.x - Kirigami.Units.largeSpacing: sampleHandle.x
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
                        Repeater {
                            model: clipObj ? clipObj.playbackPositions : 0
                            delegate: Item {
                                visible: model.positionID > -1
                                height: 5
                                width: 5
                                Rectangle {
                                    anchors.centerIn: parent
                                    rotation: 45
                                    height: 4
                                    width: 4
                                    color: sampleKeyzoneDelegate.lineColor
                                    scale: 0.5 + model.positionGain
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
                        x: pianoKeyItem && pianoRootNoteItem ? pianoRootNoteItem.x - pianoKeyItem.x: sampleHandle.x
                        visible: sampleKeyzoneDelegate.isCurrent && sampleKeyzoneDelegate.clipObj && sampleKeyzoneDelegate.clipObj.rootNote > -1 && sampleKeyzoneDelegate.clipObj.rootNote < 128
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
                        property var sharpMidiNotes: [1, 3, 6, 8, 10];
                        property bool isSharpKey: sharpMidiNotes.indexOf(index % 12) > -1;
                        Layout.fillWidth: isSharpKey ? false : true
                        Layout.fillHeight: true
                        Rectangle {
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
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
                        }
                        QQC2.Label {
                            visible: index % 12 === 0
                            anchors {
                                fill: parent
                                margins: 2
                            }
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignBottom
                            text: (index % 12) + 1
                            font.pixelSize: width
                        }
                    }
                }
            }
        }
    }
}
