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
import ZynthiLoops 1.0 as ZynthiLoops

Zynthian.ScreenPage {
    screenId: "track"
    ZynthiLoops.Song {
        id: song
        index: 0
    }
    contentItem: ColumnLayout {
		spacing: Kirigami.Units.largeSpacing
        RowLayout {
			spacing: Kirigami.Units.largeSpacing
            Layout.fillWidth: true
            Kirigami.Heading {
                level: 2
                text: qsTr("Song %1").arg(song.index + 1)
                font.capitalization: Font.AllUppercase
            }
            QQC2.SpinBox {
                font: topSoundHeading.font
                from: 0
                to: 999
                value: song.bpm
                onValueModified: song.bpm = value
                textFromValue: function(value) {
					return qsTr("%1 BPM").arg(value);
				}
            }
            Kirigami.Heading {
                level: 2
                text: qsTr("PART 01")
                font.capitalization: Font.AllUppercase
            }
            Kirigami.Heading {
                level: 2
                text: qsTr("Length: %1 bars").arg()
            }
            Item {
                Layout.fillWidth: true
            }
        }
        Repeater {
			model: song.tracksModel
			delegate: RowLayout {
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
									Kirigami.Heading {
										//Layout.fillWidth: true
										text: model.name
									}
									QQC2.ToolButton {
										icon.name: "document-edit"
										onClicked: titleStack.currentIndex = 1;
									}
								}
								QQC2.TextField {
									onAccepted: titleStack.currentIndex = 0;
									onActiveFocusChanged: {
										if(activeFocus) {
											Qt.inputMethod.update(Qt.ImQueryInput)
										}
									}
								}
							}
							QQC2.Button {
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
							}
						}
						RowLayout {
							Layout.fillWidth: true
							ColumnLayout {
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
							}
						}
					}
				}

				Zynthian.Card {
					//Layout.fillHeight: true
					Layout.preferredHeight: trackCard.height
					contentItem: ColumnLayout {
						Kirigami.Icon {
							Layout.alignment: Qt.AlignCenter
							source: "media-record"
							Layout.preferredWidth: Kirigami.Units.iconSizes.large
							Layout.preferredHeight: Layout.preferredWidth
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
		}
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
