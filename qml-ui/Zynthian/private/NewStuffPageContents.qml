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

import QtQuick 2.15
import QtQuick.Layouts 1.4
import QtMultimedia 5.15 as QMM
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import org.kde.newstuff 1.0 as NewStuff
import org.kde.plasma.components 3.0 as PlasmaComponents

import Zynthian 1.0 as Zynthian

Item {
    id: component
    anchors.fill: parent
    property alias currentIndex: mainView.currentIndex
    property alias count: mainView.count

    /**
     * \brief The configuration file path
     * This requires the full path, which usually means something like the following, if
     * the file is in the same directory as the calling component:
     * Qt.resolvedUrl("zynqtgui-themes.knsrc").toString().slice(7)
     * (that is, we need it fully resolved, but not as a url, so without the file:// part)
     */
    property string configFile
    /**
     * \brief Shows the Use This button for installed entries
     * When clicked, the useThis signal will be fired
     * To use a different string on the button, set useThisLabel to something else
     */
    property bool showUseThis: false
    /**
     * \brief The label for the Use This button
     */
    property string useThisLabel: qsTr("Use This")
    /**
     * \brief Signal fired to say something should be done with the list of files
     * The parameter installedFiles forwards the list of files for a newstuff entry,
     * and contains all the installed files from that entry.
     * You likely also want to go back from the page upon performing the action,
     * which can be done by calling zynqtgui.callable_ui_action("SWITCH_BACK_SHORT")
     */
    signal useThis(var installedFiles);

    property list<QtObject> contextualActions: [
        Kirigami.Action {
            enabled: proxyView.currentItem && (proxyView.currentIndex > -1 && (proxyView.currentItem.status == NewStuff.ItemsModel.UpdateableStatus || proxyView.currentItem.status == NewStuff.ItemsModel.DownloadableStatus || proxyView.currentItem.status == NewStuff.ItemsModel.DeletedStatus))
            text: proxyView.currentItem ? (proxyView.currentItem.status == NewStuff.ItemsModel.UpdateableStatus ? qsTr("Update") : qsTr("Install")) : ""
            onTriggered: {
                if (proxyView.currentItem.status == NewStuff.ItemsModel.UpdateableStatus) {
                    newStuffModel.updateItem(proxyView.currentIndex);
                } else {
                    newStuffModel.installItem(proxyView.currentIndex, 1);
                }
            }
        },
        Kirigami.Action {
            enabled: proxyView.currentItem && (proxyView.currentIndex > -1 && (proxyView.currentItem.status == NewStuff.ItemsModel.UpdateableStatus || proxyView.currentItem.status == NewStuff.ItemsModel.InstalledStatus))
            text: proxyView.currentItem ? qsTr("Remove") : ""
            onTriggered: {
                newStuffModel.uninstallItem(proxyView.currentIndex);
            }
        },
        Kirigami.Action {
            enabled: component.showUseThis && (proxyView.currentItem && proxyView.currentIndex > -1 && (proxyView.currentItem.status == NewStuff.ItemsModel.UpdateableStatus || proxyView.currentItem.status == NewStuff.ItemsModel.InstalledStatus))
            text: enabled ? component.useThisLabel : ""
            onTriggered: {
                component.useThis(proxyView.currentItem.installedFiles);
            }
        }
    ]

    NewStuff.Engine {
        id: newStuffEngine
        configFile: component.configFile
    }
    property bool isLoading: false
    property bool initialisingCompleted: false
    property string message: ""
    Connections {
        target: newStuffEngine
        onMessage: {
            applicationWindow().showPassiveNotification(message);
        }
        onBusyMessage: {
            if (!isLoading) { isLoading = true; }
            component.message = message;
        }
        onIdleMessage: {
            if (isLoading) { isLoading = newStuffEngine.isLoading; }
            component.message = "";
            if (mainView.currentIndex < 0) {
                mainView.currentIndex = 0;
            }
        }
        onErrorMessage: {
            if (newStuffEngine.configFile != "") {
                errorPopup.text = message;
                errorPopup.open();
            }
        }
        onIsLoadingChanged: {
            component.isLoading = newStuffEngine.isLoading;
            if (newStuffEngine.isLoading === false) {
                component.initialisingCompleted = true;
            }
        }
    }
    NewStuff.ItemsModel {
        id: newStuffModel
        engine: newStuffEngine
    }
    QMM.Audio {
        id: previewPlayer
        autoLoad: false
    }
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
                mainView.currentIndex = index;
            }
            background: DelegateBackground {
                delegate: nsDelegate
            }
            contentItem: Item {
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                implicitHeight: Kirigami.Units.iconSizes.medium
                RowLayout {
                    anchors.fill: parent
                    Kirigami.Icon {
                        Layout.fillHeight: true
                        Layout.maximumWidth: height
                        Layout.minimumWidth: height
                        visible: previewImage.status != Image.Ready;
                        source: "viewimage";
                    }
                    Image {
                        id: previewImage
                        Layout.fillHeight: true
                        Layout.maximumWidth: height
                        Layout.minimumWidth: height
                        asynchronous: true;
                        smooth: true;
                        fillMode: Image.PreserveAspectFit;
                        visible: previewImage.status == Image.Ready;
                        source: model.previewsSmall.length > 0 ? model.previewsSmall[0] : "viewimage";
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
    }
    SelectorViewBackground {
        anchors.fill: parent
        ListView {
            id: mainView
            anchors {
                fill: parent;
                margins: Kirigami.Units.largeSpacing
                rightMargin: proxyView.width + Kirigami.Units.smallSpacing + Kirigami.Units.largeSpacing
            }
            model: newStuffModel
            delegate: newStuffDelegate
            clip: true
            onCurrentIndexChanged: {
                positionViewAtIndex(currentIndex, ListView.Contain);
            }
        }
        ListView {
            id: proxyView
            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
            }
            width: component.width / 3
            interactive: false
            pixelAligned: true
            clip: true
            model: newStuffModel
            currentIndex: mainView.currentIndex
            onCurrentIndexChanged: {
                positionViewAtIndex(currentIndex, ListView.Beginning);
            }
            delegate: Item {
                id: proxyViewDelegate
                property int status: model.status;
                property string name: model.name;
                property string summary: model.summary;
                property var installedFiles: model.installedFiles;
                property string previewUrl
                // ...etc for the various roles. Would be nice if we could use the .index and .data functions
                // so we could just slap this info into the normal delegate, that way we wouldn't need this
                // proxy, but oh well, it's cheap enough, so...
                property bool hasPreview: previewUrl.length > 0
                Component.onCompleted: {
                    previewUrl = "";
                    for (let linkIndex = 0; linkIndex < model.downloadLinks.length; ++linkIndex) {
                        let downloadLink = model.downloadLinks[linkIndex];
                        if (downloadLink.descriptionLink.endsWith(".wav")) {
                            previewUrl = downloadLink.descriptionLink;
                            break;
                        }
                    }
                }

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
                            RowLayout {
                                visible: proxyViewDelegate.hasPreview
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                height: Kirigami.Units.iconSizes.medium
                                Kirigami.Icon {
                                    Layout.fillHeight: true
                                    Layout.minimumWidth: height
                                    Layout.maximumWidth: height
                                    source: previewPlayer.source == proxyViewDelegate.previewUrl && previewPlayer.playbackState === QMM.Audio.PlayingState ? "media-playback-stop" : "media-playback-start"
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (previewPlayer.source == proxyViewDelegate.previewUrl && previewPlayer.playbackState === QMM.Audio.PlayingState) {
                                                previewPlayer.stop();
                                            } else {
                                                if (previewPlayer.source != proxyViewDelegate.previewUrl) {
                                                    previewPlayer.stop();
                                                    previewPlayer.source = proxyViewDelegate.previewUrl;
                                                }
                                                previewPlayer.play();
                                            }
                                        }
                                    }
                                }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width
                                        height: Kirigami.Units.largeSpacing
                                        visible: previewPlayer.playbackState === QMM.Audio.PlayingState && previewPlayer.duration > 0
                                        color: "white"
                                        Rectangle {
                                            anchors {
                                                top: parent.top
                                                left: parent.left
                                                right: parent.right
                                                margins: 1
                                            }
                                            width: previewPlayer.duration > 0 ? (parent.width * previewPlayer.position / previewPlayer.duration) - 2 : 0
                                            color: "white"
                                            border {
                                                width: 1
                                                color: "black"
                                            }
                                        }
                                    }
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
                PlasmaComponents.BusyIndicator {
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
                bottom: parent.bottom
                right: parent.right
                left: parent.left
                margins: Kirigami.Units.largeSpacing
            }
            height: Kirigami.Units.gridUnit * 5
            visible: component.isLoading;
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
            PlasmaComponents.BusyIndicator {
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
                text: component.message
                width: paintedWidth
            }
        }
        Zynthian.DialogQuestion {
            id: errorPopup
            rejectText: ""
            acceptText: qsTr("OK")
            title: qsTr("An error occurred")
        }
    }
}
