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
import JuceGraphics 1.0

// GridLayout so TabbedControlView knows how to navigate it
GridLayout {
    id: waveBar
    rows: 1
    Layout.fillWidth: true
    property QtObject bottomBar: null

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
                sceneActionBtn.checked = false;
                mixerActionBtn.checked = true;
                bottomStack.currentIndex = 1;
                return true;
        }

        return false;
    }

    WaveFormItem {
        id: wav
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: Kirigami.Units.gridUnit
        color: Kirigami.Theme.textColor
        source: waveBar.bottomBar.controlObj.path
        PinchArea {
            anchors.fill: parent
            property real scale: 1
            onPinchUpdated: {
                //FIXME: buggy, disable for now
                return
                let actualScale = Math.min(1.2, Math.max(1, scale + pinch.scale - 1));
                print(actualScale)
                let ratio = pinch.center.x / width;
                let newLength = wav.length / actualScale;
                let remaining = wav.length - newLength;
                wav.start = remaining/(1-ratio);
                wav.end = newLength - remaining/(ratio);
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

                onXChanged: {
                    if (startHandleDragHandler.active) {
                        // Calculate amount of seconds represented by each pixel
                        let pixelToSecs = (wav.end - wav.start) / parent.width

                        // Set startposition on swipe
                        waveBar.bottomBar.controlObj.startPosition = pixelToSecs * x
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
                }
            }

            Rectangle {  //Start loop
                id: startLoopLine
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                color: Kirigami.Theme.positiveTextColor
                opacity: 0.6
                width: Kirigami.Units.smallSpacing
                x: (waveBar.bottomBar.controlObj.startPosition / waveBar.bottomBar.controlObj.duration) * parent.width
            }

            Repeater {
                model: 50
                delegate: Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                    }
                    color: "#ffffff"
                    opacity: 0.1
                    width: 1
                    x: ((waveBar.bottomBar.controlObj.startPosition+waveBar.bottomBar.controlObj.secPerBeat*modelData) / waveBar.bottomBar.controlObj.duration) * parent.width
                }
            }

            Rectangle {  // End loop
                id: endLoopLine
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                color: Kirigami.Theme.neutralTextColor
                opacity: 0.6
                width: Kirigami.Units.smallSpacing
                x: ((((60/zynthian.zynthiloops.song.bpm) * waveBar.bottomBar.controlObj.length) / waveBar.bottomBar.controlObj.duration) * parent.width) + ((waveBar.bottomBar.controlObj.startPosition / waveBar.bottomBar.controlObj.duration) * parent.width)
                onXChanged: {
                    if (!endHandleDragHandler.active) {
                       endHandle.x = endLoopLine.x - endHandle.width
                    }
                }
            }

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

                onXChanged: {
                    if (endHandleDragHandler.active) {
                        // Calculate amount of pixels represented by 1 second
                        let pixelsPerSecond = parent.width / (wav.end - wav.start)
                        let pixelsPerBeat = (60/zynthian.zynthiloops.song.bpm) * pixelsPerSecond
                        let length = Math.abs(Math.floor((endHandle.x - startLoopLine.x + endHandle.width)/pixelsPerBeat))

                        if (length > 0 || waveBar.bottomBar.controlObj.length !== length) {
                            waveBar.bottomBar.controlObj.length = length;
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
                    }
                }
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

            Rectangle { // Progress
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                visible: waveBar.bottomBar.controlObj.isPlaying
                color: Kirigami.Theme.highlightColor
                width: Kirigami.Units.smallSpacing
                x: waveBar.bottomBar.controlObj.progress/waveBar.bottomBar.controlObj.duration * parent.width
            }
        }
    }
}

