 /* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

Copyright (C) 2021 Marco Martin <mart@kde.org>
Copyright (C) 2018 Aleix Pol Gonzalez <aleixpol@kde.org>

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

import QtQuick 2.3
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.4 as Kirigami

QQC2.Menu
{
    id: root
    z: 999999999
    property alias actions: actionsInstantiator.model
    property Component submenuComponent
    //renamed to work on both Qt 5.9 and 5.10
    property Component itemDelegate: QQC2.MenuItem {
        property Kirigami.Action kirigamiAction
        visible: kirigamiAction.visible === undefined || kirigamiAction.visible
        enabled: kirigamiAction.enabled === undefined || kirigamiAction.enabled
        checkable: kirigamiAction.checkable !== undefined && kirigamiAction.checkable
        checked: kirigamiAction.checked !== undefined && kirigamiAction.checked
        height: visible ? implicitHeight : 0
        width: parent ? parent.width : 10 // Just to not spam out during instantiation

        text: kirigamiAction.text
        icon.name: kirigamiAction.icon.name
        onClicked: {
            root.visible = false;
            kirigamiAction.trigger();
        }
    }
    property Component separatorDelegate: QQC2.MenuSeparator { property var action }
    property Component loaderDelegate: Loader { property var action }
    property Kirigami.Action parentAction
    property QQC2.MenuItem parentItem
    modal: true
    QQC2.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.2)
    }

    Item {
        id: invisibleItems
        visible: false
    }
    Instantiator {
        id: actionsInstantiator

        active: root.visible
        delegate: QtObject {
            readonly property Kirigami.Action action: modelData
            property QtObject item: null

            function create() {
                if (!action.hasOwnProperty("children") && !action.children || action.children.length === 0) {
                    if (action.hasOwnProperty("separator") && action.separator) {
                        item = root.separatorDelegate.createObject(null, { action: action });
                    }
                    else if (action.displayComponent) {
                        item = root.loaderDelegate.createObject(null,
                                { action: action, sourceComponent: action.displayComponent });
                    }
                    else {
                        item = root.itemDelegate.createObject(null, { kirigamiAction: action });
                    }
                    root.addItem(item)
                } else if (root.submenuComponent) {
                    item = root.submenuComponent.createObject(null, { parentAction: action, title: action.text, actions: action.children });

                    root.insertMenu(root.count, item)
                    item.parentItem = root.contentData[root.contentData.length-1]
                    item.parentItem.icon = action.icon
                }
            }
            function remove() {
                if (!action.hasOwnProperty("children") && !action.children || action.children.length === 0) {
                    root.removeItem(item)
                } else if (root.submenuComponent) {
                    root.removeMenu(item)
                }
            }
        }

        onObjectAdded: object.create()
        onObjectRemoved: object.remove()
    }
}
