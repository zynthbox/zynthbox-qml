/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Session Dashboard page for Zynthian GUI

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
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

ColumnLayout {
    id: root

    anchors {
        fill: parent
        topMargin: -Kirigami.Units.smallSpacing
        leftMargin: Kirigami.Units.gridUnit
    }

    property int itemHeight: layersView.height / 15
    spacing: Kirigami.Units.largeSpacing

    RowLayout {
        spacing: Kirigami.Units.gridUnit * 2

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 4
            color: Kirigami.Theme.backgroundColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.gridUnit*0.5

                Repeater {
                    model: zynthian.zynthiloops.song.tracksModel
                    delegate: RowLayout {
                        property QtObject track: model.track

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0
                        visible: index < 6

                        QQC2.Label {
                            Layout.fillWidth: false
                            Layout.preferredWidth: Kirigami.Units.gridUnit*2
                            Layout.alignment: Qt.AlignVCenter
                            text: (index+1) + "."
                        }
                        QQC2.Label {
                            Layout.fillWidth: false
                            Layout.preferredWidth: Kirigami.Units.gridUnit*4
                            Layout.alignment: Qt.AlignVCenter
                            text: model.display
                        }                        
                        Repeater {
                            model: zynthian.zynthiloops.song.partsModel
                            delegate: Rectangle {
                                Layout.fillWidth: false
                                Layout.fillHeight: false
                                Layout.preferredWidth: Kirigami.Units.gridUnit*1.5
                                Layout.preferredHeight: Kirigami.Units.gridUnit*1.5
                                Layout.alignment: Qt.AlignVCenter
                                color: Kirigami.Theme.buttonBackgroundColor
                                radius: 4

                                QQC2.Label {
                                    anchors.centerIn: parent
                                    text: model.display
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
