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
    Layout.maximumWidth: parent.width

    property QtObject bottomBar: null
    property QtObject controlObj: (bottomBar.controlType === BottomBar.ControlType.Clip || bottomBar.controlType === BottomBar.ControlType.Pattern)
                                    ? bottomBar.controlObj // selected bottomBar object is clip/pattern
                                    : bottomBar.controlObj && bottomBar.controlObj.samples && bottomBar.controlObj.selectedSlotRow // selected bottomBar object is not clip/pattern and hence it is a channel
                                        ? bottomBar.controlObj.samples[bottomBar.controlObj.selectedSlotRow]
                                        : null

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.channelButton.checked = true
                return true;
        }
        
        return false;
    }

    Zynthian.SketchpadDial {
        id: startDial
        text: qsTr("Start (secs)")
        controlObj: root.controlObj
        controlProperty: "startPosition"
        valueString: dial.value.toFixed(2)
        buttonStepSize: 0.01
        Layout.fillWidth: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        Layout.maximumHeight: Kirigami.Units.gridUnit * 8

        dial {
            stepSize: root.controlObj && root.controlObj.hasOwnProperty("secPerBeat") ? root.controlObj.secPerBeat : 0.01
            from: 0
            to: root.controlObj && root.controlObj.hasOwnProperty("duration") ? root.controlObj.duration : 0
        }

        onDoubleClicked: {
            root.controlObj.startPosition = root.controlObj.initialStartPosition;
        }
    }

    Zynthian.SketchpadDial {
        id: lengthDial
        text: qsTr("Length (beats)")
        controlObj: root.controlObj
        controlProperty: "length"
        valueString: dial.value.toFixed(2)
        Layout.fillWidth: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        Layout.maximumHeight: Kirigami.Units.gridUnit * 8

        dial {
            stepSize: 1
            from: 1
            to: 64
        }

        onDoubleClicked: {
            root.controlObj.length = root.controlObj.initialLength;
        }
    }

    Zynthian.SketchpadDial {
        id: pitchDial
        text: qsTr("Pitch")
        controlObj: root.controlObj
        controlProperty: "pitch"
        Layout.fillWidth: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        Layout.maximumHeight: Kirigami.Units.gridUnit * 8

        dial {
            stepSize: 1
            from: -12
            to: 12
        }

        onDoubleClicked: {
            root.controlObj.pitch = root.controlObj.initialPitch;
        }
    }

    Zynthian.SketchpadDial {
        id: timeDial
        text: qsTr("Speed Ratio")
        controlObj: root.controlObj
        controlProperty: "time"
        valueString: dial.value.toFixed(2)
        enabled: root.controlObj ? !root.controlObj.shouldSync : false
        Layout.fillWidth: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        Layout.maximumHeight: Kirigami.Units.gridUnit * 8

        dial {
            stepSize: 0.1
            from: 0.5
            to: 2
        }

        onDoubleClicked: {
            root.controlObj.time = root.controlObj.initialTime;
        }
    }

    Zynthian.SketchpadDial {
        id: gainDial
        text: qsTr("Loudness (dB)")
        controlObj: root.controlObj
        controlProperty: "gain"
        valueString: dial.value.toFixed(1)
        Layout.fillWidth: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        Layout.maximumHeight: Kirigami.Units.gridUnit * 8

        dial {
            stepSize: 1
            from: -24
            to: 8
        }

        onDoubleClicked: {
            root.controlObj.gain = root.controlObj.initialGain;
        }
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5

        QQC2.Label {
            Layout.alignment: Qt.AlignCenter
            text: qsTr("BPM")
        }

        QQC2.Label {
            Layout.alignment: Qt.AlignCenter
            visible: root.controlObj && root.controlObj.metadataBPM ? true : false
            text: root.controlObj && root.controlObj.hasOwnProperty("metadataBPM") ? root.controlObj.metadataBPM : ""
            font.pointSize: 9
        }

        QQC2.TextField {
            id: objBpmEdit
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: TextInput.AlignHCenter
            focus: false
            text: root.controlObj && root.controlObj.bpm ? (root.controlObj.bpm <= 0 ? "" : root.controlObj.bpm.toFixed(2)) : ""
            // validator: DoubleValidator {bottom: 1; top: 250; decimals: 2}

            /** Float Matching : Matches exactly one '0' after decimal point
              *                  or a maximum of two digits
              */
            validator: RegExpValidator { regExp: /^[0-9]*(\.(0{0}|0[1-9]{0,1}|[1-9]{0,2}))?$/ }
            inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
            enabled: root.controlObj ? !root.controlObj.shouldSync : false
            onAccepted: {
                root.controlObj.bpm = parseFloat(text);
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
            implicitWidth: Kirigami.Units.gridUnit * 3
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            checked: root.controlObj && root.controlObj.hasOwnProperty("shouldSync") ? root.controlObj.shouldSync : false
            onToggled: {
                root.controlObj.shouldSync = checked
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            horizontalAlignment: TextInput.AlignHCenter
            text: qsTr("Sync")
        }
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5

        QQC2.Button {
            Layout.alignment: Qt.AlignCenter

            text: qsTr("Copy Clip")
            visible: bottomBar.clipCopySource == null
            onClicked: {
                bottomBar.clipCopySource = root.controlObj;
            }
        }

        QQC2.Button {
            Layout.alignment: Qt.AlignCenter

            text: qsTr("Paste Clip")
            visible: bottomBar.clipCopySource != null
            enabled: bottomBar.clipCopySource != root.controlObj
            onClicked: {
                root.controlObj.copyFrom(bottomBar.clipCopySource);
                bottomBar.clipCopySource = null;
            }
        }
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5

        QQC2.Switch {
            id: snapLengthToBeatSwitch
            Layout.alignment: Qt.AlignCenter
            implicitWidth: Kirigami.Units.gridUnit * 3
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            checked: root.controlObj && root.controlObj.hasOwnProperty("snapLengthToBeat") ? root.controlObj.snapLengthToBeat : true
            onToggled: {
                root.controlObj.snapLengthToBeat = checked
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            horizontalAlignment: TextInput.AlignHCenter
            wrapMode: Text.Wrap
            text: qsTr("Snap Length to beat")
        }
    }

    //Item {
        //Layout.fillWidth: true
    //}

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignRight | Qt.AlignBottom
        Layout.preferredWidth: Kirigami.Units.gridUnit * 6

        QQC2.Label {
            visible: root.controlObj && root.controlObj.soundData ? root.controlObj.soundData.length <= 0 : false
            text: "<No Metadata>"
        }
        QQC2.Label {
            visible: root.bottomBar.controlType === BottomBar.ControlType.Clip && root.controlObj.path.length > 0 && root.controlObj.metadataAudioType
            text: qsTr("Audio Type: %1").arg(root.controlObj && root.controlObj.metadataAudioType ? root.controlObj.metadataAudioType : "")
        }
        QQC2.Label {
            visible: root.bottomBar.controlType === BottomBar.ControlType.Clip && root.controlObj.path.length > 0
            text: qsTr("Duration: %1 secs").arg(root.controlObj && root.controlObj.duration ? root.controlObj.duration.toFixed(2) : 0.0)
        }
    }
}

