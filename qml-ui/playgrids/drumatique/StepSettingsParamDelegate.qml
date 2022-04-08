/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Settings panel for a single step in a pattern

Copyright (C) 2022 Dan Leinir Turthra Jensen <admin@leinir.dk>

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

RowLayout {
    id: component
    property QtObject model
    property int row
    property int column

    property int paramIndex
    property string paramName
    property string paramDefaultString
    property string paramValueSuffix
    property int paramDefault
    property int paramMin
    property int paramMax

    Layout.columnSpan: 2
    Layout.fillWidth: true
    property var paramValue: component.model && component.row > -1 && component.column > -1 && updateForcery > -1 ? component.model.subnoteMetadata(component.row, component.column, component.paramIndex, paramName) : undefined;
    property int updateForcery: 0
    Zynthian.PlayGridButton {
        text: "-"
        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
        enabled: component.paramValue === undefined || component.paramValue > component.paramMin
        onClicked: {
            if (component.paramValue === undefined) {
                component.model.setSubnoteMetadata(component.row, component.column, component.paramIndex, paramName, Math.max(component.paramDefault - 1, component.paramMin));
            } else {
                component.model.setSubnoteMetadata(component.row, component.column, component.paramIndex, paramName, component.paramValue - 1);
            }
            component.updateForcery += 1;
        }
    }
    QQC2.Label {
        Layout.fillWidth: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 6
        horizontalAlignment: Text.AlignHCenter
        text: parent.paramValue === undefined || component.paramValue === component.paramDefault ? component.paramDefaultString : parent.paramValue + component.paramValueSuffix
    }
    Zynthian.PlayGridButton {
        text: "+"
        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
        enabled: component.paramValue === undefined || component.paramValue < component.paramMax
        onClicked: {
            if (component.paramValue === undefined) {
                component.model.setSubnoteMetadata(component.row, component.column, component.paramIndex, paramName, Math.min(component.paramMax, component.paramDefault + 1));
            } else {
                component.model.setSubnoteMetadata(component.row, component.column, component.paramIndex, paramName, component.paramValue + 1);
            }
            component.updateForcery += 1;
        }
    }
}
