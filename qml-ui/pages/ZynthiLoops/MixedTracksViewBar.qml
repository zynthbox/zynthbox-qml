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
import org.kde.kirigami 2.6 as Kirigami
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls.Styles 1.4

import Zynthian 1.0 as Zynthian

Rectangle {
    id: root

    readonly property QtObject song: zynthian.zynthiloops.song
    readonly property QtObject selectedTrack: song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)

    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    function cuiaCallback(cuia) {
        switch (cuia) {
            // Set respective selected row when button 1-5 is pressed or 6(mod)+1-5 is pressed
            // and invoke respective handler when trackAudioType is synth, trig or slice
            // Otherwise, when in loop mode, do not handle button to allow falling back to track
            // selection
            case "TRACK_1":
            case "TRACK_6":
                if (root.selectedTrack.trackAudioType === "synth" ||
                    root.selectedTrack.trackAudioType === "sample-trig" ||
                    root.selectedTrack.trackAudioType === "sample-slice") {
                    bottomStack.slotsBar.selectedSlotRowItem.selectedRow = 0
                    bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                    return true
                }

                return false

            case "TRACK_2":
            case "TRACK_7":
                if (root.selectedTrack.trackAudioType === "synth" ||
                    root.selectedTrack.trackAudioType === "sample-trig" ||
                    root.selectedTrack.trackAudioType === "sample-slice") {
                    bottomStack.slotsBar.selectedSlotRowItem.selectedRow = 1
                    bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                    return true
                }

                return false

            case "TRACK_3":
            case "TRACK_8":
                if (root.selectedTrack.trackAudioType === "synth" ||
                    root.selectedTrack.trackAudioType === "sample-trig" ||
                    root.selectedTrack.trackAudioType === "sample-slice") {
                    bottomStack.slotsBar.selectedSlotRowItem.selectedRow = 2
                    bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                    return true
                }

                return false

            case "TRACK_4":
            case "TRACK_9":
                if (root.selectedTrack.trackAudioType === "synth" ||
                    root.selectedTrack.trackAudioType === "sample-trig" ||
                    root.selectedTrack.trackAudioType === "sample-slice") {
                    bottomStack.slotsBar.selectedSlotRowItem.selectedRow = 3
                    bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                    return true
                }

                return false

            case "TRACK_5":
            case "TRACK_10":
                if (root.selectedTrack.trackAudioType === "synth" ||
                    root.selectedTrack.trackAudioType === "sample-trig" ||
                    root.selectedTrack.trackAudioType === "sample-slice") {
                    bottomStack.slotsBar.selectedSlotRowItem.selectedRow = 4
                    bottomStack.slotsBar.handleItemClick(root.selectedTrack.trackAudioType)
                    return true
                }

                return false
        }

        return false;
    }

    QtObject {
        id: privateProps

        //Try to fit exactly 12 mixers + a master mixer
        property int cellWidth: (tableLayout.width - loopGrid.columnSpacing)/13
    }

    GridLayout {
        rows: 1
        anchors.fill: parent
        anchors.topMargin: Kirigami.Units.gridUnit*0.3

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true

            QQC2.ButtonGroup {
                buttons: tabButtons.children
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 1

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 1

                    QQC2.ButtonGroup {
                        buttons: buttonsColumn.children
                    }

                    BottomStackTabs {
                        id: buttonsColumn
                        Layout.preferredWidth: privateProps.cellWidth + 6
                        Layout.maximumWidth: privateProps.cellWidth + 6
                        Layout.bottomMargin: 5
                        Layout.fillHeight: true
                    }

                    Kirigami.Separator {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: "#ff31363b"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        RowLayout {
                            id: tabButtons
                            Layout.fillWidth: true
                            Layout.fillHeight: false

                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                checkable: true
                                checked: root.selectedTrack.trackAudioType === "synth"
                                text: qsTr("Synth")
                                onClicked: root.selectedTrack.trackAudioType = "synth"
                            }
                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                checkable: true
                                checked: root.selectedTrack.trackAudioType === "sample-loop"
                                text: qsTr("Loop")
                                onClicked: root.selectedTrack.trackAudioType = "sample-loop"
                            }
                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                checkable: true
                                checked: root.selectedTrack.trackAudioType === "sample-trig"
                                text: qsTr("Trig")
                                onClicked: root.selectedTrack.trackAudioType = "sample-trig"
                            }
                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                checkable: true
                                checked: root.selectedTrack.trackAudioType === "sample-slice"
                                text: qsTr("Slice")
                                onClicked: root.selectedTrack.trackAudioType = "sample-slice"
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }
    }
}
