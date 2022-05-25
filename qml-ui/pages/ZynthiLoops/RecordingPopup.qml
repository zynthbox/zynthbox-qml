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

    onVisibleChanged: {
        if (visible) {
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
            Layout.fillWidth: true

            QQC2.Label {
                text: "Source"
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
        RowLayout {
            Layout.fillWidth: true
            visible: sourceComboModel.get(sourceCombo.currentIndex).value === "external"

            QQC2.Label {
                text: "Channel"
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
        RowLayout {
            Layout.fillWidth: true
            visible: false

            QQC2.Label {
                text: "Count In (Bars)"
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

        Extras.Gauge {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit

            orientation: Qt.Horizontal
            minimumValue: -100
            maximumValue: 20
            value: root.visible
                    ? sourceComboModel.get(sourceCombo.currentIndex).value === "internal"
                        ? ZL.AudioLevels.tracks[root.selectedTrack.id]
                        : ZL.AudioLevels.add(ZL.AudioLevels.captureA, ZL.AudioLevels.captureB)
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


        QQC2.Button {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
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
}
