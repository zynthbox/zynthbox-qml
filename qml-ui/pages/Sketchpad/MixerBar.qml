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

    function focusNextElementInChain() {
        zynqtgui.sketchpad.selectedTrackId = ZUI.CommonUtils.clamp(zynqtgui.sketchpad.selectedTrackId + 1, 0, Zynthbox.Plugin.sketchpadTrackCount - 1)

        if(zynqtgui.sketchpad.lastSelectedObj.className.startsWith("MixerBar_item")){
            _mixerBarStack.focusElement()
        }

        if(zynqtgui.sketchpad.lastSelectedObj.className === "sketchpad_channel"){
            root.sketchpadView.focusChannel(zynqtgui.sketchpad.selectedTrackId)
        }
    }

    function focusPreviousElementInChain() {
        zynqtgui.sketchpad.selectedTrackId = ZUI.CommonUtils.clamp(zynqtgui.sketchpad.selectedTrackId - 1, 0, Zynthbox.Plugin.sketchpadTrackCount - 1)
        if(zynqtgui.sketchpad.lastSelectedObj.className.startsWith("MixerBar_item")){
            _mixerBarStack.focusElement()
        }

        if(zynqtgui.sketchpad.lastSelectedObj.className === "sketchpad_channel"){
            root.sketchpadView.focusChannel(zynqtgui.sketchpad.selectedTrackId)
        }
    }
    
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
        case "KNOB3_DOWN":
        case "SWITCH_ARROW_LEFT_RELEASED":
            focusPreviousElementInChain()
            return true;
        case "KNOB3_UP":
        case "SWITCH_ARROW_RIGHT_RELEASED":
            focusNextElementInChain()

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
            case "MixerBar_item_delay":
                applicationWindow().updateChannelDelaySend(1, zynqtgui.sketchpad.lastSelectedObj.value, false)
                return true;
            case "MixerBar_item_reverb":
                applicationWindow().updateChannelReverbSend(1, zynqtgui.sketchpad.lastSelectedObj.value, false)
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
            case "MixerBar_item_delay":
                applicationWindow().updateChannelDelaySend(-1, zynqtgui.sketchpad.lastSelectedObj.value, false)
                return true;
            case "MixerBar_item_reverb":
                applicationWindow().updateChannelReverbSend(-1, zynqtgui.sketchpad.lastSelectedObj.value, false)
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
                    text: "Volume"
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

            function focusElement() {
                let view = _mixerBarStack.children[_mixerBarStack.currentIndex]
                if(view) {
                    view.focusElement()
                }
            }

            ZUI.SectionGroup {

                fallbackBackground: Rectangle {
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                    color: Kirigami.Theme.backgroundColor
                    opacity: 0.1
                }  

                function focusElement(){
                    channelsVolumeRow.handleClick(root.selectedChannel)
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
                            controller: model
                            text2: qsTr("%1 dB").arg(model.channel.gainHandler.gainDb.toFixed(2))
                            onClicked: channelsVolumeRow.handleClick(controller.channel)


                            control1: VolumeControl {
                                id: volumeControl
                                // Disable when muted or channel is not being played in solo mode
                                enabled: (zynqtgui.sketchpad.song.playChannelSolo === -1 && !model.channel.muted) || zynqtgui.sketchpad.song.playChannelSolo === model.channel.id
                                inputAudioLeveldB: visible && !model.channel.muted ? Zynthbox.AudioLevels.channels[model.channel.id] : -40
                                inputAudioLevelVisible: true

                                onValueChanged: model.channel.gainHandler.gainDb = slider.value
                                
                                slider {
                                    from: model.channel.gainHandler.minimumDecibel
                                    to: model.channel.gainHandler.maximumDecibel
                                }

                                Binding {
                                    target: volumeControl.slider
                                    property: "value"
                                    value: model.channel.gainHandler.gainDb 
                                }

                                onClicked: channelsVolumeRow.handleClick(channel)                                
                                onDoubleClicked: model.channel.gainHandler.gainDb = model.channel.initialVolume                                
                            }

                            control2: PanSlider {
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

                function focusElement(){
                    channelsReverbRow.handleClick(root.selectedChannel)
                }
                
                RowLayout {
                    id: channelsReverbRow
                    function handleClick(channel) { 
                        zynqtgui.sketchpad.selectedTrackId = channel.id;
                        zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                        zynqtgui.bottomBarControlObj = zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId);
                        zynqtgui.sketchpad.lastSelectedObj.setTo("MixerBar_item_reverb", channel.id, channelsReverbRowRepeater.itemAt(channel.id), channel);
                    }

                    anchors.fill: parent
                    spacing: ZUI.Theme.cellSpacing

                    Repeater {
                        id: channelsReverbRowRepeater
                        model: root.song.channelsModel

                        delegate: MixerDelegateControl {
                            highlighted: index === zynqtgui.sketchpad.selectedTrackId
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            controller: model
                            text2: controller.channel.wetFx2Amount.toFixed(0)+"%"
                            onClicked: channelsReverbRow.handleClick(controller.channel)
                            control1: VolumeControl {
                                id: reverbControl
                                // Disable when muted or channel is not being played in solo mode
                                enabled: (zynqtgui.sketchpad.song.playChannelSolo === -1 && !model.channel.muted) || zynqtgui.sketchpad.song.playChannelSolo === model.channel.id
                                onValueChanged: controller.channel.wetFx2Amount = slider.value

                                Binding {
                                    target: reverbControl.slider
                                    property: "value"
                                    value: controller.channel.wetFx2Amount
                                }
                                
                                slider {
                                    from: 0
                                    to: 100
                                    stepSize: 1
                                }

                                onClicked: channelsReverbRow.handleClick(channel)
                                onDoubleClicked: controller.channel.wetFx2Amount = 50                                
                                tickLabelSet : ({"0":"0%", "50":"50%", "100":"100%"})                                
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

                function focusElement(){
                    channelsDelayRow.handleClick(root.selectedChannel)
                }
                
                RowLayout {
                    id: channelsDelayRow
                    function handleClick(channel) { 
                        zynqtgui.sketchpad.selectedTrackId = channel.id;
                        zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                        zynqtgui.bottomBarControlObj = zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId);
                        zynqtgui.sketchpad.lastSelectedObj.setTo("MixerBar_item_delay", channel.id, channelsDelayRowRepeater.itemAt(channel.id), channel);
                    }

                    anchors.fill: parent
                    spacing: ZUI.Theme.cellSpacing

                    Repeater {
                        id: channelsDelayRowRepeater
                        model: root.song.channelsModel

                        delegate: MixerDelegateControl {
                            highlighted: index === zynqtgui.sketchpad.selectedTrackId
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            controller: model
                            text2: controller.channel.wetFx1Amount.toFixed(0)+"%"
                            onClicked: channelsDelayRow.handleClick(controller.channel)
                            control1: VolumeControl {
                                id: delayControl
                                // Disable when muted or channel is not being played in solo mode
                                enabled: (zynqtgui.sketchpad.song.playChannelSolo === -1 && !model.channel.muted) || zynqtgui.sketchpad.song.playChannelSolo === model.channel.id
                                tickLabelSet : ({"0":"0%", "50":"50%", "100":"100%"})
                                onValueChanged: controller.channel.wetFx1Amount = slider.value
                                
                                slider {
                                    from: 0
                                    to: 100
                                }

                                Binding {
                                    target: delayControl.slider
                                    property: "value"
                                    value: controller.channel.wetFx1Amount
                                }

                                onClicked: channelsDelayRow.handleClick(channel)
                                onDoubleClicked: controller.channel.wetFx1Amount = 50     
                            }
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
            
            MixerDelegateControl {
                anchors.fill: parent

                title: "Master"
                onClicked: zynqtgui.sketchpad.lastSelectedObj.setTo("MixerBar_master", -1, masterControl.contentItem, null)
                text2: qsTr("%1 dB").arg(masterVolume.gainHandler.gainDb.toFixed(2))
                text: ""

                control1: VolumeControl {
                    id: masterVolume
                    property QtObject gainHandler: Zynthbox.Plugin.globalPlaybackClient.dryGainHandler

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

                control2: PanSlider {
                    orientation: Qt.Horizontal
                    from: -1.0
                    to: 1.0
                    controlObj: Zynthbox.Plugin.globalPlaybackClient
                    controlProp: "panAmount"
                    initialValue: 0
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
                radius: 0

                Rectangle {
                    visible: panSlider.value !== 0
                    color: Kirigami.Theme.textColor 
                    opacity: 0.2
                    radius: parent.radius

                    anchors {
                        left: (panSlider.value > 0 ? parent.horizontalCenter : undefined)
                        right: (panSlider.value <= 0 ? parent.horizontalCenter : undefined)
                        top: parent.top
                        bottom: parent.bottom
                        topMargin: 1
                        bottomMargin: 1
                    }
                    width: Math.abs(panSlider.value) * (Math.floor(_bg.width / 2) - 1)
                }

                Rectangle {
                    color: Kirigami.Theme.textColor
                    visible: panSlider.value == 0
                    opacity: 0.2
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    width: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                }  
            }  
        }
    }

    component MixerDelegateControl: AbstractCellLayout {
        id: mixerColumnDelegate
        property var controller : null 
        title: controller.channel.name
        control1: VolumeControl {}

        underlay: MouseArea {
            anchors.fill: parent
            onPressed: control1.mouseArea.handlePressed(mouse)
            onReleased: control1.mouseArea.released(mouse)
            onPressAndHold: control1.mouseArea.pressAndHold(mouse)
            onClicked: control1.mouseArea.clicked(mouse)
            onMouseXChanged: control1.mouseArea.mouseXChanged(mouse)
            onMouseYChanged: control1.mouseArea.mouseYChanged(mouse)
        }

        Timer {
            id: soundnameUpdater;
            repeat: false; running: false; interval: 1;
            onTriggered: updateSoundName();
        }
        Component.onCompleted: updateSoundName();

        Connections {
            target: zynqtgui.fixed_layers
            onList_updated: soundnameUpdater.restart();
        }

        Loader {
            active: mixerColumnDelegate.controller
            sourceComponent: Item {
                Connections {
                    ignoreUnknownSignals: true
                    target: mixerColumnDelegate.controller.channel
                    onChainedSoundsChanged: mixerColumnDelegate.controller.channel.trackType === "synth" ? soundnameUpdater.restart() : false
                    onSamplesChanged: mixerColumnDelegate.controller.channel.trackType === "synth" ? soundnameUpdater.restart() : false
                    onTrackTypeChanged: soundnameUpdater.restart()
                    onSceneClipChanged: mixerColumnDelegate.controller.channel.trackType === "sample-loop" ? soundnameUpdater.restart() : false
                    onSelectedSlotRowChanged: ["synth", "external"].indexOf(mixerColumnDelegate.controller.channel.trackType) >= 0 ? soundnameUpdater.restart() : false
                }

                Connections {
                    ignoreUnknownSignals: true
                    enabled: mixerColumnDelegate.controller
                    target: mixerColumnDelegate.controller.channel.sceneClip
                    onPathChanged: mixerColumnDelegate.controller.channel.trackType === "sample-loop" ? soundnameUpdater.restart() : false
                }
                Connections {
                    target: root
                    onVisibleChanged: root.visible ? mixerColumnDelegate.updateSoundName() : false
                }
            }
        }

        function updateSoundName() {
            if(!mixerColumnDelegate.controller)
                return;

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

                mixerColumnDelegate.text = text;
            }
        }

    }
}
