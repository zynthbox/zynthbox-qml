/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Sketchpad CopierPage

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
    readonly property QtObject copier: zynqtgui.sketchpad_copier
    readonly property QtObject session: zynqtgui.session_dashboard
    readonly property QtObject curSketchpad: zynqtgui.sketchpad.song

    id: root

    title: qsTr("Sketchpad Copier")
    screenId: "sketchpad_copier"
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8

    contextualActions: [
        Kirigami.Action {
            text: "Sketchpad"

            Kirigami.Action {
                text: "Add New Sketchpad"
                iconName: "document-new-symbolic"
                onTriggered: {
                }
            }
            Kirigami.Action {
                text: "Add Existing Sketchpad"
                iconName: "folder-new-symbolic"
                onTriggered: {
                    sketchpadPickerDialog.folderModel.folder = sketchpadPickerDialog.rootFolder;
                    sketchpadPickerDialog.open();
                }
            }
            Kirigami.Action {
                text: "Remove Sketchpad"
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
                    copier.copyChannel(channelsData.selectedChannel);
                }
            }
            Kirigami.Action {
                text: "Cancel Channel Copy"
                iconName: "dialog-cancel"
                enabled: copier.isCopyInProgress
                visible: copier.isCopyInProgress
                onTriggered: {
                    copier.cancelCopyChannel();
                }
            }
            Kirigami.Action {
                text: "Paste Channel"
                iconName: "edit-paste-symbolic"
                enabled: copier.isCopyInProgress
                visible: copier.isCopyInProgress
                onTriggered: {
                    copier.pasteChannel(sketchpadsData.selectedSketchpad);
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

        // 12 buttons for both sketchpads and channels
        property real buttonWidth: contentColumn.width/12 - contentColumn.spacing*2 - 10
        property real buttonHeight: Kirigami.Units.gridUnit*6
    }

    Zynthian.FilePickerDialog {
        id: sessionPickerDialog
        parent: root

        headerText: qsTr("Pick a session")
        rootFolder: "/zynqtgui/zynqtgui-my-data/sessions"
        folderModel {
            nameFilters: ["*.json"]
        }
        onFileSelected: {
            session.load(file.filePath);
        }
    }

    Zynthian.FilePickerDialog {
        id: sketchpadPickerDialog
        parent: root

        headerText: qsTr("Pick a sketchpad")
        rootFolder: "/zynqtgui/zynqtgui-my-data/sketchpads"
        folderModel {
            nameFilters: ["*.json"]
        }
        onFileSelected: {
            copier.addSketchpadPath = file.filePath;
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
            property var selectedSketchpad: curSketchpad
            property int selectedIndex: 0

            id: sketchpadsData
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 1

            // Available height: Total container height - header height - 2 seperator height
            // Height set: AvailableHeight/2
            //Layout.preferredHeight: (contentColumn.height-headerData.height-2)/2

            RowLayout {
                QQC2.Label {
                    text: qsTr("Sketchpad %1: %2").arg(sketchpadsData.selectedIndex+1).arg(sketchpadsData.selectedSketchpad.name)
                    opacity: 0.7
                }

                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit
                }

                QQC2.Label {
                    text: qsTr("%1 BPM").arg(sketchpadsData.selectedSketchpad.bpm)
                }
            }

            RowLayout {
                CopierButton {
                    Layout.preferredWidth: privateProps.buttonWidth
                    Layout.preferredHeight: privateProps.buttonHeight

                    enabled: copier.addSketchpadPath.length <= 0
                    highlighted: sketchpadsData.selectedSketchpad == curSketchpad
                    text: "1"
                    onClicked: {
                        sketchpadsData.selectedSketchpad = curSketchpad;
                        sketchpadsData.selectedIndex = 0;
                    }
                }

                Repeater {
                    model: session.sessionSketchpadsModel
                    delegate: CopierButton {
                        property var sketchpad: model.sketchpad
                        property int slot: model.slot

                        Layout.preferredWidth: privateProps.buttonWidth
                        Layout.preferredHeight: privateProps.buttonHeight

                        highlighted: sketchpadsData.selectedSketchpad === sketchpad
                        text: sketchpad ? (index+2) : ""
                        enabled: copier.addSketchpadPath.length > 0 || (sketchpad ? true : false)
                        dummy: sketchpad ? false : true
                        onClicked: {
                            if (copier.addSketchpadPath.length > 0) {
                                console.log("Set sketchpad to slot " + slot);
                                copier.setSketchpadSlot(slot);
                            } else {
                                sketchpadsData.selectedSketchpad = sketchpad;
                                sketchpadsData.selectedIndex = slot+1;
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: sketchpadsInfoBar

                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: Kirigami.Units.gridUnit*2

                    QQC2.Label {
                        text: qsTr("%1 BPM").arg(sketchpadsData.selectedSketchpad.bpm)
                    }
                    Item {
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                    }
                    QQC2.Label {
                        text: qsTr("%1 Channels").arg(sketchpadsData.selectedSketchpad.channelsModel.count)
                    }
                }
            }
        }
        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
        }
        ColumnLayout {
            property var selectedChannel
            property int selectedChannelIndex

            id: channelsData
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 1

            QQC2.Label {
                text: qsTr("Channel %1: %2")
                        .arg(channelsData.selectedChannel ? (channelsData.selectedChannel.id+1) : "")
                        .arg(channelsData.selectedChannel ? channelsData.selectedChannel.name : "")
                opacity: 0.7
            }

            RowLayout {
                Repeater {
                    model: sketchpadsData.selectedSketchpad.channelsModel
                    delegate: CopierButton {
                        Layout.preferredWidth: privateProps.buttonWidth
                        Layout.preferredHeight: privateProps.buttonHeight

                        enabled: !copier.isCopyInProgress
                        highlighted: channelsData.selectedChannel === channel
                        isCopySource: copier.channelCopySource === channel
                        text: (index+1)
                        onClicked: {
                            channelsData.selectedChannel = channel;
                        }
                    }
                }

                Repeater {
                    model: 12 - (sketchpadsData.selectedSketchpad.channelsModel.count
                                   ? sketchpadsData.selectedSketchpad.channelsModel.count
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
                    id: channelsInfoBar
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
