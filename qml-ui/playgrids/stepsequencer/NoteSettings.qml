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
import io.zynthbox.components 1.0 as Zynthbox

ColumnLayout {
    id: component

    property QtObject patternModel: null
    property int firstBar: -1
    property int lastBar: -1
    property int currentStep: -1
    property int currentSubNote: -1

    // If set to anything other than -1, this will force navigation to loop on one step instead of traveling through the steps
    property int forceStep: -1
    // If filled, the component only shows the subnotes whose note is contained in this list
    property var midiNoteFilter: []

    /**
     * \brief Get an array with all bars with steps with visible subnotes, with all indices of those subnotes as a subarray
     * The form of the array is arrayVariable[barIndex][stepIndex][subNoteIndex];
     */
    function visibleStepIndices() {
        var steps = [];
        for (var barIndex = 0; barIndex < patternRepeater.count; ++barIndex) {
            var barItem = patternRepeater.itemAt(barIndex);
            var barArray = [];
            for (var stepIndex = 0; stepIndex < barItem.count; ++stepIndex) {
                var stepItem = barItem.itemAt(stepIndex);
                var stepArray = [];
                for(var subNoteIndex = 0; subNoteIndex < stepItem.count; ++subNoteIndex) {
                    var subNoteItem = stepItem.itemAt(subNoteIndex);
                    if (subNoteItem.visible) {
                        stepArray.push(subNoteItem.subNoteIndex);
                    }
                }
                if (stepArray.length > 0) {
                    barArray[stepItem.stepIndex] = stepArray;
                }
            }
            if (barArray.length > 0) {
                steps[barItem.barIndex] = barArray;
            }
        }
        return steps;
    }

    signal changeStep(int newStep)
    onChangeStep: {
        if (newStep !== component.currentStep) {
            component.currentStep = newStep;
            component.changeSubnote(-1);
        }
    }
    signal changeSubnote(int newSubNote);
    onChangeSubnote: {
        if (component.currentSubNote !== newSubNote) {
            component.currentSubNote = newSubNote;
        }
    }
    function changeStepAndSubnote(newStep, newSubNote) {
        component.changeStep(newStep);
        component.changeSubnote(newSubNote);
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
    property int stepDuration: component.patternModel ? noteLengths[component.patternModel.noteLength] : 0
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
    property string stepDurationName: component.patternModel ? noteLengthNames[component.patternModel.noteLength] : ""

    readonly property int parameterPageCount: 3
    property int currenParameterPageIndex: 0

    onVisibleChanged: {
        if (!visible) {
            patternModel = null;
            firstBar = -1;
            lastBar = -1;
        }
    }
/*
    function setDuration(duration, isDefault) {
        if (component.currentStep > -1) {
            if (component.currentSubNote > -1) {
                // We have a specific one selected
            } else {
                // Work on all the subnotes on the current step
            }
        } else {
            // Work on all subnotes in all the steps in the displayed bars
        }

        if (component.currentSubNote === -1) {
            if (note) {
                for (var subnoteIndex = 0; subnoteIndex < note.subnotes.length; ++subnoteIndex) {
                    component.patternModel.setSubnoteMetadata(component.row, component.column, subnoteIndex, "duration", isDefault ? 0 : duration);
                }
            }
        } else {
            component.patternModel.setSubnoteMetadata(component.row, component.column, component.currentSubNote, "duration", isDefault ? 0 : duration);
        }
    }*/

    signal refreshStep(int row, int column);
    signal refreshSubnote(int row, int column, int subnoteIndex);
    function changeAllSubnotesPitch(pitchChange) {
        for (var row = component.firstBar; row < component.lastBar + 1; ++row) {
            for (var column = 0; column < component.patternModel.width; ++column) {
                var oldNote = component.patternModel.getNote(row, column);
                if (oldNote) {
                    var newSubnotes = [];
                    for (var subnoteIndex = 0; subnoteIndex < oldNote.subnotes.length; ++subnoteIndex) {
                        var oldSubnote = oldNote.subnotes[subnoteIndex];
                        newSubnotes.push(Zynthbox.PlayGridManager.getNote(Math.min(Math.max(oldSubnote.midiNote + pitchChange, 0), 127), oldSubnote.midiChannel));
                    }
                    component.patternModel.setNote(row, column, Zynthbox.PlayGridManager.getCompoundNote(newSubnotes));
                    for (var subnoteIndex = 0; subnoteIndex < newSubnotes.length; ++subnoteIndex) {
                        component.refreshSubnote(row, column, subnoteIndex);
                    }
                }
            }
        }
        // var patternModel = component.patternModel;
        // component.patternModel = null;
        // component.patternModel = patternModel;
    }
    function changeSubnotePitch(row, column, subnoteIndex, pitchChange) {
        // First get the old data out
        var oldNote = component.patternModel.getNote(row, column);
        var subnote = oldNote.subnotes[subnoteIndex];
        var metadata = component.patternModel.subnoteMetadata(row, column, subnoteIndex, "");
        component.patternModel.removeSubnote(row, column, subnoteIndex);
        // Now insert the replacement note and set the metadata again
        subnote = Zynthbox.PlayGridManager.getNote(Math.min(Math.max(subnote.midiNote + pitchChange, 0), 127), subnote.midiChannel)
        var subnotePosition = component.patternModel.insertSubnoteSorted(row, column, subnote);
        for (var key in metadata) {
            component.patternModel.setSubnoteMetadata(row, column, subnotePosition, key, metadata[key]);
        }
        component.refreshSubnote(row, column, subnotePosition);
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
                                component.changeStepAndSubnote(-1, -1);
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
            text: component.currenParameterPageIndex === 0
                ? "Velocity"
                : component.currenParameterPageIndex === 1
                    ? "Probability"
                    : "Ratchet Style"
            Zynthian.KnobIndicator {
                anchors {
                    left: parent.horizontalCenter
                    leftMargin: -(parent.paintedWidth / 2) - width - Kirigami.Units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }
                height: parent.height / 2
                width: height
                visible: component.currentSubNote === -1
                knobId: 0
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            text: component.currenParameterPageIndex === 0
                ? "Length"
                : component.currenParameterPageIndex === 1
                    ? ""
                    : "Ratchet Count"
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
            text: component.currenParameterPageIndex === 0
                ? "Position"
                : component.currenParameterPageIndex === 1
                    ? ""
                    : "Ratchet Probability"
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
            Zynthian.PlayGridButton {
                anchors {
                    top: parent.top
                    right: parent.right
                    bottom: parent.bottom
                }
                width: height
                text: qsTr("%1/%2").arg(component.currenParameterPageIndex + 1).arg(component.parameterPageCount)
                onClicked: {
                    if (component.currenParameterPageIndex + 1 < component.parameterPageCount) {
                        component.currenParameterPageIndex = component.currenParameterPageIndex + 1;
                    } else {
                        component.currenParameterPageIndex = 0;
                    }
                }
            }
        }
    }
    QQC2.ScrollView {
        id: contentScrollView
        Layout.preferredHeight: Kirigami.Units.gridUnit * 15
        Layout.fillWidth: true
        Layout.fillHeight: true
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
        QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AlwaysOn
        contentWidth: width
        clip: true
        ColumnLayout {
            width: contentScrollView.contentWidth
            Repeater {
                id: patternRepeater;
                property int barCount: component.lastBar - component.firstBar + 1
                model: component.patternModel ? patternRepeater.barCount : 0
                Repeater {
                    id: barDelegate
                    model: component.patternModel.width
                    // Inverting the sort order, so the entries are shown bottom-to-top
                    property int localBarIndex: patternRepeater.barCount - index - 1
                    property int barIndex: localBarIndex + component.firstBar
                    ColumnLayout {
                        id: stepDelegate
                        property int stepIndex: model.index
                        property bool updateForcery: true
                        property QtObject note: updateForcery ? component.patternModel.getNote(barDelegate.barIndex, stepDelegate.stepIndex) : null
                        visible: note && note.subnotes.length > 0
                        Layout.fillWidth: true
                        spacing: 0
                        Connections {
                            target: component
                            onRefreshStep: {
                                if (row === barDelegate.barIndex && column === stepDelegate.stepIndex) {
                                    stepDelegate.updateForcery = false;
                                    stepDelegate.updateForcery = true;
                                }
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.minimumHeight: 1
                            Layout.maximumHeight: 1
                            z: 9999 // Put the label on top of all the things
                            visible: stepDelegateRepeater.hasVisibleNotes
                            Rectangle {
                                anchors {
                                    bottomMargin: 2
                                    bottom: parent.top
                                    left: parent.left
                                    right: parent.right
                                }
                                height: 1
                                color: Kirigami.Theme.textColor
                            }
                            QQC2.Label {
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                }
                                width: Kirigami.Units.largeSpacing
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: Kirigami.Units.gridUnit * 0.7
                                text: (stepDelegate.stepIndex + 1)
                            }
                        }
                        Repeater {
                            id: stepDelegateRepeater
                            model: stepDelegate.note ? stepDelegate.note.subnotes.length : 0
                            property bool hasVisibleNotes: false
                            RowLayout {
                                id: subnoteDelegate
                                // Inverting the sort order, so the entries are shown bottom-to-top
                                property int subnoteIndex: stepDelegate.note.subnotes.length - 1 - index
                                property bool updateForcery: true
                                property QtObject note: updateForcery ? component.patternModel.getNote(barDelegate.barIndex, stepDelegate.stepIndex) : null
                                property QtObject subnote: subnoteDelegate.note ? subnoteDelegate.note.subnotes[subnoteIndex] : null
                                property bool isCurrent: component.currentStep === (barDelegate.barIndex * component.patternModel.width) + stepDelegate.stepIndex && (component.currentSubNote === -1 || subnoteDelegate.subnoteIndex === component.currentSubNote)
                                visible: component.midiNoteFilter.length === 0 || component.midiNoteFilter.indexOf(subnote.midiNote) > -1
                                onVisibleChanged: {
                                    if (visible) {
                                        stepDelegateRepeater.hasVisibleNotes = true;
                                    }
                                }
                                Layout.fillWidth: true
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                Connections {
                                    target: component
                                    onRefreshSubnote: {
                                        if (row === barDelegate.barIndex && column === stepDelegate.stepIndex && subnoteIndex === subnoteDelegate.subnoteIndex) {
                                            subnoteDelegate.updateForcery = false;
                                            subnoteDelegate.updateForcery = true;
                                        }
                                    }
                                }
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
                                                        component.changeStepAndSubnote((barDelegate.barIndex * component.patternModel.width) + stepDelegate.stepIndex, subnoteDelegate.subnoteIndex);
                                                    }
                                                }
                                            }
                                        ]
                                    }
                                    RowLayout {
                                        anchors {
                                            fill: parent
                                            margins: 1
                                        }
                                        Rectangle {
                                            Layout.fillHeight: true
                                            Layout.minimumWidth: Kirigami.Units.largeSpacing
                                            Layout.maximumWidth: Kirigami.Units.largeSpacing
                                            color: subnoteDelegate.isCurrent ? Kirigami.Theme.highlightColor : "transparent"
                                        }
                                        Zynthian.PlayGridButton {
                                            Layout.fillWidth: false
                                            Layout.minimumWidth: height * 0.8
                                            Layout.maximumWidth: height * 0.8
                                            icon.name: "edit-delete"
                                            onClicked: {
                                                // This is a workaround for "this element disappeared for some reason"
                                                var rootComponent = component;
                                                if (rootComponent.currentSubNote >= subnoteDelegate.subnoteIndex) {
                                                    rootComponent.changeSubnote(rootComponent.currentSubNote - 1);
                                                }
                                                rootComponent.patternModel.removeSubnote(barDelegate.barIndex, stepDelegate.stepIndex, subnoteDelegate.subnoteIndex);
                                                // Now refetch the note we're displaying
                                                var theColumn = rootComponent.column;
                                                rootComponent.column = -1;
                                                rootComponent.column = theColumn;
                                                //if (rootComponent.note.subnotes.count === 0) {
                                                    //rootComponent.close();
                                                //}
                                            }
                                        }
                                        Rectangle {
                                            Layout.fillHeight: true
                                            Layout.minimumWidth: height
                                            Layout.maximumWidth: height
                                            radius: height / 2
                                            color: subnoteDelegate.subnote ? zynqtgui.theme_chooser.noteColors[subnoteDelegate.subnote.midiNote] : "transparent"
                                        }
                                        QQC2.Label {
                                            id: subnoteDelegateLabel
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            // anchors.fill: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            font.bold: true
                                            text: subnoteDelegate.subnote ? /*(barDelegate.localBarIndex * component.patternModel.width + stepDelegate.stepIndex + 1) + ":" + */subnoteDelegate.subnote.name + (subnoteDelegate.subnote.octave - 1) : ""
                                        }
                                        Zynthian.PlayGridButton {
                                            Layout.fillWidth: false
                                            Layout.minimumWidth: height * 0.8
                                            Layout.maximumWidth: height * 0.8
                                            text: "-"
                                            // visible: component.midiNoteFilter.length === 0 && subnoteDelegate.subnoteIndex === component.currentSubNote && subnoteDelegate.subnote.midiNote > 0
                                            enabled: subnoteDelegate.subnote ? subnoteDelegate.subnote.midiNote > 0 : false
                                            onClicked: {
                                                component.changeSubnotePitch(barDelegate.barIndex, stepDelegate.stepIndex, subnoteDelegate.subnoteIndex, -1);
                                            }
                                        }
                                        Zynthian.PlayGridButton {
                                            Layout.fillWidth: false
                                            Layout.minimumWidth: height * 0.8
                                            Layout.maximumWidth: height * 0.8
                                            text: "+"
                                            // visible: component.midiNoteFilter.length === 0 && subnoteDelegate.subnoteIndex === component.currentSubNote && subnoteDelegate.subnote.midiNote < 127
                                            enabled: subnoteDelegate.subnote ? subnoteDelegate.subnote.midiNote < 127 : false
                                            onClicked: {
                                                component.changeSubnotePitch(barDelegate.barIndex, stepDelegate.stepIndex, subnoteDelegate.subnoteIndex, 1);
                                            }
                                        }
                                        Zynthian.PlayGridButton {
                                            Layout.fillWidth: false
                                            Layout.minimumWidth: height * 0.8
                                            Layout.maximumWidth: height * 0.8
                                            icon.name: "media-playback-start-symbolic"
                                            onClicked: {
                                                var velocity = component.patternModel.subnoteMetadata(barDelegate.barIndex, stepDelegate.stepIndex, subnoteDelegate.subnoteIndex, "velocity");
                                                if (typeof(velocity) === "undefined") {
                                                    velocity = 64;
                                                }
                                                var duration = component.patternModel.subnoteMetadata(barDelegate.barIndex, stepDelegate.stepIndex, subnoteDelegate.subnoteIndex, "duration");
                                                if (typeof(duration) === "undefined") {
                                                    duration = component.stepDuration;
                                                }
                                                var delay = component.patternModel.subnoteMetadata(barDelegate.barIndex, stepDelegate.stepIndex, subnoteDelegate.subnoteIndex, "delay");
                                                if (typeof(delay) === "undefined") {
                                                    delay = 0;
                                                }
                                                Zynthbox.PlayGridManager.scheduleNote(subnoteDelegate.subnote.midiNote, subnoteDelegate.subnote.midiChannel, true, velocity, duration, delay);
                                            }
                                        }
                                    }
                                }
                                // BEGIN Page 1 (Velocity, Length, Position)
                                StepSettingsParamDelegate {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                                    visible: component.currenParameterPageIndex === 0
                                    model: component.patternModel; row: barDelegate.barIndex; column: stepDelegate.stepIndex;
                                    paramIndex: subnoteDelegate.subnoteIndex
                                    paramName: "velocity"
                                    paramDefaultString: "64"
                                    paramValueSuffix: ""
                                    paramDefault: 64
                                    paramMin: 0
                                    paramMax: 127
                                    scrollWidth: 128
                                    knobId: 1
                                    currentlySelected: (barDelegate.barIndex * component.patternModel.width) + stepDelegate.stepIndex === component.currentStep && subnoteDelegate.subnoteIndex === component.currentSubNote
                                    onPressedChanged: {
                                        contentScrollView.contentItem.interactive = !pressed;
                                    }
                                }
                                StepSettingsParamDelegate {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                                    visible: component.currenParameterPageIndex === 0
                                    model: component.patternModel; row: barDelegate.barIndex; column: stepDelegate.stepIndex;
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
                                    currentlySelected: (barDelegate.barIndex * component.patternModel.width) + stepDelegate.stepIndex === component.currentStep && subnoteDelegate.subnoteIndex === component.currentSubNote
                                    onPressedChanged: {
                                        contentScrollView.contentItem.interactive = !pressed;
                                    }
                                }
                                StepSettingsParamDelegate {
                                    id: delayParamDelegate
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                                    visible: component.currenParameterPageIndex === 0
                                    model: component.patternModel; row: barDelegate.barIndex; column: stepDelegate.stepIndex;
                                    paramIndex: subnoteDelegate.subnoteIndex
                                    paramName: "delay"
                                    paramDefaultString: "0 (default)"
                                    paramValuePrefix: "+"
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
                                    currentlySelected: (barDelegate.barIndex * component.patternModel.width) + stepDelegate.stepIndex === component.currentStep && subnoteDelegate.subnoteIndex === component.currentSubNote
                                    onPressedChanged: {
                                        contentScrollView.contentItem.interactive = !pressed;
                                    }
                                }
                                // END Page 1 (Velocity, Length, Position)
                                // BEGIN Page 2 (Probability, ???, ???)
                                StepSettingsParamDelegate {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                                    visible: component.currenParameterPageIndex === 1
                                    model: component.patternModel; row: barDelegate.barIndex; column: stepDelegate.stepIndex;
                                    paramIndex: subnoteDelegate.subnoteIndex
                                    paramName: "probability"
                                    paramDefaultString: "100%"
                                    paramValueSuffix: "%"
                                    paramDefault: 100
                                    paramMin: 0
                                    paramMax: 100
                                    scrollWidth: 101
                                    knobId: 1
                                    currentlySelected: subnoteDelegate.subnoteIndex === component.currentSubNote
                                    onPressedChanged: {
                                        contentScrollView.contentItem.interactive = !pressed;
                                    }
                                }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                                    visible: component.currenParameterPageIndex === 1
                                }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                                    visible: component.currenParameterPageIndex === 1
                                }
                                // END Page 2 (Probability, ???, Swing)
                                // BEGIN Page 3 (Ratchet Style, Ratchet Count, Ratchet Probability)
                                StepSettingsParamDelegate {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                                    visible: component.currenParameterPageIndex === 2
                                    model: component.patternModel; row: barDelegate.barIndex; column: stepDelegate.stepIndex;
                                    paramIndex: subnoteDelegate.subnoteIndex
                                    paramName: "ratchet-style"
                                    paramDefaultString: "Split Step, Overlap"
                                    paramValueSuffix: ""
                                    paramDefault: 0
                                    paramMin: 0
                                    paramMax: 3
                                    scrollWidth: 4
                                    paramList: [0, 1, 2, 3]
                                    paramNames: {
                                        0: "Split Step, Overlap",
                                        1: "Split Step, Choke",
                                        2: "Split Length, Overlap",
                                        3: "Split Length, Choke",
                                    }
                                    knobId: 1
                                    currentlySelected: subnoteDelegate.subnoteIndex === component.currentSubNote
                                    onPressedChanged: {
                                        contentScrollView.contentItem.interactive = !pressed;
                                    }
                                }
                                StepSettingsParamDelegate {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                                    visible: component.currenParameterPageIndex === 2
                                    model: component.patternModel; row: barDelegate.barIndex; column: stepDelegate.stepIndex;
                                    paramIndex: subnoteDelegate.subnoteIndex
                                    paramName: "ratchet-count"
                                    paramDefaultString: "0"
                                    paramValueSuffix: ""
                                    paramDefault: 0
                                    paramMin: 0
                                    paramMax: 12
                                    scrollWidth: 13
                                    knobId: 2
                                    currentlySelected: subnoteDelegate.subnoteIndex === component.currentSubNote
                                    onPressedChanged: {
                                        contentScrollView.contentItem.interactive = !pressed;
                                    }
                                }
                                StepSettingsParamDelegate {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                                    visible: component.currenParameterPageIndex === 2
                                    model: component.patternModel; row: barDelegate.barIndex; column: stepDelegate.stepIndex;
                                    paramIndex: subnoteDelegate.subnoteIndex
                                    paramName: "ratchet-probability"
                                    paramDefaultString: "100%"
                                    paramValueSuffix: "%"
                                    paramDefault: 100
                                    paramMin: 0
                                    paramMax: 100
                                    scrollWidth: 101
                                    knobId: 3
                                    currentlySelected: subnoteDelegate.subnoteIndex === component.currentSubNote
                                    onPressedChanged: {
                                        contentScrollView.contentItem.interactive = !pressed;
                                    }
                                }
                                // END Page 3 (Ratchet Style, Ratchet Count, Ratchet Probability)
                            }
                        }
                    }
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
            checked: component.patternModel ? component.patternModel.defaultNoteDuration === 4 : false
            onClicked: { component.patternModel.defaultNoteDuration = checked ? 0 : 4; }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1/16"
            checked: component.patternModel ? component.patternModel.defaultNoteDuration === 8 : false
            onClicked: { component.patternModel.defaultNoteDuration = checked ? 0 : 8; }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1/8"
            checked: component.patternModel ? component.patternModel.defaultNoteDuration === 16 : false
            onClicked: { component.patternModel.defaultNoteDuration = checked ? 0 : 16; }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1/4"
            checked: component.patternModel ? component.patternModel.defaultNoteDuration === 32 : false
            onClicked: { component.patternModel.defaultNoteDuration = checked ? 0 : 32; }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1/2"
            checked: component.patternModel ? component.patternModel.defaultNoteDuration === 64 : false
            onClicked: { component.patternModel.defaultNoteDuration = checked ? 0 : 64; }
        }
        Zynthian.PlayGridButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            text: "1"
            checked: component.patternModel ? component.patternModel.defaultNoteDuration === 128 : false
            onClicked: { component.patternModel.defaultNoteDuration = checked ? 0 : 128; }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
        visible: component.midiNoteFilter.length === 0
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

