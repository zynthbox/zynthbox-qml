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

Rectangle {
    id: root
    property alias filePickerDialog: pickerDialog
    property var channelCopySource: null
    property var clipCopySource: null
    property alias tabbedView: tabbedView

    property alias patternAction: patternAction
    property alias recordingAction: recordingAction
    property alias waveEditorAction: waveEditorAction
    property alias channelWaveEditorAction: channelWaveEditorAction
    property alias channelsViewSoundsBarAction: channelSoundsAction

    Layout.fillWidth: true
    color: Kirigami.Theme.backgroundColor

    enum ControlType {
        Song,
        Clip,
        Channel,
        Part,
        Pattern,
        None
    }

    function setControlObjByType(obj, type) {
        if (type === "song") {
            zynthian.bottomBarControlType = "bottombar-controltype-song"
        } else if (type === "clip") {
            zynthian.bottomBarControlType = "bottombar-controltype-clip"
        } else if (type === "channel") {
            zynthian.bottomBarControlType = "bottombar-controltype-channel"
        } else if (type === "part") {
            zynthian.bottomBarControlType = "bottombar-controltype-part"
        } else if (type === "pattern") {
            zynthian.bottomBarControlType = "bottombar-controltype-pattern"
        }

        zynthian.bottomBarControlObj = obj
    }

    Connections {
        target: zynthian
        onBottomBarControlObjChanged: {
            if (zynthian.bottomBarControlType === "bottombar-controltype-pattern") {
                patternAction.trigger();
            }
        }
    }


    onVisibleChanged: {
        if (visible) {
            tabbedView.initialAction.trigger()
        }
    }

    QQC2.ButtonGroup {
        buttons: buttonsColumn.children
    }

    RowLayout {
        anchors.fill: parent
        spacing: 1

        BottomStackTabs {
            id: buttonsColumn
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 6
            Layout.maximumWidth: Kirigami.Units.gridUnit * 6
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                Layout.fillWidth: true
                Layout.maximumHeight: Kirigami.Units.gridUnit * 2
                visible: zynthian.bottomBarControlType !== "bottombar-controltype-channel"

                EditableHeader {
                    controlObj: zynthian.bottomBarControlObj
                    controlType: zynthian.bottomBarControlType
                    text: {
                        let text = zynthian.bottomBarControlObj ? zynthian.bottomBarControlObj.name : "";
                        switch (zynthian.bottomBarControlType) {
                        case "bottombar-controltype-song":
                            return qsTr("Folder: %1  SKETCHPAD: %2").arg(zynthian.bottomBarControlObj.sketchpadFolderName).arg(text);
                        case "bottombar-controltype-clip":
                        case "bottombar-controltype-pattern":
                            return qsTr("CLIP: %1").arg(text);
                        case "bottombar-controltype-channel":
                            return qsTr("CHANNEL: %1").arg(text);
                        case "bottombar-controltype-part":
                            return qsTr("PART: %1").arg(text);
    //                    case "bottombar-controltype-pattern":
    //                        var sequence = ZynQuick.PlayGridManager.getSequenceModel(zynthian.sketchpad.song.scenesModel.selectedTrackName)
    //                        var pattern = sequence.getByPart(zynthian.bottomBarControlObj.clipChannel.connectedPattern, 0)
    //                        return qsTr("PATTERN: %1").arg(pattern.objectName)
                        default:
                            return text;
                        }
                    }
                }


                Item {
                    Layout.fillWidth: true
                }

                // Selecting custom slices not required. Keeping the dropdown commented if later required for something else
    //            QQC2.Label {
    //                visible: (zynthian.bottomBarControlType === "bottombar-controltype-clip" || zynthian.bottomBarControlType === "bottombar-controltype-pattern") &&
    //                         zynthian.bottomBarControlObj.clipChannel.channelAudioType === "sample-slice"
    //                text: qsTr("Slices")
    //            }

    //            QQC2.ComboBox {
    //                visible: (zynthian.bottomBarControlType === "bottombar-controltype-clip" || zynthian.bottomBarControlType === "bottombar-controltype-pattern") &&
    //                         zynthian.bottomBarControlObj.clipChannel.channelAudioType === "sample-slice"
    //                model: [4, 8, 12, 16]
    //                currentIndex: find(zynthian.bottomBarControlObj.slices)
    //                onActivated: zynthian.bottomBarControlObj.slices = model[index]
    //            }

                QQC2.Label {
                    visible: zynthian.bottomBarControlType === "bottombar-controltype-clip" || zynthian.bottomBarControlType === "bottombar-controltype-pattern"
                    text: zynthian.bottomBarControlObj && zynthian.bottomBarControlObj.path
                            ? qsTr("Sample (0): %1").arg(zynthian.bottomBarControlObj.path.split('/').pop())
                            : qsTr("No File Loaded")
                }

                SidebarButton {
                    icon.name: "document-save-symbolic"
                    active: zynthian.bottomBarControlType === "bottombar-controltype-clip" || zynthian.bottomBarControlType === "bottombar-controltype-pattern"
                             && zynthian.bottomBarControlObj.hasOwnProperty("path")
                             && zynthian.bottomBarControlObj.path.length > 0

                    onClicked: {
                        zynthian.bottomBarControlObj.saveMetadata();
                    }
                }

                SidebarButton {
                    icon.name: "document-open"
                    active: zynthian.bottomBarControlType === "bottombar-controltype-clip" || zynthian.bottomBarControlType === "bottombar-controltype-pattern"
                    enabled: zynthian.bottomBarControlObj ? !zynthian.bottomBarControlObj.isPlaying : false

                    onClicked: {
                        pickerDialog.folderModel.folder = zynthian.bottomBarControlObj.recordingDir;
                        pickerDialog.open();
                    }
                }

                SidebarButton {
                    icon.name: "delete"
                    active: (zynthian.bottomBarControlObj != null) && zynthian.bottomBarControlObj.deletable

                    onClicked: {
                        zynthian.bottomBarControlObj.delete();
                    }
                }

                SidebarButton {
                    icon.name: "edit-clear-all"
                    active: (zynthian.bottomBarControlObj != null) && zynthian.bottomBarControlObj.clearable
                    enabled: zynthian.bottomBarControlObj ? !zynthian.bottomBarControlObj.isPlaying : false

                    onClicked: {
                        zynthian.bottomBarControlObj.clear()
                    }
                }

                SidebarButton {
                    icon.name: "user-trash-symbolic"
                    active: zynthian.bottomBarControlObj != null && zynthian.bottomBarControlObj.path != null && zynthian.bottomBarControlObj.path.length > 0

                    onClicked: {
                        zynthian.bottomBarControlObj.deleteClip()
                    }
                }

                SidebarButton {
                    icon.name: zynthian.bottomBarControlObj && zynthian.bottomBarControlObj.isPlaying ? "media-playback-stop" : "media-playback-start"
                    active: zynthian.bottomBarControlType !== "bottombar-controltype-part" &&
                             (zynthian.bottomBarControlObj != null) && zynthian.bottomBarControlObj.playable && zynthian.bottomBarControlObj.path

                    onClicked: {
                        if (zynthian.bottomBarControlObj.isPlaying) {
                            console.log("Stopping Sound Loop")
                            zynthian.bottomBarControlObj.stop();
                        } else {
                            console.log("Playing Sound Loop")
                            zynthian.bottomBarControlObj.playSolo();
                        }
                    }
                }

                SidebarButton {
                    icon.name: "media-playback-start"
                    active: zynthian.bottomBarControlType === "bottombar-controltype-part" &&
                             (zynthian.bottomBarControlObj != null) && zynthian.bottomBarControlObj.playable

                    onClicked: {
                        console.log("Starting Part")
                        zynthian.bottomBarControlObj.play();
                    }
                }

                SidebarButton {
                    icon.name: "media-playback-stop"
                    active: zynthian.bottomBarControlType === "bottombar-controltype-part" &&
                             (zynthian.bottomBarControlObj != null) && zynthian.bottomBarControlObj.playable

                    onClicked: {
                        console.log("Stopping Part")
                        zynthian.bottomBarControlObj.stop();
                    }
                }

    //            SidebarButton {
    //                icon.name: "media-record-symbolic"
    //                icon.color: "#f44336"
    //                active: (zynthian.bottomBarControlObj != null) && zynthian.bottomBarControlObj.recordable && !zynthian.bottomBarControlObj.path
    //                enabled: !zynthian.sketchpad.isRecording

    //                onClicked: {
    //                    zynthian.bottomBarControlObj.queueRecording();
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
                    visible: zynthian.bottomBarControlType === "bottombar-controltype-channel"
                    EditableHeader {
                        id: tabbedViewHeader
                        controlObj: zynthian.bottomBarControlObj
                        controlType: zynthian.bottomBarControlType
                        Binding {
                            target: tabbedViewHeader
                            property: "text"
                            delayed: true
                            value: {
                                let text = zynthian.bottomBarControlObj ? zynthian.bottomBarControlObj.name : "";
                                switch (zynthian.bottomBarControlType) {
                                case "bottombar-controltype-song":
                                    return qsTr("Folder: %1  SKETCHPAD: %2").arg(zynthian.bottomBarControlObj.sketchpadFolderName).arg(text);
                                case "bottombar-controltype-clip":
                                case "bottombar-controltype-pattern":
                                    return qsTr("CLIP: %1").arg(text);
                                case "bottombar-controltype-channel":
                                    return qsTr("CHANNEL: %1").arg(text);
                                case "bottombar-controltype-part":
                                    return qsTr("PART: %1").arg(text);
        //                        case "bottombar-controltype-pattern":
        //                            return qsTr("PATTERN: %1").arg(zynthian.bottomBarControlObj.col+1);
                                default:
                                    return text;
                                }
                            }
                        }
                    }
                    Item {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    }
                }
                finalHeaderItem: RowLayout {
                    visible: zynthian.bottomBarControlType === "bottombar-controltype-channel"
                    Item {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    }
    //                QQC2.Label {
    //                    visible: zynthian.bottomBarControlObj.connectedPattern >= 0
    //                    property QtObject sequence: zynthian.bottomBarControlObj.connectedPattern >= 0 ? ZynQuick.PlayGridManager.getSequenceModel(zynthian.sketchpad.song.scenesModel.selectedTrackName) : null
    //                    property QtObject pattern: sequence ? sequence.getByPart(zynthian.bottomBarControlObj.id, zynthian.bottomBarControlObj.selectedPart) : null
    //                    text: qsTr("Pattern %1").arg(zynthian.bottomBarControlObj.connectedPattern+1)
    //                }
                    QQC2.Button {
                        visible: zynthian.bottomBarControlObj && zynthian.bottomBarControlObj.connectedPattern < 0
                        Layout.fillHeight: true

                        text: qsTr("Midi")
                        //enabled: !channelDelegate.hasWavLoaded && !channelDelegate.channelHasConnectedPattern

                        onClicked: {
                            zynthian.session_dashboard.midiSelectionRequested();
                        }
                    }
    //                SidebarButton {
    //                    icon.name: "edit-clear-all"
    //                    active: (zynthian.bottomBarControlObj != null) && zynthian.bottomBarControlObj.clearable
    //                    enabled: zynthian.bottomBarControlObj ? !zynthian.bottomBarControlObj.isPlaying : false

    //                    onClicked: {
    //                        zynthian.bottomBarControlObj.clear()

    //                        var seq = ZynQuick.PlayGridManager.getSequenceModel(zynthian.sketchpad.song.scenesModel.selectedTrackName).getByPart(zynthian.bottomBarControlObj.id, zynthian.bottomBarControlObj.selectedPart);
    //                        seq.enabled = false;
    //                        zynthian.bottomBarControlObj.connectedPattern = -1;
    //                    }
    //                }

//                    Binding {
//                        target: channelAudioTypeDropdown
//                        property: "currentIndex"
//                        delayed: true
//                        value: zynthian.bottomBarControlObj &&
//                               zynthian.bottomBarControlObj.channelAudioType
//                                 ? channelAudioTypeDropdown.findCurrentIndex(zynthian.bottomBarControlObj.channelAudioType)
//                                 : -1
//                    }

//                    QQC2.ComboBox {
//                        id: channelAudioTypeDropdown

//                        function findCurrentIndex(val) {
//                            for (var i = 0; i < model.count; i++) {
//                                if (model.get(i).value === val) {
//                                    return i
//                                }
//                            }

//                            return -1
//                        }

//                        // For simplicity, channelAudioType is string in the format "sample-xxxx" or "synth"
//                        model: ListModel {
//                            ListElement { text: "Synth"; value: "synth" }
//                            ListElement { text: "Audio"; value: "sample-loop" }
//                            ListElement { text: "Smp: Trig"; value: "sample-trig" }
//                            ListElement { text: "Smp: Slice"; value: "sample-slice" }
//                            ListElement { text: "External"; value: "external" }
//                        }
//                        textRole: "text"
//                        currentIndex:  -1
//                        onActivated: {
//                            zynthian.bottomBarControlObj.channelAudioType = channelAudioTypeDropdown.model.get(index).value;
//                        }
//                    }
                }

                initialAction: {
                    switch (zynthian.bottomBarControlType) {
                    case "bottombar-controltype-song":
                        return songAction;
                    case "bottombar-controltype-clip":
                        return zynthian.bottomBarControlObj.hasOwnProperty("path") && zynthian.bottomBarControlObj.path.length > 0 ? clipSettingsAction : recordingAction;
                    case "bottombar-controltype-channel":
                        if (zynthian.bottomBarControlObj.channelAudioType === "synth")
                            return channelSoundsAction;
                        else {
                            return sampleSoundsAction;
                        }

                    case "bottombar-controltype-part":
                        return partAction;
                    case "bottombar-controltype-pattern":
                        return zynthian.bottomBarControlObj.hasOwnProperty("path") && zynthian.bottomBarControlObj.path.length > 0 ? clipSettingsAction : patternAction;
                    default:
                        return clipSettingsAction;
                    }
                }

                onInitialActionChanged: Qt.callLater(initialAction.trigger)

                tabActions: [
                    Zynthian.TabbedControlViewAction {
                        id: songAction
                        text: qsTr("Song")
                        page: Qt.resolvedUrl("SongBar.qml")
                        preload: true
                        visible: zynthian.bottomBarControlType === "bottombar-controltype-song"
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: partAction
                        text: qsTr("Clip")
                        page: Qt.resolvedUrl("PartBar.qml")
                        preload: true
                        visible: zynthian.bottomBarControlType === "bottombar-controltype-part"
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: recordingAction
                        text: qsTr("Audio")
                        page: Qt.resolvedUrl("RecordingBar.qml")
                        preload: true
                        visible: (zynthian.bottomBarControlType === "bottombar-controltype-clip" || zynthian.bottomBarControlType === "bottombar-controltype-pattern") && zynthian.bottomBarControlObj.recordable && !zynthian.bottomBarControlObj.path
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        text: qsTr("Clip Info")
                        page: Qt.resolvedUrl("ClipInfoBar.qml")
                        preload: true
                        visible: (zynthian.bottomBarControlType === "bottombar-controltype-clip" || zynthian.bottomBarControlType === "bottombar-controltype-pattern") && zynthian.bottomBarControlObj.path !== undefined && zynthian.bottomBarControlObj.path.length > 0
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: clipSettingsAction
                        text: qsTr("Clip Settings")
                        page: Qt.resolvedUrl("ClipSettingsBar.qml")
                        preload: true
                        visible: (zynthian.bottomBarControlType === "bottombar-controltype-clip" || zynthian.bottomBarControlType === "bottombar-controltype-pattern") && zynthian.bottomBarControlObj.path !== undefined && zynthian.bottomBarControlObj.path.length > 0
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: waveEditorAction
                        text: qsTr("Wave Editor")
                        page: Qt.resolvedUrl("WaveEditorBar.qml")
                        preload: true
                        visible: (zynthian.bottomBarControlType === "bottombar-controltype-clip" || zynthian.bottomBarControlType === "bottombar-controltype-pattern") && zynthian.bottomBarControlObj.path !== undefined && zynthian.bottomBarControlObj.path.length > 0
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: patternAction
                        text: qsTr("Pattern")
                        page: Qt.resolvedUrl("PatternBar.qml")
                        preload: true
                        visible: zynthian.bottomBarControlType === "bottombar-controltype-pattern"
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: channelAction
                        text: qsTr("Channel")
                        page: Qt.resolvedUrl("ChannelBar.qml")
                        preload: true
                        visible: zynthian.bottomBarControlType === "bottombar-controltype-channel"
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: channelSoundsAction
                        text: qsTr("Sounds")
                        page: Qt.resolvedUrl("../SessionDashboard/ChannelsViewSoundsBar.qml")
                        preload: true
                        visible: zynthian.bottomBarControlType === "bottombar-controltype-channel"
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: sampleSoundsAction
                        text: qsTr("Samples")
                        page: Qt.resolvedUrl("SamplesBar.qml")
                        preload: true
                        visible: zynthian.bottomBarControlType === "bottombar-controltype-channel"
                        initialProperties: {"bottomBar": root}
                    },
                    // Duplicate tab instance but for different placement and zynthian.bottomBarControlObj for channel
                    Zynthian.TabbedControlViewAction {
                        id: channelclipSettingsAction

                        property QtObject clip: zynthian.bottomBarControlObj && zynthian.bottomBarControlObj.samples ? zynthian.bottomBarControlObj.samples[zynthian.bottomBarControlObj.selectedSlotRow] : null

                        text: qsTr("Smp. Settings")
                        page: Qt.resolvedUrl("ClipSettingsBar.qml")
                        visible: zynthian.bottomBarControlType === "bottombar-controltype-channel" &&
                                 clip && clip.path && clip.path.length > 0
                        initialProperties: {"bottomBar": root}
                    },
                    // Duplicate tab instance but for different placement and zynthian.bottomBarControlObj for channel
                    Zynthian.TabbedControlViewAction {
                        id: channelWaveEditorAction

                        property QtObject clip: zynthian.bottomBarControlObj && zynthian.bottomBarControlObj.samples ? zynthian.bottomBarControlObj.samples[zynthian.bottomBarControlObj.selectedSlotRow] : null

                        text: qsTr("Wave Editor")
                        page: Qt.resolvedUrl("WaveEditorBar.qml")
                        visible: zynthian.bottomBarControlType === "bottombar-controltype-channel" &&
                                 clip && clip.path && clip.path.length > 0
                        initialProperties: {"bottomBar": root}
                    }
                   /* Zynthian.TabbedControlViewAction {
                        text: qsTr("FX")
                        page: Qt.resolvedUrl("FXBar.qml")
                        visible: zynthian.bottomBarControlType === "bottombar-controltype-channel"
                        initialProperties: {"bottomBar": root}
                    },*/
                ]
            }
        }
    }

    Zynthian.FilePickerDialog {
        id: pickerDialog
        parent: zlScreen.parent

        width: parent.width
        height: parent.height
        x: parent.x
        y: parent.y

        headerText: qsTr("%1 : Pick an audio file").arg(zynthian.bottomBarControlObj ? zynthian.bottomBarControlObj.channelName : "")
        rootFolder: "/zynthian/zynthian-my-data"
        folderModel {
            nameFilters: ["*.wav"]
        }
        onFileSelected: {
            zynthian.bottomBarControlObj.path = file.filePath
        }
    }
}
