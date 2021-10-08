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

Zynthian.Stack {
    id: root

    data: [
        Timer {
            id: delayedRemoveTimer
            interval: 500
            onTriggered: {
                if (applicationWindow().pageScreenMapping.pageForModalScreen(zynthian.current_screen_id).length === 0) {
//                     applicationWindow().pageStack.layers.pop();
//                     root.clear();
                }
            }
        },
        Connections {
            target: zynthian
            onCurrent_modal_screen_idChanged: {
                print("MODAL SCREEN ID CHANGED: "+zynthian.current_modal_screen_id);

                // Are we in a dashboard page? don't do anything
                if (applicationWindow().pageScreenMapping.pageForDashboardScreen(zynthian.current_screen_id).length > 0) {
                    delayedRemoveTimer.restart();
                    return;
                }
                if (zynthian.current_modal_screen_id === "confirm") {
                    applicationWindow().showConfirmationDialog();
                    return;
                } else {
                    applicationWindow().hideConfirmationDialog();
                }

                // No modal screen anymore
                if (zynthian.current_modal_screen_id.length === 0) {
                    applicationWindow().pageStack.layers.pop();
                    root.clear();
                    return;
                }

                root.forceActiveFocus();

                for (var i = 0; i < root.depth; ++i) {
                    let child = root.get(i);

                    // It's a MultiSelectorPage
                    if (child.hasOwnProperty("screenIds")) {
                        var j; // if (.. in ..) doesn't work
                        for (j in child.screenIds) {
                            let id = child.screenIds[j];
                            if (id === zynthian.current_modal_screen_id) {
                                root.pop(child);
                                return;
                            }
                        }
                        if (zynthian.current_modal_screen_id in child.screenIds) {
                            root.pop(child);
                            return;
                        }
                    } else if (child.hasOwnProperty("screenId")) {
                        if (child.screenId === zynthian.current_modal_screen_id) {
                            root.pop(child);
                            return;
                        }
                    }
                }

                let file = applicationWindow().pageScreenMapping.pageForModalScreen(zynthian.current_modal_screen_id);
                if (file.length > 0) {
                    if (applicationWindow().pageStack.layers.currentItem != root) {
                        applicationWindow().pageStack.layers.push(root)
                    }

                    root.push(file);

                } else {
                    print("Non managed modal screen " + zynthian.current_modal_screen_id);
                }
            }
        }
    ]
}
