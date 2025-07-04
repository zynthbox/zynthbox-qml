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

    property string pluginFormat: "LV2"
    property bool isCategorySelected: false

    screenId: "layer_effects"
    contextualActions: [
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        }
    ]
    backAction: Kirigami.Action {
        text: "Back"
        onTriggered: {
            if (root.isCategorySelected) {
                root.isCategorySelected = false
            } else {
                zynqtgui.go_back()
            }
        }
    }

    cuiaCallback: function(cuia) {
        let result = false;
        switch (cuia) {
        case "SELECT_UP":
            view.moveCurrentIndexUp();
            result = true;
            break;
        case "SELECT_DOWN":
            if (view.currentIndex === -1) {
                view.currentIndex = 0;
            } else {
                view.moveCurrentIndexDown();
            }
            result = true;
            break;
        case "NAVIGATE_LEFT":
            // root.pluginFormat = "LV2";
            view.moveCurrentIndexLeft();
            break;
        case "NAVIGATE_RIGHT":
            // root.pluginFormat = "VST3";
            view.moveCurrentIndexRight();
            break;
        case "KNOB3_TOUCHED":
        case "KNOB3_RELEASED":
            result = true;
            break;
        case "KNOB3_DOWN":
            view.moveCurrentIndexLeft();
            result = true;
            break;
        case "KNOB3_UP":
            view.moveCurrentIndexRight();
            result = true;
            break;
        case "SWITCH_BACK_SHORT":
        case "SWITCH_BACK_BOLD":
            if (root.isCategorySelected) {
                root.isCategorySelected = false
            } else {
                zynqtgui.go_back()
            }
            result = true;
            break;
        case "SWITCH_SELECT_SHORT":
        case "SWITCH_SELECT_BOLD":
            if (root.isCategorySelected) {
                zynqtgui.layer_effect_chooser.activate_index(zynqtgui.layer_effect_chooser.current_index);
            } else {
                zynqtgui.effect_types.activate_index(zynqtgui.effect_types.current_index);
                root.isCategorySelected = true;
            }
            result = true;
            break;
        default:
            break;
        }
        return result;
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
    onPluginFormatChanged: {
        // When plugin format changes, reset everything
        zynqtgui.effect_types.pluginFormat = root.pluginFormat;
        zynqtgui.layer_effect_chooser.pluginFormat = root.pluginFormat;
        root.isCategorySelected = false;
        zynqtgui.effect_types.current_index = -1;
        zynqtgui.layer_effect_chooser.current_index = -1;
        view.contentY = 0;
    }
    onVisibleChanged: {
        if (!visible) {
            // Reset values when page closes
            root.pluginFormat = "LV2";
            root.isCategorySelected = false;
            zynqtgui.effect_types.pluginFormat = root.pluginFormat;
            zynqtgui.layer_effect_chooser.pluginFormat = root.pluginFormat;
            zynqtgui.effect_types.current_index = -1;
            zynqtgui.layer_effect_chooser.current_index = -1;
            view.contentY = 0;
        }
    }

    ColumnLayout {
        anchors.fill: parent

        // RowLayout {
        //     id: tabbarLayout
        //     Layout.fillWidth: true
        //     Layout.fillHeight: true

        //     QQC2.Button {
        //         Layout.fillWidth: true
        //         implicitWidth: 1
        //         checked: root.pluginFormat == "LV2"
        //         autoExclusive: true
        //         text: qsTr("LV2 Plugins")
        //         onClicked: {
        //             root.pluginFormat = "LV2"
        //         }
        //     }
        //     // QQC2.Button {
        //     //     Layout.fillWidth: true
        //     //     implicitWidth: 1
        //     //     checked: root.pluginFormat == "VST3"
        //     //     autoExclusive: true
        //     //     text: qsTr("VST3 Plugins")
        //     //     onClicked: {
        //     //         root.pluginFormat = "VST3"
        //     //     }
        //     // }
        // }
        Zynthian.Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentItem: QQC2.ScrollView {
                id: scrollView

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    id: scrollBar
                    parent: scrollView.parent
                    policy: QQC2.ScrollBar.AlwaysOn
                    x: scrollView.mirrored ? 0 : scrollView.width - width
                    y: scrollView.topPadding
                    height: scrollView.availableHeight
                    active: scrollView.ScrollBar ? (scrollView.ScrollBar.horizontal.active) : false
                    contentItem: Rectangle {
                        implicitWidth: Kirigami.Units.gridUnit
                        implicitHeight: 150
                        radius: width/2
                        color: Kirigami.Theme.textColor
                        opacity: 0.5
                    }
                }

                GridView {
                    id: view
                    clip: true
                    cellWidth: width / 3
                    cellHeight: height / 2.2
                    currentIndex: zynqtgui.engine.current_index
                    onCurrentIndexChanged: {
                        if (zynqtgui.engine.current_index != currentIndex) {
                            zynqtgui.engine.current_index = currentIndex;
                        }
                    }

                    model: root.isCategorySelected
                            ? zynqtgui.layer_effect_chooser.selector_list
                            : zynqtgui.effect_types.selector_list

                    delegate: QQC2.AbstractButton {
                        width: view.cellWidth - Kirigami.Units.gridUnit
                        height: view.cellHeight
                        enabled: model.action_id !== undefined
                        leftPadding: Kirigami.Units.largeSpacing
                        topPadding: Kirigami.Units.largeSpacing
                        rightPadding: Kirigami.Units.largeSpacing
                        bottomPadding: Kirigami.Units.largeSpacing
                        onClicked: {
                            if (root.isCategorySelected) {
                                zynqtgui.layer_effect_chooser.current_index = index;
                                zynqtgui.layer_effect_chooser.activate_index(index);
                            } else {
                                zynqtgui.effect_types.current_index = index;
                                zynqtgui.effect_types.activate_index(index);
                                root.isCategorySelected = true;
                            }
                        }

                        contentItem: ColumnLayout {
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                color: "transparent"
                                radius: 12
                                border.width: view.currentIndex === index ? 4 : 0
                                border.color: "#ffffff"



                                Image {
                                    asynchronous: true
                                    anchors {
                                        fill: parent
                                        margins: Kirigami.Units.smallSpacing * 2
                                    }
                                    fillMode: Image.PreserveAspectCrop
                                    clip: true
                                    opacity: 0.5
                                    source: model.metadata.image
                                }
                                Rectangle {
                                    id: colorBackground
                                    anchors {
                                        fill: parent
                                        margins: Kirigami.Units.smallSpacing
                                    }
                                    readonly property bool isCurrent: view.currentIndex === index
                                    radius: parent.radius
                                    opacity: isCurrent ? 0.3 : 0
                                    color: isCurrent ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                }
                                Rectangle {
                                    anchors.fill: colorBackground
                                    border.color: Qt.rgba(0, 0, 0, 0.6)
                                    color: "transparent"
                                    radius: parent.radius
                                    Rectangle {
                                        anchors {
                                            fill: parent
                                            margins: 1
                                        }
                                        radius: parent.radius
                                        color: "transparent"
                                        border.color: colorBackground.color
                                        opacity: 0.4
                                    }
                                }

                                Kirigami.Heading {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        bottom: parent.bottom
                                        bottomMargin: Kirigami.Units.gridUnit
                                    }

                                    text: model.metadata && model.metadata.description ? model.metadata.description : ""
                                    elide: Text.ElideRight
                                    font.pointSize: 8
                                    visible: view.currentIndex === index
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.leftMargin: Kirigami.Units.gridUnit
                                Layout.rightMargin: Kirigami.Units.gridUnit

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: Kirigami.Units.gridUnit
                                    text: model.display
                                    font.pointSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                QQC2.Label {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: Kirigami.Units.gridUnit
                                    maximumLineCount: 2
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    text: model.metadata && model.metadata.description ? model.metadata.description : ""
                                    font.pointSize: 10
                                    opacity: 0.7
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
