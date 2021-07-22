/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Download page for ZYnthian themes

Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
    id: component
    screenId: "theme_downloader"
    title: qsTr("Theme Downloader")
    view.delegate: newStuffDelegate
    onItemActivated: {
        proxyView.currentIndex = index;
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
    ListView {
        id: proxyView
        anchors {
            top: view.top
            left: view.right
            bottom: view.bottom
        }
        width: 2
        model: newStuffModel
        delegate: Item {
            property int status: model.status;
            property string name: model.name;
            property string summary: model.summary;
            // ...etc for the various roles. Would be nice if we could use the .index and .data functions
            // so we could just slap this info into the normal delegate, that way we wouldn't need this
            // proxy, but oh well, it's cheap enough, so...
            // Setting these to make sure they're basically really large and we don't end up polling the model for more items than the not-proxy view has
            width: ListView.view.width
            height: ListView.view.height
        }
    }
    contextualActions: [
        Kirigami.Action {
            enabled: view.currentIndex > -1 && (proxyView.currentItem.status == NewStuff.ItemsModel.UpdateableStatus || proxyView.currentItem.status == NewStuff.ItemsModel.DownloadableStatus)
            text: proxyView.currentItem.status == NewStuff.ItemsModel.UpdateableStatus ? qsTr("Update") : qsTr("Install"); // if UpdateableStatus, say Update, if UpdateableStatus enabled = false
            onTriggered: {
                newStuffModel.installItem(view.currentIndex);
            }
        },
        Kirigami.Action {
            enabled: view.currentIndex > -1 && (proxyView.currentItem.status == NewStuff.ItemsModel.UpdateableStatus || proxyView.currentItem.status == NewStuff.ItemsModel.InstalledStatus)
            text: qsTr("Remove");
            onTriggered: {
                newStuffModel.uninstallItem(view.currentIndex);
            }
        }
    ]
    Component {
        id: newStuffDelegate
        ZComponents.SelectorDelegate {
            screenId: component.screenId
            selector: ListView.view.parent.selector
            onCurrentScreenIdRequested: ListView.view.parent.currentScreenIdRequested(screenId)
            onItemActivated: ListView.view.parent.itemActivated(screenId, index)
            onItemActivatedSecondary: ListView.view.parent.itemActivatedSecondary(screenId, index)
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
