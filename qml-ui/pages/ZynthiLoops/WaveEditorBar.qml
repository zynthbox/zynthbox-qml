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
            MouseArea {
                anchors.fill: parent
                property int lastX
                onPressed: {
                    lastX = mouse.x
                }
                onPositionChanged: {
                    let pixelToSecs = (wav.end - wav.start) / width
                    let delta = pixelToSecs * (mouse.x - lastX)

//                    if ((wav.start - delta) < 0) {
//                        delta = wav.start;
//                    } else if (wav.end - delta > wav.length) {
//                        delta = wav.length - wav.end;
//                    }
//                    wav.start -= delta;
//                    wav.end -= delta;

                    // Set startposition on swipe
                    waveBar.bottomBar.controlObj.startPosition += delta

                    lastX = mouse.x;
                }
            }
            Rectangle {  //Start loop
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
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                color: Kirigami.Theme.neutralTextColor
                opacity: 0.6
                width: Kirigami.Units.smallSpacing
                x: ((((60/zynthian.zynthiloops.song.bpm) * waveBar.bottomBar.controlObj.length) / waveBar.bottomBar.controlObj.duration) * parent.width) + ((waveBar.bottomBar.controlObj.startPosition / waveBar.bottomBar.controlObj.duration) * parent.width)
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

