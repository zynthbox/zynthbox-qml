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


QtObject {
    id: root
    property string category
    property int index: -1
    property QtObject ctrl

    onCategoryChanged: internal.syncCtrl()
    onIndexChanged: internal.syncCtrl()
    Component.onCompleted: internal.syncCtrl()

    property Connections _internal: Connections {
        id: internal
        function syncCtrl() {
            if (index < 0) {
                return;
            }
            if (category.length > 0 && category.indexOf("amixer_") === 0) {
                root.ctrl = zynqtgui.control.amixer_controller_by_category(root.category.substring(7), root.index);
                print(root.ctrl)
            } else if (category.length > 0) {
                root.ctrl = zynqtgui.control.controller_by_category(root.category, root.index);
            } else {
                root.ctrl = zynqtgui.control.controller(root.index);
            }
        }
        target: zynqtgui.control
        onControllers_changed: syncCtrl()
    }
}
