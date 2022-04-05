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
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.6 as Kirigami
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls.Styles 1.4

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

Rectangle {
    id: root

    readonly property QtObject song: zynthian.zynthiloops.song
    readonly property QtObject selectedTrack: song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)
    property QtObject sequence: root.selectedTrack && root.selectedTrack.connectedPattern >= 0 ? ZynQuick.PlayGridManager.getSequenceModel("Scene "+zynthian.zynthiloops.song.scenesModel.selectedSceneName) : null
    property QtObject pattern: root.sequence && root.selectedTrack ? root.sequence.get(root.selectedTrack.connectedPattern) : null


    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    function cuiaCallback(cuia) {
        var returnValue = false;
        switch (cuia) {
            case "SWITCH_TRACKS_MOD_SHORT":
                returnValue = true;
                break;

            case "NAVIGATE_LEFT":
                if (zynthian.session_dashboard.selectedTrack > 0) {
                    zynthian.session_dashboard.selectedTrack -= 1;
                }
                returnValue = true;
                break;

            case "NAVIGATE_RIGHT":
                if (zynthian.session_dashboard.selectedTrack < 9) {
                    zynthian.session_dashboard.selectedTrack += 1;
                }
                returnValue = true;
                break;

            case "SELECT_UP":
                if (root.selectedTrack.trackAudioType === "sample-trig") {
                    if (root.selectedTrack.selectedSampleRow > 0) {
                        root.selectedTrack.selectedSampleRow -= 1;
                    }
                    returnValue = true;
                }
                break;

            case "SELECT_DOWN":
                if (root.selectedTrack.trackAudioType === "sample-trig") {
                    if (root.selectedTrack.selectedSampleRow < 4) {
                        root.selectedTrack.selectedSampleRow += 1;
                    }
                    returnValue = true;
                }
                break;
        }
        return returnValue;
    }

    QtObject {
        id: privateProps

        //Try to fit exactly 12 mixers + a master mixer
        property int cellWidth: (tableLayout.width - loopGrid.columnSpacing)/13
    }

    GridLayout {
        rows: 1
        anchors.fill: parent

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
                                checked: root.selectedTrack.trackAudioType === "sample-trig" ||
                                         root.selectedTrack.trackAudioType === "sample-slice"
                                text: qsTr("Samples")
                                onClicked: root.selectedTrack.trackAudioType = "sample-trig"
                            }
                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                checkable: true
                                checked: root.selectedTrack.trackAudioType === "sample-loop"
                                text: qsTr("Loop")
                                onClicked: root.selectedTrack.trackAudioType = "sample-loop"
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            RowLayout {
                                visible: root.selectedTrack.trackAudioType === "synth"
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    centerIn: parent
                                    margins: Kirigami.Units.gridUnit
                                }

                                Repeater {
                                    model: root.selectedTrack.getSoundNames()

                                    delegate: Rectangle {
                                        Layout.fillWidth: false
                                        Layout.fillHeight: false
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2

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
                                            text: modelData

                                            elide: "ElideRight"
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                visible: root.selectedTrack.trackAudioType === "sample-trig" ||
                                         root.selectedTrack.trackAudioType === "sample-slice"
                                anchors {
                                    top: parent.top
                                    right: parent.right
                                    margins: Kirigami.Units.gridUnit
                                }

                                RowLayout {
                                    visible: root.selectedTrack.trackAudioType === "sample-trig"
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    QQC2.Label {
                                        text: "Auto Split:"
                                    }
                                    QQC2.Button {
                                        text: "Off"
                                        checked: root.selectedTrack && root.selectedTrack.keyZoneMode === "all-full"
                                        onClicked: {
                                            root.selectedTrack.keyZoneMode = "all-full";
                                        }
                                    }
                                    QQC2.Button {
                                        text: "Full"
                                        checked: root.selectedTrack && root.selectedTrack.keyZoneMode === "split-full"
                                        onClicked: {
                                            root.selectedTrack.keyZoneMode = "split-full";
                                        }
                                    }
                                    QQC2.Button {
                                        text: "Narrow"
                                        checked: root.selectedTrack && root.selectedTrack.keyZoneMode === "split-narrow"
                                        onClicked: {
                                            root.selectedTrack.keyZoneMode = "split-narrow";
                                        }
                                    }
                                    //QQC2.Button {
                                        //icon.name: "configure"
                                        //onClicked: {
                                            //trackKeyZoneSetup.open();
                                        //}
                                    //}
                                }
                                Item {
                                    Layout.fillWidth: false
                                    Layout.fillHeight: false
                                    Layout.preferredWidth: Kirigami.Units.gridUnit
                                }
                                RowLayout {
                                    spacing: 0
                                    QQC2.Button {
                                        text: "Trig"
                                        checked: root.selectedTrack && root.selectedTrack.trackAudioType === "sample-trig"
                                        onClicked: {
                                            root.selectedTrack.trackAudioType = "sample-trig"
                                        }
                                    }
                                    QQC2.Button {
                                        text: "Slice"
                                        checked: root.selectedTrack && root.selectedTrack.trackAudioType === "sample-slice"
                                        onClicked: {
                                            root.selectedTrack.trackAudioType = "sample-slice"
                                        }
                                    }
                                }
                            }

                            QQC2.Popup {
                                id: trackKeyZoneSetup
                                y: parent.mapFromGlobal(0, Math.round(parent.Window.height/2 - height/2)).y
                                x: parent.mapFromGlobal(Math.round(parent.Window.width/2 - width/2), 0).x
                                modal: true
                                focus: true
                                closePolicy: QQC2.Popup.CloseOnPressOutsideParent
                                TrackKeyZoneSetup {
                                    anchors.fill: parent
                                    implicitWidth: root.width - Kirigami.Units.largeSpacing * 2
                                    implicitHeight: root.height
                                    readonly property QtObject song: zynthian.zynthiloops.song
                                    selectedTrack: song ? song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack) : null
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Image {
                                id: patternVisualiser
                                anchors {
                                    fill: parent
                                }

                                smooth: false
                                visible: root.selectedTrack &&
                                         root.selectedTrack.connectedPattern >= 0 &&
                                         root.selectedTrack.trackAudioType === "synth"
                                source: root.pattern && root.selectedTrack ? "image://pattern/Scene "+zynthian.zynthiloops.song.scenesModel.selectedSceneName+"/" + root.selectedTrack.connectedPattern + "/0?" + root.pattern.lastModified : ""
                                Rectangle { // Progress
                                    anchors {
                                        top: parent.top
                                        bottom: parent.bottom
                                    }
                                    visible: root.sequence &&
                                             root.sequence.isPlaying &&
                                             root.pattern &&
                                             root.pattern.enabled
                                    color: Kirigami.Theme.highlightColor
                                    width: widthFactor // this way the progress rect is the same width as a step
                                    property double widthFactor: root.pattern ? parent.width / (root.pattern.width * root.pattern.bankLength) : 1
                                    x: root.pattern ? root.pattern.bankPlaybackPosition * widthFactor : 0
                                }
                                MouseArea {
                                    anchors.fill:parent
                                    onClicked: {
                                        var screenBack = zynthian.current_screen_id;
                                        zynthian.current_modal_screen_id = "playgrid";
                                        zynthian.forced_screen_back = "zynthiloops";
                                        ZynQuick.PlayGridManager.setCurrentPlaygrid("playgrid", ZynQuick.PlayGridManager.sequenceEditorIndex);
                                        var sequence = ZynQuick.PlayGridManager.getSequenceModel("Scene "+zynthian.zynthiloops.song.scenesModel.selectedSceneName);
                                        sequence.activePattern = root.selectedTrack.connectedPattern;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
