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

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian

Zynthian.MultiSelectorPage {
    id: root
    backAction.visible: false
    contextualActions: [
        Kirigami.Action {
            text: qsTr("Layers")
            Kirigami.Action {
                text: qsTr("Load Sound...")
                onTriggered: {
                    pickerDialog.mode = "sound";
                    pickerDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Save Sound...")
                onTriggered: {
                    saveDialog.mode = "sound";
                    saveDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Load Soundset...")
                onTriggered: {
                    pickerDialog.mode = "soundset";
                    pickerDialog.open();
                }
            }
            Kirigami.Action {
                text: qsTr("Save Soundset...")
                onTriggered: {
                    saveDialog.mode = "soundset";
                    saveDialog.open();
                }
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
        property string mode: "sound"
        parent: root.parent
        header: Kirigami.Heading {
            text: saveDialog.mode === "soundset" ? qsTr("Save Soundset As...") : qsTr("Save Sound As...")
        }
        modal: true
        z: 999999999
        x: Math.round(parent.width/2 - width/2)
        y: Qt.inputMethod.visible ? Math.round(parent.height/5) : Math.round(parent.height/2 - height/2)
        width: Kirigami.Units.gridUnit * 15
        height: Kirigami.Units.gridUnit * 8
        onAccepted: {
            if (mode === "soundset") {
                zynthian.layer.save_soundset_to_file(fileName.text);
            } else { //Sound
                zynthian.layer.save_curlayer_to_file(fileName.text);
            }
        }
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
                fileName.forceActiveFocus();
                Qt.inputMethod.visible = true;
            }
        }
        contentItem: ColumnLayout {
            QQC2.TextField {
                id: fileName
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.6)
                onAccepted: {
                    if (fileName.text.length > 0) {
                        saveDialog.accept();
                    }
                }
                onTextChanged: fileCheckTimer.restart()
                Timer {
                    id: fileCheckTimer
                    interval: 300
                    onTriggered: {
                        if (saveDialog.mode === "soundset") {
                            conflictRow.visible = zynthian.layer.soundset_file_exists(fileName.text);
                        } else {
                            conflictRow.visible = zynthian.layer.layer_file_exists(fileName.text);
                        }
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
                            saveDialog.accept();
                        }
                    }
                }
            }
        }
    }
    QQC2.Dialog {
        id: pickerDialog
        parent: root.parent
        modal: true
        property string mode: "sound"
        header: Kirigami.Heading {
            text: pickerDialog.mode === "soundset" ? qsTr("Pick a Soundset file") : qsTr("Pick a Sound file")
        }
        x: Math.round(parent.width/2 - width/2)
        y: Math.round(parent.height/2 - height/2)
        width: Math.round(parent.width * 0.8)
        height: Math.round(parent.height * 0.8)
        contentItem: QQC2.ScrollView {
            contentItem: ListView {
                model: FolderListModel {
                    id: folderModel
                    nameFilters: ["*.json"]
                    folder: pickerDialog.mode === "soundset" ? "/zynthian/zynthian-my-data/soundsets/" : "/zynthian/zynthian-my-data/sounds/"
                }
                delegate: Kirigami.BasicListItem {
                    label: model.fileName
                    onClicked: {
                        if (pickerDialog.mode === "soundset") {
                            zynthian.layer.load_soundset_from_file(model.fileName)
                        } else {
                            zynthian.layer.load_layer_from_file(model.fileName)
                        }
                        pickerDialog.accept()
                    }
                }
            }
        }
    }
}


