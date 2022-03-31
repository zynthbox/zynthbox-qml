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

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

Rectangle {
    id: root

    readonly property QtObject song: zynthian.zynthiloops.song
    readonly property QtObject selectedTrack: song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)

    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_TRACKS_MOD_SHORT":
                return true

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

            case "SELECT_UP":
                if (root.selectedTrack.trackAudioType == "sample-trig") {
                    if (root.selectedTrack.selectedSampleRow > 0) {
                        root.selectedTrack.selectedSampleRow -= 1;
                    }
                    return true;
                }

            case "SELECT_DOWN":
                if (root.selectedTrack.trackAudioType == "sample-trig") {
                    if (root.selectedTrack.selectedSampleRow < 4) {
                        root.selectedTrack.selectedSampleRow += 1;
                    }
                    return true;
                }

            // Set respective selected row when button 1-5 is pressed or 6(mod)+1-5 is pressed
            // and invoke respective handler when trackAudioType is synth, trig or slice
            // Otherwise, when in loop mode, do not handle button to allow falling back to track
            // selection
            case "TRACK_1":
            case "TRACK_6":
                if (root.selectedTrack.trackAudioType === "sample-loop") {
                    bottomStack.bottomBar.filePickerDialog.folderModel.folder = bottomStack.bottomBar.controlObj.recordingDir;
                    bottomStack.bottomBar.filePickerDialog.open();
                    return true
                } else if (root.selectedTrack.trackAudioType === "synth" ||
                    root.selectedTrack.trackAudioType === "sample-trig" ||
                    root.selectedTrack.trackAudioType === "sample-slice") {
                    bottomStack.slotsBar.selectedSlotRowItem.selectedRow = 0
                    bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                    return true
                }

                return false

            case "TRACK_2":
            case "TRACK_7":
                if (root.selectedTrack.trackAudioType === "sample-loop") {
                    return true
                } else if (root.selectedTrack.trackAudioType === "synth" ||
                    root.selectedTrack.trackAudioType === "sample-trig" ||
                    root.selectedTrack.trackAudioType === "sample-slice") {
                    bottomStack.slotsBar.selectedSlotRowItem.selectedRow = 1
                    bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                    return true
                }

                return false

            case "TRACK_3":
            case "TRACK_8":
                if (root.selectedTrack.trackAudioType === "sample-loop") {
                    return true
                } else if (root.selectedTrack.trackAudioType === "synth" ||
                    root.selectedTrack.trackAudioType === "sample-trig" ||
                    root.selectedTrack.trackAudioType === "sample-slice") {
                    bottomStack.slotsBar.selectedSlotRowItem.selectedRow = 2
                    bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                    return true
                }

                return false

            case "TRACK_4":
            case "TRACK_9":
                if (root.selectedTrack.trackAudioType === "sample-loop") {
                    return true
                } else if (root.selectedTrack.trackAudioType === "synth" ||
                    root.selectedTrack.trackAudioType === "sample-trig" ||
                    root.selectedTrack.trackAudioType === "sample-slice") {
                    bottomStack.slotsBar.selectedSlotRowItem.selectedRow = 3
                    bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                    return true
                }

                return false

            case "TRACK_5":
            case "TRACK_10":
                if (root.selectedTrack.trackAudioType === "sample-loop") {
                    return true
                } else if (root.selectedTrack.trackAudioType === "synth" ||
                    root.selectedTrack.trackAudioType === "sample-trig" ||
                    root.selectedTrack.trackAudioType === "sample-slice") {
                    bottomStack.slotsBar.selectedSlotRowItem.selectedRow = 4
                    bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                    return true
                }

                return false
        }

        return false;
    }

    QtObject {
        id: privateProps

        //Try to fit exactly 12 mixers + a master mixer
        property int cellWidth: (tableLayout.width - loopGrid.columnSpacing)/13
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
                        Layout.preferredWidth: privateProps.cellWidth + 6
                        Layout.maximumWidth: privateProps.cellWidth + 6
                        Layout.bottomMargin: 5
                        Layout.fillHeight: true
                    }

                    Kirigami.Separator {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: "#ff31363b"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        RowLayout {
                            id: tabButtons
                            Layout.fillWidth: true
                            Layout.fillHeight: false

                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                checkable: true
                                checked: root.selectedTrack.trackAudioType === "synth"
                                text: qsTr("Synth")
                                onClicked: root.selectedTrack.trackAudioType = "synth"
                            }
                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                checkable: true
                                checked: root.selectedTrack.trackAudioType === "sample-loop"
                                text: qsTr("Loop")
                                onClicked: root.selectedTrack.trackAudioType = "sample-loop"
                            }
                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                checkable: true
                                checked: root.selectedTrack.trackAudioType === "sample-trig"
                                text: qsTr("Trig")
                                onClicked: root.selectedTrack.trackAudioType = "sample-trig"
                            }
                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                checkable: true
                                checked: root.selectedTrack.trackAudioType === "sample-slice"
                                text: qsTr("Slice")
                                onClicked: root.selectedTrack.trackAudioType = "sample-slice"
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Item {
                                anchors {
                                    fill: parent
                                    margins: Kirigami.Units.largeSpacing
                                }
                                visible: root.selectedTrack.trackAudioType == "sample-trig"
                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 0
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Item {
                                            Layout.fillWidth: true
                                        }
                                        Repeater {
                                            model: 5
                                            QQC2.Button {
                                                property var trackSample: root.selectedTrack.samples && root.selectedTrack.samples[index]
                                                property QtObject clipObj: trackSample ? ZynQuick.PlayGridManager.getClipById(trackSample.cppObjId) : null;
                                                enabled: clipObj !== null
                                                text: (index === 0 ? "Assign full width to sample " : "") + (index + 1)
                                                onClicked: {
                                                    // Reset all keyzones to 0-127
                                                    if (root.selectedTrack) {
                                                        for (var i = 0; i < root.selectedTrack.samples.length; ++i) {
                                                            var sample = root.selectedTrack.samples[i];
                                                            if (sample) {
                                                                var clip = ZynQuick.PlayGridManager.getClipById(sample.cppObjId);
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
                                                    root.selectedTrack.selectedSampleRow = index;
                                                }
                                            }
                                        }
                                        QQC2.Button {
                                            text: "Reset Keyzones"
                                            onClicked: {
                                                // Reset all keyzones to 0-127
                                                if (root.selectedTrack) {
                                                    for (var i = 0; i < root.selectedTrack.samples.length; ++i) {
                                                        var sample = root.selectedTrack.samples[i];
                                                        if (sample) {
                                                            var clip = ZynQuick.PlayGridManager.getClipById(sample.cppObjId);
                                                            if (clip) {
                                                                clip.keyZoneStart = 0;
                                                                clip.keyZoneEnd = 127;
                                                                clip.rootNote = 60;
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        QQC2.Button {
                                            text: "Auto-generate Keyzones"
                                            onClicked: {
                                                // Do a bit of magic autolayouting, based on what we think things should do...
                                                // auto-split keyzones: SLOT 4 c-1 - b1, SLOT 2 c1-b3, SLOT 1 c3-b5, SLOT 3 c5-b7, SLOT 5 c7-c9
                                                // root key transpose in semtitones: +48, +24 ,0 , -24, -48
                                                var sampleSettings = [
                                                    [60, 83, 0], // slot 1
                                                    [36, 59, -24], // slot 2
                                                    [84, 107, 24], // slot 3
                                                    [12, 35, -48], // slot 4
                                                    [108, 127, 48] // slot 5
                                                ];
                                                for (var i = 0; i < root.selectedTrack.samples.length; ++i) {
                                                    var sample = root.selectedTrack.samples[i];
                                                    var clip = ZynQuick.PlayGridManager.getClipById(sample.cppObjId);
                                                    if (clip) {
                                                        clip.keyZoneStart = sampleSettings[i][0];
                                                        clip.keyZoneEnd = sampleSettings[i][1];
                                                        clip.rootNote = 60 + sampleSettings[i][2];
                                                    }
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
                                                property var trackSample: root.selectedTrack.samples && root.selectedTrack.samples[index]
                                                property QtObject clipObj: trackSample ? ZynQuick.PlayGridManager.getClipById(trackSample.cppObjId) : null;
                                                Connections {
                                                    target: clipObj
                                                    onKeyZoneStartChanged: zynthian.zynthiloops.song.schedule_save()
                                                    onKeyZoneEndChanged: zynthian.zynthiloops.song.schedule_save()
                                                    onRootNoteChanged: zynthian.zynthiloops.song.schedule_save()
                                                }
                                                height: parent.height;
                                                width: 1
                                                property bool isCurrent: root.selectedTrack.selectedSampleRow === index
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
                                                    spacing: 1
                                                    Repeater {
                                                        model: clipObj ? clipObj.playbackPositions : 0
                                                        delegate: Rectangle {
                                                            height: 4
                                                            width: 4
                                                            radius: 2
                                                            color: sampleKeyzoneDelegate.lineColor
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
}
