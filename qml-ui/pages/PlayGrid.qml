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
    property var playGridsModel: [
        { displayName: "Notes Grid", gridComponent: notesGrid, settingsComponent: notesGridSettings },
        { displayName: "Chords Grid", gridComponent: chordsGrid, settingsComponent: chordsGridSettings },
        { displayName: "Drumpads", gridComponent: chordsGrid, settingsComponent: chordsGridSettings }
    ]
    Connections {
        target: zynthian.playgrid
        onPlayGridIndexChanged: {
            playGridStack.replace(component.playGridsModel[zynthian.playgrid.playGridIndex].gridComponent);
            settingsStack.replace(component.playGridsModel[zynthian.playgrid.playGridIndex].settingsComponent);
        }
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
                        property list<QtObject> contextualActions
                    }
                }

                contentItem: RowLayout {
                    ListView {
                        Layout.preferredWidth: settingsDialog.width / 4
                        Layout.maximumWidth: Layout.preferredWidth
                        Layout.fillHeight: true
                        Layout.margins: 8
                        model: playGridsModel
                        currentIndex: zynthian.playgrid.playGridIndex
                        delegate: QQC2.ItemDelegate {
                            id: settingsSelectorDelegate
                            width: ListView.view.width
                            topPadding: Kirigami.Units.largeSpacing
                            leftPadding: Kirigami.Units.largeSpacing
                            bottomPadding: Kirigami.Units.largeSpacing
                            rightPadding: Kirigami.Units.largeSpacing
                            highlighted: ListView.isCurrentItem
                            background: Rectangle {
                                color: !settingsSelectorDelegate.ListView.isCurrentItem && !settingsSelectorDelegate.pressed
                                    ? "transparent"
                                    : ((settingsSelectorDelegate.ListView.view.activeFocus && !settingsSelectorDelegate.pressed || !settingsSelectorDelegate.ListView.view.activeFocus && settingsSelectorDelegate.pressed)
                                            ? Kirigami.Theme.highlightColor
                                            : Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.4))
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Kirigami.Units.shortDuration
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }
                            contentItem: QQC2.Label {
                                text: modelData.displayName
                                elide: Text.ElideRight
                            }
                            onClicked: {
                                zynthian.playgrid.playGridIndex = model.index;
                            }
                        }
                    }
                    QQC2.StackView {
                        id: settingsStack
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        initialItem: component.playGridsModel[zynthian.playgrid.playGridIndex].settingsComponent
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 8
                z: 999

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
                    id: settingsButton
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
                    function getYChoice() {
                        var choice = 0;
                        if (settingsSlidePoint.pressed) {
                            choice = Math.floor(settingsSlidePoint.y / settingsButton.width);
                        }
                        return choice;
                    }
                    function getXChoice() {
                        var choice = 0;
                        if (settingsSlidePoint.pressed) {
                            choice = Math.floor(settingsSlidePoint.x / settingsButton.height);
                        }
                        return choice;
                    }
                    MultiPointTouchArea {
                        anchors.fill: parent
                        touchPoints: [ TouchPoint { id: settingsSlidePoint; } ]
                        property int xChoice
                        property int yChoice
                        property string currentText
                        function getPositionalText() {
                            var text = "Do nothing";
                            var yChoice = settingsButton.getYChoice();
                            var xChoice = settingsButton.getXChoice();
                            // We only react to slides when outside the button
                            if (xChoice === 0 && yChoice !== 0) {
                                // Sliding upward from the button - switch between slide and not-slide input
                                switch (yChoice) {
                                    case -1:
                                        text = "Use Swipe Input";
                                        break;
                                    case -2:
                                        text = "Disable Swipe Input";
                                        break;
                                    default:
                                        var text = "Do nothing";
                                        break;
                                }
                            } else if (yChoice === 0 && xChoice !== 0) {
                                // Sliding rightward from the button - switch between grid modes
                                if (xChoice <= playGridsModel.length  && zynthian.playgrid.playGridIndex !== xChoice - 1) {
                                    text = "Switch to " + component.playGridsModel[xChoice - 1].displayName;
                                } else {
                                    text = "Do nothing";
                                }
                            } else if (yChoice === 0 && xChoice === 0) {
                                text = "Show Settings";
                            }
                            return text;
                        }
                        onPressed: {
                            if (settingsSlidePoint.pressed) {
                                xChoice = settingsButton.getXChoice();
                                yChoice = settingsButton.getYChoice();
                                parent.down = true;
                            }
                        }
                        onUpdated: {
                            if (settingsSlidePoint.pressed) {
                                xChoice = settingsButton.getXChoice();
                                yChoice = settingsButton.getYChoice();
                                var positionalText = getPositionalText();
                                if (positionalText != currentText) {
                                    applicationWindow().showPassiveNotification(positionalText);
                                    currentText = positionalText;
                                }
                            }
                        }
                        onReleased: {
                            if (!settingsSlidePoint.pressed) {
                                parent.down = false;
                                currentText = "";
                                if (xChoice === 0 && yChoice === 0) {
                                    // Then it we just had a tap
                                    settingsDialog.visible = true;
                                } else if (xChoice === 0 && yChoice !== 0) {
                                    switch (yChoice) {
                                        case -1:
                                            // Enable the swipey manipulation on the grids
                                            break;
                                        case -2:
                                            // Disable the swipy manipulation on the grids
                                            break;
                                        default:
                                            break;
                                    }
                                } else if (yChoice === 0 && xChoice !== 0) {
                                    if (xChoice <= playGridsModel.length && zynthian.playgrid.playGridIndex !== xChoice - 1) {
                                        zynthian.playgrid.playGridIndex = xChoice - 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        QQC2.StackView {
            id: playGridStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            initialItem: component.playGridsModel[zynthian.playgrid.playGridIndex].gridComponent
        }
    }
    Component {
        id: notesGrid
        ColumnLayout {
            objectName: "notesGrid"
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

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            background: Rectangle {
                                radius: 2
                                border {
                                    width: 1
                                    color: parent.focus ? Kirigami.Theme.highlightColor : "#e5e5e5"
                                }
                                color: {
                                    var color = "white";
                                    if (note) {
                                        if (note.isPlaying) {
                                            color = "#8bc34a";
                                        } else {
                                            if (zynthian.playgrid.scale !== "chromatic" &&
                                                note.name === component.currentNoteName
                                            ) {
                                                color = Kirigami.Theme.focusColor;
                                            } else {
                                                color = "white";
                                            }
                                        }
                                    }
                                    return color;
                                }

                                Text {
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: {
                                        var text = "";
                                        if (note && note.name != "") {
                                            if (zynthian.playgrid.scale == "major") {
                                                text = note.name
                                            } else {
                                                text = note.name + note.octave
                                            }
                                        }
                                        return text;
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
                                        var velocityValue = 64;
                                        if (zynthian.playgrid.positionalVelocity) {
                                            velocityValue = 127 - Math.floor(pitchModPoint.y * 127 / height);
                                        } else {
                                            // This seems slightly odd - but 1 is the very highest possible, and default is supposed to be a velocity of 64, so...
                                            velocityValue = pitchModPoint.pressure > 0.99999 ? 64 : Math.floor(pitchModPoint.pressure * 127);
                                        }
                                        parent.down = true;
                                        focus = true;
                                        playingNote = note;
                                        zynthian.playgrid.setNoteOn(playingNote, velocityValue);
                                    }
                                }
                                onReleased: {
                                    if (!pitchModPoint.pressed) {
                                        parent.down = false;
                                        focus = false;
                                        zynthian.playgrid.setNoteOff(playingNote);
                                        zynthian.playgrid.pitch = 0
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Component {
        id: notesGridSettings
        Kirigami.FormLayout {
            objectName: "notesGridSettings"
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
                Layout.fillWidth: true
                Kirigami.FormData.label: "Use Tap Position As Velocity"
                checked: zynthian.playgrid.positionalVelocity
                onClicked: {
                    zynthian.playgrid.positionalVelocity = !zynthian.playgrid.positionalVelocity
                }
            }
        }
    }
    Component {
        id: chordsGrid
        ColumnLayout {
            objectName: "chordsGrid"
            spacing: 0
            anchors.margins: 5
            Repeater {
                model: zynthian.playgrid.chordModel
                delegate: RowLayout {
                    property var row: index
                    Layout.margins: 2.5
                    Repeater {
                        model: zynthian.playgrid.chordModel.columnCount(zynthian.playgrid.chordModel.index(index, 0))
                        delegate: QQC2.Button {
                            id: playDelegate
                            property var column: index
                            property var note: zynthian.playgrid.chordModel.data(zynthian.playgrid.chordModel.index(row, column), zynthian.playgrid.chordModel.roles['note'])
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            background: Rectangle {
                                radius: 2
                                border {
                                    width: 1
                                    color: parent.focus ? Kirigami.Theme.highlightColor : "#e5e5e5"
                                }
                                color: {
                                    var color = "white";
                                    if (note) {
                                        if (note.isPlaying) {
                                            color = "#8bc34a";
                                        } else {
                                            if (zynthian.playgrid.scale !== "chromatic" &&
                                                note.name === component.currentNoteName
                                            ) {
                                                color = Kirigami.Theme.focusColor;
                                            } else {
                                                color = "white";
                                            }
                                        }
                                    }
                                    return color;
                                }

                                Text {
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    wrapMode: Text.Wrap
                                    text: {
                                        var text = "";
                                        if (note) {
                                            for (var i = 0; i < note.subnotes.length; ++i) {
                                                text += " " + note.subnotes[i].name + note.subnotes[i].octave
                                            }
                                        }
                                        return text;
                                    }
                                }
                            }

                            MultiPointTouchArea {
                                anchors.fill: parent
                                touchPoints: [
                                    TouchPoint {
                                        id: chordSlidePoint;
                                        property double slideX: x < 0 ? Math.floor(x) : (x > playDelegate.width ? x - playDelegate.width : 0)
                                        property double slideY: y < 0 ? -Math.floor(y) : (y > playDelegate.height ? -(y - playDelegate.height) : 0)
                                    }
                                ]
                                property var playingNote;
                                onPressed: {
                                    if (chordSlidePoint.pressed) {
                                        var velocityValue = 64;
                                        if (zynthian.playgrid.positionalVelocity) {
                                            velocityValue = 127 - Math.floor(chordSlidePoint.y * 127 / height);
                                        } else {
                                            // This seems slightly odd - but 1 is the very highest possible, and default is supposed to be a velocity of 64, so...
                                            velocityValue = chordSlidePoint.pressure > 0.99999 ? 64 : Math.floor(chordSlidePoint.pressure * 127);
                                        }
                                        parent.down = true;
                                        focus = true;
                                        playingNote = note;
                                        zynthian.playgrid.setNoteOn(playingNote, velocityValue)
                                    }
                                }
                                onReleased: {
                                    if (!chordSlidePoint.pressed) {
                                        parent.down = false;
                                        focus = false;
                                        zynthian.playgrid.setNoteOff(playingNote)
                                        zynthian.playgrid.pitch = 0
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Component {
        id: chordsGridSettings
        Kirigami.FormLayout {
            objectName: "chordsGridSettings"
            QQC2.ComboBox {
                Layout.fillWidth: true
                Kirigami.FormData.label: "Number Of Chord Rows"
                model: [3, 4, 5]
                currentIndex: {
                    for (var i = 0; i < count; ++i) {
                        if (zynthian.playgrid.chordRows === model[i]) {
                            return i;
                        }
                    }
                }
                onActivated: {
                    zynthian.playgrid.chordRows = model[currentIndex];
                }
            }
            Repeater {
                model: zynthian.playgrid.chordRows
                QQC2.ComboBox {
                    Layout.fillWidth: true
                    Kirigami.FormData.label: "Scale for row " + (index + 1)
                    property int repeaterIndex: index
                    model: scaleModel
                    textRole: "text"
                    displayText: currentText
                    currentIndex: {
                        var theScale = zynthian.playgrid.chordScales[repeaterIndex];
                        for (var i = 0; i < count; ++i) {
                            if (scaleModel.get(i).scale === theScale) {
                                return i;
                            }
                        }
                        return 0;
                    }
                    onActivated: {
                        zynthian.playgrid.setChordScale(repeaterIndex, scaleModel.get(currentIndex).scale);
                    }
                }
            }
            QQC2.Switch {
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
