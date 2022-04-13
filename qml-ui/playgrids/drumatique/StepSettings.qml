/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Settings panel for a single step in a pattern

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
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

ColumnLayout {
    id: component
    property QtObject model
    property int row: -1
    property int column: -1
    property int currentSubNote: -1
    signal changeSubnote(int newSubnote);
    onChangeSubnote: {
        component.currentSubNote = newSubnote;
    }

    property var noteLengths: {
        1: 32,
        2: 16,
        3: 8,
        4: 4,
        5: 2,
        6: 1
    }
    property int stepDuration: component.model ? noteLengths[component.model.noteLength] : 0
    property var noteLengthNames: {
        1: "1 (default)",
        2: "1/2 (default)",
        3: "1/4 (default)",
        4: "1/8 (default)",
        5: "1/16 (default)",
        6: "1/32 (default)"
    }
    property string stepDurationName: component.model ? noteLengthNames[component.model.noteLength] : ""
    property var noteSpecificColor: {
        "C":"#f08080",
        "C#":"#4b0082",
        "D":"#8a2be2",
        "D#":"#a52a2a" ,
        "E":"#deb887",
        "F":"#5f9ea0",
        "F#":"#7fff00",
        "G":"#d2691e",
        "G#":"#6495ed",
        "A":"#dc143c",
        "A#":"#008b8b",
        "B":"#b8860b"
    }

    onVisibleChanged: {
        if (!visible) {
            model = null;
            row = -1;
            column = -1;
        }
    }

    readonly property QtObject note: component.model && component.row > -1 && component.column > -1 ? component.model.getNote(component.row, component.column) : null

    function setDuration(duration, isDefault) {
        if (component.currentSubNote === -1) {
            if (note) {
                for (var subnoteIndex = 0; subnoteIndex < note.subnotes.length; ++subnoteIndex) {
                    component.model.setSubnoteMetadata(component.row, component.column, subnoteIndex, "duration", isDefault ? 0 : duration);
                }
            }
        } else {
            component.model.setSubnoteMetadata(component.row, component.column, component.currentSubNote, "duration", isDefault ? 0 : duration);
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
        QQC2.Label {
            id: noteHeaderLabel
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            text: "Note"
            MultiPointTouchArea {
                anchors.fill: parent
                touchPoints: [
                    TouchPoint {
                        onPressedChanged: {
                            if (!pressed && x > -1 && y > -1 && x < noteHeaderLabel.width && y < noteHeaderLabel.height) {
                                component.changeSubnote(-1);
                            }
                        }
                    }
                ]
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            text: "Velocity"
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            text: "Duration"
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            text: "Position"
        }
    }
    Repeater {
        model: component.note ? component.note.subnotes : 0
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            Item {
                id: noteDelegate
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                MultiPointTouchArea {
                    anchors.fill: parent
                    touchPoints: [
                        TouchPoint {
                            onPressedChanged: {
                                if (!pressed && x > -1 && y > -1 && x < noteDelegate.width && y < noteDelegate.height) {
                                    component.changeSubnote(model.index);
                                }
                            }
                        }
                    ]
                }
                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        bottom: parent.bottom
                        margins: 1
                    }
                    width: Kirigami.Units.largeSpacing
                    color: Kirigami.Theme.highlightColor
                    visible: model.index === component.currentSubNote
                }
                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        leftMargin: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                        bottom: parent.bottom
                        margins: 1
                    }
                    width: height
                    radius: height / 2
                    color: modelData ? component.noteSpecificColor[modelData.name] : "transparent"
                }
                QQC2.Label {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    font.bold: true
                    text: modelData ? modelData.name + modelData.octave : ""
                }
            }
            StepSettingsParamDelegate {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                model: component.model; row: component.row; column: component.column;
                paramIndex: index
                paramName: "velocity"
                paramDefaultString: "64"
                paramValueSuffix: ""
                paramDefault: 64
                paramMin: 0
                paramMax: 127
                scrollWidth: 128
            }
            StepSettingsParamDelegate {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                model: component.model; row: component.row; column: component.column;
                paramIndex: index
                paramName: "duration"
                paramDefaultString: component.stepDurationName
                paramValueSuffix: "/32qn"
                paramDefault: undefined
                paramInterpretedDefault: component.stepDuration
                paramMin: 0
                paramMax: 128
                scrollWidth: 128
                paramList: [0, 1, 2, 4, 8, 16, 32, 64, 128]
                paramNames: {
                    0: component.stepDurationName,
                    1: (component.model.noteLength === 6 ? "1/32qn (default)" : "1/32qn"),
                    2: (component.model.noteLength === 5 ? "1/16qn (default)" : "1/16qn"),
                    4: (component.model.noteLength === 4 ? "1/8qn (default)" : "1/8qn"),
                    8: (component.model.noteLength === 3 ? "1/4qn (default)" : "1/4qn"),
                    16: (component.model.noteLength === 2 ? "1/2qn (default)" : "1/2qn"),
                    32: (component.model.noteLength === 1 ? "1qn (default)" : "1qn"),
                    64: "2qn",
                    96: "3qn",
                    128: "4qn"
                }
            }
            StepSettingsParamDelegate {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                model: component.model; row: component.row; column: component.column;
                paramIndex: index
                paramName: "delay"
                paramDefaultString: "0 (default)"
                paramValuePrefix: "+"
                paramValueSuffix: "/32qn"
                paramDefault: undefined
                paramInterpretedDefault: 0
                paramMin: 0
                paramMax: component.stepDuration - 1
                scrollWidth: component.stepDuration
                Component.onCompleted: {
                    var potentialValues = {
                        0: "0 (default)",
                        1: "+1/32qn",
                        2: "+1/16qn",
                        4: "+1/8qn",
                        8: "+1/4qn",
                        16: "+1/2qn",
                        32: "+1qn",
                        64: "+2qn",
                        96: "+3qn",
                        128: "+4qn"
                    };
                    var values = [];
                    var names = {};
                    for (var key in potentialValues) {
                        if (potentialValues.hasOwnProperty(key) && key < component.stepDuration) {
                            values.push(key);
                            names[key] = potentialValues[key];
                        }
                    }
                    paramList = values;
                    paramNames = names;
                }
            }
        }
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.minimumHeight: 1
        Layout.maximumHeight: 1
        color: Kirigami.Theme.textColor
        opacity: 0.5
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            horizontalAlignment: Text.AlignHCenter
            text: "DEFAULT"
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1"
            checked: component.model ? component.model.noteLength === 1 : false
            onClicked: { component.setDuration(32, checked); }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1/2"
            checked: component.model ? component.model.noteLength === 2 : false
            onClicked: { component.setDuration(16, checked); }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1/4"
            checked: component.model ? component.model.noteLength === 3 : false
            onClicked: { component.setDuration(8, checked); }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1/8"
            checked: component.model ? component.model.noteLength === 4 : false
            onClicked: { component.setDuration(4, checked); }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1/16"
            checked: component.model ? component.model.noteLength === 5 : false
            onClicked: { component.setDuration(2, checked); }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1/32"
            checked: component.model ? component.model.noteLength === 6 : false
            onClicked: { component.setDuration(1, checked); }
        }
    }
}
