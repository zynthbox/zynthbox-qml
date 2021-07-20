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

QQC2.ScrollView {
    id: root

    property alias view: view
    property alias model: view.model
    property alias delegate: view.delegate
    property alias currentIndex: view.currentIndex

    property string screenId
    //TODO: Bind the base selector type to qml?
    readonly property QtObject selector: screenId.length > 0 ? zynthian[screenId] : null
    signal currentScreenIdRequested()
    signal itemActivated(int index)
    signal itemActivatedSecondary(int index)

    Component.onCompleted: view.forceActiveFocus()
    onActiveFocusChanged: {
        if (activeFocus) {
            root.currentScreenIdRequested();
            view.forceActiveFocus()
        }
    }

    leftPadding: background.leftPadding
    rightPadding: background.rightPadding
    topPadding: background.topPadding
    bottomPadding: background.bottomPadding

    QQC2.ScrollBar.horizontal.visible: false

    QQC2.ScrollBar.vertical.x: root.width - QQC2.ScrollBar.vertical.width - root.rightPadding

    ListView {
        id: view
        keyNavigationEnabled: true
        keyNavigationWraps: false
        clip: true
        currentIndex: root.selector.current_index

        onActiveFocusChanged: {
            if (activeFocus) {
                root.currentScreenIdRequested();
            }
        }

        model: root.selector.selector_list

        delegate: SelectorDelegate {}
    }

    background: SelectorViewBackground {
        id: background
        highlighted: view.activeFocus
    }
}

