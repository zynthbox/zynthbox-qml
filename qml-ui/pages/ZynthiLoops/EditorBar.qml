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
                    if (wav.start - delta < 0) {
                        delta = wav.start;
                    } else if (wav.end - delta > wav.length) {
                        delta = wav.length - wav.end;
                    }
                    wav.start -= delta;
                    wav.end -= delta;
                    lastX = mouse.x;
                }
            }
        }
    }
}

