/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Play Grid Page 

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import QtGraphicalEffects 1.0
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.ScreenPage {
    id: component
    screenId: "playgrid"
    controlsVisible: false
    leftPadding: 0
    rightPadding: 0
    topPadding: 5
    bottomPadding: 5
    anchors.fill: parent

    property QtObject sequence: zynqtgui.isBootingComplete ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName) : null
    property QtObject pattern: sequence && !sequence.isLoading && sequence.count > 0 ? sequence.activePatternObject : null

    cuiaCallback: function(cuia) {
        var returnValue = false;

        // Before passing on to the current playgrid, handle our internals
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
                if (playGridSwitcher.visible) {
                    playGridSwitcher.visible = false;
                    returnValue = true;
                } else if (settingsPopup.visible) {
                    settingsPopup.visible = false;
                    returnValue = true;
                }
                break;
            default:
                break;
        }

        if (!returnValue) {
            if (applicationWindow().playGrids.count > 0 && applicationWindow().playGrids.itemAt(Zynthbox.PlayGridManager.currentPlaygrids["playgrid"]).item.cuiaCallback != null) {
                try {
                    returnValue = applicationWindow().playGrids.itemAt(Zynthbox.PlayGridManager.currentPlaygrids["playgrid"]).item.cuiaCallback(cuia);
                }
                catch(error) {
                    console.log("Error in the current playgrid's cuia callback:", error);
                    // No change here, if there's an error in the playgrid's, pass the handling along as though nothing changed
                }
            }
        }
        return returnValue;
    }

    Connections {
        target: applicationWindow()
        function onSelectedChannelChanged() {
            for (let clipIndex = 0; clipIndex < Zynthbox.Plugin.sketchpadSlotCount; ++clipIndex) {
                let newPlaystate = Zynthbox.PlayfieldManager.clipPlaystate(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex, applicationWindow().selectedChannel.id, clipIndex, Zynthbox.PlayfieldManager.NextBarPosition);
                if (clipActivator.nextBarState != newPlaystate) {
                    clipActivator.nextBarState = newPlaystate;
                }
            }
        }
    }
    Connections {
        target: Zynthbox.PlayfieldManager
        function onPlayfieldStateChanged(sketchpadSong, sketchpadTrack, clipIndex, position, newPlaystate) {
            if (applicationWindow().selectedChannel) {
                if (sketchpadTrack === applicationWindow().selectedChannel.id && sketchpadSong === zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex && position == Zynthbox.PlayfieldManager.NextBarPosition) {
                    if (clipActivator.nextBarState != newPlaystate) {
                        clipActivator.nextBarState = newPlaystate;
                    }
                }
            }
        }
    }
    contextualActions: [
        Kirigami.Action {
            id: clipActivator
            property int nextBarState: Zynthbox.PlayfieldManager.StoppedState
            text: enabled
                ? Zynthbox.SyncTimer.timerRunning
                    ? component.pattern.isPlaying
                        ? nextBarState == Zynthbox.PlayfieldManager.PlayingState
                            ? qsTr("Deactivate") // Playback running, and next state is to be playing, so offer to deactivate
                            : qsTr("Stop Deactivating") // Playback is running, next state is to not be playing, so offer to abort that deactivation
                        : nextBarState == Zynthbox.PlayfieldManager.StoppedState
                            ? qsTr("Activate") // Playback is not running, and next state is to stay stopped, so offer to activate
                            : qsTr("Stop Activating") // Playback is not running, and next state is to be playing, so offer to abort that activation
                    : component.pattern.enabled
                        ? qsTr("Deactivate")
                        : qsTr("Activate")
                : ""
            enabled: component.pattern !== null
            onTriggered: {
                var associatedClip = applicationWindow().selectedChannel.getClipsModelById(component.pattern.clipIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                // Seems slightly backwards, but tapping a bunch of times really super fast and you'd end up with something a bit odd and unexpected, so might as well not cause that
                associatedClip.enabled = !component.pattern.enabled
            }
        },
        Kirigami.Action {
            id: placeholderAction
            text: children.length > 0 ? qsTr("%1 Actions").arg(playGridStack.currentPlayGridItem ? playGridStack.currentPlayGridItem.name : " ") : "       "
            enabled: children.length > 0
            children: applicationWindow().playGrids.count === 0 ? [] : applicationWindow().playGrids.itemAt(Zynthbox.PlayGridManager.currentPlaygrids["playgrid"]).item.additionalActions
        }
    ]

/*
Leaving this here, because it was awkward to work out and if we suddenly
decide to change our minds yet again about where these controls go, i
don't want to have to dig too far...
        ,
        Kirigami.Action {
            id: playgridSwitchAction
            text: "Switch Playgrid"
        },
        Kirigami.Action {
            text: "Get New Playgrids"
            onTriggered: {
                zynqtgui.show_modal("playgrid_downloader");
            }
        }
    property var thePlayGridActions: []
    Instantiator {
        id: playGridActionInstantiator
        model: Zynthbox.PlayGridManager.playgrids
        delegate: Kirigami.Action {
            property Item relevantPlaygrid: applicationWindow().playGrids.itemAt(index) ? applicationWindow().playGrids.itemAt(index).item : null
            text: relevantPlaygrid ? relevantPlaygrid.name : ""
            onTriggered: {
                Zynthbox.PlayGridManager.setCurrentPlaygrid("playgrid", index);
            }
        }
        onObjectAdded: {
            thePlayGridActions.push(object);
            playgridSwitchAction.children = thePlayGridActions;
        }
        onObjectRemoved: {
            thePlayGridActions.pop(object);
            playgridSwitchAction.children = thePlayGridActions;
        }
    }
*/

    RowLayout {
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            id: controlsPanel
            z: 999

            Layout.preferredWidth: 80
            Layout.maximumWidth: Layout.preferredWidth
            Layout.fillHeight: true
            Layout.margins: 8

            Zynthian.PlayGridButton {
                id: settingsButton
                // Let's put our friend here on top of the things underneath (which would usually be stacked above)
                z: 1000
                Layout.minimumHeight: width * 0.6
                Layout.maximumHeight: width * 0.6
                icon.name: "application-menu"
                // TODO Reenable this for properly we re-add the ability to have more plaground modules
                visible: applicationWindow().playGrids.count > 2
                Rectangle {
                    id: slideDelegateIconMask
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.largeSpacing
                    }
                    radius: width / 2
                    visible: false
                }
                MouseArea {
                    // A touch hacky, but we can't really depend on everybody telling us that we've lost focus, so... block out everything instead and demand taps
                    x: 0; y: 0; height: component.height; width: component.width;
                    visible: settingsPopup.visible
                    onClicked: {
                        settingsPopup.visible = false;
                    }
                }
                Item {
                    anchors {
                        top: settingsPopup.top
                        left: settingsPopup.right
                        leftMargin: Kirigami.Units.largeSpacing
                        bottom: settingsPopup.bottom
                    }
                    width: component.width - settingsPopup.width - settingsPopup.x - Kirigami.Units.largeSpacing * 4
                    visible: settingsPopup.visible && gridSettingsPopup.item !== null
                    Zynthian.Card {
                        anchors.fill: parent
                    }
                    Loader {
                        id: gridSettingsPopup
                        anchors {
                            fill: parent
                            margins: Kirigami.Units.largeSpacing * 2
                        }
                        sourceComponent: playGridStack.currentPlayGridItem && playGridStack.currentPlayGridItem.popup ? playGridStack.currentPlayGridItem.popup : null
                    }
                }
                Zynthian.Dialog {
                    id: settingsDialog
                    visible: false
                    title: qsTr("%1 Settings").arg(playGridStack.currentPlayGridItem ? playGridStack.currentPlayGridItem.name : " ")
                    modal: true
                    width: component.width - Kirigami.Units.largeSpacing * 4
                    height: component.height - Kirigami.Units.largeSpacing * 4
                    x: Kirigami.Units.largeSpacing
                    y: Kirigami.Units.largeSpacing

                    header: ColumnLayout {
                        Kirigami.Heading {
                            Layout.fillWidth: true
                            Layout.margins: Kirigami.Units.smallSpacing
                            level: 2
                            text: settingsDialog.title
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumHeight: 1
                            Layout.maximumHeight: 1
                            opacity: 0.3
                            color: Kirigami.Theme.textColor
                        }
                    }
                    footer: Zynthian.ActionBar {
                        Layout.fillWidth: true
                        currentPage: Item {
                            property QtObject backAction: Kirigami.Action {
                                text: "Back"
                                onTriggered: {
                                    settingsDialog.visible = false;
                                }
                            }
                            property list<QtObject> contextualActions
                        }
                    }

                    contentItem: Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        sourceComponent: playGridStack.currentPlayGridItem && playGridStack.currentPlayGridItem.settings ? playGridStack.currentPlayGridItem.settings : null
                    }
                }
                Item {
                    id: settingsPopup
                    visible: false
                    anchors {
                        left: parent.right
                        leftMargin: 8
                        top: parent.top
                        topMargin: -8
                    }
                    height: controlsPanel.height / 2
                    width: component.width / 3
                    Zynthian.Card {
                        anchors.fill: parent
                    }
                    onVisibleChanged: {
                        playGridSwitcher.visible = false;
                    }
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.minimumHeight: settingsButton.width
                            Layout.maximumHeight: settingsButton.width
                            icon.name: "view-grid-symbolic"
                            text: "Switch Playgrid"
                            display: QQC2.AbstractButton.TextBesideIcon
                            onClicked: {
                                playGridSwitcher.visible = !playGridSwitcher.visible;
                            }
                            Kirigami.Icon {
                                anchors {
                                    top: parent.top
                                    right: parent.right
                                    bottom: parent.bottom
                                    margins: Kirigami.Units.smallSpacing
                                }
                                width: height
                                source: "arrow-right"
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.minimumHeight: settingsButton.width
                            Layout.maximumHeight: settingsButton.width
                            icon.name: "view-fullscreen"
                            text: "Toggle Full Screen"
                            display: QQC2.AbstractButton.TextBesideIcon
                            onClicked: {
                                settingsPopup.visible = false;
                                applicationWindow().controlsVisible = !applicationWindow().controlsVisible;
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.minimumHeight: settingsButton.width
                            Layout.maximumHeight: settingsButton.width
                            icon.name: "get-hot-new-stuff"
                            text: "Get More Playgrids..."
                            display: QQC2.AbstractButton.TextBesideIcon
                            onClicked: {
                                settingsPopup.visible = false;
                                zynqtgui.show_modal("playgrid_downloader");
                            }
                        }
                        QQC2.Button {
                            Layout.fillWidth: true
                            Layout.minimumHeight: settingsButton.width
                            Layout.maximumHeight: settingsButton.width
                            icon.name: "configure"
                            text: "More Settings..."
                            display: QQC2.AbstractButton.TextBesideIcon
                            onClicked: {
                                settingsPopup.visible = false;
                                settingsDialog.visible = true;
                            }
                        }
                    }
                    Item {
                        id: playGridSwitcher
                        visible: false
                        anchors {
                            left: parent.right
                            leftMargin: -Kirigami.Units.largeSpacing
                            top: parent.top
                            topMargin:Kirigami.Units.largeSpacing
                        }
                        height: playGridSwitcherRepeater.count * settingsButton.width
                        width: component.width / 3
                        Zynthian.Card {
                            anchors.fill: parent
                        }
                        ColumnLayout {
                            anchors.fill: parent;
                            spacing: 0
                            Repeater {
                                id: playGridSwitcherRepeater
                                model: Zynthbox.PlayGridManager.playgrids
                                delegate: QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: settingsButton.width
                                    Layout.maximumHeight: settingsButton.width
                                    property Item relevantPlaygrid: applicationWindow().playGrids.itemAt(index) ? applicationWindow().playGrids.itemAt(index).item : null
                                    text: relevantPlaygrid ? relevantPlaygrid.name : ""
                                    icon.name: relevantPlaygrid ? relevantPlaygrid.icon : "view-grid-symbolic"
                                    display: QQC2.AbstractButton.TextBesideIcon
                                    onClicked: {
                                        settingsPopup.visible = false;
                                        Zynthbox.PlayGridManager.setCurrentPlaygrid("playgrid", index);
                                    }
                                }
                            }
                        }
                    }
                }
                Row {
                    anchors {
                        top: parent.top
                        left: parent.right
                        bottom: parent.bottom
                    }
                    width: applicationWindow().playGrids.count * settingsButton.width
                    spacing: 0
                    visible: settingsSlidePoint.pressed && settingsTouchArea.xChoice > 0
                    Repeater {
                        model: applicationWindow().playGrids.count
                        delegate: Item {
                            id: slideDelegate
                            property bool hovered: settingsTouchArea.xChoice - 1 === index && settingsTouchArea.yChoice === 0
                            property var playGrid: applicationWindow().playGrids.itemAt(index).item
                            property int labelRotation: 45
                            width: settingsButton.width
                            height: width
                            Rectangle {
                                id: slideDelegateBackground
                                anchors {
                                    fill: parent
                                    margins: Kirigami.Units.smallSpacing
                                }
                                radius: width / 2
                                Kirigami.Theme.inherit: false
                                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                border {
                                    width: 1
                                    color: slideDelegate.hovered ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                }
                                color: slideDelegate.hovered ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                            }
                            Kirigami.Icon {
                                anchors {
                                    fill: parent
                                    margins: Kirigami.Units.largeSpacing
                                }
                                source: playGrid.icon
                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: slideDelegateIconMask
                                }
                            }
                            Item {
                                anchors {
                                    left: parent.horizontalCenter
                                    verticalCenter: parent.verticalCenter
                                }
                                width: parent.width / 2 + Kirigami.Units.smallSpacing
                                transformOrigin: Item.Left
                                rotation: slideDelegate.labelRotation
                                Rectangle {
                                    anchors {
                                        fill: slideDelegateLabel
                                        margins: -Kirigami.Units.smallSpacing
                                    }
                                    radius: height / 2
                                    color: slideDelegateBackground.color
                                }
                                QQC2.Label {
                                    id: slideDelegateLabel
                                    anchors {
                                        verticalCenter: parent.verticalCenter
                                        left: parent.right
                                    }
                                    text: slideDelegate.playGrid.name
                                    color: slideDelegateBackground.border.color
                                }
                            }
                        }
                    }
                }
                function getYChoice() {
                    var choice = 0;
                    if (settingsSlidePoint.pressed) {
                        choice = Math.floor(settingsSlidePoint.y / settingsButton.height);
                    }
                    return choice;
                }
                function getXChoice() {
                    var choice = 0;
                    if (settingsSlidePoint.pressed) {
                        choice = Math.floor(settingsSlidePoint.x / settingsButton.width);
                    }
                    return choice;
                }
                MultiPointTouchArea {
                    id: settingsTouchArea
                    anchors.fill: parent
                    touchPoints: [ TouchPoint { id: settingsSlidePoint; } ]
                    property int xChoice
                    property int yChoice
                    onPressed: {
                        if (settingsSlidePoint.pressed) {
                            xChoice = settingsButton.getXChoice();
                            yChoice = settingsButton.getYChoice();
                            parent.focus = true;
                            parent.down = true;
                            if (sidebarLoader.item) {
                                // This looks odd - it steals focus from anything /inside/ the bar that has focus (such as a popup menu that might want hiding)
                                sidebarLoader.item.focus = true;
                            }
                        }
                    }
                    onUpdated: {
                        if (settingsSlidePoint.pressed) {
                            xChoice = settingsButton.getXChoice();
                            yChoice = settingsButton.getYChoice();
                        }
                    }
                    onReleased: {
                        if (!settingsSlidePoint.pressed) {
                            parent.down = false;
                            if (xChoice === 0 && yChoice === 0) {
                                // Then it we just had a tap
                                settingsPopup.visible = !settingsPopup.visible
                            } else if (xChoice === 0 && yChoice !== 0) {
                                switch (yChoice) {
                                    case -1:
                                        // Enable the swipey manipulation on the grids
                                        break;
                                    case -2:
                                        // Disable the swipy manipulation on the grids
                                        break;
                                    default:
                                        break;
                                }
                            } else if (yChoice === 0 && xChoice !== 0) {
                                if (0 < xChoice && xChoice <= applicationWindow().playGrids.count && Zynthbox.PlayGridManager.currentPlaygrids["playgrid"] !== xChoice - 1) {
                                    Zynthbox.PlayGridManager.setCurrentPlaygrid("playgrid", xChoice - 1);
                                }
                            }
                        }
                    }
                }
            }
            Kirigami.Separator {
                visible: settingsButton.visible
                Layout.fillWidth: true;
                Layout.fillHeight: true;
            }

            Loader {
                id: sidebarLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: playGridStack.currentPlayGridItem && playGridStack.currentPlayGridItem.sidebar ? playGridStack.currentPlayGridItem.sidebar : defaultSidebar
            }
        }

        MouseArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            z: 0
            onClicked: { /* Just need a body here... let's try and stop clicks from traveling through, see what happens */ }
            QQC2.StackView {
                id: playGridStack
                anchors.fill: parent
                clip: true
                replaceEnter: Transition {}
                replaceExit: Transition {}
                popEnter: Transition {}
                popExit: Transition {}
                pushEnter: Transition {}
                pushExit: Transition {}
                initialItem: currentPlayGridItem.grid
                property Item currentPlayGridItem: applicationWindow().playGrids.count === 0 ? null : applicationWindow().playGrids.itemAt(Zynthbox.PlayGridManager.currentPlaygrids["playgrid"]).item
                property int currentPlaygrid: -1
                function updatePlaygrid() {
                    updatePlaygridTimer.restart();
                }
                Timer {
                    id: updatePlaygridTimer
                    interval: 1; repeat: false; running: false;
                    onTriggered: {
                        if (applicationWindow().playGrids.count > 0 && playGridStack.currentPlaygrid != Zynthbox.PlayGridManager.currentPlaygrids["playgrid"]){
                            var playgrid = applicationWindow().playGrids.itemAt(Zynthbox.PlayGridManager.currentPlaygrids["playgrid"]).item
                            playGridStack.replace(playgrid.grid);
                            playGridStack.currentPlaygrid = Zynthbox.PlayGridManager.currentPlaygrids["playgrid"];
                            placeholderAction.children = playgrid.additionalActions;
                            if (playgrid.isSequencer) {
                                Zynthbox.PlayGridManager.setPreferredSequencer(Zynthbox.PlayGridManager.playgrids[Zynthbox.PlayGridManager.currentPlaygrids["playgrid"]]);
                            }
                        }
                    }
                }
                Connections {
                    target: Zynthbox.PlayGridManager
                    Component.onCompleted: playGridStack.updatePlaygrid();
                    onPlaygridsChanged: playGridStack.updatePlaygrid();
                    onCurrentPlaygridsChanged: playGridStack.updatePlaygrid();
                }
            }
        }
    }

    Component {
        id: defaultSidebar
        ColumnLayout {
            Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

            Zynthian.PlayGridButton {
                icon.name: "arrow-up"
                enabled: playGridStack.currentPlayGridItem && playGridStack.currentPlayGridItem.useOctaves ? playGridStack.currentPlayGridItem.useOctaves : false
                onClicked: {
                    if (playGridStack.currentPlayGridItem.octave < playGridStack.currentPlayGridItem.gridRowStartNotes.length - 2) {
                        playGridStack.currentPlayGridItem.octave =  playGridStack.currentPlayGridItem.octave + 1;
                    }
                }
            }

            QQC2.Label {
                text: "Octave"
                Layout.alignment: Qt.AlignHCenter
            }

            Zynthian.PlayGridButton {
                icon.name: "arrow-down"
                enabled: playGridStack.currentPlayGridItem && playGridStack.currentPlayGridItem.useOctaves ? playGridStack.currentPlayGridItem.useOctaves : false
                onClicked: {
                    if (playGridStack.currentPlayGridItem.octave > 0) {
                        playGridStack.currentPlayGridItem.octave = playGridStack.currentPlayGridItem.octave - 1;
                    }
                }
            }

            Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

            Zynthian.PlayGridButton {
                text: "Mod\nulate"
                MultiPointTouchArea {
                    anchors.fill: parent
                    property int modulationValue: Math.max(-127, Math.min(modulationPoint.y * 127 / width, 127))
                    onModulationValueChanged: {
                        Zynthbox.PlayGridManager.modulation = modulationValue;
                    }
                    touchPoints: [ TouchPoint { id: modulationPoint; } ]
                    onPressed: {
                        parent.down = true;
                        focus = true;
                    }
                    onReleased: {
                        parent.down = false;
                        focus = false;
                        Zynthbox.PlayGridManager.modulation = 0;
                    }
                }
            }

            Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

            Zynthian.PlayGridButton {
                icon.name: "arrow-up"
                onPressed: {
                    Zynthbox.PlayGridManager.pitch = 8191;
                }
                onReleased: {
                    Zynthbox.PlayGridManager.pitch = 0;
                }
            }
            QQC2.Label {
                text: "Pitch"
                Layout.alignment: Qt.AlignHCenter
            }
            Zynthian.PlayGridButton {
                icon.name: "arrow-down"
                onPressed: {
                    Zynthbox.PlayGridManager.pitch = -8192;
                }
                onReleased: {
                    Zynthbox.PlayGridManager.pitch = 0;
                }
            }
        }
    }

    /*
     * TODO
     * The code below likely wants to live somewhere not here, like a central location for
     * synchronising the behaviour of sequences with sketchpad, but for now, this location
     * works (it's a single instance location which is always loaded)
     */

    Connections {
        target: Zynthbox.MidiRouter
        onAddedHardwareDevice: {
            applicationWindow().showPassiveNotification("Device connected: " + humanReadableName);
            // Once a new device has been added, reset the bank position to center
            // Zynthbox.SyncTimer.sendProgramChangeImmediately(Zynthbox.MidiRouter.masterChannel, 64);
        }
        onRemovedHardwareDevice: {
            applicationWindow().showPassiveNotification("Device removed: " + humanReadableName);
        }
        // TODO Revive this when there's a bit of spare time...
        // We'll need to only feed stuff back to the same device the thing came from (so, hardwareDeviceId, get the device, and then explicitly post a midi message to that device, and only that device)
        // onMidiMessage: {
        //     if (port == Zynthbox.MidiRouter.HardwareInPassthroughPort && 191 < byte1 && byte1 < 208) {
        //         let midiChannel = byte1 - 192;
        //         let delta = byte2 - 64;
        //         if (delta > 0) {
        //             let selectedChannel = applicationWindow().selectedChannel;
        //             while (delta > 0) {
        //                 if (selectedChannel.selectedSlot.className === "TracksBar_synthslot") {
        //                     selectedChannel.selectNextSynthPreset(selectedChannel.selectedSlot.value);
        //                 } else if (selectedChannel.selectedSlot.className === "TracksBar_fxslot") {
        //                     selectedChannel.selectNextFxPreset(selectedChannel.selectedSlot.value);
        //                 } else if (selectedChannel.selectedSlot.className === "TracksBar_sketchfxslot") {
        //                     selectedChannel.selectNextSketchFxPreset(selectedChannel.selectedSlot.value);
        //                 }
        //                 delta = delta - 1;
        //             }
        //             Zynthbox.SyncTimer.sendProgramChangeImmediately(Zynthbox.MidiRouter.masterChannel, 64);
        //         } else if (delta < 0) {
        //             let selectedChannel = applicationWindow().selectedChannel;
        //             while (delta < 0) {
        //                 if (selectedChannel.selectedSlot.className === "TracksBar_synthslot") {
        //                     selectedChannel.selectPreviousSynthPreset(selectedChannel.selectedSlot.value);
        //                 } else if (selectedChannel.selectedSlot.className === "TracksBar_fxslot") {
        //                     selectedChannel.selectPreviousFxPreset(selectedChannel.selectedSlot.value);
        //                 } else if (selectedChannel.selectedSlot.className === "TracksBar_sketchfxslot") {
        //                     selectedChannel.selectPreviousSketchFxPreset(selectedChannel.selectedSlot.value);
        //                 }
        //                 delta = delta + 1;
        //             }
        //             Zynthbox.SyncTimer.sendProgramChangeImmediately(Zynthbox.MidiRouter.masterChannel, 64);
        //         }
        //     }
        // }
    }
    Binding {
        target: Zynthbox.PlayGridManager
        property: "zlSketchpad"
        value: zynqtgui.sketchpad
    }
    Binding {
        target: Zynthbox.SegmentHandler
        property: "song"
        value: zynqtgui.sketchpad.song
    }
    Binding {
        target: Zynthbox.PlayfieldManager
        property: "sketchpad"
        value: zynqtgui.sketchpad.song
    }
    // Our basic structure is logically scene contains channels which contain patterns, and accessing them is done through the song's inverted-structure channels model
    // the channels contain clips models (each of which holds information for all channel/clip combinations for that channel), and each clip in that model holds the data pertaining to one scene/clip/channel
    // there is further a set of sequence models which are partnered each to a scene, and inside each sequence is a pattern, which is paired with a channel
    // Which means that, logically, the structure is actually more:
    // The scene model contains scenes
    //   Each scene contains a sequence
    //     Each sequence contains a number of patterns equal to the number of channels multiplied by the number of clips on each channel
    // The channels model contains channel objects
    //   Each channel contains a clipsModel (holding information for the clip/channel combination for all scenes), and holds clips
    //   Each clip holds information specific to that scene/clip/channel combination
    //   Each scene/clip/channel combination is corresponds to one specific pattern
    // Synchronising the states means matching each pattern with the scene/clip/channel leaf in the channel's tree of data
    // The specific pattern for a leaf can be deduced through the name of the scene, the channel's index, and the clip's index in that channel
    // and fetched from PlayGridManager by asking for the sequence by name ("T1" for example), and then
    // calling getByClipId(trackIndex, clipIndex) to fetch the specific pattern
    Repeater {
        id: tracksRepeater
        delegate: Repeater {
            id: baseTrackDelegate
            property QtObject theTrack: channel
            property int trackIndex: index
            model: baseTrackDelegate.theTrack.clips
            delegate: Repeater {
                id: trackClipDelegate
                property int clipIndex: index
                property QtObject clip: modelData
                model: trackClipDelegate.clip
                delegate: Item {
                    id: trackClipSceneDelegate
                    property QtObject sceneClip: model.clip
                    property int sceneIndex: model.index
                    property string connectedSequenceName: model.index === 0 ? "global" : "global" + (model.index + 1)
                    property QtObject sequence: null
                    property int sequenceIndex: model.index;
                    property QtObject pattern: sequence && sequence.count > 0 ? trackClipSceneDelegate.sequence.getByClipId(baseTrackDelegate.trackIndex, trackClipDelegate.clipIndex) : null;
                    property int patternIndex: sequence ? sequence.indexOf(pattern) : -1;
                    onSequenceChanged: {
                        if (trackClipSceneDelegate.sequence) {
                            trackClipSceneDelegate.sequence.sceneIndex = trackClipSceneDelegate.sceneIndex;
                            // This operation is potentially a bit pricy, as setting the song
                            // to something new will cause the global sequence to be reloaded
                            // to match what is in that song
                            trackClipSceneDelegate.sequence.song = zynqtgui.sketchpad.song;
                        }
                    }
                    onPatternChanged: {
                        if (trackClipSceneDelegate.pattern) {
                            trackClipSceneDelegate.pattern.zlChannel = baseTrackDelegate.theTrack;
                            trackClipSceneDelegate.pattern.zlClip = trackClipDelegate.clip;
                            trackClipSceneDelegate.pattern.zlScene = trackClipSceneDelegate.sceneClip;
                        }
                    }

                    Binding {
                        target: trackClipSceneDelegate
                        property: "sequence"
                        value: Zynthbox.PlayGridManager.getSequenceModel(connectedSequenceName, false); // The bool parameter here makes the system not load the patterns
                        delayed: true
                    }
                }
            }
        }
    }

    Binding {
        target: tracksRepeater
        property: "model"
        value: zynqtgui.sketchpad.song.channelsModel
        delayed: true
    }
}
