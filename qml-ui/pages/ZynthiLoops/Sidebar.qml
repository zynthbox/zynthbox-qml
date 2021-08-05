import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

Item {
    enum ControlType {
        Song,
        Clip,
        Track,
        Part,
        None
    }

    property alias heading: heading.text
    property alias bpm: bpmDial.value
    property alias length: lengthDial.value
    property int controlType: Sidebar.ControlType.None
    property QtObject controlObj: null
    property bool isPlaying: false

    Binding {
        target: bpmDial
        property: "value"
        value: controlObj && controlObj.bpm ? controlObj.bpm : 120
    }

    Binding {
        target: lengthDial
        property: "value"
        value: controlObj && controlObj.length ? controlObj.length : 1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            color: Kirigami.Theme.backgroundColor

            border.width: focus ? 1 : 0
            border.color: Kirigami.Theme.highlightColor

            Kirigami.Heading {
                id: heading
                anchors.centerIn: parent
                font.bold: true
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent

                SidebarDial {
                    id: bpmDial
                    visible: controlObj && controlObj.bpm ? true : false

                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 80
                    Layout.alignment: Qt.AlignHCenter

                    stepSize: 1
                    from: 0
                    to: 200

                    onValueChanged: {
                        if (controlObj && controlObj.bpm) {
                            controlObj.bpm = value
                        }
                    }
                }

                TableHeaderLabel {
                    Layout.alignment: Qt.AlignHCenter
                    text: "BPM"
                    visible: bpmDial.visible
                }

                SidebarDial {
                    id: lengthDial
                    visible: controlObj && controlObj.length ? true : false

                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 80
                    Layout.alignment: Qt.AlignHCenter

                    stepSize: 1
                    from: 1
                    to: 16

                    onValueChanged: {
                        if (controlObj && controlObj.length) {
                            controlObj.length = value
                        }
                    }
                }

                TableHeaderLabel {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Length"
                    visible: lengthDial.visible
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            Layout.maximumHeight: Layout.preferredHeight

            SidebarButton {
                Layout.fillWidth: true
                Layout.fillHeight: true

                icon.name: "media-playback-start"
                visible: !isPlaying &&
                         (controlType === Sidebar.ControlType.Track ||
                         controlType === Sidebar.ControlType.Clip ||
                         controlType === Sidebar.ControlType.Part)

                onClicked: {
                    zynthian.zynthiloops.playWav()
                    console.log("Playing Sound Loop")
                    isPlaying = true;
                }
            }

            SidebarButton {
                Layout.fillWidth: true
                Layout.fillHeight: true

                icon.name: "media-playback-stop"
                visible: isPlaying &&
                         (controlType === Sidebar.ControlType.Track ||
                         controlType === Sidebar.ControlType.Clip ||
                         controlType === Sidebar.ControlType.Part)

                onClicked: {
                    console.log("Stopping Sound Loop")
                    isPlaying = false;
                }
            }

            SidebarButton {
                Layout.fillWidth: true
                Layout.fillHeight: true

                icon.name: "media-record"
                visible: controlType === Sidebar.ControlType.Clip

                onClicked: {
                }
            }

            SidebarButton {
                Layout.fillWidth: true
                Layout.fillHeight: true

                icon.name: "delete"
                visible: controlType === Sidebar.ControlType.Track

                onClicked: {
                }
            }

            SidebarButton {
                Layout.fillWidth: true
                Layout.fillHeight: true

                icon.name: "edit-clear-all"
                visible: controlType !== Sidebar.ControlType.Clip ||
                         controlType !== Sidebar.ControlType.Part

                onClicked: {
                }
            }
        }
    }
}
