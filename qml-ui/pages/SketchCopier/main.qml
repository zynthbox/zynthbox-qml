/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Sketch CopierPage

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
import QtQml.Models 2.10
import org.kde.kirigami 2.4 as Kirigami

import '../../Zynthian' 1.0 as Zynthian

Zynthian.ScreenPage {
    readonly property QtObject copier: zynthian.sketch_copier
    readonly property QtObject session: zynthian.session_dashboard
    readonly property QtObject curSketch: zynthian.zynthiloops.song

    id: root

    title: qsTr("Sketch Copier")
    screenId: "sketch_copier"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8

    contextualActions: [
        Kirigami.Action {
            text: "Sketch"

            Kirigami.Action {
                text: "Add New Sketch"
                iconName: "document-new-symbolic"
                onTriggered: {
                }
            }
            Kirigami.Action {
                text: "Add Existing Sketch"
                iconName: "folder-new-symbolic"
                onTriggered: {
                    sketchPickerDialog.folderModel.folder = sketchPickerDialog.rootFolder;
                    sketchPickerDialog.open();
                }
            }
            Kirigami.Action {
                text: "Remove Sketch"
                iconName: "edit-delete-symbolic"
                onTriggered: {
                }
            }
        },
        Kirigami.Action {
            text: "Channel"

            Kirigami.Action {
                text: "Copy Channel"
                iconName: "edit-copy-symbolic"
                enabled: !copier.isCopyInProgress
                visible: !copier.isCopyInProgress
                onTriggered: {
                    copier.copyTrack(tracksData.selectedTrack);
                }
            }
            Kirigami.Action {
                text: "Cancel Channel Copy"
                iconName: "dialog-cancel"
                enabled: copier.isCopyInProgress
                visible: copier.isCopyInProgress
                onTriggered: {
                    copier.cancelCopyTrack();
                }
            }
            Kirigami.Action {
                text: "Paste Channel"
                iconName: "edit-paste-symbolic"
                enabled: copier.isCopyInProgress
                visible: copier.isCopyInProgress
                onTriggered: {
                    copier.pasteTrack(sketchesData.selectedSketch);
                }
            }
        },
        Kirigami.Action {
            text: "Session"

            Kirigami.Action {
                text: "Save Session"
                iconName: "document-save-symbolic"
                onTriggered: {
                    fileNameDialog.fileName = "";
                    fileNameDialog.open();
                }
            }
            Kirigami.Action {
                text: "Load Session"
                iconName: "folder-download-symbolic"
                onTriggered: {
                    sessionPickerDialog.folderModel.folder = sessionPickerDialog.rootFolder;
                    sessionPickerDialog.open();
                }
            }
        }
    ]

    Component.onCompleted: {
        applicationWindow().controlsVisible = true;
    }

    Component.onDestruction: {
        applicationWindow().controlsVisible = true;
    }

    QtObject {
        id: privateProps

        // 12 buttons for both sketches and tracks
        property real buttonWidth: contentColumn.width/12 - contentColumn.spacing*2 - 10
        property real buttonHeight: Kirigami.Units.gridUnit*6
    }

    Zynthian.FilePickerDialog {
        id: sessionPickerDialog
        parent: root

        headerText: qsTr("Pick a session")
        rootFolder: "/zynthian/zynthian-my-data/sessions"
        folderModel {
            nameFilters: ["*.json"]
        }
        onFileSelected: {
            session.load(file.filePath);
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
            copier.addSketchPath = file.filePath;
        }
    }

    Zynthian.SaveFileDialog {
        id: fileNameDialog
        visible: false

        headerText: qsTr("New Session")
        conflictText: qsTr("Session Exists")
        overwriteOnConflict: false

        onFileNameChanged: {
            fileCheckTimer.restart()
        }
        Timer {
            id: fileCheckTimer
            interval: 300
            onTriggered: {
                if (fileNameDialog.fileName.length > 0 && session.exists(fileNameDialog.fileName)) {
                    fileNameDialog.conflict = true;
                } else {
                    fileNameDialog.conflict = false;
                }
            }
        }

        onAccepted: {
            console.log("Accepted")
            session.saveAs(fileNameDialog.fileName);
        }
        onRejected: {
            console.log("Rejected")
        }
    }

    contentItem : ColumnLayout {
        id: contentColumn
        Item {
            id: headerData
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit*4

            StackLayout {
                id: nameStack
                anchors.centerIn: parent

                RowLayout {
                    QQC2.Label {
                        text: qsTr("Project: %1").arg(session.name)
                        font.pointSize: 18
                    }
                    QQC2.Button {
                        icon.name: "document-edit"
                        onClicked: {
                            nameStack.currentIndex = 1;
                            objNameEdit.text = session.name;
                            objNameEdit.forceActiveFocus();
                        }
                    }
                }

                QQC2.TextField {
                    id: objNameEdit
                    onAccepted: {
                        session.name = text;
                        nameStack.currentIndex = 0;
                    }
                }
            }
        }
        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
        }
        ColumnLayout {
            property var selectedSketch: curSketch
            property int selectedIndex: 0

            id: sketchesData
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 1

            // Available height: Total container height - header height - 2 seperator height
            // Height set: AvailableHeight/2
            //Layout.preferredHeight: (contentColumn.height-headerData.height-2)/2

            RowLayout {
                QQC2.Label {
                    text: qsTr("Sketch %1: %2").arg(sketchesData.selectedIndex+1).arg(sketchesData.selectedSketch.name)
                    opacity: 0.7
                }

                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit
                }

                QQC2.Label {
                    text: qsTr("%1 BPM").arg(sketchesData.selectedSketch.bpm)
                }
            }

            RowLayout {
                CopierButton {
                    Layout.preferredWidth: privateProps.buttonWidth
                    Layout.preferredHeight: privateProps.buttonHeight

                    enabled: copier.addSketchPath.length <= 0
                    highlighted: sketchesData.selectedSketch == curSketch
                    text: "1"
                    onClicked: {
                        sketchesData.selectedSketch = curSketch;
                        sketchesData.selectedIndex = 0;
                    }
                }

                Repeater {
                    model: session.sessionSketchesModel
                    delegate: CopierButton {
                        property var sketch: model.sketch
                        property int slot: model.slot

                        Layout.preferredWidth: privateProps.buttonWidth
                        Layout.preferredHeight: privateProps.buttonHeight

                        highlighted: sketchesData.selectedSketch === sketch
                        text: sketch ? (index+2) : ""
                        enabled: copier.addSketchPath.length > 0 || (sketch ? true : false)
                        dummy: sketch ? false : true
                        onClicked: {
                            if (copier.addSketchPath.length > 0) {
                                console.log("Set sketch to slot " + slot);
                                copier.setSketchSlot(slot);
                            } else {
                                sketchesData.selectedSketch = sketch;
                                sketchesData.selectedIndex = slot+1;
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: sketchesInfoBar

                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: Kirigami.Units.gridUnit*2

                    QQC2.Label {
                        text: qsTr("%1 BPM").arg(sketchesData.selectedSketch.bpm)
                    }
                    Item {
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                    }
                    QQC2.Label {
                        text: qsTr("%1 Channels").arg(sketchesData.selectedSketch.tracksModel.count)
                    }
                }
            }
        }
        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
        }
        ColumnLayout {
            property var selectedTrack
            property int selectedTrackIndex

            id: tracksData
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 1

            QQC2.Label {
                text: qsTr("Channel %1: %2")
                        .arg(tracksData.selectedTrack ? (tracksData.selectedTrack.id+1) : "")
                        .arg(tracksData.selectedTrack ? tracksData.selectedTrack.name : "")
                opacity: 0.7
            }

            RowLayout {
                Repeater {
                    model: sketchesData.selectedSketch.tracksModel
                    delegate: CopierButton {
                        Layout.preferredWidth: privateProps.buttonWidth
                        Layout.preferredHeight: privateProps.buttonHeight

                        enabled: !copier.isCopyInProgress
                        highlighted: tracksData.selectedTrack === track
                        isCopySource: copier.trackCopySource === track
                        text: (index+1)
                        onClicked: {
                            tracksData.selectedTrack = track;
                        }
                    }
                }

                Repeater {
                    model: 12 - (sketchesData.selectedSketch.tracksModel.count
                                   ? sketchesData.selectedSketch.tracksModel.count
                                   : 0)
                    delegate: CopierButton {
                        Layout.preferredWidth: privateProps.buttonWidth
                        Layout.preferredHeight: privateProps.buttonHeight

                        text: ""
                        enabled: false
                        dummy: true
                    }
                }

                ColumnLayout {
                    id: tracksInfoBar
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: Kirigami.Units.gridUnit*2

                    QQC2.Label {
                        text: qsTr("Sounds:")
                    }
                }
            }
        }
    }
}
