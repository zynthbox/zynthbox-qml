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
    contextualActions: [
        Kirigami.Action {
            enabled: proxyView.currentItem && (proxyView.currentIndex > -1 && (proxyView.currentItem.status == NewStuff.ItemsModel.UpdateableStatus || proxyView.currentItem.status == NewStuff.ItemsModel.DownloadableStatus || proxyView.currentItem.status == NewStuff.ItemsModel.DeletedStatus))
            text: proxyView.currentItem ? (proxyView.currentItem.status == NewStuff.ItemsModel.UpdateableStatus ? qsTr("Update") : qsTr("Install")) : ""
            onTriggered: {
                newStuffModel.installItem(proxyView.currentIndex);
            }
        },
        Kirigami.Action {
            enabled: proxyView.currentItem && (proxyView.currentIndex > -1 && (proxyView.currentItem.status == NewStuff.ItemsModel.UpdateableStatus || proxyView.currentItem.status == NewStuff.ItemsModel.InstalledStatus))
            text: proxyView.currentItem ? qsTr("Remove") : ""
            onTriggered: {
                newStuffModel.uninstallItem(proxyView.currentIndex);
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
    ListView {
        id: proxyView
        anchors {
            top: view.top
            right: view.right
            bottom: view.bottom
        }
        width: component.width / 3
        interactive: false
        pixelAligned: true
        model: newStuffModel
        onCurrentIndexChanged: {
            positionViewAtIndex(currentIndex, ListView.Beginning);
        }
        delegate: Item {
            property int status: model.status;
            property string name: model.name;
            property string summary: model.summary;
            // ...etc for the various roles. Would be nice if we could use the .index and .data functions
            // so we could just slap this info into the normal delegate, that way we wouldn't need this
            // proxy, but oh well, it's cheap enough, so...

            // We're using this as our de-facto single-item view, so just make these the full size of the ListView
            width: ListView.view.width
            height: ListView.view.height
            ZComponents.Card {
                anchors.fill: parent;
                ColumnLayout {
                    opacity: busyInstallingStuff.running ? 0.3 : 1
                    Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration; } }
                    anchors {
                        fill: parent;
                        margins: Kirigami.Units.largeSpacing;
                    }
                    Item {
                        id: previewContainer;
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Image {
                            id: previewImage;
                            anchors {
                                fill: parent;
                                margins: Kirigami.Units.smallSpacing;
                            }
                            verticalAlignment: Image.AlignTop
                            asynchronous: true;
                            fillMode: Image.PreserveAspectFit;
                            source: model.previews.length > 0 ? model.previews[0] : "";
                            Kirigami.Icon {
                                id: updateAvailableBadge;
                                opacity: (model.status == NewStuff.ItemsModel.UpdateableStatus) ? 1 : 0;
                                Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration; } }
                                anchors {
                                    top: parent.top;
                                    right: parent.right;
                                    margins: -Kirigami.Units.smallSpacing;
                                }
                                height: Kirigami.Units.iconSizes.smallMedium;
                                width: height;
                                source: "vcs-update-required";
                            }
                            Kirigami.Icon {
                                id: installedBadge;
                                opacity: (model.status == NewStuff.ItemsModel.InstalledStatus) ? 1 : 0;
                                Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration; } }
                                anchors {
                                    top: parent.top;
                                    right: parent.right;
                                    margins: -Kirigami.Units.smallSpacing;
                                }
                                height: Kirigami.Units.iconSizes.smallMedium;
                                width: height;
                                source: "vcs-normal";
                            }
                        }
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: model.summary
                        wrapMode: Text.Wrap
                        maximumLineCount: 5
                        elide: Text.ElideRight
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        visible: model.version.length > 0
                        text: qsTr("Version %1").arg(model.version)
                        elide: Text.ElideRight
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: qsTr("Released on %1").arg(model.releaseDate.toLocaleDateString())
                        elide: Text.ElideRight
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: qsTr("By %1").arg(model.author["name"])
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label {
                            text: qsTr("Rated as")
                        }
                        ZComponents.Rating {
                            Layout.fillWidth: true
                            rating: model.rating
                        }
                    }
                }
            }
            QQC2.BusyIndicator {
                id: busyInstallingStuff
                anchors {
                    horizontalCenter: parent.horizontalCenter;
                    bottom: parent.verticalCenter
                    bottomMargin: Kirigami.Units.largeSpacing
                }
                height: Kirigami.Units.gridUnit * 3
                width: height
                opacity: (model.status == NewStuff.ItemsModel.InstallingStatus || model.status == NewStuff.ItemsModel.UpdatingStatus) ? 1 : 0;
                Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration; } }
                running: opacity > 0;
                QQC2.Label {
                    anchors {
                        horizontalCenter: parent.horizontalCenter;
                        top: parent.bottom
                        topMargin: Kirigami.Units.largeSpacing
                    }
                    text: (model.status == NewStuff.ItemsModel.InstallingStatus) ? "Installing" : ((model.status == NewStuff.ItemsModel.UpdatingStatus) ? "Updating" : "");
                    width: paintedWidth;
                }
            }
        }
    }
}
