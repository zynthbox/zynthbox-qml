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
import io.zynthbox.components 1.0 as Zynthbox

QQC2.Button {
    id: control
    property string category: "*"
    readonly property QtObject categoryInfo: Zynthbox.SndLibrary.categories[category]
    property string origin: ""

    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Button
        radius: control.radius ? control.radius : 2
        color: control.highlighted ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
    }
    checkable: true
    text: "%1 (%2)"
            .arg(categoryInfo.name)
            .arg(control.origin == "my-sounds"
                    ? categoryInfo.myFileCount
                    : control.origin == "community-sounds"
                        ? categoryInfo.communityFileCount
                        : control.origin == ""
                            ? categoryInfo.myFileCount + categoryInfo.communityFileCount
                            : 0)
}
