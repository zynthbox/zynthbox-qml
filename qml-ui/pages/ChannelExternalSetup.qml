/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

External mode editor page

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
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.6 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents

import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian

Zynthian.ScreenPage {
    id: component
    screenId: "channel_external_setup"
    title: qsTr("Track External Setup")
    property bool isVisible:zynqtgui.current_screen_id === "channel_external_setup"

    property var cuiaCallback: function(cuia) {
        let returnValue = false;
        if (contentLoader.item && contentLoader.item.hasOwnProperty("cuiaCallback")) {
            returnValue = contentLoader.item.cuiaCallback(cuia);
        }
        return returnValue;
    }
    Connections {
        target: applicationWindow()
        enabled: component.isVisible
        onSelectedChannelChanged: {
            if (applicationWindow().selectedChannel) {
                zynqtgui.callable_ui_action_simple("SCREEN_EDIT_CONTEXTUAL");
            }
        }
    }
    QtObject {
        id: _private
        property QtObject selectedChannel: null
    }
    Timer {
        id: selectedChannelThrottle
        interval: 1; running: false; repeat: false;
        onTriggered: {
            _private.selectedChannel = null;
            _private.selectedChannel = applicationWindow().selectedChannel;
            if (_private.selectedChannel) {
                if (_private.selectedChannel.externalSettings.selectedModule === "") {
                    // Use the default module if none has been selected
                    contentLoader.source = "ChannelExternalSetupDefaultModule.qml";
                } else {
                    // TODO When we have a list, use that list to check if the selected module exists, and if not, use the default module
                }
            } else {
                // No particular reason to do anything, this is a temporary state and we'll be getting a track shortly
            }
        }
    }
    Connections {
        target: applicationWindow()
        onSelectedChannelChanged: selectedChannelThrottle.restart()
    }
    Connections {
        target: zynqtgui.sketchpad
        onSongChanged: selectedChannelThrottle.restart()
    }
    Connections {
        target: zynqtgui.sketchpad.song
        onIsLoadingChanged: selectedChannelThrottle.restart()
    }
    Component.onCompleted: {
        selectedChannelThrottle.restart()
    }

    contextualActions: [
        Kirigami.Action {
            enabled: true
            text: qsTr("PICK MODULE")
            onTriggered: {
            }
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        }
    ]

    Item {
        anchors.fill: parent
        PlasmaComponents.BusyIndicator {
            visible: contentLoader.status == Loader.Loading
            anchors.centerIn: parent
            height: Kirigami.Units.gridUnit * 3
            width: height
            running: visible
            background: Item {} // Quiet some warnings
        }
        Loader {
            id: contentLoader
            anchors.fill: parent
            asynchronous: true
            visible: status == Loader.Ready
        }
    }
}
