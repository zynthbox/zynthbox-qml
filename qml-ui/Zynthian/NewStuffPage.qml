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
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents

import Zynthian 1.0 as Zynthian

Zynthian.ScreenPage {
    id: component
    property bool isVisible: zynqtgui.current_screen_id === component.screenId

    cuiaCallback: function(cuia) {
        switch (cuia) {
            case "KNOB3_DOWN":
            case "SELECT_UP":
                if (contentLoader.item && contentLoader.item.currentIndex > 0) {
                    contentLoader.item.currentIndex -= 1;
                }
                return true;

            case "KNOB3_UP":
            case "SELECT_DOWN":
                if (contentLoader.item && contentLoader.item.currentIndex < contentLoader.item.count - 1) {
                    contentLoader.item.currentIndex += 1;
                }
                return true;
        }

        return false;
    }
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

    onIsVisibleChanged: {
        engineUpdater.restart();
    }
    property bool connectionChecked: false
    property bool hasStoreConnection: false
    property string connectionErrorDescription: ""
    Connections {
        target: zynqtgui.sketchpad_downloader // We just need any, and this one's kind of a base we can assume will exist
        onStoreConnectionStateChecked: {
            component.connectionErrorDescription = message;
            component.hasStoreConnection = state;
            component.connectionChecked = true;
            engineUpdater.restart();
        }
    }
    Timer {
        id: engineUpdater
        running: false; repeat: false; interval: 10
        onTriggered: {
            if (component.isVisible) {
                if (component.connectionChecked) {
                    if (component.hasStoreConnection) {
                        contentLoader.setSource("private/NewStuffPageContents.qml", {"showUseThis": component.showUseThis, "useThisLabel": component.useThisLabel, "configFile": component.configFile});
                    }
                } else {
                    zynqtgui.sketchpad_downloader.checkStoreConnection();
                }
            } else if (component.newStuffEngine !== null) {
                contentLoader.source = "";
                component.connectionChecked = false;
            }
        }
    }
    contextualActions: contentLoader.status == Loader.Ready ? contentLoader.item.contextualActions : []
    contentItem: Item {
        anchors.fill: parent
        Zynthian.Card {
            anchors.centerIn: parent
            height: Kirigami.Units.gridUnit * 10
            width: Kirigami.Units.gridUnit * 15
            visible: component.connectionChecked === true && component.hasStoreConnection === false
            ColumnLayout {
                anchors.fill: parent
                Kirigami.Heading {
                    Layout.fillWidth: true
                    text: qsTr("No Network Connection")
                }
                QQC2.Label {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: qsTr("Sorry, you seem to have no network connection right now. Either plug in a network cable, or connect to a wifi network, and then come back here to try again.\n%1").arg(component.connectionErrorDescription)
                }
            }
        }
        Item {
            id: busyLoadingPage
            anchors {
                bottom: parent.bottom
                right: parent.right
                left: parent.left
                margins: Kirigami.Units.largeSpacing
            }
            height: Kirigami.Units.gridUnit * 5
            visible: contentLoader.status != Loader.Ready
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
                running: parent.visible
                background: Item {} // Quiet some warnings
            }
        }
        Loader {
            id: contentLoader
            anchors.fill: parent
            // asynchronous: true
        }
        Connections {
            target: contentLoader.item
            onUseThis: component.useThis(installedFiles)
        }
        Binding {
            target: contentLoader.item
            property: "showUseThis"
            value: component.showUseThis
        }
        Binding {
            target: contentLoader.item
            property: "useThisLabel"
            value: component.useThisLabel
        }
        Binding {
            target: contentLoader.item
            property: "configFile"
            value: component.configFile
        }
    }
}
