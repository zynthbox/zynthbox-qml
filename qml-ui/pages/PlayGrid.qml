/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Play Grid Page 

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import QtGraphicalEffects 1.0
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

Zynthian.ScreenPage {
    id: component
    screenId: "playgrid"
    leftPadding: 0
    rightPadding: 0
    topPadding: 5
    bottomPadding: 5

    Component.onCompleted: {
        applicationWindow().controlsVisible = false
    }

    Component.onDestruction: {
        applicationWindow().controlsVisible = true
    }
    onVisibleChanged: {
        applicationWindow().controlsVisible = !visible
        if (visible) {
            height = parent.height;
        }
    }

    ListModel {
        id: scaleModel
        ListElement { scale: "chromatic"; text: "Chromatic" }
        ListElement { scale: "ionian"; text: "Ionian (Major)" }
        ListElement { scale: "dorian"; text: "Dorian" }
        ListElement { scale: "phrygian"; text: "Phrygian" }
        ListElement { scale: "lydian"; text: "Lydian" }
        ListElement { scale: "mixolydian"; text: "Mixolydian" }
        ListElement { scale: "aeolian"; text: "Aeolian (Natural Minor)" }
        ListElement { scale: "locrian"; text: "Locrian" }
    }

    ListModel {
        id: keyModel
        function getName(note) {
            for(var i = 0; i < keyModel.rowCount(); ++i) {
                var le = keyModel.get(i);
                if (le.note = note) {
                    return le.text;
                }
            }
            return "C";
        }

        ListElement { note: 36; text: "C" }
        ListElement { note: 37; text: "C#" }
        ListElement { note: 38; text: "D" }
        ListElement { note: 39; text: "D#" }
        ListElement { note: 40; text: "E" }
        ListElement { note: 41; text: "F" }
        ListElement { note: 42; text: "F#" }
        ListElement { note: 43; text: "G" }
        ListElement { note: 44; text: "G#" }
        ListElement { note: 45; text: "A" }
        ListElement { note: 46; text: "A#" }
        ListElement { note: 47; text: "B" }
    }

    ListModel {
        id: gridModel

        ListElement { row: 0; column: 0; text: "Custom" }
        ListElement { row: 3; column: 3; text: "3x3" }
        ListElement { row: 4; column: 4; text: "4x4" }
        ListElement { row: 5; column: 8; text: "5x8" }
    }

    Connections {
        target: ZynQuick.PlayGridManager
        onCurrentPlaygridsChanged: {
            if (playGridsRepeater.count > 0){
                var playgrid = playGridsRepeater.itemAt(ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]).item
                playGridStack.replace(playgrid.grid);
                settingsStack.replace(playgrid.settings);
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            id: controlsPanel
            z: 1

            Layout.preferredWidth: 80
            Layout.maximumWidth: Layout.preferredWidth
            Layout.fillHeight: true
            Layout.margins: 8

            QQC2.Dialog {
                id: settingsDialog
                visible: false
                title: "Settings"
                modal: true
                width: component.width - Kirigami.Units.largeSpacing * 4
                height: component.height - Kirigami.Units.largeSpacing * 4
                x: Kirigami.Units.largeSpacing
                y: Kirigami.Units.largeSpacing

                footer: Zynthian.ActionBar {
                    Layout.fillWidth: true
                    currentPage: Item {
                        property QtObject backAction: Kirigami.Action {
                            text: "Back"
                            onTriggered: {
                                settingsDialog.visible = false;
                            }
                        }
                        property list<QtObject> contextualActions: [
                            Kirigami.Action {
                                text: "Get New Playgrids"
                                onTriggered: {
                                    settingsDialog.visible = false;
                                    zynthian.show_modal("playgrid_downloader");
                                    applicationWindow().controlsVisible = true;
                                }
                            }
                        ]
                    }
                }

                contentItem: RowLayout {
                    ListView {
                        Layout.preferredWidth: settingsDialog.width / 4
                        Layout.maximumWidth: Layout.preferredWidth
                        Layout.fillHeight: true
                        Layout.margins: 8
                        model: playGridsRepeater.count
                        currentIndex: ZynQuick.PlayGridManager.currentPlaygrids["playgrid"] != undefined ? ZynQuick.PlayGridManager.currentPlaygrids["playgrid"] : -1
                        delegate: QQC2.ItemDelegate {
                            id: settingsSelectorDelegate
                            property Item gridComponent: playGridsRepeater.count === 0 ? null : playGridsRepeater.itemAt(model.index).item
                            
                            width: ListView.view.width
                            topPadding: Kirigami.Units.largeSpacing
                            leftPadding: Kirigami.Units.largeSpacing
                            bottomPadding: Kirigami.Units.largeSpacing
                            rightPadding: Kirigami.Units.largeSpacing
                            highlighted: ListView.isCurrentItem
                            background: Rectangle {
                                color: !settingsSelectorDelegate.ListView.isCurrentItem && !settingsSelectorDelegate.pressed
                                    ? "transparent"
                                    : ((settingsSelectorDelegate.ListView.view.activeFocus && !settingsSelectorDelegate.pressed || !settingsSelectorDelegate.ListView.view.activeFocus && settingsSelectorDelegate.pressed)
                                            ? Kirigami.Theme.highlightColor
                                            : Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.4))
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Kirigami.Units.shortDuration
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }
                            contentItem: QQC2.Label {
                                text: settingsSelectorDelegate.gridComponent.name
                                elide: Text.ElideRight
                            }
                            onClicked: {
                                ZynQuick.PlayGridManager.setCurrentPlaygrid("playgrid", model.index);
                            }
                        }
                    }
                    QQC2.StackView {
                        id: settingsStack
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        initialItem: playGridsRepeater.count === 0 ? null : playGridsRepeater.itemAt(ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]).item.settings
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 8
                z: 999

                QQC2.Button {
                    id: settingsButton
                    Layout.fillWidth: true
                    Layout.minimumHeight: width
                    Layout.maximumHeight: width
                    icon.name: "application-menu"
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    background: Rectangle {
                        radius: 2
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        border {
                            width: 1
                            color: Kirigami.Theme.textColor
                        }
                        color: Kirigami.Theme.backgroundColor
                    }
                    Rectangle {
                        id: slideDelegateIconMask
                        anchors {
                            fill: parent
                            margins: Kirigami.Units.largeSpacing
                        }
                        radius: width / 2
                        visible: false
                    }
                    Item {
                        id: settingsPopup
                        visible: false
                        anchors {
                            left: parent.right
                            leftMargin: 8
                            top: parent.top
                            topMargin: -8
                        }
                        height: controlsPanel.height
                        width: component.width / 3
                        Zynthian.Card {
                            anchors.fill: parent
                        }
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0
                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                model: playGridsRepeater.count
                                interactive: playGridsRepeater.count >= (height / settingsButton.height)
                                delegate: QQC2.Button {
                                    width: ListView.view.width
                                    height: settingsButton.height
                                    property var playGrid: playGridsRepeater.itemAt(index).item
                                    icon.name: playGrid.icon
                                    text: playGrid.name
                                    display: QQC2.AbstractButton.TextBesideIcon
                                    enabled: index !== ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]
                                    onClicked: {
                                        settingsPopup.visible = false;
                                        ZynQuick.PlayGridManager.setCurrentPlaygrid("playgrid", index);
                                    }
                                }
                            }
                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.minimumHeight: settingsButton.height
                                Layout.maximumHeight: settingsButton.height
                                icon.name: "configure"
                                text: "Settings..."
                                display: QQC2.AbstractButton.TextBesideIcon
                                onClicked: {
                                    settingsPopup.visible = false;
                                    settingsDialog.visible = true;
                                }
                            }
                        }
                    }
                    Item {
                        anchors {
                            top: settingsPopup.top
                            left: settingsPopup.right
                            leftMargin: Kirigami.Units.largeSpacing
                            bottom: settingsPopup.bottom
                        }
                        width: component.width - settingsPopup.mapToGlobal(settingsPopup.width, 0).x - Kirigami.Units.largeSpacing * 3
                        visible: settingsPopup.visible && gridSettingsPopup.item !== null
                        Zynthian.Card {
                            anchors.fill: parent
                        }
                        Loader {
                            id: gridSettingsPopup
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: playGridsRepeater.currentItem && playGridsRepeater.currentItem.popup ? playGridsRepeater.currentItem.popup : null
                        }
                    }
                    Row {
                        anchors {
                            top: parent.top
                            left: parent.right
                            bottom: parent.bottom
                        }
                        width: playGridsRepeater.count * settingsButton.width
                        spacing: 0
                        visible: settingsSlidePoint.pressed && settingsTouchArea.xChoice > 0
                        Repeater {
                            model: playGridsRepeater.count
                            delegate: Item {
                                id: slideDelegate
                                property bool hovered: settingsTouchArea.xChoice - 1 === index && settingsTouchArea.yChoice === 0
                                property var playGrid: playGridsRepeater.itemAt(index).item
                                property int labelRotation: 45
                                width: settingsButton.width
                                height: width
                                Rectangle {
                                    id: slideDelegateBackground
                                    anchors {
                                        fill: parent
                                        margins: Kirigami.Units.smallSpacing
                                    }
                                    radius: width / 2
                                    Kirigami.Theme.inherit: false
                                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                    border {
                                        width: 1
                                        color: slideDelegate.hovered ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                    }
                                    color: slideDelegate.hovered ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                                }
                                Kirigami.Icon {
                                    anchors {
                                        fill: parent
                                        margins: Kirigami.Units.largeSpacing
                                    }
                                    source: playGrid.icon
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: slideDelegateIconMask
                                    }
                                }
                                Item {
                                    anchors {
                                        left: parent.horizontalCenter
                                        verticalCenter: parent.verticalCenter
                                    }
                                    width: parent.width / 2 + Kirigami.Units.smallSpacing
                                    transformOrigin: Item.Left
                                    rotation: slideDelegate.labelRotation
                                    Rectangle {
                                        anchors {
                                            fill: slideDelegateLabel
                                            margins: -Kirigami.Units.smallSpacing
                                        }
                                        radius: height / 2
                                        color: slideDelegateBackground.color
                                    }
                                    QQC2.Label {
                                        id: slideDelegateLabel
                                        anchors {
                                            verticalCenter: parent.verticalCenter
                                            left: parent.right
                                        }
                                        text: slideDelegate.playGrid.name
                                        color: slideDelegateBackground.border.color
                                    }
                                }
                            }
                        }
                    }
                    function getYChoice() {
                        var choice = 0;
                        if (settingsSlidePoint.pressed) {
                            choice = Math.floor(settingsSlidePoint.y / settingsButton.width);
                        }
                        return choice;
                    }
                    function getXChoice() {
                        var choice = 0;
                        if (settingsSlidePoint.pressed) {
                            choice = Math.floor(settingsSlidePoint.x / settingsButton.height);
                        }
                        return choice;
                    }
                    MultiPointTouchArea {
                        id: settingsTouchArea
                        anchors.fill: parent
                        touchPoints: [ TouchPoint { id: settingsSlidePoint; } ]
                        property int xChoice
                        property int yChoice
                        onPressed: {
                            if (settingsSlidePoint.pressed) {
                                xChoice = settingsButton.getXChoice();
                                yChoice = settingsButton.getYChoice();
                                parent.down = true;
                            }
                        }
                        onUpdated: {
                            if (settingsSlidePoint.pressed) {
                                xChoice = settingsButton.getXChoice();
                                yChoice = settingsButton.getYChoice();
                            }
                        }
                        onReleased: {
                            if (!settingsSlidePoint.pressed) {
                                parent.down = false;
                                if (xChoice === 0 && yChoice === 0) {
                                    // Then it we just had a tap
                                    settingsPopup.visible = !settingsPopup.visible
                                } else if (xChoice === 0 && yChoice !== 0) {
                                    switch (yChoice) {
                                        case -1:
                                            // Enable the swipey manipulation on the grids
                                            break;
                                        case -2:
                                            // Disable the swipy manipulation on the grids
                                            break;
                                        default:
                                            break;
                                    }
                                } else if (yChoice === 0 && xChoice !== 0) {
                                    if (0 < xChoice && xChoice <= playGridsRepeater.count && ZynQuick.PlayGridManager.currentPlaygrids["playgrid"] !== xChoice - 1) {
                                        ZynQuick.PlayGridManager.setCurrentPlaygrid("playgrid", xChoice - 1);
                                    }
                                }
                            }
                        }
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    sourceComponent: playGridsRepeater.currentItem && playGridsRepeater.currentItem.sidebar ? playGridsRepeater.currentItem.sidebar : defaultSidebar
                }
            }
        }

        QQC2.StackView {
            id: playGridStack
            z: 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            initialItem: playGridsRepeater.count === 0 ? null : playGridsRepeater.itemAt(ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]).item.grid
        }
    }

    Component {
        id: defaultSidebar
        ColumnLayout {
            Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon.name: "arrow-up"
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                enabled: playGridsRepeater.currentItem && playGridsRepeater.currentItem.useOctaves ? playGridsRepeater.currentItem.useOctaves : false
                background: Rectangle {
                    radius: 2
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    border {
                        width: 1
                        color: Kirigami.Theme.textColor
                    }
                    color: Kirigami.Theme.backgroundColor
                }
                onClicked: {
                    if (playGridsRepeater.currentItem.octave + 1 < 11){
                        playGridsRepeater.currentItem.octave =  playGridsRepeater.currentItem.octave + 1;
                    } else {
                        playGridsRepeater.currentItem.octave =  10;
                    }
                }
            }

            QQC2.Label {
                text: "Octave"
                Layout.alignment: Qt.AlignHCenter
            }

            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon.name: "arrow-down"
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                enabled: playGridsRepeater.currentItem && playGridsRepeater.currentItem.useOctaves ? playGridsRepeater.currentItem.useOctaves : false
                background: Rectangle {
                    radius: 2
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    border {
                        width: 1
                        color: Kirigami.Theme.textColor
                    }
                    color: Kirigami.Theme.backgroundColor
                }
                onClicked: {
                    if (playGridsRepeater.currentItem.octave - 1 > 0) {
                        playGridsRepeater.currentItem.octave = playGridsRepeater.currentItem.octave - 1;
                    } else {
                        playGridsRepeater.currentItem.octave = 0;
                    }
                }
            }

            Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                background: Rectangle {
                    radius: 2
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    border {
                        width: 1
                        color: Kirigami.Theme.textColor
                    }
                    color: Kirigami.Theme.backgroundColor

                    Text {
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: Kirigami.Theme.textColor
                        text: "Mod\nulate"
                    }
                }
                MultiPointTouchArea {
                    anchors.fill: parent
                    property int modulationValue: Math.max(-127, Math.min(modulationPoint.y * 127 / width, 127))
                    onModulationValueChanged: {
                        ZynQuick.PlayGridManager.modulation = modulationValue;
                    }
                    touchPoints: [ TouchPoint { id: modulationPoint; } ]
                    onPressed: {
                        parent.down = true;
                        focus = true;
                    }
                    onReleased: {
                        parent.down = false;
                        focus = false;
                        ZynQuick.PlayGridManager.modulation = 0;
                    }
                }
            }

            Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon.name: "arrow-up"
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                background: Rectangle {
                    radius: 2
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    border {
                        width: 1
                        color: Kirigami.Theme.textColor
                    }
                    color: Kirigami.Theme.backgroundColor
                }
                MultiPointTouchArea {
                    anchors.fill: parent
                    onPressed: {
                        parent.down = true;
                        focus = true;
                        ZynQuick.PlayGridManager.pitch = 8191;
                    }
                    onReleased: {
                        parent.down = false;
                        focus = false;
                        ZynQuick.PlayGridManager.pitch = 0;
                    }
                }
            }
            QQC2.Label {
                text: "Pitch"
                Layout.alignment: Qt.AlignHCenter
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon.name: "arrow-down"
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                background: Rectangle {
                    radius: 2
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    border {
                        width: 1
                        color: Kirigami.Theme.textColor
                    }
                    color: Kirigami.Theme.backgroundColor
                }
                MultiPointTouchArea {
                    anchors.fill: parent
                    onPressed: {
                        parent.down = true;
                        focus = true;
                        ZynQuick.PlayGridManager.pitch = -8192;
                    }
                    onReleased: {
                        parent.down = false;
                        focus = false;
                        ZynQuick.PlayGridManager.pitch = 0;
                    }
                }
            }
        }
    }


    Repeater {
        id:playGridsRepeater
        model: ZynQuick.PlayGridManager.playgrids
        property Item currentItem: playGridsRepeater.count === 0 ? null : playGridsRepeater.itemAt(ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]).item
        Loader {
            id:playGridLoader
            source: modelData + "/main.qml"
        }
    }

}
