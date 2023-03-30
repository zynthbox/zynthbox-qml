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
import org.kde.kirigami 2.5 as Kirigami


Kirigami.ScrollablePage {
    id: root

    property Kirigami.Action backAction: Kirigami.Action {
        text: qsTr("Back")
        onTriggered: zynqtgui.go_back()
    }
    property string previousScreen

    property string screenId

    signal currentScreenIdRequested(string screenId)
    signal itemActivated(string screenId, int index)
    signal itemActivatedSecondary(string screenId, int index)

    bottomPadding: Kirigami.Units.gridUnit

}
