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
                    onClicked: zynqtgui.current_modal_screen_id = "sketchpad_copier"
                }
            }
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                ListView {
                    id: scenesView
                    model: zynqtgui.sketchpad.song.scenesModel
                    delegate: Kirigami.AbstractListItem {
                        separatorVisible: false
                        width: scenesView.width
                        height: root.itemHeight
                        highlighted: index === zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex
                        contentItem: QQC2.Label {
                            text: model.scene.name
                        }
                        onClicked: zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex = index
                    }
                }
            }
        }

        ColumnLayout {
            id: channelsLayout
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            spacing: 0
            Kirigami.Heading {
                level: 2
                text: qsTr("Channels")
                MouseArea {
                    anchors.fill: parent
                    onClicked: zynqtgui.current_modal_screen_id = "sketchpad"
                }
            }

            Repeater {
                model: zynqtgui.sketchpad.song.channelsModel
                delegate: DashboardListItem {
                    width: parent.width
                    patternConnections: index < 6 ? channelSoundConnections : channelPatternConnections
                    secondColumn: index < 6 ? layersLayout : patternsLayout
                    Layout.preferredHeight: root.itemHeight
                    //dragManager.targetMinY: -550
                    dragManager.targetMaxY: index < 6 ? patternsLayout.y - soundsHeading.height  : layersLayout.height + soundsHeading.height //FIXME: random magic numbers
                    contentItem: RowLayout {
                        id: delegate
                        property QtObject channel: model.channel
                        QQC2.Label {
                            text: (index+1) + "." + (visibleChildren.length > 1 ? model.display : "")
                        }
                        Repeater { //HACK
                            model: delegate.channel.clipsModel
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
                    Component.onCompleted: {
                        for (var i in model) {
                            print(i+ " _ " + model[i])
                        }
                        for (var i in model.channel) {
                            print(i+ " => " + model.channel[i])
                        }
                        if (index < 6 && model.channel.connectedSound >= 0) {
                            channelSoundConnections.addConnection(index, model.channel.connectedSound);
                        }
                        if (index >= 6 && model.channel.connectedPattern >= 0) {
                            channelPatternConnections.addConnection(index, model.channel.connectedPattern);
                        }
                    }
                    onRequestConnect: {
                        if (index < 6) {
                            if (child) {
                                model.channel.connectedSound = child.row;
                            } else {
                                model.channel.connectedSound = -1;
                            }
                        } else {
                            if (child) {
                                model.channel.connectedPattern = child.row;
                            } else {
                                model.channel.connectedPattern = -1;
                            }
                        }
                    }
                    data: [Connections {
                        target: model.channel
                        onConnectedSoundChanged: {
                            if (model.channel.connectedSound >= 0) {
                                channelSoundConnections.addConnection(index, model.channel.connectedSound);
                            } else {
                                channelSoundConnections.removeConnection(index)
                            }
                        }
                    }]
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
                id: channelPatternConnections
                anchors {
                    fill: parent
                    //topMargin: soundsHeading.height
                }
                leftYOffset: soundsHeading.height
                rightYOffset: patternsLayout.y
                slotHeight: root.itemHeight

                connections:[
                    /*[6, 0],
                    [7, 1],
                    [8, 2],
                    [9, 3],
                    [10, 4],*/
                ]
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            spacing: 0
            Item {
                Layout.fillHeight: true
                Layout.preferredHeight: parent.height / 2
            }
            Kirigami.Heading {
                Layout.fillWidth: true
                level: 2
                text: qsTr("Patterns")
                MouseArea {
                    anchors.fill: parent
                    onClicked: zynqtgui.current_modal_screen_id = "playgrid"
                }
            }

            ColumnLayout {
                id: patternsLayout
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 8 //FIXME: why is this needed?
                spacing: 0
                onHeightChanged: {
                    patternSoundsConnections.requestPaint();
                    channelPatternConnections.requestPaint();
                }
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
                                    channel = zynqtgui.active_midi_channel
                                }
                                patternSoundsConnections.addConnection(index, channel)
                            }
                            property int chan: model.layer
                            onChanChanged: {
                                print("Updated Pattern Layer: " + chan)
                                var channel = chan
                                if (channel === 0) {
                                    channel = zynqtgui.active_midi_channel
                                }
                                patternSoundsConnections.addConnection(index, channel)
                            }
                            data: [Connections {
                                target: zynqtgui
                                onActive_midi_channelChanged: {
                                    if (delegate.chan === 0) {
                                        patternSoundsConnections.addConnection(index, zynqtgui.active_midi_channel);
                                    }
                                }
                            }]
                            contentItem: RowLayout {
                                QQC2.Label {
                                    text: ((index + 1) + ". ") + (patternsViewMainRepeater.count === 1 ? model.text : model.text + " (" + playgridId.split("/").slice(-1)[0] + ")")
                                }
                                QQC2.Label {
                                    text: "I"
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
                                    text: "II"
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
                            secondColumn: layersLayout
                            onClicked: {
                                zynqtgui.current_modal_screen_id = "playgrid";
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
                id: channelSoundConnections
                anchors {
                    fill: parent
                    //topMargin: soundsHeading.height
                    leftMargin: -parent.width * 2
                }
                leftYOffset: soundsHeading.height
                rightYOffset: soundsHeading.height - layersView.contentY
                slotHeight: root.itemHeight
            }

            PatternConnections {
                id: patternSoundsConnections
                leftYOffset: patternsLayout.y
                rightYOffset: soundsHeading.height - layersView.contentY
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
                    onClicked: zynqtgui.current_screen_id = "main_layers_view"
                }
            }
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                topPadding: 0
                bottomPadding: 0
                Flickable {
                    id: layersView
                    contentWidth: width
                    contentHeight: layersLayout.height
                    clip: true
                    ColumnLayout {
                        id: layersLayout
                        width: parent.width
                        spacing: 0
                        Repeater {
                            model: zynqtgui.fixed_layers.selector_list
                            delegate: Kirigami.AbstractListItem {
                                width: layersLayout.width
                                implicitHeight: root.itemHeight
                                highlighted: zynqtgui.active_midi_channel === index
                                separatorVisible: false
                                topPadding: 0
                                bottomPadding: 0
                                property int row: index
                                readonly property int channel: model.metadata.midi_channel
                                onClicked: {
                                    //zynqtgui.current_screen_id = "main_layers_view";
                                    zynqtgui.fixed_layers.activate_index(index);
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
}
