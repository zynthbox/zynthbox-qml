/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

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

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian

Zynthian.Card {
    id: root
    enum ControlType {
        Song,
        Clip,
        Track,
        Part,
        None
    }

    property int controlType: BottomBar.ControlType.None
    property QtObject controlObj: null

    transform: Translate {
        y: Qt.inputMethod.visible ? -Kirigami.Units.gridUnit * 6 : 0
    }

    contentItem: ColumnLayout {
        RowLayout {
            Layout.fillWidth: true
            Layout.maximumHeight: Kirigami.Units.gridUnit * 2

            StackLayout {
                id: titleStack
                RowLayout {
                    Kirigami.Heading {
                        id: heading
                        text: {
                            let text = root.controlObj ? root.controlObj.name : "";
                            switch (root.controlType) {
                            case BottomBar.ControlType.Song:
                                return qsTr("SKETCH: %1").arg(text);
                            case BottomBar.ControlType.Clip:
                                return qsTr("CLIP: %1").arg(text);
                            case BottomBar.ControlType.Track:
                                return qsTr("TRACK: %1").arg(text);
                            case BottomBar.ControlType.Part:
                                return qsTr("PART: %1").arg(text);
                            default:
                                return text;
                            }
                        }
                        //Layout.fillWidth: true
                        wrapMode: Text.NoWrap
                    }
                    QQC2.Button {
                        icon.name: "document-edit"
                        visible: controlObj && controlObj.nameEditable
                        onClicked: {
                            titleStack.currentIndex = 1;
                            objNameEdit.text = root.controlObj ? root.controlObj.name : "";
                            objNameEdit.forceActiveFocus();
                        }
                        Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.medium*1.3)
                        Layout.preferredHeight: Layout.preferredWidth
                    }
                    Connections {
                        target: Qt.inputMethod
                        onVisibleChanged: {
                            if (!Qt.inputMethod.visible) {
                                titleStack.currentIndex = 0;
                            }
                        }
                    }
                }
                QQC2.TextField {
                    id: objNameEdit
                    onAccepted: {
                        controlObj.name = text
                        titleStack.currentIndex = 0;
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            SidebarButton {
                icon.name: "document-open"
                visible: root.controlType === BottomBar.ControlType.Clip

                onClicked: {
                    pickerDialog.open()
                }
            }

            SidebarButton {
                icon.name: "delete"
                visible: (controlObj != null) && controlObj.deletable

                onClicked: {
                    controlObj.delete();
                }
            }

            SidebarButton {
                icon.name: "edit-clear-all"
                visible: (controlObj != null) && controlObj.clearable

                onClicked: controlObj.clear()
            }

            SidebarButton {
                icon.name: controlObj.isPlaying ? "media-playback-stop" : "media-playback-start"
                visible: root.controlType !== BottomBar.ControlType.Part &&
                         (controlObj != null) && controlObj.playable && controlObj.path

                onClicked: {
                    if (controlObj.isPlaying) {
                        console.log("Stopping Sound Loop")
                        controlObj.stop();
                    } else {
                        console.log("Playing Sound Loop")
                        controlObj.play();
                    }
                }
            }

            SidebarButton {
                icon.name: "media-playback-start"
                visible: root.controlType === BottomBar.ControlType.Part &&
                         (controlObj != null) && controlObj.playable

                onClicked: {
                    console.log("Starting Part")
                    controlObj.play();
                }
            }

            SidebarButton {
                icon.name: "media-playback-stop"
                visible: root.controlType === BottomBar.ControlType.Part &&
                         (controlObj != null) && controlObj.playable

                onClicked: {
                    console.log("Stopping Part")
                    controlObj.stop();
                }
            }

//            SidebarButton {
//                icon.name: "media-record-symbolic"
//                icon.color: "#f44336"
//                visible: (controlObj != null) && controlObj.recordable && !controlObj.path
//                enabled: !controlObj.isRecording

//                onClicked: {
//                    controlObj.queueRecording();
//                }
//            }
        }

        Zynthian.TabbedControlView {
            id: tabbedView
            Layout.fillWidth: true
            Layout.fillHeight: true
            minimumTabsCount: 4
            orientation: Qt.Vertical

            initialAction: {
                switch (root.controlType) {
                case BottomBar.ControlType.Song:
                    return songAction;
                case BottomBar.ControlType.Clip:
                    return controlObj.hasOwnProperty("path") && controlObj.path.length > 0 ? waveAction : recordingAction;
                case BottomBar.ControlType.Track:
                    return trackAction;
                case BottomBar.ControlType.Part:
                    return partAction;
                default:
                    return waveAction;
                }
            }

            onInitialActionChanged: initialAction.trigger()

            tabActions: [
                Zynthian.TabbedControlViewAction {
                    id: songAction
                    text: qsTr("Song")
                    page: Qt.resolvedUrl("SongBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Song
                    initialProperties: {"bottomBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    text: qsTr("Mixer")
                    page: Qt.resolvedUrl("MixerBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Song
                    initialProperties: {"bottomBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    id: partAction
                    text: qsTr("Part")
                    page: Qt.resolvedUrl("PartBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Part
                    initialProperties: {"bottomBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    id: recordingAction
                    text: qsTr("Record")
                    page: Qt.resolvedUrl("RecordingBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Clip && controlObj.recordable && !controlObj.path
                    initialProperties: {"bottomBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    id: waveAction
                    text: qsTr("Wave")
                    page: Qt.resolvedUrl("WaveBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Clip && controlObj.path.length > 0
                    initialProperties: {"bottomBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    id: editorAction
                    text: qsTr("Editor")
                    page: Qt.resolvedUrl("EditorBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Clip && controlObj.path.length > 0
                    initialProperties: {"bottomBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    text: qsTr("Info")
                    page: Qt.resolvedUrl("InfoBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Clip && controlObj.path.length > 0
                    initialProperties: {"bottomBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    id: trackAction
                    text: qsTr("Track")
                    page: Qt.resolvedUrl("TrackBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Track
                    initialProperties: {"bottomBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    text: qsTr("FX")
                    page: Qt.resolvedUrl("FXBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Track
                    initialProperties: {"bottomBar": root}
                }
            ]
        }
    }

    QQC2.Dialog {
        id: pickerDialog
        parent: root.parent
        modal: true
        standardButtons: Dialog.Cancel
        header: ColumnLayout{
            spacing: 8

            Kirigami.Heading {
                text: qsTr("Pick an audio file")
                font.pointSize: 16
                Layout.leftMargin: 12
                Layout.topMargin: 12
            }

            RowLayout {
                property var folderSplitArray: String(folderModel.folder).replace("file:///", "").split("/").filter(function(e) { return e.length > 0 })

                id: folderBreadcrumbs
                Layout.leftMargin: 12
                spacing: 2
                Repeater {
                    model: folderBreadcrumbs.folderSplitArray
                    delegate: Zynthian.BreadcrumbButton {
                        text: modelData
                        onClicked: {
                            folderModel.folder = "/"+folderBreadcrumbs.folderSplitArray.slice(0, index+1).join("/")
                        }
                    }
                }
            }
        }
        x: parent.width/2 - width/2
        y: parent.height/2 - height/2
        width: Math.round(parent.width * 0.8)
        height: Math.round(parent.height * 0.8)
        contentItem: QQC2.ScrollView {
            contentItem: ListView {
                Layout.leftMargin: 8
                clip: true
                model: FolderListModel {
                    id: folderModel
                    nameFilters: ["*.wav"]
                    folder: root.controlObj.recordingDir
                    showDirs: true
                    showDirsFirst: true
                    showDotAndDotDot: true
                }
                delegate: Kirigami.BasicListItem {
                    label: model.fileName
                    icon: {
                        if (model.fileIsDir) {
                            return "folder-symbolic"
                        }
                        else if (model.filePath.endsWith(".wav")) {
                            return "folder-music-symbolic"
                        } else {
                            return "file-catalog-symbolic"
                        }
                    }
                    onClicked: {
                        if (model.fileIsDir) {
                            folderModel.folder = model.filePath
                        } else {
                            root.controlObj.path = model.filePath
                            pickerDialog.accept()
                        }
                    }
                }
            }
        }
    }
}
