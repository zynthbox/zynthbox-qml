/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

External midi channel picker component

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

import Zynthian 1.0 as Zynthian

Zynthian.DialogQuestion {
    id: root
    function pickChannel(channel) {
        _private.selectedChannel = channel;
        _private.newAudioSource = channel.externalAudioSource;
        open();
    }

    function cuiaCallback(cuia) {
        var returnValue = root.opened;
        switch (cuia) {
        case "SWITCH_BACK_SHORT":
        case "SWITCH_BACK_BOLD":
        case "SWITCH_BACK_LONG":
            root.close();
            returnValue = true;
            break;
        case "SWITCH_SELECT_SHORT":
            // pick the currently selected channel and close
            root.close();
            returnValue = true;
            break;
        }
        return returnValue;
    }
    rejectText: qsTr("Back")
    acceptText: qsTr("Select")
    onAccepted: {
        _private.selectedChannel.externalAudioSource = _private.newAudioSource;
    }

    ColumnLayout {
        anchors.fill: parent
        implicitWidth: Kirigami.Units.gridUnit * 50
        implicitHeight: Kirigami.Units.gridUnit * 25
        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: qsTr("Pick External Audio Source For Track %1").arg(_private.selectedChannel ? _private.selectedChannel.name : "")
 
            QtObject {
                id: _private
                property QtObject selectedChannel
                property string newAudioSource
            }
        }
        QQC2.Button {
            Layout.fillWidth: true
            text: qsTr("No External Audio Source")
            checked: _private.newAudioSource === ""
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    _private.newAudioSource = "";
                }
            }
        }
        QQC2.Button {
            Layout.fillWidth: true
            text: qsTr("Capture Microphone In")
            checked: _private.newAudioSource === "system"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    _private.newAudioSource = "system";
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
