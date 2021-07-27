/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Test Touchpoints Page 

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>

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

import "../components" as ZComponents

ZComponents.ScreenPage {
    screenId: "test_touchpoints"
    leftPadding: 0
    rightPadding: 0
    topPadding: 5
    bottomPadding: 5
    
    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                anchors.margins: 5

                Repeater {
                    model: zynthian.test_touchpoints.notesModel.rowCount()
                    delegate: RowLayout {
                        property var row: index

                        Layout.margins: 2.5

                        Repeater {
                            model: zynthian.test_touchpoints.notesModel.columnCount(zynthian.test_touchpoints.notesModel.index(index, 0))
                            delegate: QQC2.Button {
                                property var column: index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: zynthian.test_touchpoints.notesModel.data(zynthian.test_touchpoints.notesModel.index(row, column), Qt.DisplayRole)
                                onClicked: {
                                    focus = false
                                    zynthian.test_touchpoints.play_sound("C4");
                                    console.log(row, column, Qt.DisplayRole, zynthian.test_touchpoints.notesModel.data(zynthian.test_touchpoints.notesModel.index(row, column), Qt.DisplayRole));
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 320
            Layout.fillHeight: true

            color: "transparent"
        }
    }
}
