/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Play Grid Page 

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>

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

import Zynthian 1.0 as Zynthian

Zynthian.ScreenPage {
    id: component
    screenId: "playgrid"
    leftPadding: 0
    rightPadding: 0
    topPadding: 5
    bottomPadding: 5

    Component.onCompleted: {
        applicationWindow().controlsVisible = false
    }

    Component.onDestruction: {
        applicationWindow().controlsVisible = true
    }

    ListModel {
        id: scaleModel

        ListElement { scale: "chromatic"; text: "Chromatic" }
        ListElement { scale: "ionian"; text: "Ionian (Major)" }
        ListElement { scale: "dorian"; text: "Dorian" }
        ListElement { scale: "phrygian"; text: "Phrygian" }
        ListElement { scale: "lydian"; text: "Lydian" }
        ListElement { scale: "mixolydian"; text: "Mixolydian" }
        ListElement { scale: "aeolian"; text: "Aeolian (Natural Minor)" }
        ListElement { scale: "locrian"; text: "Locrian" }
    }
    property string currentNoteName: keyModel.getName(zynthian.playgrid.startingNote)
    ListModel {
        id: keyModel
        function getName(note) {
            for(var i = 0; i < keyModel.rowCount(); ++i) {
                var le = keyModel.get(i);
                if (le.note = note) {
                    return le.text;
                }
            }
            return "C";
        }

        ListElement { note: 36; text: "C" }
        ListElement { note: 37; text: "C#" }
        ListElement { note: 38; text: "D" }
        ListElement { note: 39; text: "D#" }
        ListElement { note: 40; text: "E" }
        ListElement { note: 41; text: "F" }
        ListElement { note: 42; text: "F#" }
        ListElement { note: 43; text: "G" }
        ListElement { note: 44; text: "G#" }
        ListElement { note: 45; text: "A" }
        ListElement { note: 46; text: "A#" }
        ListElement { note: 47; text: "B" }
    }
    ListModel {
        id: gridModel

        ListElement { row: 0; column: 0; text: "Custom" }
        ListElement { row: 3; column: 3; text: "3x3" }
        ListElement { row: 4; column: 4; text: "4x4" }
        ListElement { row: 5; column: 8; text: "5x8" }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            id: controlsPanel

            Layout.preferredWidth: 80
            Layout.maximumWidth: Layout.preferredWidth
            Layout.fillHeight: true
            Layout.margins: 8

            QQC2.Dialog {
                id: settingsDialog
                visible: false
                title: "Settings"
                modal: true
                width: component.width - Kirigami.Units.largeSpacing * 4
                height: component.height - Kirigami.Units.largeSpacing * 4
                x: Kirigami.Units.largeSpacing
                y: Kirigami.Units.largeSpacing

                footer: Zynthian.ActionBar {
                    Layout.fillWidth: true
                    currentPage: Item {
                        property QtObject backAction: Kirigami.Action {
                            text: "Back"
                            onTriggered: {
                                settingsDialog.visible = false;
                            }
                        }
                        property list<QtObject> contextualActions: [
                            Kirigami.Action {
                                text: "Main Settings"
                                enabled: settingsStack.currentItem ? settingsStack.currentItem.objectName !== "main" : false
                                onTriggered: {
                                    settingsStack.replace(mainSettings);
                                }
                            },
                            Kirigami.Action {
                                text: "Chords"
                                enabled: settingsStack.currentItem ? settingsStack.currentItem.objectName !== "chords" : false
                                onTriggered: {
                                    settingsStack.replace(chordsSettings);
                                }
                            }
                        ]
                    }
                }

                QQC2.StackView {
                    id: settingsStack
                    anchors.fill: parent
                    initialItem: mainSettings
                }
                Component {
                    id: chordsSettings
                    Kirigami.FormLayout {
                        objectName: "chords"
                        QQC2.ComboBox {
                            model: ["beep", "boop"]
                        }
                    }
                }
                Component {
                    id: mainSettings
                    Kirigami.FormLayout {
                        objectName: "main"
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        QQC2.ComboBox {
                            id: comboScale
                            Kirigami.FormData.label: "Modes"
                            Layout.fillWidth: true
                            model: scaleModel
                            textRole: "text"
                            displayText: currentText
                            currentIndex: 1

                            onActivated: {
                                zynthian.playgrid.startingNote = 36;
                                zynthian.playgrid.scale = scaleModel.get(currentIndex).scale
                            }
                        }
                        QQC2.ComboBox {
                            id: comboKey
                            Layout.fillWidth: true
                            Kirigami.FormData.label: "Key"
                            visible: zynthian.playgrid.scale == "chromatic"
                            model: keyModel
                            textRole: "text"
                            displayText: currentText
                            currentIndex: 0

                            onActivated: {
                                zynthian.playgrid.startingNote = keyModel.get(currentIndex).note;
                            }
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            Kirigami.FormData.label: "Transpose"
                            visible: zynthian.playgrid.scale == "chromatic"
                            text: "-"
                            onClicked: {
                                if (zynthian.playgrid.startingNote - 1 > 0) {
                                    zynthian.playgrid.startingNote--;
                                } else {
                                    zynthian.playgrid.startingNote = 0;
                                }
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            visible: zynthian.playgrid.scale == "chromatic"
                            text: "+"
                            onClicked: {
                                zynthian.playgrid.startingNote++;
                            }
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            Kirigami.FormData.label: "Octave"
                            visible: zynthian.playgrid.scale != "chromatic"
                            text: "-"
                            onClicked: {
                                if (zynthian.playgrid.startingNote - 12 > 0) {
                                    zynthian.playgrid.startingNote = zynthian.playgrid.startingNote - 12;
                                } else {
                                    zynthian.playgrid.startingNote = 0;
                                }
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            visible: zynthian.playgrid.scale != "chromatic"
                            text: "+"
                            onClicked: {
                                zynthian.playgrid.startingNote = zynthian.playgrid.startingNote + 12;
                            }
                        }
                        QQC2.ComboBox {
                            id: optionGrid
                            Layout.fillWidth: true
                            Kirigami.FormData.label: "Grid"
                            model: gridModel
                            textRole: "text"
                            displayText: currentText
                            currentIndex: 3

                            onActivated: {
                                var data = gridModel.get(currentIndex)

                                if (data.row === 0 && data.column === 0) {
                                    zynthian.playgrid.rows = customRows.currentText;
                                    zynthian.playgrid.columns = customColumns.currentText;
                                } else {
                                    zynthian.playgrid.rows = data.row;
                                    zynthian.playgrid.columns = data.column;
                                }
                            }
                        }

                        QQC2.ComboBox {
                            id: customRows
                            Layout.fillWidth: true
                            visible: optionGrid.currentIndex === 0
                            Kirigami.FormData.label: "Custom Grid Rows"
                            model: [3,4,5,6,7,8,9]
                            displayText: currentText
                            currentIndex: 0
                            onActivated: {
                                zynthian.playgrid.rows = currentText;
                            }
                        }
                        QQC2.ComboBox {
                            id: customColumns
                            Layout.fillWidth: true
                            visible: optionGrid.currentIndex === 0
                            Kirigami.FormData.label: "Custom Grid Columns"
                            model: [3,4,5,6,7,8,9]
                            displayText: currentText
                            currentIndex: 0
                            onActivated: {
                                zynthian.playgrid.columns = currentText;
                            }
                        }
                        QQC2.Switch {
                            id: positionalVelocitySwitch
                            Layout.fillWidth: true
                            Kirigami.FormData.label: "Use Tap Position As Velocity"
                            checked: zynthian.playgrid.positionalVelocity
                            onClicked: {
                                zynthian.playgrid.positionalVelocity = !zynthian.playgrid.positionalVelocity
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 8

                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    icon.name: "arrow-up"
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    background: Rectangle {
                        radius: 2
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        border {
                            width: 1
                            color: Kirigami.Theme.textColor
                        }
                        color: Kirigami.Theme.backgroundColor
                    }
                    onClicked: {
                        zynthian.playgrid.startingNote = zynthian.playgrid.startingNote + 12;
                    }
                }
                QQC2.Label {
                    text: "Octave"
                    Layout.alignment: Qt.AlignHCenter
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    icon.name: "arrow-down"
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    background: Rectangle {
                        radius: 2
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        border {
                            width: 1
                            color: Kirigami.Theme.textColor
                        }
                        color: Kirigami.Theme.backgroundColor
                    }
                    onClicked: {
                        if (zynthian.playgrid.startingNote - 12 > 0) {
                            zynthian.playgrid.startingNote = zynthian.playgrid.startingNote - 12;
                        } else {
                            zynthian.playgrid.startingNote = 0;
                        }
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    background: Rectangle {
                        radius: 2
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        border {
                            width: 1
                            color: Kirigami.Theme.textColor
                        }
                        color: Kirigami.Theme.backgroundColor

                        Text {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            Kirigami.Theme.inherit: false
                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                            color: Kirigami.Theme.textColor
                            text: "Mod\nulate"
                        }
                    }
                    MultiPointTouchArea {
                        anchors.fill: parent
                        property int modulationValue: Math.max(-127, Math.min(modulationPoint.y * 127 / width, 127))
                        onModulationValueChanged: {
                            //zynthian.playgrid.modulation = modulationValue;
                        }
                        touchPoints: [ TouchPoint { id: modulationPoint; } ]
                        onPressed: {
                            parent.down = true;
                            focus = true;
                        }
                        onReleased: {
                            parent.down = false;
                            focus = false;
                            //zynthian.playgrid.modulation = 0;
                        }
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    icon.name: "arrow-up"
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    background: Rectangle {
                        radius: 2
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        border {
                            width: 1
                            color: Kirigami.Theme.textColor
                        }
                        color: Kirigami.Theme.backgroundColor
                    }
                    MultiPointTouchArea {
                        anchors.fill: parent
                        onPressed: {
                            parent.down = true;
                            focus = true;
                            zynthian.playgrid.pitch = 8191;
                        }
                        onReleased: {
                            parent.down = false;
                            focus = false;
                            zynthian.playgrid.pitch = 0;
                        }
                    }
                }
                QQC2.Label {
                    text: "Pitch"
                    Layout.alignment: Qt.AlignHCenter
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    icon.name: "arrow-down"
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    background: Rectangle {
                        radius: 2
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        border {
                            width: 1
                            color: Kirigami.Theme.textColor
                        }
                        color: Kirigami.Theme.backgroundColor
                    }
                    MultiPointTouchArea {
                        anchors.fill: parent
                        onPressed: {
                            parent.down = true;
                            focus = true;
                            zynthian.playgrid.pitch = -8192;
                        }
                        onReleased: {
                            parent.down = false;
                            focus = false;
                            zynthian.playgrid.pitch = 0;
                        }
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    icon.name: "configure"
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    background: Rectangle {
                        radius: 2
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        border {
                            width: 1
                            color: Kirigami.Theme.textColor
                        }
                        color: Kirigami.Theme.backgroundColor
                    }
                    onClicked: {
                        settingsDialog.visible = true;
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                anchors.margins: 5

                Repeater {
                    model: zynthian.playgrid.model
                    delegate: RowLayout {
                        property var row: index

                        Layout.margins: 2.5

                        Repeater {
                            model: zynthian.playgrid.model.columnCount(zynthian.playgrid.model.index(index, 0))
                            delegate: QQC2.Button {
                                id: playDelegate
                                property var column: index
                                property var note: zynthian.playgrid.model.data(zynthian.playgrid.model.index(row, column), zynthian.playgrid.model.roles['note'])

                                // Pitch is -8192 to 8191 inclusive
                                property int pitchValue: Math.max(-8192, Math.min(pitchModPoint.pitchModX * 8192 / width, 8191))
                                onPitchValueChanged: zynthian.playgrid.pitch = pitchValue
                                property int modulationValue: Math.max(-127, Math.min(pitchModPoint.pitchModY * 127 / width, 127))
                                property int velocityValue: {
                                    if (zynthian.playgrid.positionalVelocity) {
                                        return 127-pitchModPoint.startY * 127 / height;
                                    } else {
                                        // This seems slightly odd - but 1 is the very highest possible, and default is supposed to be a velocity of 64, so...
                                        return pitchModPoint.pressure > 0.99999 ? 64 : Math.floor(pitchModPoint.pressure * 127)
                                    }
                                }

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                background: Rectangle {
                                    radius: 2
                                    border {
                                        width: 1
                                        color: parent.focus ? Kirigami.Theme.highlightColor : "#e5e5e5"
                                    }
                                    color: {
                                        if (note.isPlaying) {
                                            return "#8bc34a";
                                        } else {
                                            if (zynthian.playgrid.scale !== "chromatic" &&
                                                note.name === component.currentNoteName
                                            )
                                                return Kirigami.Theme.focusColor
                                            else
                                                return "white"
                                        }
                                    }

                                    Text {
                                        anchors.fill: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        text: {
                                            if (zynthian.playgrid.scale == "major")
                                                return note.name
                                            else
                                                return note.name + note.octave
                                        }
                                    }
                                }

                                MultiPointTouchArea {
                                    anchors.fill: parent
                                    touchPoints: [
                                        TouchPoint {
                                            id: pitchModPoint;
                                            property double pitchModX: x < 0 ? Math.floor(x) : (x > playDelegate.width ? x - playDelegate.width : 0)
                                            property double pitchModY: y < 0 ? -Math.floor(y) : (y > playDelegate.height ? -(y - playDelegate.height) : 0)
                                        }
                                    ]
                                    property var playingNote;
                                    onPressed: {
                                        if (pitchModPoint.pressed) {
                                            parent.down = true;
                                            focus = true;
                                            playingNote = note;
                                            playingNote.on(playDelegate.velocityValue);
                                            zynthian.playgrid.highlightPlayingNotes(note, true);
                                        }
                                    }
                                    onReleased: {
                                        if (!pitchModPoint.pressed) {
                                            parent.down = false;
                                            focus = false;
                                            playingNote.off();
                                            zynthian.playgrid.pitch = 0
                                            zynthian.playgrid.highlightPlayingNotes(note, false);
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
