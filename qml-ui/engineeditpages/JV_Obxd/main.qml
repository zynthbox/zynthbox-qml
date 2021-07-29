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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import "../../components" as ZComponents

Item { //TODO: componentize
    id: root

    property QQC2.StackView stack

    RowLayout {
        anchors.fill: parent
        ColumnLayout {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 6
            Layout.fillHeight: true
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("Main")
                autoExclusive: true
                checkable: true
                checked: true
                onCheckedChanged: {
                    if (checked) {
                        internalStack.replace(mainPage)
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("ADSR")
                autoExclusive: true
                checkable: true
                onCheckedChanged: {
                    if (checked) {
                        internalStack.replace(Qt.resolvedUrl("ADSRPage.qml"))
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("Filter")
                autoExclusive: true
                checkable: true
                onCheckedChanged: {
                    if (checked) {
                        internalStack.replace(Qt.resolvedUrl("FilterPage.qml"))
                    }
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("OSC")
                autoExclusive: true
                checkable: true
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("LFO")
                autoExclusive: true
                checkable: true
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("Mix")
                autoExclusive: true
                checkable: true
            }
        }
        ZComponents.Stack {
            id: internalStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            initialItem: mainPage
        }
    }

    GridLayout {
        id: mainPage
        visible: false
        rows: 2
        columns: 2

        // VoiceCount
        ZComponents.SpinBoxController {
            title: qsTr("Voices")
            implicitWidth: 1
            implicitHeight: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            controller: zynthian.control.controller_by_category("Obxd#2", 0)
            spinBox.stepSize: Math.round(spinBox.to / 7)
            spinBox.textFromValue: function(value, locale) {
                return Math.round(spinBox.realValue / (200 / 7)) + 1
            }
        }
        // Octave
        ZComponents.SpinBoxController {
            title: qsTr("Transpose")
            implicitWidth: 1
            implicitHeight: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            controller: zynthian.control.controller_by_category("Obxd#2", 2)
            spinBox.stepSize: 5000
            spinBox.textFromValue: function(value, locale) {
                let val = Math.round((spinBox.realValue - 100) / 50)
                return (val > 0 ? "+" : "") + val
            }
        }
        // Tune
        ZComponents.DialController {
            title: qsTr("Tune")
            implicitWidth: 1
            implicitHeight: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            controller: zynthian.control.controller_by_category("Obxd#2", 1)
            valueLabel: (value > 100 ? "+" : "") + Math.round(value - 100) + "%"
        }
        // VOLUME
        ZComponents.SliderController {
            title: qsTr("Volume")
            implicitWidth: 1
            implicitHeight: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            controller: zynthian.control.controller_by_category("Obxd#1", 3)
            valueLabel: Math.round(value / 2)
        }
    }
}
