import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Qt.labs.folderlistmodel 2.11

Item {
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
/*
    Binding {
        target: bpmDial
        property: "value"
        value: controlObj && controlObj.bpm ? controlObj.bpm : 120
    }

    Binding {
        target: lengthDial
        property: "value"
        value: controlObj && controlObj.length ? controlObj.length : 1
    }*/

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            color: Kirigami.Theme.backgroundColor

            border.width: focus ? 1 : 0
            border.color: Kirigami.Theme.highlightColor
            StackLayout {
                id: titleStack
                anchors.centerIn: parent
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
        }

        QQC2.Label {
            Layout.fillWidth: true
            visible: root.controlType === Sidebar.ControlType.Clip
            text: {
                if (!controlObj || !controlObj.path) {
                    return "";
                }
                var arr = controlObj.path.split('/')
                return arr[arr.length - 1]
            }
            wrapMode: Text.Wrap
        }
        QQC2.Label {
            visible: root.controlType === Sidebar.ControlType.Clip
            text: qsTr("Duration: %1 secs").arg(controlObj && controlObj.duration ? controlObj.duration.toFixed(2) : 0.0)
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }


        ColumnLayout {
            Layout.alignment: Qt.AplignCenter
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
        }
        Item {
            Layout.fillHeight: true
        }


        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            Layout.maximumHeight: Layout.preferredHeight

            SidebarButton {
                Layout.fillWidth: true
                Layout.fillHeight: true

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
                Layout.fillWidth: true
                Layout.fillHeight: true

                icon.name: "media-record"
                visible: (controlObj != null) && controlObj.recordable

                onClicked: {
                }
            }

            SidebarButton {
                Layout.fillWidth: true
                Layout.fillHeight: true

                icon.name: "document-open"
                visible: root.controlType === Sidebar.ControlType.Clip

                onClicked: {
                    pickerDialog.open()
                }
            }

            SidebarButton {
                Layout.fillWidth: true
                Layout.fillHeight: true

                icon.name: "delete"
                visible: (controlObj != null) && controlObj.deletable

                onClicked: {
                }
            }

            SidebarButton {
                Layout.fillWidth: true
                Layout.fillHeight: true

                icon.name: "edit-clear-all"
                visible: (controlObj != null) && controlObj.clearable

                onClicked: controlObj.clear()
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
                        controlObj.path = model.filePath
                        pickerDialog.accept()
                    }
                }
            }
        }
    }
}
