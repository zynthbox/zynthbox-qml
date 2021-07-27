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

    QtObject {
        id: privateProps

        property var gridKeys: [
            [49,50,51,52,53,54,55,56],
            [41,42,43,44,45,46,47,48],
            [33,34,35,36,37,38,39,40],
            [25,26,27,28,29,30,31,32],
            [17,18,19,20,21,22,23,24],
            [9,10,11,12,13,14,15,16],
            [1,2,3,4,5,6,7,8],
        ]
    }
    
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
                    model: privateProps.gridKeys
                    delegate: RowLayout {
                        Layout.margins: 2.5

                        Repeater {
                            model: privateProps.gridKeys[index]
                            delegate: QQC2.Button {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: modelData
                                onClicked: {
                                    focus = false                                
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
