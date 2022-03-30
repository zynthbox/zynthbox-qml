/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Snth Categories Page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>

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

import '../../Zynthian' 1.0 as Zynthian

Zynthian.ScreenPage {
    id: root

    property QtObject track: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)

    title: qsTr("Sound Categories")
    screenId: "sound_categories"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Move") // qsTr("Paste")
            enabled: false
        },
        Kirigami.Action {
            text: qsTr("Save")
            enabled: false
        },
        Kirigami.Action {
            text: qsTr("Load")
            enabled: false
        }
    ]

    cuiaCallback: function(cuia) {
        return false;
    }

    Connections {
        target: zynthian
        onCurrent_screen_idChanged: {
            // Refresh sounds model on page open
            if (zynthian.current_screen_id === root.screenId) {
                zynthian.sound_categories.load_sounds_model()
            }
        }
    }
    
    contentItem : GridLayout {
        id: content

        rows: 1
        columns: 5

        Rectangle {
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
            color: Kirigami.Theme.backgroundColor

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit*3
                    horizontalAlignment: "AlignHCenter"
                    verticalAlignment: "AlignVCenter"
                    font.pointSize: 16
                    text: qsTr("Categories")
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: 2
                }

                QQC2.ButtonGroup {
                    buttons: categoryButtons.children
                }

                ColumnLayout {
                    id: categoryButtons

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: spacing
                    spacing: content.rowSpacing

                    QQC2.Button {
                        id: categoryAllButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        checked: true
                        text: qsTr("All")
                        onClicked: {
                            zynthian.sound_categories.setCategoryFilter("*")
                        }
                    }

                    QQC2.Button {
                        id: categoryUncategorizedButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        text: qsTr("Uncategorized")
                        onClicked: {
                            zynthian.sound_categories.setCategoryFilter("0")
                        }
                    }

                    QQC2.Button {
                        id: categoryDrumsButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        text: qsTr("Drums")
                        onClicked: {
                            zynthian.sound_categories.setCategoryFilter("1")
                        }
                    }

                    QQC2.Button {
                        id: categoryBassButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        text: qsTr("Bass")
                        onClicked: {
                            zynthian.sound_categories.setCategoryFilter("2")
                        }
                    }

                    QQC2.Button {
                        id: categoryLeadsButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        text: qsTr("Leads")
                        onClicked: {
                            zynthian.sound_categories.setCategoryFilter("3")
                        }
                    }

                    QQC2.Button {
                        id: categoryKeysButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        text: qsTr("Keys/Pads")
                        onClicked: {
                            zynthian.sound_categories.setCategoryFilter("4")
                        }
                    }

                    QQC2.Button {
                        id: categoryOthersButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        checkable: true
                        text: qsTr("Others")
                        onClicked: {
                            zynthian.sound_categories.setCategoryFilter("99")
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.columnSpan: 3
            Layout.fillWidth: true
            Layout.fillHeight: true

            color: Kirigami.Theme.backgroundColor

            ColumnLayout {
                id: middleColumn
                anchors.fill: parent

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3

                    QQC2.ComboBox {
                        id: comboBox

                        width: Kirigami.Units.gridUnit * 10
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            margins: Kirigami.Units.gridUnit
                            centerIn: parent
                        }

                        model: ["community-sounds", "my-sounds"]
                        onActivated: {
                            zynthian.sound_categories.setSoundTypeFilter(model[index])
                        }

                        delegate: QQC2.ItemDelegate {
                            id: itemDelegate
                            width: parent.width
                            text: comboBox.textRole ? (Array.isArray(comboBox.model) ? modelData[comboBox.textRole] : model[comboBox.textRole]) : modelData
                            font.weight: comboBox.currentIndex === index ? Font.DemiBold : Font.Normal
                            highlighted: comboBox.highlightedIndex === index
                            hoverEnabled: comboBox.hoverEnabled

                            contentItem: QQC2.Label {
                                text: itemDelegate.text
                                font: itemDelegate.font
                                elide: QQC2.Label.ElideRight
                                verticalAlignment: QQC2.Label.AlignVCenter
                                horizontalAlignment: QQC2.Label.AlignHCenter
                            }
                        }
                    }

                    QQC2.Button {
                        anchors {
                            right: parent.right
                            rightMargin: Kirigami.Units.gridUnit
                            verticalCenter: parent.verticalCenter
                        }

                        width: Kirigami.Units.gridUnit * 2
                        height: comboBox.height
                        onClicked: zynthian.sound_categories.load_sounds_model()

                        Kirigami.Icon {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: Qt.resolvedUrl("../../../img/refresh.svg")
                            color: "#ffffffff"
                        }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: gridContent.width
                    contentHeight: gridContent.height
                    flickableDirection: Flickable.AutoFlickDirection
                    clip: true

                    Item {
                        id: gridContent
                        width: middleColumn.width

                        GridLayout {
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: Kirigami.Units.gridUnit
                            }

                            columns: 3
                            rowSpacing: Kirigami.Units.gridUnit
                            columnSpacing: Kirigami.Units.gridUnit

                            Repeater {
                                model: zynthian.sound_categories.soundsModel
                                delegate: QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: false
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                                    Layout.alignment: Qt.AlignTop

                                    QQC2.Label {
                                        anchors.fill: parent
                                        text: model.display
                                        wrapMode: "WrapAnywhere"
                                        horizontalAlignment: QQC2.Label.AlignHCenter
                                        verticalAlignment: QQC2.Label.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            color: Kirigami.Theme.backgroundColor

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit*3
                    horizontalAlignment: "AlignHCenter"
                    verticalAlignment: "AlignVCenter"
                    font.pointSize: 16
                    text: qsTr("Current")
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: 2
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: content.rowSpacing
                    flickableDirection: Flickable.VerticalFlick
                    orientation: ListView.Vertical
                    clip: true
                    model: root.track.chainedSounds

                    delegate: Item {
                        width: ListView.view.width
                        height: (ListView.view.height - ListView.view.spacing * 4) / 5

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - Kirigami.Units.gridUnit * 2
                            height: Kirigami.Units.gridUnit * 2

                            Kirigami.Theme.inherit: false
                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                            color: Kirigami.Theme.backgroundColor

                            border.color: "#ff999999"
                            border.width: 1
                            radius: 4

                            QQC2.Label {
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    right: parent.right
                                    leftMargin: Kirigami.Units.gridUnit*0.5
                                    rightMargin: Kirigami.Units.gridUnit*0.5
                                }
                                horizontalAlignment: Text.AlignLeft
                                text: modelData >= 0 && root.track.checkIfLayerExists(modelData)
                                        ? root.track.getLayerNameByMidiChannel(modelData)
                                        : ""

                                elide: "ElideRight"
                            }
                        }
                    }
                }
            }
        }
    }
}
