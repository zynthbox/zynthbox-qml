/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian slots bar page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Marco MArtin <mart@kde.org>
Copyright (C) 2026 Camilo Higuita <milo.h@aol.com>

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
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami
import QtQuick.Extras 1.4 as Extras
import QtGraphicalEffects 1.0
import org.kde.plasma.core 2.0 as PlasmaCore

import QtQuick.Controls.Styles 1.4

import io.zynthbox.ui 1.0 as ZUI

import io.zynthbox.components 1.0 as Zynthbox

ZUI.CellControl {
    id: control

    default property alias content: _layout.data
    property alias text2 : _label2.text
    property alias title : _label1.text

    property Item control1: null
    property Item control2: null

    property alias underlay: _underlayItem.data

    contentItem: Item {
        ColumnLayout {
            id: _layout
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing            

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Item {
                    id: _underlayItem
                    anchors.fill: parent
                }

                Item {
                    anchors.fill: parent

                    StackLayout {
                        id: _stack
                        anchors.fill: parent
                        data: control.control1
                    }

                    Item {   
                        id: _parentLabel                    
                        width: Kirigami.Units.gridUnit

                        anchors.right: parent.right
                        anchors.bottom: parent.bottom      
                        anchors.top: parent.top
                        anchors.margins: Kirigami.Units.smallSpacing  +6         

                        QQC2.Label {
                            id: _titleLabel
                            height: parent.width
                            width: parent.height
                            anchors.top: parent.bottom

                            elide: Text.ElideMiddle
                            text: control.text
                            opacity: 0.5

                            font.pointSize: 8

                            transform: Rotation {
                                origin.x: 0
                                origin.y: 0
                                angle: -90
                            }
                        }
                    }
                }
            }

            StackLayout {
                visible: control.control2
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: visible ? Kirigami.Units.gridUnit : 0
                Layout.leftMargin: visible ? Kirigami.Units.smallSpacing : 0
                Layout.rightMargin: visible ? Kirigami.Units.smallSpacing : 0
                data: control.control2
            }

            QQC2.Label {
                id: _label1
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.margins: 4
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight

                MouseArea {
                    anchors.fill: parent
                    onClicked: control.clicked()
                    onDoubleClicked: control.doubleClicked()                    
                }
            }

            QQC2.Label {
                id: _label2
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.fillHeight: false
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pointSize: 9

                MouseArea {
                    anchors.fill: parent
                    onClicked: control.clicked()
                    onDoubleClicked: control.doubleClicked()
                }
            }
        }
    }
}