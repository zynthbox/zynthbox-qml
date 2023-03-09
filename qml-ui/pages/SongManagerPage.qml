/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Song Player Page

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

import libzl 1.0 as ZL
import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

import "Sketchpad" as Sketchpad

Zynthian.ScreenPage {
    id: component
    screenId: "song_manager"
    title: qsTr("Song")
    property bool isVisible:zynthian.current_screen_id === "song_manager"

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
        }
        return returnValue;
    }
    Connections {
        target: zynthian.song_manager
        onBigKnobValueChanged: {
            if (zynthian.song_manager.bigKnobValue < 0) {
                for (var i = zynthian.song_manager.bigKnobValue; i < 0; ++i) {
                    _private.goLeft();
                }
            } else if (zynthian.song_manager.bigKnobValue > 0) {
                for (var i = zynthian.song_manager.bigKnobValue; i > 0; --i) {
                    _private.goRight();
                }
            } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
        }
        onKnob1ValueChanged: {
            if (zynthian.song_manager.knob1Value < 0) {
                for (var i = zynthian.song_manager.knob1Value; i < 0; ++i) {
                    _private.knob1Down();
                }
            } else if (zynthian.song_manager.knob1Value > 0) {
                for (var i = zynthian.song_manager.knob1Value; i > 0; --i) {
                    _private.knob1Up();
                }
            } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
        }
        onKnob2ValueChanged: {
            if (zynthian.song_manager.knob2Value < 0) {
                for (var i = zynthian.song_manager.knob2Value; i < 0; ++i) {
                    _private.knob2Down();
                }
            } else if (zynthian.song_manager.knob2Value > 0) {
                for (var i = zynthian.song_manager.knob2Value; i > 0; --i) {
                    _private.knob2Up();
                }
            } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
        }
        onKnob3ValueChanged: {
            if (zynthian.song_manager.knob3Value < 0) {
                for (var i = zynthian.song_manager.knob3Value; i < 0; ++i) {
                    _private.knob3Down();
                }
            } else if (zynthian.song_manager.knob3Value > 0) {
                for (var i = zynthian.song_manager.knob3Value; i > 0; --i) {
                    _private.knob3Up();
                }
            } // and no reason to do anything with 0, that's just the knob resetting itself after sending the delta out
        }
    }
    QtObject {
        id: _private
        function goLeft() {
            if (zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex > 0) {
                zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex -= 1;
            }
        }
        function goRight() {
            if (zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex < zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count - 1) {
                zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex += 1;
            }
        }
        function knob1Up() {
            segmentDetails.selectedSegment.barLength += 1;
        }
        function knob1Down() {
            if (segmentDetails.selectedSegment.barLength > 0) {
                segmentDetails.selectedSegment.barLength -= 1;
            }
        }
        function knob2Up() {
            if (segmentDetails.selectedSegment.beatLength < 3) {
                segmentDetails.selectedSegment.beatLength += 1;
            }
        }
        function knob2Down() {
            if (segmentDetails.selectedSegment.beatLength > 0) {
                segmentDetails.selectedSegment.beatLength -= 1;
            }
        }
        function knob3Up() {
        }
        function knob3Down() {
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
            enabled: zynthian.sketchpad.song.sketchesModel.songMode
                ? zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.totalBeatDuration > 0
                : true
            onTriggered: {
                multichannelRecorderPopup.recordSong(zynthian.sketchpad.song)
            }
        }
    ]
    Zynthian.MultichannelRecorderPopup {
        id: multichannelRecorderPopup
    }
    Zynthian.SegmentModelPicker {
        id: segmentModelPicker
    }

    ColumnLayout {
        anchors.fill: parent
        // BEGIN Segments navigator bar
        RowLayout {
            id: segmentsLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 1

            // Should show arrows is True when segment count is greater than 11 and hence needs arrows to scroll
            property bool shouldShowSegmentArrows: zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count > 11
            // Segment offset will determine what is the first segment to display when arrow keys are displayed
            property int segmentOffset: 0
            // Maximum segment offset allows the arrow keys to check if there are any more segments outside view
            property int maximumSegmentOffset: zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count - 11 + 2
            // The index of the last visible segment cell (as opposed to the segment as exists in the song's segments model)
            property int lastVisibleSegmentCellIndex: 10

            Connections {
                target: zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel
                enabled: component.isVisible
                onSelectedSegmentIndexChanged: {
                    // When selectedSegmentIndex changes (i.e. being set with Big Knob), adjust visible segments so that selected segment is brought into view
                    if (zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex > (segmentsLayout.segmentOffset+7)) {
                        // console.log("selected segment is outside visible segments on the right :", zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex, segmentsLayout.segmentOffset, Math.min(segmentsLayout.maximumSegmentOffset, zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex - 7))
                        segmentsLayout.segmentOffset = Math.min(segmentsLayout.maximumSegmentOffset, zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex - 7)
                    } else if (zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex < segmentsLayout.segmentOffset) {
                        // console.log("selected segment is outside visible segments on the left :", zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex, segmentsLayout.segmentOffset, zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex)
                        segmentsLayout.segmentOffset = zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex
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
                    property QtObject segment: zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count > 0
                                                ? zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.get_segment(segmentHeader.thisSegmentIndex)
                                                : null

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    text: zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count > segmentsLayout.lastVisibleSegmentCellIndex + 1
                                ? index === 0
                                    ? "<"
                                    : index === segmentsLayout.lastVisibleSegmentCellIndex
                                        ? ">"
                                        : segmentHeader.segment
                                            ? segmentHeader.segment.name
                                            : ""
                                : segmentHeader.segment
                                    ? segmentHeader.segment.name
                                    : ""
                    subText: {
                        if (zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count > segmentsLayout.lastVisibleSegmentCellIndex + 1 && (index === 0 || index === segmentsLayout.lastVisibleSegmentCellIndex)) {
                            return " "
                        } else if (!segmentHeader.segment || (segmentHeader.segment.barLength === 0 && segmentHeader.segment.beatLength === 0)) {
                            return " "
                        } else {
                            return segmentHeader.segment.barLength + "." + segmentHeader.segment.beatLength
                        }
                    }

                    textSize: 10
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
                        return segmentHeader.thisSegmentIndex === zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex
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
                                zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex = segmentHeader.thisSegmentIndex
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
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit
            spacing: 0
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Button
            Repeater {
                id: segmentsRepeater
                property int totalDuration: zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count > 0 ? ZynQuick.PlayGridManager.syncTimer.getMultiplier() * zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.totalBeatDuration : 0
                model: component.isVisible && totalDuration > 0 ? zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel : 0
                delegate: Item {
                    property QtObject segment: model.segment
                    property int duration: ZynQuick.PlayGridManager.syncTimer.getMultiplier() * (segment.barLength * 4 + segment.beatLength)
                    Layout.fillWidth: true
                    Layout.preferredWidth: component.width * (duration / segmentsRepeater.totalDuration)
                    Layout.preferredHeight: Kirigami.Units.gridUnit
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
                x: component.visible && segmentsRepeater.totalDuration > 0 ? parent.width * (ZynQuick.SegmentHandler.playhead / segmentsRepeater.totalDuration) : 0
                Rectangle {
                    anchors {
                        bottom: parent.top
                        horizontalCenter: parent.horizontalCenter
                    }
                    height: Kirigami.Units.gridUnit + 10 // 10 because the default spacing is 5 and we want it to stick up and down by that spacing amount, why not
                    width: 3
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: Kirigami.Theme.focusColor
                }
            }
        }
        // END Playback progress bar
        RowLayout {
            // BEGIN Segment picker grid
            ColumnLayout {
                RowLayout {
                    Layout.fillWidth: true
                    Repeater {
                        model: 10
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                            horizontalAlignment: Text.AlignHCenter
                            text: "Ch" + (index + 1)
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Repeater {
                        model: 10
                        Sketchpad.PartBarDelegate {
                            id: partBarDelegate
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: Kirigami.Units.gridUnit* 2
                            channel: zynthian.sketchpad.song.channelsModel.getChannel(model.index)
                            songMode: true
                        }
                    }
                }
            }
            // END Segment picker grid
            // BEGIN Segment details column
            ColumnLayout {
                id: segmentDetails
                property QtObject selectedSegment: zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegment
                onSelectedSegmentChanged: {
                    barLengthInput.text = segmentDetails.selectedSegment.barLength
                    beatLengthInput.text = segmentDetails.selectedSegment.beatLength
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

                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    horizontalAlignment: "AlignHCenter"
                    verticalAlignment: "AlignVCenter"
                    text: segmentDetails.selectedSegment.name
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
                        text: segmentDetails.selectedSegment.barLength
                        onAccepted: {
                            segmentDetails.selectedSegment.barLength = parseInt(text)
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
                        text: segmentDetails.selectedSegment.beatLength
                        onAccepted: {
                            segmentDetails.selectedSegment.beatLength = parseInt(text)
                        }
                    }
                }

                QQC2.Button {
                    text: qsTr("Play Segment")
                    onClicked: {
                        console.log(
                            "Playing Segment",
                            segmentDetails.selectedSegment.segmentId,
                            " : Offset",
                            segmentDetails.selectedSegment.getOffsetInBeats(),
                            ", durationInBeats",
                            (segmentDetails.selectedSegment.barLength * 4 + segmentDetails.selectedSegment.beatLength),
                            ", durationInTicks",
                            ZynQuick.PlayGridManager.syncTimer.getMultiplier() * (segmentDetails.selectedSegment.barLength * 4 + segmentDetails.selectedSegment.beatLength)
                        )

                        ZynQuick.SegmentHandler.startPlayback(
                            ZynQuick.PlayGridManager.syncTimer.getMultiplier() * segmentDetails.selectedSegment.getOffsetInBeats(),
                            ZynQuick.PlayGridManager.syncTimer.getMultiplier() * (segmentDetails.selectedSegment.barLength * 4 + segmentDetails.selectedSegment.beatLength)
                        )
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                QQC2.Button {
                    text: qsTr("Add Before")
                    onClicked: {
                        zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.new_segment(segmentDetails.selectedSegment.segmentId);
                    }
                }
                QQC2.Button {
                    text: confirmRemoval.visible ? qsTr("Don't Remove") : qsTr("Remove...")
                    onClicked: {
                        confirmRemoval.visible = !confirmRemoval.visible;
                    }
                    QQC2.Button {
                        id: confirmRemoval
                        anchors {
                            top: parent.top
                            right: parent.left
                            rightMargin: Kirigami.Units.smallSpacing
                            bottom: parent.bottom
                        }
                        visible: false
                        width: parent.width
                        text: qsTr("Remove")
                        onClicked: {
                            confirmRemoval.visible = false;
                            if (zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count === 1) {
                                // If there's only this single segment, don't actually delete it, just clear it
                                zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegment.clear();
                            } else {
                                // If there's more than one, we can remove the one we've got selected
                                if (zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex === zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.count - 1) {
                                    // If we've got the last segment selected, and we're deleting that, we need to go back a step to avoid ouchies
                                    zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex = zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex - 1;
                                    zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.remove_segment(zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex + 1);
                                } else {
                                    zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.remove_segment(zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex);
                                }
                            }
                        }
                    }
                }
                QQC2.Button {
                    text: qsTr("Add After")
                    onClicked: {
                        zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.new_segment(segmentDetails.selectedSegment.segmentId + 1);
                        zynthian.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex = segmentDetails.selectedSegment.segmentId + 1;
                    }
                }
            }
            // END Segment details column
        }
    }
}
