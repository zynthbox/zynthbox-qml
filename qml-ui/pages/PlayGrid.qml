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

    contextualActions: [
        Kirigami.Action {
            id: placeholderAction
            text: children.length > 0 ? qsTr("%1 Actions").arg(playGridsRepeater.currentItem ? playGridsRepeater.currentItem.name : " ") : "       "
            enabled: children.length > 0
        },
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
    ]
    property var thePlayGridActions: []
    Instantiator {
        id: playGridActionInstantiator
        model: ZynQuick.PlayGridManager.playgrids
        delegate: Kirigami.Action {
            property Item relevantPlaygrid: playGridsRepeater.itemAt(index) ? playGridsRepeater.itemAt(index).item : null
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

    Connections {
        target: ZynQuick.PlayGridManager
        property string currentPlaygrid
        function updatePlaygrid() {
            if (playGridsRepeater.count > 0 && currentPlaygrid != ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]){
                var playgrid = playGridsRepeater.itemAt(ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]).item
                playGridStack.replace(playgrid.grid);
                currentPlaygrid = ZynQuick.PlayGridManager.currentPlaygrids["playgrid"];
            }
        }
        onPlaygridsChanged: updatePlaygrid();
        onCurrentPlaygridsChanged: updatePlaygrid();
    }

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
                title: qsTr("%1 Settings").arg(playGridsRepeater.currentItem ? playGridsRepeater.currentItem.name : " ")
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
                    sourceComponent: playGridsRepeater.currentItem && playGridsRepeater.currentItem.settings ? playGridsRepeater.currentItem.settings : null
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
                        height: controlsPanel.height / 3
                        width: component.width / 3
                        Zynthian.Card {
                            anchors.fill: parent
                        }
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0
                            QQC2.Button {
                                Layout.fillWidth: true
                                Layout.minimumHeight: settingsButton.height
                                Layout.maximumHeight: settingsButton.height
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
                                Layout.minimumHeight: settingsButton.height
                                Layout.maximumHeight: settingsButton.height
                                icon.name: "configure"
                                text: "More Settings..."
                                display: QQC2.AbstractButton.TextBesideIcon
                                onClicked: {
                                    settingsPopup.visible = false;
                                    settingsDialog.visible = true;
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
                            sourceComponent: playGridsRepeater.currentItem && playGridsRepeater.currentItem.popup ? playGridsRepeater.currentItem.popup : null
                        }
                    }
                    Row {
                        anchors {
                            top: parent.top
                            left: parent.right
                            bottom: parent.bottom
                        }
                        width: playGridsRepeater.count * settingsButton.width
                        spacing: 0
                        visible: settingsSlidePoint.pressed && settingsTouchArea.xChoice > 0
                        Repeater {
                            model: playGridsRepeater.count
                            delegate: Item {
                                id: slideDelegate
                                property bool hovered: settingsTouchArea.xChoice - 1 === index && settingsTouchArea.yChoice === 0
                                property var playGrid: playGridsRepeater.itemAt(index).item
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
                                    if (0 < xChoice && xChoice <= playGridsRepeater.count && ZynQuick.PlayGridManager.currentPlaygrids["playgrid"] !== xChoice - 1) {
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
                    sourceComponent: playGridsRepeater.currentItem && playGridsRepeater.currentItem.sidebar ? playGridsRepeater.currentItem.sidebar : defaultSidebar
                }
            }
        }

        QQC2.StackView {
            id: playGridStack
            z: 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            replaceEnter: Transition {}
            replaceExit: Transition {}
            popEnter: Transition {}
            popExit: Transition {}
            pushEnter: Transition {}
            pushExit: Transition {}
            initialItem: playGridsRepeater.count === 0 ? null : playGridsRepeater.itemAt(ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]).item.grid
        }
    }

    Component {
        id: defaultSidebar
        ColumnLayout {
            Kirigami.Separator { Layout.fillWidth: true; Layout.fillHeight: true; }

            Zynthian.PlayGridButton {
                icon.name: "arrow-up"
                enabled: playGridsRepeater.currentItem && playGridsRepeater.currentItem.useOctaves ? playGridsRepeater.currentItem.useOctaves : false
                onClicked: {
                    if (playGridsRepeater.currentItem.octave + 1 < 11){
                        playGridsRepeater.currentItem.octave =  playGridsRepeater.currentItem.octave + 1;
                    } else {
                        playGridsRepeater.currentItem.octave =  10;
                    }
                }
            }

            QQC2.Label {
                text: "Octave"
                Layout.alignment: Qt.AlignHCenter
            }

            Zynthian.PlayGridButton {
                icon.name: "arrow-down"
                enabled: playGridsRepeater.currentItem && playGridsRepeater.currentItem.useOctaves ? playGridsRepeater.currentItem.useOctaves : false
                onClicked: {
                    if (playGridsRepeater.currentItem.octave - 1 > 0) {
                        playGridsRepeater.currentItem.octave = playGridsRepeater.currentItem.octave - 1;
                    } else {
                        playGridsRepeater.currentItem.octave = 0;
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


    Repeater {
        id:playGridsRepeater
        model: ZynQuick.PlayGridManager.playgrids
        property Item currentItem: playGridsRepeater.count === 0 ? null : playGridsRepeater.itemAt(ZynQuick.PlayGridManager.currentPlaygrids["playgrid"]).item
        Loader {
            id:playGridLoader
            source: modelData + "/main.qml"
            onLoaded: {
                playGridLoader.item.setId(modelData);
            }
        }
    }

    /*
     * TODO
     * The code below likely wants to live somewhere not here, like a central location for
     * synchronising the behaviour of sequences with zynthiloops, but for now, this location
     * works (it's a single instance location which is always loaded)
     */
    Connections {
        target: zynthian.zynthiloops
        onSongChanged: {
            _private.sequence.song = zynthian.zynthiloops.song;
        }
    }
    function adoptCurrentMidiChannel() {
        adoptCurrentMidiChannelTimer.restart();
    }
    Timer {
        id: adoptCurrentMidiChannelTimer; interval: 1; repeat: false; running: false
        onTriggered: {
            var theTrack = zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack);
            ZynQuick.PlayGridManager.currentMidiChannel = (theTrack != null) ? theTrack.connectedSound : -1;
        }
    }
    Connections {
        target: zynthian.session_dashboard
        onSelectedTrackChanged: adoptCurrentMidiChannel()
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
    Repeater {
        model: ZynQuick.PlayGridManager.getSequenceModel("Global")
        delegate: Item {
            id: patternObject
            property QtObject thisPattern: model.pattern
            property int thisPatternIndex: model.index
            property QtObject trackClipsModel: associatedTrack == null ? null : associatedTrack.clipsModel
            property QtObject associatedTrack: null
            property int associatedTrackIndex: -1
            function adoptTrackLayer() {
                trackAdopterTimer.restart();
            }
            Timer {
                id: trackAdopterTimer; interval: 1; repeat: false; running: false
                onTriggered: {
                    var foundTrack = null;
                    var foundIndex = -1;
                    for(var i = 0; i < zynthian.zynthiloops.song.tracksModel.count; ++i) {
                        var track = zynthian.zynthiloops.song.tracksModel.getTrack(i);
                        if (track && track.connectedPattern === patternObject.thisPatternIndex) {
                            foundTrack = track;
                            foundIndex = i;
                            break;
                        }
                    }
                    patternObject.associatedTrack = foundTrack;
                    patternObject.associatedTrackIndex = foundIndex;

                    if (patternObject.associatedTrackIndex > -1) {
                        var connectedSound = patternObject.associatedTrack.connectedSound;
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
                    trackClipsRepeater.updateEnabledFromClips();
                }
            }
            Connections {
                target: patternObject.thisPattern
                onLayerChanged: patternObject.adoptTrackLayer()
                onEnabledChanged: trackClipsRepeater.updateClipsFromEnabled()
                onBankOffsetChanged: trackClipsRepeater.updateClipsFromEnabled()
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
            }
            Component.onCompleted: {
                adoptTrackLayer();
            }
            Timer {
                id: updateEnabledFromClipsTimer; interval: 1; repeat: false; running: false
                onTriggered: {
                    var enabledBank = -1;
                    for(var i = 0; i < trackClipsRepeater.count; ++i) {
                        var clipItem = trackClipsRepeater.itemAt(i);
                        if (clipItem.clipInScene) {
                            enabledBank = i;
                            break;
                        }
                    }
                    patternObject.thisPattern.enabled = (enabledBank > -1);
                    if (enabledBank > -1) {
                        patternObject.thisPattern.bankOffset = enabledBank * patternObject.thisPattern.bankLength;
                    }
                }
            }
            Timer {
                id: updateClipsFromEnabledTimer; interval: 1; repeat: false; running: false
                onTriggered: {
                    var enabledClip = patternObject.thisPattern.bankOffset / patternObject.thisPattern.bankLength;
                    if (!patternObject.thisPattern.enabled) {
                        enabledClip = -1;
                    }
                    for (var i = 0; i < trackClipsRepeater.count; ++i) {
                        var clipItem = trackClipsRepeater.itemAt(i);
                        if (i === enabledClip && !clipItem.clipInScene) {
                            zynthian.zynthiloops.song.scenesModel.addClipToCurrentScene(clipItem.clip);
                            // Since the call above already disables all other clips from the same
                            // track, there's no particular need to keep this going
                            break;
                        } else if (enabledClip === -1 && clipItem.clipInScene) {
                            // If there are no enabled clips, then we'll need to remove any that are
                            // set as in the scene right now
                            zynthian.zynthiloops.song.scenesModel.removeClipFromCurrentScene(clipItem.clip);
                        }
                    }
                }
            }
            Repeater {
                id: trackClipsRepeater
                model: patternObject.trackClipsModel
                function updateEnabledFromClips() {
                    updateEnabledFromClipsTimer.restart();
                }
                // The inverse situation of the above - if we're setting the state here,
                // we should feed it back to the scene model, so it knows what's going on
                function updateClipsFromEnabled() {
                    updateClipsFromEnabledTimer.restart();
                }
                delegate: Item {
                    id: clipProxyDelegate
                    property QtObject clip: model.clip
                    property bool clipInScene: model.clip.inCurrentScene
                    Connections {
                        target: clipProxyDelegate.clip
                        onInCurrentSceneChanged: {
                            trackClipsRepeater.updateEnabledFromClips();
                        }
                    }
                }
            }
        }
    }
}
