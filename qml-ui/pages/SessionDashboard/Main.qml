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

    readonly property QtObject song: zynthian.sketchpad.song
    property QtObject selectedChannel: zynthian.sketchpad.song.channelsModel.getChannel(zynthian.session_dashboard.selectedChannel)

    backAction: null
    contextualActions: [
        Kirigami.Action {
            text: qsTr("Sketchpad")

            Kirigami.Action {
                // Rename Save button as Save as for temp sketchpad
                text: root.song.isTemp ? qsTr("Save As") : qsTr("Save")
                onTriggered: {
                    if (root.song.isTemp) {
                        fileNameDialog.dialogType = "save";
                        fileNameDialog.fileName = "Sketchpad-1";
                        fileNameDialog.open();
                    } else {
                        zynthian.sketchpad.saveSketchpad();
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
                    fileNameDialog.fileName = song.sketchpadFolderName;
                    fileNameDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Load Sketchpad")
                onTriggered: {
                    sketchpadPickerDialog.folderModel.folder = sketchpadPickerDialog.rootFolder;
                    sketchpadPickerDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("New Sketchpad")
                onTriggered: {
                    zynthian.sketchpad.newSketchpad()
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
                onTriggered: zynthian.admin.restart_gui()
            }
            Kirigami.Action {
                text: qsTr("Reboot")
                onTriggered: zynthian.admin.reboot()
            }
            Kirigami.Action {
                text: qsTr("Power Off")
                onTriggered: zynthian.admin.power_off()
            }
        }
    ]
    screenId: "session_dashboard"

    cuiaCallback: function(cuia) {
        var result = false;
        if (sketchpadPickerDialog.opened) {
            result = sketchpadPickerDialog.cuiaCallback(cuia);
        }
        if (!result) {
            result = tabbedView.cuiaCallback(cuia);
        }
        return result;
    }

    Zynthian.SaveFileDialog {
        property string dialogType: "save"

        id: fileNameDialog
        visible: false

        headerText: {
            if (fileNameDialog.dialogType == "savecopy")
                return qsTr("Clone Sketchpad")
            else if (fileNameDialog.dialogType === "saveas")
                return qsTr("New version")
            else
                return qsTr("New Sketchpad")
        }
        conflictText: {
            if (dialogType == "savecopy")
                return qsTr("Sketchpad Exists")
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
                    && zynthian.sketchpad.sketchpadExists(fileNameDialog.fileName)) {
                    // Sketchpad with name already exists
                    fileNameDialog.conflict = true;
                } else if (fileNameDialog.dialogType === "saveas"
                           && fileNameDialog.fileName.length > 0
                           && zynthian.sketchpad.versionExists(fileNameDialog.fileName)) {
                    fileNameDialog.conflict = true;
                } else {
                    fileNameDialog.conflict = false;
                }
            }
        }

        onAccepted: {
            console.log("Accepted")

            if (dialogType === "save") {
                zynthian.sketchpad.createSketchpad(fileNameDialog.fileName)
            } else if (dialogType === "saveas") {
                root.song.name = fileNameDialog.fileName;
                zynthian.sketchpad.saveSketchpad();
            } else if (dialogType === "savecopy") {
                zynthian.sketchpad.saveCopy(fileNameDialog.fileName);
            }
        }
        onRejected: {
            console.log("Rejected")
        }
    }

    Zynthian.FilePickerDialog {
        id: sketchpadPickerDialog
        parent: root

        headerText: qsTr("Pick a sketchpad")
        rootFolder: "/zynthian/zynthian-my-data/sketchpads"
        folderModel {
            nameFilters: ["*.sketchpad.json"]
        }
        onFileSelected: {
            console.log("Selected Sketchpad : " + file.fileName + "("+ file.filePath +")")
            zynthian.sketchpad.loadSketchpad(file.filePath)
        }
    }

    Timer {
        interval: 10 * 1000
        // As per #299, disabling clock
        running: false
        repeat: true
        triggeredOnStart: true
        function pad(d) {
            return (d < 10) ? '0' + d.toString() : d.toString();
        }
        onTriggered: {
            let d = new Date();
            clockLabel.text = d.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit' });

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
            // Select connected sound of selected channel if not already selected
            if (zynthian.current_screen_id === "session_dashboard" &&
                !selectedChannel.checkIfLayerExists(zynthian.active_midi_channel) &&
                zynthian.active_midi_channel !== selectedChannel.connectedSound) {
                zynthian.fixed_layers.activate_index(selectedChannel.connectedSound);
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
                id: sketchpadHeader
                Layout.alignment: Qt.AlignCenter
                text: zynthian.sketchpad.song.name
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit*2

                RowLayout {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                    }
                    x: Math.round(parent.mapFromItem(root, root.width/2-width/2, 0).x)
                    QQC2.Button {
                        text: "1-6"
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        checked: zynthian.session_dashboard.visibleChannelsStart == 0
                        onClicked: {
                            zynthian.session_dashboard.visibleChannelsStart = 0;
                            zynthian.session_dashboard.visibleChannelsEnd = 5;
                        }
                    }
                    QQC2.Button {
                        text: "7-12"
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        checked: zynthian.session_dashboard.visibleChannelsStart == 6
                        onClicked: {
                            zynthian.session_dashboard.visibleChannelsStart = 6;
                            zynthian.session_dashboard.visibleChannelsEnd = 11;
                        }
                    }
                }
            }
            Item {
                Layout.fillWidth: true



                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    QQC2.Button {
                        Layout.preferredWidth: Kirigami.Units.gridUnit*2
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignCenter
                        checkable: true
                        checked: zynthian.sketchpad.clickChannelEnabled
                        onToggled: {
                            zynthian.sketchpad.clickChannelEnabled = checked
                        }
                        
                        Kirigami.Icon {
                            width: Kirigami.Units.gridUnit
                            height: width
                            anchors.centerIn: parent
                            source: Qt.resolvedUrl("../../../img/metronome.svg")
                            color: "#ffffff"
                        }
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignCenter
                        font.pointSize: 12
                        text: qsTr("%1 x Sounds | %2 x Midi")
                        .arg(15 - zynthian.sketchpad.song.channelsModel.connectedSoundsCount)
                        .arg(5 - zynthian.sketchpad.song.channelsModel.connectedPatternsCount)
                    }

                    Kirigami.Heading {
                        id: clockLabel
                        Layout.alignment: Qt.AlignCenter
                    }
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
                    id: channelsViewTab
                    text: qsTr("Channels")
                    page: Qt.resolvedUrl("ChannelsView.qml")
                },
                Zynthian.TabbedControlViewAction {
                    // Sketchpads tab renamed to sessions
                    text: qsTr("Sessions")
                    page: Qt.resolvedUrl("SketchpadsView.qml")
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

