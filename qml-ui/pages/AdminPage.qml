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

import Zynthian 1.0 as Zynthian

Zynthian.SelectorPage {
    screenId: "admin"
    contextualActions: [
        Kirigami.Action {
            text: qsTr("Themes")
            onTriggered: zynqtgui.show_modal("theme_chooser")
        }
    ]

    QQC2.Dialog {
        property string label

        id: progressDialog

        modal: true
        closePolicy: QQC2.Popup.NoAutoClose

        x: Math.round(parent.width/2 - width/2)
        y: Math.round(parent.height/2 - height/2)
        width: Kirigami.Units.gridUnit * 15
        height: Kirigami.Units.gridUnit * 4

        contentItem: ColumnLayout {
            anchors.fill: parent
            
            ColumnLayout {
                Layout.alignment: Qt.AlignCenter

                QQC2.Label {
                    text: progressDialog.label
                    Layout.alignment: Qt.AlignHCenter
                }
                QQC2.ProgressBar {
                    indeterminate: true
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.gridUnit * 2
                    Layout.rightMargin: Kirigami.Units.gridUnit * 2
                    Layout.topMargin: Kirigami.Units.gridUnit * 1
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    Zynthian.Dialog {
        property string label

        id: errorDialog

        modal: true

        x: Math.round(parent.width/2 - width/2)
        y: Math.round(parent.height/2 - height/2)
        width: Kirigami.Units.gridUnit * 15
        height: Kirigami.Units.gridUnit * 4

        contentItem: ColumnLayout {
            anchors.fill: parent

            ColumnLayout {
                Layout.alignment: Qt.AlignCenter

                QQC2.Label {
                    text: errorDialog.label
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    Connections {
        target: zynqtgui.admin

        onCheckForUpdatesStarted: {
            progressDialog.label = qsTr("Checking for updates");
            progressDialog.visible = true;
        }
        onCheckForUpdatesErrored: {
            progressDialog.visible = false;
            errorDialog.label = qsTr("Error while checking for updates. Retry again later.")
            errorDialog.visible = true;
        }
        onCheckForUpdatesCompleted: {
            progressDialog.visible = false;
        }
        onCheckForUpdatesUnavailable: {
            progressDialog.visible = false;
            errorDialog.label = qsTr("No Updates Available")
            errorDialog.visible = true;
        }

        onUpdateStarted: {
            progressDialog.label = qsTr("Updating system");
            progressDialog.visible = true;
        }
        onUpdateErrored: {
            progressDialog.visible = false;
            errorDialog.label = qsTr("Error while updating system")
            errorDialog.visible = true;
        }
        onUpdateCompleted: {
            progressDialog.visible = false;
            errorDialog.label = qsTr("Update Complete")
            errorDialog.visible = true;
        }
    }
}
