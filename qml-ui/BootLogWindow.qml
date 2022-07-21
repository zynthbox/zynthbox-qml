import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1

QQC2.ApplicationWindow {
    id: root

    visible: true
     color: "#000000"

    width: Screen.width
    height: Screen.height
    maximumWidth: width
    maximumHeight: height

    // Start window on bottom so that logo appears on top of this window.
    flags: Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.WindowStaysOnBottomHint

    // Display log on bottom as the window is fullscreen
    QQC2.Label {
        width: parent.width
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        horizontalAlignment: Qt.AlignHCenter
        font.pointSize: 12
        color: "white"
        text: bootLogInterface.bootLog
    }
}
