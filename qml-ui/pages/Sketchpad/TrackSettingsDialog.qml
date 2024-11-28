/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI



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
    function showTrackSettings(track) {
        _private.selectedTrack = track;
        trackNameField.text = track.name;
        trackAllowMulticlipField.checked = track.allowMulticlip;
        open();
    }

    property var cuiaCallback: function(cuia) {
        var returnValue = root.opened;
        // console.log("TrackSettingsDialog cuia:", cuia);
        switch (cuia) {
        case "KNOB3_UP":
            returnValue = true;
            break;
        case "KNOB3_DOWN":
            returnValue = true;
            break;
        case "SWITCH_BACK_SHORT":
        case "SWITCH_BACK_BOLD":
            root.reject();
            returnValue = true;
            break;
        case "SWITCH_SELECT_SHORT":
            root.accept();
            returnValue = true;
            break;
        }
        return returnValue;
    }
    rejectText: qsTr("Back")
    acceptText: qsTr("Select")
    title: qsTr("Settings for Track %1").arg(_private.selectedTrack ? _private.selectedTrack.name : "")
    width: Kirigami.Units.gridUnit * 30
    height: Kirigami.Units.gridUnit * 15
    onAccepted: {
        if (trackNameField.text == "") {
            // Don't allow people to set an empty track name, that's just silly
            _private.selectedTrack.name = "T%1".arg(_private.selectedTrack.id + 1);
        } else {
            _private.selectedTrack.name = trackNameField.text;
        }
        _private.selectedTrack.allowMulticlip = trackAllowMulticlipField.checked;
    }

    contentItem: Kirigami.FormLayout {
        QtObject {
            id: _private
            property QtObject selectedTrack
            property string trackName
        }
        QQC2.TextField {
            id: trackNameField
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 5
            Kirigami.FormData.label: qsTr("Track Name:")
        }
        QQC2.Switch {
            id: trackAllowMulticlipField
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 5
            implicitWidth: Kirigami.Units.gridUnit * 5
            Layout.minimumWidth: Kirigami.Units.gridUnit * 5
            Kirigami.FormData.label: qsTr("Allow Multiple Enabled Clips:")
        }
    }
}