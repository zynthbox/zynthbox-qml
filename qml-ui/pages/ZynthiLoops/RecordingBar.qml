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
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4 as Extras
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

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_SELECT_SHORT":
                bottomBar.filePickerDialog.folderModel.folder = bottomBar.controlObj.recordingDir;
                bottomBar.filePickerDialog.open();
                return true;

            case "SWITCH_BACK_SHORT":
                sceneActionBtn.checked = false;
                mixerActionBtn.checked = true;
                bottomStack.currentIndex = 1;
                return true;
        }

        return false;
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8

        QQC2.Label {
            Layout.alignment: Qt.AlignCenter
            text: qsTr("Source")
        }

        QQC2.ComboBox {
            id: sourceCombo

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            model: ListModel {
                id: sourceComboModel

                ListElement { text: "Internal (Active Layer)"; value: "internal" }
                ListElement { text: "External (Audio In)"; value: "external" }
            }
            textRole: "text"
        }
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        visible: sourceCombo.currentIndex === 1

        QQC2.Label {
            Layout.alignment: Qt.AlignCenter
            text: qsTr("Channel")
        }

        QQC2.ComboBox {
            id: channelCombo

            Layout.fillWidth: true
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

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8

        QQC2.Label {
            Layout.alignment: Qt.AlignCenter
            text: qsTr("Count In (Bars)")
        }

        QQC2.ComboBox {
            id: countInCombo
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            model: ListModel {
                id: countInComboModel
                ListElement { value: 1 }
                ListElement { value: 2 }
                ListElement { value: 4 }
            }
            textRole: "value"
        }
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true

//        Repeater {
//            model: controlObj.hasOwnProperty("soundData") ? controlObj.soundData : []

//            delegate: QQC2.Label {
//                Layout.alignment: Qt.AlignCenter
//                text: modelData
//            }
//        }

//        QQC2.Label {
//            text: zynthian.zynthiloops.countInValue
//            visible: controlObj.isRecording && zynthian.zynthiloops.countInValue > 0
//        }
    }

    ColumnLayout {
        property bool isCapturing: false

        id: monitorColumn

        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 4

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                opacity: monitorColumn.isCapturing ? 1 : 0.3
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }

                Extras.Gauge {
                    Layout.fillHeight: true

                    minimumValue: -400
                    maximumValue: 0
                    value: monitorColumn.isCapturing
                               ? sourceComboModel.get(sourceCombo.currentIndex).value === "internal"
                                  ? zynthian.zynthiloops.recordingAudioLevel
                                  : zynthian.zynthiloops.captureAudioLevelLeft
                               : -400

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

                    minimumValue: -400
                    maximumValue: 0
                    value: monitorColumn.isCapturing
                               ? sourceComboModel.get(sourceCombo.currentIndex).value === "internal"
                                  ? zynthian.zynthiloops.recordingAudioLevel
                                  : zynthian.zynthiloops.captureAudioLevelRight
                               : -400

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

            QQC2.Button {
                visible: !monitorColumn.isCapturing
                text: "Monitor"
                anchors.centerIn: parent
                onClicked: {
                    monitorColumn.isCapturing = true;
                    zynthian.zynthiloops.monitorCaptureAudioLevels();
                }
            }
        }

        QQC2.Label {
            Layout.alignment: Qt.AlignHCenter
            text: "Capture"
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

            icon.name: controlObj.isRecording ? "media-playback-stop" : "media-record-symbolic"

            onClicked: {
                if (!controlObj.isRecording) {
                    // console.log("Count In", countInComboModel.get(countInCombo.currentIndex).value)
                    controlObj.queueRecording(
                        sourceComboModel.get(sourceCombo.currentIndex).value,
                        channelComboModel.get(channelCombo.currentIndex).value
                    );
                    Zynthian.CommonUtils.startMetronomeAndPlayback();
                } else {
                    controlObj.stopRecording();
                    zynthian.zynthiloops.song.scenesModel.addClipToCurrentScene(controlObj);
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
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8

        QQC2.Button {
            Layout.alignment: Qt.AlignCenter

            text: qsTr("Paste Clip")
            visible: bottomBar.clipCopySource != null
            enabled: bottomBar.clipCopySource != bottomBar.controlObj
            onClicked: {
                bottomBar.controlObj.copyFrom(bottomBar.clipCopySource);
                bottomBar.clipCopySource = null;
            }
        }
    }
}

