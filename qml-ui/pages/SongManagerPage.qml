/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Song Manager Page

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
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian

import "Sketchpad" as Sketchpad

Zynthian.ScreenPage {
    id: component
    screenId: "song_manager"
    title: qsTr("Song")
    property bool isVisible:zynqtgui.current_screen_id === "song_manager"

    property var cuiaCallback: function(cuia) {
        var returnValue = false;
        switch (cuia) {
            case "NAVIGATE_LEFT":
            case "SELECT_DOWN":
                _private.goLeft();
                returnValue = true;
                break;

            case "NAVIGATE_RIGHT":
            case "SELECT_UP":
                _private.goRight();
                returnValue = true;
                break;
            case "KNOB0_UP":
                _private.knob0Up();
                returnValue = true;
                break;
            case "KNOB0_DOWN":
                _private.knob0Down();
                returnValue = true;
                break;
            case "KNOB1_UP":
                _private.knob1Up();
                returnValue = true;
                break;
            case "KNOB1_DOWN":
                _private.knob1Down();
                returnValue = true;
                break;
            case "KNOB2_UP":
                _private.knob2Up();
                returnValue = true;
                break;
            case "KNOB2_DOWN":
                _private.knob2Down();
                returnValue = true;
                break;
            case "KNOB3_UP":
                _private.goRight();
                returnValue = true;
                break;
            case "KNOB3_DOWN":
                _private.goLeft();
                returnValue = true;
                break;
        }
        if (returnValue) {
            zynqtgui.ignoreNextModeButtonPress = true;
        }
        return returnValue;
    }
    QtObject {
        id: _private
        function goLeft() {
            if (zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex > 0) {
                zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex -= 1;
            }
        }
        function goRight() {
            if (zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex < zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count - 1) {
                zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex += 1;
            }
        }
        function knob0Up() {
            if (zynqtgui.modeButtonPressed) {
                let nextSegment = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.get_segment(zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex + 1);
                if (nextSegment != null && nextSegment.barLength > 0) {
                    for (let i = 0; i < 4; ++i) {
                        changeBeatLength(segmentDetails.selectedSegment, true);
                        changeBeatLength(nextSegment, false);
                    }
                }
            } else {
                segmentDetails.selectedSegment.barLength += 1;
            }
        }
        function knob0Down() {
            if (zynqtgui.modeButtonPressed) {
                let nextSegment = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.get_segment(zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex + 1);
                if (nextSegment != null && segmentDetails.selectedSegment.barLength > 0) {
                    for (let i = 0; i < 4; ++i) {
                        changeBeatLength(segmentDetails.selectedSegment, false);
                        changeBeatLength(nextSegment, true);
                    }
                }
            } else {
                if (segmentDetails.selectedSegment.barLength > 0) {
                    segmentDetails.selectedSegment.barLength -= 1;
                }
            }
        }
        function knob1Up() {
            if (zynqtgui.modeButtonPressed) {
                let nextSegment = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.get_segment(zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex + 1);
                if (nextSegment != null && (nextSegment.barLength > 0 || nextSegment.beatLength > 0)) {
                    changeBeatLength(segmentDetails.selectedSegment, true);
                    changeBeatLength(nextSegment, false);
                }
            } else {
                changeBeatLength(segmentDetails.selectedSegment, true);
            }
        }
        function knob1Down() {
            if (zynqtgui.modeButtonPressed) {
                let nextSegment = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.get_segment(zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex + 1);
                if (nextSegment != null && (segmentDetails.selectedSegment.barLength > 0 || segmentDetails.selectedSegment.beatLength > 0)) {
                    changeBeatLength(segmentDetails.selectedSegment, false);
                    changeBeatLength(nextSegment, true);
                }
            } else {
                changeBeatLength(segmentDetails.selectedSegment, false);
            }
        }
        function knob2Up() {
        }
        function knob2Down() {
        }
        function changeBeatLength(segment, increase=true) {
            if (increase) {
                if (segment.beatLength < 3) {
                    segment.beatLength += 1;
                } else {
                    segment.barLength += 1;
                    segment.beatLength = 0;
                }
            } else {
                if (segment.beatLength > 0) {
                    segment.beatLength -= 1;
                } else if (segment.barLength > 0) {
                    segment.barLength -= 1;
                    segment.beatLength = 3;
                }
            }
        }
    }

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Variations")
            onTriggered: {
                segmentModelPicker.open();
            }
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            text: qsTr("Export Song")
            onTriggered: {
                multichannelRecorderPopup.recordSong(zynqtgui.sketchpad.song)
            }
        }
    ]
    Zynthian.MultichannelRecorderPopup {
        id: multichannelRecorderPopup
    }
    Zynthian.SegmentModelPicker {
        id: segmentModelPicker
    }

    RowLayout {
        anchors.fill: parent
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            // BEGIN Segments navigator bar
            RowLayout {
                id: segmentsLayout
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit
                spacing: 1

                // Should show arrows is True when segment count is greater than 11 and hence needs arrows to scroll
                property bool shouldShowSegmentArrows: zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count > 11
                // Segment offset will determine what is the first segment to display when arrow keys are displayed
                property int segmentOffset: 0
                // Maximum segment offset allows the arrow keys to check if there are any more segments outside view
                property int maximumSegmentOffset: zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count - 11 + 2
                // The index of the last visible segment cell (as opposed to the segment as exists in the song's segments model)
                property int lastVisibleSegmentCellIndex: 10

                Connections {
                    target: zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel
                    enabled: component.isVisible
                    onSelectedSegmentIndexChanged: {
                        // When selectedSegmentIndex changes (i.e. being set with Big Knob), adjust visible segments so that selected segment is brought into view
                        if (zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex > (segmentsLayout.segmentOffset+7)) {
                            // console.log("selected segment is outside visible segments on the right :", zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex, segmentsLayout.segmentOffset, Math.min(segmentsLayout.maximumSegmentOffset, zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex - 7))
                            segmentsLayout.segmentOffset = Math.min(segmentsLayout.maximumSegmentOffset, zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex - 7)
                        } else if (zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex < segmentsLayout.segmentOffset) {
                            // console.log("selected segment is outside visible segments on the left :", zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex, segmentsLayout.segmentOffset, zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex)
                            segmentsLayout.segmentOffset = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex
                        }
                    }
                }
                Connections {
                    target: Zynthbox.SegmentHandler
                    onPlayheadSegmentChanged: {
                        if (Zynthbox.SyncTimer.timerRunning && -1 < Zynthbox.SegmentHandler.playheadSegment && Zynthbox.SegmentHandler.playheadSegment < zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count) {
                            zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex = Zynthbox.SegmentHandler.playheadSegment;
                        }
                    }
                }
                Repeater {
                    model: segmentsLayout.lastVisibleSegmentCellIndex + 1
                    Sketchpad.TableHeader {
                        id: segmentHeader

                        property bool startDrag: false
                        property point dragStartPosition
                        property int segmentOffsetAtDragStart

                        // Calculate current cell's segment index
                        // If arrow keys are visible, take into account that arrow keys will be visible no cells 0 and 10 respectively
                        property int thisSegmentIndex: index +
                                                        (segmentsLayout.shouldShowSegmentArrows ? segmentsLayout.segmentOffset : 0) + // Offset index if arrows are visible else 0
                                                        (segmentsLayout.shouldShowSegmentArrows ? -1 : 0) // if arrows are being displayed, display segment from 2nd slot onwards
                        // A little odd looking perhaps - we use the count changed signal here to ensure we refetch the segments when we add, remove, or otherwise change the model
                        property QtObject segment: zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count > 0
                                                    ? zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.get_segment(segmentHeader.thisSegmentIndex)
                                                    : null

                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        text: zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count > segmentsLayout.lastVisibleSegmentCellIndex + 1
                                    ? index === 0
                                        ? "◀"
                                        : index === segmentsLayout.lastVisibleSegmentCellIndex
                                            ? "▶"
                                            : segmentHeader.segment
                                                ? segmentHeader.segment.name
                                                : ""
                                    : segmentHeader.segment
                                        ? segmentHeader.segment.name
                                        : ""
                        subText: {
                            if (zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count > segmentsLayout.lastVisibleSegmentCellIndex + 1 && (index === 0 || index === segmentsLayout.lastVisibleSegmentCellIndex)) {
                                return " "
                            } else if (!segmentHeader.segment || (segmentHeader.segment.barLength === 0 && segmentHeader.segment.beatLength === 0)) {
                                return " "
                            } else {
                                return segmentHeader.segment.barLength + "." + segmentHeader.segment.beatLength
                            }
                        }

                        textSize: zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count > segmentsLayout.lastVisibleSegmentCellIndex + 1
                                    ? index === 0
                                        ? 20
                                        : index === segmentsLayout.lastVisibleSegmentCellIndex
                                            ? 20
                                            : 10
                                    : 10
                        subTextSize: 9

                        active: {
                            // If song mode is active, mark respective arrow key cell as active if there are segments outside view
                            if (segmentsLayout.shouldShowSegmentArrows && index === 0 && segmentsLayout.segmentOffset > 0) {
                                return true
                            } else if (segmentsLayout.shouldShowSegmentArrows && index === segmentsLayout.lastVisibleSegmentCellIndex && segmentsLayout.segmentOffset < segmentsLayout.maximumSegmentOffset) {
                                return true
                            }

                            // If song mode is active, mark segment cell as active if it has a segment
                            if (segmentHeader.segment != null) {
                                return true
                            } else {
                                return false
                            }
                        }

                        highlightOnFocus: false
                        highlighted: {
                            // If song mode is active and arrow keys are visible, do not highlight arrow key cells
                            if (segmentsLayout.shouldShowSegmentArrows && index === 0) {
                                return false
                            } else if (segmentsLayout.shouldShowSegmentArrows && index === segmentsLayout.lastVisibleSegmentCellIndex) {
                                return false
                            }

                            // If song mode is active and cell is not an arrow key, then highlight if selected segment is current cell
                            return segmentHeader.thisSegmentIndex === zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex
                        }

                        onPressed: {
                            if (segmentsLayout.shouldShowSegmentArrows && index === 0) {
                                // If song mode is active, clicking left arrow key cells should decrement segment offset to display out of view segments
                                segmentsLayout.segmentOffset = Math.max(0, segmentsLayout.segmentOffset - 1)
                            } else if (segmentsLayout.shouldShowSegmentArrows && index === segmentsLayout.lastVisibleSegmentCellIndex) {
                                // If song mode is active, clicking right arrow key cells should increment segment offset to display out of view segments
                                segmentsLayout.segmentOffset = Math.min(segmentsLayout.maximumSegmentOffset, segmentsLayout.segmentOffset + 1)
                            } else {
                                // If song mode is active, clicking segment cells should activate that segment
                                if (segmentHeader.segment) {
                                    zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex = segmentHeader.thisSegmentIndex
                                }
                            }
                        }
                        onPressAndHold: {
                            segmentHeader.startDrag = true
                            segmentHeader.dragStartPosition = Qt.point(pressX, pressY)
                            segmentHeader.segmentOffsetAtDragStart = segmentsLayout.segmentOffset
                        }
                        onReleased: {
                            startDrag = false
                        }
                        onPressXChanged: {
                            if (startDrag) {
                                var offset = Math.round((pressX-dragStartPosition.x)/segmentHeader.width)

                                if (offset < 0) {
                                    segmentsLayout.segmentOffset = Math.min(segmentsLayout.maximumSegmentOffset, segmentHeader.segmentOffsetAtDragStart + Math.abs(offset))
                                } else {
                                    segmentsLayout.segmentOffset = Math.max(0, segmentHeader.segmentOffsetAtDragStart - Math.abs(offset))
                                }
                            }
                        }
                    }
                }
            }
            // END Segments navigator bar
            // BEGIN Playback progress bar
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit / 2
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit / 2
                    spacing: 0
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    Repeater {
                        id: segmentsRepeater
                        property int totalDuration: zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count > 0 ? Zynthbox.PlayGridManager.syncTimer.getMultiplier() * zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.totalBeatDuration : 0
                        model: component.isVisible && totalDuration > 0 ? zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel : 0
                        delegate: Item {
                            property QtObject segment: model.segment
                            property int duration: Zynthbox.PlayGridManager.syncTimer.getMultiplier() * (segment.barLength * 4 + segment.beatLength)
                            Layout.fillWidth: true
                            Layout.preferredWidth: component.width * (duration / segmentsRepeater.totalDuration)
                            Layout.preferredHeight: Kirigami.Units.gridUnit / 2
                            Rectangle {
                                anchors {
                                    fill: parent;
                                    margins: 1
                                }
                                border {
                                    width: 1
                                    color: Kirigami.Theme.focusColor
                                }
                                color: Kirigami.Theme.backgroundColor
                                Rectangle {
                                    anchors {
                                        fill: parent
                                        margins: 2
                                    }
                                    color: Kirigami.Theme.focusColor
                                    visible: component.isVisible ? zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex === model.index : false
                                }
                            }
                        }
                    }
                }
                Item {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 1
                    Layout.maximumHeight: 1
                    visible: segmentsRepeater.totalDuration > 0
                    Item {
                        height: 1
                        width: 1
                        y: 0
                        x: component.visible && Zynthbox.SegmentHandler.duration > 0 ? parent.width * Math.min(1, Zynthbox.SegmentHandler.playhead / Zynthbox.SegmentHandler.duration) : 0
                        Rectangle {
                            anchors {
                                bottom: parent.top
                                horizontalCenter: parent.horizontalCenter
                            }
                            height: (Kirigami.Units.gridUnit / 2) + 10 // 10 because the default spacing is 5 and we want it to stick up and down by that spacing amount, why not
                            width: 3
                            Kirigami.Theme.inherit: false
                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                            color: Kirigami.Theme.textColor
                            border {
                                width: 1
                                color: Kirigami.Theme.backgroundColor
                            }
                        }
                    }
                    QQC2.Label {
                        anchors {
                            topMargin: -7 // Similar logic to our height above
                            top: parent.top
                            right: parent.right
                            left: parent.left
                        }
                        font.pixelSize: Kirigami.Units.gridUnit / 2
                        horizontalAlignment: Text.AlignRight
                        text: segmentsRepeater.totalDuration > 0 ? formatTime(Zynthbox.SyncTimer.subbeatCountToSeconds(Zynthbox.SyncTimer.bpm, segmentsRepeater.totalDuration).toFixed(2)) : ""
                        function formatTime(seconds) {
                            const hours = Math.floor(seconds / 3600);
                            const minutes = Math.floor((seconds % 3600) / 60);
                            const remainingSeconds = seconds % 60;

                            if (hours > 0) {
                                return `${hours}h${minutes}m${remainingSeconds}s`;
                            } else if (minutes > 0) {
                                return `${minutes}m${remainingSeconds}s`;
                            }
                            return `${seconds}s`;
                        }
                    }
                }
            }
            // END Playback progress bar
            // BEGIN Segment picker grid
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit
                Repeater {
                    model: 10
                    QQC2.Button {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        text: "Ch" + (index + 1)
                        onClicked: {
                            zynqtgui.sketchpad.selectedTrackId = index;
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                Repeater {
                    model: 10
                    Sketchpad.PartBarDelegate {
                        id: partBarDelegate
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit* 2
                        channel: zynqtgui.sketchpad.song.channelsModel.getChannel(model.index)
                        songMode: true
                    }
                }
            }
            // END Segment picker grid
        }
        // BEGIN Segment details column
        ColumnLayout {
            id: segmentDetails
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            property QtObject selectedSegment: zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegment
            onSelectedSegmentChanged: {
                if (segmentDetails.selectedSegment) {
                    barLengthInput.text = segmentDetails.selectedSegment.barLength;
                    beatLengthInput.text = segmentDetails.selectedSegment.beatLength;
                }
            }
            Connections {
                target: segmentDetails.selectedSegment
                onBarLengthChanged: {
                    barLengthInput.text = segmentDetails.selectedSegment.barLength
                }
                onBeatLengthChanged: {
                    beatLengthInput.text = segmentDetails.selectedSegment.beatLength
                }
            }

            Kirigami.Heading {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                horizontalAlignment: "AlignHCenter"
                verticalAlignment: "AlignVCenter"
                text: segmentDetails.selectedSegment != null ? segmentDetails.selectedSegment.name : ""
                level: 2
            }

            Kirigami.Separator {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: 2
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false

                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredWidth: Kirigami.Units.gridUnit
                    horizontalAlignment: "AlignHCenter"
                    verticalAlignment: "AlignVCenter"
                    text: qsTr("Bar")
                }
                QQC2.Label {
                    Layout.fillWidth: false
                    Layout.fillHeight: false
                    Layout.preferredWidth: Kirigami.Units.gridUnit / 10
                    horizontalAlignment: "AlignHCenter"
                    verticalAlignment: "AlignVCenter"
                    text: "/"
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredWidth: Kirigami.Units.gridUnit
                    horizontalAlignment: "AlignHCenter"
                    verticalAlignment: "AlignVCenter"
                    text: qsTr("Beat")
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                QQC2.TextField {
                    id: barLengthInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit
                    horizontalAlignment: "AlignHCenter"
                    verticalAlignment: "AlignVCenter"
                    inputMethodHints: Qt.ImhDigitsOnly
                    activeFocusOnTab: false
                    text: segmentDetails.selectedSegment != null ? segmentDetails.selectedSegment.barLength : ""
                    onTextChanged: {
                        var value = parseInt(text);
                        if (text !== "" && value != segmentDetails.selectedSegment.barLength) {
                            segmentDetails.selectedSegment.barLength = value;
                        }
                    }
                }
                QQC2.Label {
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit / 10
                    horizontalAlignment: "AlignHCenter"
                    verticalAlignment: "AlignVCenter"
                    text: "/"
                }
                QQC2.TextField {
                    id: beatLengthInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit
                    horizontalAlignment: "AlignHCenter"
                    verticalAlignment: "AlignVCenter"
                    inputMethodHints: Qt.ImhDigitsOnly
                    activeFocusOnTab: false
                    text: segmentDetails.selectedSegment != null ? segmentDetails.selectedSegment.beatLength : ""
                    onTextChanged: {
                        var value = parseInt(text);
                        if (text !== "" && value != segmentDetails.selectedSegment.barLength) {
                            segmentDetails.selectedSegment.beatLength = value;
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            QQC2.Button {
                text: qsTr("Play Segment")
                Layout.fillWidth: true
                onClicked: {
                    console.log(
                        "Playing Segment",
                        segmentDetails.selectedSegment.segmentId,
                        " : Offset",
                        segmentDetails.selectedSegment.getOffsetInBeats(),
                        ", durationInBeats",
                        (segmentDetails.selectedSegment.barLength * 4 + segmentDetails.selectedSegment.beatLength),
                        ", durationInTicks",
                        Zynthbox.PlayGridManager.syncTimer.getMultiplier() * (segmentDetails.selectedSegment.barLength * 4 + segmentDetails.selectedSegment.beatLength)
                    )

                    Zynthbox.SegmentHandler.startPlayback(
                        Zynthbox.PlayGridManager.syncTimer.getMultiplier() * segmentDetails.selectedSegment.getOffsetInBeats(),
                        Zynthbox.PlayGridManager.syncTimer.getMultiplier() * (segmentDetails.selectedSegment.barLength * 4 + segmentDetails.selectedSegment.beatLength)
                    )
                }
            }

            QQC2.Button {
                text: qsTr("Play From Here")
                Layout.fillWidth: true
                onClicked: {
                    console.log(
                        "Playing From Segment",
                        segmentDetails.selectedSegment.segmentId,
                        " : Offset",
                        segmentDetails.selectedSegment.getOffsetInBeats()
                    )

                    Zynthbox.SegmentHandler.startPlayback(
                        Zynthbox.PlayGridManager.syncTimer.getMultiplier() * segmentDetails.selectedSegment.getOffsetInBeats(),
                        0
                    )
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            QQC2.Button {
                text: qsTr("Add Before")
                Layout.fillWidth: true
                onClicked: {
                    zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.new_segment(segmentDetails.selectedSegment.segmentId);
                }
            }
            QQC2.Button {
                text: qsTr("Split In Half")
                Layout.fillWidth: true
                onClicked: {
                    let totalBeatDuration = segmentDetails.selectedSegment.barLength * 4 + segmentDetails.selectedSegment.beatLength;
                    let halfBeatDuration = Math.floor(totalBeatDuration / 2);
                    let unevenSplit = (totalBeatDuration - (halfBeatDuration * 2)) > 0;
                    let halfBarDuration = Math.floor(halfBeatDuration / 4);
                    halfBeatDuration = halfBeatDuration - (halfBarDuration * 4);
                    let newSegment = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.new_segment(segmentDetails.selectedSegment.segmentId + 1);
                    newSegment.barLength = halfBarDuration;
                    newSegment.beatLength = halfBeatDuration;
                    newSegment.clips = segmentDetails.selectedSegment.clips;
                    // Not copying across restartClips to the new segment (since we want to leave the perceived playback alone, so we need to not restart anything)
                    segmentDetails.selectedSegment.barLength = halfBarDuration;
                    segmentDetails.selectedSegment.beatLength = halfBeatDuration;
                    if (unevenSplit) {
                        _private.changeBeatLength(segmentDetails.selectedSegment, true);
                    }
                }
            }
            QQC2.Button {
                text: qsTr("Add After")
                Layout.fillWidth: true
                onClicked: {
                    zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.new_segment(segmentDetails.selectedSegment.segmentId + 1);
                    zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex = segmentDetails.selectedSegment.segmentId + 1;
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            QQC2.Button {
                text: qsTr("Remove Segment...")
                Layout.fillWidth: true
                onClicked: {
                    segmentRemover.open();
                }
                Zynthian.ActionPickerPopup {
                    id: segmentRemover
                    rows: 1
                    columns: 3
                    function doRemove() {
                        if (zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count === 1) {
                            // If there's only this single segment, don't actually delete it, just clear it
                            zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegment.clear();
                        } else {
                            // If there's more than one, we can remove the one we've got selected
                            zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.remove_segment(zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex);
                        }
                    }
                    actions: [
                        QQC2.Action {
                            text: qsTr("Remove Segment,\nAdd Duration To Previous")
                            enabled: zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex > 0
                            onTriggered: {
                                let totalBeatDuration = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegment.beatLength + (zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegment.barLength * 4);
                                let previousSegment = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.get_segment(zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex - 1);
                                for (let beat = 0; beat < totalBeatDuration; ++beat) {
                                    _private.changeBeatLength(previousSegment, true);
                                }
                                segmentRemover.doRemove();
                                // Since we're merging with the previous, that is really the one that'll be of interest next, so... select that
                                zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex - 1;
                            }
                        },
                        QQC2.Action {
                            text: qsTr("Just Remove Segment")
                            onTriggered: {
                                segmentRemover.doRemove();
                            }
                        },
                        QQC2.Action {
                            text: qsTr("Remove Segment,\nAdd Duration To Next")
                            enabled: zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex < zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count - 1
                            onTriggered: {
                                let totalBeatDuration = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegment.beatLength + (zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegment.barLength * 4);
                                let nextSegment = zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.get_segment(zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex + 1);
                                for (let beat = 0; beat < totalBeatDuration; ++beat) {
                                    _private.changeBeatLength(nextSegment, true);
                                }
                                segmentRemover.doRemove();
                            }
                        }
                    ]
                }
            }
        }
        // END Segment details column
    }
}
