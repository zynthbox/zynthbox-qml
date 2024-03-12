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
    function pickSlotInputs(channel, slotType, slotIndex) {
        _private.slotIndex = slotIndex;
        _private.slotType = slotType;
        _private.selectedChannel = channel;
        _private.displayedSection = 0;
        component.open();
    }

    onAccepted: {
        _private.selectedChannel = null;
    }

    height: Kirigami.Units.gridUnit * 30
    width: Kirigami.Units.gridUnit * 35

    acceptText: qsTr("Close")
    rejectText: ""
    title: _private.engineData === null ? "" : qsTr("Select Inputs for %1").arg(_private.engineData.name)

    ColumnLayout {
        anchors {
            fill: parent
            margins: Kirigami.Units.largeSpacing
        }
        QtObject {
            id: _private
            property QtObject selectedChannel
            property string slotType
            property int slotIndex
            property int displayedSection: 0
            property QtObject engineData: selectedChannel === null
                ? null
                : slotType === "synth"
                    ? selectedChannel.synthRoutingData[slotIndex]
                    : slotType === "fx"
                        ? selectedChannel.fxRoutingData[slotIndex]
                        : null
        }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: _private.selectedChannel === null ? "" : qsTr("Use this dialog to override the default routing for this slot. If you leave this alone, the routing is defined by the Routing option on the Track view (which is currently set to %1 for Track %2). This is useful to be able to do for things like vocoders and other effects which modulate one sound with another.").arg(_private.selectedChannel.channelRoutingStyleName).arg(_private.selectedChannel.name)
        }
        RowLayout {
            Layout.fillWidth: true
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 15
                text: qsTr("Audio Inputs")
                checked: _private.displayedSection === 0
                visible: _private.engineData ? _private.engineData.audioInPorts.length > 0 : false
                MouseArea { anchors.fill: parent; onClicked: parent.onClicked(); }
                onClicked: {
                    _private.displayedSection = 0;
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 15
                text: qsTr("MIDI Inputs")
                checked: _private.displayedSection === 1
                visible: _private.engineData ? _private.engineData.midiInPorts.length > 0 : false
                MouseArea { anchors.fill: parent; onClicked: parent.onClicked(); }
                onClicked: {
                    _private.displayedSection = 1;
                }
            }
        }
        ColumnLayout {
            visible: _private.displayedSection === 0
            Layout.fillWidth: true
            Zynthian.ComboBox {
                id: sourceComboBox
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: false
                model: Zynthbox.MidiRouter.model.audioInSources
                function pickSource(port, source) {
                    sourceComboBox.port = port;
                    sourceComboBox.source = source;
                    if (sourceComboBox.source) {
                        sourceComboBox.selectIndex(Zynthbox.MidiRouter.model.audioInSourceIndex(source.port));
                    } else {
                        sourceComboBox.selectIndex(-1);
                    }
                    sourceComboBox.onClicked();
                }
                textRole: "text"
                property QtObject port: null
                property QtObject source: null
                onActivated: {
                    let listElement = sourceComboBox.model[index];
                    if (sourceComboBox.source === null) {
                        sourceComboBox.port.addSource(listElement.value, listElement.text);
                    } else {
                        sourceComboBox.source.port = listElement.value;
                        sourceComboBox.source.name = listElement.text;
                    }
                    sourceComboBox.source = null;
                }
            }
            Repeater {
                id: portRepeater
                model: _private.engineData === null ? 0 : _private.engineData.audioInPorts
                delegate: RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 10 // Just making these the same height, because that's kind of nice
                    ColumnLayout {
                        id: portDelegate
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 25
                        property QtObject port: modelData
                        property var sources: modelData.sources
                        Repeater {
                            id: sourceRepeater
                            model: 5 // let's not go wild, stop people adding more than five sources
                            delegate: RowLayout {
                                id: sourceDelegate
                                property QtObject source: portDelegate.sources.length > model.index ? portDelegate.sources[model.index] : null
                                Layout.fillWidth: true
                                visible: sourceDelegate.source !== null || model.index === portDelegate.sources.length
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: sourceDelegate.source === null
                                        ? qsTr("Tap to select a source")
                                        : sourceDelegate.source.name
                                    onClicked: {
                                        sourceComboBox.pickSource(portDelegate.port, sourceDelegate.source);
                                    }
                                }
                                QQC2.Button {
                                    Layout.fillHeight: true
                                    visible: sourceDelegate.source
                                    icon.name: "edit-clear-symbolic"
                                    onClicked: {
                                        portDelegate.port.removeSource(model.index);
                                    }
                                }
                                QQC2.Label {
                                    Layout.fillHeight: true
                                    text: "🡢"
                                }
                            }
                        }
                    }
                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        text: modelData.name
                        MouseArea { anchors.fill: parent; onClicked: {} }
                    }
                }
            }
        }
        ColumnLayout {
            visible: _private.displayedSection === 1
            Layout.fillWidth: true
            Zynthian.ComboBox {
                id: midiSourceComboBox
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: false
                model: Zynthbox.MidiRouter.model.midiInSources
                function pickSource(port, source) {
                    midiSourceComboBox.port = port;
                    midiSourceComboBox.source = source;
                    if (midiSourceComboBox.source) {
                        midiSourceComboBox.selectIndex(Zynthbox.MidiRouter.model.midiInSourceValue(source.port));
                    } else {
                        midiSourceComboBox.selectIndex(-1);
                    }
                    midiSourceComboBox.onClicked();
                }
                textRole: "text"
                property QtObject port: null
                property QtObject source: null
                onActivated: {
                    let listElement = midiSourceComboBox.model[index];
                    if (midiSourceComboBox.source === null) {
                        midiSourceComboBox.port.addSource(listElement.value, listElement.text);
                    } else {
                        midiSourceComboBox.source.port = listElement.value;
                        midiSourceComboBox.source.name = listElement.text;
                    }
                    midiSourceComboBox.source = null;
                }
            }
            Repeater {
                id: midiPortRepeater
                model: _private.engineData === null ? 0 : _private.engineData.midiInPorts
                delegate: RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 10 // Just making these the same height, because that's kind of nice
                    ColumnLayout {
                        id: midiPortDelegate
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 25
                        property QtObject port: modelData
                        property var sources: port.sources
                        Repeater {
                            id: midiSourceRepeater
                            model: 5 // let's not go wild, stop people adding more than five sources
                            delegate: RowLayout {
                                id: midiSourceDelegate
                                property QtObject source: midiPortDelegate.sources.length > model.index ? midiPortDelegate.sources[model.index] : null
                                Layout.fillWidth: true
                                visible: midiSourceDelegate.source !== null || model.index === midiPortDelegate.sources.length
                                QQC2.Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: midiSourceDelegate.source === null
                                        ? qsTr("Tap to select a source")
                                        : midiSourceDelegate.source.name
                                    onClicked: {
                                        midiSourceComboBox.pickSource(midiPortDelegate.port, midiSourceDelegate.source);
                                    }
                                }
                                QQC2.Button {
                                    Layout.fillHeight: true
                                    visible: midiSourceDelegate.source && midiSourceDelegate.source.port.length > 0
                                    icon.name: "edit-clear-symbolic"
                                    onClicked: {
                                        midiPortDelegate.port.removeSource(model.index);
                                    }
                                }
                                QQC2.Label {
                                    Layout.fillHeight: true
                                    text: "🡢"
                                }
                            }
                        }
                    }
                    QQC2.Button {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        text: modelData.name
                        MouseArea { anchors.fill: parent; onClicked: {} }
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
