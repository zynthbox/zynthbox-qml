/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Play Grid Page

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

import Zynthian 1.0 as Zynthian

Zynthian.ScreenPage {
    screenId: "zynthiloops"
    leftPadding: 0
    rightPadding: 0
    topPadding: 5
    bottomPadding: 5

    Component.onCompleted: {
        applicationWindow().controlsVisible = true;
        applicationWindow().headerVisible = false;
    }

    Component.onDestruction: {
        applicationWindow().controlsVisible = true;
        applicationWindow().headerVisible = true;
    }

    ListView {
        model: zynthian.zynthiloops.model
        anchors.fill: parent

        delegate: QQC2.Label {
            text: name
        }
    }
}
