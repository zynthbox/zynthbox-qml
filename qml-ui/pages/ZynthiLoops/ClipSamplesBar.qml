import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

Zynthian.Card {
    id: root

    property QtObject selectedTrack: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)
    property int selectedSampleRow: 0
    property QtObject bottomBar: null

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SELECT_UP":
                if (selectedSampleRow > 0) {
                    selectedSampleRow -= 1
                }
                return true;

            case "SELECT_DOWN":
                if (selectedSampleRow < 4) {
                    selectedSampleRow += 1
                }
                return true;

            case "SWITCH_BACK_SHORT":
                sceneActionBtn.checked = false;
                mixerActionBtn.checked = true;
                bottomStack.currentIndex = 1;

                return true;

            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
            case "SWITCH_SELECT_LONG":
                samplePickerDialog.folderModel.folder = samplePickerDialog.rootFolder;
                samplePickerDialog.open();

                return true;

            default:
                return false;
        }
    }

    padding: Kirigami.Units.gridUnit
    contentItem: ColumnLayout {
        anchors.margins: Kirigami.Units.gridUnit

        Repeater {
            model: 5
            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true

                border.width: selectedSampleRow === index ? 1 : 0
                border.color: Kirigami.Theme.highlightColor
                color: "transparent"
                radius: 4

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        selectedSampleRow = index;
                    }
                }

                RowLayout {
                    opacity: selectedSampleRow === index ? 1 : 0.5
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
                            text: controlObj.samples && controlObj.samples[index].path && controlObj.samples[index].path.length > 0
                                    ? controlObj.samples[index].path.split("/").pop()
                                    : ""

                            elide: "ElideRight"
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                if (selectedSampleRow !== index) {
                                    selectedSampleRow = index
                                } else {
                                    samplePickerDialog.folderModel.folder = controlObj.recordingDir;
                                    samplePickerDialog.open();
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
        }
    }

    Zynthian.FilePickerDialog {
        id: samplePickerDialog
        parent: zlScreen.parent

        width: parent.width
        height: parent.height
        x: parent.x
        y: parent.y

        headerText: qsTr("%1 : Pick an audio file").arg(controlObj ? controlObj.name : "")
        rootFolder: "/zynthian/zynthian-my-data"
        folderModel {
            nameFilters: ["*.wav"]
        }
        onFileSelected: {
            controlObj.set_sample(file.filePath, selectedSampleRow)
        }
    }
} 
