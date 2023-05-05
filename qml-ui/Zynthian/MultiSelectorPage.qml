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
    title: qsTr("Synth")

    property var screenIds: []
    property var screenTitles: []

    cuiaCallback: function(cuia) {
        let currentScreenIndex = root.screenIds.indexOf(zynqtgui.current_screen_id);
        switch (cuia) {
        case "NAVIGATE_LEFT":
            var newIndex = Math.max(0, currentScreenIndex - 1);
            zynqtgui.current_screen_id = root.screenIds[newIndex];
            return true;
        case "NAVIGATE_RIGHT":
            var newIndex = Math.min(root.screenIds.length - 1, currentScreenIndex + 1);
            zynqtgui.current_screen_id = root.screenIds[newIndex];
            return true;
        case "SWITCH_BACK_SHORT":
        case "SWITCH_BACK_BOLD":
        case "SWITCH_BACK_LONG":
            zynqtgui.current_screen_id = screenIds[0];
            zynqtgui.go_back();
            return true;
        default:
            return false;
        }
    }

    bottomPadding: Kirigami.Units.gridUnit

    contentItem: RowLayout {
        id: layout

        // FIXME : Find a way to correctly expand the columns equally with fillWidth property instead of using manually calculated width value
        property real columnWidth: width / root.screenIds.length - spacing / (root.screenIds.length - 1)

        spacing: Kirigami.Units.gridUnit
        Repeater {
            model: root.screenIds
            delegate: ColumnLayout {
                property alias view: view
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.preferredWidth: layout.columnWidth
                Kirigami.Heading {
                    level: 2
                    text: root.screenTitles.length > index ? root.screenTitles[index] : view.selector.caption
                    Kirigami.Theme.inherit: false
                    // TODO: this should eventually go to Window and the panels to View
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                }
                SelectorView {
                    id: view
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    screenId: modelData
                    onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                    onItemActivated: root.itemActivated(screenId, index)
                    onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
                    Component.onCompleted: {
                        view.background.highlighted = Qt.binding(function() { return zynqtgui.current_screen_id === screenId })
                    }
                }
            }
        }
    }
}
