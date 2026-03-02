/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

General information panel for sketchpad clips

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

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.7 as Kirigami

import io.zynthbox.components 1.0 as Zynthbox
import io.zynthbox.ui 1.0 as ZUI

Item {
    id: component
    property QtObject sketchpadClip
    property QtObject clip
    RowLayout {
        anchors {
            fill: parent
            margins: Kirigami.Units.smallSpacing
        }
        ZUI.SketchpadDial {
            id: startDial
            text: qsTr("Start") + "\n"
            controlObj: component.clip ? component.clip.selectedSliceObject : null
            controlProperty: "startPositionSeconds"
            valueString: component.clip ? qsTr("%1\nsecs").arg(component.clip.selectedSliceObject.startPositionSeconds.toFixed(2)) : 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            knobId: 0

            dial {
                stepSize: 0.01
                from: 0
                to: component.clip ? component.clip.durationSeconds : 0
            }

            onDoubleClicked: {
                component.clip.selectedSliceObject.startPositionSeconds = 0;
            }
        }
        ZUI.SketchpadDial {
            id: loopOffsetSecondsDial
            text: qsTr("Loop Offset\n(seconds)")
            controlObj: component.clip ? component.clip.selectedSliceObject : null
            controlProperty: "loopDeltaSeconds"
            valueString: component.clip ? qsTr("%1\nsecs").arg(component.clip.selectedSliceObject.loopDeltaSeconds.toFixed(2)) : 0
            visible: component.clip && component.clip.selectedSliceObject.effectivePlaybackStyle != Zynthbox.ClipAudioSource.WavetableStyle && component.clip.selectedSliceObject.snapLengthToBeat === false
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            knobId: 1

            buttonStepSize: 0.1
            dial {
                stepSize: 0.01
                from: 0
                to: component.clip ? component.clip.lengthSeconds : 0
            }

            onDoubleClicked: {
                component.clip.selectedSliceObject.loopDeltaSeconds = 0;
            }
        }
        ZUI.SketchpadDial {
            id: loopOffsetBeatsDial
            text: qsTr("Loop Offset\n(beats)")
            controlObj: component.clip ? component.clip.selectedSliceObject : null
            controlProperty: "loopDeltaBeats"
            readonly property double beatLengthRemainder: component.clip ? component.clip.selectedSliceObject.loopDeltaBeats % 4 : 0
            valueString: component.clip ? qsTr("%1:%2\nbeats").arg(Math.floor(component.clip.selectedSliceObject.loopDeltaBeats / 4)).arg((beatLengthRemainder).toFixed(Number.isInteger(beatLengthRemainder) ? 0 : 2)) : 0
            visible: component.clip && component.clip.selectedSliceObject.effectivePlaybackStyle != Zynthbox.ClipAudioSource.WavetableStyle && component.clip.selectedSliceObject.snapLengthToBeat === true
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            knobId: 1

            buttonStepSize: 0.25
            dial {
                stepSize: 0.01
                from: 0
                to: component.clip ? component.clip.selectedSliceObject.lengthBeats : 0
            }

            onDoubleClicked: {
                component.clip.selectedSliceObject.loopDeltaBeats = 0;
            }
        }
        ZUI.SketchpadDial {
            id: lengthSecondsDial
            text: qsTr("Length\n(seconds)")
            controlObj: component.clip ? component.clip.selectedSliceObject : null
            controlProperty: "lengthSeconds"
            valueString: component.clip ? qsTr("%1\nsecs").arg(component.clip.selectedSliceObject.lengthSeconds.toFixed(2)) : 0
            visible: component.clip && component.clip.selectedSliceObject.effectivePlaybackStyle != Zynthbox.ClipAudioSource.WavetableStyle && component.clip.selectedSliceObject.snapLengthToBeat === false
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            knobId: 2

            dial {
                stepSize: 0.01
                from: 0
                // Longest loop length is the double of our longest pattern, so 2 * 8 bars * 4 beats per bar
                to: Zynthbox.SyncTimer.subbeatCountToSeconds(Zynthbox.SyncTimer.bpm, 64 * Zynthbox.SyncTimer.getMultiplier())
            }

            onDoubleClicked: {
                component.clip.selectedSliceObject.lengthSeconds = 0;
            }
        }
        ZUI.SketchpadDial {
            id: lengthBeatsDial
            text: qsTr("Length\n(beats)")
            controlObj: component.clip ? component.clip.selectedSliceObject : null
            controlProperty: "lengthBeats"
            readonly property double beatLengthRemainder: component.clip ? component.clip.selectedSliceObject.lengthBeats % 4 : 0
            valueString: component.clip ? qsTr("%1:%2\nbeats").arg(Math.floor(component.clip.selectedSliceObject.lengthBeats / 4)).arg((beatLengthRemainder).toFixed(Number.isInteger(beatLengthRemainder) ? 0 : 2)) : 0
            visible: component.clip && component.clip.selectedSliceObject.effectivePlaybackStyle != Zynthbox.ClipAudioSource.WavetableStyle && component.clip.selectedSliceObject.snapLengthToBeat === true
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            knobId: 2

            buttonStepSize: 0.25
            dial {
                stepSize: 0.01
                from: 0
                // Longest loop length is the double of our longest pattern, so 2 * 8 bars * 4 beats per bar
                to: 64
            }

            onDoubleClicked: {
                component.clip.selectedSliceObject.lengthBeats = 0;
            }
        }
        ZUI.SketchpadDial {
            id: lengthSamplesDial
            text: qsTr("Length\n(samples)")
            controlObj: component.clip ? component.clip.selectedSliceObject : null
            controlProperty: "lengthSamples"
            visible: component.clip && component.clip.selectedSliceObject.effectivePlaybackStyle == Zynthbox.ClipAudioSource.WavetableStyle
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            knobId: 2

            dial {
                stepSize: 1
                from: 0
                // Longest loop length is the double of our longest pattern, so 2 * 8 bars * 4 beats per bar
                to: component.clip ? component.clip.durationSamples : 0
            }

            onDoubleClicked: {
                component.clip.selectedSliceObject.lengthSamples = 0;
            }
        }
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 15
            columns: 2
            QQC2.Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                Layout.columnSpan: 2
                text: component.sketchpadClip ? component.sketchpadClip.filename : ""
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                text: "Duration:"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                text: component.clip ? ZUI.CommonUtils.formatTime(component.clip.durationSeconds.toFixed(3)) : ""
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                text: "Samplerate:"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                text: component.clip ? qsTr("%1KHz").arg((component.clip.sampleRate / 1000).toFixed(2)) : ""
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                text: "File size:"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                text: component.clip ? ZUI.CommonUtils.formatFileSize(component.clip.fileSize) : ""
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
            }
        }
    }
}
