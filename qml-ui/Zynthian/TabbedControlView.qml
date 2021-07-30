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

Item {
    id: root

    // FIXME: Use Kirigami.PAgePool when frameworks will be recent enough
    property list<Zynthian.TabbedControlViewAction> tabActions

    RowLayout {
        anchors.fill: parent
        ColumnLayout {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 6
            Layout.fillHeight: true
            Repeater {
                model: root.tabActions
                delegate: QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: modelData.text
                    autoExclusive: true
                    enabled: modelData.enabled
                    visible: modelData.visible
                    checkable: true
                    checked: internalStack.activeAction === modelData
                    onClicked: {
                        internalStack.replace(modelData.page);
                        internalStack.activeAction = modelData;
                        if (modelData.children.length > 0) {
                            internalStack.activeSubAction = modelData.children[0]
                        }
                    }
                }
            }
            Repeater {
                model: Math.max(0, 6 - root.tabActions.length)
                delegate: QQC2.Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    enabled: false
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Zynthian.Stack {
                id: internalStack
                property Zynthian.TabbedControlViewAction activeAction: tabActions[0]
                property Zynthian.TabbedControlViewAction activeSubAction: tabActions[0].children[0]
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                initialItem: Qt.resolvedUrl(tabActions[0].page)
            }
            RowLayout {
                Layout.fillWidth: true
                visible: internalStack.activeAction && internalStack.activeAction.children.length > 0
                Repeater {
                    model: internalStack.activeAction.children
                    delegate: QQC2.Button {
                        implicitWidth: 1
                        Layout.fillWidth: true
                        text: modelData.text
                        autoExclusive: true
                        enabled: modelData.enabled
                        visible: modelData.visible
                        checkable: true
                        checked: internalStack.activeSubAction === modelData
                        onClicked: {
                            internalStack.replace(modelData.page);
                            internalStack.activeSubAction = modelData;
                        }
                    }
                }
            }
        }
    }
}
