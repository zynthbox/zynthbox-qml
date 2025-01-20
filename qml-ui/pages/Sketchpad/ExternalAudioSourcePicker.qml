/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

External audio source picker component

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

import Zynthian 1.0 as Zynthian

Zynthian.DialogQuestion {
    id: root
    function pickChannel(channel) {
        _private.selectedChannel = channel;
        _private.newAudioSourceIndex = _private.newAudioSources.indexOf(channel.externalAudioSource);
        open();
    }

    property var cuiaCallback: function(cuia) {
        var returnValue = root.opened;
        // console.log("ExternalAudioSourcePicker cuia:", cuia);
        switch (cuia) {
        case "KNOB3_UP":
            _private.newAudioSourceIndex = Math.min(_private.newAudioSourceIndex + 1, 6);
            returnValue = true;
            break;
        case "KNOB3_DOWN":
            _private.newAudioSourceIndex = Math.max(_private.newAudioSourceIndex - 1, 0);
            returnValue = true;
            break;
        case "SWITCH_BACK_SHORT":
        case "SWITCH_BACK_BOLD":
            root.reject();
            returnValue = true;
            break;
        case "SWITCH_SELECT_SHORT":
            // pick the currently highlighted source and close
            root.accept();
            returnValue = true;
            break;
        }
        return returnValue;
    }
    rejectText: qsTr("Cancel")
    acceptText: qsTr("OK")
    title: qsTr("Pick External Audio Source For Track %1").arg(_private.selectedChannel ? _private.selectedChannel.name : "")
    width: Kirigami.Units.gridUnit * 20
    height: Kirigami.Units.gridUnit * 22
    onAccepted: {
        _private.selectedChannel.externalAudioSource = _private.newAudioSources[_private.newAudioSourceIndex];
    }

    contentItem: ColumnLayout {
        QtObject {
            id: _private
            property QtObject selectedChannel
            property int newAudioSourceIndex: 0
            property var newAudioSources: [
                "",
                "system:",
                "system:capture_1",
                "system:capture_2",
                "usb-gadget-in:",
                "usb-gadget-in:capture_1",
                "usb-gadget-in:capture_2",
            ]
            property var newAudioSourceNames: [
                qsTr("No External Audio Source"),
                qsTr("Capture Microphone In (stereo)"),
                qsTr("Capture Microphone In (left)"),
                qsTr("Capture Microphone In (right)"),
                qsTr("Capture USB In (stereo)"),
                qsTr("Capture USB In (left)"),
                qsTr("Capture USB In (right)"),
            ]
        }
        Repeater {
            model: 7
            QQC2.Button {
                Layout.fillWidth: true
                text: _private.newAudioSourceNames[model.index]
                checked: _private.newAudioSourceIndex === model.index
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        _private.newAudioSourceIndex = model.index;
                    }
                }
            }
        }
    }
}
