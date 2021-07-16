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


Kirigami.BasicListItem {
    width: ListView.view.width
    label: model.display
    reserveSpaceForIcon: false

    enabled: model.action_id !== undefined
    highlighted: ListView.isCurrentItem

    //implicitHeight: Math.round(Kirigami.Units.gridUnit * 2.5)

    activeBackgroundColor: (ListView.view.activeFocus && !pressed || !ListView.view.activeFocus && pressed)
        ? Kirigami.Theme.highlightColor
        : Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.4)

    Behavior on activeBackgroundColor {
        ColorAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.InOutQuad
        }
    }

    onClicked: {
        let oldCurrent_screen_id = zynthian.current_screen_id;
        root.selector.current_index = index;
        root.selector.activate_index(index);
        root.itemActivated(index)
        // if the activation didn't explicitly ask for a new screen, set the current as this
        if (zynthian.current_screen_id === oldCurrent_screen_id) {
            root.currentScreenIdRequested()
        }
    }
    onPressAndHold: {
        let oldCurrent_screen_id = zynthian.current_screen_id;
        root.selector.current_index = index;
        root.selector.activate_index_secondary(index);
        root.itemActivatedSecondary(index)
        if (zynthian.current_screen_id === oldCurrent_screen_id) {
            root.currentScreenIdRequested()
        }
    }
}

