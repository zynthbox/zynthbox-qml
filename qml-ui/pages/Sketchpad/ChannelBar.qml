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

// GridLayout so TabbedControlView knows how to navigate it
GridLayout {
    id: root
    rows: 1
    Layout.fillWidth: true

    property QtObject bottomBar: null

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.channelButton.checked = true
                return true;
        }
        
        return false;
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 6

//        Binding {
//            target: volumeControl.slider
//            property: "value"
//            value: zynthian.bottomBarControlObj.volume
//        }

        VolumeControl {
            id: volumeControl
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Kirigami.Units.gridUnit*2

            headerText: zynthian.bottomBarControlObj.className && zynthian.bottomBarControlObj.className === "sketchpad_channel" ||
                            zynthian.bottomBarControlObj.audioLevel <= -40
                                ? ""
                                : zynthian.bottomBarControlObj.audioLevel == null
                                    ? ""
                                    : (zynthian.bottomBarControlObj.audioLevel.toFixed(2) + " (dB)")
            footerText: zynthian.bottomBarControlObj.name
            audioLeveldB: zynthian.bottomBarControlObj.className && zynthian.bottomBarControlObj.className === "sketchpad_channel" ? zynthian.bottomBarControlObj.audioLevel : -400

            slider.value: zynthian.bottomBarControlObj.className && zynthian.bottomBarControlObj.className === "sketchpad_channel" ? zynthian.bottomBarControlObj.volume : 0
            onValueChanged: {
                zynthian.bottomBarControlObj.volume = slider.value
            }

            onDoubleClicked: {
                slider.value = zynthian.bottomBarControlObj.initialVolume;
            }
        }
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 6
        // This looks really dumb, but for some reason that i do not fathom, without the literal check on top, we'll be warned that we cannot assign undefined to a bool
        visible: (zynthian.bottomBarControlObj.className && zynthian.bottomBarControlObj.className === "sketchpad_channel" && !zynthian.bottomBarControlObj.isEmpty()) ? true : false

        QQC2.Button {
            // As per #299 disable this button
            visible: false
            Layout.alignment: Qt.AlignCenter
            text: "Channel Editor"
            onClicked: {
                zynthian.current_modal_screen_id = "channel"
            }
        }
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 6

        QQC2.Button {
            Layout.alignment: Qt.AlignCenter

            text: qsTr("Copy Channel")
            visible: bottomBar.channelCopySource == null
            onClicked: {
                bottomBar.channelCopySource = zynthian.bottomBarControlObj;
            }
        }

        QQC2.Button {
            Layout.alignment: Qt.AlignCenter

            text: qsTr("Paste Channel")
            visible: bottomBar.channelCopySource != null
            enabled: bottomBar.channelCopySource != zynthian.bottomBarControlObj
            onClicked: {
                zynthian.bottomBarControlObj.copyFrom(bottomBar.channelCopySource);
                bottomBar.channelCopySource = null;
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}

