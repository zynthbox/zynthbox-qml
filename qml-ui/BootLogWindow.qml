import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1

QQC2.ApplicationWindow {
    width: Screen.width
    height: 100
    x: Screen.width/2 - width/2
    y: Screen.height/2 - height/2 - 50
    flags: Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    
    Component.onCompleted: {
        requestActivate()
    }
    
    QQC2.Label {
        width: parent.width
        anchors.centerIn: parent
        text: bootLogInterface.bootLog
    }
}
