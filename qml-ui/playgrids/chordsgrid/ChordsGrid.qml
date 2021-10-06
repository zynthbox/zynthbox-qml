/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Base Grid Component 

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
ColumnLayout {
    id: component
    property QtObject model
    property bool positionalVelocity

    spacing: 0
    anchors.margins: 5
    Repeater {
        id: mainRepeater
        model: component.model
        delegate: RowLayout {
            id: rowDelegate
            property var row: index
            Layout.margins: 2.5
            Repeater {
                model: component.model.columnCount(component.model.index(rowDelegate.row, 0))
                delegate: Zynthian.NotePad {
                    positionalVelocity: component.positionalVelocity
                    note: component.model.data(component.model.index(rowDelegate.row, index), component.model.roles['note'])
                }
            }
        }
    }
}
