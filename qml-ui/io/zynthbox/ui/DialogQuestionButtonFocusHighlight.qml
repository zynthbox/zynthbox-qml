/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Component for visually highlighting the parent in a DialogQuestion instance

Copyright (C) 2024 Dan Leinir Turthra Jensen <admin@leinir.dk>

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

import QtQuick 2.15
import org.kde.kirigami 2.6 as Kirigami

Rectangle {
    id: component
    property QtObject selectedButton: null
    anchors.fill: parent
    anchors.margins: -5
    color: "transparent"
    border.width: 2
    border.color: Kirigami.Theme.textColor
    opacity: component.selectedButton === parent ? 0.7 : 0
}
