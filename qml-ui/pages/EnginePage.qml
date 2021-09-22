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

Zynthian.ScreenPage {
    id: root

    screenId: "engine"

    cuiaCallback: function(cuia) {
        switch (cuia) {
        case "SELECT_UP":
            if (view.currentIndex < 3) {
                tabbarScope.forceActiveFocus();
            } else {
                view.moveCurrentIndexUp();
            }
            return true;
        case "SELECT_DOWN":
            if (tabbarScope.activeFocus) {
                view.forceActiveFocus();
            } else {
                if (view.currentIndex === -1) {
                    view.currentIndex = 0;
                } else {
                    view.moveCurrentIndexDown();
                }
            }
            return true;
        case "NAVIGATE_LEFT":
            if (tabbarScope.activeFocus) {
                lv2Switch.checked = true;
                lv2Switch.toggled();
                view.currentIndex = -1;
            } else {
                view.moveCurrentIndexLeft();
            }
            return true;
        case "NAVIGATE_RIGHT":
            if (tabbarScope.activeFocus) {
                othersSwitch.checked = true;
                othersSwitch.toggled();
                view.currentIndex = -1;
            } else {
                view.moveCurrentIndexRight();
            }
            return true;
        default:
            return false;
        }
    }

    function stringToColor(string) {
        var hash = 0;
        if (string.length === 0) return hash;
        for (var i = 0; i < string.length; i++) {
            hash = string.charCodeAt(i) + ((hash << 5) - hash);
            hash = hash & hash;
        }
        var rgb = [0, 0, 0];
        for (var i = 0; i < 3; i++) {
            var value = (hash >> (i * 8)) & 255;
            rgb[i] = value;
        }
        return Qt.rgba(rgb[0]/255, rgb[1]/255, rgb[2]/255, 1);
    }

    ColumnLayout {
        anchors.fill: parent
        FocusScope {
            id: tabbarScope
            Layout.fillWidth: true
            implicitHeight: tabbarLayout.implicitHeight
            Zynthian.Card {
                anchors {
                    fill: parent
                    margins: -1
                }
                highlighted: true
                visible: tabbarScope.activeFocus
            }
            RowLayout {
                id: tabbarLayout
                anchors.fill: parent

                QQC2.Button {
                    id: lv2Switch
                    Layout.fillWidth: true
                    implicitWidth: 1
                    checkable: true
                    checked: true
                    autoExclusive: true
                    text: qsTr("LV2 Instruments")
                    onToggled: {
                        if (checked) {
                            zynthian.engine.shown_category = "Instrument";
                        }
                    }
                    onClicked: view.forceActiveFocus()
                    Component.onCompleted: {
                        zynthian.engine.shown_category = "Instrument";
                        zynthian.engine.current_index = -1;
                        view.contentY = 0;
                    }
                }
                QQC2.Button {
                    id: othersSwitch
                    Layout.fillWidth: true
                    implicitWidth: 1
                    checkable: true
                    autoExclusive: true
                    text: qsTr("Other Synths")
                    onToggled: {
                        if (checked) {
                            zynthian.engine.shown_category = "None";
                        }
                    }
                    onClicked: view.forceActiveFocus()
                }
            }
        }
        Zynthian.Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            highlighted: view.activeFocus
            contentItem: QQC2.ScrollView {
                GridView {
                    id: view
                    clip: true
                    cellWidth: width / 3
                    cellHeight: height / 4
                    currentIndex: zynthian.engine.current_index
                    onCurrentIndexChanged: zynthian.engine.current_index = currentIndex

                    model: zynthian.engine.selector_list
                    delegate: QQC2.AbstractButton {
                        width: view.cellWidth
                        height: view.cellHeight
                        leftPadding: Kirigami.Units.largeSpacing
                        topPadding: Kirigami.Units.largeSpacing
                        rightPadding: Kirigami.Units.largeSpacing
                        bottomPadding: Kirigami.Units.largeSpacing
                        onClicked: {
                            zynthian.engine.current_index = index;
                            zynthian.engine.activate_index(index);
                            delegate.itemActivated(delegate.screenId, index);
                        }
                        contentItem: Kirigami.Heading {
                            text: model.display
                            level: 2
                            horizontalAlignment: Text.AlignHCenter
                        }
                        background: Item {
                            Rectangle {
                                id: colorBackground
                                anchors {
                                    fill: parent
                                    margins: Kirigami.Units.smallSpacing
                                }
                                readonly property bool isCurrent: view.currentIndex == index
                                opacity: isCurrent ? 0.2 : 0.1
                                color: isCurrent ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor//root.stringToColor(model.display)
                                //Image {
                                    //anchors.fill: parent
                                    //source: "../../img/noisebackground.png"
                                //}
                            }
                            Rectangle {
                                anchors.fill: colorBackground
                                border.color: Qt.rgba(0, 0, 0, 0.6)
                                color: "transparent"
                                radius: 2
                                Rectangle {
                                    anchors {
                                        fill: parent
                                        margins: 1
                                    }
                                    radius: 2
                                    color: "transparent"
                                    border.color: colorBackground.color
                                    opacity: 0.4
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
