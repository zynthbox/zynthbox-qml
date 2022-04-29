/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Marco MArtin <mart@kde.org>

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

import Qt.labs.folderlistmodel 2.11
import Qt.labs.handlers 1.0

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick
import JuceGraphics 1.0

// GridLayout so TabbedControlView knows how to navigate it
GridLayout {
    id: waveBar
    rows: 1
    Layout.fillWidth: true
    property QtObject bottomBar: null
    property QtObject controlObj: (bottomBar.controlType === BottomBar.ControlType.Clip || bottomBar.controlType === BottomBar.ControlType.Pattern)
                                    ? bottomBar.controlObj // selected bottomBar object is clip/pattern
                                    : bottomBar.controlObj.samples[bottomBar.controlObj.selectedSampleRow] // selected bottomBar object is not clip/pattern and hence it is a track
    property QtObject track: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)

    Connections {
        target: bottomBar
        onControlObjChanged: {
            console.log("Handling bottombar control obj changed")
            console.log(bottomBar.controlType, bottomBar.controlObj)
            if (bottomBar.controlType === BottomBar.ControlType.Clip || bottomBar.controlType === BottomBar.ControlType.Pattern) {
                console.log("Clip/pattern")
            } else {
                console.log("Track")
            }
        }
    }

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.trackButton.checked = true
                return true;
        }
        
        return false;
    }

    WaveFormItem {
        id: wav

        // Calculate amount of pixels represented by 1 second
        property real pixelToSecs: (wav.end - wav.start) / width

        // Calculate amount of pixels represented by 1 beat
        property real pixelsPerBeat: (60/zynthian.zynthiloops.song.bpm) / wav.pixelToSecs

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: Kirigami.Units.gridUnit
        color: Kirigami.Theme.textColor
        source: waveBar.controlObj.path
//        clip: true
        PinchArea {
            anchors.fill: parent
            property real scale: 1
            onPinchUpdated: {
                //FIXME: buggy, disable for now
                /* let actualScale = Math.min(1.2, Math.max(1, scale + pinch.scale - 1));
                print(actualScale)
                let ratio = pinch.center.x / width;
                let newLength = wav.length / actualScale;
                let remaining = wav.length - newLength;
                wav.start = remaining/(1-ratio);
                wav.end = newLength - remaining/(ratio); */
            }
            onPinchFinished: {
                scale = pinch.scale
                print ("scale"+scale)
            }

            // Mask for wave part before start
            Rectangle {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                    right: startLoopLine.left
                }
                color: "#99000000"
            }

            // Mask for wave part after
            Rectangle {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: endLoopLine.right
                    right: parent.right
                }
                color: "#99000000"
            }

            // Area after start handle and before end handle to
            // allow setting startposition with drag in between handles
            Rectangle {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: startHandle.right
                    right: endHandle.left
                }
                color: "transparent"
                border.width: 0
                border.color: "white"
                MouseArea {
                    property int lastX
                    anchors.fill: parent
                    onPressed: {
                        lastX = mouse.x
                    }
                    onPositionChanged: {
                        let delta = wav.pixelToSecs * (mouse.x - lastX)

                        // Set startposition on swipe
                        waveBar.controlObj.startPosition += delta
                    }
                    onPressedChanged: {
                        zynthian.zynthiloops.knobTouchUpdateInProgress = pressed
                    }
                }
            }

            // Handle for setting start position
            QQC2.Button {
                id: startHandle

                x: startLoopLine.x
                y: 0
                padding: Kirigami.Units.largeSpacing * 1.5
                background: Item {
                    Image {
                        id: startHandleSeparator
                        anchors {
                            right: parent.right
                            top: parent.top
                            bottom: parent.bottom
                        }
                        source: "../../Zynthian/img/breadcrumb-separator.svg"
                    }
                }
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                opacity: 1
                text: qsTr("S", "Start")
                z: 100

                onXChanged: {
                    if (startHandleDragHandler.active) {
                        // Set startposition on swipe
                        waveBar.controlObj.startPosition = wav.pixelToSecs * x
                    }
                }

                DragHandler {
                    id: startHandleDragHandler
                    xAxis {
                        minimum: 0
                        maximum: parent.parent.width
                        // Set maximum value such that endLine never goes out of view
                        // maximum: parent.parent.width - (endLoopLine.x - startLoopLine.x)
                    }

                    yAxis.enabled: false
                    onGrabChanged: {
                        zynthian.zynthiloops.knobTouchUpdateInProgress = startHandleDragHandler.active
                    }
                }
            }

            // Handle for setting loop point
            QQC2.Button {
                id: loopHandle

                visible: waveBar.track.trackAudioType !== "sample-slice"
                anchors.verticalCenter: startLoopLine.verticalCenter
                padding: Kirigami.Units.largeSpacing * 1.5
                background: Item {
                    Image {
                        id: loopHandleSeparator
                        anchors {
                            right: parent.right
                            top: parent.top
                            bottom: parent.bottom
                        }
                        source: "../../Zynthian/img/breadcrumb-separator.svg"
                    }
                }
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                opacity: 1
                text: qsTr("L", "Loop")
                z: 100

                onXChanged: {
                    if (loopHandleDragHandler.active) {
                        waveBar.controlObj.loopDelta = (loopHandle.x - startLoopLine.x) * wav.pixelToSecs
                    }
                }

                DragHandler {
                    id: loopHandleDragHandler
                    xAxis {
                        minimum: startLoopLine.x
                        maximum: endLoopLine.x
                    }

                    yAxis.enabled: false
                    onGrabChanged: {
                        zynthian.zynthiloops.knobTouchUpdateInProgress = loopHandleDragHandler.active
                    }
                }
            }

            // Handle for setting length
            QQC2.Button {
                id: endHandle

                anchors.bottom: parent.bottom
                padding: Kirigami.Units.largeSpacing * 1.5
                background: Item {
                    Image {
                        id: endHandleSeparator
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        mirror: true
                        source: "../../Zynthian/img/breadcrumb-separator.svg"
                    }
                }
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                opacity: 1
                text: qsTr("E", "End")
                z: 100

                onXChanged: {
                    if (endHandleDragHandler.active) {
                        let calculatedLength

                        if (waveBar.controlObj.snapLengthToBeat) {
                            calculatedLength = Math.abs(Math.floor((endHandle.x - startLoopLine.x + endHandle.width)/wav.pixelsPerBeat))
                        } else {
                            calculatedLength = Math.abs((endHandle.x + endHandle.width - startLoopLine.x)/wav.pixelsPerBeat);
                        }

                        if (calculatedLength > 0 || waveBar.controlObj.length !== calculatedLength) {
                            waveBar.controlObj.length = calculatedLength;
                        }

                        // When dragging end handle, check and set loop handle to be not greater than end
                        if (loopLine.x > endLoopLine.x) {
                            waveBar.controlObj.loopDelta = (endLoopLine.x - startLoopLine.x) * wav.pixelToSecs
                        }
                    }
                }
                DragHandler {
                    id: endHandleDragHandler
                    xAxis {
                        minimum: startLoopLine.x - width
                        maximum: parent.parent.width
                    }

                    yAxis.enabled: false
                    onGrabChanged: {
                        if (!active) {
                            endHandle.x = endLoopLine.x - endHandle.width
                        }

                        zynthian.zynthiloops.knobTouchUpdateInProgress = endHandleDragHandler.active
                    }
                }
            }

            // Start loop line
            Rectangle {
                id: startLoopLine
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                color: Kirigami.Theme.positiveTextColor
                opacity: 0.6
                width: Kirigami.Units.smallSpacing
                x: (waveBar.controlObj.startPosition / waveBar.controlObj.duration) * parent.width
            }

            // Loop line
            Rectangle {
                id: loopLine
                visible: waveBar.track.trackAudioType !== "sample-slice"
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                x: startLoopLine.x + waveBar.controlObj.loopDelta/wav.pixelToSecs
                color: Kirigami.Theme.highlightColor
                opacity: 0.6
                width: Kirigami.Units.smallSpacing
                onXChanged: {
                    if (!loopHandleDragHandler.active) {
                        loopHandle.x = loopLine.x
                    }
                }
            }

            // End loop line
            Rectangle {
                id: endLoopLine
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                color: Kirigami.Theme.neutralTextColor
                opacity: 0.6
                width: Kirigami.Units.smallSpacing
                x: ((((60/zynthian.zynthiloops.song.bpm) * waveBar.controlObj.length) / waveBar.controlObj.duration) * parent.width) + ((waveBar.controlObj.startPosition / waveBar.controlObj.duration) * parent.width)
                onXChanged: {
                    if (!endHandleDragHandler.active) {
                       endHandle.x = endLoopLine.x - endHandle.width
                    }
                }
            }

            // Progress line
            Rectangle {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                visible: waveBar.controlObj.isPlaying
                color: Kirigami.Theme.highlightColor
                width: Kirigami.Units.smallSpacing
                x: waveBar.controlObj.progress/waveBar.controlObj.duration * parent.width
            }

            // Slice progress lines
            Repeater {
                property QtObject cppClipObject: ZynQuick.PlayGridManager.getClipById(waveBar.controlObj.cppObjId);
                model: (waveBar.track.trackAudioType === "sample-slice" || waveBar.track.trackAudioType === "sample-trig") && cppClipObject
                    ? cppClipObject.playbackPositions
                    : 0
                delegate: Item {
                    Rectangle {
                        anchors.centerIn: parent
                        rotation: 45
                        color: Kirigami.Theme.highlightColor
                        width: Kirigami.Units.largeSpacing
                        height:  Kirigami.Units.largeSpacing
                        scale: 0.5 + model.positionGain
                    }
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.floor(model.positionProgress * parent.width)
                }
            }

            // Create and place beat lines when trackAudioType !== "sample-slice"
            Repeater {
                // Count number of beat lines to be shown as per beat and visible width
                model: waveBar.track.trackAudioType !== "sample-slice"
                        ? Math.ceil(wav.width / wav.pixelsPerBeat)
                        : 0
                delegate: Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                    }
                    color: "#ffffff"
                    opacity: 0.1
                    width: 1
                    // Calculate position of each beat line taking startposition into consideration
                    x: wav.pixelsPerBeat*modelData + (startLoopLine.x % wav.pixelsPerBeat)
                }
            }

            // Create and place slice lines when trackAudioType === "sample-slice"
            Repeater {
                // Count number of slice lines to be shown
                model: waveBar.track.trackAudioType === "sample-slice"
                       ? waveBar.controlObj.slices
                       : 0
                delegate: Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                    }
                    color: Qt.rgba(Kirigami.Theme.highlightColor.r,
                                   Kirigami.Theme.highlightColor.g,
                                   Kirigami.Theme.highlightColor.b,
                                   index === 0 ? 0 : 0.8)
                    width: 2
                    // Calculate position of each beat line taking startposition into consideration
                    x: startLoopLine.x + (endLoopLine.x - startLoopLine.x)*modelData/waveBar.controlObj.slices

                    Rectangle {
                        width: Math.min(Kirigami.Units.gridUnit, (endLoopLine.x - startLoopLine.x)/waveBar.controlObj.slices - 4)
                        height: width
                        anchors {
                            left: parent.right
                            bottom: parent.bottom
                        }

                        border.width: 1
                        border.color: "#99ffffff"
                        color: Kirigami.Theme.backgroundColor

                        QQC2.Label {
                            anchors.centerIn: parent
                            text: qsTr("%L1").arg(index+1)
                            font.pointSize: Math.min(8, parent.width)
                        }
                    }
                }
            }
        }
        QQC2.Button {
            anchors {
                top: parent.top
                right: parent.right
            }
            // Slightly odd check - sometimes this will return a longer string, but as it's a
            // base64 encoding of a midi file, it'll be at least the header size of that if
            // it's useful, so... just check for bigger than 10, that'll do
            visible: waveBar.controlObj.metadataMidiRecording.length > 10
            text: ZynQuick.MidiRecorder.isPlaying ? "Stop playing midi" : "Play embedded midi"
            onClicked: {
                if (ZynQuick.MidiRecorder.isPlaying) {
                    ZynQuick.MidiRecorder.stopPlayback();
                } else {
                    if (ZynQuick.MidiRecorder.loadFromBase64Midi(waveBar.controlObj.metadataMidiRecording)) {
                        ZynQuick.MidiRecorder.forceToChannel(ZynQuick.PlayGridManager.currentMidiChannel);
                        ZynQuick.MidiRecorder.playRecording();
                    } else {
                        console.log("Failed to load recording from clip data, which is:\n", waveBar.controlObj.metadataMidiRecording);
                    }
                }
            }
        }
    }
}

