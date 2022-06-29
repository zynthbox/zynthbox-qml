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
import org.zynthian.quick 1.0 as ZynQuick


QQC2.Dialog {
    id: root

    property QtObject selectedTrack: applicationWindow().selectedTrack

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
                        if (root.selectedTrack.checkIfLayerExists(root.selectedTrack.chainedSounds[root.selectedTrack.selectedSlotRow])) {
                            zynthian.layer.page_after_layer_creation = zynthian.current_screen_id
                            root.accept()
                            zynthian.fixed_layers.activate_index(root.selectedTrack.chainedSounds[root.selectedTrack.selectedSlotRow]);
                            newSynthWorkaroundTimer.restart()
                            zynthian.layer.select_engine(root.selectedTrack.chainedSounds[root.selectedTrack.selectedSlotRow])
                        } else if (!root.selectedTrack.createChainedSoundInNextFreeLayer(root.selectedTrack.selectedSlotRow)) {
                            root.reject();
                            noFreeSlotsPopup.open();
                        } else {
                            zynthian.layer.page_after_layer_creation = zynthian.current_screen_id
                            root.accept()
                            zynthian.fixed_layers.activate_index(root.selectedTrack.chainedSounds[root.selectedTrack.selectedSlotRow]);
                            newSynthWorkaroundTimer.restart()
                            zynthian.layer.select_engine(root.selectedTrack.chainedSounds[root.selectedTrack.selectedSlotRow])
                        }
                    })
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                visible: root.selectedTrack.checkIfLayerExists(root.selectedTrack.chainedSounds[root.selectedTrack.selectedSlotRow])
                text: qsTr("Change preset")
                onClicked: {
                    zynthian.current_screen_id = "preset"
                    root.accept();
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: qsTr("Load A Sound")
                onClicked: {
                    zynthian.show_modal("sound_categories")
                    root.accept();
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                visible: root.selectedTrack.checkIfLayerExists(root.selectedTrack.chainedSounds[root.selectedTrack.selectedSlotRow])
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                visible: root.selectedTrack.checkIfLayerExists(root.selectedTrack.chainedSounds[root.selectedTrack.selectedSlotRow])
                text: qsTr("Remove Synth")
                onClicked: {
                    root.accept();
                    if (root.selectedTrack.checkIfLayerExists(root.selectedTrack.chainedSounds[root.selectedTrack.selectedSlotRow])) {
                        root.selectedTrack.remove_and_unchain_sound(root.selectedTrack.chainedSounds[root.selectedTrack.selectedSlotRow])
                    }
                }
            }
            Timer { //HACK why is this necessary?
                id: newSynthWorkaroundTimer
                interval: 200
                onTriggered: {
                    if (root.selectedTrack.connectedPattern >= 0) {
                        var pattern = ZynQuick.PlayGridManager.getSequenceModel(zynthian.zynthiloops.song.scenesModel.selectedMixName).getByPart(root.selectedTrack.id, root.selectedTrack.selectedPart);
                        pattern.midiChannel = root.selectedTrack.connectedSound;
                    }
                }
            }
            QQC2.Popup {
                id: noFreeSlotsPopup
                parent: QQC2.Overlay.overlay
                y: parent.mapFromGlobal(0, Math.round(parent.height/2 - height/2)).y
                x: parent.mapFromGlobal(Math.round(parent.width/2 - width/2), 0).x
                width: Kirigami.Units.gridUnit*12
                height: Kirigami.Units.gridUnit*4
                modal: true

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
