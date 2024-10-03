/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Base Grid Component 

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>
Copyright (C) 2021 David Nelvand <dnelband@gmail.com>

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
import org.kde.kirigami 2.4 as Kirigami

import io.zynthbox.components 1.0 as Zynthbox

QQC2.Button {
    id: component
    property QtObject playgrid
    property QtObject patternModel
    property int activeBar
    property int padNoteNumber
    property QtObject note
    property int padNoteRow: component.patternModel ? activeBar + component.patternModel.bankOffset : 0
    property int padNoteIndex
    property bool isCurrent: false
    property int currentSubNote: -1
    property alias subNoteCount: padSubNoteRepeater.count
    signal tapped(int subNoteIndex);
    signal pressAndHold(int subNoteIndex);

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    readonly property color foregroundColor: Kirigami.Theme.backgroundColor
    readonly property color backgroundColor: Kirigami.Theme.textColor
    readonly property color borderColor: foregroundColor
    readonly property color focusColor: Kirigami.Theme.focusColor

    background: Rectangle {
        id:padNoteRect
        anchors.fill:parent
        color: component.backgroundColor
        border {
            color: component.borderColor
            width: 1
        }
        property bool shouldChange: true
        Binding {
            target: padNoteRect
            property: "shouldChange"
            value: (component.playgrid.heardNotes.length > 0) ? true : false
            delayed: true
        }
        MultiPointTouchArea {
            anchors.fill: parent

            property var timeOnClick
            property var timeOnRelease

            touchPoints: [
                TouchPoint {
                    function updateInsideBounds() {
                        if (pressed) {
                            if (x > -1 && y > -1 && x < component.width && y < component.height) {
                                longPressTimer.insideBounds = true;
                            } else {
                                longPressTimer.insideBounds = false;
                            }
                        }
                    }
                    onXChanged: updateInsideBounds();
                    onYChanged: updateInsideBounds();
                    onPressedChanged: {
                        if (pressed) {
                            updateInsideBounds();
                            longPressTimer.subNoteIndex = -1;
                            longPressTimer.restart();
                        } else {
                            if (x > -1 && y > -1 && x < component.width && y < component.height) {
                                if (!longPressTimer.pressingAndHolding) {
                                    if (padNoteRect.shouldChange) {
                                        if (component.playgrid.heardNotes.length > 0) {
                                            var removedAtLeastOne = false;
                                            // First, let's see if any of the notes in our list are already on this position, and if so, remove them
                                            for (var i = 0; i < component.playgrid.heardNotes.length; ++i) {
                                                var subNoteIndex = component.patternModel.workingModel.subnoteIndex(component.padNoteRow, component.padNoteIndex, component.playgrid.heardNotes[i].midiNote);
                                                if (subNoteIndex > -1) {
                                                    component.patternModel.workingModel.removeSubnote(component.padNoteRow, component.padNoteIndex, subNoteIndex);
                                                    removedAtLeastOne = true;
                                                }
                                            }

                                            // And then, only if we didn't remove anything should we be adding the notes
                                            if (!removedAtLeastOne) {
                                                var subNoteIndex = -1;
                                                for (var i = 0; i < component.playgrid.heardNotes.length; ++i) {
                                                    subNoteIndex = component.patternModel.workingModel.insertSubnoteSorted(component.padNoteRow, component.padNoteIndex, component.playgrid.heardNotes[i]);
                                                    component.patternModel.workingModel.setSubnoteMetadata(component.padNoteRow, component.padNoteIndex, subNoteIndex, "velocity", component.playgrid.heardVelocities[i]);
                                                    if (component.patternModel.workingModel.defaultNoteDuration > 0) {
                                                        component.patternModel.workingModel.setSubnoteMetadata(component.padNoteRow, component.padNoteIndex, subNoteIndex, "duration", component.patternModel.workingModel.defaultNoteDuration);
                                                    }
                                                }
                                            }
                                            component.currentSubNote = -1;
                                            component.note = component.patternModel.workingModel.getNote(component.padNoteRow, component.padNoteIndex);
                                        }
                                    } else {
                                        component.tapped(-1);
                                    }
                                }
                            }
                            longPressTimer.pressingAndHolding = false;
                            longPressTimer.stop();
                        }
                    }
                }
            ]
        }

        RowLayout {
            id: subnoteLayout
            anchors {
                fill: parent
                leftMargin: 1
                rightMargin: 1
                bottomMargin: 10
            }
            property int maxHalfSubnoteHeight: (height / 2) - 5
            spacing: 1
            Repeater {
                id:padSubNoteRepeater
                model: component.note ? component.note.subnotes : 0;
                delegate: Item {
                    id:padSubNoteRect
                    property var subNote: modelData
                    property var subNoteVelocity: component.patternModel.workingModel.subnoteMetadata(component.padNoteRow, component.padNoteIndex, index, "velocity");
                    property double actualSubnoteVelocity: subNoteVelocity == undefined
                        ? 0
                        : subNoteVelocity == -1
                            ? 0
                            : subNoteVelocity == 0
                                ? 64
                                : subNoteVelocity

                    Layout.fillWidth: true
                    Layout.minimumHeight: subnoteLayout.maxHalfSubnoteHeight * 2
                    Layout.maximumHeight: Layout.minimumHeight
                    property bool currentGlobalPick: component.playgrid.heardNotes.length === 0 || component.playgrid.heardNotes.indexOf(subNote) > -1
                    opacity: currentGlobalPick ? 1 : 0.3
                    MultiPointTouchArea {
                        enabled: !padNoteRect.shouldChange
                        anchors.fill: parent
                        touchPoints: [
                            TouchPoint {
                                function updateInsideBounds() {
                                    if (pressed) {
                                        if (x > -1 && y > -1 && x < padSubNoteRect.width && y < padSubNoteRect.height) {
                                            longPressTimer.insideBounds = true;
                                        } else {
                                            longPressTimer.insideBounds = false;
                                        }
                                    }
                                }
                                onXChanged: updateInsideBounds();
                                onYChanged: updateInsideBounds();
                                onPressedChanged: {
                                    if (pressed) {
                                        updateInsideBounds();
                                        longPressTimer.subNoteIndex = index;
                                        longPressTimer.restart();
                                    } else {
                                        if (x > -1 && y > -1 && x < padSubNoteRect.width && y < padSubNoteRect.height) {
                                            if (!longPressTimer.pressingAndHolding) {
                                                if (zynqtgui.altButtonPressed) {
                                                    component.tapped(index);
                                                } else {
                                                    component.tapped(-1);
                                                }
                                            }
                                        }
                                        longPressTimer.pressingAndHolding = false;
                                        longPressTimer.stop();
                                    }
                                }
                            }
                        ]
                    }
                    Rectangle {
                        anchors.fill: parent;
                        color: zynqtgui.theme_chooser.noteColors[subNote.midiNote]
                        opacity: 0.3
                    }
                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: padSubNoteRect.height * (actualSubnoteVelocity / 127)
                        color: zynqtgui.theme_chooser.noteColors[subNote.midiNote]
                    }
                    QQC2.Label {
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignBottom
                        text: "⏼"
                        font.pixelSize: 10
                        visible: subNoteVelocity === -1
                    }
                    Rectangle {
                        anchors.fill: parent;
                        border {
                            width: 2
                            color: Kirigami.Theme.highlightColor
                        }
                        color: "transparent"
                        visible: component.currentSubNote == index
                    }
                }
            }
        }

        Item {
            anchors {
                fill: parent
                bottomMargin: 10
            }
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Kirigami.Units.largeSpacing
                    verticalCenter: parent.verticalCenter
                }
                height: width;
                color: padNoteRect.color
                opacity: 0.3
                radius: height / 2
            }
            QQC2.Label {
                id: padNoteLabel
                anchors.centerIn: parent
                text: component.patternModel ? (component.padNoteNumber - component.patternModel.workingModel.bankOffset * component.patternModel.workingModel.width) + 1 : ""
                color: component.foregroundColor
            }
        }

        Rectangle {
            id:stepIndicatorRect
            anchors {
                left: parent.left
                right: parent.right
                top: parent.bottom
                margins: 1
            }
            height:9
            color: visible && component.patternModel
                ? component.patternModel.sequence.isPlaying
                    ? component.patternModel.playingRow === component.padNoteRow && component.patternModel.playingColumn === component.padNoteIndex
                        ? "yellow"
                        : "transparent"
                    : component.padNoteRow === component.patternModel.bankOffset && component.padNoteIndex === 0 && ((component.patternModel.sequence.soloPattern > -1 && component.patternModel.sequence.soloPatternObject === component.patternModel) || (component.patternModel.sequence.soloPattern === -1 && component.patternModel.enabled))
                        ? "yellow"
                        : "transparent"
                : "transparent"
        }
        Rectangle {
            anchors {
                fill: parent;
                margins: 1
            }
            border {
                width: 2
                color: Kirigami.Theme.highlightColor
            }
            color: "transparent"
            visible: component.isCurrent && component.currentSubNote === -1
        }
        Rectangle {
            id: pressAndHoldVisualiser
            anchors {
                left: padNoteRect.right
                leftMargin: 1
                bottom: padNoteRect.bottom
                bottomMargin: 1
            }
            width: Kirigami.Units.smallSpacing
            color: component.focusColor
            height: 0
            opacity: 0
            states: [
                State {
                    name: "held"; when: (longPressTimer.running || longPressTimer.pressingAndHolding);
                    PropertyChanges { target: pressAndHoldVisualiser; height: padNoteRect.height - 2; opacity: 1 }
                }
            ]
            transitions: [
                Transition {
                    from: ""; to: "held";
                    NumberAnimation { property: "height"; duration: longPressTimer.interval; }
                    NumberAnimation { property: "opacity"; duration: longPressTimer.interval; }
                }
            ]
            Timer {
                id: longPressTimer;
                interval: 1000; repeat: false; running: false
                property bool pressingAndHolding: false;
                property bool insideBounds: false;
                property int subNoteIndex: -1;
                onTriggered: {
                    if (insideBounds) {
                        component.pressAndHold(subNoteIndex);
                    }
                    longPressTimer.pressingAndHolding = true;
                }
            }
        }
    }
}
