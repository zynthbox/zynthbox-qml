/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian layer setup dialog

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>

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
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls.Styles 1.4

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox


Zynthian.ActionPickerPopup {
    id: root
    property QtObject selectedChannel: null
    signal requestSlotPicker(QtObject channel, string slotType, int slotIndex)
    signal requestSlotInputPicker(QtObject channel, string slotType, int slotIndex)
    signal requestSlotEqualizer(QtObject channel, string slotType, int slotIndex)
    signal requestChannelKeyZoneSetup()

    Timer {
        id: selectedChannelThrottle
        interval: 10; running: false; repeat: false;
        onTriggered: {
            root.selectedChannel = applicationWindow().selectedChannel;
        }
    }
    Connections {
        target: applicationWindow()
        onSelectedChannelChanged: selectedChannelThrottle.restart()
    }
    Component.onCompleted: {
        selectedChannelThrottle.restart()
    }
    Zynthian.Popup {
        id: noFreeSlotsPopup
        parent: QQC2.Overlay.overlay
        y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
        x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
        width: Kirigami.Units.gridUnit*12
        height: Kirigami.Units.gridUnit*4

        QQC2.Label {
            width: parent.width
            height: parent.height
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: qsTr("No free slots remaining")
            font.italic: true
        }
    }

    columns: 3
    rows: 3
    property bool layerExists: root.selectedChannel ? root.selectedChannel.checkIfLayerExists(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow]) : false
    actions: [
        Kirigami.Action {
            text: qsTr("Pick a Synth")
            onTriggered: {
                Qt.callLater(function() {
                    if (root.layerExists) {
                        zynqtgui.layer.page_after_layer_creation = zynqtgui.current_screen_id
                        root.close()
                        zynqtgui.fixed_layers.activate_index(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow]);
                        zynqtgui.layer.select_engine(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow])
                    } else if (!root.selectedChannel.createChainedSoundInNextFreeLayer(root.selectedChannel.selectedSlotRow)) {
                        root.close();
                        noFreeSlotsPopup.open();
                    } else {
                        zynqtgui.layer.page_after_layer_creation = zynqtgui.current_screen_id
                        root.close()
                        zynqtgui.fixed_layers.activate_index(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow]);
                        zynqtgui.layer.select_engine(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow])
                    }
                })
            }
        },
        Kirigami.Action {
            text: qsTr("Load A Sound...")
            onTriggered: {
                zynqtgui.show_modal("sound_categories")
                root.close();
            }
        },
        Kirigami.Action {
            enabled: root.layerExists
            text: qsTr("Change Preset...")
            onTriggered: {
                zynqtgui.current_screen_id = "preset"
                root.close();
            }
        },
        Kirigami.Action {
            text: qsTr("Edit Sound...")
            onTriggered: {
                root.close();
                zynqtgui.show_modal("control")
            }
        },
        Kirigami.Action {
            enabled: root.layerExists
            text: "Set Input Overrides..."
            onTriggered: {
                root.requestSlotInputPicker(root.selectedChannel, "synth", root.selectedChannel.selectedSlotRow);
            }
        },
        Kirigami.Action {
            enabled: root.layerExists
            text: "Equalizer..."
            onTriggered: {
                root.requestSlotEqualizer(root.selectedChannel, "synth", root.selectedChannel.selectedSlotRow);
            }
        },
        Kirigami.Action {
            text: qsTr("Swap With Slot...")
            onTriggered: {
                root.requestSlotPicker(root.selectedChannel, "synth", root.selectedChannel.selectedSlotRow);
            }
        },
        Kirigami.Action {
            enabled: root.layerExists
            text: "Edit Keyzones..."
            onTriggered: {
                root.requestChannelKeyZoneSetup();
            }
        },
        Kirigami.Action {
            enabled: root.layerExists
            text: qsTr("Remove Synth")
            onTriggered: {
                root.close();
                if (root.layerExists) {
                    root.selectedChannel.remove_and_unchain_sound(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow])
                }
            }
        }
    ]
}
