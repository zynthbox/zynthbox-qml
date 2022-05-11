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
import org.zynthian.quick 1.0 as ZynQuick

Zynthian.ScreenPage {
    id: component
    screenId: "playgrid"
    leftPadding: 0
    rightPadding: 0
    topPadding: 5
    bottomPadding: 5
    anchors.fill: parent

    cuiaCallback: function(cuia) {
        var returnValue = false;

        // Before passing on to the current playgrid, handle our internals
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                if (playGridSwitcher.visible) {
                    playGridSwitcher.visible = false;
                    returnValue = true;
                } else if (settingsPopup.visible) {
                    settingsPopup.visible = false;
                    returnValue = true;
                } else if (settingsDialog.visible) {
                    settingsDialog.visible = false;
                    returnValue = true;
                }
                break;
            default:
                break;
        }

        if (!returnValue) {
            if (applicationWindow().playGrids.count > 0 && applicationWindow().playGrids.itemAt(ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]).item.cuiaCallback != null) {
                try {
                    returnValue = applicationWindow().playGrids.itemAt(ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]).item.cuiaCallback(cuia);
                }
                catch(error) {
                    console.log("Error in the current playgrid's cuia callback:", error);
                    // No change here, if there's an error in the playgrid's, pass the handling along as though nothing changed
                }
            }
        }
        return returnValue;
    }

    contextualActions: [
        Kirigami.Action {
            id: placeholderAction
            text: children.length > 0 ? qsTr("%1 Actions").arg(playGridStack.currentPlayGridItem ? playGridStack.currentPlayGridItem.name : " ") : "       "
            enabled: children.length > 0
            children: applicationWindow().playGrids.count === 0 ? [] : applicationWindow().playGrids.itemAt(ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]).item.additionalActions
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
                zynthian.show_modal("playgrid_downloader");
            }
        }
    property var thePlayGridActions: []
    Instantiator {
        id: playGridActionInstantiator
        model: ZynQuick.PlayGridManager.playgrids
        delegate: Kirigami.Action {
            property Item relevantPlaygrid: applicationWindow().playGrids.itemAt(index) ? applicationWindow().playGrids.itemAt(index).item : null
            text: relevantPlaygrid ? relevantPlaygrid.name : ""
            onTriggered: {
                ZynQuick.PlayGridManager.setCurrentPlaygrid("playgrid", index);
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
            z: 1

            Layout.preferredWidth: 80
            Layout.maximumWidth: Layout.preferredWidth
            Layout.fillHeight: true
            Layout.margins: 8

            QQC2.Dialog {
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

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 8
                z: 999

                Zynthian.PlayGridButton {
                    id: settingsButton
                    // Let's put our friend here on top of the things underneath (which would usually be stacked above)
                    z: 1000
                    Layout.minimumHeight: width * 0.6
                    Layout.maximumHeight: width * 0.6
                    icon.name: "application-menu"
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
                                    zynthian.show_modal("playgrid_downloader");
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
                                    model: ZynQuick.PlayGridManager.playgrids
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
                                            ZynQuick.PlayGridManager.setCurrentPlaygrid("playgrid", index);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Item {
                        anchors {
                            top: settingsPopup.top
                            left: settingsPopup.right
                            leftMargin: Kirigami.Units.largeSpacing
                            bottom: settingsPopup.bottom
                        }
                        width: component.width - settingsPopup.mapToGlobal(settingsPopup.width, 0).x - Kirigami.Units.largeSpacing * 3
                        visible: settingsPopup.visible && gridSettingsPopup.item !== null
                        Zynthian.Card {
                            anchors.fill: parent
                        }
                        Loader {
                            id: gridSettingsPopup
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: playGridStack.currentPlayGridItem && playGridStack.currentPlayGridItem.popup ? playGridStack.currentPlayGridItem.popup : null
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
                                    if (0 < xChoice && xChoice <= applicationWindow().playGrids.count && ZynQuick.PlayGridManager.currentPlaygrids["playgrid"] !== xChoice - 1) {
                                        ZynQuick.PlayGridManager.setCurrentPlaygrid("playgrid", xChoice - 1);
                                    }
                                }
                            }
                        }
                    }
                }

                Loader {
                    id: sidebarLoader
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    sourceComponent: playGridStack.currentPlayGridItem && playGridStack.currentPlayGridItem.sidebar ? playGridStack.currentPlayGridItem.sidebar : defaultSidebar
                }
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
                property Item currentPlayGridItem: applicationWindow().playGrids.count === 0 ? null : applicationWindow().playGrids.itemAt(ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]).item
                property int currentPlaygrid: -1
                function updatePlaygrid() {
                    updatePlaygridTimer.restart();
                }
                Timer {
                    id: updatePlaygridTimer
                    interval: 1; repeat: false; running: false;
                    onTriggered: {
                        if (applicationWindow().playGrids.count > 0 && playGridStack.currentPlaygrid != ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]){
                            var playgrid = applicationWindow().playGrids.itemAt(ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]).item
                            playGridStack.replace(playgrid.grid);
                            playGridStack.currentPlaygrid = ZynQuick.PlayGridManager.currentPlaygrids["playgrid"];
                            placeholderAction.children = playgrid.additionalActions;
                            if (playgrid.isSequencer) {
                                ZynQuick.PlayGridManager.setPreferredSequencer(ZynQuick.PlayGridManager.playgrids[ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]]);
                            }
                        }
                    }
                }
                Connections {
                    target: ZynQuick.PlayGridManager
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
                    if (playGridStack.currentPlayGridItem.octave + 1 < 11){
                        playGridStack.currentPlayGridItem.octave =  playGridStack.currentPlayGridItem.octave + 1;
                    } else {
                        playGridStack.currentPlayGridItem.octave =  10;
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
                    if (playGridStack.currentPlayGridItem.octave - 1 > 0) {
                        playGridStack.currentPlayGridItem.octave = playGridStack.currentPlayGridItem.octave - 1;
                    } else {
                        playGridStack.currentPlayGridItem.octave = 0;
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
                        ZynQuick.PlayGridManager.modulation = modulationValue;
                    }
                    touchPoints: [ TouchPoint { id: modulationPoint; } ]
                    onPressed: {
                        parent.down = true;
                        focus = true;
                    }
                    onReleased: {
                        parent.down = false;
                        focus = false;
                        ZynQuick.PlayGridManager.modulation = 0;
                    }
                }
            }

            Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

            Zynthian.PlayGridButton {
                icon.name: "arrow-up"
                onPressed: {
                    ZynQuick.PlayGridManager.pitch = 8191;
                }
                onReleased: {
                    ZynQuick.PlayGridManager.pitch = 0;
                }
            }
            QQC2.Label {
                text: "Pitch"
                Layout.alignment: Qt.AlignHCenter
            }
            Zynthian.PlayGridButton {
                icon.name: "arrow-down"
                onPressed: {
                    ZynQuick.PlayGridManager.pitch = -8192;
                }
                onReleased: {
                    ZynQuick.PlayGridManager.pitch = 0;
                }
            }
        }
    }

    /*
     * TODO
     * The code below likely wants to live somewhere not here, like a central location for
     * synchronising the behaviour of sequences with zynthiloops, but for now, this location
     * works (it's a single instance location which is always loaded)
     */
    function adoptSong() {
        adoptSongTimer.restart();
    }
    Timer {
        id: adoptSongTimer; interval: 1; repeat: false; running: false
        onTriggered: {
            var sceneNames = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"];
            for (var i = 0; i < 10; ++i) {
                var sequence = ZynQuick.PlayGridManager.getSequenceModel("Scene " + sceneNames[i]);
                if (sequence) {
                    // This operation is potentially a bit pricy, as setting the song
                    // to something new will cause the global sequence to be reloaded
                    // to match what is in that song
                    sequence.song = zynthian.zynthiloops.song;
                    sequence.shouldMakeSounds = (zynthian.zynthiloops.song.scenesModel.selectedSceneIndex == i);
                }
            }
            adoptTrack();
        }
    }
    function adoptTrack() {
        var sceneNames = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"];
        var theTrack = zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack);
        for (var i = 0; i < 10; ++i) {
            var sequence = ZynQuick.PlayGridManager.getSequenceModel("Scene " + sceneNames[i]);
            if (sequence) {
                sequence.setActiveTrack(theTrack.id, 0);
            }
        }
    }
    Connections {
        target: zynthian.zynthiloops
        onSongChanged: adoptSong()
    }
    Component.onCompleted: {
        adoptSong();
    }

    function adoptCurrentMidiChannel() {
        adoptCurrentMidiChannelTimer.restart();
    }
    Timer {
        id: adoptCurrentMidiChannelTimer; interval: 1; repeat: false; running: false
        onTriggered: {
            ZynQuick.PlayGridManager.currentMidiChannel = zynthian.session_dashboard.selectedTrack;
        }
    }
    Connections {
        target: zynthian.session_dashboard
        onSelectedTrackChanged: {
            adoptTrack();
            adoptCurrentMidiChannel();
        }
    }
    Connections {
        target: zynthian.zynthiloops.song.tracksModel
        onConnectedSoundsCountChanged: adoptCurrentMidiChannel()
        onConnectedPatternsCountChanged: adoptCurrentMidiChannel();
    }
    Connections {
        target: zynthian.zynthiloops
        onSongChanged: adoptCurrentMidiChannel();
    }
    Connections {
        target: zynthian.zynthiloops.song
        onBpmChanged: {
            ZynQuick.PlayGridManager.syncTimer.bpm = zynthian.zynthiloops.song.bpm
        }
    }
    Repeater {
        model: zynthian.zynthiloops.song.scenesModel
        delegate: Item {
            id: sceneObject
            property string connectedSequenceName: "Scene " + model.scene.name
            property int thisIndex: model.index
            property QtObject sequence: ZynQuick.PlayGridManager.getSequenceModel(connectedSequenceName)
            Connections {
                target: zynthian.zynthiloops.song
                onBpmChanged: {
                    if (sceneObject.sequence && sceneObject.sequence.bpm != zynthian.zynthiloops.song.bpm) {
                        sceneObject.sequence.bpm = zynthian.zynthiloops.song.bpm;
                        scheduleSequenceSave();
                    }
                }
            }
            Connections {
                target: sceneObject.sequence
                onIsDirtyChanged: {
                    if (sceneObject.sequence.isDirty) {
                        scheduleSequenceSave()
                    }
                }
            }
            function scheduleSequenceSave() {
                sequenceSaverThrottle.restart();
            }
            Timer {
                id: sequenceSaverThrottle; repeat: false; running: false; interval: 100
                onTriggered: {
                    sceneObject.sequence.save();
                }
            }
            Connections {
                target: zynthian.zynthiloops.song.scenesModel
                onSelectedSceneIndexChanged: {
                    sceneObject.sequence.shouldMakeSounds = (zynthian.zynthiloops.song.scenesModel.selectedSceneIndex == sceneObject.thisIndex);
                }
            }
            Repeater {
                model: sceneObject.sequence
                delegate: Item {
                    id: patternObject
                    property QtObject thisPattern: model.pattern
                    property int thisPatternIndex: model.index
                    property QtObject trackClipsModel: associatedTrack == null ? null : associatedTrack.clipsModel
                    property QtObject associatedTrack: null
                    property int associatedTrackIndex: -1
                    onAssociatedTrackChanged: {
                        adoptSamples();
                    }
                    function adoptSamples() {
                        var clipIds = [-1,-1,-1,-1,-1];
                        if (patternObject.associatedTrack) {
                            for (var i = 0; i < patternObject.associatedTrack.samples.length; ++i) {
                                var sample = patternObject.associatedTrack.samples[i];
                                if (sample) {
                                    clipIds[i] = sample.cppObjId;
                                }
                            }
                        }
                        patternObject.thisPattern.clipIds = clipIds;
                    }
                    function adoptTrackLayer() {
                        trackAdopterTimer.restart();
                    }
                    Timer {
                        id: trackAdopterTimer; interval: 1; repeat: false; running: false
                        onTriggered: {
                            var foundTrack = null;
                            var foundIndex = -1;
                            if (patternObject.thisPattern.trackIndex > -1) {
                                foundIndex = patternObject.thisPattern.trackIndex;
                                foundTrack = zynthian.zynthiloops.song.tracksModel.getTrack(patternObject.thisPattern.trackIndex)
                            } else {
                                for(var i = 0; i < zynthian.zynthiloops.song.tracksModel.count; ++i) {
                                    var track = zynthian.zynthiloops.song.tracksModel.getTrack(i);
                                    if (track && track.connectedPattern === patternObject.thisPatternIndex) {
                                        foundTrack = track;
                                        foundIndex = i;
                                        break;
                                    }
                                }
                            }
                            patternObject.associatedTrack = foundTrack;
                            patternObject.associatedTrackIndex = foundIndex;

                            if (patternObject.associatedTrackIndex > -1) {
                                if (patternObject.associatedTrack.trackAudioType === "sample-trig") {
                                    patternObject.thisPattern.noteDestination = ZynQuick.PatternModel.SampleTriggerDestination;
                                } else if (patternObject.associatedTrack.trackAudioType == "sample-slice") {
                                    patternObject.thisPattern.noteDestination = ZynQuick.PatternModel.SampleSlicedDestination;
                                } else if (patternObject.associatedTrack.trackAudioType == "sample-loop") {
                                    patternObject.thisPattern.noteDestination = ZynQuick.PatternModel.SampleLoopedDestination;
                                } else if (patternObject.associatedTrack.trackAudioType == "external") {
                                    patternObject.thisPattern.noteDestination = ZynQuick.PatternModel.ExternalDestination;
                                } else {
                                    patternObject.thisPattern.noteDestination = ZynQuick.PatternModel.SynthDestination;
                                }
                                var connectedSound = patternObject.associatedTrackIndex;
                                if (connectedSound === -1) {
                                    // Channel 15 is interpreted as "no assigned sound, either use override or play nothing"
                                    patternObject.thisPattern.layer = 15;
                                } else if (connectedSound !== patternObject.thisPattern.layer) {
                                    patternObject.thisPattern.layer = connectedSound;
                                }
                            } else {
                                // Channel 15 is interpreted as "no assigned sound, either use override or play nothing"
                                patternObject.thisPattern.layer = 15;
                            }
                            if (patternObject.thisPattern.layer === 15) {
                                patternObject.thisPattern.layerData = "";
                            } else {
                                patternObject.thisPattern.layerData = zynthian.layer.layer_as_json(patternObject.associatedTrack.connectedSound);
                            }
                            patternObject.thisPattern.externalMidiChannel = patternObject.associatedTrack.externalMidiChannel;
                            sceneClipItem.updateEnabledFromClips();
                        }
                    }
                    Connections {
                        target: patternObject.thisPattern
                        onLayerChanged: patternObject.adoptTrackLayer()
                        onEnabledChanged: sceneClipItem.updateClipsFromEnabled()
                        onBankOffsetChanged: sceneClipItem.updateClipsFromEnabled()
                        onNoteDestinationChanged: {
                            if (patternObject.associatedTrack) {
                                switch (patternObject.thisPattern.noteDestination) {
                                    case ZynQuick.PatternModel.SampleTriggerDestination:
                                        patternObject.associatedTrack.trackAudioType = "sample-trig";
                                        break;
                                    case ZynQuick.PatternModel.SampleSlicedDestination:
                                        patternObject.associatedTrack.trackAudioType = "sample-slice";
                                        break;
                                    case ZynQuick.PatternModel.SampleLoopedDestination:
                                        patternObject.associatedTrack.trackAudioType = "sample-loop";
                                        break;
                                    case ZynQuick.PatternModel.ExternalDestination:
                                        patternObject.associatedTrack.trackAudioType = "external";
                                        break;
                                    case ZynQuick.PatternModel.SynthDestination:
                                    default:
                                        patternObject.associatedTrack.trackAudioType = "synth";
                                        break;
                                }
                            }
                        }
                    }
                    Connections {
                        target: zynthian.zynthiloops.song.tracksModel
                        onConnectedSoundsCountChanged: patternObject.adoptTrackLayer()
                        onConnectedPatternsCountChanged: patternObject.adoptTrackLayer()
                    }
                    Connections {
                        target: zynthian.zynthiloops
                        onSongChanged: patternObject.adoptTrackLayer()
                    }
                    Connections {
                        target: patternObject.associatedTrack
                        onConnectedPatternChanged: patternObject.adoptTrackLayer()
                        onConnectedSoundChanged: patternObject.adoptTrackLayer()
                        onTrackAudioTypeChanged: {
                            if (patternObject.associatedTrack.trackAudioType === "sample-trig") {
                                patternObject.thisPattern.noteDestination = ZynQuick.PatternModel.SampleTriggerDestination;
                            } else if (patternObject.associatedTrack.trackAudioType == "sample-slice") {
                                patternObject.thisPattern.noteDestination = ZynQuick.PatternModel.SampleSlicedDestination;
                            } else if (patternObject.associatedTrack.trackAudioType == "sample-loop") {
                                patternObject.thisPattern.noteDestination = ZynQuick.PatternModel.SampleLoopedDestination;
                            } else if (patternObject.associatedTrack.trackAudioType == "external") {
                                patternObject.thisPattern.noteDestination = ZynQuick.PatternModel.ExternalDestination;
                            } else {
                                patternObject.thisPattern.noteDestination = ZynQuick.PatternModel.SynthDestination;
                            }
                            component.adoptCurrentMidiChannel();
                        }
                        onSamplesChanged: {
                            adoptSamples();
                        }
                        onSelectedPartChanged: {
                            sceneClipItem.updateEnabledFromClips();
                            if (patternObject.thisPattern.trackIndex === sceneObject.sequence.activePatternObject.trackIndex) {
                                if (patternObject.thisPattern.partIndex === patternObject.associatedTrack.selectedPart) {
                                    sceneObject.sequence.activePattern = patternObject.thisPatternIndex;
                                }
                            }
                        }
                        onExternalMidiChannelChanged: {
                            patternObject.thisPattern.externalMidiChannel = patternObject.associatedTrack.externalMidiChannel;
                            component.adoptCurrentMidiChannel();
                        }
                    }
                    Component.onCompleted: {
                        adoptTrackLayer();
                    }
                    // Our basic structure is logically scene contains tracks which contain patterns, but in reality it's a set of parallel structures
                    // the scene model basically contains only scenes
                    // the tracks contain clips, each of which corresponds to a scene, and references a part (held as an index, though they are named a, b, c, d, and e)
                    // there is further a set of sequence models which are partnered each to a scene, and inside each sequence is a pattern, which is paired with a track
                    // Which means that, logically, the structure is actually more:
                    // The scene model contains scenes
                    //   Each scene contains a sequence
                    //     Each sequence contains a number of patterns equal to the number of tracks multiplied by the number of parts in each track
                    // The tracks model contains clips
                    //   Each row of clips corresponds to one scene (so all clips in the same position in each track correspond to the same scene)
                    //   Each individual clip holds a set of parts
                    //   Each part in a clip corresponds to one pattern
                    // Synchronising the states means matching each pattern with the part in the clip matching it in each track
                    Timer {
                        id: updateEnabledFromClipsTimer; interval: 1; repeat: false; running: false
                        onTriggered: {
                            if (sceneClipItem.clip) {
                                var clipInScene = zynthian.zynthiloops.song.scenesModel.isClipInScene(sceneClipItem.clip, sceneClipItem.clip.col);
                                var isSelectedPart = (patternObject.associatedTrack.selectedPart === patternObject.thisPattern.partIndex);
                                patternObject.thisPattern.enabled = clipInScene && isSelectedPart;
                            } else {
                                updateEnabledFromClipsTimer.restart();
                            }
                        }
                    }
                    Timer {
                        id: updateClipsFromEnabledTimer; interval: 1; repeat: false; running: false
                        onTriggered: {
                            var enabledClip = patternObject.thisPattern.enabled ? sceneObject.thisIndex : -1;
                            var clipInScene = zynthian.zynthiloops.song.scenesModel.isClipInScene(sceneClipItem.clip, sceneClipItem.clip.col);
                            // Only update clips if we're actually the selected pattern
                            if (patternObject.associatedTrack.selectedPart === patternObject.thisPattern.partIndex) {
                                if (patternObject.thisPattern.enabled && !clipInScene) {
                                    zynthian.zynthiloops.song.scenesModel.addClipToCurrentScene(sceneClipItem.clip);
                                } else if (!patternObject.thisPattern.enabled && clipInScene) {
                                    zynthian.zynthiloops.song.scenesModel.removeClipFromCurrentScene(sceneClipItem.clip);
                                }
                            }
                        }
                    }
                    Item {
                        id: sceneClipItem
                        property QtObject clip: patternObject.trackClipsModel ? patternObject.trackClipsModel.getClip(sceneObject.thisIndex) : null
                        function updateEnabledFromClips() {
                            updateEnabledFromClipsTimer.restart();
                        }
                        // The inverse situation of the above - if we're setting the state here,
                        // we should feed it back to the scene model, so it knows what's going on
                        function updateClipsFromEnabled() {
                            updateClipsFromEnabledTimer.restart();
                        }
                        Connections {
                            target: sceneClipItem.clip
                            onCppObjIdChanged: {
                                sceneClipItem.updateEnabledFromClips();
                            }
                            onInCurrentSceneChanged: {
                                sceneClipItem.updateEnabledFromClips();
                            }
                        }
                    }
                }
            }
        }
    }
}
