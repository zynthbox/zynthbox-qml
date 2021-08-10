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
import QtQuick.Window 2.10
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

Item {
    id: root

    // FIXME: Use Kirigami.PAgePool when frameworks will be recent enough
    property list<Zynthian.TabbedControlViewAction> tabActions

    property var cuiaCallback: function(cuia) {
        let focusedScope = internalStack.activeFocus ? internalStack : primaryTabsScope
        if (!focusedScope.activeFocus) {
            focusedScope.forceActiveFocus()
        }

        switch (cuia) { //TODO: figure out rows and columns
        // Eat select actions
        case "SWITCH_SELECT_SHORT":
        case "SWITCH_SELECT_BOLD":
        case "SWITCH_SELECT_LONG":
            return true;
        case "SWITCH_BACK_SHORT":
        case "SWITCH_BACK_BOLD":
        case "SWITCH_BACK_LONG":
            if (focusedScope === primaryTabsScope) {
                return false;
            } else if (focusedScope === internalStack) {
                var layoutInfo = gridLayoutInfoFor(Window.activeFocusItem);
                if (layoutInfo && (layoutInfo.position % layoutInfo.layout.columns !== 0)) {
                    var controller = nextFocusItemInScope(internalStack, false);
                    if (controller) {
                        controller.forceActiveFocus();
                    }
                } else {
                    primaryTabsScope.forceActiveFocus();
                }
            }

            return true;
        case "SELECT_UP":
            if (focusedScope === primaryTabsScope) {
                var button = nextFocusItemInScope(primaryTabsScope, false);
                if (button) {
                    button.forceActiveFocus();
                    button.clicked();
                }
            } else if (focusedScope === internalStack) {
                var layoutInfo = gridLayoutInfoFor(Window.activeFocusItem);
                if (layoutInfo) {
                    var newIndex = Number(layoutInfo.position) - layoutInfo.layout.columns;
                    if (newIndex >= 0) {
                        layoutInfo.layout.children[newIndex].forceActiveFocus();
                    }
                } else {
                    var controller = nextFocusItemInScope(internalStack, false);
                    if (controller) {
                        controller.forceActiveFocus();
                    }
                }
            }
            return true;

        case "SELECT_DOWN":
            if (focusedScope === primaryTabsScope) {
                var button = nextFocusItemInScope(primaryTabsScope, true);
                if (button) {
                    button.forceActiveFocus();
                    button.clicked();
                }
            } else if (focusedScope === internalStack) {
                var layoutInfo = gridLayoutInfoFor(Window.activeFocusItem);
                if (layoutInfo) {
                    var newIndex = Number(layoutInfo.position) + layoutInfo.layout.columns;
                    if (newIndex < layoutInfo.layout.children.length) {
                        layoutInfo.layout.children[newIndex].forceActiveFocus();
                    }
                } else {
                    var controller = nextFocusItemInScope(internalStack, true);
                    if (controller) {
                        controller.forceActiveFocus();
                    }
                }
            }

            return true;
        case "NEXT_SCREEN":
            if (focusedScope === primaryTabsScope) {
                internalStack.forceActiveFocus()
            } else if (focusedScope === internalStack) {
                var controller = nextFocusItemInScope(internalStack, true);
                if (controller) {
                    controller.forceActiveFocus();
                }
            }
            return true;
        default:
            return false;
        }
    }

    function nextFocusItemInScope(scope, forward) {
        if (scope.activeFocus) {
            var item = Window.activeFocusItem.nextItemInFocusChain(forward);
            //Check if the item is still in scope
            var candidate = item;
            while (candidate = candidate.parent) {
                if (candidate === scope) {
                    return item;
                }
            }
        }
        return null;
    }

    function gridLayoutInfoFor(item) {
        var result = null;
        var candidate = item;
        while (candidate && candidate != internalStack && candidate != root) {
            candidate = candidate.parent;
            if (candidate && candidate.parent && candidate.parent.parent
                && candidate.parent.parent == internalStack
                && candidate.parent instanceof GridLayout) {
                let layout = candidate.parent;
                let index = -1;
                var i;
                for (i in layout.children) {
                    let child = layout.children[i];
                    if (child === candidate) {
                        index = i;
                        break;
                    }
                }

                if (index >= 0) {
                    return {"layout": layout, "position": index};
                } else {
                    return null;
                }
            }
        }
        return null;
    }

    Component.onCompleted: primaryTabsScope.children[1].forceActiveFocus()

    RowLayout {
        anchors.fill: parent
        FocusScope {
            id: primaryTabsScope
            Layout.minimumWidth: Layout.maximumWidth
            Layout.maximumWidth: Kirigami.Units.gridUnit * 6
            Layout.fillHeight: true
            ColumnLayout {
                anchors.fill: parent

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
                onActiveFocusChanged: {
                    if (activeFocus) {
                        nextItemInFocusChain(true).forceActiveFocus()
                    }
                }
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
