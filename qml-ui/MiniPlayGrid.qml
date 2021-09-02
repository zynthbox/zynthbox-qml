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

RowLayout {
    id: component
    spacing: 0
    property string currentNoteName: keyModel.getName(zynthian.miniplaygrid.startingNote)
    ColumnLayout {
        z: 1
        Layout.preferredWidth: 64
        Layout.maximumWidth: Layout.preferredWidth
        Layout.fillHeight: true
        Layout.margins: 8
        QQC2.Button {
            Layout.fillWidth: true
            Layout.preferredHeight: width
            Layout.maximumHeight: width
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
                    text: "Hide"
                }
            }
            MultiPointTouchArea {
                anchors.fill: parent
                onPressed: {
                    parent.down = true;
                    focus = true;
                }
                onReleased: {
                    parent.down = false;
                    focus = false;
                    zynthian.callable_ui_action("KEYBOARD")
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

        QQC2.Button {
            id: settingsButton
            Layout.fillWidth: true
            Layout.preferredHeight: width
            Layout.maximumHeight: width
            icon.name: "configure"
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
            Row {
                anchors {
                    top: parent.top
                    left: parent.right
                    bottom: parent.bottom
                }
                width: playGridsRepeater.count * settingsButton.width
                spacing: 0
                opacity: settingsSlidePoint.pressed ? (settingsTouchArea.xChoice > 0 && settingsTouchArea.yChoice === 0 ? 1 : 0.3) : 0
                Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration; } }
                Repeater {
                    model: playGridsRepeater.count
                    delegate: Item {
                        id: slideDelegate
                        property bool hovered: settingsTouchArea.xChoice - 1 === index && settingsTouchArea.yChoice === 0
                        property var playGrid: playGridsRepeater.itemAt(index).item
                        height: parent.height
                        width: settingsButton.width
                        Rectangle {
                            anchors {
                                fill: parent
                                margins: Kirigami.Units.smallSpacing / 2
                            }
                            radius: Math.max(width,height) / 2
                            Kirigami.Theme.inherit: false
                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                            border {
                                width: 1
                                color: slideDelegate.hovered ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                            }
                            color: slideDelegate.hovered ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                        }
                        Rectangle {
                            anchors {
                                left: parent.right
                                bottom: parent.top
                                bottomMargin: -Kirigami.Units.largeSpacing
                            }
                            rotation: -45
                            transformOrigin: Item.BottomLeft
                            height: slideDelegateLabel.height + Kirigami.Units.smallSpacing * 2
                            width: slideDelegateLabel.width + Kirigami.Units.smallSpacing * 2
                            radius: height / 2
                            color: slideDelegate.hovered ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                            QQC2.Label {
                                id: slideDelegateLabel
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    margins: Kirigami.Units.smallSpacing
                                }
                                text: slideDelegate.playGrid.name
                                color: slideDelegate.hovered ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
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
                            if (0 < xChoice && xChoice <= playGridsRepeater.count && zynthian.miniplaygrid.playGridIndex !== xChoice - 1) {
                                zynthian.miniplaygrid.playGridIndex = xChoice - 1
                            }
                        }
                    }
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
        initialItem: playGridsRepeater.count === 0 ? null : playGridsRepeater.itemAt(zynthian.miniplaygrid.playGridIndex).item.miniGrid
        Connections {
            target: zynthian.miniplaygrid
            onPlayGridIndexChanged: {
                if (playGridsRepeater.count > 0) {
                    var playgrid = playGridsRepeater.itemAt(zynthian.miniplaygrid.playGridIndex).item
                    playGridStack.replace(playgrid.miniGrid);
                    //settingsStack.replace(playgrid.settings);
                }
            }
        }

        Repeater {
            id:playGridsRepeater
            model: zynthian.miniplaygrid.playgrids
            property Item currentItem: playGridsRepeater.count === 0 ? null : playGridsRepeater.itemAt(zynthian.miniplaygrid.playGridIndex).item
            Loader {
                id:playGridLoader
                source: modelData + "/main.qml"
                Binding {
                    target: playGridLoader.item
                    property: 'currentNoteName'
                    value: component.currentNoteName
                }
            }
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
    }
}
