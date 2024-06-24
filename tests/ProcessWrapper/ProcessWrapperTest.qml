import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: root
    visible: true
    width: 600
    height: 600

    ColumnLayout {
        spacing: 0
        anchors.fill: parent
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#10000000"
            ListView {
                anchors.fill: parent
                anchors.margins: 10
                model: app.consoleOutput
                spacing: 25
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                interactive: true
                clip: true
                onCountChanged: {
                    currentIndex = count - 1
                }
                delegate: RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "$>"
                        Layout.alignment: Qt.AlignTop
                    }
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: "#33000000"
                    }
                    TextEdit {
                        Layout.fillWidth: true
                        text: modelData
                        readOnly: true
                        selectByMouse: true
                    }
                }
                ScrollBar.vertical: ScrollBar {}
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            Layout.minimumHeight: 50
            Layout.maximumHeight: 50

            RowLayout {
                anchors.fill: parent
                TextArea {
                    id: textAreaCmd
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.alignment: Qt.AlignVCenter
                    enabled: !app.cmdInProgress
                    opacity: enabled ? 1 : 0.5
                    focus: true
                    placeholderText: "Command"
                    Keys.onReturnPressed: buttonSend.clicked()
                }
                Button {
                    id: buttonSend
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    icon.name: "keyboard-enter"
                    icon.color: "#ffffff"
                    enabled: !app.cmdInProgress
                    opacity: enabled ? 1 : 0.5
                    background: Rectangle {
                        color: "#2196f3"
                    }
                    onClicked: {
                        if (textAreaCmd.text.trim() != "") {
                            app.sendCommandToProcess(textAreaCmd.text)
                            textAreaCmd.text = ""
                        }
                    }
                }
            }
        }
    }
}
