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
    property QtObject soundCopySource

    title: qsTr("Sound Categories")
    screenId: "sound_categories"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Move/Paste")

            Kirigami.Action {
                enabled: root.soundCopySource == null && soundButtonGroup.checkedButton != null
                text: qsTr("Move")
                onTriggered: {
                    root.soundCopySource = soundButtonGroup.checkedButton.soundObj
                }
            }
            Kirigami.Action {
                enabled: root.soundCopySource != null &&
                         categoryButtonGroup.checkedButton &&
                         categoryButtonGroup.checkedButton.category !== "*" &&
                         categoryButtonGroup.checkedButton.category !== root.soundCopySource.category
                text: qsTr("Paste")
                onTriggered: {
                    root.soundCopySource.category = categoryButtonGroup.checkedButton.category
                    root.soundCopySource = null
                }
            }
            Kirigami.Action {
                enabled: root.soundCopySource != null
                text: qsTr("Cancel")
                onTriggered: {
                    root.soundCopySource = null
                }
            }
            Kirigami.Action {
                enabled: soundButtonGroup.checkedButton && soundButtonGroup.checkedButton.soundObj.category !== "0"
                text: qsTr("Clear Category")
                onTriggered: {
                    soundButtonGroup.checkedButton.soundObj.category = "0"
                }
            }
        },
        Kirigami.Action {
            enabled: root.soundCopySource == null
            text: qsTr("Save")
        },
        Kirigami.Action {
            enabled: root.soundCopySource == null
            text: qsTr("Load")
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
                    id: categoryButtonGroup
                    buttons: categoryButtons.children
                }

                ColumnLayout {
                    id: categoryButtons

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: spacing
                    spacing: content.rowSpacing

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "*"
                        checked: true
                    }

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "0"
                    }

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "1"
                    }

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "2"
                    }

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "3"
                    }

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "4"
                    }

                    CategoryButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        category: "99"
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

                    // Take into consideration the top and bottom margin of Kirigami.Units.gridUnit each
                    contentHeight: soundGrid.height + Kirigami.Units.gridUnit * 2

                    flickableDirection: Flickable.AutoFlickDirection
                    clip: true

                    Item {
                        width: middleColumn.width

                        QQC2.ButtonGroup {
                            id: soundButtonGroup
                            buttons: soundGrid.children
                        }

                        GridLayout {
                            id: soundGrid

                            property real cellWidth: (width - columnSpacing * (columns-1))/columns

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
                                id: soundButtonsRepeater
                                model: zynthian.sound_categories.soundsModel
                                delegate: QQC2.Button {
                                    property QtObject soundObj: model.sound

                                    Layout.fillWidth: false
                                    Layout.fillHeight: false
                                    Layout.preferredWidth: soundGrid.cellWidth
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                                    checkable: true

                                    QQC2.Label {
                                        anchors.fill: parent
                                        text: model.display
                                        wrapMode: "WrapAnywhere"
                                        horizontalAlignment: QQC2.Label.AlignHCenter
                                        verticalAlignment: QQC2.Label.AlignVCenter
                                    }
                                }
                            }

                            /** When soundsModel has 2 columns, alignment issue occurs because of
                              * less amount of items than columns. To mitigate, temporarily add a
                              * empty component of same width and height
                              */
                            Item {
                                Layout.fillWidth: false
                                Layout.fillHeight: false
                                Layout.preferredWidth: soundGrid.cellWidth
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                                visible: soundButtonsRepeater.count < 3
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
