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

    property int controlType: Sidebar.ControlType.None
    property QtObject controlObj: null

    transform: Translate {
        y: Qt.inputMethod.visible ? -Kirigami.Units.gridUnit * 4 : 0
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
                        text: root.controlObj ? root.controlObj.name : ""
                        //Layout.fillWidth: true
                        wrapMode: Text.NoWrap
                    }
                    QQC2.Button {
                        icon.name: "document-edit"
                        visible: controlObj && controlObj.nameEditable
                        onClicked: {
                            titleStack.currentIndex = 1;
                            objNameEdit.text = heading.text;
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


        RowLayout {
            Layout.fillWidth: true
            width: Math.min(parent.width, implicitWidth)

            SidebarDial {
                id: bpmDial
                text: qsTr("BPM")
                controlObj: root.controlObj
                controlProperty: "bpm"

                dial {
                    stepSize: 1
                    from: 50
                    to: 200
                }
            }

            SidebarDial {
                id: startDial
                text: qsTr("Start Position (msecs)")
                controlObj: root.controlObj
                controlProperty: "startPosition"
                valueString: Math.round(dial.value * 1000)

                dial {
                    stepSize: 0.001
                    from: 0
                    to: controlObj && controlObj.hasOwnProperty("duration") ? controlObj.duration : 0
                }
            }

            SidebarDial {
                id: lengthDial
                text: qsTr("Length (beats)")
                controlObj: root.controlObj
                controlProperty: "length"

                dial {
                    stepSize: 1
                    from: 1
                    to: 16
                }
            }

            SidebarDial {
                id: pitchDial
                text: qsTr("Pitch")
                controlObj: root.controlObj
                controlProperty: "pitch"

                dial {
                    stepSize: 1
                    from: -12
                    to: 12
                }
            }

            SidebarDial {
                id: timeDial
                text: qsTr("Time")
                controlObj: root.controlObj
                controlProperty: "time"

                dial {
                    stepSize: 1
                    from: 0
                    to: 200
                }
            }

            Item {
                Layout.fillWidth: true
            }

            GridLayout {
                columns: 2
                Layout.alignment: Qt.AlignBottom
                //Layout.maximumHeight: Kirigami.Units.iconSizes.large

                SidebarButton {
                    icon.name: "document-open"
                    visible: root.controlType === Sidebar.ControlType.Clip

                    onClicked: {
                        pickerDialog.open()
                    }
                }

                SidebarButton {
                    icon.name: "delete"
                    visible: (controlObj != null) && controlObj.deletable

                    onClicked: {
                    }
                }

                SidebarButton {
                    icon.name: "edit-clear-all"
                    visible: (controlObj != null) && controlObj.clearable

                    onClicked: controlObj.clear()
                }

                SidebarButton {
                    icon.name: controlObj.isPlaying ? "media-playback-stop" : "media-playback-start"
                    visible: (controlObj != null) && controlObj.playable

                    onClicked: {
                        if (controlObj.isPlaying) {
                            console.log("Stopping Sound Loop")
                            controlObj.stop();
                        } else {
                            console.log("Playing Sound Loop")
                            controlObj.play();
                        }
                    }
                }

                SidebarButton {
                    icon.name: "media-record"
                    visible: (controlObj != null) && controlObj.recordable

                    onClicked: {
                    }
                }
            }
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
