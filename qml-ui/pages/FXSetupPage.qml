/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

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

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.ScreenPage {
    id: root
    property var screenIds: ["effects_for_channel", "effect_preset"]
    property QtObject selectedChannel: null
    Timer {
        id: selectedChannelThrottle
        interval: 1; running: false; repeat: false;
        onTriggered: {
            root.selectedChannel = applicationWindow().selectedChannel;
            // When current screen is opened and track changes, make sure to update curlayer and implicitly all lists
            if (root.screenIds.includes(zynqtgui.current_screen_id)) {
                applicationWindow().pageStack.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("fx", root.selectedChannel.selectedSlot.value);
            }
        }
    }
    Connections {
        target: applicationWindow()
        onSelectedChannelChanged: selectedChannelThrottle.restart()
    }
    Component.onCompleted: {
        selectedChannelThrottle.restart()
    }

    contextualActions: [
        Kirigami.Action {
            text: qsTr("Load Sound")
            onTriggered: {
                zynqtgui.show_screen("sound_categories")
            }
        },
        Kirigami.Action {
            text: "Save Sound"
            onTriggered: {
                zynqtgui.show_modal("sound_categories")
                applicationWindow().pageStack.getPage("sound_categories").showSaveSoundDialog()
            }
        },
        Kirigami.Action {
            text: qsTr("Edit")
            onTriggered: {
                zynqtgui.show_screen("control");
            }
        }
    ]
    onVisibleChanged: {
        if (visible) {
            zynqtgui.control.single_effect_engine = ""
        }
    }
    cuiaCallback: function(cuia) {
        // Call cuiaCallback of current selectorView
        var selectorCuiaReturnVal = false
        switch(zynqtgui.current_screen_id) {
            case "effects_for_channel":
                selectorCuiaReturnVal = fixedEffectsView.cuiaCallback(cuia)
                break;
            case "effect_preset":
                selectorCuiaReturnVal = effectPresetView.cuiaCallback(cuia)
                break
        }
        if (selectorCuiaReturnVal == true) {
            // If selected view returns true, return from here as well since CUIA event is already handled
            return true
        } else {
            let currentScreenIndex = root.screenIds.indexOf(zynqtgui.current_screen_id);
            var newIndex

            switch (cuia) {
                case "SCREEN_LAYER":
                case "SCREEN_PRESET":
                    // Switch to Sounds page when library page is open and F2 is pressed again
                    zynqtgui.show_screen("sound_categories")
                    return true;
                case "NAVIGATE_LEFT":
                    newIndex = Math.max(0, currentScreenIndex - 1);
                    zynqtgui.current_screen_id = root.screenIds[newIndex];
                    return true;
                case "NAVIGATE_RIGHT":
                    newIndex = Math.min(root.screenIds.length - 1, currentScreenIndex + 1);
                    zynqtgui.current_screen_id = root.screenIds[newIndex];
                    return true;
                case "KNOB0_TOUCHED":
                    if (!applicationWindow().osd.opened) {
                        pageManager.getPage("sketchpad").updateSelectedFxLayerVolume(0, root.selectedChannel.selectedSlot.value)
                    }
                    return true;
                case "KNOB0_UP":
                    pageManager.getPage("sketchpad").updateSelectedFxLayerVolume(1, root.selectedChannel.selectedSlot.value)
                    return true;
                case "KNOB0_DOWN":
                    pageManager.getPage("sketchpad").updateSelectedFxLayerVolume(-1, root.selectedChannel.selectedSlot.value)
                    return true;
                case "KNOB1_TOUCHED":
                    if (!applicationWindow().osd.opened) {
                        pageManager.getPage("sketchpad").updateSelectedChannelFxLayerCutoff(0, root.selectedChannel.selectedSlot.value)
                    }
                    return true;
                case "KNOB1_UP":
                    pageManager.getPage("sketchpad").updateSelectedChannelFxLayerCutoff(1, root.selectedChannel.selectedSlot.value)
                    return true;
                case "KNOB1_DOWN":
                    pageManager.getPage("sketchpad").updateSelectedChannelFxLayerCutoff(-1, root.selectedChannel.selectedSlot.value)
                    return true;
                case "KNOB2_TOUCHED":
                    if (!applicationWindow().osd.opened) {
                        pageManager.getPage("sketchpad").updateSelectedChannelFxLayerResonance(0, root.selectedChannel.selectedSlot.value)
                    }
                    return true;
                case "KNOB2_UP":
                    pageManager.getPage("sketchpad").updateSelectedChannelFxLayerResonance(1, root.selectedChannel.selectedSlot.value)
                    return true;
                case "KNOB2_DOWN":
                    pageManager.getPage("sketchpad").updateSelectedChannelFxLayerResonance(-1, root.selectedChannel.selectedSlot.value)
                    return true;
                case "SWITCH_BACK_SHORT":
                case "SWITCH_BACK_BOLD":
                    zynqtgui.go_back();
                    return true;
                default:
                    return false;
            }
        }
    }
    contentItem: RowLayout {
        id: layout
        // FIXME : Find a way to correctly expand the columns equally with filLWidth property instead of using manually calculated width value
        property real columnWidth: width / children.length - spacing/2
        spacing: Kirigami.Units.gridUnit

        ColumnLayout {
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: layout.columnWidth

            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredHeight: favToggleButton.height
                contentItem: Kirigami.Heading {
                    level: 2
                    text: qsTr("Track %1 Sketch FX").arg(zynqtgui.sketchpad.selectedTrackId+1)
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                }
                onClicked: {
                    applicationWindow().libraryTypePicker.open();
                }
            }

            Zynthian.SelectorView {
                id: fixedEffectsView
                Layout.fillWidth: true
                Layout.fillHeight: true
                screenId: root.screenIds[0]
                onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                onItemActivated: {
                    pageManager.getPage("sketchpad").bottomStack.tracksBar.switchToSlot("fx", index);
                    if (zynqtgui.current_screen_id != "effects_for_channel") {
                        zynqtgui.current_screen_id = "effects_for_channel";
                    }
                    root.itemActivated(screenId, index)
                }
                onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
                autoActivateIndexOnChange: true
                onIconClicked: {
                    if (fixedEffectsView.selector.current_index != index) {
                        fixedEffectsView.selector.current_index = index;
                        fixedEffectsView.selector.activate_index(index);
                    }
                    zynqtgui.current_screen_id = "effects_for_channel";
                }
                Component.onCompleted: {
                    fixedEffectsView.background.highlighted = Qt.binding(function() { return zynqtgui.current_screen_id === screenId })
                }
                delegate: Zynthian.SelectorDelegate {
                    id: delegate
                    screenId: fixedEffectsView.screenId
                    selector: fixedEffectsView.selector
                    highlighted: zynqtgui.current_screen_id === fixedEffectsView.screenId
                    onCurrentScreenIdRequested: fixedEffectsView.currentScreenIdRequested(screenId)
                    onItemActivated: fixedEffectsView.itemActivated(screenId, index)
                    onItemActivatedSecondary: fixedEffectsView.itemActivatedSecondary(screenId, index)
                    height: fixedEffectsView.view.height/5
                    onClicked: {
                        if (!zynqtgui.effects_for_channel.current_index_valid) {
                            delegate.selector.activate_index(index);
                        }
                    }
                    contentItem: ColumnLayout {
                        RowLayout {
                            QQC2.Label {
                                id: mainLabel
                                Layout.fillWidth: true
                                Binding { // Optimization
                                    target: mainLabel
                                    property: "text"
                                    delayed: true
                                    value: mainLabel.visible
                                        ? model.display
                                        : ""
                                }
                                elide: Text.ElideRight
                            }
                        }                        
                        Rectangle {
                            property QtObject fxPassthroughClient: root.selectedChannel != null && Zynthbox.Plugin.fxPassthroughClients[root.selectedChannel.id] ? Zynthbox.Plugin.fxPassthroughClients[root.selectedChannel.id][index] : null
                            Layout.preferredWidth: fxPassthroughClient && fxPassthroughClient.dryWetMixAmount >= 0 ? parent.width * Zynthian.CommonUtils.interp(fxPassthroughClient.dryWetMixAmount, 0, 2, 0, 1) : 0
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                            visible: fxPassthroughClient != null && root.selectedChannel != null && root.selectedChannel.chainedFx[index] != null
                            color: Kirigami.Theme.highlightColor
                            opacity: 0.7
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: layout.columnWidth

            Kirigami.Heading {
                level: 2
                text: ""
                Kirigami.Theme.inherit: false
                // TODO: this should eventually go to Window and the panels to View
                Kirigami.Theme.colorSet: Kirigami.Theme.View
            }

            Zynthian.SelectorView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: []
            }
        }

        ColumnLayout {
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: layout.columnWidth

            RowLayout {
                Layout.fillWidth: true
                Kirigami.Heading {
                    level: 2
                    text: qsTr("Presets (%1)").arg(zynqtgui.preset.effective_count)
                    Kirigami.Theme.inherit: false
                    // TODO: this should eventually go to Window and the panels to View
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                }
                Item {
                    Layout.fillWidth: true
                }
                QQC2.Button {
                    id: favToggleButton
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    text: zynqtgui.preset.show_only_favorites ? qsTr("Show All") : qsTr("Show Favorites")
                    onClicked: {
                        zynqtgui.preset.show_only_favorites = !zynqtgui.preset.show_only_favorites
                    }
                }
            }
            Zynthian.SelectorView {
                id: effectPresetView
                Layout.fillWidth: true
                Layout.fillHeight: true
                screenId: root.screenIds[1]
                onCurrentScreenIdRequested: root.currentScreenIdRequested(screenId)
                onItemActivated: {
                    if (zynqtgui.current_screen_id != "effect_preset") {
                        zynqtgui.current_screen_id = "effect_preset";
                    }
                    root.itemActivated(screenId, index)
                }
                onItemActivatedSecondary: root.itemActivatedSecondary(screenId, index)
                autoActivateIndexOnChange: true
                onIconClicked: {
                    if (effectPresetView.selector.current_index != index) {
                        effectPresetView.selector.current_index = index;
                        effectPresetView.selector.activate_index(index);
                    }
                    zynqtgui.preset.current_is_favorite = !zynqtgui.preset.current_is_favorite;
                    zynqtgui.current_screen_id = "effect_preset";
                }
                Component.onCompleted: {
                    effectPresetView.background.highlighted = Qt.binding(function() { return zynqtgui.current_screen_id === screenId })
                }
            }
        }
    }
}
