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

import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian

// GridLayout so TabbedControlView knows how to navigate it
ColumnLayout {
    id: root
    Layout.fillWidth: true
    Layout.maximumWidth: parent.width

    property QtObject bottomBar: null
    property string controlType: zynqtgui.bottomBarControlType
    property QtObject controlObj: null;
    property QtObject clipAudioSource: root.controlObj ? Zynthbox.PlayGridManager.getClipById(root.controlObj.cppObjId) : null
    property bool controlObjIsManual: false
    Timer {
        id: controlObjUpdater
        interval: 1; repeat: false; running: false;
        onTriggered: {
            if (controlObjIsManual == false) {
                root.controlObj = (root.controlType === "bottombar-controltype-clip" || root.controlType === "bottombar-controltype-pattern")
                    ? zynqtgui.bottomBarControlObj // selected bottomBar object is clip/pattern
                    : zynqtgui.bottomBarControlObj && zynqtgui.bottomBarControlObj.hasOwnProperty("samples") && zynqtgui.bottomBarControlObj.hasOwnProperty("selectedSlotRow") // selected bottomBar object is not clip/pattern and hence it is a channel
                        ? zynqtgui.bottomBarControlObj.samples[zynqtgui.bottomBarControlObj.selectedSlotRow]
                        : null
            }
        }
    }
    Connections {
        target: zynqtgui
        onBottomBarControlObjChanged: controlObjUpdater.restart()
    }
    Connections {
        target: zynqtgui.bottomBarControlObj && zynqtgui.bottomBarControlObj.hasOwnProperty("samples") && zynqtgui.bottomBarControlObj.hasOwnProperty("selectedSlotRow") ? zynqtgui.bottomBarControlObj : null
        onSamplesChanged: controlObjUpdater.restart()
        onSelectedSlotRowChanged: controlObjUpdater.restart()
    }
    onControlTypeChanged: controlObjUpdater.restart()
    property QtObject selectedChannel: null
    Timer {
        id: selectedChannelThrottle
        interval: 0; running: false; repeat: false;
        onTriggered: {
            root.selectedChannel = applicationWindow().selectedChannel;
        }
    }
    Connections {
        target: applicationWindow()
        onSelectedChannelChanged: selectedChannelThrottle.restart()
    }
    Component.onCompleted: {
        selectedChannelThrottle.restart()
    }
    property bool showCopyPasteButtons: true

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "KNOB0_TOUCHED":
            case "KNOB1_TOUCHED":
            case "KNOB2_TOUCHED":
            case "KNOB3_TOUCHED":
                return true;
            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.channelButton.checked = true
                return true;
            case "KNOB0_UP":
                if (root.clipAudioSource) {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        root.clipAudioSource.selectedSliceObject.pan = root.clipAudioSource.selectedSliceObject.pan + 0.01;
                    } else {
                        root.clipAudioSource.selectedSliceObject.gainHandler.gainAbsolute = root.clipAudioSource.selectedSliceObject.gainHandler.gainAbsolute + 0.01;
                    }
                }
                return true;
            case "KNOB0_DOWN":
                if (root.clipAudioSource) {
                    if (zynqtgui.modeButtonPressed) {
                        zynqtgui.ignoreNextModeButtonPress = true;
                        root.clipAudioSource.selectedSliceObject.pan = root.clipAudioSource.selectedSliceObject.pan - 0.01;
                    } else {
                        root.clipAudioSource.selectedSliceObject.gainHandler.gainAbsolute = root.clipAudioSource.selectedSliceObject.gainHandler.gainAbsolute - 0.01;
                    }
                }
                return true;
            case "KNOB1_UP":
                if (zynqtgui.modeButtonPressed) {
                    zynqtgui.ignoreNextModeButtonPress = true;
                    pageManager.getPage("sketchpad").updateClipPitch(root.controlObj, 0.01)
                } else {
                    pageManager.getPage("sketchpad").updateClipPitch(root.controlObj, 1)
                }
                return true;
            case "KNOB1_DOWN":
                if (zynqtgui.modeButtonPressed) {
                    zynqtgui.ignoreNextModeButtonPress = true;
                    pageManager.getPage("sketchpad").updateClipPitch(root.controlObj, -0.01)
                } else {
                    pageManager.getPage("sketchpad").updateClipPitch(root.controlObj, -1)
                }
                return true;
            case "KNOB2_UP":
                pageManager.getPage("sketchpad").updateClipSpeedRatio(root.controlObj, 1)
                return true;
            case "KNOB2_DOWN":
                pageManager.getPage("sketchpad").updateClipSpeedRatio(root.controlObj, -1)
                return true;
            case "KNOB3_UP":
                pageManager.getPage("sketchpad").updateClipBpm(root.controlObj, 1)
                return true;
            case "KNOB3_DOWN":
                pageManager.getPage("sketchpad").updateClipBpm(root.controlObj, -1)
                return true;
        }

        return false;
    }

    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.maximumHeight: Kirigami.Units.gridUnit * 10
        Zynthian.SketchpadDial {
            id: gainDial
            text: qsTr("Gain (dB)") + "\n"
            controlObj: root.clipAudioSource ? root.clipAudioSource.selectedSliceObject.gainHandler : null
            controlProperty: "gainAbsolute"
            valueString: root.clipAudioSource ? qsTr("%1 dB").arg(root.clipAudioSource.selectedSliceObject.gainHandler.gainDb.toFixed(2)) : 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5

            dial {
                stepSize: 0.01
                from: 0
                to: 1
            }

            onDoubleClicked: {
                root.clipAudioSource.selectedSliceObject.gainHandler.gainDb = root.controlObj.initialGain;
            }
        }

        Zynthian.SketchpadDial {
            id: panDial
            text: qsTr("Pan") + "\n"
            controlObj: root.clipAudioSource ? root.clipAudioSource.selectedSliceObject : null
            controlProperty: "pan"
            valueString: root.clipAudioSource ? root.clipAudioSource.selectedSliceObject.pan.toFixed(2) : 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5

            dial {
                stepSize: 0.01
                from: -1
                to: 1
            }

            onDoubleClicked: {
                root.clipAudioSource.selectedSliceObject.pan = 0;
            }
        }

        Zynthian.SketchpadDial {
            id: pitchDial
            text: qsTr("Pitch") + "\n"
            controlObj: root.clipAudioSource ? root.clipAudioSource.selectedSliceObject : null
            controlProperty: "pitch"
            fixedPointTrail: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5

            dial {
                stepSize: 1
                from: -48
                to: 48
            }

            onDoubleClicked: {
                root.clipAudioSource.selectedSliceObject.pitch = root.controlObj.initialPitch;
            }
        }

        Zynthian.SketchpadDial {
            id: timeDial
            text: qsTr("Speed Ratio") + "\n"
            controlObj: root.clipAudioSource
            controlProperty: "speedRatio"
            valueString: dial.value.toFixed(2)
            enabled: timeDial.controlObj ? !timeDial.controlObj.autoSynchroniseSpeedRatio : false
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5

            dial {
                stepSize: 0.1
                from: 0.5
                to: 2
            }

            onDoubleClicked: {
                root.clipAudioSource.speedRatio = root.controlObj.initialSpeedRatio;
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            RowLayout {
                Item {
                    Layout.fillWidth: true
                }
                QQC2.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("BPM")
                }
                QQC2.Button {
                    text: "🎜"
                    enabled: root.controlObj ? true : false
                    onClicked: {
                        zynqtgui.start_loading();
                        zynqtgui.currentTaskMessage = "Attempting to determine BPM within selected playback area";
                        bpmGuessedDialog.guessedBPM = root.clipAudioSource.guessBPM(-1); // -1 being the "global" slice
                        bpmGuessedDialog.open();
                        zynqtgui.stop_loading();
                    }
                    Zynthian.DialogQuestion {
                        id: bpmGuessedDialog
                        property double guessedBPM: 0
                        title: "Estimated BPM"
                        text: "The estimated BPM was %1\nWould you like to set that as the new BPM for this clip, changing it from %2?".arg(bpmGuessedDialog.guessedBPM).arg(root.clipAudioSource ? root.clipAudioSource.bpm : 0)
                        acceptText: "Yes: Set clip BPM to %1".arg(bpmGuessedDialog.guessedBPM)
                        rejectText: "No"
                        onAccepted: {
                            root.clipAudioSource.bpm = bpmGuessedDialog.guessedBPM;
                        }
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
            }

            QQC2.TextField {
                id: objBpmEdit
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: TextInput.AlignHCenter
                focus: false
                text: enabled
                        ? root.clipAudioSource ? (root.clipAudioSource.bpm <= 0 ? "" : root.clipAudioSource.bpm) : ""
                        : ""
                // validator: DoubleValidator {bottom: 1; top: 250; decimals: 2}

                /** Float Matching : Matches exactly one '0' after decimal point
                *                  or a maximum of two digits
                */
                validator: RegExpValidator { regExp: /^[0-9]*(\.(0{0}|0[1-9]{0,1}|[1-9]{0,2}))?$/ }
                inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
                activeFocusOnTab: false
                enabled: root.clipAudioSource ? true : false
                onTextChanged: {
                    var newValue = parseFloat(text);
                    if (text !== "" && root.clipAudioSource.bpm !== newValue) {
                        root.clipAudioSource.bpm = newValue;
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            QQC2.Switch {
                id: syncSwitch
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                checked: root.clipAudioSource ? root.clipAudioSource.autoSynchroniseSpeedRatio : false
                enabled: root.clipAudioSource && root.clipAudioSource.bpm > 0 // This also ensures we check that it actually exists, since a null or undefined also becomes a zero for numerical comparisons
                onToggled: {
                    root.clipAudioSource.autoSynchroniseSpeedRatio = checked
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                horizontalAlignment: TextInput.AlignHCenter
                text: qsTr("Auto-Sync\nSpeed Ratio")
            }
        }

        // ColumnLayout {
        //     Layout.fillHeight: true
        //     Layout.fillWidth: false
        //     Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        //     visible: root.showCopyPasteButtons
        //
        //     QQC2.Button {
        //         Layout.alignment: Qt.AlignCenter
        //
        //         text: qsTr("Copy Clip")
        //         visible: bottomBar ? (bottomBar.clipCopySource == null) : false
        //         onClicked: {
        //             bottomBar.clipCopySource = root.controlObj;
        //         }
        //     }
        //
        //     QQC2.Button {
        //         Layout.alignment: Qt.AlignCenter
        //
        //         text: qsTr("Paste Clip")
        //         visible: bottomBar ? (bottomBar.clipCopySource != null) : false
        //         enabled: bottomBar ? (bottomBar.clipCopySource != root.controlObj) : false
        //         onClicked: {
        //             root.controlObj.copyFrom(bottomBar.clipCopySource);
        //             bottomBar.clipCopySource = null;
        //         }
        //     }
        // }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5

            QQC2.Button {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                visible: root.selectedChannel ? root.selectedChannel.trackType !== "sample-loop" : false
                text: root.clipAudioSource ? qsTr("Playback Style:\n%1").arg(root.clipAudioSource.selectedSliceObject.playbackStyleLabel) : ""
                onClicked: {
                    playbackStylePicker.open();
                }
                Zynthian.ActionPickerPopup {
                    id: playbackStylePicker
                    actions: [
                        Kirigami.Action {
                            text: root.clipAudioSource
                                ? root.clipAudioSource.selectedSliceObject.playbackStyle === Zynthbox.ClipAudioSource.NonLoopingPlaybackStyle
                                    ? qsTr("<b>Inherit from Clip</b><br />(currently %1)").arg(root.clipAudioSource.rootSlice.playbackStyleLabel)
                                    : qsTr("Inherit from Clip\n(currently %1)").arg(root.clipAudioSource.rootSlice.playbackStyleLabel)
                                : qsTr("No Clip")
                            visible: root.clipAudioSource && root.clipAudioSource.selectedSliceObject.isRootSlice === false
                            onTriggered: {
                                root.clipAudioSource.selectedSliceObject.playbackStyle = Zynthbox.ClipAudioSource.NonLoopingPlaybackStyle;
                            }
                        },
                        Kirigami.Action {
                            text: root.clipAudioSource && root.clipAudioSource.selectedSliceObject.playbackStyle === Zynthbox.ClipAudioSource.NonLoopingPlaybackStyle
                                ? qsTr("<b>Non-looping</b>")
                                : qsTr("Non-looping")
                            onTriggered: {
                                root.clipAudioSource.selectedSliceObject.playbackStyle = Zynthbox.ClipAudioSource.NonLoopingPlaybackStyle;
                            }
                        },
                        Kirigami.Action {
                            text: root.clipAudioSource && root.clipAudioSource.selectedSliceObject.playbackStyle === Zynthbox.ClipAudioSource.LoopingPlaybackStyle
                                ? qsTr("<b>Looping</b>")
                                : qsTr("Looping")
                            onTriggered: {
                                root.clipAudioSource.selectedSliceObject.playbackStyle = Zynthbox.ClipAudioSource.LoopingPlaybackStyle;
                            }
                        },
                        Kirigami.Action {
                            text: root.clipAudioSource && root.clipAudioSource.selectedSliceObject.playbackStyle === Zynthbox.ClipAudioSource.OneshotPlaybackStyle
                                ? qsTr("<b>One-shot</b>")
                                : qsTr("One-shot")
                            onTriggered: {
                                root.clipAudioSource.selectedSliceObject.playbackStyle = Zynthbox.ClipAudioSource.OneshotPlaybackStyle;
                            }
                        },
                        Kirigami.Action {
                            text: root.clipAudioSource && root.clipAudioSource.selectedSliceObject.playbackStyle === Zynthbox.ClipAudioSource.WavetableStyle
                                ? qsTr("<b>Wavetable</b>")
                                : qsTr("Wavetable")
                            onTriggered: {
                                root.clipAudioSource.selectedSliceObject.playbackStyle = Zynthbox.ClipAudioSource.WavetableStyle;
                            }
                        },
                        Kirigami.Action {
                            text: root.clipAudioSource && root.clipAudioSource.selectedSliceObject.playbackStyle === Zynthbox.ClipAudioSource.GranularNonLoopingPlaybackStyle
                                ? qsTr("<b>Granular Non-looping</b><br />(experimental)")
                                : qsTr("Granular Non-looping\n(experimental)")
                            onTriggered: {
                                root.clipAudioSource.selectedSliceObject.playbackStyle = Zynthbox.ClipAudioSource.GranularNonLoopingPlaybackStyle;
                            }
                        },
                        Kirigami.Action {
                            text: root.clipAudioSource && root.clipAudioSource.selectedSliceObject.playbackStyle === Zynthbox.ClipAudioSource.GranularLoopingPlaybackStyle
                                ? qsTr("<b>Granular Looping</b><br />(experimental)")
                                : qsTr("Granular Looping\n(experimental)")
                            onTriggered: {
                                root.clipAudioSource.selectedSliceObject.playbackStyle = Zynthbox.ClipAudioSource.GranularLoopingPlaybackStyle;
                            }
                        }
                    ]
                }
            }
            QQC2.Button {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                text: root.clipAudioSource
                    ? root.clipAudioSource.selectedSliceObject.timeStretchStyle === Zynthbox.ClipAudioSource.TimeStretchBetter
                        ? "Pitch Shifting:\nHQ Timestretched"
                        : root.clipAudioSource.selectedSliceObject.timeStretchStyle === Zynthbox.ClipAudioSource.TimeStretchStandard
                            ? "Pitch Shifting:\nTimestretched"
                            : "Pitch Shifting:\nStandard"
                    : ""
                onClicked: {
                    timeStretchingPopup.open();
                }
                Zynthian.ActionPickerPopup {
                    id: timeStretchingPopup
                    actions: [
                        Kirigami.Action {
                            text: root.clipAudioSource && root.clipAudioSource.selectedSliceObject.timeStretchStyle === Zynthbox.ClipAudioSource.TimeStretchBetter
                                ? qsTr("<b>HQ Timestretch Pitch Shift</b><br />(retains sample length<br />slower, better quality)")
                                : qsTr("HQ Timestretch Pitch Shift\n(retains sample length,\nmost cpu, better quality)")
                            onTriggered: {
                                root.clipAudioSource.selectedSliceObject.timeStretchStyle = Zynthbox.ClipAudioSource.TimeStretchBetter;
                            }
                        },
                        Kirigami.Action {
                            text: root.clipAudioSource && root.clipAudioSource.selectedSliceObject.timeStretchStyle === Zynthbox.ClipAudioSource.TimeStretchStandard
                                ? qsTr("<b>Timestretch Pitch Shift</b><br />(retains sample length<br />faster, good quality)")
                                : qsTr("Timestretch Pitch Shift\n(retains sample length,\nmore cpu, good quality)")
                            onTriggered: {
                                root.clipAudioSource.selectedSliceObject.timeStretchStyle = Zynthbox.ClipAudioSource.TimeStretchStandard;
                            }
                        },
                        Kirigami.Action {
                            text: root.clipAudioSource && root.clipAudioSource.selectedSliceObject.timeStretchStyle === Zynthbox.ClipAudioSource.TimeStretchOff
                                ? qsTr("<b>Standard Pitch Shift</b><br />(changes playback length,<br />least cpu, highest quality)")
                                : qsTr("Standard Pitch Shift\n(changes playback length\nleast cpu, best quality)")
                            onTriggered: {
                                root.clipAudioSource.selectedSliceObject.timeStretchStyle = Zynthbox.ClipAudioSource.TimeStretchOff;
                            }
                        }
                    ]
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            QQC2.Switch {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                checked: root.clipAudioSource ? root.clipAudioSource.selectedSliceObject.snapLengthToBeat : true
                onToggled: {
                    root.clipAudioSource.selectedSliceObject.snapLengthToBeat = checked
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.selectedChannel ? root.selectedChannel.trackType === "sample-loop" : false
            }
            QQC2.Label {
                Layout.fillWidth: true
                horizontalAlignment: TextInput.AlignHCenter
                wrapMode: Text.Wrap
                text: qsTr("Snap Length\nto Beat")
            }
        }
    }

    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}

