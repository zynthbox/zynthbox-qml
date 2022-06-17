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

import Zynthian 1.0 as Zynthian

Zynthian.ScreenPage {
    screenId: "main"
    backAction.visible: false


    cuiaCallback: function(cuia) {
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_LONG":
            case "SWITCH_BACK_BOLD":
                if (zynthian.main.visibleCategory === "sessions-versions") {
                    // Mimic back to return to sketch folder view when versions are being displayed
                    zynthian.main.visibleCategory = "sessions"
                    return true
                }
                return false

            case "SWITCH_SELECT_BOLD":
                zynthian.main.power_off()
                return true
            case "SELECT_UP":
                mainviewGridId.moveCurrentIndexUp();
                return true;
            case "SELECT_DOWN":
                if (mainviewGridId.currentIndex === -1) {
                    mainviewGridId.currentIndex = 0;
                } else {
                    mainviewGridId.moveCurrentIndexDown();
                }
                return true;
            case "NAVIGATE_LEFT":
                mainviewGridId.moveCurrentIndexLeft();
                return true;
            case "NAVIGATE_RIGHT":
                mainviewGridId.moveCurrentIndexRight();
                return true;

            case "TRACK_1":
            case "TRACK_6":
                zynthian.main.visibleCategory = "modules"
                return true

            case "TRACK_2":
            case "TRACK_7":
                zynthian.main.visibleCategory = "appimages"
                return true

            case "TRACK_3":
            case "TRACK_8":
                zynthian.main.visibleCategory = "sessions"
                return true

            case "TRACK_4":
            case "TRACK_9":
                zynthian.main.visibleCategory = "templates"
                return true

            case "TRACK_5":
            case "TRACK_10":
                zynthian.main.visibleCategory = "discover"
                return true

            default:
                return false;
        }
    }

    contentItem: RowLayout {
        spacing: Kirigami.Units.gridUnit

        QQC2.ButtonGroup {
            buttons: categoryButtons.children
        }

        ColumnLayout {
            id: categoryButtons

            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 6

            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                checkable: true
                checked: zynthian.main.visibleCategory === "modules"
                text: qsTr("Modules")
                onClicked: zynthian.main.visibleCategory = "modules"
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                checkable: true
                checked: zynthian.main.visibleCategory === "appimages"
                text: qsTr("Apps")
                onClicked: zynthian.main.visibleCategory = "appimages"
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                checkable: true
                checked: zynthian.main.visibleCategory === "sessions" ||
                         zynthian.main.visibleCategory === "sessions-versions"
                text: qsTr("Sessions")
                onClicked: zynthian.main.visibleCategory = "sessions"
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                checkable: true
                checked: zynthian.main.visibleCategory === "templates"
                text: qsTr("Templates")
                onClicked: zynthian.main.visibleCategory = "templates"
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                checkable: true
                checked: zynthian.main.visibleCategory === "discover"
                text: qsTr("Discover")
                onClicked: zynthian.main.visibleCategory = "discover"
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridView {
                id: mainviewGridId

                property int iconWidth: (parent.width / 5)
                property int iconHeight:  (parent.height / 2.1)

                clip: true
                anchors.fill: parent
                cellWidth:iconWidth
                cellHeight:iconHeight
                currentIndex: zynthian.main.current_index
                model:zynthian.main.selector_list
                delegate: HomeScreenIcon {
                    readonly property bool isCurrent: mainviewGridId.currentIndex === index

                    width: mainviewGridId.iconWidth
                    height: mainviewGridId.iconHeight

                    imgSrc: model.icon
                    highlighted: isCurrent
                    onIsCurrentChanged: {
                        if (isCurrent) {
                            zynthian.main.current_index = index;
                        }
                    }
                    onClicked: {
                        // activate_index will start the appimage process and open zynthiloops after 5 seconds
                        // to mimic closing of menu after opening an app like other modules in main page
                        zynthian.main.activate_index(model.index);

                        if (model.action_id === "appimage") {
                            zynthian.start_loading();
                            stopLoadingTimer.restart();
                        }
                    }
                    text: model.display
                }

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true

                    // FIXME : The following implementation is a bit HACKY but works for now.
                    //         Would be good if it could be implemented in a better way
                    //
                    // When a flick is happening, it seems to not call onReleased handler, rather only onPressed is being called.
                    // onReleased seems to be called only when pressed and released without flicking.
                    onReleased: {
                        var mappedPos = {x: mouse.x + mainviewGridId.contentX, y: mouse.y + mainviewGridId.contentY}
                        var delegate = mainviewGridId.itemAt(mappedPos.x, mappedPos.y)

                        // If delegate is not null, click the item otherwise open zynthiloops to mimic
                        // closing of main menu when clicked on empty area
                        if (delegate != null && delegate.clicked) {
                            delegate.clicked()
                        } else {
                            zynthian.show_modal("zynthiloops")
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: stopLoadingTimer
        interval: 30000
        onTriggered: zynthian.stop_loading()
    }

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Close")
            onTriggered: Qt.callLater(function() { zynthian.show_modal("zynthiloops") })
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            text: qsTr("Get New Modules")
            onTriggered: zynthian.show_modal("module_downloader")
        },
        Kirigami.Action {
            text: qsTr("Power")
            Kirigami.Action {
                text: qsTr("Restart UI")
                onTriggered: zynthian.main.restart_gui()
            }
            Kirigami.Action {
                text: qsTr("Reboot")
                onTriggered: zynthian.main.reboot()
            }
            Kirigami.Action {
                text: qsTr("Power Off")
                onTriggered: zynthian.main.power_off()
            }
        }
    ]
}
