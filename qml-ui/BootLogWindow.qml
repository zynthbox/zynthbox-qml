import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1
import QtMultimedia 5.15

QQC2.ApplicationWindow {
    id: root
    flags: Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "#00000000"
    visible: true
    width: Screen.width
    height: Screen.height
    maximumWidth: width
    maximumHeight: height

    Video {
        id: splash
        anchors.fill: parent
        source: "/usr/share/zynthbox-bootsplash/zynthbox-bootsplash.mp4"
        autoPlay: true
        loops: MediaPlayer.Infinite
    }

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
