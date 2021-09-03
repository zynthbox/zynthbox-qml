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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import JuceGraphics 1.0

Zynthian.ScreenPage {
    id: root

    readonly property QtObject song: zynthian.zynthiloops.song
    readonly property QtObject track: zynthian.track.track
    readonly property QtObject part: zynthian.track.part
    readonly property QtObject clip: track.clipsModel.getClip(zynthian.track.partId);

    screenId: "track"
    title: qsTr("%1 Details").arg(root.track.name)//zynthian.track.selector_path_element

    Component.onCompleted: zynthian.fixed_layers.activate_index(6)

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Layout.fillWidth: true
            Kirigami.Heading {
                level: 2
                text: root.song.name
                font.capitalization: Font.AllUppercase
            }
            QQC2.SpinBox {
                font: topSoundHeading.font
                from: 0
                to: 999
                value: root.song.bpm
                onValueModified: root.song.bpm = value
                textFromValue: function(value) {
                    return qsTr("%1 BPM").arg(value);
                }
            }
            QQC2.SpinBox {
                font: topSoundHeading.font
                from: 0
                to: root.song.partsModel.count - 1
                value: root.track.partId
                onValueModified: zynthian.track.partId = value
                textFromValue: function(value) {
                    return root.part.name
                }
            }
            QQC2.SpinBox {
                //font: topSoundHeading.font
                from: 1
                to: 999
                value: root.part.length
                onValueModified: root.part.length = value
                textFromValue: function(value) {
                    return qsTr("Length: %1 bars").arg(root.part.length)
                }
            }
            Item {
                Layout.fillWidth: true
            }
        }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Layout.fillWidth: true
            Zynthian.Card {
                id: trackCard
                Layout.fillWidth: true

                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing
                    RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        StackLayout {
                            id: titleStack
                            RowLayout {
                                QQC2.SpinBox {
                                    from: 0
                                    implicitWidth: trackTitle.implicitWidth + Kirigami.Units.gridUnit * 7
                                    implicitHeight: trackTitle.implicitHeight + topPadding + bottomPadding
                                    to: root.song.tracksModel.count - 1
                                    value: root.track.trackId
                                    onValueModified: zynthian.track.trackId = value
                                    contentItem: Kirigami.Heading {
                                        id: trackTitle
                                        //Layout.fillWidth: true
                                        wrapMode: Text.NoWrap
                                        text: root.track.name
                                    }
                                }
                                QQC2.Button {
                                    icon.name: "document-edit"
                                    onClicked: {
                                        titleStack.currentIndex = 1;
                                        trackNameEdit.text = root.track.name;
                                        trackNameEdit.forceActiveFocus();
                                    }
                                    Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.medium*1.3)
                                    Layout.preferredHeight: Layout.preferredWidth
                                }
                            }
                            QQC2.TextField {
                                id: trackNameEdit
                                onAccepted: {
                                    root.track.name = text
                                    titleStack.currentIndex = 0;
                                }
                            }
                        }

                        /*QQC2.Button {
                            id: midiButton
                            text: qsTr("MIDI")
                            checkable: true
                            autoExclusive: true
                        }
                        QQC2.Button {
                            text: qsTr("AUDIO")
                            checked: true
                            checkable: true
                            autoExclusive: true
                        }*/
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Repeater {
                            model: 5
                            delegate: ColumnLayout {
                                id: channelDelegate
                                readonly property int targetMidiChan: model.index + 5

                                Kirigami.Heading {
                                    id: topSoundHeading
                                    Layout.fillWidth: true
                                    text: qsTr("Voice %1").arg(index + 1)
                                    level: 2
                                    font.capitalization: Font.AllUppercase
                                }

                                /*QQC2.SpinBox {
                                    Layout.fillWidth: true
                                    font: topSoundHeading.font
                                    from: 0
                                    to: 5
                                    textFromValue: function(value) {
                                        return zynthian.fixed_layers.selector_list.data(zynthian.fixed_layers.selector_list.index(index+6, 0)).substring(3, 15)
                                    }
                                    onValueModified: {
                                        zynthian.layer.copy_midichan_layer(value, index+5);
                                    }
                                }*/
                                QQC2.ComboBox {
                                    id: voiceCombo
                                    Layout.fillWidth: true
                                    model: ListModel {
                                        id: filteredLayersModel
                                    }
                                    Component.onCompleted: {
                                        filteredLayersModel.append({"display": qsTr("None")});
                                        for (var i = 0; i < zynthian.fixed_layers.selector_list.count; ++i) {
                                            filteredLayersModel.append({"display": zynthian.fixed_layers.selector_list.data(zynthian.fixed_layers.selector_list.index(i, 0))})
                                        }
                                        voiceCombo.updateText();
                                    }
                                    function updateText() {
                                        let text = zynthian.fixed_layers.selector_list.data(zynthian.fixed_layers.selector_list.index(channelDelegate.targetMidiChan + 1, 0));
                                        text = text.substring(4);
                                        text = text.split(">")[1];
                                        if (text) {
                                            currentSoundName.text = text.length > 4 ? text : "";
                                        } else {
                                            currentSoundName.text = "";
                                        }
                                    }
                                    Connections {
                                        target: zynthian.fixed_layers
                                        onSpecial_layer_nameChanged: voiceCombo.updateText();
                                    }

                                    displayText: ""
                                    textRole: "display"
                                    onActivated: {
                                        if (index === 0) {
                                            zynthian.layer.remove_clone_midi(5, channelDelegate.targetMidiChan);
                                            zynthian.layer.remove_midichan_layer(channelDelegate.targetMidiChan);
                                            currentSoundName.text = ""
                                            zynthian.layer.ensure_special_layers_midi_cloned()
                                        } else {
                                            print("COPYING "+(index-1)+" "+ channelDelegate.targetMidiChan)
                                            zynthian.layer.copy_midichan_layer(index-1, channelDelegate.targetMidiChan);
                                            print("COPIED")
                                            zynthian.layer.ensure_special_layers_midi_cloned()

                                            let text = zynthian.fixed_layers.selector_list.data(zynthian.fixed_layers.selector_list.index(channelDelegate.targetMidiChan + 1, 0)).substring(4)
                                            text = text.split(">")[1];
                                            currentSoundName.text = text
                                        }
                                        zynthian.fixed_layers.activate_index(6)
                                        zynthian.zynthiloops.saveLayersToTrack(zynthian.track.trackId)
                                    }
                                    delegate: QQC2.MenuItem {
                                        text: model.display
                                        visible: index < 6 && model.display.indexOf("- -") === -1
                                        height: visible ? implicitHeight : 0
                                    }
                                    popup.width: Kirigami.Units.gridUnit * 15
                                }
                                QQC2.Label {
                                    id: currentSoundName
                                }
                            }
                        }
                        /*ColumnLayout {
                            enabled: false
                            Kirigami.Heading {
                                id: topSoundHeading
                                text: qsTr("Top Sound")
                                level: 2
                                font.capitalization: Font.AllUppercase
                            }
                            QQC2.SpinBox {
                                Layout.fillWidth: true
                                font: topSoundHeading.font
                            }
                        }
                        ColumnLayout {
                            enabled: midiButton.checked
                            Kirigami.Heading {
                                text: qsTr("Synth")
                                level: 2
                                font.capitalization: Font.AllUppercase
                            }
                            QQC2.SpinBox {
                                Layout.fillWidth: true
                                font: topSoundHeading.font
                                from: 0
                                to: zynthian.layer.selector_list.count
                                textFromValue: function(value) {
                                    return zynthian.layer.selector_list.data(zynthian.layer.selector_list.index(value, 0)).substring(0, 5)
                                }
                            }
                        }
                        ColumnLayout {
                            enabled: midiButton.checked
                            Kirigami.Heading {
                                text: qsTr("Bank")
                                level: 2
                                font.capitalization: Font.AllUppercase
                            }
                            QQC2.SpinBox {
                                Layout.fillWidth: true
                                font: topSoundHeading.font
                                from: 0
                                to: zynthian.bank.selector_list.count
                                textFromValue: function(value) {
                                    return zynthian.bank.selector_list.data(zynthian.bank.selector_list.index(value, 0)).substring(0, 5)
                                }
                            }
                        }
                        ColumnLayout {
                            enabled: midiButton.checked
                            Kirigami.Heading {
                                text: qsTr("Preset")
                                level: 2
                                font.capitalization: Font.AllUppercase
                            }
                            QQC2.SpinBox {
                                Layout.fillWidth: true
                                font: topSoundHeading.font
                                from: 0
                                to: zynthian.preset.selector_list.count
                                textFromValue: function(value) {
                                    return zynthian.preset.selector_list.data(zynthian.preset.selector_list.index(value, 0)).substring(0, 5)
                                }
                            }
                        }*/
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        QQC2.Label {
                            text: metadataRepeater.count === 0 ? qsTr("No Metadata") : qsTr("Metadata:")
                        }
                        Repeater {
                            id: metadataRepeater
                            model: root.track.soundData

                            delegate: QQC2.Label {
                                Layout.alignment: Qt.AlignRight
                                text: (index > 0 ? ", " : "") + qsTr("Voice %1: %2").arg(modelData.midi_chan - 4).arg(modelData.preset_name)
                            }
                        }
                        QQC2.Button {
                            id: midiButton
                            text: qsTr("Load Voices")
                            visible: metadataRepeater.count > 0
                            onClicked: {
                                zynthian.zynthiloops.restoreLayersFromTrack(zynthian.track.trackId)
                                zynthian.layer.ensure_special_layers_midi_cloned()
                                zynthian.fixed_layers.activate_index(6)
                            }
                        }
                    }
                }
            }

            Zynthian.Card {
                //Layout.fillHeight: true
                Layout.preferredHeight: trackCard.height
                contentItem: ColumnLayout {
                    QQC2.ToolButton {
                        Layout.alignment: Qt.AlignCenter
                        icon.name: root.clip.isRecording ? "media-playback-stop" : "media-record-symbolic"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.large
                        Layout.preferredHeight: Layout.preferredWidth
                        onClicked: {
                            if (root.clip.isRecording) {
                                root.clip.clear();
                                root.clip.queueRecording();
                            } else {
                                root.clip.stopRecording();
                            }
                        }
                    }
                    QQC2.ComboBox {
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            ListElement { text: "None" }
                            ListElement { text: "Playgrid" }
                        }
                    }
                }
            }
        }


        WaveFormItem {
            id: wav
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Kirigami.Theme.textColor
            source: root.clip.path
        }
    }
}
