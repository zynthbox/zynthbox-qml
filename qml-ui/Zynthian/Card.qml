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

import "private"

//NOTE: this is due to a bug in Kirigami.AbstractCard from Buster's version
QQC2.Control {
    id: root

    property bool highlighted: false

    padding: Kirigami.Units.smallSpacing
    // leftPadding: background.leftPadding
    // rightPadding: background.rightPadding
    // topPadding: background.topPadding
    // bottomPadding: background.bottomPadding

    // This is done for performance reasons
    // background: CardBackground {
    //     id: background
    //     highlighted: root.highlighted
    // }

    background: Rectangle
    {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.inherit: false
        color: Kirigami.Theme.backgroundColor
        radius: 4
    }
}
