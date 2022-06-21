/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian recording popup

Copyright (C) 2022 Anupam Basak <anupam.basak27@gmail.com>

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
import QtQuick.Controls.Styles 1.4

import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami


import libzl 1.0 as ZL
import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

QQC2.Popup {
    id: root
    property QtObject selectedTrack: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)

    exit: null; enter: null; // Disable the enter and exit transition animations. TODO This really wants doing somewhere central...
    modal: true
    focus: true
    parent: QQC2.Overlay.overlay
    y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
    x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
    closePolicy: !root.selectedTrack.sceneClip.isRecording ? (QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside) : QQC2.Popup.NoAutoClose

    onOpenedChanged: {
        if (opened) {
            // Report dialog open to zynthian for passing cuia events to dialog
            zynthian.openedDialog = root
        } else {
            // Report dialog close to zynthian to stop receiving cuia events
            if (zynthian.openedDialog === root) {
                zynthian.openedDialog = null
            }
        }
    }

    onOpened: {
        zynthian.recordingPopupActive = true
    }
    onClosed: {
        zynthian.recordingPopupActive = false
    }

    function cuiaCallback(cuia) {
        var returnValue = false;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                root.close();
                returnValue = true;
                break;
        }

        return returnValue;
    }

    ColumnLayout {
        implicitWidth: root.parent.width * 0.6
        implicitHeight: root.parent.height * 0.7

        Kirigami.Heading {
            Layout.fillWidth: true
            text: qsTr("Record clip for Track %1").arg(selectedTrack.id+1)
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 1
            Layout.maximumHeight: 1
            color: Kirigami.Theme.textColor
            opacity: 0.5
        }
        RowLayout {
            Layout.preferredHeight: Kirigami.Units.gridUnit * 12
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: false
                enabled: !root.selectedTrack.sceneClip.isRecording

                RowLayout {
                    Layout.fillWidth: false
                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Audio Source")
                    }

                    QQC2.ComboBox {
                        id: sourceCombo

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: sourceComboModel

                            ListElement { text: "Internal (Active Layer)"; value: "internal" }
                            ListElement { text: "External (Audio In)"; value: "external" }
                        }
                        textRole: "text"
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    visible: sourceCombo.currentIndex === 0 // Visible when source is internal

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        Layout.alignment: Qt.AlignCenter
                        enabled: parent.enabled
                        text: qsTr("Source Track")
                    }

                    QQC2.ComboBox {
                        id: trackCombo

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: trackComboModel

                            ListElement { text: "Track 1"; value: 0 }
                            ListElement { text: "Track 2"; value: 1 }
                            ListElement { text: "Track 3"; value: 2 }
                            ListElement { text: "Track 4"; value: 3 }
                            ListElement { text: "Track 5"; value: 4 }
                            ListElement { text: "Track 6"; value: 5 }
                            ListElement { text: "Track 7"; value: 6 }
                            ListElement { text: "Track 8"; value: 7 }
                            ListElement { text: "Track 9"; value: 8 }
                            ListElement { text: "Track 10"; value: 9 }
                        }
                        textRole: "text"
                        currentIndex: visible ? zynthian.session_dashboard.selectedTrack : -1
                        onActivated: {
                            zynthian.session_dashboard.selectedTrack = trackComboModel.get(index).value
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    visible: sourceCombo.currentIndex === 1 // Visible when source is external

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Channel")
                    }

                    QQC2.ComboBox {
                        id: channelCombo

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: channelComboModel

                            ListElement { text: "Left Channel"; value: "1" }
                            ListElement { text: "Right Channel"; value: "2" }
                            ListElement { text: "Stereo"; value: "*" }
                        }
                        textRole: "text"
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Count In (Bars)")
                    }

                    QQC2.ComboBox {
                        id: countInCombo

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: countInComboModel

                            ListElement { text: "Off"; value: 0 }
                            ListElement { text: "1"; value: 1 }
                            ListElement { text: "2"; value: 2 }
                            ListElement { text: "4"; value: 4 }
                        }
                        textRole: "text"
                        onActivated: zynthian.zynthiloops.countInBars = countInComboModel.get(index).value
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Record Master Output")
                    }

                    QQC2.CheckBox {
                        checked: zynthian.zynthiloops.recordMasterOutput
                        onToggled: {
                            zynthian.zynthiloops.recordMasterOutput = checked
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: false
                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        Layout.alignment: Qt.AlignCenter
                        text: qsTr("Metronome")
                    }

                    QQC2.Switch {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: Kirigami.Units.gridUnit * 3
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        checked: zynthian.zynthiloops.clickTrackEnabled
                        onToggled: {
                            zynthian.zynthiloops.clickTrackEnabled = checked
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: false
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                        }

                        Extras.Gauge {
                            Layout.fillHeight: true

                            minimumValue: -100
                            maximumValue: 20
                            value: visible
                                   ? sourceComboModel.get(sourceCombo.currentIndex).value === "internal"
                                      ? ZL.AudioLevels.tracks[root.selectedTrack.id]
                                      : ZL.AudioLevels.captureA
                                   : -100

                            font.pointSize: 8

                            style: GaugeStyle {
                                valueBar: Rectangle {
                                    color: Qt.lighter(Kirigami.Theme.highlightColor, 1.6)
                                    implicitWidth: 6
                                }
                                minorTickmark: null
                                tickmark: null
                                tickmarkLabel: null
                            }
                        }

                        Extras.Gauge {
                            Layout.fillHeight: true

                            minimumValue: -100
                            maximumValue: 20
                            value: visible
                                    ? sourceComboModel.get(sourceCombo.currentIndex).value === "internal"
                                       ? ZL.AudioLevels.tracks[root.selectedTrack.id]
                                       : ZL.AudioLevels.captureB
                                    : -100

                            font.pointSize: 8

                            style: GaugeStyle {
                                valueBar: Rectangle {
                                    color: Qt.lighter(Kirigami.Theme.highlightColor, 1.6)
                                    implicitWidth: 6
                                }
                                minorTickmark: null
                                tickmark: null
                                tickmarkLabel: null
                            }
                        }
                    }
                }

                QQC2.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Audio Level"
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: false
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8

                QQC2.Button {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 6
                    Layout.alignment: Qt.AlignCenter

                    icon.name: root.selectedTrack.sceneClip.isRecording ? "media-playback-stop" : "media-record-symbolic"

                    onClicked: {
                        if (!root.selectedTrack.sceneClip.isRecording) {
                            // console.log("Count In", countInComboModel.get(countInCombo.currentIndex).value)
                            root.selectedTrack.sceneClip.queueRecording(
                                sourceComboModel.get(sourceCombo.currentIndex).value,
                                channelComboModel.get(channelCombo.currentIndex).value
                            );
                            Zynthian.CommonUtils.startMetronomeAndPlayback();
                        } else {
                            Zynthian.CommonUtils.stopMetronomeAndPlayback();
                            bottomBar.tabbedView.initialAction.trigger()
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }
}
