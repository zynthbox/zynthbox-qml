import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

Zynthian.Card {
    id: root

    property int selectedRowIndex: 0
    property QtObject selectedTrack: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SELECT_UP":
                if (root.selectedRowIndex > 0) {
                    root.selectedRowIndex -= 1
                    return true;
                } else {
                    return false;
                }

            case "SELECT_DOWN":
                if (root.selectedRowIndex < 4) {
                    root.selectedRowIndex += 1
                    return true;
                } else {
                    return false;
                }

            default:
                return false;
        }
    }

    padding: Kirigami.Units.gridUnit
    contentItem: ColumnLayout {
        anchors.margins: Kirigami.Units.gridUnit

        Repeater {
            model: root.selectedTrack.chainedSounds
            delegate: Rectangle {
                id: soundDelegate

                property int chainedSound: modelData

                Layout.fillWidth: true
                Layout.fillHeight: true

                border.width: root.selectedRowIndex === index ? 1 : 0
                border.color: Kirigami.Theme.highlightColor
                color: "transparent"
                radius: 4

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.selectedRowIndex = index;
                    }
                }

                RowLayout {
                    opacity: root.selectedRowIndex === index ? 1 : 0.5
                    anchors.fill: parent

                    Rectangle {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*12
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
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
                            text: root.selectedTrack.getLayerNameByMidiChannel(modelData)

                            elide: "ElideRight"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.selectedRowIndex !== index) {
                                    root.selectedRowIndex = index;
                                } else {
                                    if (soundDelegate.chainedSound >= 0) {
                                        // Open library page
                                    } else {
                                        root.selectedTrack.createChainedSoundInNextFreeLayer(index);
                                    }
                                }
                            }
                        }
                    }

                    QQC2.RoundButton {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*2
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        enabled: root.selectedRowIndex === index

                        Kirigami.Icon {
                            width: Math.round(Kirigami.Units.gridUnit)
                            height: width
                            anchors.centerIn: parent
                            source: "edit-clear-all"
                            color: Kirigami.Theme.textColor
                        }
                    }

                    QQC2.RoundButton {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*2
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        enabled: root.selectedRowIndex === index

                        Kirigami.Icon {
                            width: Math.round(Kirigami.Units.gridUnit)
                            height: width
                            anchors.centerIn: parent
                            source: "document-edit"
                            color: Kirigami.Theme.textColor
                        }
                    }

                    QQC2.RoundButton {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*2
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        enabled: root.selectedRowIndex === index

                        Kirigami.Icon {
                            width: Math.round(Kirigami.Units.gridUnit)
                            height: width
                            anchors.centerIn: parent
                            source: "documentinfo"
                            color: Kirigami.Theme.textColor
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*12
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
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
                            text: "FX"

                            elide: "ElideRight"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.selectedRowIndex !== index) {
                                    root.selectedRowIndex = index;
                                } else {

                                }
                            }
                        }
                    }

                    QQC2.RoundButton {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*2
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        enabled: root.selectedRowIndex === index

                        Kirigami.Icon {
                            width: Math.round(Kirigami.Units.gridUnit)
                            height: width
                            anchors.centerIn: parent
                            source: "edit-clear-all"
                            color: Kirigami.Theme.textColor
                        }
                    }

                    QQC2.Slider {
                        orientation: Qt.Horizontal

                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: Kirigami.Units.gridUnit
                        Layout.rightMargin: Kirigami.Units.gridUnit

                        from: 0
                        to: 100
                        stepSize: 1
                        value: 100
                    }
                }
            }
        }
    }
} 
