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
    property int minimumTabsCount: 6
    property int orientation: Qt.Horizontal
    property Zynthian.TabbedControlViewAction initialAction: tabActions[0]
    readonly property Zynthian.TabbedControlViewAction activeAction: internalStack.activeAction

    property var cuiaCallback: function(cuia) {
        let focusedScope = internalStack.activeFocus ? internalStack : (primaryTabsScope.activeFocus ? primaryTabsScope : secondaryTabsScope)
        if (!focusedScope.activeFocus) {
            focusedScope.forceActiveFocus()
        }

        switch (cuia) { //TODO: figure out rows and columns
        // Eat select actions
        case "SWITCH_SELECT_SHORT":
        case "SWITCH_SELECT_BOLD":
        case "SWITCH_SELECT_LONG":
            return true;
        case "NAVIGATE_LEFT":
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
            } else if (focusedScope === secondaryTabsScope) {
                var button = nextFocusItemInScope(secondaryTabsScope, false);
                if (button) {
                    button.forceActiveFocus();
                    button.tabAction.trigger();
                }
            }

            return true;
        case "SELECT_UP":
            if (focusedScope === primaryTabsScope) {
                var button = nextFocusItemInScope(primaryTabsScope, false);
                if (button) {
                    button.forceActiveFocus();
                    button.tabAction.trigger();
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
            } else if (focusedScope === secondaryTabsScope) {
                internalStack.forceActiveFocus();
            }
            return true;

        case "SELECT_DOWN":
            if (focusedScope === primaryTabsScope) {
                var button = nextFocusItemInScope(primaryTabsScope, true);
                if (button) {
                    button.forceActiveFocus();
                    button.tabAction.trigger();
                }
            } else if (focusedScope === internalStack) {
                var layoutInfo = gridLayoutInfoFor(Window.activeFocusItem);
                if (layoutInfo) {
                    var newIndex = Number(layoutInfo.position) + layoutInfo.layout.columns;
                    if (newIndex < layoutInfo.layout.children.length) {
                        layoutInfo.layout.children[newIndex].forceActiveFocus();
                    } else {
                        secondaryTabsScope.forceActiveFocus();
                    }
                } else {
                    var controller = nextFocusItemInScope(internalStack, true);
                    if (controller) {
                        controller.forceActiveFocus();
                    }
                }
            }

            return true;
        case "NAVIGATE_RIGHT":
            if (focusedScope === primaryTabsScope) {
                internalStack.forceActiveFocus()
            } else if (focusedScope === internalStack) {
                var controller = nextFocusItemInScope(internalStack, true);
                if (controller) {
                    controller.forceActiveFocus();
                }
            } else if (focusedScope === secondaryTabsScope) {
                var button = nextFocusItemInScope(secondaryTabsScope, true);
                if (button) {
                    button.forceActiveFocus();
                    button.tabAction.trigger();
                }
            }
            return true;
        case "INCREASE":
            if (focusedScope === internalStack) {
                if (Window.activeFocusItem && Window.activeFocusItem.increase) {
                    Window.activeFocusItem.increase();
                }
            }
            return true;
        case "DECREASE":
            if (focusedScope === internalStack) {
                if (Window.activeFocusItem && Window.activeFocusItem.decrease) {
                    Window.activeFocusItem.decrease();
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

    Component.onCompleted: internalStack.forceActiveFocus()

    GridLayout {
        columns: root.orientation === Qt.Horizontal ? 2 : 1
        anchors.fill: parent
        FocusScope {
            id: primaryTabsScope
            opacity: tabsLayout.visibleChildren.length > 3 ? 1 : 0
            Layout.minimumWidth: root.orientation === Qt.Horizontal ? Layout.maximumWidth : -1
            Layout.maximumWidth: root.orientation === Qt.Horizontal ? Kirigami.Units.gridUnit * 6 : -1
            Layout.minimumHeight: root.orientation === Qt.Horizontal ? -1 : Layout.maximumHeight
            Layout.maximumHeight: root.orientation === Qt.Horizontal ? -1 : Kirigami.Units.gridUnit * 1.6
            Layout.fillHeight: root.orientation === Qt.Horizontal
            Layout.fillWidth: root.orientation !== Qt.Horizontal
            GridLayout {
                id: tabsLayout
                columns: root.orientation === Qt.Horizontal ? 1 : undefined
                rows: root.orientation === Qt.Horizontal ? undefined : 1
                anchors.fill: parent

                Repeater {
                    model: root.tabActions
                    delegate: QQC2.Button {
                        readonly property Zynthian.TabbedControlViewAction tabAction: modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        implicitWidth: 1
                        implicitHeight: 1
                        text: modelData.text
                        autoExclusive: true
                        enabled: modelData.enabled
                        visible: modelData.visible
                        checkable: true
                        checked: internalStack.activeAction === modelData
                        onCheckedChanged: {
                            if (checked) {
                                modelData.trigger();
                            }
                        }
                        Connections {
                            target: modelData
                            onTriggered: {
                                if (internalStack.activeAction === modelData) {
                                    return;
                                }
                                internalStack.replace(modelData.page, modelData.initialProperties);
                                internalStack.activeAction = modelData;
                                if (modelData.children.length > 0) {
                                    internalStack.activeSubAction = modelData.children[0]
                                }
                            }
                        }
                    }
                }
                Repeater {
                    model: Math.max(0, root.minimumTabsCount - root.tabActions.length)
                    delegate: QQC2.Button {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        implicitWidth: 1
                        implicitHeight: 1
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
                property Zynthian.TabbedControlViewAction activeAction: root.initialAction
                property Zynthian.TabbedControlViewAction activeSubAction: root.initialAction.children[0]
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                onActiveFocusChanged: {
                    if (activeFocus) {
                        nextItemInFocusChain(true).forceActiveFocus()
                    }
                }
                Component.onCompleted: {
                    internalStack.push(Qt.resolvedUrl(root.initialAction.page), root.initialAction.initialProperties);
                }
            }
            FocusScope {
                id: secondaryTabsScope
                implicitHeight: secondaryTabLayout.implicitHeight
                Layout.fillWidth: true
                visible: internalStack.activeAction && internalStack.activeAction.children.length > 0
                RowLayout {
                    id: secondaryTabLayout
                    anchors.fill: parent
                    Repeater {
                        model: internalStack.activeAction.children
                        delegate: QQC2.Button {
                            readonly property Zynthian.TabbedControlViewAction tabAction: modelData
                            implicitWidth: 1
                            Layout.fillWidth: true
                            text: modelData.text
                            autoExclusive: true
                            enabled: modelData.enabled
                            visible: modelData.visible
                            checkable: true
                            checked: internalStack.activeSubAction === modelData
                            onClicked: {
                                internalStack.replace(modelData.page, modelData.initialProperties);
                                internalStack.activeSubAction = modelData;
                            }
                        }
                    }
                }
            }
        }
    }
}
