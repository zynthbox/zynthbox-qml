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

import org.zynthian.quick 1.0 as ZynQuick

QQC2.Button {
    id: component
    property QtObject playgrid
    property QtObject patternModel
    property int activeBar
    property int padNoteNumber
    property QtObject note
    property int padNoteRow: component.patternModel ? activeBar + component.patternModel.bankOffset : 0
    property int padNoteIndex
    property var mostRecentlyPlayedNote
    property bool isCurrent: false
    property int currentSubNote: -1
    property alias subNoteCount: padSubNoteRepeater.count

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    property color foregroundColor: Kirigami.Theme.backgroundColor
    property color backgroundColor: Kirigami.Theme.textColor
    property color borderColor: foregroundColor

    MultiPointTouchArea {
        anchors.fill: parent

        property var timeOnClick
        property var timeOnRelease
        enabled: (component.playgrid.mostRecentlyPlayedNote || component.playgrid.heardNotes.length > 0) ? true : false

        onPressed: {
            if (component.playgrid.heardNotes.length > 0) {
                var removedAtLeastOne = false;
                // First, let's see if any of the notes in our list are already on this position, and if so, remove them
                for (var i = 0; i < component.playgrid.heardNotes.length; ++i) {
                    var subNoteIndex = component.patternModel.subnoteIndex(component.padNoteRow, component.padNoteIndex, component.playgrid.heardNotes[i].midiNote);
                    if (subNoteIndex > -1) {
                        component.patternModel.removeSubnote(component.padNoteRow, component.padNoteIndex, subNoteIndex);
                        removedAtLeastOne = true;
                    }
                }

                // And then, only if we didn't remove anything should we be adding the notes
                if (!removedAtLeastOne) {
                    for (var i = 0; i < component.playgrid.heardNotes.length; ++i) {
                        var subNoteIndex = component.patternModel.addSubnote(component.padNoteRow, component.padNoteIndex, component.playgrid.heardNotes[i]);
                        component.patternModel.setSubnoteMetadata(component.padNoteRow, component.padNoteIndex, subNoteIndex, "velocity", component.playgrid.heardVelocities[i]);
                    }
                }
                component.note = component.patternModel.getNote(component.padNoteRow, component.padNoteIndex);
            } else if (component.playgrid.mostRecentlyPlayedNote) {
                var aNoteData = {
                    velocity: component.playgrid.mostRecentNoteVelocity,
                    note: component.playgrid.mostRecentlyPlayedNote.midiNote,
                    channel: component.playgrid.mostRecentlyPlayedNote.midiChannel
                }

                var subNoteIndex = component.patternModel.subnoteIndex(component.padNoteRow, component.padNoteIndex, aNoteData["note"]);
                if (subNoteIndex > -1) {
                    component.patternModel.removeSubnote(component.padNoteRow, component.padNoteIndex, subNoteIndex)
                } else {
                    subNoteIndex = component.patternModel.addSubnote(component.padNoteRow, component.padNoteIndex, component.playgrid.getNote(aNoteData["note"], aNoteData["channel"]));
                    component.patternModel.setSubnoteMetadata(component.padNoteRow, component.padNoteIndex, subNoteIndex, "velocity", aNoteData["velocity"]);
                }
                component.note = component.patternModel.getNote(component.padNoteRow, component.padNoteIndex)
            }
        }
    }

    background: Rectangle {
        id:padNoteRect
        anchors.fill:parent
        color: component.backgroundColor
        border {
            color: component.borderColor
            width: 1
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
            property real dividedSubNoteHeight: maxHalfSubnoteHeight / 100
            spacing: 1
            Repeater {
                id:padSubNoteRepeater
                model: component.note ? component.note.subnotes : 0;
                delegate: Item {
                    id:padSubNoteRect
                    property var subNote: modelData
                    property var subNoteVelocity: component.patternModel.subnoteMetadata(component.padNoteRow, component.padNoteIndex, index, "velocity");
                    property var subNoteDuration: component.patternModel.subnoteMetadata(component.padNoteRow, component.padNoteIndex, index, "duration");

                    Layout.fillWidth: true
                    Layout.minimumHeight: subnoteLayout.maxHalfSubnoteHeight * 2
                    Layout.maximumHeight: Layout.minimumHeight
                    visible: component.mostRecentlyPlayedNote == undefined || component.mostRecentlyPlayedNote == subNote
                    MultiPointTouchArea {
                        enabled: component.playgrid.mostRecentlyPlayedNote ? false : true
                        anchors.fill: parent
                        touchPoints: [
                            TouchPoint {
                                onPressedChanged: {
                                    if (!pressed) {
                                        if (x > -1 && y > -1 && x < padSubNoteRect.width && y < padSubNoteRect.height) {
                                            component.playgrid.mostRecentNoteVelocity = padSubNoteRect.subNoteVelocity;
                                            component.playgrid.mostRecentlyPlayedNote = padSubNoteRect.subNote;
                                        }
                                    }
                                }
                            }
                        ]
                    }
                    Rectangle {
                        anchors.fill: parent;
                        color: playgrid.getNoteSpecificColor(subNote.name,subNote.octave)
                        opacity: 0.3
                    }
                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: subnoteLayout.maxHalfSubnoteHeight + (subnoteLayout.dividedSubNoteHeight * (subNoteVelocity / 127) * 100)
                        color: playgrid.getNoteSpecificColor(subNote.name,subNote.octave)
                    }
                    Item {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                        }
                        height: 4
                        width: 2
                        visible: padSubNoteRect.subNoteDuration > 0
                        Item {
                            anchors {
                                top: parent.top
                                left: parent.right
                            }
                            transformOrigin: Item.TopLeft
                            rotation: -90
                            height: subnoteText.height
                            width: subnoteText.width
                            Rectangle {
                                anchors {
                                    fill: parent
                                    margins: -1
                                }
                                color: component.backgroundColor
                                opacity: 0.3
                                radius: height / 2
                            }
                            Text {
                                id: subnoteText
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                }
                                height: paintedHeight
                                width: paintedWidth
                                text: padSubNoteRect.subNoteDuration + "/32 qn"
                                font.pixelSize: 8
                                verticalAlignment: Text.AlignTop
                                horizontalAlignment: Text.AlignLeft
                            }
                        }
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
                text: component.patternModel ? (component.padNoteNumber - component.patternModel.bankOffset * component.patternModel.width) + 1 : ""
                color: component.foregroundColor
            }
        }

        Rectangle {
            id:stepIndicatorRect
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 1
            }
            height:9
            color: component.patternModel
                ? component.patternModel.sequence.isPlaying
                    ? component.patternModel.playingRow === component.padNoteRow && component.patternModel.playingColumn === component.padNoteIndex
                        ? "yellow"
                        : component.backgroundColor
                    : component.padNoteRow === component.patternModel.bankOffset && component.padNoteIndex === 0 && ((component.patternModel.sequence.soloPattern > -1 && component.patternModel.sequence.soloPatternObject === component.patternModel) || (component.patternModel.sequence.soloPattern === -1 && component.patternModel.enabled))
                        ? "yellow"
                        : component.backgroundColor
                : "white"
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
    }
}
