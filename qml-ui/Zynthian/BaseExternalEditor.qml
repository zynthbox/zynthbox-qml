/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Base component for External mode editor page modules

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

import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian

Item {
    id: component
    readonly property bool isVisible:zynqtgui.current_screen_id === "channel_external_setup"
    readonly property QtObject externalSettings: _private.selectedChannel ? _private.selectedChannel.externalSettings : null
    readonly property QtObject selectedChannel: _private.selectedChannel
    readonly property QtObject sketchpadTrackInfo: _private.selectedChannel ? Zynthbox.MidiRouter.getSketchpadTrackInfo(_private.selectedChannel.id) : null
    property var cuiaCallback: function(cuia) { return false; }
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
}
