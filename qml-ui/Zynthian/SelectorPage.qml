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


ScreenPage {
    id: root

    visible: true
    title: root.selector.selector_path_element

    //TODO: Bind the base selector type to qml?
    readonly property alias selector: view.selector
    readonly property alias view: view.view
    property alias delegate: view.delegate
    property alias currentIndex: view.currentIndex
    property alias cuiaCallback: view.cuiaCallback

    bottomPadding: Kirigami.Units.gridUnit
    Component.onCompleted: view.forceActiveFocus()

    onFocusChanged: {
        if (focus) {
            view.forceActiveFocus()
        }
    }

    contentItem: SelectorView {
        id: view

        screenId: root.screenId
        implicitHeight: 1

        onCurrentScreenIdRequested: root.currentScreenIdRequested(root.screenId)
        onItemActivated: root.itemActivated(root.screenId, index)
        onItemActivatedSecondary: root.itemActivatedSecondary(root.screenId, index)
    }
}
