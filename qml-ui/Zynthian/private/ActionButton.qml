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
import Zynthian 1.0 as Zynthian

QQC2.Button {
    id: root
    Layout.fillWidth: true
    opacity: enabled ? 1 : 0.4
    implicitWidth: 1 // For even layout partitioning
    enabled: kirigamiAction !== null && kirigamiAction.enabled && kirigamiAction.visible
    // FIXME: replace it with action: when a more recent Kirigami can be used
    property Kirigami.Action kirigamiAction
    font.capitalization: Font.AllUppercase
    // font.weight: Font.DemiBold
    font.family: "Hack"

    text: kirigamiAction && kirigamiAction.visible ? kirigamiAction.text : ""
    checkable: kirigamiAction && kirigamiAction.checkable
    checked: kirigamiAction && kirigamiAction.checked

    onClicked: {
        if (!kirigamiAction || !kirigamiAction.visible || !kirigamiAction.enabled) {
            return;
        }
        kirigamiAction.trigger()
        if (kirigamiAction && kirigamiAction.hasOwnProperty("menuDelegate") && kirigamiAction.menuDelegate) {
            kirigamiAction.menuDelegate.parent = root;
            kirigamiAction.menuDelegate.visible = true;
        } else if (kirigamiAction && kirigamiAction.hasOwnProperty("children") && kirigamiAction.children.length > 0) {
            mainActionSubMenu.visible = true;
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: Kirigami.Units.largeSpacing
        }
        visible: (root.kirigamiAction && root.kirigamiAction.hasOwnProperty("children") && root.kirigamiAction.children.length > 0) || (kirigamiAction && kirigamiAction.hasOwnProperty("menuDelegate") && kirigamiAction.menuDelegate)
        parent: root.background
        height: Kirigami.Units.smallSpacing
        color: Kirigami.Theme.highlightColor
    }

    Zynthian.ActionPickerPopup {
        id: mainActionSubMenu
        actions: root.kirigamiAction && root.kirigamiAction.hasOwnProperty("children") ? root.kirigamiAction.children : null
    }
}

