/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Slot Swapper, for swapping the slots (sound sources or fx) on a sketchpad track

Copyright (C) 2023 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import QtQuick.Window 2.1
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.DialogQuestion {
    id: component
    function pickSlotToSwapWith(channel, slotType, slotIndex) {
        _private.swapWithSlotIndex = -1;
        _private.selectedChannel = channel;
        _private.slotIndex = slotIndex;
        _private.slotType = slotType;
        var newSlotTitles = [];
        switch(_private.slotType) {
            case "pattern":
                let sequenceModel = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName);
                for (let slotIndex = 0; slotIndex < 5; ++slotIndex) {
                    let patternModel = sequenceModel.sequence.getByPart(_private.selectedChannel.id, slotIndex);
                    if (patternModel.hasNotes) {
                        newSlotTitles.push(qsTr("Pattern %1%2").arg(_private.selectedChannel.id + 1).arg(patternModel.partName));
                    } else {
                        newSlotTitles.push(qsTr("Pattern %1%2 (empty)").arg(_private.selectedChannel.id + 1).arg(patternModel.partName));
                    }
                }
                newSlotTitles = [qsTr("Pattern 1"), qsTr("Pattern 2"), qsTr("Pattern 3"), qsTr("Pattern 4"), qsTr("Pattern 5")];
                break;
            case "synth":
                for (let slotIndex = 0; slotIndex < 5; ++slotIndex) {
                    let slotData = root.selectedChannel.chainedSoundsNames[slotIndex];
                    if (slotData === "") {
                        newSlotTitles.push("(empty)");
                    } else {
                        newSlotTitles.push(slotData);
                    }
                }
                break;
            case "sample":
                for (let slotIndex = 0; slotIndex < 5; ++slotIndex) {
                    let slotData = root.selectedChannel.samples[slotIndex];
                    if (slotData.path) {
                        newSlotTitles.push(slotData.path.split("/").pop());
                    } else {
                        newSlotTitles.push("(empty)");
                    }
                }
                break;
            case "sketch":
                for (let slotIndex = 0; slotIndex < 5; ++slotIndex) {
                    let slotData = root.selectedChannel.getClipsModelByPart(slotIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                    if (slotData.path) {
                        newSlotTitles.push(slotData.path.split("/").pop());
                    } else {
                        newSlotTitles.push("(empty)");
                    }
                }
                break;
            case "fx":
                for (let slotIndex = 0; slotIndex < 5; ++slotIndex) {
                    let slotData = root.selectedChannel.chainedFxNames[slotIndex];
                    if (slotData === "") {
                        newSlotTitles.push("(empty)");
                    } else {
                        newSlotTitles.push(slotData);
                    }
                }
                break;
            default:
                console.debug("Unknown slot type! Expected one of synth, sample, sketch, or fx, and got:", slotType);
                break;
        }
        _private.slotTitles = newSlotTitles;
        component.open();
    }

    onAccepted: {
        switch(_private.slotType) {
            case "pattern":
                let sequenceModel = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName);
                let swapThisPattern = sequenceModel.getByPart(_private.selectedChannel.id, _private.slotIndex);
                let swapThisData = swapThisPattern.toJson();
                let withThisPattern = sequenceModel.getByPart(_private.selectedChannel.id, slotIndex);
                let withThisData = withThisPattern.toJson();
                swapThisPattern.setFromJson(withThisData);
                withThisPattern.setFromJson(swapThisData);
                break;
            case "synth":
                _private.selectedChannel.swapSlots(_private.slotIndex, _private.swapWithSlotIndex, "synth");
                break;
            case "sample":
                _private.selectedChannel.swapSlots(_private.slotIndex, _private.swapWithSlotIndex, "sample-trig");
                break;
            case "sketch":
                _private.selectedChannel.swapSlots(_private.slotIndex, _private.swapWithSlotIndex, "sample-loop");
                break;
            case "fx":
                _private.selectedChannel.swapChainedFx(_private.slotIndex, _private.swapWithSlotIndex);
                break;
            default:
                console.debug("Unknown slot type!");
                break;
        }
    }

    height: Kirigami.Units.gridUnit * 10
    width: Kirigami.Units.gridUnit * 35

    acceptEnabled: _private.swapWithSlotIndex > -1
    acceptText: qsTr("Select")
    rejectText: qsTr("Back")
    title: qsTr("Pick the other slot...")

    contentItem: ColumnLayout {
        QtObject {
            id: _private
            property QtObject selectedChannel
            property string slotType
            property int slotIndex
            property int swapWithSlotIndex
            property var slotTitles: []
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Kirigami.Units.largeSpacing
            Repeater {
                model: _private.slotTitles
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                    QQC2.Button {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            bottom: parent.verticalCenter
                        }
                        text: modelData
                        checked: _private.swapWithSlotIndex === index
                    }
                    QQC2.Label {
                        anchors {
                            top: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        horizontalAlignment: Text.AlignHCenter
                        text: _private.slotIndex === index
                            ? qsTr("Swap this...")
                            : _private.swapWithSlotIndex === index
                                ? qsTr("...with this")
                                : ""
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (_private.slotIndex !== index) {
                                _private.swapWithSlotIndex = index;
                            }
                        }
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
