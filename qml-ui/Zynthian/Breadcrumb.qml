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

import "private"

QQC2.ToolBar {
    id: root
    property alias leftHeaderControl: leftHeaderControl.contentItem
    property alias rightHeaderControl: rightHeaderControl.contentItem
    readonly property Item pageRow: applicationWindow().pageStack //FIXME: is really what we want?

    leftPadding: 0
    rightPadding: 0
    position: QQC2.ToolBar.Header
    onPageRowChanged: syncConnection.syncBreadCrumb()
    Component.onCompleted: syncConnection.syncBreadCrumb()
    Connections {
        id: syncConnection
        target: root.pageRow
        onDepthChanged: syncBreadCrumb()
        function syncBreadCrumb() {
            breadcrumbModel.clear();
            for (var i = 0; i < root.pageRow.depth; ++i) {
                let page = root.pageRow.get(i);
                if (page.hasOwnProperty("screenIds")) {
                    for (var j = 0; j < page.screenIds.length; ++j) {
                        let id = page.screenIds[j];
                        breadcrumbModel.append({"screenId": id, "page": page});
                    }
                } else {
                    breadcrumbModel.append({"screenId": page.screenId, "page": page});
                }
            }
        }
    }
    contentItem: RowLayout {
        spacing: 0
        QQC2.Control {
            id: leftHeaderControl
            z: 999
            Layout.fillHeight: true
            visible: contentItem !== null
        }
        Item {
            id: breadcrumbParent
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                id: breadcrumbLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: Math.min(implicitWidth, parent.width)
                spacing: 0
                Repeater {
                    model: ListModel {
                        id: breadcrumbModel
                    }
                    BreadcrumbButton {
                        id: toolButton
                        Layout.fillWidth: true
                        text: zynqtgui[model.screenId].selector_path_element
                               || zynqtgui[model.screenId].selector_path.replace("Jalv/", "")
                               //|| model.page.title //HACK for name shortening
                        // HACK to hide home button as there is already one
                        visible: (index > 1 /*|| root.layerManager.depth > 1*/) && text.length > 0
                        highlighted: model.screenId === zynqtgui.current_screen_id;
                        //enabled: root.layerManager.depth === 1

                        onClicked: {
                            //if (root.layerManager.depth > 1 && applicationWindow().pageScreenMapping.pageForScreen(model.screenId).length === 0) {
                                //zynqtgui.current_modal_screen_id = model.screenId;
                            //}
                            zynqtgui.current_screen_id = model.screenId;
                        }
                    }
                }
            }
        }

        QQC2.Control {
            id: rightHeaderControl
            z: 999
            Layout.fillHeight: true
            visible: contentItem !== null
        }
    }
}
