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
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import org.zynthian.quick 1.0 as ZynQuick
import Zynthian 1.0 as Zynthian

Zynthian.ScreenPage {
    id: root

    readonly property QtObject song: zynthian.zynthiloops.song
    property QtObject selectedTrack: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)

    backAction: null
    contextualActions: [
        Kirigami.Action {
            text: qsTr("Sketch")

            Kirigami.Action {
                // Rename Save button as Save as for temp sketch
                text: root.song.isTemp ? qsTr("Save As") : qsTr("Save")
                onTriggered: {
                    if (root.song.isTemp) {
                        fileNameDialog.dialogType = "save";
                        fileNameDialog.fileName = "Sketch-1";
                        fileNameDialog.open();
                    } else {
                        zynthian.zynthiloops.saveSketch();
                    }
                }
            }
            Kirigami.Action {
                text: qsTr("Save As")
                visible: !root.song.isTemp
                onTriggered: {
                    fileNameDialog.dialogType = "saveas";
                    fileNameDialog.fileName = song.name;
                    fileNameDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Clone As")
                visible: !root.song.isTemp
                onTriggered: {
                    fileNameDialog.dialogType = "savecopy";
                    fileNameDialog.fileName = song.sketchFolderName;
                    fileNameDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Load Sketch")
                onTriggered: {
                    sketchPickerDialog.folderModel.folder = sketchPickerDialog.rootFolder;
                    sketchPickerDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("New Sketch")
                onTriggered: {
                    zynthian.zynthiloops.newSketch()
                }
            }
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            enabled: false
        },
        Kirigami.Action {
            text: qsTr("Power")
            Kirigami.Action {
                text: qsTr("Restart UI")
                onTriggered: zynthian.main.restart_gui()
            }
            Kirigami.Action {
                text: qsTr("Reboot")
                onTriggered: zynthian.main.reboot()
            }
            Kirigami.Action {
                text: qsTr("Power Off")
                onTriggered: zynthian.main.power_off()
            }
        }
    ]
    screenId: "session_dashboard"

    cuiaCallback: function(cuia) {
        return tabbedView.cuiaCallback(cuia);
    }

    Zynthian.SaveFileDialog {
        property string dialogType: "save"

        id: fileNameDialog
        visible: false

        headerText: {
            if (fileNameDialog.dialogType == "savecopy")
                return qsTr("Clone Sketch")
            else if (fileNameDialog.dialogType === "saveas")
                return qsTr("New version")
            else
                return qsTr("New Sketch")
        }
        conflictText: {
            if (dialogType == "savecopy")
                return qsTr("Sketch Exists")
            else if (dialogType == "saveas")
                return qsTr("Version Exists")
            else
                return qsTr("Exists")
        }
        overwriteOnConflict: false

        onFileNameChanged: {
            console.log("File Name : " + fileName)
            fileCheckTimer.restart()
        }
        Timer {
            id: fileCheckTimer
            interval: 300
            onTriggered: {
                if (fileNameDialog.dialogType == "savecopy"
                    && fileNameDialog.fileName.length > 0
                    && zynthian.zynthiloops.sketchExists(fileNameDialog.fileName)) {
                    // Sketch with name already exists
                    fileNameDialog.conflict = true;
                } else if (fileNameDialog.dialogType === "saveas"
                           && fileNameDialog.fileName.length > 0
                           && zynthian.zynthiloops.versionExists(fileNameDialog.fileName)) {
                    fileNameDialog.conflict = true;
                } else {
                    fileNameDialog.conflict = false;
                }
            }
        }

        onAccepted: {
            console.log("Accepted")

            if (dialogType === "save") {
                zynthian.zynthiloops.createSketch(fileNameDialog.fileName)
            } else if (dialogType === "saveas") {
                root.song.name = fileNameDialog.fileName;
                zynthian.zynthiloops.saveSketch();
            } else if (dialogType === "savecopy") {
                zynthian.zynthiloops.saveCopy(fileNameDialog.fileName);
            }
        }
        onRejected: {
            console.log("Rejected")
        }
    }

    Zynthian.FilePickerDialog {
        id: sketchPickerDialog
        parent: root

        headerText: qsTr("Pick a sketch")
        rootFolder: "/zynthian/zynthian-my-data/sketches"
        folderModel {
            nameFilters: ["*.json"]
        }
        onFileSelected: {
            console.log("Selected Sketch : " + file.fileName + "("+ file.filePath +")")
            zynthian.zynthiloops.loadSketch(file.filePath)
        }
    }

    Timer {
        interval: 10 * 1000
        // Remove clock as per #299
        running: false
        repeat: true
        triggeredOnStart: true
        function pad(d) {
            return (d < 10) ? '0' + d.toString() : d.toString();
        }
        onTriggered: {
            /* Remove clock as per #299
            let d = new Date();
            clockLabel.text = d.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit' });
            */

            /* Remove session time as per #272
               TODO : Remove below snippet
            let sessionSecs = zynthian.session_dashboard.get_session_time()
            let sessionMins = Math.floor(sessionSecs / 60);
            let sessionHours = Math.floor(sessionMins / 60);
            sessionMins = sessionMins % 60;
            sessionTimeLabel.text = pad(sessionHours) + ":" + pad(sessionMins);
            */
        }
    }

    Connections {
        target: zynthian
        onCurrent_screen_idChanged: {
            // Select connected sound of selected track if not already selected
            if (zynthian.current_screen_id === "session_dashboard" &&
                !selectedTrack.checkIfLayerExists(zynthian.active_midi_channel) &&
                zynthian.active_midi_channel !== selectedTrack.connectedSound) {
                zynthian.fixed_layers.activate_index(selectedTrack.connectedSound);
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        RowLayout {
            /* Remove session time as per #272
               TODO : Remove below snippet
            QQC2.Label {
                Layout.alignment: Qt.AlignCenter
                text: "Session time:"
            }
            Kirigami.Heading {
                id: sessionTimeLabel
                Layout.alignment: Qt.AlignCenter
            }
            */
            Kirigami.Heading {
                id: sketchHeader
                Layout.alignment: Qt.AlignCenter
                text: zynthian.zynthiloops.song.name
            }
            Item {
                Layout.fillWidth: true
            }
            RowLayout {
                Layout.alignment: Qt.AlignCenter

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter

                    QQC2.Button {
                        Layout.preferredWidth: Kirigami.Units.gridUnit*4
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        enabled: !zynthian.zynthiloops.isMetronomeRunning
                        onClicked: {
                            Zynthian.CommonUtils.startMetronomeAndPlayback();
                        }

                        Kirigami.Icon {
                            width: Kirigami.Units.gridUnit
                            height: width
                            anchors.centerIn: parent
                            source: "media-playback-start"
                            color: parent.enabled ? "white" : "#99999999"
                        }
                    }
                    QQC2.Button {
                        Layout.preferredWidth: Kirigami.Units.gridUnit*4
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        enabled: zynthian.zynthiloops.isMetronomeRunning
                        onClicked: {
                            Zynthian.CommonUtils.stopMetronomeAndPlayback();
                        }

                        Kirigami.Icon {
                            width: Kirigami.Units.gridUnit
                            height: width
                            anchors.centerIn: parent
                            source: "media-playback-stop"
                            color: parent.enabled ? "white" : "#99999999"
                        }
                    }
                }

                QQC2.Label {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: Kirigami.Units.gridUnit

                    font.pointSize: 12
                    text: qsTr("%1 x Sounds | %2 x Midi")
                            .arg(15 - zynthian.zynthiloops.song.tracksModel.connectedSoundsCount)
                            .arg(5 - zynthian.zynthiloops.song.tracksModel.connectedPatternsCount)
                }

                Kirigami.Heading {
                    id: clockLabel
                    Layout.alignment: Qt.AlignCenter
                }
            }
        }

        Zynthian.TabbedControlView {
            id: tabbedView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visibleFocusRects: false
            minimumTabsCount: 5

            property QQC2.StackView stack

            tabActions: [
                Zynthian.TabbedControlViewAction {
                    id: tracksViewTab
                    text: qsTr("Tracks")
                    page: Qt.resolvedUrl("TracksView.qml")
                },
                Zynthian.TabbedControlViewAction {
                    // Sketches tab renamed to sessions
                    text: qsTr("Sessions")
                    page: Qt.resolvedUrl("SketchesView.qml")
                },
                Zynthian.TabbedControlViewAction {
                    // Sessions tab renamed to Wiring
                    text: qsTr("Wiring")
                    page: Qt.resolvedUrl("SessionView.qml")
                },
                Zynthian.TabbedControlViewAction {
                    text: qsTr("Templates")
                    page: Qt.resolvedUrl("TemplatesView.qml")
                },
                Zynthian.TabbedControlViewAction {
                    text: qsTr("Discover")
                    page: Qt.resolvedUrl("DiscoverView.qml")
                }
            ]
        }
    }
}

