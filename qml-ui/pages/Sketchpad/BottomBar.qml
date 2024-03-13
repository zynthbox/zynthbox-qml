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
import io.zynthbox.components 1.0 as Zynthbox

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
            zynqtgui.bottomBarControlType = "bottombar-controltype-song"
        } else if (type === "clip") {
            zynqtgui.bottomBarControlType = "bottombar-controltype-clip"
        } else if (type === "channel") {
            zynqtgui.bottomBarControlType = "bottombar-controltype-channel"
        } else if (type === "part") {
            zynqtgui.bottomBarControlType = "bottombar-controltype-part"
        } else if (type === "pattern") {
            zynqtgui.bottomBarControlType = "bottombar-controltype-pattern"
        }

        zynqtgui.bottomBarControlObj = obj
    }

    Connections {
        target: zynqtgui
        onBottomBarControlObjChanged: {
            if (zynqtgui.bottomBarControlType === "bottombar-controltype-pattern") {
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
                visible: zynqtgui.bottomBarControlType !== "bottombar-controltype-channel"

                EditableHeader {
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    controlObj: zynqtgui.bottomBarControlObj
                    controlType: zynqtgui.bottomBarControlType
                    text: {
                        let text = zynqtgui.bottomBarControlObj ? zynqtgui.bottomBarControlObj.name : "";
                        switch (zynqtgui.bottomBarControlType) {
                        case "bottombar-controltype-song":
                            return qsTr("Folder: %1  SKETCHPAD: %2").arg(zynqtgui.bottomBarControlObj.sketchpadFolderName).arg(text);
                        case "bottombar-controltype-clip":
                        case "bottombar-controltype-pattern":
                            return qsTr("CLIP: %1").arg(text);
                        case "bottombar-controltype-channel":
                            return qsTr("TRACK: %1").arg(text);
                        case "bottombar-controltype-part":
                            return qsTr("PART: %1").arg(text);
    //                    case "bottombar-controltype-pattern":
    //                        var sequence = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName)
    //                        var pattern = sequence.getByPart(zynqtgui.bottomBarControlObj.clipChannel.connectedPattern, 0)
    //                        return qsTr("PATTERN: %1").arg(pattern.objectName)
                        default:
                            return text;
                        }
                    }
                }


                Item {
                    Layout.fillWidth: true
                    visible: !(zynqtgui.bottomBarControlType === "bottombar-controltype-clip" || zynqtgui.bottomBarControlType === "bottombar-controltype-pattern")
                }

                QQC2.Label {
                    visible: zynqtgui.bottomBarControlType === "bottombar-controltype-clip" || zynqtgui.bottomBarControlType === "bottombar-controltype-pattern"
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                    horizontalAlignment: Text.AlignRight
                    text: zynqtgui.bottomBarControlObj && zynqtgui.bottomBarControlObj.path
                            ? qsTr("Sample (0): %1").arg(zynqtgui.bottomBarControlObj.path.split('/').pop())
                            : qsTr("No File Loaded")
                }

                SidebarButton {
                    icon.name: "document-save-symbolic"
                    active: zynqtgui.bottomBarControlType === "bottombar-controltype-clip" || zynqtgui.bottomBarControlType === "bottombar-controltype-pattern"
                             && !zynqtgui.bottomBarControlObj.isEmpty

                    onClicked: {
                        zynqtgui.bottomBarControlObj.saveMetadata();
                    }
                }

                SidebarButton {
                    icon.name: "document-open"
                    active: zynqtgui.bottomBarControlType === "bottombar-controltype-clip" || zynqtgui.bottomBarControlType === "bottombar-controltype-pattern"
                    enabled: zynqtgui.bottomBarControlObj ? !zynqtgui.bottomBarControlObj.isPlaying : false

                    onClicked: {
                        pickerDialog.folderModel.folder = zynqtgui.bottomBarControlObj.recordingDir;
                        pickerDialog.open();
                    }
                }

                SidebarButton {
                    icon.name: "delete"
                    active: (zynqtgui.bottomBarControlObj != null) && zynqtgui.bottomBarControlObj.deletable

                    onClicked: {
                        zynqtgui.bottomBarControlObj.delete();
                    }
                }

                SidebarButton {
                    icon.name: "edit-clear-all"
                    active: (zynqtgui.bottomBarControlObj != null) && zynqtgui.bottomBarControlObj.clearable
                    enabled: zynqtgui.bottomBarControlObj ? !zynqtgui.bottomBarControlObj.isPlaying : false

                    onClicked: {
                        zynqtgui.bottomBarControlObj.clear()
                    }
                }

                SidebarButton {
                    icon.name: "user-trash-symbolic"
                    active: zynqtgui.bottomBarControlObj != null && !zynqtgui.bottomBarControlObj.isEmpty

                    onClicked: {
                        zynqtgui.bottomBarControlObj.deleteClip()
                    }
                }

                SidebarButton {
                    icon.name: zynqtgui.bottomBarControlObj && zynqtgui.bottomBarControlObj.isPlaying ? "media-playback-stop" : "media-playback-start"
                    active: zynqtgui.bottomBarControlType !== "bottombar-controltype-part" &&
                             (zynqtgui.bottomBarControlObj != null) && zynqtgui.bottomBarControlObj.playable && zynqtgui.bottomBarControlObj.path

                    onClicked: {
                        if (zynqtgui.bottomBarControlObj.isPlaying) {
                            console.log("Stopping Sound Loop")
                            zynqtgui.bottomBarControlObj.stop();
                        } else {
                            console.log("Playing Sound Loop")
                            zynqtgui.bottomBarControlObj.play();
                        }
                    }
                }

                SidebarButton {
                    icon.name: "media-playback-start"
                    active: zynqtgui.bottomBarControlType === "bottombar-controltype-part" &&
                             (zynqtgui.bottomBarControlObj != null) && zynqtgui.bottomBarControlObj.playable

                    onClicked: {
                        console.log("Starting Part")
                        zynqtgui.bottomBarControlObj.play();
                    }
                }

                SidebarButton {
                    icon.name: "media-playback-stop"
                    active: zynqtgui.bottomBarControlType === "bottombar-controltype-part" &&
                             (zynqtgui.bottomBarControlObj != null) && zynqtgui.bottomBarControlObj.playable

                    onClicked: {
                        console.log("Stopping Part")
                        zynqtgui.bottomBarControlObj.stop();
                    }
                }
            }


            Zynthian.TabbedControlView {
                id: tabbedView
                Layout.fillWidth: true
                Layout.fillHeight: true
                minimumTabsCount: 4
                orientation: Qt.Vertical
                visibleFocusRects: false

                initialHeaderItem: EditableHeader {
                    id: tabbedViewHeader
                    implicitWidth: Kirigami.Units.gridUnit * 10
                    visible: zynqtgui.bottomBarControlType === "bottombar-controltype-channel"
                    controlObj: zynqtgui.bottomBarControlObj
                    controlType: zynqtgui.bottomBarControlType
                    Binding {
                        target: tabbedViewHeader
                        property: "text"
                        delayed: true
                        value: {
                            let text = zynqtgui.bottomBarControlObj ? zynqtgui.bottomBarControlObj.name : "";
                            switch (zynqtgui.bottomBarControlType) {
                            case "bottombar-controltype-song":
                                return qsTr("Folder: %1  SKETCHPAD: %2").arg(zynqtgui.bottomBarControlObj.sketchpadFolderName).arg(text);
                            case "bottombar-controltype-clip":
                            case "bottombar-controltype-pattern":
                                return qsTr("CLIP: %1").arg(text);
                            case "bottombar-controltype-channel":
                                return qsTr("TRACK: %1").arg(text);
                            case "bottombar-controltype-part":
                                return qsTr("PART: %1").arg(text);
    //                        case "bottombar-controltype-pattern":
    //                            return qsTr("PATTERN: %1").arg(zynqtgui.bottomBarControlObj.col+1);
                            default:
                                return text;
                            }
                        }
                    }
                }
//                finalHeaderItem: RowLayout {
//                    Layout.fillWidth: true
//                    visible: zynqtgui.bottomBarControlType === "bottombar-controltype-channel"
//                    QQC2.Button {
//                        visible: zynqtgui.bottomBarControlObj && zynqtgui.bottomBarControlObj.connectedPattern < 0
//                        Layout.fillHeight: true

//                        text: qsTr("Midi")
//                        //enabled: !channelDelegate.hasWavLoaded && !channelDelegate.channelHasConnectedPattern

//                        onClicked: {
//                            zynqtgui.session_dashboard.midiSelectionRequested();
//                        }
//                    }
//                }

                initialAction: {
                    switch (zynqtgui.bottomBarControlType) {
                    case "bottombar-controltype-song":
                        return songAction;
                    case "bottombar-controltype-clip":
                        return !zynqtgui.bottomBarControlObj.isEmpty ? clipSettingsAction : recordingAction;
                    case "bottombar-controltype-channel":
                        if (zynqtgui.bottomBarControlObj.channelAudioType === "synth")
                            return channelSoundsAction;
                        else {
                            return sampleSoundsAction;
                        }

                    case "bottombar-controltype-part":
                        return partAction;
                    case "bottombar-controltype-pattern":
                        return !zynqtgui.bottomBarControlObj.isEmpty ? clipSettingsAction : patternAction;
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
                        visible: zynqtgui.bottomBarControlType === "bottombar-controltype-song"
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: partAction
                        text: qsTr("Clip")
                        page: Qt.resolvedUrl("PartBar.qml")
                        preload: true
                        visible: zynqtgui.bottomBarControlType === "bottombar-controltype-part"
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: recordingAction
                        text: qsTr("Audio")
                        page: Qt.resolvedUrl("RecordingBar.qml")
                        preload: true
                        visible: (zynqtgui.bottomBarControlType === "bottombar-controltype-clip" || zynqtgui.bottomBarControlType === "bottombar-controltype-pattern") && zynqtgui.bottomBarControlObj.recordable && !zynqtgui.bottomBarControlObj.path
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        text: qsTr("Clip Info")
                        page: Qt.resolvedUrl("ClipInfoBar.qml")
                        preload: true
                        visible: (zynqtgui.bottomBarControlType === "bottombar-controltype-clip" || zynqtgui.bottomBarControlType === "bottombar-controltype-pattern") && !zynqtgui.bottomBarControlObj.isEmpty
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: clipSettingsAction
                        text: qsTr("Clip Settings")
                        page: Qt.resolvedUrl("ClipSettingsBar.qml")
                        preload: true
                        visible: (zynqtgui.bottomBarControlType === "bottombar-controltype-clip" || zynqtgui.bottomBarControlType === "bottombar-controltype-pattern") && !zynqtgui.bottomBarControlObj.isEmpty
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: sampleADSREditorAction
                        text: qsTr("ADSR")
                        page: Qt.resolvedUrl("SampleADSREditor.qml")
                        preload: true
                        visible: (zynqtgui.bottomBarControlType === "bottombar-controltype-clip" || zynqtgui.bottomBarControlType === "bottombar-controltype-pattern") && !zynqtgui.bottomBarControlObj.isEmpty
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: waveEditorAction
                        text: qsTr("Wave Editor")
                        page: Qt.resolvedUrl("WaveEditorBar.qml")
                        preload: true
                        visible: (zynqtgui.bottomBarControlType === "bottombar-controltype-clip" || zynqtgui.bottomBarControlType === "bottombar-controltype-pattern") && !zynqtgui.bottomBarControlObj.isEmpty
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: patternAction
                        text: qsTr("Pattern")
                        page: Qt.resolvedUrl("PatternBar.qml")
                        preload: true
                        visible: zynqtgui.bottomBarControlType === "bottombar-controltype-pattern"
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: channelAction
                        text: qsTr("Track")
                        page: Qt.resolvedUrl("ChannelBar.qml")
                        preload: true
                        visible: zynqtgui.bottomBarControlType === "bottombar-controltype-channel"
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: channelSoundsAction
                        text: qsTr("Sounds")
                        page: Qt.resolvedUrl("../SessionDashboard/ChannelsViewSoundsBar.qml")
                        preload: true
                        visible: zynqtgui.bottomBarControlType === "bottombar-controltype-channel"
                        initialProperties: {"bottomBar": root}
                    },
                    Zynthian.TabbedControlViewAction {
                        id: sampleSoundsAction
                        text: qsTr("Samples")
                        page: Qt.resolvedUrl("SamplesBar.qml")
                        preload: true
                        visible: zynqtgui.bottomBarControlType === "bottombar-controltype-channel"
                        initialProperties: {"bottomBar": root}
                    },
                    // Duplicate tab instance but for different placement and zynqtgui.bottomBarControlObj for channel
                    Zynthian.TabbedControlViewAction {
                        id: channelSampleADSREditorAction

                        property QtObject clip: zynqtgui.bottomBarControlObj && zynqtgui.bottomBarControlObj.samples ? zynqtgui.bottomBarControlObj.samples[zynqtgui.bottomBarControlObj.selectedSlotRow] : null

                        text: qsTr("ADSR")
                        page: Qt.resolvedUrl("SampleADSREditor.qml")
                        visible: zynqtgui.bottomBarControlType === "bottombar-controltype-channel" && clip && !clip.isEmpty
                        initialProperties: {"bottomBar": root}
                    },
                    // Duplicate tab instance but for different placement and zynqtgui.bottomBarControlObj for channel
                    Zynthian.TabbedControlViewAction {
                        id: channelclipSettingsAction

                        property QtObject clip: zynqtgui.bottomBarControlObj && zynqtgui.bottomBarControlObj.samples ? zynqtgui.bottomBarControlObj.samples[zynqtgui.bottomBarControlObj.selectedSlotRow] : null

                        text: qsTr("Smp. Settings")
                        page: Qt.resolvedUrl("ClipSettingsBar.qml")
                        visible: zynqtgui.bottomBarControlType === "bottombar-controltype-channel" && clip && !clip.isEmpty
                        initialProperties: {"bottomBar": root}
                    },
                    // Duplicate tab instance but for different placement and zynqtgui.bottomBarControlObj for channel
                    Zynthian.TabbedControlViewAction {
                        id: channelWaveEditorAction

                        property QtObject clip: zynqtgui.bottomBarControlObj && zynqtgui.bottomBarControlObj.samples ? zynqtgui.bottomBarControlObj.samples[zynqtgui.bottomBarControlObj.selectedSlotRow] : null

                        text: qsTr("Wave Editor")
                        page: Qt.resolvedUrl("WaveEditorBar.qml")
                        visible: zynqtgui.bottomBarControlType === "bottombar-controltype-channel" && clip && !clip.isEmpty
                        initialProperties: {"bottomBar": root}
                    }
                   /* Zynthian.TabbedControlViewAction {
                        text: qsTr("FX")
                        page: Qt.resolvedUrl("FXBar.qml")
                        visible: zynqtgui.bottomBarControlType === "bottombar-controltype-channel"
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

        headerText: qsTr("%1 : Pick an audio file").arg(zynqtgui.bottomBarControlObj ? zynqtgui.bottomBarControlObj.channelName : "")
        rootFolder: "/zynthian/zynthian-my-data"
        folderModel {
            nameFilters: ["*.wav"]
        }
        onFileSelected: {
            zynqtgui.bottomBarControlObj.path = file.filePath
        }
    }
}
