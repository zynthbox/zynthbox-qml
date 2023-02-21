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

    property int controlType: BottomBar.ControlType.None
    property QtObject controlObj: null

    function setControlObjByType(obj, type) {
        if (type === "song") {
            root.controlType = BottomBar.ControlType.Song
        } else if (type === "clip") {
            root.controlType = BottomBar.ControlType.Clip
        } else if (type === "channel") {
            root.controlType = BottomBar.ControlType.Channel
        } else if (type === "part") {
            root.controlType = BottomBar.ControlType.Part
        } else if (type === "pattern") {
            root.controlType = BottomBar.ControlType.Pattern
        }

        root.controlObj = obj
    }

    onControlObjChanged: {
        if (root.controlType === BottomBar.ControlType.Pattern) {
            patternAction.trigger();
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
                visible: root.controlType !== BottomBar.ControlType.Channel

                EditableHeader {
                    text: {
                        let text = root.controlObj ? root.controlObj.name : "";
                        switch (root.controlType) {
                        case BottomBar.ControlType.Song:
                            return qsTr("Folder: %1  SKETCHPAD: %2").arg(root.controlObj.sketchpadFolderName).arg(text);
                        case BottomBar.ControlType.Clip:
                        case BottomBar.ControlType.Pattern:
                            return qsTr("CLIP: %1").arg(text);
                        case BottomBar.ControlType.Channel:
                            return qsTr("CHANNEL: %1").arg(text);
                        case BottomBar.ControlType.Part:
                            return qsTr("PART: %1").arg(text);
    //                    case BottomBar.ControlType.Pattern:
    //                        var sequence = ZynQuick.PlayGridManager.getSequenceModel(zynthian.sketchpad.song.scenesModel.selectedTrackName)
    //                        var pattern = sequence.getByPart(root.controlObj.clipChannel.connectedPattern, 0)
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
    //                visible: (root.controlType === BottomBar.ControlType.Clip || root.controlType === BottomBar.ControlType.Pattern) &&
    //                         controlObj.clipChannel.channelAudioType === "sample-slice"
    //                text: qsTr("Slices")
    //            }

    //            QQC2.ComboBox {
    //                visible: (root.controlType === BottomBar.ControlType.Clip || root.controlType === BottomBar.ControlType.Pattern) &&
    //                         controlObj.clipChannel.channelAudioType === "sample-slice"
    //                model: [4, 8, 12, 16]
    //                currentIndex: find(controlObj.slices)
    //                onActivated: controlObj.slices = model[index]
    //            }

                QQC2.Label {
                    visible: root.controlType === BottomBar.ControlType.Clip || root.controlType === BottomBar.ControlType.Pattern
                    text: controlObj && controlObj.path
                            ? qsTr("Sample (0): %1").arg(controlObj.path.split('/').pop())
                            : qsTr("No File Loaded")
                }

                SidebarButton {
                    icon.name: "document-save-symbolic"
                    active: root.controlType === BottomBar.ControlType.Clip || root.controlType === BottomBar.ControlType.Pattern
                             && controlObj.hasOwnProperty("path")
                             && controlObj.path.length > 0

                    onClicked: {
                        controlObj.saveMetadata();
                    }
                }

                SidebarButton {
                    icon.name: "document-open"
                    active: root.controlType === BottomBar.ControlType.Clip || root.controlType === BottomBar.ControlType.Pattern
                    enabled: controlObj ? !controlObj.isPlaying : false

                    onClicked: {
                        pickerDialog.folderModel.folder = root.controlObj.recordingDir;
                        pickerDialog.open();
                    }
                }

                SidebarButton {
                    icon.name: "delete"
                    active: (controlObj != null) && controlObj.deletable

                    onClicked: {
                        controlObj.delete();
                    }
                }

                SidebarButton {
                    icon.name: "edit-clear-all"
                    active: (controlObj != null) && controlObj.clearable
                    enabled: controlObj ? !controlObj.isPlaying : false

                    onClicked: {
                        controlObj.clear()
                    }
                }

                SidebarButton {
                    icon.name: "user-trash-symbolic"
                    active: controlObj != null && controlObj.path != null && controlObj.path.length > 0

                    onClicked: {
                        controlObj.deleteClip()
                    }
                }

                SidebarButton {
                    icon.name: controlObj && controlObj.isPlaying ? "media-playback-stop" : "media-playback-start"
                    active: root.controlType !== BottomBar.ControlType.Part &&
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
                    active: root.controlType === BottomBar.ControlType.Part &&
                             (controlObj != null) && controlObj.playable

                    onClicked: {
                        console.log("Starting Part")
                        controlObj.play();
                    }
                }

                SidebarButton {
                    icon.name: "media-playback-stop"
                    active: root.controlType === BottomBar.ControlType.Part &&
                             (controlObj != null) && controlObj.playable

                    onClicked: {
                        console.log("Stopping Part")
                        controlObj.stop();
                    }
                }

    //            SidebarButton {
    //                icon.name: "media-record-symbolic"
    //                icon.color: "#f44336"
    //                active: (controlObj != null) && controlObj.recordable && !controlObj.path
    //                enabled: !zynthian.sketchpad.isRecording

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
                    visible: root.controlType === BottomBar.ControlType.Channel
                    EditableHeader {
                        id: tabbedViewHeader
                        Binding {
                            target: tabbedViewHeader
                            property: "text"
                            delayed: true
                            value: {
                                let text = root.controlObj ? root.controlObj.name : "";
                                switch (root.controlType) {
                                case BottomBar.ControlType.Song:
                                    return qsTr("Folder: %1  SKETCHPAD: %2").arg(root.controlObj.sketchpadFolderName).arg(text);
                                case BottomBar.ControlType.Clip:
                                case BottomBar.ControlType.Pattern:
                                    return qsTr("CLIP: %1").arg(text);
                                case BottomBar.ControlType.Channel:
                                    return qsTr("CHANNEL: %1").arg(text);
                                case BottomBar.ControlType.Part:
                                    return qsTr("PART: %1").arg(text);
        //                        case BottomBar.ControlType.Pattern:
        //                            return qsTr("PATTERN: %1").arg(root.controlObj.col+1);
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
                    visible: root.controlType === BottomBar.ControlType.Channel
                    Item {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    }
    //                QQC2.Label {
    //                    visible: controlObj.connectedPattern >= 0
    //                    property QtObject sequence: controlObj.connectedPattern >= 0 ? ZynQuick.PlayGridManager.getSequenceModel(zynthian.sketchpad.song.scenesModel.selectedTrackName) : null
    //                    property QtObject pattern: sequence ? sequence.getByPart(controlObj.id, controlObj.selectedPart) : null
    //                    text: qsTr("Pattern %1").arg(controlObj.connectedPattern+1)
    //                }
                    QQC2.Button {
                        visible: controlObj && controlObj.connectedPattern < 0
                        Layout.fillHeight: true

                        text: qsTr("Midi")
                        //enabled: !channelDelegate.hasWavLoaded && !channelDelegate.channelHasConnectedPattern

                        onClicked: {
                            zynthian.session_dashboard.midiSelectionRequested();
                        }
                    }
    //                SidebarButton {
    //                    icon.name: "edit-clear-all"
    //                    active: (controlObj != null) && controlObj.clearable
    //                    enabled: controlObj ? !controlObj.isPlaying : false

    //                    onClicked: {
    //                        controlObj.clear()

    //                        var seq = ZynQuick.PlayGridManager.getSequenceModel(zynthian.sketchpad.song.scenesModel.selectedTrackName).getByPart(controlObj.id, controlObj.selectedPart);
    //                        seq.enabled = false;
    //                        controlObj.connectedPattern = -1;
    //                    }
    //                }

//                    Binding {
//                        target: channelAudioTypeDropdown
//                        property: "currentIndex"
//                        delayed: true
//                        value: controlObj &&
//                               controlObj.channelAudioType
//                                 ? channelAudioTypeDropdown.findCurrentIndex(controlObj.channelAudioType)
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
//                            controlObj.channelAudioType = channelAudioTypeDropdown.model.get(index).value;
//                        }
//                    }
                }

                initialAction: {
                    switch (root.controlType) {
                    case BottomBar.ControlType.Song:
                        return songAction;
                    case BottomBar.ControlType.Clip:
                        return controlObj.hasOwnProperty("path") && controlObj.path.length > 0 ? clipSettingsAction : recordingAction;
                    case BottomBar.ControlType.Channel:
                        if (controlObj.channelAudioType === "synth")
                            return channelSoundsAction;
                        else {
                            return sampleSoundsAction;
                        }

                    case BottomBar.ControlType.Part:
                        return partAction;
                    case BottomBar.ControlType.Pattern:
                        return controlObj.hasOwnProperty("path") && controlObj.path.length > 0 ? clipSettingsAction : patternAction;
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
                        visible: root.controlType === BottomBar.ControlType.Song
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: partAction
                        text: qsTr("Clip")
                        page: Qt.resolvedUrl("PartBar.qml")
                        preload: true
                        visible: root.controlType === BottomBar.ControlType.Part
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: recordingAction
                        text: qsTr("Audio")
                        page: Qt.resolvedUrl("RecordingBar.qml")
                        preload: true
                        visible: (root.controlType === BottomBar.ControlType.Clip || root.controlType === BottomBar.ControlType.Pattern) && controlObj.recordable && !controlObj.path
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        text: qsTr("Clip Info")
                        page: Qt.resolvedUrl("ClipInfoBar.qml")
                        preload: true
                        visible: (root.controlType === BottomBar.ControlType.Clip || root.controlType === BottomBar.ControlType.Pattern) && controlObj.path !== undefined && controlObj.path.length > 0
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: clipSettingsAction
                        text: qsTr("Clip Settings")
                        page: Qt.resolvedUrl("ClipSettingsBar.qml")
                        preload: true
                        visible: (root.controlType === BottomBar.ControlType.Clip || root.controlType === BottomBar.ControlType.Pattern) && controlObj.path !== undefined && controlObj.path.length > 0
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: waveEditorAction
                        text: qsTr("Wave Editor")
                        page: Qt.resolvedUrl("WaveEditorBar.qml")
                        preload: true
                        visible: (root.controlType === BottomBar.ControlType.Clip || root.controlType === BottomBar.ControlType.Pattern) && controlObj.path !== undefined && controlObj.path.length > 0
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: patternAction
                        text: qsTr("Pattern")
                        page: Qt.resolvedUrl("PatternBar.qml")
                        preload: true
                        visible: root.controlType === BottomBar.ControlType.Pattern
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: channelAction
                        text: qsTr("Channel")
                        page: Qt.resolvedUrl("ChannelBar.qml")
                        preload: true
                        visible: root.controlType === BottomBar.ControlType.Channel
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: channelSoundsAction
                        text: qsTr("Sounds")
                        page: Qt.resolvedUrl("../SessionDashboard/ChannelsViewSoundsBar.qml")
                        preload: true
                        visible: root.controlType === BottomBar.ControlType.Channel
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: sampleSoundsAction
                        text: qsTr("Samples")
                        page: Qt.resolvedUrl("SamplesBar.qml")
                        preload: true
                        visible: root.controlType === BottomBar.ControlType.Channel
                        initialProperties: {"bottomBar": root}
                    },
                    // Duplicate tab instance but for different placement and controlObj for channel
                    Zynthian.TabbedControlViewAction {
                        id: channelclipSettingsAction

                        property QtObject clip: root.controlObj && root.controlObj.samples ? root.controlObj.samples[root.controlObj.selectedSlotRow] : null

                        text: qsTr("Smp. Settings")
                        page: Qt.resolvedUrl("ClipSettingsBar.qml")
                        visible: root.controlType === BottomBar.ControlType.Channel &&
                                 clip && clip.path && clip.path.length > 0
                        initialProperties: {"bottomBar": root}
                    },
                    // Duplicate tab instance but for different placement and controlObj for channel
                    Zynthian.TabbedControlViewAction {
                        id: channelWaveEditorAction

                        property QtObject clip: root.controlObj && root.controlObj.samples ? root.controlObj.samples[root.controlObj.selectedSlotRow] : null

                        text: qsTr("Wave Editor")
                        page: Qt.resolvedUrl("WaveEditorBar.qml")
                        visible: root.controlType === BottomBar.ControlType.Channel &&
                                 clip && clip.path && clip.path.length > 0
                        initialProperties: {"bottomBar": root}
                    }
                   /* Zynthian.TabbedControlViewAction {
                        text: qsTr("FX")
                        page: Qt.resolvedUrl("FXBar.qml")
                        visible: root.controlType === BottomBar.ControlType.Channel
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

        headerText: qsTr("%1 : Pick an audio file").arg(root.controlObj ? root.controlObj.channelName : "")
        rootFolder: "/zynthian/zynthian-my-data"
        folderModel {
            nameFilters: ["*.wav"]
        }
        onFileSelected: {
            root.controlObj.path = file.filePath
        }
    }
}
