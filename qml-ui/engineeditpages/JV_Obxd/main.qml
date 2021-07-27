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

    GridLayout {
        anchors.fill: parent
        rows: 2
        columns: 4
        // ASDR
        ZComponents.Controller {
            implicitWidth: 1
            implicitHeight: 1
            controller: zynthian.control.controller_by_category("Obxd#14", 0)
        }
        ZComponents.Controller {
            implicitWidth: 1
            implicitHeight: 1
            controller: zynthian.control.controller_by_category("Obxd#14", 2)
        }
        ZComponents.Controller {
            implicitWidth: 1
            implicitHeight: 1
            controller: zynthian.control.controller_by_category("Obxd#14", 1)
        }
        ZComponents.Controller {
            implicitWidth: 1
            implicitHeight: 1
            controller: zynthian.control.controller_by_category("Obxd#14", 3)
        }

        /*ZComponents.Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentItem: ColumnLayout {
                Kirigami.Heading {
                    text: qsTr("ASDR")
                    level:2
                }
                QQC2.Button {
                    text: "open"
                    onClicked: stack.push(Qt.resolvedUrl("./ASDRPage.qml"))
                }
            }
        }*/

        // Cutoff
        ZComponents.Controller {
            implicitWidth: 1
            implicitHeight: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            controller: zynthian.control.controller_by_category("Obxd#12", 2)
        }
        // Resonance
        ZComponents.Controller {
            implicitWidth: 1
            implicitHeight: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            controller: zynthian.control.controller_by_category("Obxd#12", 1)
        }
        ZComponents.Card {
            implicitWidth: 1
            implicitHeight: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        // VOLUME
        ZComponents.Controller {
            implicitWidth: 1
            implicitHeight: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            controller: zynthian.control.controller_by_category("Obxd#1", 3)
        }
    }
}
