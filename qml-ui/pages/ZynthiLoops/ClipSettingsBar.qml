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

    Zynthian.ZynthiloopsDial {
        id: startDial
        text: qsTr("Start (secs)")
        controlObj: root.bottomBar.controlObj
        controlProperty: "startPosition"
        valueString: dial.value.toFixed(2)
        buttonStepSize: 0.01

        dial {
            stepSize: controlObj.hasOwnProperty("secPerBeat") ? controlObj.secPerBeat : 0.01
            from: 0
            to: controlObj && controlObj.hasOwnProperty("duration") ? controlObj.duration : 0
        }
    }

    Zynthian.ZynthiloopsDial {
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

    Zynthian.ZynthiloopsDial {
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

    Zynthian.ZynthiloopsDial {
        id: timeDial
        text: qsTr("Speed Ratio")
        controlObj: root.bottomBar.controlObj
        controlProperty: "time"
        valueString: dial.value.toFixed(2)
        enabled: !root.bottomBar.controlObj.shouldSync

        dial {
            stepSize: 0.1
            from: 0.5
            to: 2
        }
    }

    Zynthian.ZynthiloopsDial {
        id: gainDial
        text: qsTr("Loudness (dB)")
        controlObj: root.bottomBar.controlObj
        controlProperty: "gain"
        valueString: dial.value.toFixed(1)

        dial {
            stepSize: 1
            from: -24
            to: 8
        }
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 6

        QQC2.Label {
            Layout.alignment: Qt.AlignCenter
            text: qsTr("BPM")
        }

        QQC2.TextField {
            id: objBpmEdit
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: TextInput.AlignHCenter
            focus: false
            text: root.bottomBar.controlObj.bpm <= 0 ? "" : root.bottomBar.controlObj.bpm.toFixed(2)
            // validator: DoubleValidator {bottom: 1; top: 250; decimals: 2}

            /** Float Matching : Matches exactly one '0' after decimal point
              *                  or a maximum of two digits
              */
            validator: RegExpValidator { regExp: /^[0-9]*(\.(0{0}|0[1-9]{0,1}|[1-9]{0,2}))?$/ }
            inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
            enabled: !root.bottomBar.controlObj.shouldSync
            onAccepted: {
                root.bottomBar.controlObj.bpm = parseFloat(text);
            }
            onPressed: {
                forceActiveFocus()
            }
            Connections {
                target: Qt.inputMethod
                onVisibleChanged: {
                    if (!Qt.inputMethod.visible) {
                        syncSwitch.forceActiveFocus()
                    }
                }
            }
        }

        QQC2.Switch {
            id: syncSwitch
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            checked: root.bottomBar.controlObj.shouldSync
            onToggled: {
                root.bottomBar.controlObj.shouldSync = checked
            }
        }

        QQC2.Label {
            Layout.alignment: Qt.AlignCenter
            text: qsTr("Sync")
        }
    }

    Item {
        Layout.fillWidth: true
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignRight | Qt.AlignBottom

        QQC2.Label {
            visible: controlObj.soundData.length <= 0
            text: "<No Metadata>"
        }
        QQC2.Label {
            visible: root.bottomBar.controlType === BottomBar.ControlType.Clip && controlObj.path.length > 0
            text: qsTr("BPM: %1").arg(controlObj.metadataBPM ? controlObj.metadataBPM : "--")
        }
        QQC2.Label {
            visible: root.bottomBar.controlType === BottomBar.ControlType.Clip && controlObj.path.length > 0 && controlObj.metadataAudioType
            text: qsTr("Audio Type: %1").arg(controlObj.metadataAudioType ? controlObj.metadataAudioType : "")
        }
        QQC2.Label {
            visible: root.bottomBar.controlType === BottomBar.ControlType.Clip && controlObj.path.length > 0
            text: qsTr("Duration: %1 secs").arg(controlObj && controlObj.duration ? controlObj.duration.toFixed(2) : 0.0)
        }
        QQC2.Label {
            Layout.fillWidth: true
            visible: root.bottomBar.controlType === BottomBar.ControlType.Clip
            elide: Text.ElideMiddle
            text: {
                if (!controlObj || !controlObj.path) {
                    return qsTr("No File Loaded");
                }
                var arr = controlObj.path.split('/');
                return qsTr("File: %1").arg(arr[arr.length - 1]);
            }
        }
    }
}

