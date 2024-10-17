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
    contextualActions: [
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            readonly property QtObject selectedChannel: zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId)

            text: qsTr("Clear Slot")
            enabled: selectedChannel.checkIfLayerExists(zynqtgui.active_midi_channel)
            onTriggered: {
                selectedChannel.remove_and_unchain_sound(zynqtgui.active_midi_channel)
                zynqtgui.show_modal("sketchpad")
            }
        }
    ]

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
            zynqtgui.engine.shown_category = "Instrument";
            break;
        case "NAVIGATE_RIGHT":
            zynqtgui.engine.shown_category = "None";
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
    Component.onCompleted: {
        zynqtgui.engine.synth_engine_type = "MIDI Synth"
        zynqtgui.engine.shown_category = "Instrument";        
        zynqtgui.engine.plugin_format = "LV2"
        zynqtgui.engine.current_index = -1;
        view.contentY = 0;
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            id: tabbarLayout
            Layout.fillWidth: true
            Layout.fillHeight: true

            QQC2.Button {
                id: lv2Switch
                Layout.fillWidth: true
                implicitWidth: 1
                checked: zynqtgui.engine.pluginFormat == "LV2"
                autoExclusive: true
                text: qsTr("LV2 Instruments")
                onClicked: {
                    zynqtgui.engine.pluginFormat = "LV2"
                }
            }
            // QQC2.Button {
            //     id: vst3Switch
            //     Layout.fillWidth: true
            //     implicitWidth: 1
            //     checked: zynqtgui.engine.pluginFormat == "VST3"
            //     autoExclusive: true
            //     text: qsTr("VST3 Instruments")
            //     onClicked: {
            //         zynqtgui.engine.pluginFormat = "VST3"
            //     }
            // }
            QQC2.Button {
                id: othersSwitch
                Layout.fillWidth: true
                implicitWidth: 1
                checked: zynqtgui.engine.pluginFormat == ""
                autoExclusive: true
                text: qsTr("Other Synths")
                onClicked: {
                    zynqtgui.engine.pluginFormat = ""
                }
            }
        }
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

                    model: zynqtgui.engine.selector_list

                    delegate: QQC2.AbstractButton {
                        width: view.cellWidth - Kirigami.Units.gridUnit
                        height: view.cellHeight
                        enabled: model.action_id !== undefined
                        leftPadding: Kirigami.Units.largeSpacing
                        topPadding: Kirigami.Units.largeSpacing
                        rightPadding: Kirigami.Units.largeSpacing
                        bottomPadding: Kirigami.Units.largeSpacing
                        onClicked: {
                            zynqtgui.engine.current_index = index;
                            zynqtgui.engine.activate_index(index);
                            root.itemActivated(root.screenId, index);
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
                                    id: synthImage
                                    asynchronous: true
                                    visible: synthImage.status !== Image.Error
                                    anchors {
                                        fill: parent
                                        margins: Kirigami.Units.smallSpacing * 2
                                    }
                                    fillMode: Image.PreserveAspectCrop
                                    clip: true
                                    opacity: 0.5
                                    source: Qt.resolvedUrl("../../img/synths/" + model.display.toLowerCase().replace(/ /g, "-")  + ".png")
                                }

                                Image {
                                    asynchronous: true
                                    visible: synthImage.status === Image.Error
                                    anchors {
                                        fill: parent
                                        margins: Kirigami.Units.smallSpacing * 2
                                    }
                                    fillMode: Image.PreserveAspectCrop
                                    horizontalAlignment: Image.AlignHCenter
                                    verticalAlignment: Image.AlignVCenter
                                    clip: true
                                    opacity: 0.3
                                    source: Qt.resolvedUrl("../../img/synths/zynth-default.png")
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

                                    text: model.metadata.description ? model.metadata.description : ""
                                    elide: "ElideRight"
                                    font.pointSize: 8
                                    visible: view.currentIndex === index
                                    horizontalAlignment: "AlignHCenter"
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.leftMargin: Kirigami.Units.gridUnit
                                Layout.rightMargin: Kirigami.Units.gridUnit

                                Kirigami.Heading {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: Kirigami.Units.gridUnit
                                    text: model.display
                                    level: 2
                                    horizontalAlignment: "AlignHCenter"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
