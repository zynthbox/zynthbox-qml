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
import org.kde.newstuff 1.0 as NewStuff

import "../components" as ZComponents
import "../components/private/" as ZComponentsPrivate

ZComponents.SelectorPage {
    screenId: "theme_downloader"
    title: qsTr("Theme Downloader")
    view.delegate: newStuffDelegate
    onItemActivated: {
        console.log("Activated item " + index + " on screen " + screenId );
    }
    Component.onCompleted: {
        selector.newstuff_model = newStuffModel;
    }
    NewStuff.Engine {
        id: newStuffEngine
        // The configFile entry is local-only and we need to strip the URL bits from the resolved version...
        configFile: Qt.resolvedUrl("zynthian-themes.knsrc").toString().slice(7)
    }
    NewStuff.ItemsModel {
        id: newStuffModel
        engine: newStuffEngine.engine
    }
    Component {
        id: newStuffDelegate
        ZComponents.SelectorDelegate {
            selector: ListView.view.parent.selector
            onCurrentScreenIdRequested: ListView.view.parent.currentScreenIdRequested()
            onItemActivated: ListView.view.parent.itemActivated(index)
            onItemActivatedSecondary: ListView.view.parent.itemActivatedSecondary(index)
            Kirigami.Icon {
                id: updateAvailableBadge;
                opacity: (model.status == NewStuff.ItemsModel.UpdateableStatus) ? 1 : 0;
                Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration; } }
                anchors {
                    bottom: parent.bottom;
                    right: parent.right;
                    top: parent.top;
                }
                width: height;
                source: "vcs-update-required";
            }
            Kirigami.Icon {
                id: installedBadge;
                opacity: (model.status == NewStuff.ItemsModel.InstalledStatus) ? 1 : 0;
                Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration; } }
                anchors {
                    bottom: parent.bottom;
                    right: parent.right;
                    top: parent.top;
                }
                width: height;
                source: "vcs-normal";
            }
        }
    }
}
