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

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

import "private"

QQC2.ScrollView {
    id: root

    property alias view: view
    property alias model: view.model
    property alias delegate: view.delegate
    property alias currentIndex: view.currentIndex
    property alias highlighted: background.highlighted
    property bool active: true
    property string screenId
    //TODO: Bind the base selector type to qml?
    readonly property QtObject selector: screenId.length > 0 ? zynqtgui[screenId] : null
    property bool autoActivateIndexOnChange
    property var cuiaCallback: function (cuia) {
        var returnVal = false

        switch(cuia) {
            case "KNOB3_UP":
                root.selector.select_down()
                returnVal = true
                break
            case "KNOB3_DOWN":
                root.selector.select_up()
                returnVal = true
                break
        }

        return returnVal
    }

    signal currentScreenIdRequested(string screenId)
    signal itemActivated(string screenId, int index)
    signal itemActivatedSecondary(string screenId, int index)
    signal iconClicked(string screenId, int index)

    Component.onCompleted: {
        if (zynqtgui.current_screen_id === root.screenId) {
            view.forceActiveFocus();
        }
        root.selector.autoActivateIndexOnChange = Qt.binding(function() {
            return root.autoActivateIndexOnChange
        })
    }
    onActiveFocusChanged: {
        if (activeFocus) {
            root.currentScreenIdRequested(root.screenId);
        }
    }

    leftPadding: background.leftPadding
    rightPadding: background.rightPadding
    topPadding: background.topPadding
    bottomPadding: background.bottomPadding

    QQC2.ScrollBar.horizontal.visible: false

    QQC2.ScrollBar.vertical.x: view.x + view.width  - QQC2.ScrollBar.vertical.width// - root.rightPadding


    contentItem: ListView {
        id: view
        keyNavigationEnabled: true
        keyNavigationWraps: false
        clip: true
        Binding {
            target: view
            property: "currentIndex"
            value: root.selector.current_index
            when: root.active
            delayed: true
            restoreMode: Binding.RestoreBindingOrValue
        }
        reuseItems: true
        cacheBuffer: Kirigami.Units.gridUnit*2
        highlightMoveDuration: 0
        highlightMoveVelocity: -1

        onActiveFocusChanged: {
            if (activeFocus) {
                root.currentScreenIdRequested(root.screenId);
            }
        }

        onCountChanged: syncPosTimer.restart()

        //highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: Kirigami.Units.gridUnit * 2
        preferredHighlightEnd: Kirigami.Units.gridUnit * 4

        Binding {
            target: view
            property: "model"
            value: root.selector.selector_list
            when: root.active
            delayed: true
            restoreMode: Binding.RestoreBindingOrValue
        }

        delegate: SelectorDelegate {
            screenId: root.screenId
            selector: root.selector
            highlighted: zynqtgui.current_screen_id === root.screenId
            onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
            onItemActivated: root.itemActivated(screenId, index)
            onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
            onIconClicked: root.iconClicked(screenId, index)
        }
    }

    Connections {
        id: focusConnection
        target: zynqtgui
        onCurrent_screen_idChanged: {
            if (zynqtgui.current_screen_id === root.screenId) {
                view.forceActiveFocus();
            }
        }
    }

    function forceViewPosition(ignoreActive=false) {
        // Force view position only when current visible page has this selectorview or if ignoreActive is set to true
        //
        // Check if current page is SelectorView's page
        // For all other pages except "layers_for_channel", zynqtgui.current_screen_id and root.screenId should be same for a SelectorView
        // In "layers_for_channel" page, there are 2 SelectorViews (preset and bank) which belong to layers_for_channel page
        if (ignoreActive || zynqtgui.current_screen_id === root.screenId || (['bank', 'preset'].indexOf(root.screenId) >= 0 && zynqtgui.current_screen_id === "layers_for_channel")) {
            root.view.positionViewAtIndex(root.currentIndex, ListView.SnapPosition)
            root.view.contentY-- //HACK: workaround for Qt 5.11 ListView sometimes not reloading its items after positionViewAtIndex
            root.view.forceLayout()
        }
    }
    onVisibleChanged: root.forceViewPosition();
    Timer {
        id: syncPosTimer
        interval: 100
        onTriggered: root.forceViewPosition();
    }

    Kirigami.Separator {
        parent: view
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        color: Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2))
        opacity: 1
        visible: !view.atYBeginning
    }
    Kirigami.Separator {
        parent: view
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        color: Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2))
        opacity: 1
        visible: !view.atYEnd
    }


    background: SelectorViewBackground {
        id: background
        //highlighted: view.activeFocus || zynqtgui.current_screen_id === root.screenId || (zynqtgui.current_screen_id === "layer" && root.screenId === "fixed_layers")
    }
}

