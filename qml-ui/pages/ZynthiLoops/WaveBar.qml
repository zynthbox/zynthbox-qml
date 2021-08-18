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

    SidebarDial {
        id: bpmDial
        text: qsTr("BPM")
        controlObj: root.bottomBar.controlObj
        controlProperty: "bpm"

        dial {
            stepSize: 1
            from: 50
            to: 200
        }
    }

    SidebarDial {
        id: startDial
        text: qsTr("Start (msecs)")
        controlObj: root.bottomBar.controlObj
        controlProperty: "startPosition"
        valueString: Math.round(dial.value * 1000)

        dial {
            stepSize: 0.001
            from: 0
            to: controlObj && controlObj.hasOwnProperty("duration") ? controlObj.duration : 0
        }
    }

    SidebarDial {
        id: lengthDial
        text: qsTr("Length (beats)")
        controlObj: root.bottomBar.controlObj
        controlProperty: "length"

        dial {
            stepSize: 1
            from: 1
            to: 16
        }
    }

    SidebarDial {
        id: pitchDial
        text: qsTr("Pitch")
        controlObj: root.bottomBar.controlObj
        controlProperty: "pitch"

        dial {
            stepSize: 1
            from: -12
            to: 12
        }
    }

    SidebarDial {
        id: timeDial
        text: qsTr("Time")
        controlObj: root.bottomBar.controlObj
        controlProperty: "time"

        dial {
            stepSize: 1
            from: 0
            to: 200
        }
    }

    Item {
        Layout.fillWidth: true
    }

    GridLayout {
        columns: 2
        Layout.alignment: Qt.AlignBottom
        //Layout.maximumHeight: Kirigami.Units.iconSizes.large

        SidebarButton {
            icon.name: "document-open"
            visible: root.bottomBar.controlType === BottomBar.ControlType.Clip

            onClicked: {
                pickerDialog.open()
            }
        }

        SidebarButton {
            icon.name: "delete"
            visible: (controlObj != null) && controlObj.deletable

            onClicked: {
            }
        }

        SidebarButton {
            icon.name: "edit-clear-all"
            visible: (controlObj != null) && controlObj.clearable

            onClicked: controlObj.clear()
        }

        SidebarButton {
            icon.name: controlObj.isPlaying ? "media-playback-stop" : "media-playback-start"
            visible: (controlObj != null) && controlObj.playable

            onClicked: {
                if (controlObj.isPlaying) {
                    console.log("Stopping Sound Loop")
                    controlObj.stop();
                } else {
                    console.log("Playing Sound Loop")
                    controlObj.play();
                }
            }
        }

        SidebarButton {
            icon.name: "media-record"
            visible: (controlObj != null) && controlObj.recordable

            onClicked: {
            }
        }
    }
}

