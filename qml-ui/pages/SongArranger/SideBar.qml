/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Marco MArtin <mart@kde.org>

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

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian

Zynthian.Card {
    id: root

    enum ControlType {
        Track,
        None
    }

    property int controlType: SideBar.ControlType.None
    property QtObject controlObj: null

    contentItem: ColumnLayout {
        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumHeight: Kirigami.Units.gridUnit * 2

            Kirigami.Heading {
                id: heading
                text: root.controlObj ? root.controlObj.name : ""
                wrapMode: Text.NoWrap
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Zynthian.TabbedControlView {
            id: tabbedView
            Layout.fillWidth: true
            Layout.fillHeight: true
            minimumTabsCount: 0
            orientation: Qt.Vertical

            initialAction: {
                switch (root.controlType) {
                    case SideBar.ControlType.Track:
                        return trackAction;
                    default:
                        return emptyAction;
                }
            }

            onInitialActionChanged: initialAction.trigger()

            tabActions: [
                Zynthian.TabbedControlViewAction {
                    id: trackAction
                    text: qsTr("Channel")
                    page: Qt.resolvedUrl("TrackBar.qml")
                    visible: root.controlType === SideBar.ControlType.Track
                    initialProperties: {"sideBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    id: emptyAction
                    text: qsTr("Empty")
                    page: Qt.resolvedUrl("EmptyBar.qml")
                    visible: root.controlType === SideBar.ControlType.None
                    initialProperties: {"sideBar": root}
                }
            ]
        }
    }
}
