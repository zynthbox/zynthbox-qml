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

import "../components" as ZComponents

ZComponents.ScreenPage {
    id: root
    title: zynthian.control.selector_path_element

    screenId: "control"

    Component.onCompleted: {
        mainView.forceActiveFocus()
    }
    onFocusChanged: {
        if (focus) {
            mainView.forceActiveFocus()
        }
    }

    bottomPadding: Kirigami.Units.gridUnit
    contentItem: RowLayout {
        ColumnLayout {
            Layout.maximumWidth: Math.floor(root.width / 4)
            Layout.minimumWidth: Layout.maximumWidth
            Layout.fillHeight: true
            ZComponents.Controller {
                // FIXME: this always assumes there are always exactly 4 controllers for the entire lifetime
                controller: zynthian.control.controllers_count > 0 ? zynthian.control.controller(0) : null
            }
            ZComponents.Controller {
                controller: zynthian.control.controllers_count > 1 ? zynthian.control.controller(1) : null
            }
        }
        ZComponents.SelectorView {
            id: mainView
            screenId: root.screenId
            Layout.fillWidth: true
            Layout.fillHeight: true
            onCurrentScreenIdRequested: root.currentScreenIdRequested(root.screenId)
			onItemActivated: root.itemActivated(root.screenId, index)
        }
        ColumnLayout {
            Layout.maximumWidth: Math.floor(root.width / 4)
            Layout.minimumWidth: Layout.maximumWidth
            Layout.fillHeight: true
            ZComponents.Controller {
                controller: zynthian.control.controllers_count > 2 ? zynthian.control.controller(2) : null
            }
            ZComponents.Controller {
                controller: zynthian.control.controllers_count > 3 ? zynthian.control.controller(3) : null
            }
        }
    }
}
