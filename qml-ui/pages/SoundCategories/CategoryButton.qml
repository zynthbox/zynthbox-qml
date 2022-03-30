/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

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

QQC2.Button {
    property string category: "*"
    checkable: true
    text: {
        if      (category === "*") return qsTr("All")
        else if (category === "0") return qsTr("Uncategorized")
        else if (category === "1") return qsTr("Drums")
        else if (category === "2") return qsTr("Bass")
        else if (category === "3") return qsTr("Leads")
        else if (category === "4") return qsTr("Keys/Pads")
        else if (category === "99") return qsTr("Others")
    }
    onClicked: {
        zynthian.sound_categories.setCategoryFilter(category)
    }
}
