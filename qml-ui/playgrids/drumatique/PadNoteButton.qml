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
    property int padNoteRow: activeBar + component.patternModel.bankOffset
    property int padNoteIndex
    property var mostRecentlyPlayedNote
    signal saveDraft();

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    property color foregroundColor: Kirigami.Theme.backgroundColor
    property color backgroundColor: Kirigami.Theme.textColor
    property color borderColor: foregroundColor

    MultiPointTouchArea {
        anchors.fill: parent

        property var timeOnClick
        property var timeOnRelease
        enabled: component.playgrid.mostRecentlyPlayedNote ? true : false

        onPressed: {
            if (component.playgrid.mostRecentlyPlayedNote) {
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
                component.saveDraft();
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
                delegate:Rectangle {
                    id:padSubNoteRect
                    property var subNote: modelData
                    property var subNoteVelocity: component.patternModel.subnoteMetadata(component.padNoteRow, component.padNoteIndex, index, "velocity");

                    Layout.alignment: Qt.AlignBottom
                    Layout.fillWidth: true
                    Layout.minimumHeight: subnoteLayout.maxHalfSubnoteHeight + (subnoteLayout.dividedSubNoteHeight * (subNoteVelocity / 127) * 100)
                    Layout.maximumHeight: Layout.minimumHeight
                    visible: component.mostRecentlyPlayedNote == undefined || component.mostRecentlyPlayedNote == subNote
                    color: playgrid.getNoteSpecificColor(subNote.name,subNote.octave)
                    MultiPointTouchArea {
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
                text: (component.padNoteNumber - component.patternModel.bankOffset * component.patternModel.width) + 1
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
            color: component.patternModel.sequence.isPlaying && component.patternModel.playingRow === component.padNoteRow && component.patternModel.playingColumn === component.padNoteIndex
                ? "yellow"
                : component.backgroundColor
        }
    }
}
