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

GridLayout {
    id: component
    property QtObject model
    property int row: -1
    property int column: -1

    onVisibleChanged: {
        if (!visible) {
            model = null;
            row = -1;
            column = -1;
        }
    }

    flow: GridLayout.TopToBottom
    rows: note ? note.subnotes.length + 2 : 2
    readonly property QtObject note: component.model && component.row > -1 && component.column > -1 ? component.model.getNote(component.row, component.column) : null
    QQC2.Label {
        Layout.fillWidth: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
        horizontalAlignment: Text.AlignHCenter
        font.bold: true
        text: "Note"
    }
    Repeater {
        model: component.note ? component.note.subnotes : 0
        QQC2.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            text: modelData ? modelData.name + modelData.octave : ""
        }
    }
    QQC2.Label {
        Layout.fillWidth: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
        horizontalAlignment: Text.AlignHCenter
        text: "DEFAULT"
    }

    QQC2.Label {
        Layout.columnSpan: 2
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        font.bold: true
        text: "Velocity"
    }
    Repeater {
        model: component.note ? component.note.subnotes : 0
        StepSettingsParamDelegate {
            model: component.model; row: component.row; column: component.column;
            paramIndex: index
            paramName: "velocity"
            paramDefaultString: "64"
            paramValueSuffix: ""
            paramDefault: 64
            paramMin: 0
            paramMax: 127
        }
    }
    Zynthian.PlayGridButton {
        text: "1"
        checked: component.model ? component.model.noteLength === 1 : false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
    }
    Zynthian.PlayGridButton {
        text: "1/2"
        checked: component.model ? component.model.noteLength === 2 : false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
    }

    QQC2.Label {
        Layout.columnSpan: 2
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        font.bold: true
        text: "Duration"
    }
    Repeater {
        model: component.note ? component.note.subnotes : 0
        StepSettingsParamDelegate {
            model: component.model; row: component.row; column: component.column;
            paramIndex: index
            paramName: "duration"
            paramDefaultString: "(default)"
            paramValueSuffix: "/32qn"
            paramDefault: 0
            paramMin: 0
            paramMax: 2147483647
        }
    }
    Zynthian.PlayGridButton {
        text: "1/4"
        checked: component.model ? component.model.noteLength === 3 : false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
    }
    Zynthian.PlayGridButton {
        text: "1/8"
        checked: component.model ? component.model.noteLength === 4 : false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
    }

    QQC2.Label {
        Layout.columnSpan: 2
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        font.bold: true
        text: "Delay"
    }
    Repeater {
        model: component.note ? component.note.subnotes : 0
        StepSettingsParamDelegate {
            model: component.model; row: component.row; column: component.column;
            paramIndex: index
            paramName: "delay"
            paramDefaultString: "(no delay)"
            paramValueSuffix: "/32qn"
            paramDefault: 0
            paramMin: 0
            paramMax: 2147483647
        }
    }
    Zynthian.PlayGridButton {
        text: "1/16"
        checked: component.model ? component.model.noteLength === 5 : false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
    }
    Zynthian.PlayGridButton {
        text: "1/32"
        checked: component.model ? component.model.noteLength === 6 : false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
    }
}
