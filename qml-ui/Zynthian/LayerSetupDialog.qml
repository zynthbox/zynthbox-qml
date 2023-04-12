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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls.Styles 1.4

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox


Zynthian.Dialog {
    id: root

    property QtObject selectedChannel: applicationWindow().selectedChannel

    parent: QQC2.Overlay.overlay
    y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
    x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
    height: footer.implicitHeight + topMargin + bottomMargin
    modal: true

    onAccepted: {
    }
    onRejected: {
    }

    footer: QQC2.Control {
        leftPadding: root.leftPadding
        topPadding: root.topPadding
        rightPadding: root.rightPadding
        bottomPadding: root.bottomPadding
        contentItem: ColumnLayout {
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: qsTr("Pick a Synth")
                onPressed: {
                    Qt.callLater(function() {
                        if (root.selectedChannel.checkIfLayerExists(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow])) {
                            zynqtgui.layer.page_after_layer_creation = zynqtgui.current_screen_id
                            root.accept()
                            zynqtgui.fixed_layers.activate_index(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow]);
                            newSynthWorkaroundTimer.restart()
                            zynqtgui.layer.select_engine(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow])
                        } else if (!root.selectedChannel.createChainedSoundInNextFreeLayer(root.selectedChannel.selectedSlotRow)) {
                            root.reject();
                            noFreeSlotsPopup.open();
                        } else {
                            zynqtgui.layer.page_after_layer_creation = zynqtgui.current_screen_id
                            root.accept()
                            zynqtgui.fixed_layers.activate_index(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow]);
                            newSynthWorkaroundTimer.restart()
                            zynqtgui.layer.select_engine(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow])
                        }
                    })
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                visible: root.selectedChannel.checkIfLayerExists(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow])
                text: qsTr("Change preset")
                onClicked: {
                    zynqtgui.current_screen_id = "preset"
                    root.accept();
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: qsTr("Load A Sound")
                onClicked: {
                    zynqtgui.show_modal("sound_categories")
                    root.accept();
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                visible: root.selectedChannel.checkIfLayerExists(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow])
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                visible: root.selectedChannel.checkIfLayerExists(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow])
                text: qsTr("Remove Synth")
                onClicked: {
                    root.accept();
                    if (root.selectedChannel.checkIfLayerExists(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow])) {
                        root.selectedChannel.remove_and_unchain_sound(root.selectedChannel.chainedSounds[root.selectedChannel.selectedSlotRow])
                    }
                }
            }
            Timer { //HACK why is this necessary?
                id: newSynthWorkaroundTimer
                interval: 200
                onTriggered: {
                    if (root.selectedChannel.connectedPattern >= 0) {
                        var pattern = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName).getByPart(root.selectedChannel.id, root.selectedChannel.selectedPart);
                        pattern.midiChannel = root.selectedChannel.connectedSound;
                    }
                }
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
                    horizontalAlignment: "AlignHCenter"
                    verticalAlignment: "AlignVCenter"
                    text: qsTr("No free slots remaining")
                    font.italic: true
                }
            }
        }
    }
}
