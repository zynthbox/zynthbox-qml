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

    readonly property QtObject song: zynthian.sketchpad.song
    readonly property QtObject channel: zynthian.channel.channel
    readonly property QtObject part: zynthian.channel.part
    readonly property QtObject clip: channel.clipsModel.getClip(zynthian.channel.partId);

    screenId: "channel"
    title: qsTr("%1 Details").arg(root.channel.name)//zynthian.channel.selector_path_element

    //Component.onCompleted: zynthian.fixed_layers.activate_index(6)

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
                value: root.channel.partId
                onValueModified: zynthian.channel.partId = value
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
                id: channelCard
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
                                    implicitWidth: channelTitle.implicitWidth + Kirigami.Units.gridUnit * 7
                                    implicitHeight: channelTitle.implicitHeight + topPadding + bottomPadding
                                    to: root.song.channelsModel.count - 1
                                    value: root.channel.channelId
                                    onValueModified: zynthian.channel.channelId = value
                                    contentItem: Kirigami.Heading {
                                        id: channelTitle
                                        //Layout.fillWidth: true
                                        wrapMode: Text.NoWrap
                                        text: root.channel.name
                                    }
                                }
                                QQC2.Button {
                                    icon.name: "document-edit"
                                    onClicked: {
                                        titleStack.currentIndex = 1;
                                        channelNameEdit.text = root.channel.name;
                                        channelNameEdit.forceActiveFocus();
                                    }
                                    Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.medium*1.3)
                                    Layout.preferredHeight: Layout.preferredWidth
                                }
                            }
                            QQC2.TextField {
                                id: channelNameEdit
                                onAccepted: {
                                    root.channel.name = text
                                    titleStack.currentIndex = 0;
                                }
                            }
                        }

                        QQC2.Button {
                            id: midiButton
                            text: qsTr("Load Voices")
                            onClicked: {
                                zynthian.sketchpad.restoreLayersFromChannel(zynthian.channel.channelId)
                                //zynthian.fixed_layers.activate_index(6)
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

                                        for (var i in root.channel.soundData) {
                                            let data = root.channel.soundData[i];
                                            if (data.midi_chan === channelDelegate.targetMidiChan) {
                                                currentSoundName.text = data.preset_name;
                                                return;
                                            }
                                            currentSoundName.text = "";
                                        }
                                    }
                                    Connections {
                                        target: zynthian.fixed_layers
                                        onSpecial_layer_nameChanged: voiceCombo.updateText();
                                    }
                                    Connections {
                                        target: root
                                        onChannelChanged: voiceCombo.updateText();
                                    }

                                    displayText: ""
                                    textRole: "display"
                                    onActivated: {
                                        if (index === 0) {
                                            zynthian.layer.remove_clone_midi(5, channelDelegate.targetMidiChan);
                                            zynthian.layer.remove_midichan_layer(channelDelegate.targetMidiChan);
                                            voiceCombo.updateText()
                                        } else {
                                            print("COPYING "+(index-1)+" "+ channelDelegate.targetMidiChan)
                                            zynthian.layer.copy_midichan_layer(index-1, channelDelegate.targetMidiChan);
                                            print("COPIED")

                                            voiceCombo.updateText()
                                        }
                                        //zynthian.fixed_layers.activate_index(6)
                                        zynthian.sketchpad.saveLayersToChannel(zynthian.channel.channelId)
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
                }
            }

            Zynthian.Card {
                //Layout.fillHeight: true
                Layout.preferredHeight: channelCard.height
                contentItem: ColumnLayout {
                    QQC2.ToolButton {
                        Layout.alignment: Qt.AlignCenter
                        icon.name: zynthian.sketchpad.isRecording ? "media-playback-stop" : "media-record-symbolic"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.large
                        Layout.preferredHeight: Layout.preferredWidth
                        onClicked: {
                            if (!zynthian.sketchpad.isRecording) {
                                root.clip.clear();
                                root.clip.queueRecording();
                                Zynthian.CommonUtils.startMetronomeAndPlayback();
                            } else {
                                root.clip.stopRecording();
                            }
                        }
                    }
                    QQC2.ComboBox {
                        id: sourceCombo

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: sourceComboModel

                            ListElement { text: "Internal (Active Layer)"; value: "internal" }
                            ListElement { text: "External (Audio In)"; value: "external" }
                        }
                        textRole: "text"
                        onActivated: {
                            zynthian.sketchpad.recordingSource = sourceComboModel.get(index).value
                        }
                    }
                    QQC2.ComboBox {
                        id: channelCombo

                        enabled: sourceCombo.currentIndex === 1
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignCenter
                        model: ListModel {
                            id: channelComboModel

                            ListElement { text: "Left Channel"; value: "1" }
                            ListElement { text: "Right Channel"; value: "2" }
                        }
                        textRole: "text"
                        onActivated: {
                            zynthian.sketchpad.recordingChannel = channelComboModel.get(index).value
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
