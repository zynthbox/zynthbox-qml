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
import org.zynthian.quick 1.0 as ZynQuick

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
    signal close();

    property var noteLengths: {
        1: 32,
        2: 16,
        3: 8,
        4: 4,
        5: 2,
        6: 1
    }
    property int stepDuration: component.model ? noteLengths[component.model.noteLength] : 0
    // This is going to come back to haunt us - if we don't somehow tell the user the difference between a quantised note and one set to what happens to be the current note length... that will be an issue
    property var noteLengthNames: {
        1: "1/4 (auto)",
        2: "1/8 (auto)",
        3: "1/16 (auto)",
        4: "1/32 (auto)",
        5: "1/64 (auto)",
        6: "1/128 (auto)"
    }
    //property var noteLengthNames: {
        //1: "1/4",
        //2: "1/8",
        //3: "1/16",
        //4: "1/32",
        //5: "1/64",
        //6: "1/128"
    //}
    property string stepDurationName: component.model ? noteLengthNames[component.model.noteLength] : ""

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
    function changeAllSubnotesPitch(pitchChange) {
        var oldNote = component.model.getNote(component.row, component.column);
        var newSubnotes = [];
        for (var i = 0; i < oldNote.subnotes.length; ++i) {
            var oldSubnote = oldNote.subnotes[i];
            newSubnotes.push(ZynQuick.PlayGridManager.getNote(Math.min(Math.max(oldSubnote.midiNote + pitchChange, 0), 127), oldSubnote.midiChannel));
        }
        component.model.setNote(component.row, component.column, ZynQuick.PlayGridManager.getCompoundNote(newSubnotes));

        // Now refetch the note we're displaying
        var theColumn = component.column;
        component.column = -1;
        component.column = theColumn;
    }
    function changeSubnotePitch(subnoteIndex, pitchChange) {
        // First get the old data out
        var subnote = component.note.subnotes[subnoteIndex];
        var metadata = component.model.subnoteMetadata(component.row, component.column, subnoteIndex, "");
        component.model.removeSubnote(component.row, component.column, subnoteIndex);
        // Now insert the replacement note and set the metadata again
        subnote = ZynQuick.PlayGridManager.getNote(Math.min(Math.max(subnote.midiNote + pitchChange, 0), 127), subnote.midiChannel)
        var subnotePosition = component.model.insertSubnoteSorted(component.row, component.column, subnote);
        for (var key in metadata) {
            component.model.setSubnoteMetadata(component.row, component.column, subnotePosition, key, metadata[key]);
        }

        // Finally, refetch the note we're displaying
        var theColumn = component.column;
        component.column = -1;
        component.column = theColumn;
        component.changeSubnote(subnotePosition);
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
        QQC2.Label {
            id: noteHeaderLabel
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
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
            Zynthian.KnobIndicator {
                anchors {
                    left: parent.horizontalCenter
                    leftMargin: -(parent.paintedWidth / 2) - width - Kirigami.Units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }
                height: parent.height / 2
                width: height
                visible: component.currentSubNote === -1
                knobId: 1
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            text: "Length"
            Zynthian.KnobIndicator {
                anchors {
                    left: parent.horizontalCenter
                    leftMargin: -(parent.paintedWidth / 2) - width - Kirigami.Units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }
                height: parent.height / 2
                width: height
                visible: component.currentSubNote === -1
                knobId: 2
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            text: "Position"
            Zynthian.KnobIndicator {
                anchors {
                    left: parent.horizontalCenter
                    leftMargin: -(parent.paintedWidth / 2) - width - Kirigami.Units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }
                height: parent.height / 2
                width: height
                visible: component.currentSubNote === -1
                knobId: 3
            }
        }
    }
    Repeater {
        model: component.note ? component.note.subnotes : 0
        RowLayout {
            id: subnoteDelegate
            // Inverting the sort order, so the entries are shown bottom-to-top
            property int subnoteIndex: component.note.subnotes.length - 1 - model.index
            property QtObject subnote: component.note.subnotes[subnoteIndex]
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            Item {
                id: noteDelegate
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                MultiPointTouchArea {
                    anchors.fill: parent
                    touchPoints: [
                        TouchPoint {
                            onPressedChanged: {
                                if (!pressed && x > -1 && y > -1 && x < noteDelegate.width && y < noteDelegate.height) {
                                    component.changeSubnote(subnoteDelegate.subnoteIndex);
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
                    visible: subnoteDelegate.subnoteIndex === component.currentSubNote
                }
                Rectangle {
                    anchors {
                        top: parent.top
                        right: parent.right
                        rightMargin: 1
                        bottom: parent.bottom
                        margins: 1
                    }
                    width: height
                    radius: height / 2
                    color: subnoteDelegate.subnote ? zynthian.theme_chooser.noteColors[subnoteDelegate.subnote.midiNote] : "transparent"
                }
                QQC2.Label {
                    id: subnoteDelegateLabel
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    font.bold: true
                    text: subnoteDelegate.subnote ? subnoteDelegate.subnote.name + (subnoteDelegate.subnote.octave - 1) : ""
                }
                Zynthian.PlayGridButton {
                    anchors {
                        top: parent.top
                        left: parent.left
                        leftMargin: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                        bottom: parent.bottom
                        margins: 1
                    }
                    width: height
                    icon.name: "edit-delete"
                    visible: subnoteDelegate.subnoteIndex === component.currentSubNote
                    onClicked: {
                        // This is a workaround for "this element disappeared for some reason"
                        var rootComponent = component;
                        if (rootComponent.currentSubNote >= subnoteDelegate.subnoteIndex) {
                            rootComponent.changeSubnote(rootComponent.currentSubNote - 1);
                        }
                        rootComponent.model.removeSubnote(rootComponent.row, rootComponent.column, subnoteDelegate.subnoteIndex);
                        // Now refetch the note we're displaying
                        var theColumn = rootComponent.column;
                        rootComponent.column = -1;
                        rootComponent.column = theColumn;
                        if (rootComponent.note.subnotes.count === 0) {
                            rootComponent.close();
                        }
                    }
                }
                Zynthian.PlayGridButton {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.horizontalCenter
                        leftMargin: height / 2
                        margins: 1
                    }
                    width: height
                    text: "+"
                    visible: subnoteDelegate.subnoteIndex === component.currentSubNote && subnoteDelegate.subnote.midiNote < 127
                    onClicked: {
                        component.changeSubnotePitch(subnoteDelegate.subnoteIndex, 1);
                    }
                }
                Zynthian.PlayGridButton {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.horizontalCenter
                        rightMargin: height / 2
                        margins: 1
                    }
                    width: height
                    text: "-"
                    visible: subnoteDelegate.subnoteIndex === component.currentSubNote && subnoteDelegate.subnote.midiNote > 0
                    onClicked: {
                        component.changeSubnotePitch(subnoteDelegate.subnoteIndex, -1);
                    }
                }
            }
            StepSettingsParamDelegate {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                model: component.model; row: component.row; column: component.column;
                paramIndex: subnoteDelegate.subnoteIndex
                paramName: "velocity"
                paramDefaultString: "64"
                paramValueSuffix: ""
                paramDefault: 64
                paramMin: 0
                paramMax: 127
                scrollWidth: 128
                knobId: 1
                currentlySelected: subnoteDelegate.subnoteIndex === component.currentSubNote
            }
            StepSettingsParamDelegate {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                model: component.model; row: component.row; column: component.column;
                paramIndex: subnoteDelegate.subnoteIndex
                paramName: "duration"
                paramDefaultString: component.stepDurationName
                paramValueSuffix: "/128"
                paramDefault: undefined
                paramInterpretedDefault: component.stepDuration
                paramMin: 0
                paramMax: 1024
                scrollWidth: 128
                paramList: [0, 1, 2, 4, 8, 16, 32, 64, 128, 256, /*384,*/ 512, /*640, 768, 896,*/ 1024]
                paramNames: {
                    0: component.stepDurationName,
                    1: "1/128",
                    2: "1/64",
                    4: "1/32",
                    8: "1/16",
                    16: "1/8",
                    32: "1/4",
                    64: "1/2",
                    96: "3/4",
                    128: "1",
                    256: "2",
                    384: "3",
                    512: "4",
                    640: "5",
                    768: "6",
                    896: "7",
                    1024: "8"
                }
                knobId: 2
                currentlySelected: subnoteDelegate.subnoteIndex === component.currentSubNote
            }
            StepSettingsParamDelegate {
                id: delayParamDelegate
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                model: component.model; row: component.row; column: component.column;
                paramIndex: subnoteDelegate.subnoteIndex
                paramName: "delay"
                paramDefaultString: "0 (default)"
                paramValuePrefix: paramValue > 0 ? "+" : ""
                paramValueSuffix: "/128"
                paramDefault: undefined
                paramInterpretedDefault: 0
                paramMin: -component.stepDuration + 1
                paramMax: component.stepDuration - 1
                scrollWidth: component.stepDuration
                Component.onCompleted: {
                    var potentialValues = {
                        "-128": "-1",
                        "-96": "-3/4",
                        "-64": "-1/2:",
                        "-32": "-1/4",
                        "-16": "-1/8",
                        "-8": "-1/16",
                        "-4": "-1/32",
                        "-2": "-1/64",
                        "-1": "-1/128",
                        "0": "0 (default)",
                        "1": "+1/128",
                        "2": "+1/64",
                        "4": "+1/32",
                        "8": "+1/16",
                        "16": "+1/8",
                        "32": "+1/4",
                        "64": "+1/2",
                        "96": "+3/4",
                        "128": "+1"
                    };
                    var values = [];
                    var names = {};
                    for (var key in potentialValues) {
                        if (potentialValues.hasOwnProperty(key) && key <= delayParamDelegate.paramMax && key >= delayParamDelegate.paramMin) {
                            values.push(key);
                            names[key] = potentialValues[key];
                        }
                    }
                    values.sort(function(a, b) { return a - b; });
                    paramList = values;
                    paramNames = names;
                }
                knobId: 3
                currentlySelected: subnoteDelegate.subnoteIndex === component.currentSubNote
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
    // TODO This is super in the wrong place, as it sets a setting for the entire pattern, which isn't even used in this dialog... but where would it go?
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
            horizontalAlignment: Text.AlignHCenter
            text: "DEFAULT"
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1/32"
            checked: component.model ? component.model.defaultNoteDuration === 4 : false
            onClicked: { component.model.defaultNoteDuration = checked ? 0 : 4; }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1/16"
            checked: component.model ? component.model.defaultNoteDuration === 8 : false
            onClicked: { component.model.defaultNoteDuration = checked ? 0 : 8; }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1/8"
            checked: component.model ? component.model.defaultNoteDuration === 16 : false
            onClicked: { component.model.defaultNoteDuration = checked ? 0 : 16; }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1/4"
            checked: component.model ? component.model.defaultNoteDuration === 32 : false
            onClicked: { component.model.defaultNoteDuration = checked ? 0 : 32; }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1/2"
            checked: component.model ? component.model.defaultNoteDuration === 64 : false
            onClicked: { component.model.defaultNoteDuration = checked ? 0 : 64; }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1"
            checked: component.model ? component.model.defaultNoteDuration === 128 : false
            onClicked: { component.model.defaultNoteDuration = checked ? 0 : 128; }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
            horizontalAlignment: Text.AlignHCenter
            text: "All Notes"
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 30
            text: "Pitch -"
            onClicked: {
                component.changeAllSubnotesPitch(-1);
            }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 30
            text: "Pitch +"
            onClicked: {
                component.changeAllSubnotesPitch(1);
            }
        }
    }
}
