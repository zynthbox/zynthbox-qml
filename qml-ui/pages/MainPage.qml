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
                if (zynqtgui.main.visibleCategory === "sessions-versions") {
                    // Mimic back to return to sketchpad folder view when versions are being displayed
                    zynqtgui.main.visibleCategory = "sessions"
                    return true
                }
                return false

            case "SWITCH_SELECT_BOLD":
                zynqtgui.admin.power_off()
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

            case "CHANNEL_1":
            case "CHANNEL_6":
                zynqtgui.main.visibleCategory = "modules"
                return true

            case "CHANNEL_2":
            case "CHANNEL_7":
                zynqtgui.main.visibleCategory = "appimages"
                return true

            case "CHANNEL_3":
            case "CHANNEL_8":
                zynqtgui.main.visibleCategory = "sessions"
                return true

            case "CHANNEL_4":
            case "CHANNEL_9":
                zynqtgui.main.visibleCategory = "templates"
                return true

            case "CHANNEL_5":
            case "CHANNEL_10":
                zynqtgui.main.visibleCategory = "discover"
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
                checked: zynqtgui.main.visibleCategory === "modules"
                text: qsTr("Modules")
                onClicked: zynqtgui.main.visibleCategory = "modules"
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                checkable: true
                checked: zynqtgui.main.visibleCategory === "appimages"
                text: qsTr("Apps")
                onClicked: zynqtgui.main.visibleCategory = "appimages"
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                checkable: true
                checked: zynqtgui.main.visibleCategory === "sessions" ||
                         zynqtgui.main.visibleCategory === "sessions-versions"
                text: qsTr("Sessions")
                onClicked: zynqtgui.main.visibleCategory = "sessions"
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                checkable: true
                checked: zynqtgui.main.visibleCategory === "templates"
                text: qsTr("Templates")
                onClicked: zynqtgui.main.visibleCategory = "templates"
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                checkable: true
                checked: zynqtgui.main.visibleCategory === "discover"
                text: qsTr("Discover")
                onClicked: zynqtgui.main.visibleCategory = "discover"
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MouseArea {
                id: gridMouseArea
                property bool blocked: false

                anchors.fill: parent
                drag.filterChildren: true
                onClicked: {
                    if (!gridMouseArea.blocked) {
                        zynqtgui.show_modal("sketchpad")
                    }
                }

                GridView {
                    id: mainviewGridId

                    property int iconWidth: (parent.width / 5)
                    property int iconHeight:  (parent.height / 2.1)

                    clip: true
                    anchors.fill: parent
                    cellWidth:iconWidth
                    cellHeight:iconHeight
                    currentIndex: zynqtgui.main.current_index
                    model:zynqtgui.main.selector_list
                    delegate: MouseArea {
                        width: mainviewGridId.iconWidth
                        height: mainviewGridId.iconHeight
                        onPressed: {
                            gridMouseArea.blocked = true
                            mainviewGridId.currentIndex = index
                        }
                        onReleased: gridMouseArea.blocked = false
                        onCanceled: gridMouseArea.blocked = false
                        onClicked: {
                            // activate_index will start the appimage process and open sketchpad after 5 seconds
                            // to mimic closing of menu after opening an app like other modules in main page
                            zynqtgui.main.activate_index(model.index);

                            if (model.action_id === "appimage") {
                                zynqtgui.start_loading();
                                stopLoadingTimer.restart();
                            }
                        }

                        HomeScreenIcon {
                            id: delegateIconButton
                            readonly property bool isCurrent: mainviewGridId.currentIndex === index

                            anchors.fill: parent
                            imgSrc: model.icon
                            highlighted: isCurrent
                            onIsCurrentChanged: {
                                if (isCurrent) {
                                    zynqtgui.main.current_index = index;
                                }
                            }

                            text: model.display
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: stopLoadingTimer
        interval: 30000
        onTriggered: zynqtgui.stop_loading()
    }

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Close")
            onTriggered: Qt.callLater(function() { zynqtgui.show_modal("sketchpad") })
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            text: qsTr("Get New Apps")
            onTriggered: zynqtgui.show_modal("module_downloader")
        },
        Kirigami.Action {
            text: qsTr("Power")
            Kirigami.Action {
                text: qsTr("Restart UI")
                onTriggered: zynqtgui.admin.restart_gui()
            }
            Kirigami.Action {
                text: qsTr("Reboot")
                onTriggered: zynqtgui.admin.reboot()
            }
            Kirigami.Action {
                text: qsTr("Power Off")
                onTriggered: zynqtgui.admin.power_off()
            }
        }
    ]
}
