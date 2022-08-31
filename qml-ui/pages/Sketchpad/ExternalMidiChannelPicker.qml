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

QQC2.Popup {
    id: root
    function pickChannel(channel) {
        _private.selectedChannel = channel;
        open();
    }

    exit: null; enter: null; // Disable the enter and exit transition animations. TODO This really wants doing somewhere central...
    modal: true
    focus: true
    parent: QQC2.Overlay.overlay
    y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
    x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
    closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

    function cuiaCallback(cuia) {
        var returnValue = false;
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

    ColumnLayout {
        anchors.fill: parent
        implicitWidth: Kirigami.Units.gridUnit * 50
        implicitHeight: Kirigami.Units.gridUnit * 25
        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: qsTr("Pick External Midi Channel For Channel %1").arg(_private.selectedChannel ? _private.selectedChannel.name : "")
 
            QtObject {
                id: _private
                property QtObject selectedChannel
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 1
            Layout.maximumHeight: 1
            color: Kirigami.Theme.textColor
            opacity: 0.5
        }
        GridLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            columns: 4
            Repeater {
                model: _private.selectedChannel ? 16 : 0
                delegate: Zynthian.PlayGridButton {
                    id: channelDelegate
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                    text: _private.selectedChannel.externalMidiChannel === model.index
                        ? qsTr("Reset to default from %1").arg(model.index + 1)
                        : qsTr("Set to channel %1").arg(model.index + 1)
                    onClicked: {
                        if (_private.selectedChannel.externalMidiChannel === model.index) {
                            _private.selectedChannel.externalMidiChannel = -1;
                        } else {
                            _private.selectedChannel.externalMidiChannel = model.index;
                        }
                        root.close();
                    }
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 1
            Layout.maximumHeight: 1
            color: Kirigami.Theme.textColor
            opacity: 0.5
        }
        QQC2.Button {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Close"
            onClicked: {
                root.close();
            }
        }
    }
}
