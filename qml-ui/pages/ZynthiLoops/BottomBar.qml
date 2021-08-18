/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Marco MArtin <mart@kde.org>

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

Zynthian.Card {
    id: root
    enum ControlType {
        Song,
        Clip,
        Track,
        Part,
        None
    }

    property int controlType: BottomBar.ControlType.None
    property QtObject controlObj: null

    transform: Translate {
        y: Qt.inputMethod.visible ? -Kirigami.Units.gridUnit * 2 : 0
    }

    contentItem: ColumnLayout {

        RowLayout {
            Layout.fillWidth: true
            Layout.maximumHeight: Kirigami.Units.gridUnit * 2

            StackLayout {
                id: titleStack
                RowLayout {
                    Kirigami.Heading {
                        id: heading
                        text: {
                            let text = root.controlObj ? root.controlObj.name : "";
                            switch (root.controlType) {
                            case BottomBar.ControlType.Song:
                                return qsTr("SONG: %1").arg(text);
                            case BottomBar.ControlType.Clip:
                                return qsTr("CLIP: %1").arg(text);
                            case BottomBar.ControlType.Track:
                                return qsTr("TRACK: %1").arg(text);
                            case BottomBar.ControlType.Part:
                                return qsTr("PART: %1").arg(text);
                            default:
                                return text;
                            }
                        }
                        //Layout.fillWidth: true
                        wrapMode: Text.NoWrap
                    }
                    QQC2.Button {
                        icon.name: "document-edit"
                        visible: controlObj && controlObj.nameEditable
                        onClicked: {
                            titleStack.currentIndex = 1;
                            objNameEdit.text = root.controlObj ? root.controlObj.name : "";
                            objNameEdit.forceActiveFocus();
                        }
                        Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.medium*1.3)
                        Layout.preferredHeight: Layout.preferredWidth
                    }
                }
                QQC2.TextField {
                    id: objNameEdit
                    onAccepted: {
                        controlObj.name = text
                        titleStack.currentIndex = 0;
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            QQC2.Label {
                visible: root.controlType === Sidebar.ControlType.Clip
                text: {
                    if (!controlObj || !controlObj.path) {
                        return "";
                    }
                    var arr = controlObj.path.split('/')
                    return arr[arr.length - 1]
                }
            }
            QQC2.Label {
                visible: root.controlType === Sidebar.ControlType.Clip && controlObj.path.length > 0
                text: qsTr("Duration: %1 secs").arg(controlObj && controlObj.duration ? controlObj.duration.toFixed(2) : 0.0)
            }
        }

        Zynthian.TabbedControlView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            minimumTabsCount: 4
            orientation: Qt.Vertical
            tabActions: [
                Zynthian.TabbedControlViewAction {
                    text: qsTr("Wave")
                    page: Qt.resolvedUrl("WaveBar.qml")
                    initialProperties: {"bottomBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    text: qsTr("Editor")
                    page: Qt.resolvedUrl("EditorBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Clip
                    initialProperties: {"bottomBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    text: qsTr("FX")
                    page: Qt.resolvedUrl("FXBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Track
                    initialProperties: {"bottomBar": root}
                },
                Zynthian.TabbedControlViewAction {
                    text: qsTr("Info")
                    page: Qt.resolvedUrl("InfoBar.qml")
                    visible: root.controlType === BottomBar.ControlType.Clip
                    initialProperties: {"bottomBar": root}
                }
            ]
        }
    }

    QQC2.Dialog {
        id: pickerDialog
        parent: root.parent
        header: Kirigami.Heading {
            text: qsTr("Pick an audio file")
        }
        x: parent.width/2 - width/2
        y: parent.height/2 - height/2
        width: Math.round(parent.width * 0.8)
        height: Math.round(parent.height * 0.8)
        contentItem: QQC2.ScrollView {
            contentItem: ListView {
                model: FolderListModel {
                    id: folderModel
                    nameFilters: ["*.wav"]
                    folder: "/zynthian/zynthian-my-data/capture/"
                }
                delegate: Kirigami.BasicListItem {
                    label: model.fileName
                    onClicked: {
                        root.controlObj.path = model.filePath
                        pickerDialog.accept()
                    }
                }
            }
        }
    }
}
