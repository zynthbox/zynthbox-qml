import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.Card {
    id: root

    property QtObject selectedChannel: zynqtgui.sketchpad.song.channelsModel.getChannel(zynqtgui.sketchpad.selectedTrackId)
    property QtObject controlObj: zynqtgui.bottomBarControlObj

    function cuiaCallback(cuia) {
        if (samplePickerDialog.opened) {
            return samplePickerDialog.cuiaCallback(cuia);
        }

        switch (cuia) {
            case "SELECT_UP":
                if (controlObj.selectedSlotRow > 0) {
                    controlObj.selectedSlotRow -= 1
                }
                return true;

            case "SELECT_DOWN":
                if (controlObj.selectedSlotRow < 4) {
                    controlObj.selectedSlotRow += 1
                }
                return true;

            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.channelButton.checked = true
                return true;

            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
            case "SWITCH_SELECT_LONG":
                samplePickerDialog.folderModel.folder = samplePickerDialog.rootFolder;
                samplePickerDialog.open();

                return true;
        }
        
        return false;
    }

    padding: Kirigami.Units.gridUnit
    contentItem: ColumnLayout {
        anchors.margins: Kirigami.Units.gridUnit

        Repeater {
            model: 5
            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true

                border.width: controlObj.selectedSlotRow === index ? 1 : 0
                border.color: Kirigami.Theme.highlightColor
                color: "transparent"
                radius: 4

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        controlObj.selectedSlotRow = index;
                    }
                }

                RowLayout {
                    opacity: controlObj.selectedSlotRow === index ? 1 : 0.5
                    anchors.fill: parent

                    QQC2.Label {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredHeight: parent.height < Kirigami.Units.gridUnit*2 ? Kirigami.Units.gridUnit*1.3 : Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: Kirigami.Units.gridUnit
                        text: qsTr("Sample (%1)").arg(index+1)
                    }

                    Rectangle {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*20
                        Layout.preferredHeight: parent.height < Kirigami.Units.gridUnit*2 ? Kirigami.Units.gridUnit*1.3 : Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: Kirigami.Units.gridUnit
                        Layout.rightMargin: Kirigami.Units.gridUnit

                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: Kirigami.Theme.backgroundColor

                        border.color: "#ff999999"
                        border.width: 1
                        radius: 4

                        QQC2.Label {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                right: parent.right
                                leftMargin: Kirigami.Units.gridUnit*0.5
                                rightMargin: Kirigami.Units.gridUnit*0.5
                            }
                            horizontalAlignment: Text.AlignLeft
                            text: controlObj.samples && !controlObj.samples[index].isEmpty
                                    ? controlObj.samples[index].path.split("/").pop()
                                    : ""

                            elide: "ElideRight"
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                if (controlObj.selectedSlotRow !== index) {
                                    controlObj.selectedSlotRow = index
                                } else {
                                    samplePickerDialog.folderModel.folder = controlObj.recordingDir;
                                    samplePickerDialog.open();
                                }
                            }
                        }
                    }

                    QQC2.Button {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*1.5
                        Layout.preferredHeight: Kirigami.Units.gridUnit*1.5

                        enabled: (controlObj.samples !== undefined && !zynqtgui.sketchpad.isRecording)
                        icon.name: controlObj.samples !== undefined && zynqtgui.sketchpad.isRecording ? "media-playback-stop" : "media-record-symbolic"
                        onClicked: {
                            applicationWindow().openRecordingPopup()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }

    Zynthian.FilePickerDialog {
        id: samplePickerDialog
        parent: zlScreen.parent

        headerText: qsTr("%1 : Pick an audio file").arg(controlObj ? controlObj.name : "")
        rootFolder: "/zynthian/zynthian-my-data"
        folderModel {
            nameFilters: ["*.wav"]
        }
        onAccepted: {
            controlObj.set_sample(samplePickerDialog.selectedFile.filePath, controlObj.selectedSlotRow)
        }
    }
} 
