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
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

Zynthian.ScreenPage {
    id: root
    backAction: null
    contextualActions: [
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
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
    screenId: "session_dashboard"
    Timer {
        interval: 10 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        function pad(d) {
            return (d < 10) ? '0' + d.toString() : d.toString();
        }
        onTriggered: {
            let d = new Date();
            clockLabel.text = d.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit' });

            /* Remove session time as per #272
               TODO : Remove below snippet
            let sessionSecs = zynthian.session_dashboard.get_session_time()
            let sessionMins = Math.floor(sessionSecs / 60);
            let sessionHours = Math.floor(sessionMins / 60);
            sessionMins = sessionMins % 60;
            sessionTimeLabel.text = pad(sessionHours) + ":" + pad(sessionMins);
            */
        }
    }

    ColumnLayout {
        anchors.fill: parent
        RowLayout {
            /* Remove session time as per #272
               TODO : Remove below snippet
            QQC2.Label {
                Layout.alignment: Qt.AlignCenter
                text: "Session time:"
            }
            Kirigami.Heading {
                id: sessionTimeLabel
                Layout.alignment: Qt.AlignCenter
            }
            */
            Kirigami.Heading {
                id: sketchHeader
                Layout.alignment: Qt.AlignCenter
                text: zynthian.zynthiloops.song.name
            }
            Item {
                Layout.fillWidth: true
            }
            Kirigami.Heading {
                id: clockLabel
                Layout.alignment: Qt.AlignCenter
            }
        }

        Zynthian.TabbedControlView {
            id: tabbedView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visibleFocusRects: false
            minimumTabsCount: 5

            property QQC2.StackView stack

            tabActions: [
                Zynthian.TabbedControlViewAction {
                    text: qsTr("Tracks")
                    page: Qt.resolvedUrl("TracksView.qml")
                },
                Zynthian.TabbedControlViewAction {
                    // Sketches tab renamed to sessions
                    text: qsTr("Sessions")
                    page: Qt.resolvedUrl("SketchesView.qml")
                },
                Zynthian.TabbedControlViewAction {
                    // Sessions tab renamed to Wiring
                    text: qsTr("Wiring")
                    page: Qt.resolvedUrl("SessionView.qml")
                },
                Zynthian.TabbedControlViewAction {
                    text: qsTr("Templates")
                    page: Qt.resolvedUrl("TemplatesView.qml")
                },
                Zynthian.TabbedControlViewAction {
                    text: qsTr("Discover")
                    page: Qt.resolvedUrl("DiscoverView.qml")
                }
            ]
        }
    }
}

