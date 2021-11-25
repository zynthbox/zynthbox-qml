import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

Zynthian.Card {
    id: root

    property int selectedRowIndex: 0

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
            model: 5
            delegate: Rectangle {
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
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*16
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: Kirigami.Units.gridUnit
                        Layout.rightMargin: Kirigami.Units.gridUnit

                        color: Kirigami.Theme.buttonBackgroundColor

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
                            text: ""

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
                }
            }
        }
    }
} 
