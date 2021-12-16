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

    Component.onCompleted: {
        zynthian.current_screen_id_changed()
    }

    data: [
        Connections {
            target: zynthian
            property string lastScreen
            onCurrent_screen_idChanged: {
                let screenId = zynthian.current_screen_id;
                print("SCREEN ID CHANGED: "+lastScreen + "->"+screenId);

                if (applicationWindow().pageScreenMapping.pageForScreen(screenId) !== applicationWindow().pageScreenMapping.pageForScreen(lastScreen)) {
                    zynthian.forced_modal_screen_back = null
                    zynthian.forced_screen_back = null
                }

                lastScreen = screenId;

                // This should never happen
                if (screenId.length === 0) {
                    print("Warning: empty screen requested")
                    return;
                }

                // Skipping modal screen requests
                if (screenId === zynthian.current_modal_screen_id) {
                    return;
                }
                //if (root.layers.depth > 1) {
                    //root.layers.pop(root)
                //}

                for (var i = 0; i < root.depth; ++i) {
                    let child = root.get(i);

                    // It's a MultiSelectorPage
                    if (child.hasOwnProperty("screenIds")) {
                        var j; // if (.. in ..) doesn't work
                        for (j in child.screenIds) {
                            let id = child.screenIds[j];
                            if (id === screenId) {
                                root.pop(child);
                                return;
                            }
                        }
                        if (screenId in child.screenIds) {
                            root.pop(child);
                            return;
                        }
                    } else if (child.hasOwnProperty("screenId")) {
                        if (child.screenId === screenId) {
                            root.pop(child);
                            return;
                        }
                    }
                }
                let file = applicationWindow().pageScreenMapping.pageForScreen(screenId);
                if (file.length > 0) {
                    root.push(file);
                } else {
                    print("Non managed screen " + screenId);
                }
            }
        }
    ]
}
