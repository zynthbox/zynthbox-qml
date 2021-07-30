/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Play Grid Page 

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>

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

    RowLayout {
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            property var textSize: 10
            property var textElementWidth: 150
            property var cellSize: 30

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
                standardButtons: Dialog.Close
                width: 600
                height: 400
                x: root.width / 2 - width / 2
                y: root.height / 2 - height / 2

                ColumnLayout{
                    anchors.centerIn: parent

                    RowLayout {
                        id: optionScale

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

                        QQC2.Label {
                            Layout.preferredWidth: controlsPanel.textElementWidth
                            text: "Modes"
                            font.pointSize: controlsPanel.textSize
                        }
                        QQC2.ComboBox {
                            id: comboScale
                            Layout.fillWidth: true
                            Layout.preferredHeight: controlsPanel.cellSize
                            model: scaleModel
                            textRole: "text"
                            displayText: currentText
                            currentIndex: 1

                            onActivated: {
                                if (scaleModel.get(currentIndex).scale === 'chromatic') {
                                    optionKey.visible = false;
                                    optionOctave.visible = true;
                                    optionTranspose.visible = true;
                                } else {
                                    optionKey.visible = true;
                                    optionOctave.visible = true;
                                    optionTranspose.visible = false;
                                }

                                zynthian.playgrid.startingNote = 36;
                                zynthian.playgrid.scale = scaleModel.get(currentIndex).scale
                            }
                        }
                    }

                    RowLayout {
                        id: optionKey
                        visible: true

                        ListModel {
                            id: keyModel

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

                        QQC2.Label {
                            Layout.preferredWidth: controlsPanel.textElementWidth
                            text: "Key"
                            font.pointSize: controlsPanel.textSize
                        }
                        QQC2.ComboBox {
                            id: comboKey
                            Layout.fillWidth: true
                            Layout.preferredHeight: controlsPanel.cellSize
                            model: keyModel
                            textRole: "text"
                            displayText: currentText
                            currentIndex: 0

                            onActivated: {
                                zynthian.playgrid.startingNote = keyModel.get(currentIndex).note;
                            }
                        }
                    }

                    RowLayout {
                        id: optionTranspose
                        visible: false

                        QQC2.Label {
                            Layout.preferredWidth: controlsPanel.textElementWidth
                            text: "Transpose"
                            font.pointSize: controlsPanel.textSize
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: controlsPanel.cellSize

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
                            Layout.preferredHeight: controlsPanel.cellSize
                            text: "+"
                            onClicked: {                               
                                zynthian.playgrid.startingNote++;
                            }
                        }
                    }

                    RowLayout {
                        id: optionOctave
                        visible: true

                        QQC2.Label {
                            Layout.preferredWidth: controlsPanel.textElementWidth
                            text: "Octave"
                            font.pointSize: controlsPanel.textSize
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: controlsPanel.cellSize
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
                            Layout.preferredHeight: controlsPanel.cellSize
                            text: "+"
                            onClicked: {
                                zynthian.playgrid.startingNote = zynthian.playgrid.startingNote + 12;
                            }
                        }
                    }

                    RowLayout {
                        id: optionGrid

                        ListModel {
                            id: gridModel

                            ListElement { row: 3; column: 3; text: "3x3" }
                            ListElement { row: 4; column: 4; text: "4x4" }
                            ListElement { row: 5; column: 8; text: "5x8" }
                            ListElement { row: 0; column: 0; text: "Custom" }
                        }

                        QQC2.Label {
                            Layout.preferredWidth: controlsPanel.textElementWidth
                            text: "Grid"
                            font.pointSize: controlsPanel.textSize
                        }
                        QQC2.ComboBox {
                            Layout.fillWidth: true
                            Layout.preferredHeight: controlsPanel.cellSize
                            model: gridModel
                            textRole: "text"
                            displayText: currentText
                            currentIndex: 2

                            onActivated: {
                                var data = gridModel.get(currentIndex)

                                if (data.row === 0 && data.column === 0) {
                                    optionCustomGrid.visible = true
                                    zynthian.playgrid.rows = customRows.currentText;
                                    zynthian.playgrid.columns = customColumns.currentText;
                                } else {
                                    optionCustomGrid.visible = false;
                                    zynthian.playgrid.rows = data.row;
                                    zynthian.playgrid.columns = data.column;
                                }
                            }
                        }
                    }

                    RowLayout {
                        id: optionCustomGrid
                        visible: false

                        QQC2.Label {
                            Layout.preferredWidth: controlsPanel.textElementWidth
                            text: "Custom Grid"
                            font.pointSize: controlsPanel.textSize
                        }
                        QQC2.ComboBox {
                            id: customRows
                            Layout.fillWidth: true
                            Layout.preferredHeight: controlsPanel.cellSize
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
                            Layout.preferredHeight: controlsPanel.cellSize
                            model: [3,4,5,6,7,8,9]
                            displayText: currentText
                            currentIndex: 0
                            onActivated: {
                                zynthian.playgrid.columns = currentText;
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
                    background: Rectangle {
                        radius: 2
                        border {
                            width: 1
                            color: Kirigami.Theme.buttonTextColor
                        }
                        color: Kirigami.Theme.buttonBackgroundColor
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
                    background: Rectangle {
                        radius: 2
                        border {
                            width: 1
                            color: Kirigami.Theme.buttonTextColor
                        }
                        color: Kirigami.Theme.buttonBackgroundColor
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
                    background: Rectangle {
                        radius: 2
                        border {
                            width: 1
                            color: Kirigami.Theme.buttonTextColor
                        }
                        color: Kirigami.Theme.buttonBackgroundColor

                        Text {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: Kirigami.Theme.buttonTextColor
                            text: "Mod\nulate"
                        }
                    }
                    onClicked: {
                        settingsDialog.visible = true;
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    icon.name: "arrow-up"
                    background: Rectangle {
                        radius: 2
                        border {
                            width: 1
                            color: Kirigami.Theme.buttonTextColor
                        }
                        color: Kirigami.Theme.buttonBackgroundColor
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
                    background: Rectangle {
                        radius: 2
                        border {
                            width: 1
                            color: Kirigami.Theme.buttonTextColor
                        }
                        color: Kirigami.Theme.buttonBackgroundColor
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
                    background: Rectangle {
                        radius: 2
                        border {
                            width: 1
                            color: Kirigami.Theme.buttonTextColor
                        }
                        color: Kirigami.Theme.buttonBackgroundColor
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
                                // This seems slightly odd - but 1 is the very highest possible, and default is supposed to be a velocity of 64, so...
                                property int velocityValue: pitchModPoint.pressure > 0.99999 ? 64 : Math.floor(pitchModPoint.pressure * 127)

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
                                            if (scaleModel.get(comboScale.currentIndex).scale !== "chromatic" &&
                                                note.name === keyModel.get(comboKey.currentIndex).text
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
                                            if (scaleModel.get(comboScale.currentIndex).scale == "major")
                                                return note.name// + "\nPitch/Mod\n" + zynthian.playgrid.pitch + "/" + playDelegate.modulationValue + "\nVel: " + playDelegate.velocityValue
                                            else
                                                return note.name + note.octave// + "\nPitch/Mod\n" + zynthian.playgrid.pitch + "/" + playDelegate.modulationValue + "\nVel: " + playDelegate.velocityValue
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
                                    onPressed: {
                                        if (pitchModPoint.pressed) {
                                            parent.down = true;
                                            focus = true;
                                            note.on(playDelegate.velocityValue);
                                            zynthian.playgrid.highlightPlayingNotes(note, true);
                                        }
                                    }
                                    onReleased: {
                                        if (!pitchModPoint.pressed) {
                                            parent.down = false;
                                            focus = false;
                                            note.off();
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
