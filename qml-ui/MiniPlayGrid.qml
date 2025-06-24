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
import QtGraphicalEffects 1.0
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox
import "pages" as Pages

RowLayout {
    id: component
    spacing: 0

    Item{
        implicitWidth: 64
        Layout.fillHeight: true
        Layout.margins: 8

        ColumnLayout {
            z: 1
            anchors.fill: parent
            spacing: Kirigami.Units.mediumSpacing

            Zynthian.PlayGridButton {
                id: settingsButton
                Layout.preferredHeight: width
                Layout.maximumHeight: width
                icon.name: "configure"
                // TODO Reenable this for properly we re-add the ability to have more plaground modules
                visible: applicationWindow().playGrids.count > 2
                Rectangle {
                    id: slideDelegateIconMask
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.largeSpacing
                    }
                    radius: width / 2
                    visible: false
                }
                Row {
                    anchors {
                        top: parent.top
                        left: parent.right
                        bottom: parent.bottom
                    }
                    width: applicationWindow().playGrids.count * settingsButton.width
                    spacing: 0
                    opacity: settingsSlidePoint.pressed ? 1 : 0
                    Repeater {
                        model: applicationWindow().playGrids.count
                        delegate: Item {
                            id: slideDelegate
                            property bool hovered: settingsTouchArea.xChoice - 1 === index && settingsTouchArea.yChoice === 0
                            property var playGrid: applicationWindow().playGrids.itemAt(index).item
                            property int labelRotation: -45
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
                        choice = Math.floor(settingsSlidePoint.y / settingsButton.height);
                    }
                    return choice;
                }
                function getXChoice() {
                    var choice = 0;
                    if (settingsSlidePoint.pressed) {
                        choice = Math.floor(settingsSlidePoint.x / settingsButton.width);
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
                                //settingsDialog.visible = true;
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
                                if (0 < xChoice && xChoice <= applicationWindow().playGrids.count && Zynthbox.PlayGridManager.currentPlaygrids["minigrid"] !== xChoice - 1) {
                                    Zynthbox.PlayGridManager.setCurrentPlaygrid("minigrid", xChoice - 1);
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true; Layout.fillHeight: true; }

            QQC2.Label {
                text: "Octave"
                Layout.alignment: Qt.AlignHCenter
                font.weight: Font.Normal
                font.pointSize: 10
                font.capitalization: Font.AllUppercase
                font.family: "Hack"
            }

            QQC2.Control {
                padding: 1
                Layout.fillWidth: true
                background: Rectangle
                {
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    Kirigami.Theme.inherit: false
                    color: Kirigami.Theme.alternateBackgroundColor
                    radius: 4
                    border.color: Qt.darker(Kirigami.Theme.alternateBackgroundColor, 1.5)
                }

                contentItem: Column {
                    spacing: 0
                    QQC2.Button {
                        icon.name: "arrow-up"
                        width: parent.width
                        height: width
                        // Layour.preferredHeight: width
                        icon.width: 24
                        icon.height: 24
                        enabled: playGridStack.currentPlayGridItem && playGridStack.currentPlayGridItem.useOctaves ? playGridStack.currentPlayGridItem.useOctaves : false
                        onClicked: {
                            if (playGridStack.currentPlayGridItem.octave < playGridStack.currentPlayGridItem.gridRowStartNotes.length - 2) {
                                playGridStack.currentPlayGridItem.octave =  playGridStack.currentPlayGridItem.octave + 1;
                            }
                        }
                        background: Rectangle
                        {
                            color: parent.pressed || parent.highlighted ? Kirigami.Theme.highlightColor : "transparent"
                            radius: 4
                        }
                    }

                    Kirigami.Separator{
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        Kirigami.Theme.inherit: false
                        width: parent.width
                        height: 1
                        color: Qt.darker(Kirigami.Theme.alternateBackgroundColor, 1.5)
                    }

                    QQC2.Button {
                        icon.name: "arrow-down"
                        width: parent.width
                        height: width
                        // Layour.preferredHeight: width
                        icon.width: 24
                        icon.height: 24
                        enabled: playGridStack.currentPlayGridItem && playGridStack.currentPlayGridItem.useOctaves ? playGridStack.currentPlayGridItem.useOctaves : false
                        onClicked: {
                            if (playGridStack.currentPlayGridItem.octave > 0) {
                                playGridStack.currentPlayGridItem.octave = playGridStack.currentPlayGridItem.octave - 1;
                            }
                        }
                        background: Rectangle
                        {
                            color: parent.pressed || parent.highlighted ? Kirigami.Theme.highlightColor : "transparent"
                            radius: 4
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true; Layout.fillHeight: true; }

            QQC2.Button {
                text: "Hide"
                Layout.fillWidth: true
                // Layour.preferredHeight: width
                icon.width: 64
                implicitHeight: 64
                background: null
                onClicked: {
                    zynqtgui.callable_ui_action_simple("HIDE_KEYBOARD")
                }
            }
        }
    }

    QQC2.StackView {
        id: playGridStack
        z: 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        replaceEnter: Transition {}
        replaceExit: Transition {}
        popEnter: Transition {}
        popExit: Transition {}
        pushEnter: Transition {}
        pushExit: Transition {}
        initialItem: currentPlayGridItem.miniGrid
        property Item currentPlayGridItem: applicationWindow().playGrids.count === 0 ? null : applicationWindow().playGrids.itemAt(Zynthbox.PlayGridManager.currentPlaygrids["minigrid"]).item
        property int currentPlaygrid: -1
        function updatePlaygrid() {
            updatePlaygridTimer.restart();
        }
        Timer {
            id: updatePlaygridTimer
            interval: 1; repeat: false; running: false;
            onTriggered: {
                if (applicationWindow().playGrids.count > 0 && playGridStack.currentPlaygrid != Zynthbox.PlayGridManager.currentPlaygrids["minigrid"]) {
                    var playgrid = applicationWindow().playGrids.itemAt(Zynthbox.PlayGridManager.currentPlaygrids["minigrid"]).item
                    playGridStack.replace(playgrid.miniGrid);
                    //settingsStack.replace(playgrid.settings);
                    playGridStack.currentPlaygrid = Zynthbox.PlayGridManager.currentPlaygrids["minigrid"];
                }
            }
        }
        Connections {
            target: Zynthbox.PlayGridManager
            Component.onCompleted: playGridStack.updatePlaygrid();
            onPlaygridsChanged: playGridStack.updatePlaygrid();
            onCurrentPlaygridsChanged: playGridStack.updatePlaygrid();
        }
    }
}
