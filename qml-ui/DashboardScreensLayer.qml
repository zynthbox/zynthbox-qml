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

import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import "pages" as Pages
import "pages/SessionDashboard" as Dash
import "pages/Sketchpad" as ZL

Zynthian.Stack {
    id: root

    //visible: depth > 0 || busy
    onVisibleChanged: {
        if (visible) {
            root.forceActiveFocus()
        }
    }

    property var pageCache: {
        //"session_dashboard": dashboard
        "sketchpad": sketchpad
    }
    //initialItem: Dash.Main {
        //id: dashboard
    //}
    initialItem: ZL.Main {
        id: sketchpad
    }
    data: [
        Timer {
            id: preloadTimer
            interval: 0
            running: true
            onTriggered: {
                let file = ""
                console.log("Caching sketchpad")
                if (!root.pageCache["main"]) {
                    file = applicationWindow().pageScreenMapping.pageForDashboardScreen("main");
                    var component = Qt.createComponent(file);
                    root.pageCache["main"] = component.createObject(root, {"width": root.width, "height": root.height});
                    root.pageCache["main"].visible = false;
                }
            }
        },
        Connections {
            target: zynthian
            onCurrent_screen_idChanged: {
                print("SCREEN ID CHANGED, DASHBOARD MANAGER: "+zynthian.current_screen_id);

                // This should never happen
                if (zynthian.current_screen_id.length === 0) {
                    print("Warning: empty screen requested")
                    root.visible = false;
                   // root.clear(QQC2.StackView.PopTransition);
                   // root.depthChanged() // this old qt didn't emit it after clear
                    return;
                }
                root.visible = true;


                // Skipping modal screen requests
                /*if (zynthian.current_screen_id === zynthian.current_modal_screen_id) {
                    root.clear(QQC2.StackView.PopTransition);
                    root.depthChanged()
                    return;
                }*/


                if (root.currentItem && root.currentItem.hasOwnProperty("screenId") && root.currentItem.screenId === zynthian.current_screen_id) {
                    return;
                }

                var newItem = null;
                if (root.pageCache && root.pageCache[zynthian.current_screen_id]) {
                    newItem = root.pageCache[zynthian.current_screen_id];
                    for (var i = 0; i < root.depth; ++i) {
                        var otherItem = root.get(i);
                        if (newItem == otherItem) {
                            root.pop(otherItem, QQC2.StackView.ImmediateTransition);
                            return;
                        }
                    }
                    root.push(newItem, QQC2.StackView.ImmediateTransition);
                } else {
                    let file = applicationWindow().pageScreenMapping.pageForDashboardScreen(zynthian.current_screen_id);
                    if (file.length > 0) {
                        root.replace(file, QQC2.StackView.ImmediateTransition);
                    } else {
                        print("Non managed dashboard screen " + zynthian.current_screen_id);
                        root.visible = false;
                    }
                }
            }
        }
    ]
    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
        opacity: root.depth > 0
        //Behavior on opacity {
            //OpacityAnimator {
               //duration: Kirigami.Units.shortDuration
               //easing.type: Easing.InOutCubic
            //}
        //}

        Component.onCompleted: {
            zynthian.currentTaskMessage = "Loading sketchpad page"
        }
    }
}
