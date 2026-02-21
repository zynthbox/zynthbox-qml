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
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls.Styles 1.4
import org.kde.plasma.core 2.0 as PlasmaCore

import io.zynthbox.components 1.0 as Zynthbox

import io.zynthbox.ui 1.0 as ZUI

AbstractSketchpadPage {
    id: root

    selectedChannel: applicationWindow().selectedChannel
    
    function cuiaCallback(cuia) {
        switch (cuia) {
        case "SWITCH_BACK_RELEASED":
            bottomStack.setView(Main.BarView.TracksBar);
            return true

        case "SWITCH_SELECT_RELEASED":
            zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
            zynqtgui.bottomBarControlObj = zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId);
            bottomStack.setView(Main.BarView.BottomBar)
            zynqtgui.sketchpad.lastSelectedObj.setTo("MixerBar_item", root.selectedChannel.id, mixerItemsRepeater.itemAt(root.selectedChannel.id), root.selectedChannel)

            return true;

        case "SWITCH_ARROW_LEFT_RELEASED":
            if (zynqtgui.sketchpad.selectedTrackId > 0) {
                zynqtgui.sketchpad.selectedTrackId -= 1;
            }

            return true;

        case "SWITCH_ARROW_RIGHT_RELEASED":
            if (zynqtgui.sketchpad.selectedTrackId < 9) {
                zynqtgui.sketchpad.selectedTrackId += 1;
            }

            return true;
        case "KNOB0_TOUCHED":
        case "KNOB1_TOUCHED":
            // Eat these two events to stop the OSD from showing up
            return true;
        case "KNOB0_UP":
            switch(zynqtgui.sketchpad.lastSelectedObj.className) {
            case "MixerBar_item":
                applicationWindow().updateChannelVolume(1, zynqtgui.sketchpad.lastSelectedObj.value, false)
                return true;
            case "MixerBar_master":
                applicationWindow().updateMasterVolume(1, false)
                return true;
            default:
                return false;
            }
        case "KNOB0_DOWN":
            switch(zynqtgui.sketchpad.lastSelectedObj.className) {
            case "MixerBar_item":
                applicationWindow().updateChannelVolume(-1, zynqtgui.sketchpad.lastSelectedObj.value, false)
                return true;
            case "MixerBar_master":
                applicationWindow().updateMasterVolume(-1, false)
                return true;
            default:
                return false;
            }
        case "KNOB1_UP":
            switch(zynqtgui.sketchpad.lastSelectedObj.className) {
            case "MixerBar_item":
                root.sketchpadView.updateChannelPan(1, zynqtgui.sketchpad.lastSelectedObj.value)
                return true;
            case "MixerBar_master":
                applicationWindow().updateGlobalPlaybackPan(1);
                return true;
            default:
                return false;
            }
        case "KNOB1_DOWN":
            switch(zynqtgui.sketchpad.lastSelectedObj.className) {
            case "MixerBar_item":
                root.sketchpadView.updateChannelPan(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                return true;
            case "MixerBar_master":
                applicationWindow().updateGlobalPlaybackPan(-1);
                return true;
            default:
                return false;
            }
        }
        return false;
    }

    enum View {
        Main,
        Reverb,
        Delay,
        EQ,
        Comp
    }  

    contentItem: ZUI.ThreeColumnView {
        altTabs: false
        leftTab: ZUI.SectionGroup {
            ColumnLayout {
                anchors.fill: parent
                spacing: ZUI.Theme.spacing

                ZUI.SectionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: Kirigami.Units.gridUnit
                    text: "Main"
                    checked: highlighted
                    highlighted: _mixerBarStack.currentView === MixerBar.View.Main
                    onClicked: _mixerBarStack.setView(MixerBar.View.Main)                
                }

                ZUI.SectionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: Kirigami.Units.gridUnit
                    text: "Reverb"
                    checked: highlighted
                    highlighted: _mixerBarStack.currentView === MixerBar.View.Reverb
                    onClicked: _mixerBarStack.setView(MixerBar.View.Reverb)  
                }

                ZUI.SectionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: Kirigami.Units.gridUnit
                    text: "Delay"
                    checked: highlighted
                    highlighted: _mixerBarStack.currentView === MixerBar.View.Delay
                    onClicked: _mixerBarStack.setView(MixerBar.View.Delay)  
                }

                ZUI.SectionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: Kirigami.Units.gridUnit
                    text: "EQ"
                    checked: highlighted
                    highlighted: _mixerBarStack.currentView === MixerBar.View.EQ
                    onClicked: _mixerBarStack.setView(MixerBar.View.EQ)  
                }

                ZUI.SectionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: Kirigami.Units.gridUnit
                    text: "Comp"
                    checked: highlighted
                    highlighted: _mixerBarStack.currentView === MixerBar.View.Comp
                    onClicked: _mixerBarStack.setView(MixerBar.View.Comp)  
                }
            }
        }

        middleTab: StackLayout {
            id: _mixerBarStack
            property int currentView: MixerBar.View.Main
            currentIndex : currentView

            function setView(view) {
                _mixerBarStack.currentView = view
                _mixerBarStack.currentIndex = _mixerBarStack.currentView
            }

            ZUI.SectionGroup {

                fallbackBackground: Rectangle {
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                    color: Kirigami.Theme.backgroundColor
                    opacity: 0.1
                }  
                
                RowLayout {
                    id: channelsVolumeRow
                    function handleClick(channel) {
                        zynqtgui.sketchpad.selectedTrackId = channel.id;
                        zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                        zynqtgui.bottomBarControlObj = zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId);
                        zynqtgui.sketchpad.lastSelectedObj.setTo("MixerBar_item", channel.id, mixerItemsRepeater.itemAt(channel.id), channel);
                    }

                    anchors.fill: parent
                    spacing: ZUI.Theme.cellSpacing

                    Repeater {
                        id: mixerItemsRepeater
                        model: root.song.channelsModel

                        delegate: MixerDelegateControl {
                            id: mixerColumnDelegate
                            highlighted: index === zynqtgui.sketchpad.selectedTrackId
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            control: channelsVolumeRow
                            controller: model
                            text2: qsTr("%1 dB").arg(model.channel.gainHandler.gainDb.toFixed(2))

                            volumeControl: VolumeControl {
                                id: volumeControl
                                // Disable when muted or channel is not being played in solo mode
                                enabled: (zynqtgui.sketchpad.song.playChannelSolo === -1 && !model.channel.muted) || zynqtgui.sketchpad.song.playChannelSolo === model.channel.id
                                inputAudioLeveldB: visible && !model.channel.muted ? Zynthbox.AudioLevels.channels[model.channel.id] : -40
                                value: model.channel.gainHandler.gainDb 
                                inputAudioLevelVisible: true

                                onValueChanged: model.channel.gainHandler.gainDb = slider.value
                                
                                slider {
                                    from: model.channel.gainHandler.minimumDecibel
                                    to: model.channel.gainHandler.maximumDecibel
                                }

                                onClicked: channelsVolumeRow.handleClick(channel)                                
                                onDoubleClicked: model.channel.gainHandler.gainDb = model.channel.initialVolume                                
                            }

                            panControl: PanSlider {
                                orientation: Qt.Horizontal
                                from: -1.0
                                to: 1.0
                                controlObj: model.channel
                                controlProp: "pan"
                                initialValue: model.channel.initialPan
                                onClicked: channelsVolumeRow.handleClick(channel)                                
                            }

                            ZUI.SectionGroup {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                                Layout.margins: 2

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: ZUI.Theme.spacing

                                    QQC2.RoundButton {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: (parent.width-parent.spacing)/2
                                        radius: 2
                                        font.pointSize: 8
                                        checked: root.song.playChannelSolo === model.channel.id
                                        text: qsTr("S")
                                        contentItem: QQC2.Label {
                                            text: parent.text
                                            font: parent.font
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        background: Rectangle {
                                            radius: parent.radius
                                            border.width: 1
                                            border.color: Qt.rgba(50, 50, 50, 0.1)
                                            color: parent.down || parent.checked ? Kirigami.Theme.positiveBackgroundColor : Qt.lighter(Kirigami.Theme.backgroundColor, 1.3)
                                        }
                                        onClicked: {
                                            if (root.song.playChannelSolo == model.channel.id) {
                                                root.song.playChannelSolo = -1
                                            } else {
                                                root.song.playChannelSolo = model.channel.id
                                            }
                                        }
                                    }
                                    QQC2.RoundButton {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: (parent.width-parent.spacing)/2
                                        radius: 2
                                        font.pointSize: 8
                                        checked: model.channel.muted
                                        text: qsTr("M")
                                        contentItem: QQC2.Label {
                                            text: parent.text
                                            font: parent.font
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        background: Rectangle {
                                            radius: parent.radius
                                            border.width: 1
                                            border.color: Qt.rgba(50, 50, 50, 0.1)
                                            color: parent.down || parent.checked ? Kirigami.Theme.negativeBackgroundColor : Qt.lighter(Kirigami.Theme.backgroundColor, 1.3)
                                        }
                                        onClicked: model.channel.muted = !model.channel.muted                                        
                                    }
                                }
                            }
                        }
                    }
                }
                
            }

            ZUI.SectionGroup {
                fallbackBackground: Rectangle {
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                    color: Kirigami.Theme.backgroundColor
                    opacity: 0.1
                }  
                
                RowLayout {
                    id: channelsReverbRow
                    function handleClick(channel) { //TODO
                        // zynqtgui.sketchpad.selectedTrackId = channel.id;
                        // zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                        // zynqtgui.bottomBarControlObj = zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId);
                        // zynqtgui.sketchpad.lastSelectedObj.setTo("MixerBar_item", channel.id, mixerItemsRepeater.itemAt(channel.id), channel);
                    }

                    anchors.fill: parent
                    spacing: ZUI.Theme.cellSpacing

                    Repeater {
                        model: root.song.channelsModel

                        delegate: MixerDelegateControl {
                            highlighted: index === zynqtgui.sketchpad.selectedTrackId
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            control: channelsReverbRow
                            controller: model
                            text2: controller.channel.wetFx2Amount.toFixed(0)+"%"
                            volumeControl: VolumeControl {
                                id: reverbControl
                                // Disable when muted or channel is not being played in solo mode
                                enabled: (zynqtgui.sketchpad.song.playChannelSolo === -1 && !model.channel.muted) || zynqtgui.sketchpad.song.playChannelSolo === model.channel.id
                                value: controller.channel.wetFx2Amount
                                onValueChanged: controller.channel.wetFx2Amount = slider.value
                                
                                slider {
                                    from: 0
                                    to: 100
                                    stepSize: 1
                                }

                                onClicked: channelsReverbRow.handleClick(channel)
                                onDoubleClicked: controller.channel.wetFx1Amount = 50                                
                                tickLabelSet : ({"0":"0%", "50":"50%", "100":"100%"})
                                
                            }
                            panControl: null
                        }
                    }
                }
            }

             ZUI.SectionGroup {
                fallbackBackground: Rectangle {
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                    color: Kirigami.Theme.backgroundColor
                    opacity: 0.1
                }  
                
                RowLayout {
                    id: channelsDelayRow
                    function handleClick(channel) { //TODO
                        // zynqtgui.sketchpad.selectedTrackId = channel.id;
                        // zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                        // zynqtgui.bottomBarControlObj = zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId);
                        // zynqtgui.sketchpad.lastSelectedObj.setTo("MixerBar_item", channel.id, mixerItemsRepeater.itemAt(channel.id), channel);
                    }

                    anchors.fill: parent
                    spacing: ZUI.Theme.cellSpacing

                    Repeater {
                        model: root.song.channelsModel

                        delegate: MixerDelegateControl {
                            highlighted: index === zynqtgui.sketchpad.selectedTrackId
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            control: channelsDelayRow
                            controller: model
                            text2: controller.channel.wetFx1Amount.toFixed(0)+"%"
                            volumeControl: VolumeControl {
                                id: reverbControl
                                value: controller.channel.wetFx1Amount
                                // Disable when muted or channel is not being played in solo mode
                                enabled: (zynqtgui.sketchpad.song.playChannelSolo === -1 && !model.channel.muted) || zynqtgui.sketchpad.song.playChannelSolo === model.channel.id
                                tickLabelSet : ({"0":"0%", "50":"50%", "100":"100%"})
                                onValueChanged: controller.channel.wetFx1Amount = slider.value
                                
                                slider {
                                    from: 0
                                    to: 100
                                }

                                onClicked: channelsDelayRow.handleClick(channel)
                                onDoubleClicked: controller.channel.wetFx1Amount = 50     
                            }
                            panControl: null
                        }
                    }
                }
            }

            Item {}
            Item {}
            Item {}
        }

        rightTab: ZUI.SectionGroup {
                id: masterControl
                property bool highlighted : false
                
                ZUI.CellControl {
                    anchors.fill: parent

                    contentItem: Item {
                        MouseArea {
                            anchors.fill: parent
                            onPressed: masterVolume.mouseArea.handlePressed(mouse)
                            onReleased: masterVolume.mouseArea.released(mouse)
                            onPressAndHold: masterVolume.mouseArea.pressAndHold(mouse)
                            onClicked: masterVolume.mouseArea.clicked(mouse)
                            onMouseXChanged: masterVolume.mouseArea.mouseXChanged(mouse)
                            onMouseYChanged: masterVolume.mouseArea.mouseYChanged(mouse)
                        }
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Kirigami.Units.smallSpacing

                            VolumeControl {
                                id: masterVolume
                                property QtObject gainHandler: Zynthbox.Plugin.globalPlaybackClient.dryGainHandler

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                inputAudioLeveldB: visible ? Zynthbox.AudioLevels.playback :  -40
                                inputAudioLevelVisible: true
                                enabled: !gainHandler.muted

                                Binding {
                                    target: masterVolume.slider
                                    property: "value"
                                    value: masterVolume.gainHandler.gainDb
                                }

                                slider {
                                    value: masterVolume.gainHandler.gainDb
                                    from: masterVolume.gainHandler.minimumDecibel
                                    to: masterVolume.gainHandler.maximumDecibel
                                }
                                onValueChanged: {
                                    masterVolume.gainHandler.gainDb = masterVolume.slider.value;
                                    zynqtgui.sketchpad.song.volume = masterVolume.slider.value;
                                }
                                onClicked: {
                                    zynqtgui.sketchpad.lastSelectedObj.setTo("MixerBar_master", -1, masterControl.contentItem, null)
                                }
                                onDoubleClicked: {
                                    masterVolume.gainHandler.gainDb = zynqtgui.initialMasterVolume
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit
                                Layout.leftMargin: Kirigami.Units.smallSpacing
                                Layout.rightMargin: Kirigami.Units.smallSpacing
                                // color: "pink"
                                PanSlider {
                                    anchors.fill: parent
                                    orientation: Qt.Horizontal
                                    from: -1.0
                                    to: 1.0
                                    controlObj: Zynthbox.Plugin.globalPlaybackClient
                                    controlProp: "panAmount"
                                    initialValue: 0
                                }
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignCenter
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.margins: 4
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: "Master"

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        zynqtgui.sketchpad.lastSelectedObj.setTo("MixerBar_master", -1, masterControl.contentItem, null)
                                    }
                                }
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignCenter
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: qsTr("%1 dB").arg(masterVolume.gainHandler.gainDb.toFixed(2))
                                font.pointSize: 9

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        zynqtgui.sketchpad.lastSelectedObj.setTo("MixerBar_master", -1, masterControl.contentItem, null)
                                    }
                                }
                            }

                            ZUI.SectionGroup {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                                Layout.margins: 2

                                QQC2.RoundButton {   
                                    anchors.fill: parent                                
                                    radius: 2
                                    font.pointSize: 8
                                    checked: masterVolume.gainHandler.muted
                                    text: qsTr("M")
                                    contentItem: QQC2.Label {
                                        text: parent.text
                                        font: parent.font
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    background: Rectangle {
                                        radius: parent.radius
                                        border.width: 1
                                        border.color: Qt.rgba(50, 50, 50, 0.1)
                                        color: parent.down || parent.checked ? Kirigami.Theme.negativeBackgroundColor : Qt.lighter(Kirigami.Theme.backgroundColor, 1.3)
                                    }
                                    onClicked: {
                                        masterVolume.gainHandler.muted = !masterVolume.gainHandler.muted
                                    }
                                }
                            }
                        }
                    }
                }
        }    
    }

    component PanSlider : ZUI.ResetableSlider {

        id: panSlider
        implicitHeight: Kirigami.Units.gridUnit

        background: Item {
            
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Button
            Rectangle{   
                id:_bg             
                anchors.fill: parent
                color: Kirigami.Theme.backgroundColor
                border.color: Qt.darker(Kirigami.Theme.backgroundColor, 3)
                radius: ZUI.Theme.radius

                Rectangle {
                    visible: panSlider.value !== 0
                    color: Kirigami.Theme.highlightColor
                    radius: ZUI.Theme.radius 

                    anchors {
                        left: (panSlider.value > 0 ? parent.horizontalCenter : undefined)
                        right: (panSlider.value <= 0 ? parent.horizontalCenter : undefined)
                        top: parent.top
                        bottom: parent.bottom
                        margins: 2
                    }
                    width: Math.abs(panSlider.value) * (Math.floor(_bg.width / 2) - 2)
                }

                Rectangle {
                    color: Kirigami.Theme.textColor
                    height: 6
                    width: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item {
                height: 16
                width: 16
                anchors.top: parent.bottom
                x: (parent.width * panSlider.position) - width/2

                Kirigami.Icon {
                    anchors.verticalCenter: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitHeight: 16
                    implicitWidth: 16
                    source: Qt.resolvedUrl("../../../img/arrow-up.svg")
                    color: Kirigami.Theme.textColor
                }
            }    
        }
    }

    component MixerDelegateControl: ZUI.CellControl {
        id: mixerColumnDelegate
        property Item control : null
        property var controller : null 

        default property alias content: _layout.data
        property alias text2 : _label2.text

        property VolumeControl volumeControl: VolumeControl {}
        property PanSlider panControl: null

        contentItem: Item {
            ColumnLayout {
                id: _layout
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    MouseArea {
                        anchors.fill: parent
                        onPressed: volumeControl.mouseArea.handlePressed(mouse)
                        onReleased: volumeControl.mouseArea.released(mouse)
                        onPressAndHold: volumeControl.mouseArea.pressAndHold(mouse)
                        onClicked: volumeControl.mouseArea.clicked(mouse)
                        onMouseXChanged: volumeControl.mouseArea.mouseXChanged(mouse)
                        onMouseYChanged: volumeControl.mouseArea.mouseYChanged(mouse)
                    }

                    StackLayout {
                        anchors.fill: parent
                        data: mixerColumnDelegate.volumeControl
                    }

                    Item {                       
                        width: volumeControl.slider.height
                        height: soundLabel.height*1.5

                        anchors.left: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: -soundLabel.height*2
                        anchors.bottomMargin: -(soundLabel.height/2)

                        transform: Rotation {
                            origin.x: 0
                            origin.y: 0
                            angle: -90
                        }

                        QQC2.Label {
                            id: soundLabel

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: mixerColumnDelegate.text

                            font.pointSize: 8

                            Timer {
                                id: soundnameUpdater;
                                repeat: false; running: false; interval: 1;
                                onTriggered: soundLabel.updateSoundName();
                            }
                            Component.onCompleted: soundLabel.updateSoundName();
                            Connections {
                                target: zynqtgui.fixed_layers
                                onList_updated: soundnameUpdater.restart();
                            }

                            Connections {
                                target: controller.channel
                                onChainedSoundsChanged: controller.channel.trackType === "synth" ? soundnameUpdater.restart() : false
                                onSamplesChanged: controller.channel.trackType === "synth" ? soundnameUpdater.restart() : false
                                onTrackTypeChanged: soundnameUpdater.restart()
                                onSceneClipChanged: controller.channel.trackType === "sample-loop" ? soundnameUpdater.restart() : false
                                onSelectedSlotRowChanged: ["synth", "external"].indexOf(controller.channel.trackType) >= 0 ? soundnameUpdater.restart() : false
                            }

                            Connections {
                                target: controller.channel.sceneClip
                                onPathChanged: controller.channel.trackType === "sample-loop" ? soundnameUpdater.restart() : false
                            }
                            Connections {
                                target: root
                                onVisibleChanged: root.visible ? soundLabel.updateSoundName() : false
                            }

                            function updateSoundName() {
                                if (root.visible) {
                                    var text = "";

                                    if (controller.channel.trackType === "synth") {
                                        for (var id in controller.channel.chainedSounds) {
                                            if (controller.channel.chainedSounds[id] >= 0 &&
                                                    controller.channel.checkIfLayerExists(controller.channel.chainedSounds[id])) {
                                                var soundName = zynqtgui.fixed_layers.selector_list.getDisplayValue(controller.channel.chainedSounds[id]).split(">");
                                                text = qsTr("%1").arg(soundName[1] ? soundName[1].trim() : "")
                                                break;
                                            }
                                        }
                                        if (text === "") {
                                            try {
                                                text = controller.channel.samples[controller.channel.selectedSlotRow].path.split("/").pop()
                                            } catch (e) {}
                                        }
                                    } else if (controller.channel.trackType === "sample-loop") {
                                        try {
                                            text = controller.channel.sceneClip.path.split("/").pop()
                                        } catch (e) {}
                                    }

                                    soundLabel.text = text;
                                }
                            }
                        }
                    }
                }

                StackLayout {
                    visible: mixerColumnDelegate.panControl
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: visible ? Kirigami.Units.gridUnit : 0
                    Layout.leftMargin: visible ? Kirigami.Units.smallSpacing : 0
                    Layout.rightMargin: visible ? Kirigami.Units.smallSpacing : 0
                    data: mixerColumnDelegate.panControl
                }

                QQC2.Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.margins: 4
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: controller.channel.name

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            mixerColumnDelegate.control.handleClick(controller.channel);
                        }
                    }
                }

                QQC2.Label {
                    id: _label2
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.pointSize: 9

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            mixerColumnDelegate.control.handleClick(channel);
                        }
                    }
                }
            }
        }
    }
}
