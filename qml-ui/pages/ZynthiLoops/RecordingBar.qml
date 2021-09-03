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

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 12

        QQC2.Label {
            Layout.alignment: Qt.AlignCenter
            text: "Source"
        }

        QQC2.ComboBox {
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
        Layout.preferredWidth: Kirigami.Units.gridUnit * 12

        QQC2.Label {
            Layout.alignment: Qt.AlignCenter
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
        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 12

        QQC2.Button {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
            Layout.preferredHeight: Kirigami.Units.gridUnit * 8
            Layout.alignment: Qt.AlignCenter

            icon.name: controlObj.isRecording ? "media-playback-stop" : "media-record-symbolic"

            onClicked: {
                if (!controlObj.isRecording) {
                    console.log("Count In", countInComboModel.get(countInCombo.currentIndex).value)
                    controlObj.queueRecording();
                } else {
                    controlObj.stopRecording();
                }
            }
        }
    }
}

