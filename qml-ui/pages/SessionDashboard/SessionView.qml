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
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

ColumnLayout {
    id: root

    anchors {
        fill: parent
        topMargin: -Kirigami.Units.smallSpacing
        leftMargin: Kirigami.Units.gridUnit
    }

    property int itemHeight: layersView.height / 15
    spacing: Kirigami.Units.largeSpacing

    RowLayout {
        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
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

        ColumnLayout {
            id: tracksLayout
            Layout.fillWidth: true
            Layout.preferredWidth: 1
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
                    patternConnections: index < 6 ? trackSoundConnections : trackPatternConnections
                    secondColumn: index < 6 ? layersView.contentItem : patternsLayout
                    Layout.preferredHeight: root.itemHeight
                    dragManager.targetMaxY: index < 6 ? patternsLayout.y : layersView.contentItem.height + soundsHeading.height
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

        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            PatternConnections {
                id: trackPatternConnections
                anchors {
					fill: parent
					//topMargin: soundsHeading.height
				}
				leftYOffset: soundsHeading.height
                rightYOffset: patternsLayout.y
                slotHeight: root.itemHeight

                connections:[
                    [6, 0],
                    [7, 1],
                    [8, 2],
                    [9, 3],
                    [10, 4],
                ]
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
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
                            id: delegate
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.itemHeight
                            Layout.maximumHeight: root.itemHeight
                            dragManager.targetMinY: patternsLayout.y
                            Component.onCompleted: {
                                print("Pattern layer: "+ model.layer)
                                for (var i in model) {
                                    print(i+ " _ " + model[i])
                                }
                                for (var i in model.pattern) {
                                    print(i+ " => " + model.pattern[i])
                                }
                                var channel = chan
                                if (channel === 0) {
                                    channel = zynthian.active_midi_channel
                                }
                                patternSoundsConnections.addConnection(index, channel)
                            }
                            property int chan: model.layer
                            onChanChanged: {
                                print("Updated Pattern Layer: " + chan)
                                var channel = chan
                                if (channel === 0) {
                                    channel = zynthian.active_midi_channel
                                }
                                patternSoundsConnections.addConnection(index, channel)
                            }
                            data: [Connections {
                                target: zynthian
                                onActive_midi_channelChanged: {
                                    if (delegate.chan === 0) {
                                        patternSoundsConnections.addConnection(index, zynthian.active_midi_channel);
                                    }
                                }
                            }]
                            contentItem: RowLayout {
                                QQC2.Label {
                                    text: (patternsViewMainRepeater.count === 1 ? model.text : model.text + " (" + playgridId.split("/").slice(-1)[0] + ")")
                                }
                                QQC2.Label {
                                    text: "A"
                                    Rectangle {
                                        anchors {
                                            fill: parent
                                            margins: -Kirigami.Units.smallSpacing
                                        }
                                        z: -1
                                        color: Kirigami.Theme.highlightColor
                                        visible: model.pattern.bankOffset == 0 //TODO: use model.bank
                                    }
                                }
                                QQC2.Label {
                                    text: "B"
                                    Rectangle {
                                        anchors {
                                            fill: parent
                                            margins: -Kirigami.Units.smallSpacing
                                        }
                                        z: -1
                                        color: Kirigami.Theme.highlightColor
                                        visible: model.pattern.bankOffset > 0
                                    }
                                }
                            }

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
                                if (child.channel < 10) {
                                    return;
                                }
                                patternsViewPlaygridRepeater.model.setPatternProperty(index, "layer", child.channel)
                            }
                        }
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true

            PatternConnections {
                id: trackSoundConnections
                anchors {
                    fill: parent
                    topMargin: soundsHeading.height
                    leftMargin: -parent.width * 2
                }
                slotHeight: root.itemHeight
                connections:[
                    [0, 0],
                    [1, 1],
                    [2, 2],
                    [3, 3],
                    [4, 4],
                ]
            }

            PatternConnections {
                id: patternSoundsConnections
                leftYOffset: patternsLayout.y
                rightYOffset: soundsHeading.height
                slotHeight: root.itemHeight
                anchors {
					fill: parent
					//topMargin: soundsHeading.height
				}
            }
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            Layout.preferredWidth: 2
            Kirigami.Heading {
				id: soundsHeading
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
                        topPadding: 0
                        bottomPadding: 0
                        property int row: index
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
