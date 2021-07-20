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
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.4 as Kirigami

QQC2.ToolButton {
    id: root
    Layout.fillHeight: true
    rightPadding: breadcrumbSeparator.width + Kirigami.Units.largeSpacing
    background: Item {
        Image {
            id: breadcrumbSeparator
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            source: "../img/breadcrumb-separator.svg"
        }
    }
    opacity: checked ? 1 : 0.5
    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
}


