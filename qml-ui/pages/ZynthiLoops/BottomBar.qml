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
import org.zynthian.quick 1.0 as ZynQuick

Zynthian.Card {
    property alias filePickerDialog: pickerDialog
    property var trackCopySource: null
    property var clipCopySource: null
    property alias tabbedView: tabbedView

    leftPadding: 0
    rightPadding: 0

    id: root
    enum ControlType {
        Song,
        Clip,
        Track,
        Part,
        Pattern,
        None
    }

    property int controlType: BottomBar.ControlType.None
    property QtObject controlObj: null

    onControlObjChanged: {
        if (root.controlType === BottomBar.ControlType.Pattern) {
            patternAction.trigger();
        }
    }

    transform: Translate {
        y: Qt.inputMethod.visible ? -Kirigami.Units.gridUnit * 6 : 0
    }

    contentItem: ColumnLayout {
        RowLayout {
            Layout.fillWidth: true
            Layout.maximumHeight: Kirigami.Units.gridUnit * 2
            visible: root.controlType !== BottomBar.ControlType.Track

            EditableHeader {
                text: {
                    let text = root.controlObj ? root.controlObj.name : "";
                    switch (root.controlType) {
                    case BottomBar.ControlType.Song:
                        return qsTr("Folder: %1  SKETCH: %2").arg(root.controlObj.sketchFolderName).arg(text);
                    case BottomBar.ControlType.Clip:
                        return qsTr("CLIP: %1").arg(text);
                    case BottomBar.ControlType.Track:
                        return qsTr("TRACK: %1").arg(text);
                    case BottomBar.ControlType.Part:
                        return qsTr("PART: %1").arg(text);
                    case BottomBar.ControlType.Pattern:
                        var sequence = ZynQuick.PlayGridManager.getSequenceModel("Global "+zynthian.zynthiloops.song.scenesModel.selectedSceneName)
                        var pattern = sequence.get(root.controlObj.clipTrack.connectedPattern)
                        return qsTr("PATTERN: %1, pt.%2")
                                                .arg(pattern.objectName)
                                                .arg(root.controlObj.col == 0 ? "I" : "II")
                    default:
                        return text;
                    }
                }
            }


            Item {
                Layout.fillWidth: true
            }

            QQC2.Label {
                visible: root.controlType === BottomBar.ControlType.Clip
                text: {
                    if (!controlObj || !controlObj.path) {
                        return qsTr("No File Loaded");
                    }
                    var arr = controlObj.path.split('/');
                    return qsTr("File: %1").arg(arr[arr.length - 1]);
                }
            }

            SidebarButton {
                icon.name: "document-save-symbolic"
                visible: root.controlType === BottomBar.ControlType.Clip
                         && controlObj.hasOwnProperty("path")
                         && controlObj.path.length > 0

                onClicked: {
                    controlObj.saveMetadata();
                }
            }

            SidebarButton {
                icon.name: "document-open"
                visible: root.controlType === BottomBar.ControlType.Clip
                enabled: controlObj ? !controlObj.isPlaying : false

                onClicked: {
                    pickerDialog.folderModel.folder = root.controlObj.recordingDir;
                    pickerDialog.open();
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
                enabled: controlObj ? !controlObj.isPlaying : false

                onClicked: {
                    if (root.controlType === BottomBar.ControlType.Pattern && patternAction.checked) {
                        var sequence = ZynQuick.PlayGridManager.getSequenceModel("Global "+zynthian.zynthiloops.song.scenesModel.selectedSceneName)
                        var pattern = sequence.get(root.controlObj.clipTrack.connectedPattern)

//                        pattern.clearBank(root.controlObj.col);
                    } else {
                        controlObj.clear()
                    }

                    if (root.controlType === BottomBar.ControlType.Pattern || root.controlType === BottomBar.ControlType.Clip) {
                        zynthian.zynthiloops.song.scenesModel.removeClipFromCurrentScene(root.controlObj);
                    }
                }
            }

            SidebarButton {
                icon.name: controlObj && controlObj.isPlaying ? "media-playback-stop" : "media-playback-start"
                visible: root.controlType !== BottomBar.ControlType.Part &&
                         (controlObj != null) && controlObj.playable && controlObj.path

                onClicked: {
                    if (controlObj.isPlaying) {
                        console.log("Stopping Sound Loop")
                        controlObj.stop();
                    } else {
                        console.log("Playing Sound Loop")
                        controlObj.playSolo();
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
            visibleFocusRects: false

            initialHeaderItem: RowLayout {
                visible: root.controlType === BottomBar.ControlType.Track
                EditableHeader {
                    text: {
                        let text = root.controlObj ? root.controlObj.name : "";
                        switch (root.controlType) {
                        case BottomBar.ControlType.Song:
                            return qsTr("Folder: %1  SKETCH: %2").arg(root.controlObj.sketchFolderName).arg(text);
                        case BottomBar.ControlType.Clip:
                            return qsTr("CLIP: %1").arg(text);
                        case BottomBar.ControlType.Track:
                            return qsTr("TRACK: %1").arg(text);
                        case BottomBar.ControlType.Part:
                            return qsTr("PART: %1").arg(text);
                        case BottomBar.ControlType.Pattern:
                            return qsTr("PATTERN: %1").arg(root.controlObj.col+1);
                        default:
                            return text;
                        }
                    }
                }
                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                }
            }
            finalHeaderItem: RowLayout {
                visible: root.controlType === BottomBar.ControlType.Track
                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                }
                QQC2.Label {
                    visible: controlObj.connectedPattern >= 0
                    property QtObject sequence: controlObj.connectedPattern >= 0 ? ZynQuick.PlayGridManager.getSequenceModel("Global "+zynthian.zynthiloops.song.scenesModel.selectedSceneName) : null
                    property QtObject pattern: sequence ? sequence.get(controlObj.connectedPattern) : null
                    text: qsTr("Pattern %1").arg(controlObj.connectedPattern+1)
                }
                QQC2.Button {
                    visible: controlObj.connectedPattern < 0
                    Layout.fillHeight: true

                    text: qsTr("Midi")
                    //enabled: !trackDelegate.hasWavLoaded && !trackDelegate.trackHasConnectedPattern

                    onClicked: {
                        zynthian.session_dashboard.midiSelectionRequested();
                    }
                }
                SidebarButton {
                    icon.name: "edit-clear-all"
                    visible: (controlObj != null) && controlObj.clearable
                    enabled: controlObj ? !controlObj.isPlaying : false

                    onClicked: {
                        controlObj.clear()

                        var seq = ZynQuick.PlayGridManager.getSequenceModel("Global "+zynthian.zynthiloops.song.scenesModel.selectedSceneName).get(controlObj.connectedPattern);
                        seq.enabled = false;
                        controlObj.connectedPattern = -1;
                    }
                }
            }

            initialAction: {
                switch (root.controlType) {
                case BottomBar.ControlType.Song:
                    return songAction;
                case BottomBar.ControlType.Clip:
                    return controlObj.hasOwnProperty("path") && controlObj.path.length > 0 ? waveAction : recordingAction;
                case BottomBar.ControlType.Track:
                    return trackSoundsAction;
                case BottomBar.ControlType.Part:
                    return partAction;
                case BottomBar.ControlType.Pattern:
                    return patternAction;
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
                    visible: (root.controlType === BottomBar.ControlType.Clip || root.controlType === BottomBar.ControlType.Pattern) && controlObj.recordable && !controlObj.path
                    initialProperties: {"bottomBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    id: waveAction
                    text: qsTr("Clip Settings")
                    page: Qt.resolvedUrl("ClipSettingsBar.qml")
                    visible: (root.controlType === BottomBar.ControlType.Clip || root.controlType === BottomBar.ControlType.Pattern) && controlObj.path.length > 0
                    initialProperties: {"bottomBar": root}
                    preload: true
                },
                Zynthian.TabbedControlViewAction {
                    id: editorAction
                    text: qsTr("Wave Editor")
                    page: Qt.resolvedUrl("WaveEditorBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Clip && controlObj.path.length > 0
                    initialProperties: {"bottomBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    id: metadataSoundsAction
                    text: qsTr("Sounds")
                    page: Qt.resolvedUrl("MetadataSoundsBar.qml")
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
                    id: trackSoundsAction
                    text: qsTr("Sounds")
                    page: Qt.resolvedUrl("../SessionDashboard/TracksViewSoundsBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Track
                    initialProperties: {"bottomBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    id: trackAction
                    text: qsTr("Track")
                    page: Qt.resolvedUrl("TrackBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Track
                    initialProperties: {"bottomBar": root}
                },
               /* Zynthian.TabbedControlViewAction {
                    text: qsTr("FX")
                    page: Qt.resolvedUrl("FXBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Track
                    initialProperties: {"bottomBar": root}
                },*/
                Zynthian.TabbedControlViewAction {
                    id: patternAction
                    text: qsTr("Pattern")
                    page: Qt.resolvedUrl("PatternBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Pattern
                    initialProperties: {"bottomBar": root}
                }
            ]
        }
    }

    Zynthian.FilePickerDialog {
        id: pickerDialog
        parent: zlScreen.parent

        width: parent.width
        height: parent.height
        x: parent.x
        y: parent.y

        headerText: qsTr("%1 : Pick an audio file").arg(root.controlObj ? root.controlObj.trackName : "")
        rootFolder: "/zynthian/zynthian-my-data"
        folderModel {
            nameFilters: ["*.wav"]
        }
        onFileSelected: {
            root.controlObj.path = file.filePath
        }
    }
}
