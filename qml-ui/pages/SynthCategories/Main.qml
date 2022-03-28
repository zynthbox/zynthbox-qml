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

    title: qsTr("Synth Categories")
    screenId: "synth_categories"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Copy")
            enabled: false
        },
        Kirigami.Action {
            text: qsTr("Paste")
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
    
    contentItem : GridLayout {
        id: content

        property real cellWidth: (width - columnSpacing * (columns-1))/columns

        rows: 1
        columns: 5

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Kirigami.Theme.backgroundColor

            ColumnLayout {
                anchors.fill: parent

                Zynthian.TableHeader {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit*3
                    text: qsTr("Categories")
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredWidth: 1
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: content.rowSpacing
                    flickableDirection: Flickable.VerticalFlick
                    orientation: ListView.Vertical
                    clip: true
                    model: 10

                    delegate: Zynthian.TableHeader {
                        width: ListView.view.width
                        height: Kirigami.Units.gridUnit * 2
                        text: "Tag"
                    }
                }
            }
        }

        Rectangle {
            Layout.columnSpan: 3
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: content.cellWidth * 3

            color: Kirigami.Theme.backgroundColor
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Kirigami.Theme.backgroundColor

            ColumnLayout {
                anchors.fill: parent

                Zynthian.TableHeader {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit*3
                    text: qsTr("Details")
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredWidth: 1
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: content.rowSpacing
                    flickableDirection: Flickable.VerticalFlick
                    orientation: ListView.Vertical
                    clip: true
                    model: 5

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
                                text: ""

                                elide: "ElideRight"
                            }
                        }
                    }
                }
            }
        }
    }
}
