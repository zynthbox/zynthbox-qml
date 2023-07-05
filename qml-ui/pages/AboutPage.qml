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
import QtQuick.Window 2.10
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

Zynthian.ScreenPage {
    id: root
    title: zynqtgui.about.selector_path

    screenId: "about"

    Component {
        id: aboutDetailsComponent
        Kirigami.FormLayout {
            Layout.alignment: Qt.AlignCenter
            QQC2.Label {
                Kirigami.FormData.label: "Zynthbox OS:"
                text: zynqtgui.about.zynthbox_version
            }
            QQC2.Label {
                Kirigami.FormData.label: "Qt:"
                text: zynqtgui.about.qt_version
            }
            QQC2.Label {
                Kirigami.FormData.label: "Kirigami:"
                text: zynqtgui.about.kirigami_version
            }
            QQC2.Label {
                Kirigami.FormData.label: "Libzynthbox:"
                text: zynqtgui.about.libzynthbox_version
            }
            QQC2.Label {
                Kirigami.FormData.label: "Distribution:"
                text: zynqtgui.about.distribution_version
            }
            QQC2.Label {
                Kirigami.FormData.label: "Kernel:"
                text: zynqtgui.about.kernel_version
            }
            QQC2.Label {
                Kirigami.FormData.label: "Hostname:"
                text: zynqtgui.network.getHostname()
            }
        }
    }
    contentItem: RowLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            source: "../../img/logo.png"
        }
        Loader {
            id: aboutDetailsLoader
            Layout.fillWidth: true
            asynchronous: true
            sourceComponent: aboutDetailsComponent
            QQC2.BusyIndicator {
                anchors.centerIn: parent
                visible: parent.status !== Loader.Ready
                running: visible
            }
        }
    }
}
