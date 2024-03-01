/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Routing Style Picker, for picking the basic decision profile for routing the audio of sound sources and fx

Copyright (C) 2023 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.DialogQuestion {
    id: component
    function pickRoutingStyle(channel) {
        _private.selectedChannel = channel;
        _private.newRoutingStyle = channel.channelRoutingStyle;
        component.open();
    }
    onAccepted: {
        if (_private.selectedChannel.channelRoutingStyle !== _private.newRoutingStyle) {
            _private.selectedChannel.channelRoutingStyle = _private.newRoutingStyle;
        }
    }
    height: Kirigami.Units.gridUnit * 18
    width: Kirigami.Units.gridUnit * 35
    acceptText: qsTr("Select")
    rejectText: qsTr("Back")
    title: qsTr("Pick Audio Routing Style For Track %1").arg(_private.selectedChannel ? _private.selectedChannel.name : "")

    ColumnLayout {
        anchors {
            fill: parent
            margins: Kirigami.Units.largeSpacing
        }
        QtObject {
            id: _private
            property QtObject selectedChannel
            property string newRoutingStyle
        }
        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("Serial Routing")
                checked: _private.newRoutingStyle === "standard"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        _private.newRoutingStyle = "standard";
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit
                text: qsTr("One-to-One Routing")
                checked: _private.newRoutingStyle === "one-to-one"
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        _private.newRoutingStyle = "one-to-one";
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Image {
                anchors {
                    fill: parent;
                    margins: Kirigami.Units.largeSpacing;
                }
                fillMode: Image.PreserveAspectFit
                source: {
                    if (_private.newRoutingStyle === "standard") {
                        return "../../../img/routing-style-serial.png";
                    } else if (_private.newRoutingStyle === "one-to-one") {
                        return "../../../img/routing-style-one-to-one.png";
                    }
                    return "";
                }
            }
        }
    }
}
