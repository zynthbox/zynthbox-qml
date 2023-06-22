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

QQC2.ItemDelegate {
    id: delegate
    width: ListView.view.width

    enabled: delegate.visible && model.action_id !== undefined

    topPadding: Kirigami.Units.largeSpacing
    leftPadding: Kirigami.Units.largeSpacing
    bottomPadding: Kirigami.Units.largeSpacing
    rightPadding: Kirigami.Units.largeSpacing
    highlighted: delegate.ListView.view.activeFocus

    property string screenId
    property QtObject selector
    signal currentScreenIdRequested(string screenId)
    signal itemActivated(string screenId, int index)
    signal itemActivatedSecondary(string screenId, int index)
    signal iconClicked(string screenId, int index)

    //implicitHeight: Math.round(Kirigami.Units.gridUnit * 2.5)

    background: DelegateBackground {
        delegate: delegate
    }
    contentItem: RowLayout {
        QQC2.Label {
            text: delegate.visible ? (model.show_numbers ? (index + 1) + " - " : "") + model.display : ""
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: height * 2
            Kirigami.Icon {
                width: parent.height
                height: parent.height
                source: model.icon
                visible: valid
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                onClicked: delegate.iconClicked(delegate.screenId, index)
            }
        }
    }

    onClicked: {
        let oldCurrent_screen_id = zynqtgui.current_screen_id;
        delegate.selector.current_index = index;
        delegate.selector.activate_index(index);
        delegate.itemActivated(delegate.screenId, index);
        // if the activation didn't explicitly ask for a new screen, set the current as this
        if (zynqtgui.current_screen_id === oldCurrent_screen_id) {
            delegate.currentScreenIdRequested(screenId);
        }
    }
    onPressAndHold: {
        let oldCurrent_screen_id = zynqtgui.current_screen_id;
        delegate.selector.current_index = index;
        delegate.selector.activate_index_secondary(index);
        delegate.itemActivatedSecondary(delegate.screenId, index);
        if (zynqtgui.current_screen_id === oldCurrent_screen_id) {
            delegate.currentScreenIdRequested(screenId);
        }
    }
}

