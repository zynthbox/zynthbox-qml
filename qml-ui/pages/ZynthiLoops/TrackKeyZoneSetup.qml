/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

KeyZone setup component for ZynthiLoops Tracks

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
import org.zynthian.quick 1.0 as ZynQuick
Item {
    id: component
    property QtObject selectedTrack: null
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            Item {
                Layout.fillWidth: true
            }
            QQC2.Label {
                text: "Manual"
                Rectangle {
                    visible: component.selectedTrack && component.selectedTrack.keyZoneMode == "manual";
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
                    property var trackSample: visible ? component.selectedTrack && component.selectedTrack.samples && component.selectedTrack.samples[index] : undefined
                    property QtObject clipObj: trackSample ? ZynQuick.PlayGridManager.getClipById(trackSample.cppObjId) : null;
                    enabled: clipObj !== null
                    text: (index === 0 ? "Assign full width to sample " : "") + (index + 1)
                    onClicked: {
                        // Reset all keyzones to 0-127
                        component.selectedTrack.keyZoneMode = "manual";
                        if (component.selectedTrack) {
                            for (var i = 0; i < component.selectedTrack.samples.length; ++i) {
                                var sample = component.selectedTrack.samples[i];
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
                        component.selectedTrack.selectedSampleRow = index;
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
                checked: component.selectedTrack && component.selectedTrack.keyZoneMode == "all-full";
                onClicked: {
                    if (component.selectedTrack) {
                        component.selectedTrack.keyZoneMode = "all-full";
                    }
                }
            }
            QQC2.Button {
                text: "Split Full"
                checked: component.selectedTrack && component.selectedTrack.keyZoneMode == "split-full";
                onClicked: {
                    if (component.selectedTrack) {
                        component.selectedTrack.keyZoneMode = "split-full";
                    }
                }
            }
            QQC2.Button {
                text: "Split Narrow"
                checked: component.selectedTrack && component.selectedTrack.keyZoneMode == "split-narrow";
                onClicked: {
                    if (component.selectedTrack) {
                        component.selectedTrack.keyZoneMode = "split-narrow";
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
                    property var trackSample: component.selectedTrack.samples && component.selectedTrack.samples[index]
                    property QtObject clipObj: trackSample ? ZynQuick.PlayGridManager.getClipById(trackSample.cppObjId) : null;
                    Connections {
                        target: clipObj
                        onKeyZoneStartChanged: zynthian.zynthiloops.song.schedule_save()
                        onKeyZoneEndChanged: zynthian.zynthiloops.song.schedule_save()
                        onRootNoteChanged: zynthian.zynthiloops.song.schedule_save()
                    }
                    height: parent.height;
                    width: 1
                    property bool isCurrent: component.selectedTrack.selectedSampleRow === index
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
                                opacity: 0.5 + (model.positionGain / 2)
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
