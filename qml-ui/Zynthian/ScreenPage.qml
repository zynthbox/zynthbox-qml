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
    // A workaround for StackView in Qt 5.11 not resizing its children properly on resizes
    // Useful for when we toggle the action bar on and off
    anchors.fill: parent

    property Kirigami.Action backAction: Kirigami.Action {
        text: qsTr("Back")
        onTriggered: zynqtgui.go_back()
    }
    property string previousScreen

    property string screenId

    Kirigami.Action {
        id: backAction
        text: qsTr("Back")
        onTriggered: zynqtgui.go_back()
    }

    // This can be a function taking the cuia action name as paramenter. if returns
    // true the python part won't manage that action.
    // Useful for custom navigation in pages
    property var cuiaCallback

    signal currentScreenIdRequested(string screenId)
    signal itemActivated(string screenId, int index)
    signal itemActivatedSecondary(string screenId, int index)

    bottomPadding: Kirigami.Units.gridUnit

    Component.onCompleted: {
        //HACK to disable kirigami automatic toolbars in that old version
        var i
        for (i in root.children) {
            let child = root.children[i];
            // Duck type Loaders
            if (child.hasOwnProperty("active") && child.hasOwnProperty("source")) {
                child.active = false;
            }
        }
    }
}
