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

Zynthian.MultiSelectorPage {
    id: root
    backAction.visible: false
    contextualActions: [
        Kirigami.Action {
            text: qsTr("Layers")
            Kirigami.Action {
                text: qsTr("Save Soundset...")
                onTriggered: saveDialog.open()
            }
            Kirigami.Action {
                text: qsTr("Remove Layer")
                onTriggered: zynthian.layer.ask_remove_current_layer()
            }
            Kirigami.Action {
                text: qsTr("Remove All")
                onTriggered: zynthian.layer.ask_reset()
            }
        },
        Kirigami.Action {
            text: qsTr("Synths")
            onTriggered: zynthian.layer.select_engine()
        },
        Kirigami.Action {
            text: qsTr("Audio-FX")
            onTriggered: {
                zynthian.layer_options.show(); //FIXME: that show() method should change name
                zynthian.current_screen_id = "layer_effects";
            }
        },
        Kirigami.Action {
            text: qsTr("Edit")
            onTriggered: zynthian.current_screen_id = "control"
        }
    ]

    screenIds: ["fixed_layers", "bank", "preset"]
    screenTitles: [qsTr("Layers (%1)").arg(zynthian.layer.effective_count || qsTr("None")), qsTr("Banks (%1)").arg(zynthian.bank.selector_list.count), qsTr("Presets (%1)").arg(zynthian.preset.selector_list.count)]
    previousScreen: "main"
    onCurrentScreenIdRequested: zynthian.current_screen_id = screenId

    QQC2.Dialog {
        id: saveDialog
        parent: root.parent
        header: Kirigami.Heading {
            text: qsTr("Save Soundset As...")
        }
        modal: true
        z: 999999999
        x: Math.round(parent.width/2 - width/2)
        y: Qt.inputMethod.visible ? Math.round(parent.height/5) : Math.round(parent.height/2 - height/2)
        width: Kirigami.Units.gridUnit * 15
        height: Kirigami.Units.gridUnit * 8
        onVisibleChanged : {
			cancelSaveButton.forceActiveFocus();
            if (visible) {
                delayKeyboardTimer.restart()
            } else {
                fileName.text = "";
            }
        }
        Timer {
            id: delayKeyboardTimer
            interval: 300
            onTriggered: {
				fileName.forceActiveFocus()
				Qt.inputMethod.setVisible(true);
			}
        }
        contentItem: ColumnLayout {
            QQC2.TextField {
                id: fileName
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.6)
                onAccepted: {
                    if (fileName.text.length > 0 && !zynthian.layer.snapshot_file_exists(fileName.text)) {
                        zynthian.layer.save_soundset_to_file(fileName.text);
                        saveDialog.close();
                    }
                }
                onTextChanged: fileCheckTimer.restart()
                Timer {
                    id: fileCheckTimer
                    interval: 300
                    onTriggered: {
                        conflictRow.visible = zynthian.layer.snapshot_file_exists(fileName.text)
                    }
                }
            }
            RowLayout {
                id: conflictRow
                visible: false
                QQC2.Label {
                    Layout.fillWidth: true
                    text: qsTr("File exists")
                }
            }
        }
        footer: QQC2.Control {
            leftPadding: saveDialog.leftPadding
            topPadding: Kirigami.Units.smallSpacing
            rightPadding: saveDialog.rightPadding
            bottomPadding: saveDialog.bottomPadding
            contentItem: RowLayout {
                Layout.fillWidth: true
                QQC2.Button {
					id: cancelSaveButton
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    text: qsTr("Cancel")
                    onClicked: {
                            saveDialog.close();
                        }
                    }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    text: conflictRow.visible ? qsTr("Overwrite") : qsTr("Save")
                    enabled: fileName.text.length > 0
                    onClicked: {
                        if (fileName.text.length > 0) {
                            zynthian.layer.save_soundset_to_file(fileName.text)
                            saveDialog.close();
                        }
                    }
                }
            }
        }
    }
}


