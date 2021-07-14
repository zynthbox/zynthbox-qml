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


Kirigami.Page {
    id: root

    visible: true
    title: root.selector.selector_path_element

    property string previousScreen
    property alias view: view.view
    property alias model: view.model
    property alias delegate: view.delegate
    property alias currentIndex: view.currentIndex

    property alias screenId: view.screenId
    //TODO: Bind the base selector type to qml?
    property alias selector: view.selector
    signal currentScreenIdRequested()
    signal itemActivated(int index)
    signal itemActivatedSecondary(int index)

    bottomPadding: Kirigami.Units.gridUnit
    Component.onCompleted: view.forceActiveFocus()

    onFocusChanged: {
        if (focus) {
            view.forceActiveFocus()
        }
    }

    header: Kirigami.Heading {
        level: 2
        text: root.selector.caption
        leftPadding: root.leftPadding + Kirigami.Units.largeSpacing
        visible: false
    }

    contentItem: SelectorView {
        id: view
        //Layout.fillHeight: true
        //Layout.maximumWidth: Math.floor(root.width / 4) * 3
        //Layout.minimumWidth: Layout.maximumWidth
        onCurrentScreenIdRequested: root.currentScreenIdRequested()
        onItemActivated: root.itemActivated(index)
        onItemActivatedSecondary: root.itemActivatedSecondary(index)
    }
}
