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
    property int firstStep: -1
    property int lastStep: -1
    property int currentStep: -1
    property int currentSubNote: -1

    // If set to anything other than -1, this will force navigation to loop on one step instead of traveling through the steps
    property int forceStep: -1
    // If filled, the component only shows the subnotes whose note is contained in this list
    property var midiNoteFilter: []

    function cuiaCallback(cuia) {
        let result = true;
        switch(cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
            case "SWITCH_SELECT_LONG":
                component.close();
                break;
            case "NAVIGATE_LEFT":
                // page down
                if (component.currenParameterPageIndex > 0) {
                    component.currenParameterPageIndex = component.currenParameterPageIndex - 1;
                } else {
                    component.currenParameterPageIndex = component.parameterPageCount - 1;
                }
                break;
            case "NAVIGATE_RIGHT":
                // page up
                if (component.currenParameterPageIndex + 1 < component.parameterPageCount) {
                    component.currenParameterPageIndex = component.currenParameterPageIndex + 1;
                } else {
                    component.currenParameterPageIndex = 0;
                }
                break;
            case "KNOB0_UP":
                result = false;
                break;
            case "KNOB0_DOWN":
                result = false;
                break;
            case "KNOB1_UP":
                result = false;
                break;
            case "KNOB1_DOWN":
                result = false;
                break;
            case "KNOB2_UP":
                result = false;
                break;
            case "KNOB2_DOWN":
                result = false;
                break;
            case "KNOB3_UP":
                if (component.currentIndex + 1 < component.listData.length) {
                    component.currentIndex = component.currentIndex + 1;
                }
                break;
            case "KNOB3_DOWN":
                // -1 being the "nothing selected" state, we should be able to navigate back to that state
                // -using the knob as well (also since that's how the sequencer controls work)
                if (component.currentIndex > -1) {
                    component.currentIndex = component.currentIndex - 1;
                }
                break;
            default:
                break;
        }
        return result;
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
            firstStep = -1;
            lastStep = -1;
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
        // Adjust by a full octave if the mode button is held down
        let octaveAdjustment = 1;
        if (zynqtgui.modeButtonPressed) {
            octaveAdjustment = 12;
            zynqtgui.ignoreNextModeButtonPress = true;
        }
        // Now insert the replacement note and set the metadata again
        subnote = Zynthbox.PlayGridManager.getNote(Math.min(Math.max(subnote.midiNote + (octaveAdjustment * pitchChange), 0), 127), subnote.midiChannel);
        var subnotePosition = component.patternModel.insertSubnoteSorted(row, column, subnote);
        for (var key in metadata) {
            component.patternModel.setSubnoteMetadata(row, column, subnotePosition, key, metadata[key]);
        }
        component.selectBarStepAndSubnote(row, column, subnotePosition);
        component.refreshSubnote(row, column, subnotePosition);
    }
    /**
     * The data the dialog list operates on, in the form of a bunch of objects with the structure
     * described below. The update function will fill this list, reset the current index to -1, and
     * while filling will ensure that the note filter and the bar and step limiters are applied.
     * {
     *  barIndex: integer,
     *  stepIndex: integer,
     *  subnoteIndex: integer,
     *  firstInStep: bool,
     *  subnote: Note object
     * }
     */
    property alias listData: _private.listData
    property int currentIndex: -1
    property int firstDisplayedIndex: 0
    onMidiNoteFilterChanged: updateListData()
    onFirstBarChanged: updateListData()
    onLastBarChanged: updateListData()
    onFirstStepChanged: updateListData()
    onLastStepChanged: updateListData()
    onPatternModelChanged: updateListData()
    onRefreshSubnote: updateListData(false)
    function updateListData(resetViewPosition = true) {
        if (listDataUpdater.resetViewPosition == false) {
            listDataUpdater.resetViewPosition = resetViewPosition;
        }
        listDataUpdater.restart();
    }
    onCurrentIndexChanged: {
        if (currentIndex === -1) {
            if (component.firstStep > -1 && component.firstStep === component.lastStep) {
                // If we're showing a single step, when deselecting, just re-select the step itself, but not a subnote
                component.changeStepAndSubnote(component.firstStep, -1);
            } else {
                // If we're showing more than one step, deselect everything
                component.changeStepAndSubnote(-1, -1);
            }
        } else {
            let subnoteData = listData[component.currentIndex];
            component.changeStepAndSubnote((subnoteData["barIndex"] * component.patternModel.width) + subnoteData["stepIndex"], subnoteData["subnoteIndex"]);
            if (component.listData.length > 7) {
                if (component.currentIndex < 3) {
                    component.firstDisplayedIndex = 0;
                } else if (component.currentIndex > component.listData.length - 4) {
                    component.firstDisplayedIndex = component.listData.length - 7;
                } else {
                    component.firstDisplayedIndex = component.currentIndex - 3;
                }
            } else {
                component.firstDisplayedIndex = 0;
            }
        }
    }
    function selectBarStepAndSubnote(barIndex, stepIndex, subnoteIndex) {
        listDataUpdater.barStepAndSubnoteToSelect = { "barIndex": barIndex, "stepIndex": stepIndex, "subnoteIndex": subnoteIndex }
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
                                component.currentIndex = -1;
                            }
                        }
                    }
                ]
            }
            QtObject {
                id: _private
                property var listData: []
            }
            Timer {
                id: listDataUpdater
                interval: 1; repeat: false; running: false;
                property bool resetViewPosition: false
                property var barStepAndSubnoteToSelect: { "barIndex": -1, "stepIndex": -1, "subnoteIndex": -1 }
                onTriggered: {
                    let newListData = [];
                    if (component.patternModel) {
                        let firstStep = (component.firstStep == -1 ? 0 : component.firstStep);
                        let lastStepAndOne = (component.lastStep == -1 ? component.patternModel.width : component.lastStep + 1);
                        for (let barIndex = component.firstBar; barIndex < component.lastBar + 1; ++barIndex) {
                            for (let stepIndex = firstStep; stepIndex < lastStepAndOne; ++stepIndex) {
                                let stepNote = component.patternModel.getNote(barIndex, stepIndex);
                                let firstInStep = true;
                                // The display order for notes wants to be higher to lower, but the subnotes
                                // list is ordered lower to higher, so run through them backwards
                                if (stepNote) {
                                    for (let subnoteIndex = stepNote.subnotes.length - 1; -1 < subnoteIndex; --subnoteIndex) {
                                        let subnote = stepNote.subnotes[subnoteIndex];
                                        if (component.midiNoteFilter.length === 0 || component.midiNoteFilter.indexOf(subnote.midiNote) > -1) {
                                            newListData.push(
                                                {
                                                    "barIndex": barIndex,
                                                    "stepIndex": stepIndex,
                                                    "subnoteIndex": subnoteIndex,
                                                    "firstInStep": firstInStep,
                                                    "subnote": subnote
                                                }
                                            );
                                            firstInStep = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if (resetViewPosition) {
                        component.currentIndex = -1;
                        listDataUpdater.resetViewPosition = false;
                    }
                    _private.listData = newListData;
                    if (barStepAndSubnoteToSelect["subnoteIndex"] > -1) {
                        for (let listDataIndex = 0; listDataIndex < _private.listData.length; ++listDataIndex) {
                            let listDataEntry = _private.listData[listDataIndex];
                            if (listDataEntry["barIndex"] == barStepAndSubnoteToSelect["barIndex"] && listDataEntry["stepIndex"] == barStepAndSubnoteToSelect["stepIndex"] && listDataEntry["subnoteIndex"] == barStepAndSubnoteToSelect["subnoteIndex"]) {
                                component.currentIndex = listDataIndex;
                                break;
                            }
                        }
                        barStepAndSubnoteToSelect = { "barIndex": -1, "stepIndex": -1, "subnoteIndex": -1 };
                    }
                }
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
                    ? "Next Step"
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
    Repeater {
        // Arbitrary number, because 7 elements fits nicely, and gives us three on either side
        // of a central point, which just looks kind of nice when there's a bunch of elements
        model: 7
        delegate: ColumnLayout {
            id: subnoteDelegate
            Layout.fillWidth: true
            property int thisDataIndex: component.firstDisplayedIndex + index
            property var subnoteData: -1 < thisDataIndex && thisDataIndex < component.listData.length ? component.listData[thisDataIndex] : null
            property int barIndex: subnoteData === null ? -1 : subnoteData["barIndex"]
            property int stepIndex: subnoteData === null ? -1 : subnoteData["stepIndex"]
            property int subnoteIndex: subnoteData === null ? -1 : subnoteData["subnoteIndex"]
            property int firstInStep: subnoteData === null ? false : subnoteData["firstInStep"]
            property QtObject subnote: subnoteData === null ? null : subnoteData["subnote"]
            property bool isCurrent: component.currentIndex === thisDataIndex
            opacity: subnote === null ? 0 : 1
            spacing: 0
            Item {
                Layout.fillWidth: true
                Layout.minimumHeight: 1
                Layout.maximumHeight: 1
                z: 9999 // Put the label on top of all the things
                opacity: subnoteDelegate.thisDataIndex === 0 || model.index === 0 || subnoteDelegate.firstInStep ? 1 : 0
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
                    text: (subnoteDelegate.stepIndex + 1)
                }
            }
            RowLayout {
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
                                        component.currentIndex = subnoteDelegate.thisDataIndex;
                                    }
                                }
                                // TODO When swiping up and down, change currentIndex accordingly (since we're no longer in a scrollview, we have to be our own scrollview, but we can also be Kind Of Smartypants about it)
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
                                rootComponent.patternModel.removeSubnote(subnoteDelegate.barIndex, subnoteDelegate.stepIndex, subnoteDelegate.subnoteIndex);
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
                            text: subnoteDelegate.subnote ? /*(subnoteDelegate.localBarIndex * component.patternModel.width + subnoteDelegate.stepIndex + 1) + ":" + */subnoteDelegate.subnote.name + (subnoteDelegate.subnote.octave - 1) : ""
                        }
                        Zynthian.PlayGridButton {
                            Layout.fillWidth: false
                            Layout.minimumWidth: height * 0.8
                            Layout.maximumWidth: height * 0.8
                            text: "-"
                            // visible: component.midiNoteFilter.length === 0 && subnoteDelegate.subnoteIndex === component.currentSubNote && subnoteDelegate.subnote.midiNote > 0
                            enabled: subnoteDelegate.subnote ? subnoteDelegate.subnote.midiNote > 0 : false
                            onClicked: {
                                component.changeSubnotePitch(subnoteDelegate.barIndex, subnoteDelegate.stepIndex, subnoteDelegate.subnoteIndex, -1);
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
                                component.changeSubnotePitch(subnoteDelegate.barIndex, subnoteDelegate.stepIndex, subnoteDelegate.subnoteIndex, 1);
                            }
                        }
                        Zynthian.PlayGridButton {
                            Layout.fillWidth: false
                            Layout.minimumWidth: height * 0.8
                            Layout.maximumWidth: height * 0.8
                            icon.name: "media-playback-start-symbolic"
                            onClicked: {
                                var velocity = component.patternModel.subnoteMetadata(subnoteDelegate.barIndex, subnoteDelegate.stepIndex, subnoteDelegate.subnoteIndex, "velocity");
                                if (typeof(velocity) === "undefined") {
                                    velocity = 64;
                                }
                                var duration = component.patternModel.subnoteMetadata(subnoteDelegate.barIndex, subnoteDelegate.stepIndex, subnoteDelegate.subnoteIndex, "duration");
                                if (typeof(duration) === "undefined") {
                                    duration = component.stepDuration;
                                }
                                var delay = component.patternModel.subnoteMetadata(subnoteDelegate.barIndex, subnoteDelegate.stepIndex, subnoteDelegate.subnoteIndex, "delay");
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
                    model: component.patternModel; row: subnoteDelegate.barIndex; column: subnoteDelegate.stepIndex;
                    paramIndex: subnoteDelegate.subnoteIndex
                    paramName: "velocity"
                    paramDefaultString: "64"
                    paramValueSuffix: ""
                    paramDefault: 64
                    paramMin: 0
                    paramMax: 127
                    scrollWidth: 128
                    knobId: 1
                    currentlySelected: subnoteDelegate.isCurrent
                }
                StepSettingsParamDelegate {
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                    visible: component.currenParameterPageIndex === 0
                    model: component.patternModel; row: subnoteDelegate.barIndex; column: subnoteDelegate.stepIndex;
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
                    currentlySelected: subnoteDelegate.isCurrent
                }
                StepSettingsParamDelegate {
                    id: delayParamDelegate
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                    visible: component.currenParameterPageIndex === 0
                    model: component.patternModel; row: subnoteDelegate.barIndex; column: subnoteDelegate.stepIndex;
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
                    currentlySelected: subnoteDelegate.isCurrent
                }
                // END Page 1 (Velocity, Length, Position)
                // BEGIN Page 2 (Probability, ???, ???)
                StepSettingsParamDelegate {
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                    visible: component.currenParameterPageIndex === 1
                    model: component.patternModel; row: subnoteDelegate.barIndex; column: subnoteDelegate.stepIndex;
                    paramIndex: subnoteDelegate.subnoteIndex
                    paramName: "probability"
                    paramDefaultString: "100%"
                    paramValueSuffix: "%"
                    paramDefault: 100
                    paramMin: 0
                    paramMax: 100
                    scrollWidth: 101
                    knobId: 1
                    currentlySelected: subnoteDelegate.isCurrent
                }
                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                    visible: component.currenParameterPageIndex === 1
                }
                StepSettingsParamDelegate {
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                    visible: component.currenParameterPageIndex === 1
                    model: component.patternModel; row: subnoteDelegate.barIndex; column: subnoteDelegate.stepIndex;
                    paramIndex: subnoteDelegate.subnoteIndex
                    paramName: "next-step"
                    paramDefaultString: "Next"
                    paramValueSuffix: ""
                    paramDefault: 0
                    paramMin: 0
                    paramMax: 128
                    scrollWidth: 128
                    paramList: [0, 1, 17, 33, 49, 65, 81, 97, 113]
                    paramNames: {
                        0: "Split Step, Overlap",
                        1: "Bar 1",
                        17: "Bar 2",
                        33: "Bar 3",
                        49: "Bar 4",
                        65: "Bar 5",
                        81: "Bar 6",
                        97: "Bar 7",
                        113: "Bar 8",
                    }
                    knobId: 3
                    currentlySelected: subnoteDelegate.isCurrent
                }
                // END Page 2 (Probability, ???, Swing)
                // BEGIN Page 3 (Ratchet Style, Ratchet Count, Ratchet Probability)
                StepSettingsParamDelegate {
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                    visible: component.currenParameterPageIndex === 2
                    model: component.patternModel; row: subnoteDelegate.barIndex; column: subnoteDelegate.stepIndex;
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
                    currentlySelected: subnoteDelegate.isCurrent
                }
                StepSettingsParamDelegate {
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                    visible: component.currenParameterPageIndex === 2
                    model: component.patternModel; row: subnoteDelegate.barIndex; column: subnoteDelegate.stepIndex;
                    paramIndex: subnoteDelegate.subnoteIndex
                    paramName: "ratchet-count"
                    paramDefaultString: "0"
                    paramValueSuffix: ""
                    paramDefault: 0
                    paramMin: 0
                    paramMax: 12
                    scrollWidth: 13
                    knobId: 2
                    currentlySelected: subnoteDelegate.isCurrent
                }
                StepSettingsParamDelegate {
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                    visible: component.currenParameterPageIndex === 2
                    model: component.patternModel; row: subnoteDelegate.barIndex; column: subnoteDelegate.stepIndex;
                    paramIndex: subnoteDelegate.subnoteIndex
                    paramName: "ratchet-probability"
                    paramDefaultString: "100%"
                    paramValueSuffix: "%"
                    paramDefault: 100
                    paramMin: 0
                    paramMax: 100
                    scrollWidth: 101
                    knobId: 3
                    currentlySelected: subnoteDelegate.isCurrent
                }
                // END Page 3 (Ratchet Style, Ratchet Count, Ratchet Probability)
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

