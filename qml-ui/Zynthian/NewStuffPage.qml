/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Page for KNewStuff downloadable content

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

import Zynthian 1.0 as Zynthian

import "private" as Private

Zynthian.SelectorPage {
    id: component

    cuiaCallback: function(cuia) {
        switch (cuia) {
            case "SELECT_UP":
                if (selector.current_index > 0) {
                    selector.current_index -= 1
                }
                return true;

            case "SELECT_DOWN":
                if (selector.current_index < mainView.count - 1) {
                    selector.current_index += 1
                }
                return true;
        }

        return false;
    }
    /**
     * The configuration file path - this requires the full path, which usually means
     * something like the following, if the file is in the same directory as the calling
     * component:
     * Qt.resolvedUrl("zynthian-themes.knsrc").toString().slice(7)
     * (that is, we need it fully resolved, but not as a url, so without the file:// part)
     */
    property alias configFile: newStuffEngine.configFile

    Component.onCompleted: {
        selector.newstuff_model = newStuffModel;
    }
    Connections {
        target: applicationWindow()
        onCurrentPageChanged: {
            if (applicationWindow().currentPage.screenId !== component.screenId) {
                applicationWindow().pageStack.layers.currentItem.pop()
            }
        }
    }
    NewStuff.Engine {
        id: newStuffEngine
        property bool isLoading: false
        property string message
        onMessage: {
            applicationWindow().showPassiveNotification(message);
        }
        onBusyMessage: {
            if (!isLoading) { isLoading = true; }
            newStuffEngine.message = message;
        }
        onIdleMessage: {
            if (isLoading) { isLoading = false; }
            newStuffEngine.message = "";
        }
        onErrorMessage: {
            zynthian.comfirm.show(message)
        }
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
        QQC2.ItemDelegate {
            id: nsDelegate
            width: ListView.view.width
            topPadding: Kirigami.Units.largeSpacing
            leftPadding: Kirigami.Units.largeSpacing
            bottomPadding: Kirigami.Units.largeSpacing
            rightPadding: Kirigami.Units.largeSpacing
            highlighted: ListView.view.activeFocus
            onClicked: {
                selector.current_index = index;
            }
            background: Private.DelegateBackground {
                delegate: nsDelegate
            }
            contentItem: RowLayout {
                Item {
                    Layout.fillHeight: true
                    Layout.maximumWidth: height
                    Layout.minimumWidth: height
                    Kirigami.Icon {
                        anchors.fill: parent;
                        visible: previewImage.status != Image.Ready;
                        source: "viewimage";
                    }
                    Image {
                        id: previewImage
                        anchors.fill: parent;
                        asynchronous: true;
                        smooth: true;
                        fillMode: Image.PreserveAspectFit;
                        source: model.previewsSmall.length > 0 ? model.previewsSmall[0] : "viewimage";
                    }
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: model.name
                }
                QQC2.Label {
                    visible: installedBadge.visible
                    text: "Installed"
                }
                QQC2.Label {
                    visible: updateAvailableBadge.visible
                    text: "Update Available"
                }
                Kirigami.Icon {
                    id: installedBadge;
                    visible: model.status == NewStuff.ItemsModel.InstalledStatus;
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    source: "vcs-normal";
                }
                Kirigami.Icon {
                    id: updateAvailableBadge;
                    visible: model.status == NewStuff.ItemsModel.UpdateableStatus;
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    source: "vcs-update-required";
                }
            }
        }
    }
    Private.SelectorViewBackground {
        anchors.fill: parent
        ListView {
            id: mainView
            anchors {
                fill: parent;
                margins: Kirigami.Units.largeSpacing
                rightMargin: proxyView.width + Kirigami.Units.smallSpacing + Kirigami.Units.largeSpacing
            }
            model: newStuffModel
            currentIndex: selector.current_index
            delegate: newStuffDelegate
            clip: true
            onCurrentIndexChanged: {
                positionViewAtIndex(currentIndex, ListView.Contain);
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
        clip: true
        model: newStuffModel
        currentIndex: selector.current_index
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
            Zynthian.Card {
                anchors.fill: parent;
                ColumnLayout {
                    opacity: busyInstallingStuff.running ? 0.3 : 1
                    anchors {
                        fill: parent;
                        margins: Kirigami.Units.largeSpacing;
                    }
                    Item {
                        id: previewContainer;
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Kirigami.Icon {
                            anchors {
                                fill: parent;
                                margins: Kirigami.Units.smallSpacing;
                            }
                            visible: previewImage.status != Image.Ready;
                            source: "viewimage";
                        }
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
                                visible: model.status == NewStuff.ItemsModel.UpdateableStatus;
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
                                visible: model.status == NewStuff.ItemsModel.InstalledStatus;
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
                        visible: model.status == NewStuff.ItemsModel.UpdateableStatus
                        text: qsTr("<strong>Update Available</strong>")
                        elide: Text.ElideRight
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        visible: model.version.length > 0
                        text: model.status == NewStuff.ItemsModel.UpdateableStatus
                            ? qsTr("Version %1 (installed %2)").arg(model.updateVersion).arg(model.version)
                            : qsTr("Version %1").arg(model.version)
                        elide: Text.ElideRight
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: model.status == NewStuff.ItemsModel.UpdateableStatus
                            ? qsTr("Released on %1\nInstalled release: %2").arg(model.updateReleaseDate.toLocaleDateString()).arg(model.releaseDate.toLocaleDateString())
                            : qsTr("Released on %1").arg(model.releaseDate.toLocaleDateString())
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
                        Zynthian.Rating {
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
                visible: model.status == NewStuff.ItemsModel.InstallingStatus || model.status == NewStuff.ItemsModel.UpdatingStatus;
                running: visible;
                background: Item {} // Quiet some warnings
                QQC2.Label {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.bottom
                        topMargin: Kirigami.Units.largeSpacing
                    }
                    text: (model.status == NewStuff.ItemsModel.InstallingStatus) ? "Installing" : ((model.status == NewStuff.ItemsModel.UpdatingStatus) ? "Updating" : "");
                    width: paintedWidth;
                }
            }
        }
    }
    Item {
        id: busyWithEngineStuff
        anchors {
            bottom: view.bottom
            right: view.right
            left: view.left
            margins: Kirigami.Units.largeSpacing
        }
        height: Kirigami.Units.gridUnit * 5
        visible: newStuffEngine.isLoading;
        Zynthian.Card {
            anchors {
                top: parent.top
                left: busyWithEngineStuffLabel.left
                right: busyWithEngineStuffLabel.right
                bottom: parent.bottom
                topMargin: -Kirigami.Units.largeSpacing
                leftMargin: -Kirigami.Units.gridUnit * 2.5
                rightMargin: -Kirigami.Units.gridUnit * 2.5
                bottomMargin: -Kirigami.Units.largeSpacing
            }
        }
        QQC2.BusyIndicator {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: Kirigami.Units.largeSpacing
            }
            height: Kirigami.Units.gridUnit * 3
            width: height
            running: parent.visible;
            background: Item {} // Quiet some warnings
        }
        QQC2.Label {
            id: busyWithEngineStuffLabel
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: Kirigami.Units.largeSpacing
            }
            text: newStuffEngine.message
            width: paintedWidth
        }
    }
}
