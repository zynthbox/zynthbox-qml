/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

ComboBox like touch friendly component based on Popup

Copyright (C) 2023 Anupam Basak <anupam.basak27@gmail.com>

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
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import Zynthian 1.0 as Zynthian

QQC2.Button {
    id: root

    property var model
    property string textRole: ""
    property string textPrefix: ""
    property int currentIndex: -1
    property QtObject currentItem: null
    property string currentText: ""
    property var comboBoxPopup: popupComponent.createObject(applicationWindow(), {"model": root.model})

    signal activated(int index)
    function selectIndex(index) {
        root.currentIndex = index;
        if (-1 < index && index < comboBoxPopup.popupListView.count) {
            comboBoxPopup.popupListView.positionViewAtIndex(index, ListView.Center);
        }
    }

    contentItem: QQC2.Label {
        horizontalAlignment: QQC2.Label.AlignLeft
        verticalAlignment: QQC2.Label.AlignVCenter
        text: root.currentText
        color: Kirigami.Theme.textColor
    }
    onCurrentIndexChanged: {
        root.currentItem = comboBoxPopup.popupListView.itemAtIndex(root.currentIndex);
        if (root.currentItem) {
            root.currentText = root.currentItem.text;
        } else {
            root.currentText = "";
        }
    }
    onClicked: {
        comboBoxPopup.open()
    }

    Component {
        id: popupComponent

        // If popup is not instantiated with createObject having parent set to applicationWindow(), qml reports an error
        // saying it cannot find a window to open popup in. So set visual parent to Overlay and while instantiating set
        // object parent to application window

        Zynthian.Popup {
            id: popupRoot

            property alias popupListView: popupListView
            property alias model: popupListView.model

            property var cuiaCallback: function(cuia) {
                var returnValue = true;
                switch (cuia) {
                    case "KNOB3_UP":
                    case "SELECT_DOWN":
                    case "NAVIGATE_RIGHT":
                        root.selectIndex(root.currentIndex + 1);
                        break;
                    case "KNOB3_DOWN":
                    case "SELECT_UP":
                    case "NAVIGATE_LEFT":
                        root.selectIndex(root.currentIndex - 1);
                        break;
                    case "SWITCH_SELECT_SHORT":
                    case "SWITCH_SELECT_BOLD":
                    case "SWITCH_SELECT_LONG":
                        root.activated(root.currentIndex);
                        popupRoot.close();
                        break;
                    case "SWITCH_BACK_SHORT":
                    case "SWITCH_BACK_BOLD":
                    case "SWITCH_BACK_LONG":
                        popupRoot.close();
                        break;
                }

                return returnValue;
            }

            parent: QQC2.Overlay.overlay
            x: parent.width / 2 - width / 2
            y: parent.height / 2 - height / 2
            width: Kirigami.Units.gridUnit * 20
            height: Math.min(popupListView.count * Kirigami.Units.gridUnit * 2, parent.height * 0.8)
            clip: true

            ListView {
                id: popupListView
                anchors.fill: parent
                cacheBuffer: height * 2
                currentIndex: root.currentIndex
                delegate: QQC2.ItemDelegate {
                    id: delegate
                    width: ListView.view.width
                    height: Kirigami.Units.gridUnit * 2
                    text: "%1%2".arg(root.textPrefix).arg(modelData ? modelData[root.textRole] : model[root.textRole])
                    highlighted: popupListView.currentIndex === index || delegate.pressed
                    contentItem: Item {
                        anchors.fill: parent
                        Rectangle {
                            anchors.fill: parent
                            visible: delegate.highlighted
                            radius: 3
                            border {
                                width: 1
                                color: Kirigami.Theme.focusColor
                            }
                            color: "transparent"
                        }
                        QQC2.Label {
                            text: delegate.text
                            anchors {
                                fill: parent
                                margins: Kirigami.Units.smallSpacing
                            }
                            horizontalAlignment: Text.AlignLeft
                        }
                    }
                    onClicked: {
                        root.currentIndex = index
                        root.activated(index)
                        popupRoot.close()
                    }
                }
            }
        }
    }
}
