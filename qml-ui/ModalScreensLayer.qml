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

    visible: depth > 0 || busy
    onVisibleChanged: {
        if (visible) {
            root.forceActiveFocus()
        }
    }

    property var pageCache: {}
    onWidthChanged: {
        for (var i in pageCache) {
            root.pageCache[i].width = width;
            root.pageCache[i].height = height;
        }
    }
    data: [
        Timer {
            id: preloadTimer
            interval: 0
            running: true
            onTriggered: {
                let file = ""
                if (!root.pageCache) {
                    root.pageCache = {};
                }
//                 if (!root.pageCache["zynthiloops"]) {
//                     file = applicationWindow().pageScreenMapping.pageForModalScreen("zynthiloops");
//                     var component = Qt.createComponent(file);
//                     root.pageCache["zynthiloops"] = component.createObject(root, {"width": root.width, "height": root.height});
//                     root.pageCache["zynthiloops"].visible = false;
//                 }
                if (!root.pageCache["session_dashboard"]) {
                    file = applicationWindow().pageScreenMapping.pageForModalScreen("session_dashboard");
                    var component = Qt.createComponent(file);
                    root.pageCache["session_dashboard"] = component.createObject(root, {"width": root.width, "height": root.height});
                    root.pageCache["session_dashboard"].visible = false;
                }
                if (!root.pageCache["song_arranger"]) {
                    file = applicationWindow().pageScreenMapping.pageForModalScreen("song_arranger");
                    var component = Qt.createComponent(file);
                    root.pageCache["song_arranger"] = component.createObject(root, {"width": root.width, "height": root.height});
                    root.pageCache["song_arranger"].visible = false;
                }
                if (!root.pageCache["playgrid"]) {
                    file = applicationWindow().pageScreenMapping.pageForModalScreen("playgrid");
                    var component = Qt.createComponent(file);
                    root.pageCache["playgrid"] = component.createObject(root, {"width": root.width, "height": root.height});
                    root.pageCache["playgrid"].visible = false;
                }
                if (!root.pageCache["sketch_copier"]) {
                    file = applicationWindow().pageScreenMapping.pageForModalScreen("sketch_copier");
                    var component = Qt.createComponent(file);
                    root.pageCache["sketch_copier"] = component.createObject(root, {"width": root.width, "height": root.height});
                    root.pageCache["sketch_copier"].visible = false;
                }
                if (!root.pageCache["midi_key_range"]) {
                    file = applicationWindow().pageScreenMapping.pageForModalScreen("midi_key_range");
                    var component = Qt.createComponent(file);
                    root.pageCache["midi_key_range"] = component.createObject(root, {"width": root.width, "height": root.height});
                    root.pageCache["midi_key_range"].visible = false;
                }
                if (!root.pageCache["sound_categories"]) {
                    file = applicationWindow().pageScreenMapping.pageForModalScreen("sound_categories");
                    var component = Qt.createComponent(file);
                    root.pageCache["sound_categories"] = component.createObject(root, {"width": root.width, "height": root.height});
                    root.pageCache["sound_categories"].visible = false;
                }
            }
        },
        Connections {
            target: zynthian

            onCurrent_screen_idChanged: {
                if (zynthian.current_modal_screen_id.length === 0) {
                    root.clear();
                }
            }

            onCurrent_modal_screen_idChanged: {
                print("MODAL SCREEN ID CHANGED: "+zynthian.current_modal_screen_id);

                // Are we in a dashboard page? don't do anything
                if (applicationWindow().pageScreenMapping.pageForDashboardScreen(zynthian.current_screen_id).length > 0) {
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

                if (root.pageCache && root.pageCache[zynthian.current_modal_screen_id]) {
                    root.replace(root.pageCache[zynthian.current_modal_screen_id]);
                } else {
                    let file = applicationWindow().pageScreenMapping.pageForModalScreen(zynthian.current_modal_screen_id);
                    if (file.length > 0) {
                        root.push(file);
                    } else {
                        print("Non managed modal screen " + zynthian.current_modal_screen_id);
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
        /*Behavior on opacity {
            OpacityAnimator {
               duration: Kirigami.Units.shortDuration
               easing.type: Easing.InOutCubic
            }
        }*/
    }
}
