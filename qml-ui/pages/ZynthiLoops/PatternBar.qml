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
import org.zynthian.quick 1.0 as ZynQuick

import Zynthian 1.0 as Zynthian

// GridLayout so TabbedControlView knows how to navigate it
GridLayout {
    id: root
    rows: 1
    Layout.fillWidth: true
    property QtObject bottomBar: null

    Image {
        id: patternVisualiser
        Layout.fillWidth: true
        Layout.fillHeight: true
        smooth: false

        visible: controlObj.clipTrack.connectedPattern >= 0
        property QtObject sequence: controlObj.clipTrack.connectedPattern >= 0 ? ZynQuick.PlayGridManager.getSequenceModel("Global") : null
        property QtObject pattern: sequence ? sequence.get(controlObj.clipTrack.connectedPattern) : null
        source: pattern ? "image://pattern/Global/" + controlObj.clipTrack.connectedPattern + "/" + controlObj.col + "?" + pattern.lastModified : ""
        Rectangle { // Progress
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            visible: patternVisualiser.sequence &&
                     patternVisualiser.sequence.isPlaying &&
                     patternVisualiser.pattern &&
                     patternVisualiser.pattern.enabled &&
                     ((controlObj.col === 0 && patternVisualiser.pattern.bank === "I") || (controlObj.col === 1 && patternVisualiser.pattern.bank === "II"))
            color: Kirigami.Theme.highlightColor
            width: widthFactor // this way the progress rect is the same width as a step
            property double widthFactor: patternVisualiser.pattern ? parent.width / (patternVisualiser.pattern.width * patternVisualiser.pattern.bankLength) : 1
            x: patternVisualiser.pattern ? patternVisualiser.pattern.bankPlaybackPosition * widthFactor : 0
        }
        MouseArea {
            anchors.fill:parent
            onClicked: {
                var screenBack = zynthian.current_screen_id;
                zynthian.current_modal_screen_id = "playgrid";
                zynthian.forced_screen_back = "zynthiloops";
                ZynQuick.PlayGridManager.setCurrentPlaygrid("playgrid", ZynQuick.PlayGridManager.sequenceEditorIndex);
                var sequence = ZynQuick.PlayGridManager.getSequenceModel("Global");
                sequence.activePattern = controlObj.clipTrack.connectedPattern;
            }
        }
    }
}

