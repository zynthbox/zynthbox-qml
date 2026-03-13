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
            case "MixerBar_item_hicut":
                if(_EQStack.showQ){
                    if(_EQStack.applyToAll)
                        applicationWindow().updateAllChannelEQHiCutQuality(1, zynqtgui.sketchpad.lastSelectedObj.value)
                    else
                        applicationWindow().updateChannelEQHiCutQuality(1, zynqtgui.sketchpad.lastSelectedObj.value)
                }else{
                    if(_EQStack.applyToAll)
                        applicationWindow().updateAllChannelEQHiCut(1, zynqtgui.sketchpad.lastSelectedObj.value)
                    else
                        applicationWindow().updateChannelEQHiCut(1, zynqtgui.sketchpad.lastSelectedObj.value)
                }
                return true;
            case "MixerBar_item_lowcut":
                if(_EQStack.showQ){
                    if(_EQStack.applyToAll)
                        applicationWindow().updateAllChannelEQLowCutQuality(1, zynqtgui.sketchpad.lastSelectedObj.value)
                    else
                        applicationWindow().updateChannelEQLowCutQuality(1, zynqtgui.sketchpad.lastSelectedObj.value)
                }else{
                    if(_EQStack.applyToAll)
                        applicationWindow().updateAllChannelEQLowCut(1, zynqtgui.sketchpad.lastSelectedObj.value)
                    else
                        applicationWindow().updateChannelEQLowCut(1, zynqtgui.sketchpad.lastSelectedObj.value)
                }
                return true;
            case "MixerBar_item_threshold":
                applicationWindow().updateAllChannelCompThreshold(1, zynqtgui.sketchpad.lastSelectedObj.value)
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
            case "MixerBar_item_hicut":
                if(_EQStack.showQ){
                    if(_EQStack.applyToAll)
                        applicationWindow().updateAllChannelEQHiCutQuality(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                    else
                        applicationWindow().updateChannelEQHiCutQuality(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                }else{
                    if(_EQStack.applyToAll)
                        applicationWindow().updateAllChannelEQHiCut(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                    else
                        applicationWindow().updateChannelEQHiCut(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                }
                return true;
            case "MixerBar_item_lowcut":
                if(_EQStack.showQ){
                    if(_EQStack.applyToAll)
                        applicationWindow().updateAllChannelEQLowCutQuality(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                    else
                        applicationWindow().updateChannelEQLowCutQuality(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                }else{
                    if(_EQStack.applyToAll)
                        applicationWindow().updateAllChannelEQLowCut(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                    else
                        applicationWindow().updateChannelEQLowCut(-1, zynqtgui.sketchpad.lastSelectedObj.value)
                }
                return true;
            case "MixerBar_item_threshold":
                applicationWindow().updateAllChannelCompThreshold(-1, zynqtgui.sketchpad.lastSelectedObj.value)
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

    enum EQView {
        HiCut,
        LowCut
    }

    enum CompView {
        Threshold
    }

    readonly property alias currentView : _mixerBarStack.currentView
    function setView(view) {
        root.sketchpadView.bottomStack.setView(Main.BarView.MixerBar)
        _mixerBarStack.setView(view)
    }

    contentItem: ZUI.ThreeColumnView {
        altTabs: false
        // leftTab: ZUI.SectionGroup {
        //     ColumnLayout {
        //         anchors.fill: parent
        //         spacing: ZUI.Theme.spacing

        //         ZUI.SectionButton {
        //             Layout.fillWidth: true
        //             Layout.fillHeight: true
        //             implicitHeight: Kirigami.Units.gridUnit
        //             text: "Volume"
        //             checked: highlighted
        //             highlighted: _mixerBarStack.currentView === MixerBar.View.Main
        //             onClicked: _mixerBarStack.setView(MixerBar.View.Main)                
        //         }

        //         ZUI.SectionButton {
        //             Layout.fillWidth: true
        //             Layout.fillHeight: true
        //             implicitHeight: Kirigami.Units.gridUnit
        //             text: "Reverb"
        //             checked: highlighted
        //             highlighted: _mixerBarStack.currentView === MixerBar.View.Reverb
        //             onClicked: _mixerBarStack.setView(MixerBar.View.Reverb)  
        //         }

        //         ZUI.SectionButton {
        //             Layout.fillWidth: true
        //             Layout.fillHeight: true
        //             implicitHeight: Kirigami.Units.gridUnit
        //             text: "Delay"
        //             checked: highlighted
        //             highlighted: _mixerBarStack.currentView === MixerBar.View.Delay
        //             onClicked: _mixerBarStack.setView(MixerBar.View.Delay)  
        //         }

        //         ZUI.SectionButton {
        //             Layout.fillWidth: true
        //             Layout.fillHeight: true
        //             implicitHeight: Kirigami.Units.gridUnit
        //             text: "EQ"
        //             checked: highlighted
        //             highlighted: _mixerBarStack.currentView === MixerBar.View.EQ
        //             onClicked: _mixerBarStack.setView(MixerBar.View.EQ)  
        //         }

        //         ZUI.SectionButton {
        //             Layout.fillWidth: true
        //             Layout.fillHeight: true
        //             implicitHeight: Kirigami.Units.gridUnit
        //             text: "Comp"
        //             checked: highlighted
        //             highlighted: _mixerBarStack.currentView === MixerBar.View.Comp
        //             onClicked: _mixerBarStack.setView(MixerBar.View.Comp)  
        //         }
        //     }
        // }

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

            ColumnLayout {
                spacing: ZUI.Theme.sectionSpacing
                enabled: root.selectedChannel.trackType !== "external"

                function focusElement(){
                    _EQStack.children[_EQStack.currentIndex].focusElement()
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit *  2
                    Layout.minimumHeight: Kirigami.Units.gridUnit *  2
                    
                    RowLayout {
                        anchors.fill: parent
                        spacing: ZUI.Theme.spacing

                        ZUI.SectionGroup {
                            Layout.fillHeight: true

                            QQC2.ButtonGroup {
                                buttons: _EQButtonsRow.children
                            }

                            RowLayout {
                                id: _EQButtonsRow
                                anchors.fill: parent
                                spacing: ZUI.Theme.spacing

                                ZUI.SectionButton {
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                    text: "HiCut"
                                    checked: highlighted
                                    highlighted: _EQStack.currentView === MixerBar.EQView.HiCut
                                    onClicked: _EQStack.setView(MixerBar.EQView.HiCut)
                                }
                                ZUI.SectionButton {
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                    text: "LowCut"
                                    checked: highlighted
                                    highlighted: _EQStack.currentView === MixerBar.EQView.LowCut
                                    onClicked: _EQStack.setView(MixerBar.EQView.LowCut)
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        ZUI.SectionGroup {
                            Layout.fillHeight: true

                            RowLayout {
                                anchors.fill: parent
                                spacing: ZUI.Theme.spacing

                                ZUI.SectionButton {
                                    checkable: true
                                    checked: _EQStack.applyToAll
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                    text: "All"
                                    onToggled: _EQStack.applyToAll = checked
                                }

                                ZUI.SectionButton {
                                    checkable: true
                                    checked: _EQStack.showQ
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                    text: "Q"
                                    onToggled: _EQStack.showQ = checked
                                }
                            }
                        }
                    }
                }

                ZUI.SectionGroup {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    fallbackBackground: Rectangle {
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                        color: Kirigami.Theme.backgroundColor
                        opacity: 0.1
                    } 

                    StackLayout {
                        id: _EQStack
                        visible: enabled
                        anchors.fill: parent
                        property int currentView: MixerBar.EQView.HiCut
                        currentIndex : currentView

                        property bool applyToAll: false
                        property bool showQ: false

                        function setView(view) {
                            _EQStack.currentView = view
                            _EQStack.currentIndex = _EQStack.currentView

                            _EQStack.children[_EQStack.currentIndex].focusElement()
                        }

                        RowLayout {
                            id: _EQHiCutRow
                            spacing: ZUI.Theme.cellSpacing
                            property double globalHiCutValue: 0
                            property double globalHiCutQ: 0

                            function focusElement() {
                                handleClick(root.selectedChannel.id)
                            }
                            
                            function handleClick(channel) { 
                                zynqtgui.sketchpad.selectedTrackId = channel;
                                zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                zynqtgui.sketchpad.lastSelectedObj.setTo("MixerBar_item_hicut", channel, _hicutRepeater.itemAt(channel),  root.selectedChannel);
                            }

                            Repeater {
                                id: _hicutRepeater
                                model: Zynthbox.Plugin.sketchpadTrackCount
                                delegate: ZUI.CellControl {
                                    id: _hicutDelegate 
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    enabled: eq !== null
                                    highlighted: (index === root.selectedChannel.id || _EQStack.applyToAll) && enabled
                                    property QtObject ctrl : Zynthbox.AudioLevels.tracks[index]
                                    property QtObject eq: ctrl ? ctrl.equaliserSettings[5] : null
                                    
                                    //[5] is hicut and [0] is lowcut and for the menu [11] highcut(lowpass) and [1] lowcut(high pass)     

                                    Connections {
                                        target: _EQHiCutRow
                                        onGlobalHiCutValueChanged: {
                                            if(_hicutDelegate.enabled){
                                                _hicutDelegate.eq.frequencyAbsolute = _EQHiCutRow.globalHiCutValue
                                            }
                                        }

                                        onGlobalHiCutQChanged: {
                                            if(_hicutDelegate.enabled){
                                                _hicutDelegate.eq.quality = _EQHiCutRow.globalHiCutQ
                                            }
                                        }
                                    }                               

                                    contentItem: StackLayout {

                                        currentIndex: _EQStack.showQ ? 1 : 0

                                        AbstractCellLayout {
                                            text2: _hicutDelegate.eq
                                                  ?  (_hicutDelegate.eq.frequency < 1000.0 || zynqtgui.modeButtonPressed)
                                                    ? "%1 Hz".arg(_hicutDelegate.eq.frequency.toFixed(1))
                                                    : "%1 kHz".arg((_hicutDelegate.eq.frequency / 1000.0).toFixed(2))
                                            : ""
                                            enabled: _hicutDelegate.eq 
                                            text: root.selectedChannel.synthSlotsData[index]
                                            title: enabled ? _hicutDelegate.eq.name : "-"
                                            onClicked: _EQHiCutRow.handleClick(index)

                                            ZUI.SectionGroup {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                                                Layout.margins: 2

                                                RowLayout {
                                                    anchors.fill: parent
                                                    spacing: ZUI.Theme.spacing
                                                    
                                                    QQC2.RoundButton {
                                                        text: "S"
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        checked: _hicutDelegate.eq ? _hicutDelegate.eq.soloed : false
                                                        font.pointSize: 8
                                                        radius: 2
                                                        onClicked: {
                                                            _hicutDelegate.eq.soloed =!_hicutDelegate.eq.soloed;
                                                        }
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
                                                    }

                                                    QQC2.RoundButton{
                                                        text: "A"
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        checked: _hicutDelegate.eq? _hicutDelegate.eq.active : false
                                                        font.pointSize: 8
                                                        radius: 2
                                                        onClicked: {
                                                            _hicutDelegate.eq.active = !_hicutDelegate.eq.active;
                                                        }
                                                        contentItem: QQC2.Label {
                                                            text: parent.text
                                                            font: parent.font
                                                            horizontalAlignment: Text.AlignHCenter
                                                        }
                                                        background: Rectangle {
                                                            radius: parent.radius
                                                            border.width: 1
                                                            border.color: Qt.rgba(50, 50, 50, 0.1)
                                                            color: parent.down || parent.checked ? Kirigami.Theme.highlightColor : Qt.lighter(Kirigami.Theme.backgroundColor, 1.3)
                                                        }                                                        
                                                    }
                                                }
                                            }

                                            control1: VolumeControl {
                                                id: volumeControl
                                                tickLabelSet : ({"0":"20Hz", "50":"650Hz", "100":"20kHz"})
                                                slider {
                                                    stepSize: 1
                                                    from: 0
                                                    to: 100
                                                }

                                                Binding {
                                                    target: volumeControl.slider
                                                    property: "value"
                                                    value: _hicutDelegate.eq  ? _hicutDelegate.eq.frequencyAbsolute*100 : 0
                                                }

                                                onValueChanged: {
                                                    if (_hicutDelegate.eq) {
                                                        if(_EQStack.applyToAll) {
                                                            _EQHiCutRow.globalHiCutValue = slider.value/100
                                                        }else{
                                                            _hicutDelegate.eq.frequencyAbsolute = slider.value/100
                                                        }
                                                    }
                                                }
                                                onClicked: _EQHiCutRow.handleClick(index)


                                            }
                                            underlay: MouseArea {
                                                anchors.fill: parent
                                                onPressed: volumeControl.mouseArea.handlePressed(mouse)                                                
                                                onReleased: volumeControl.mouseArea.released(mouse)
                                                onPressAndHold: volumeControl.mouseArea.pressAndHold(mouse)
                                                onClicked: volumeControl.mouseArea.clicked(mouse)
                                                onMouseXChanged: volumeControl.mouseArea.mouseXChanged(mouse)
                                                onMouseYChanged: volumeControl.mouseArea.mouseYChanged(mouse)
                                            }
                                        }

                                        AbstractCellLayout {
                                            title: "Q"
                                            enabled:  _hicutDelegate.eq 
                                            text: root.selectedChannel.synthSlotsData[index]
                                            text2: _hicutDelegate.eq ? _hicutDelegate.eq.quality.toFixed(2): "-"

                                            control1: VolumeControl {
                                                id: volumeControl2
                                                tickLabelSet : ({"0":"0", "5":"5", "10":"10"})  
                                                slider {
                                                    from: 0
                                                    to: 10
                                                    stepSize: 0.1
                                                    value: _hicutDelegate.eq ? _hicutDelegate.eq.quality : 0
                                                }
                                                onValueChanged: {
                                                    if (_hicutDelegate.eq) {
                                                        if(_EQStack.applyToAll) {
                                                            _EQHiCutRow.globalHiCutQ = slider.value
                                                        }else{
                                                            _hicutDelegate.eq.quality = slider.value
                                                        }
                                                    }
                                                }
                                                onClicked: _EQHiCutRow.handleClick(index)
                                            }
                                            underlay: MouseArea {
                                                anchors.fill: parent
                                                onPressed: volumeControl2.mouseArea.handlePressed(mouse)                                                
                                                onReleased: volumeControl2.mouseArea.released(mouse)
                                                onPressAndHold: volumeControl2.mouseArea.pressAndHold(mouse)
                                                onClicked: volumeControl2.mouseArea.clicked(mouse)
                                                onMouseXChanged: volumeControl2.mouseArea.mouseXChanged(mouse)
                                                onMouseYChanged: volumeControl2.mouseArea.mouseYChanged(mouse)
                                            }
                                        }
                                    }

                                    // enabled: root.selectedChannel.synthSlotsData[index].length > 0
                                    // onClicked: _SYNFilterResoRow.handleClick(index)
                                }
                            }
                        }
                        
                        RowLayout {
                            id: _EQLowCutRow
                            spacing: ZUI.Theme.cellSpacing
                            property double globalLowCutValue: 0
                            property double globalLowCutQ: 0

                            function focusElement() {
                                handleClick(root.selectedChannel.id)
                            }
                            
                            function handleClick(channel) { 
                                zynqtgui.sketchpad.selectedTrackId = channel;
                                zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                zynqtgui.sketchpad.lastSelectedObj.setTo("MixerBar_item_lowcut", channel, _lowcutRepeater.itemAt(channel),  root.selectedChannel);
                            }

                            Repeater {
                                id: _lowcutRepeater
                                model: Zynthbox.Plugin.sketchpadTrackCount
                                delegate: ZUI.CellControl {
                                    id: _lowcutDelegate 

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    highlighted: (index === root.selectedChannel.id || _EQStack.applyToAll) && enabled
                                    property QtObject ctrl : Zynthbox.AudioLevels.tracks[index]
                                    property QtObject eq: ctrl ? ctrl.equaliserSettings[0] : null
                                    
                                    //[5] is hicut and [0] is lowcut and for the menu [11] highcut(lowpass) and [1] lowcut(high pass)

                                    Connections {
                                        target: _EQLowCutRow
                                        onGlobalLowCutValueChanged: {
                                            if(_lowcutDelegate.enabled){
                                                _lowcutDelegate.eq.frequencyAbsolute = _EQLowCutRow.globalLowCutValue
                                            }
                                        }

                                        onGlobalLowCutQChanged: {
                                            if(_lowcutDelegate.enabled){
                                                _lowcutDelegate.eq.quality = _EQLowCutRow.globalLowCutQ
                                            }
                                        }
                                    }   
                                    
                                    contentItem: StackLayout {

                                        currentIndex: _EQStack.showQ ? 1 : 0

                                        AbstractCellLayout {
                                            text2: _lowcutDelegate.eq
                                                  ?  (_lowcutDelegate.eq.frequency < 1000.0 || zynqtgui.modeButtonPressed)
                                                    ? "%1 Hz".arg(_lowcutDelegate.eq.frequency.toFixed(1))
                                                    : "%1 kHz".arg((_lowcutDelegate.eq.frequency / 1000.0).toFixed(2))
                                            : ""
                                            enabled: _lowcutDelegate.eq 
                                            text: root.selectedChannel.synthSlotsData[index]
                                            title: enabled ? _lowcutDelegate.eq.name : "-"

                                            ZUI.SectionGroup {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                                                Layout.margins: 2

                                                RowLayout {
                                                    anchors.fill: parent
                                                    spacing: ZUI.Theme.spacing
                                                    QQC2.RoundButton {
                                                        text: "S"
                                                        font.pointSize: 8
                                                        radius: 2
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        checked: _lowcutDelegate.eq ? _lowcutDelegate.eq.soloed : false
                                                        onClicked: {
                                                            _lowcutDelegate.eq.soloed =!_lowcutDelegate.eq.soloed;
                                                        }
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
                                                    }

                                                    QQC2.RoundButton {
                                                        text: "A"
                                                        font.pointSize: 8
                                                        radius: 2
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        checked: _lowcutDelegate.eq? _lowcutDelegate.eq.active : false
                                                        onClicked: {
                                                            _lowcutDelegate.eq.active = !_lowcutDelegate.eq.active;
                                                        }

                                                        contentItem: QQC2.Label {
                                                            text: parent.text
                                                            font: parent.font
                                                            horizontalAlignment: Text.AlignHCenter
                                                        }
                                                        background: Rectangle {
                                                            radius: parent.radius
                                                            border.width: 1
                                                            border.color: Qt.rgba(50, 50, 50, 0.1)
                                                            color: parent.down || parent.checked ? Kirigami.Theme.highlightColor : Qt.lighter(Kirigami.Theme.backgroundColor, 1.3)
                                                        }
                                                    }
                                                }
                                            }

                                            control1: VolumeControl {
                                                id: volumeControl
                                                tickLabelSet : ({"0":"20Hz", "50":"650Hz", "100":"20kHz"})
                                                slider {
                                                    stepSize: 1
                                                    from: 0
                                                    to: 100
                                                }

                                                Binding {
                                                    target: volumeControl.slider
                                                    property: "value"
                                                    value: _lowcutDelegate.eq  ? _lowcutDelegate.eq.frequencyAbsolute*100 : 0
                                                }

                                                onValueChanged: {
                                                    if (_lowcutDelegate.eq) {
                                                        if(_EQStack.applyToAll) {
                                                            _EQLowCutRow.globalLowCutValue = slider.value/100
                                                        }else{
                                                            _lowcutDelegate.eq.frequencyAbsolute = slider.value/100
                                                        }
                                                    }
                                                }
                                                onClicked: _EQLowCutRow.handleClick(index)
                                            }
                                            underlay: MouseArea {
                                                anchors.fill: parent
                                                onPressed: volumeControl.mouseArea.handlePressed(mouse)                                                
                                                onReleased: volumeControl.mouseArea.released(mouse)
                                                onPressAndHold: volumeControl.mouseArea.pressAndHold(mouse)
                                                onClicked: volumeControl.mouseArea.clicked(mouse)
                                                onMouseXChanged: volumeControl.mouseArea.mouseXChanged(mouse)
                                                onMouseYChanged: volumeControl.mouseArea.mouseYChanged(mouse)
                                            }
                                        }

                                        AbstractCellLayout {
                                            title: "Q"
                                            enabled:  _lowcutDelegate.eq 
                                            text: root.selectedChannel.synthSlotsData[index]
                                            text2: _lowcutDelegate.eq ? _lowcutDelegate.eq.quality.toFixed(2): "-"

                                            control1: VolumeControl {
                                                id: volumeControl2
                                                tickLabelSet : ({"0":"0", "5":"5", "10":"10"})  
                                                slider {
                                                    from: 0
                                                    to: 10
                                                    stepSize: 0.1
                                                    value: _lowcutDelegate.eq ? _lowcutDelegate.eq.quality : 0
                                                }
                                                onValueChanged: {
                                                    if (_lowcutDelegate.eq) {
                                                        if(_EQStack.applyToAll) {
                                                            _EQLowCutRow.globalLowCutQ = slider.value
                                                        }else{
                                                            _lowcutDelegate.eq.quality = slider.value
                                                        }
                                                    }
                                                }
                                                onClicked: _EQLowCutRow.handleClick(index)
                                            }
                                            underlay: MouseArea {
                                                anchors.fill: parent
                                                onPressed: volumeControl2.mouseArea.handlePressed(mouse)                                                
                                                onReleased: volumeControl2.mouseArea.released(mouse)
                                                onPressAndHold: volumeControl2.mouseArea.pressAndHold(mouse)
                                                onClicked: volumeControl2.mouseArea.clicked(mouse)
                                                onMouseXChanged: volumeControl2.mouseArea.mouseXChanged(mouse)
                                                onMouseYChanged: volumeControl2.mouseArea.mouseYChanged(mouse)
                                            }
                                        }
                                    }

                                    // enabled: root.selectedChannel.synthSlotsData[index].length > 0
                                    // onClicked: _SYNFilterResoRow.handleClick(index)
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: ZUI.Theme.sectionSpacing
                enabled: root.selectedChannel.trackType !== "external"

                function focusElement(){
                    _compStack.children[_compStack.currentIndex].focusElement()
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit *  2
                    Layout.minimumHeight: Kirigami.Units.gridUnit *  2
                    
                    RowLayout {
                        anchors.fill: parent
                        spacing: ZUI.Theme.spacing

                        ZUI.SectionGroup {
                            Layout.fillHeight: true

                            QQC2.ButtonGroup {
                                buttons: _compButtonsRow.children
                            }

                            RowLayout {
                                id: _compButtonsRow
                                anchors.fill: parent
                                spacing: ZUI.Theme.spacing

                                ZUI.SectionButton {
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                    text: "Threshold"
                                    checked: highlighted
                                    highlighted: _compStack.currentView === MixerBar.CompView.Threshold
                                    onClicked: _compStack.setView(MixerBar.CompView.Threshold)
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        ZUI.SectionGroup {
                            Layout.fillHeight: true

                            RowLayout {
                                anchors.fill: parent
                                spacing: ZUI.Theme.spacing

                                ZUI.SectionButton {
                                    checkable: true
                                    checked: _compStack.applyToAll
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                    text: "All"
                                    onToggled: _compStack.applyToAll = checked
                                    visible: false
                                }
                            }
                        }
                    }
                }

                ZUI.SectionGroup {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    fallbackBackground: Rectangle {
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                        color: Kirigami.Theme.backgroundColor
                        opacity: 0.1
                    } 

                    StackLayout {
                        id: _compStack
                        visible: enabled
                        anchors.fill: parent
                        property int currentView: MixerBar.CompView.Threshold
                        currentIndex : currentView

                        property bool applyToAll: false

                        function setView(view) {
                            _compStack.currentView = view
                            _compStack.currentIndex = _compStack.currentView

                            _compStack.children[_compStack.currentIndex].focusElement()
                        }

                        RowLayout {
                            id: _compThresholdRow
                            spacing: ZUI.Theme.cellSpacing
                            property double globalHiCutValue: 0
                            property double globalHiCutQ: 0

                            function focusElement() {
                                handleClick(root.selectedChannel.id)
                            }
                            
                            function handleClick(channel) { 
                                zynqtgui.sketchpad.selectedTrackId = channel;
                                zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                zynqtgui.sketchpad.lastSelectedObj.setTo("MixerBar_item_threshold", channel, _thresholdRepeater.itemAt(channel),  root.selectedChannel);
                            }

                            Repeater {
                                id: _thresholdRepeater
                                model: Zynthbox.Plugin.sketchpadTrackCount
                                delegate: AbstractCellLayout {
                                    id: _thresholdDelegate 
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    enabled: compressor !== null
                                    highlighted: (index === root.selectedChannel.id || _compStack.applyToAll) && enabled
                                    property QtObject ctrl : Zynthbox.AudioLevels.tracks[index]
                                    property QtObject compressor: ctrl ? ctrl.compressorSettings : null

                                    title: "Threshold"
                                    text2: compressor ? "%1dB".arg(compressor.thresholdDB.toFixed(2)) : "-"

                                    control1: VolumeControl {
                                        id: volumeControl
                                        slider {
                                            from: 0
                                            to: 100
                                        }
                                        tickLabelSet : ({"0":"-50dB", "50":"-20dB", "100":"10dB"})                                        

                                        Binding {
                                            target: volumeControl.slider
                                            property: "value"
                                            value: _thresholdDelegate.compressor ? _thresholdDelegate.compressor.threshold*100 : 0
                                        }

                                        onValueChanged: {
                                            if (_thresholdDelegate.compressor) {
                                                _thresholdDelegate.compressor.threshold = slider.value/100
                                            }
                                        }

                                        onClicked: _compThresholdRow.handleClick(index)
                                    }

                                    underlay: MouseArea {
                                        anchors.fill: parent
                                        onPressed: volumeControl.mouseArea.handlePressed(mouse)                                                
                                        onReleased: volumeControl.mouseArea.released(mouse)
                                        onPressAndHold: volumeControl.mouseArea.pressAndHold(mouse)
                                        onClicked: volumeControl.mouseArea.clicked(mouse)
                                        onMouseXChanged: volumeControl.mouseArea.mouseXChanged(mouse)
                                        onMouseYChanged: volumeControl.mouseArea.mouseYChanged(mouse)
                                    }
                                }
                            }
                        }
                    }
                }
            }
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
