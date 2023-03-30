/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

Copyright (C) 2021 Marco Martin <mart@kde.org>

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

import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1
import org.kde.kirigami 2.6 as Kirigami

ColumnLayout {
    id: component
    objectName: "clipPickerFile"

    property bool isRecording: zynqtgui.main.isRecording
    function startRecording() {
        // If the current module is an alsa thing, don't use jack to record it and instead record using alsa
        if (zynqtgui.main.currentModuleRecordAlsa === true) {
            zynqtgui.main.start_recording_alsa();
        } else {
            zynqtgui.main.start_recording();
        }
    }
    function stopRecording() {
        zynqtgui.main.stop_recording();
    }

    Kirigami.Heading {
        Layout.fillWidth: true
        text: qsTr("Save Recordings To A File");
    }
    QQC2.Label {
        Layout.fillWidth: true
        Layout.fillHeight: true
        wrapMode: Text.Wrap
        text: qsTr("Recordings from this module will be stored in your current sketchpad's wav folder. They will be given the name of the module, with a timestamp so you can tell your recordings apart by when you made them.")
    }
    QQC2.Label {
        Layout.fillWidth: true
        visible: zynqtgui.main.mostRecentRecordingFile != ""
        wrapMode: Text.Wrap
        text: qsTr("Your most recent recording is:\n%1").arg(zynqtgui.main.mostRecentRecordingFile)
    }
    RowLayout {
        Layout.fillWidth: true
        QQC2.Button {
            Layout.fillWidth: true
            visible: zynqtgui.main.mostRecentRecordingFile != ""
            text: qsTr("Discard Recording")
            onClicked: {
                zynqtgui.main.discardMostRecentRecording();
            }
        }
        QQC2.Button {
            Layout.fillWidth: true
            visible: zynqtgui.main.mostRecentRecordingFile != ""
            text: zynqtgui.main.isPlaying ? qsTr("Stop Playback") : qsTr("Play Recording")
            onClicked: {
                if (zynqtgui.main.isPlaying) {
                    zynqtgui.main.stopMostRecentRecordingPlayback();
                } else {
                    zynqtgui.main.playMostRecentRecording();
                }
            }
        }
    }
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}
