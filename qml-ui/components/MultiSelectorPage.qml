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
    title: qsTr("Synth")

    property var screenIds: []
    property string previousScreen

    signal currentScreenIdRequested(string screenId)
    signal itemActivated(string screenId, int index)
    signal itemActivatedSecondary(string screenId, int index)

    bottomPadding: Kirigami.Units.largeSpacing
    Component.onCompleted: focusConnection.syncFocus()

    onFocusChanged: {
        if (focus) {
            focusConnection.syncFocus();
        }
    }

    data: [
        Connections {
            id: focusConnection
            target: zynthian
            function syncFocus() {
                var i
                for (i in layout.children) {
                    let child = layout.children[i];
                    if (child.hasOwnProperty("view")
                        && (child.view.screenId === zynthian.current_screen_id
                            || child.view.screenId === zynthian.current_modal_screen_id)) {
                        child.view.forceActiveFocus();
                    }
                }
            }
            onCurrent_screen_idChanged: syncFocus()
            onCurrent_modal_screen_idChanged: syncFocus()
        }
    ]

    contentItem: RowLayout {
        id: layout
        spacing: Kirigami.Units.largeSpacing
        Repeater {
            model: root.screenIds
            delegate: ColumnLayout {
                property alias view: view
                Layout.fillWidth: true
                Layout.fillHeight: true
                // NOTE: this is to make fillWidth always partition the space in equal sizes
                implicitWidth: 1
                Layout.preferredWidth: 1
                Kirigami.Heading {
                    level: 2
                    text: view.selector.caption
                }
                SelectorView {
                    id: view
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    screenId: modelData
                    onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                    onItemActivated: root.itemActivated(screenId, index)
                    onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
                }
            }
        }
    }
}
