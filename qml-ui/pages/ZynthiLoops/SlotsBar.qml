/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian slots bar page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Marco MArtin <mart@kde.org>

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
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls.Styles 1.4

//import Zynthian 1.0 as Zynthian

Rectangle {
    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_SELECT_SHORT":
                bottomBar.controlType = BottomBar.ControlType.Track;
                bottomBar.controlObj = zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack);

                bottomStack.currentIndex = 0;
                mixerActionBtn.checked = false;

                return true;

            case "NAVIGATE_LEFT":
                if (zynthian.session_dashboard.selectedTrack > 0) {
                    zynthian.session_dashboard.selectedTrack -= 1;
                }

                return true;

            case "NAVIGATE_RIGHT":
                if (zynthian.session_dashboard.selectedTrack < 9) {
                    zynthian.session_dashboard.selectedTrack += 1;
                }

                return true;
        }

        return false;
    }

    QtObject {
        id: privateProps

        //Try to fit exactly 12 mixers + a master mixer
        property int cellWidth: (tableLayout.width - loopGrid.columnSpacing)/13
    }

    GridLayout {
        id: root
        rows: 1
        anchors.fill: parent
        anchors.topMargin: Kirigami.Units.gridUnit*0.3

        readonly property QtObject song: zynthian.zynthiloops.song

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true

            Kirigami.Heading {
                visible: false
                text: qsTr("Slots : %1").arg(song.name)
            }

            ColumnLayout {
                id: tableLayout

                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 1

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 1

                    ColumnLayout {
                        Layout.preferredWidth: privateProps.cellWidth + 6
                        Layout.maximumWidth: privateProps.cellWidth + 6
                        Layout.bottomMargin: 5
                        Layout.fillHeight: true

                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: qsTr("Synths")
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: qsTr("Samples")
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: qsTr("FX")
                        }
                    }

                    Kirigami.Separator {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: "#ff31363b"
                    }

                    ListView {
                        id: tracksSlotsRow

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        clip: true
                        spacing: 0
                        orientation: Qt.Horizontal
                        boundsBehavior: Flickable.StopAtBounds

                        model: root.song.tracksModel

                        function handleClick(track) {
                            if (zynthian.session_dashboard.selectedTrack !== track.id) {
                                zynthian.session_dashboard.disableNextSoundSwitchTimer();
                                zynthian.session_dashboard.selectedTrack = track.id;
                                bottomBar.controlType = BottomBar.ControlType.Track;
                                bottomBar.controlObj = zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack);
                            } else {
                                bottomBar.controlType = BottomBar.ControlType.Track;
                                bottomBar.controlObj = zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack);

                                bottomStack.currentIndex = 0
                                mixerActionBtn.checked = false;
                            }
                        }

                        delegate: Rectangle {
                            property bool highlighted: index === zynthian.session_dashboard.selectedTrack
                            width: privateProps.cellWidth
                            height: ListView.view.height
                            color: highlighted ? "#22ffffff" : "transparent"
                            radius: 2
                            border.width: 1
                            border.color: highlighted ? Kirigami.Theme.highlightColor : "transparent"

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    tracksSlotsRow.handleClick(track);
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.topMargin: 4
                                spacing: 0

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: Kirigami.Units.gridUnit * 0.7

                                    Repeater {
                                        model: 5
                                        delegate: Item {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.leftMargin: 4
                                            Layout.rightMargin: 4

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: parent.width
                                                height: Kirigami.Units.gridUnit * 2

                                                Kirigami.Theme.inherit: false
                                                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                                color: Kirigami.Theme.backgroundColor

                                                border.color: "#ff999999"
                                                border.width: 1
                                                radius: 4
                                            }
                                        }
                                    }
                                }

                                Kirigami.Separator {
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 1
                                    color: "#ff31363b"
                                    visible: index !== root.song.tracksModel.count-1 && !highlighted
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        Layout.leftMargin: 2
                        Layout.preferredWidth: privateProps.cellWidth*2 - 10
                        Layout.bottomMargin: 5
                    }

                    Kirigami.Separator {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: "#ff31363b"
                    }
                }
            }
        }
    }
}
