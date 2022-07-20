import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1

QQC2.ApplicationWindow {
    id: root

    visible: true
     color: "#000000"

    width: Screen.width
    height: 100
    maximumWidth: width
    maximumHeight: height

    flags: Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.WindowStaysOnBottomHint

    QQC2.Label {
        width: parent.width
        anchors.centerIn: parent
        horizontalAlignment: Qt.AlignHCenter
        font.pointSize: 12
        color: "white"
        text: bootLogInterface.bootLog
    }

    Connections {
        target: root
        onScreenChanged: updatePosition()
        onXChanged: updatePosition()
        onYChanged: updatePosition()
    }

    function updatePosition() {
        var xpos = Screen.width / 2 - root.width / 2;
        var ypos = Screen.height - root.height

        if (root.x != xpos) {
            root.x = xpos
        }
        if (root.y != ypos) {
            root.y = ypos
        }
    }
}
