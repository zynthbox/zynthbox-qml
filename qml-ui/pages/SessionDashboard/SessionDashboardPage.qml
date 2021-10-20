/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Session Dashboard page for Zynthian GUI

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
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

Zynthian.ScreenPage {
    id: root
    title: zynthian.control.selector_path_element

    property int itemHeight: layersView.height / 15
    backAction: null
    contextualActions: [
        Kirigami.Action {
            enabled: false
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
    Timer {
        interval: 10 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        function pad(d) {
            return (d < 10) ? '0' + d.toString() : d.toString();
        }
        onTriggered: {
            let d = new Date();
            clockLabel.text = d.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit' });
            let sessionSecs = zynthian.session_dashboard.get_session_time()
            let sessionMins = Math.floor(sessionSecs / 60);
            let sessionHours = Math.floor(sessionMins / 60);
            sessionMins = sessionMins % 60;
            sessionTimeLabel.text = pad(sessionHours) + ":" + pad(sessionMins);
        }
    }
    ColumnLayout {
        anchors {
            fill: parent
            topMargin: -Kirigami.Units.smallSpacing
        }
        spacing: Kirigami.Units.largeSpacing
        RowLayout {
            QQC2.Label {
                Layout.alignment: Qt.AlignCenter
                text: "Session time:"
            }
            Kirigami.Heading {
                id: sessionTimeLabel
                Layout.alignment: Qt.AlignCenter
            }
            Item {
                Layout.fillWidth: true
            }
            Kirigami.Heading {
                id: clockLabel
                Layout.alignment: Qt.AlignCenter
            }
        }

        RowLayout {
            spacing: 0
            ColumnLayout {
                spacing: 0
                Layout.preferredWidth: parent.width / 10
                Layout.maximumWidth: parent.width / 10
                Kirigami.Heading {
                    level: 2
                    text: zynthian.session_dashboard.name
                    MouseArea {
                        anchors.fill: parent
                        onClicked: zynthian.current_modal_screen_id = "sketch_copier"
                    }
                }
                QQC2.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    ListView {
                        model: zynthian.session_dashboard.sessionSketchesModel
                        header: QQC2.Control {
                            width: parent.width
                            height: root.itemHeight
                            contentItem: RowLayout {
                                QQC2.Label {
                                    text: "1. " + zynthian.zynthiloops.song.name
                                }
                            }
                            background: Rectangle {
                                color: Kirigami.Theme.highlightColor
                            }
                        }
                        delegate: QQC2.Control {
                            width: parent.width
                            height: root.itemHeight
                            contentItem: RowLayout {
                                QQC2.Label {
                                    text: (model.slot + 2) + ". " + (model.sketch ? model.sketch.name : " - ")
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.preferredWidth: parent.width / 10
                Layout.maximumWidth: parent.width / 10
            }

            ColumnLayout {
                Layout.preferredWidth: parent.width / 10
                Layout.maximumWidth: parent.width / 10
                spacing: 0
                Kirigami.Heading {
                    level: 2
                    text: qsTr("Scenes")
                    MouseArea {
                        anchors.fill: parent
                        onClicked: zynthian.current_modal_screen_id = "sketch_copier"
                    }
                }
                QQC2.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    ListView {
                        id: scenesView
                        model: zynthian.zynthiloops.song.scenesModel
                        delegate: Kirigami.AbstractListItem {
                            separatorVisible: false
                            width: scenesView.width
                            height: root.itemHeight
                            highlighted: index === zynthian.zynthiloops.song.scenesModel.selectedSceneIndex
                            contentItem: QQC2.Label {
                                text: model.scene.name
                            }
                            onClicked: zynthian.zynthiloops.song.scenesModel.selectedSceneIndex = index
                        }
                    }
                }
            }

            Item {
                Layout.preferredWidth: parent.width / 10
                Layout.maximumWidth: parent.width / 10
            }

            ColumnLayout {
                id: tracksLayout
                Layout.preferredWidth: parent.width / 10
                Layout.maximumWidth: parent.width / 10
                spacing: 0
                Kirigami.Heading {
                    level: 2
                    text: qsTr("Tracks")
                    MouseArea {
                        anchors.fill: parent
                        onClicked: zynthian.current_modal_screen_id = "zynthiloops"
                    }
                }

                Repeater {
                    model: zynthian.zynthiloops.song.tracksModel
                    delegate: DashboardListItem {
                        width: parent.width
                        patternConnections: index < 7 ? trackSoundConnections : trackPatternConnections
                        secondColumn: index < 7 ? layersView.contentItem : patternsLayout
                        Layout.preferredHeight: root.itemHeight
                        contentItem: RowLayout {
                            id: delegate
                            property QtObject track: model.track
                            QQC2.Label {
                                text: (index+1) + "." + (visibleChildren.length > 1 ? model.display : "")
                            }
                            Repeater { //HACK
                                model: delegate.track.clipsModel
                                QQC2.Label {
                                    text: model.display
                                    visible: model.clip.path.length > 0
                                    Rectangle {
                                        anchors {
                                            fill: parent
                                            margins: -Kirigami.Units.smallSpacing
                                        }
                                        z: -1
                                        color: Kirigami.Theme.highlightColor
                                        visible: model.clip.inCurrentScene
                                    }
                                }
                            }
                        }
                    }
                }
                Item {
                    Layout.fillHeight: true
                }
            }

            ColumnLayout {
                Layout.preferredWidth: parent.width / 10
                Layout.maximumWidth: parent.width / 10
                Layout.fillHeight: true
                spacing: 0
                Item {
                    Layout.fillHeight: true
                }
                PatternConnections {
                    id: trackPatternConnections
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    connections:[
                        [tracksLayout.children[8].dragManager, patternsLayout.children[0]],
                        [tracksLayout.children[9].dragManager, patternsLayout.children[1]],
                        [tracksLayout.children[10].dragManager, patternsLayout.children[2]],
                        [tracksLayout.children[11].dragManager, patternsLayout.children[3]],
                        [tracksLayout.children[12].dragManager, patternsLayout.children[6]],
                    ]
                }
            }

            ColumnLayout {
                Layout.preferredWidth: parent.width / 10
                Layout.maximumWidth: parent.width / 10
                spacing: 0
                Item {
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1
                }
                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 2
                    text: qsTr("Patterns")
                    MouseArea {
                        anchors.fill: parent
                        onClicked: zynthian.current_modal_screen_id = "playgrid"
                    }
                }

                ColumnLayout {
                    id: patternsLayout
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 8 //FIXME: why is this needed?
                    spacing: 0
                    Repeater {
                        id: patternsViewMainRepeater
                        model: Object.keys(ZynQuick.PlayGridManager.dashboardModels)
                        delegate: Repeater {
                            id: patternsViewPlaygridRepeater
                            model: ZynQuick.PlayGridManager.dashboardModels[modelData]
                            property string playgridId: modelData
                            delegate: DashboardListItem {
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.itemHeight
                                Layout.maximumHeight: root.itemHeight
                                Component.onCompleted: {
                                    print("Pattern layer: "+ model.layer)
                                }
                                property int chan: model.layer
                                onChanChanged: print("Updated Pattern Layer: "+chan)
                                text: patternsViewMainRepeater.count === 1 ? model.text : model.text + " (" + playgridId.split("/").slice(-1)[0] + ")"

                                patternConnections: patternSoundsConnections
                                secondColumn: layersView.contentItem
                                onClicked: {
                                    zynthian.current_modal_screen_id = "playgrid";
                                    var playgridIndex = ZynQuick.PlayGridManager.playgrids.indexOf(playgridId);
                                    //console.log("Attempting to switch to playgrid index " + playgridIndex + " for the playgrid named " + playgridId);
                                    ZynQuick.PlayGridManager.setCurrentPlaygrid("playgrid", playgridIndex);
                                    ZynQuick.PlayGridManager.pickDashboardModelItem(patternsViewPlaygridRepeater.model, index);
                                }
                                onRequestConnect: {
                                    patternsViewPlaygridRepeater.model.setPatternProperty(index, "layer", child.channel)
                                }
                            }
                        }
                    }
                }
            }
            ColumnLayout {
                Layout.preferredWidth: parent.width / 10
                Layout.maximumWidth: parent.width / 10
                Layout.fillHeight: true
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    PatternConnections {
                        id: trackSoundConnections
                        anchors {
                            fill: parent
                            leftMargin: -parent.width * 2
                        }
                    //    Layout.leftMargin: -width
                        connections:[
                            [tracksLayout.children[1].dragManager, layersView.contentItem.children[0]],
                            [tracksLayout.children[2].dragManager, layersView.contentItem.children[1]],
                            [tracksLayout.children[3].dragManager, layersView.contentItem.children[2]],
                            [tracksLayout.children[4].dragManager, layersView.contentItem.children[3]],
                            [tracksLayout.children[5].dragManager, layersView.contentItem.children[4]],
                        ]
                    }
                }
                PatternConnections {
                    id: patternSoundsConnections
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    connections:[
                        [patternsLayout.children[0].dragManager, layersView.contentItem.children[11]],
                        [patternsLayout.children[1].dragManager, layersView.contentItem.children[12]],
                        [patternsLayout.children[2].dragManager, layersView.contentItem.children[13]],
                        [patternsLayout.children[3].dragManager, layersView.contentItem.children[14]],
                        [patternsLayout.children[6].dragManager, layersView.contentItem.children[15]],
                    ]
                }
            }

            ColumnLayout {
                spacing: 0
                Kirigami.Heading {
                    level: 2
                    text: qsTr("Sounds")
                    MouseArea {
                        anchors.fill: parent
                        onClicked: zynthian.current_screen_id = "main_layers_view"
                    }
                }
                QQC2.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    topPadding: 0
                    bottomPadding: 0
                    ListView {
                        id: layersView
                        model: zynthian.fixed_layers.selector_list
                        delegate: Kirigami.AbstractListItem {
                            width: layersView.width
                            height: root.itemHeight
                            highlighted: zynthian.active_midi_channel === index
                            separatorVisible: false
                            readonly property int channel: model.metadata.midi_channel
                            onClicked: {
                                zynthian.current_screen_id = "main_layers_view";
                                zynthian.fixed_layers.activate_index(index);
                            }
                            contentItem: RowLayout {
                                QQC2.Label {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: {
                                        let numPrefix = model.metadata.midi_channel + 1;
                                        if (numPrefix > 5 && numPrefix <= 10) {
                                            numPrefix = "6." + (numPrefix - 5);
                                        }
                                        return numPrefix + ". " + model.display
                                    }
                                }
                                QQC2.Label {
                                    text: {
                                        let text = "";
                                        if (model.metadata.note_high < 60) {
                                            text = "L";
                                        } else if (model.metadata.note_low >= 60) {
                                            text = "H";
                                        }
                                        if (model.metadata.octave_transpose !== 0) {
                                            if (model.metadata.octave_transpose > 0) {
                                                text += "+"
                                            }
                                            text += model.metadata.octave_transpose;
                                        }
                                        return text;
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
