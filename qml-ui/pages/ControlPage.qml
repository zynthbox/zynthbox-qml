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
import QtQuick.Window 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.7 as Kirigami

import io.zynthbox.ui 1.0 as ZUI
import io.zynthbox.ui2 1.0 as ZUI2

import io.zynthbox.components 1.0 as Zynthbox

ZUI2.ScreenPage {
    id: root
    title: zynqtgui.control.selector_path_element

    screenId: "control"
    property bool isVisible:zynqtgui.current_screen_id === "control"
    property var cuiaCallback: function(cuia) {
        if (!stack.currentItem
            || !stack.currentItem.hasOwnProperty("cuiaCallback")
            || !(stack.currentItem.cuiaCallback instanceof Function)) {
            return false;
        }

        //return false if the function returns anything not boolean
        if (stack.currentItem.cuiaCallback(cuia) === true) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * Update controller value of selected column
     * @param rowIndex The rowIndex(0, 1, 2) of controller whose value needs to be updated
     * @param sign Sign to determine if value should be incremented / decremented. Pass +1 to increment and -1 to decrement value by controller's step size
     */
    function updateControllerValue(controller, sign) {
        if (controller != null) {
            if (controller.value_type === "bool") {
                controller.value = sign > 0 ? controller.max_value : controller.value0;
            } else {
                let stepSize = controller.step_size === 0 ? 1 : controller.step_size
                controller.value = ZUI2.CommonUtils.clamp(controller.value + sign * stepSize, controller.value0, controller.max_value)
            }
        }
    }

    contextualActions: [
        Kirigami.Action {
            id: viewAction
            text: qsTr("Select Mod")
            enabled: zynqtgui.control.control_pages_model.count > 1
            property QQC2.Menu menuDelegate: customControlsMenu
        },
        Kirigami.Action {
            visible: false
        },
        Kirigami.Action {
            text: qsTr("Get New Mods...")
            onTriggered: zynqtgui.control.single_effect_engine === "" ? zynqtgui.show_modal("control_downloader") : zynqtgui.show_modal("fx_control_downloader")
        }
    ]

//    Connections {
//        target: applicationWindow()
//        onActiveFocusItemChanged: {
//            var candidate = applicationWindow().activeFocusItem
//            while(candidate) {
//                if (candidate.hasOwnProperty("controller")) {
//                    break;
//                }
//                candidate = candidate.parent
//            }
//            if (candidate) {
//                zynqtgui.control.active_custom_controller = candidate.controller.ctrl
//            } else {
//                zynqtgui.control.active_custom_controller = null
//            }
//        }
//    }
//    Connections {
//        target: applicationWindow()
//        enabled: root.isVisible
//        onSelectedChannelChanged: {
//            if (applicationWindow().selectedChannel) {
//                if (applicationWindow().selectedChannel.trackType === "external") {
//                    zynqtgui.callable_ui_action_simple("SCREEN_EDIT_CONTEXTUAL");
//                } else if (applicationWindow().selectedChannel.trackType.startsWith("sample-")) {
//                    zynqtgui.callable_ui_action_simple("SCREEN_EDIT_CONTEXTUAL");
//                }
//            }
//        }
//    }
    QQC2.Menu {
        id: customControlsMenu
        y: -height
        QQC2.MenuItem {
            height: Kirigami.Units.gridUnit * 2
            text: qsTr("Select Preferred Mod-pack")
            onClicked: {
                modPackPicker.open();
            }
        }
        QQC2.MenuItem {
            height: Kirigami.Units.gridUnit * 2
            text: qsTr("Update Mod List")
            onClicked: {
                zynqtgui.control.updateRegistry();
            }
        }
        QQC2.MenuSeparator { }
        Repeater {
            model: zynqtgui.control.control_pages_model
            delegate: QQC2.MenuItem {
                id: menuItem
                height: Kirigami.Units.gridUnit * 2
                text: model.display
                checkable: true
                autoExclusive: true
                checked: model.path == ""
                    ? (zynqtgui.control.custom_control_page == "")
                    : (zynqtgui.control.custom_control_page.indexOf(model.path) == 0)

                onClicked: {
                    zynqtgui.control.refresh_values()
                    zynqtgui.control.custom_control_page = model.path
                }
            }
        }
    }

    Component.onCompleted: {
       // mainView.forceActiveFocus()
        root.ensurePageCache();
        //HACK
        if (!root.visible) {
            return;
        }
        if (zynqtgui.control.custom_control_page.length > 0) {
            if (stack.currentItem != null) {
                stack.currentItem.visible = false
            }
            stack.replace(zynqtgui.control.custom_control_page);
            root.currentControlPage = zynqtgui.control.custom_control_page;
        } else {
            if (stack.currentItem != null) {
                stack.currentItem.visible = false
            }
            stack.replace(defaultPage);
            root.currentControlPage = "defaultPage";
        }
    }

    onVisibleChanged: {
        if (zynqtgui.control.custom_control_page.length > 0) {
            if (root.currentControlPage !== zynqtgui.control.custom_control_page) {
                if (stack.currentItem != null) {
                    stack.currentItem.visible = false
                }
                stack.replace(zynqtgui.control.custom_control_page);
                root.currentControlPage = zynqtgui.control.custom_control_page;
            }
        } else if (!stack.currentItem || stack.currentItem.objectName !== "defaultPage") {
            if (stack.currentItem != null) {
                stack.currentItem.visible = false
            }
            stack.replace(defaultPage);
            root.currentControlPage = "defaultPage";
        }
    }
    property string currentControlPage
    property var controlPageCache: ({})
    function getControlPage(page) {
        let actualPage = page;
        let defaultParams = {/*"width": root.width, "height": root.height,*/ visible: false};
        if (actualPage == "") {
            actualPage = "defaultPage";
            if (root.controlPageCache.hasOwnProperty("defaultPage") == false) {
                root.controlPageCache[actualPage] = {
                    ttl: 0,
                    url: "DefaultEditPage.qml",
                    params: defaultParams,
                    errorString: "",
                    pageObject: defaultPage.createObject(applicationWindow(), defaultParams)
                };
            }
        } else if (root.controlPageCache[actualPage] == null) {
            // console.log("Page cache not found for actualPage :", actualPage)
            // console.log("Instantiating page", actualPage, ":", actualPage);
            var cache = ZUI2.CommonUtils.instantiateComponent(actualPage, defaultParams);

            if (cache.errorString != "") {
                console.log("Error instantiating page", cache.url, ":", cache.errorString);
                actualPage = "defaultPage";
                // Ensure we cache the default page, and then fall back appropriately...
                getControlPage(actualPage);
            } else {
                root.controlPageCache[actualPage] = cache;
            }
        }
        return root.controlPageCache[actualPage].pageObject;
    }
    Connections {
        target: zynqtgui.control
        onCustom_control_pageChanged: {
            if (!root.visible) {
                return;
            }
            if (zynqtgui.control.custom_control_page.length > 0) {
                if (root.currentControlPage !== zynqtgui.control.custom_control_page) {
                    if (stack.currentItem != null) {
                        stack.currentItem.visible = false
                    }
                    stack.replace(root.getControlPage(zynqtgui.control.custom_control_page));
                    root.currentControlPage = zynqtgui.control.custom_control_page;
                }
            } else if (!stack.currentItem || stack.currentItem.objectName !== "defaultPage") {
                if (stack.currentItem != null) {
                    stack.currentItem.visible = false
                }
                stack.replace(root.getControlPage(""));
                root.currentControlPage = "defaultPage";
            }
        }
    }
    Connections {
        id: currentConnection
        target: zynqtgui
        onCurrent_screen_idChanged: {
            root.visible = zynqtgui.current_screen_id === "control";
        }
    }
    function ensurePageCache() {
        for (let trackIndex = 0; trackIndex < Zynthbox.Plugin.sketchpadTrackCount; ++trackIndex) {
            let track = zynqtgui.sketchpad.song.channelsModel.getChannel(trackIndex);
            let chainedSounds = track.chainedSounds;
            for (let i = 0; i < chainedSounds.length; ++i) {
                let midiChannel = chainedSounds[i];
                // console.log("Testing chained sound", i, "on track", trackIndex, "which has midi channel", midiChannel, "which exists?", track.checkIfLayerExists(midiChannel));
                if (midiChannel > -1 && track.checkIfLayerExists(midiChannel)) {
                    let layer = zynqtgui.layer.get_layer_by_midi_channel(midiChannel);
                    let customControlPage = zynqtgui.control.get_custom_control_page_for_plugin(layer.engineObject.pluginID);
                    root.getControlPage(customControlPage);
                }
            }
            let chainedFx = track.chainedFx;
            for (let i = 0; i < chainedFx.length; ++i) {
                let layer = chainedFx[i];
                if (layer) {
                    let customControlPage = zynqtgui.control.get_custom_control_page_for_plugin(layer.engineObject.pluginID);
                    root.getControlPage(customControlPage);
                }
            }
        }
        // console.log("Cache operation completion");
    }
    Connections {
        target: zynqtgui.sketchpad.song
        onIsLoadingChanged: {
            if (zynqtgui.sketchpad.song.isLoading == false) {
                // When we're done loading a song, ensure we've got all the control pages for synths and fx cached
                root.ensurePageCache();
            }
        }
    }
    Repeater {
        model: zynqtgui.sketchpad.song.channelsModel
        delegate: Item {
            Connections {
                target: zynqtgui.sketchpad.song.channelsModel.getChannel(model.index)
                // When the sounds and fx change, ensure we've got all the control pages for synths and fx cached
                onChained_sounds_changed: root.ensurePageCache()
                onChainedFxChanged: root.ensurePageCache()
            }
        }
    }

    //onFocusChanged: {
        //if (focus) {
            //mainView.forceActiveFocus()
        //}
    //}

    bottomPadding: Kirigami.Units.gridUnit
    contentItem: ZUI2.Stack {
        id: stack
    }

    Component {
        id: defaultPage

        DefaultEditPage {
            id: defaultPageRoot
            objectName: "defaultPage"
        }
    }

    ZUI2.ActionPickerPopup {
        id: modPackPicker
        actions: [
            QQC2.Action {
                text: "Default"
                checked: zynqtgui.control.preferredModpack === ""
                onTriggered: {
                    zynqtgui.control.preferredModpack = "";
                }
            }
        ]
    }
    Instantiator {
        id: modPackPickerActionInstantiator
        model: zynqtgui.control.modpacks
        delegate: QQC2.Action {
            readonly property var theModPack: zynqtgui.control.modpacks[index]
            text: theModPack.display
            checked: zynqtgui.control.preferredModpack = theModPack.path
            onTriggered: {
                zynqtgui.control.preferredModpack = theModPack.path;
            }
        }
        onObjectAdded: {
            modPackPicker.actions.push(object);
        }
        onObjectRemoved: {
            modPackPicker.actions.pop(object);
        }
    }

    function showControlActions(control) {
        controlActions.control = control;
        controlActions.open();
    }
    ZUI2.ActionPickerPopup {
        id: controlActions
        property QtObject control: null
        property int oldLearnChannel: -1
        property int oldLearnCC: -1

        actions: [
            Kirigami.Action {
                text: controlActions.control !== null ? qsTr("Clear Midi Learn\nChannel %1 - CC %2").arg(controlActions.control.midiLearnChannel + 1).arg(controlActions.control.midiLearnCC) : ""
                enabled: controlActions.control !== null && controlActions.control.midiLearnChannel > -1
                onTriggered: {
                    controlActions.control.midi_unlearn();
                }
            },
            Kirigami.Action {
                text: qsTr("Midi Learn...")
                onTriggered: {
                    controlActions.oldLearnChannel = controlActions.control.midiLearnChannel;
                    controlActions.oldLearnCC = controlActions.control.midiLearnCC;
                    controlActions.control.init_midi_learn(controlActions.control);
                }
            }
        ]
    }
    Connections {
        target: zynqtgui
        onMidiLearnZctrlChanged: {
            if (zynqtgui.midiLearnZctrl) {
                midiLearner.open();
            } else {
                if (midiLearner.opened) {
                    midiLearner.close();
                }
            }
        }
    }
    ZUI2.DialogQuestion {
        id: midiLearner
        text: zynqtgui.midiLearnZctrl !== null ? qsTr("Learning %1\nWaiting for midi control change input...").arg(zynqtgui.midiLearnZctrl.shortName) : ""
        acceptText: ""
        rejectText: qsTr("Abort Midi Learn")
        onRejected: {
            let theControl = zynqtgui.midiLearnZctrl;
            zynqtgui.end_midi_learn();
            theControl.set_midi_learn(controlActions.oldLearnChannel, controlActions.oldLearnCC);
        }
    }
}
