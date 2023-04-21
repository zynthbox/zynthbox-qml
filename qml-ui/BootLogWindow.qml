import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1
import QtMultimedia 5.15

QQC2.ApplicationWindow {
    id: root

    property int dotCount: 0
    property bool displayLoadingText: true

    flags: Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "#00000000"
    visible: true
    width: Screen.width
    height: Screen.height
    maximumWidth: width
    maximumHeight: height

    Timer {
        id: dotTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            root.dotCount = root.dotCount+1 > 3 ? 0 : root.dotCount + 1;
        }
    }

    Video {
        id: videoPlayer
        anchors.fill: parent
        autoPlay: true
        loops: MediaPlayer.Infinite
        fillMode: VideoOutput.Stretch
        flushMode: VideoOutput.LastFrame
        source: "/usr/share/zynthbox-bootsplash/zynthbox-bootsplash.mp4"
    }

    RowLayout {
        visible: root.displayLoadingText
        anchors.centerIn: parent

        QQC2.Label {
            font.pointSize: 40
            color: "white"
            text: qsTr("Loading")
        }
        QQC2.Label {
            Layout.preferredWidth: 20
            font.pointSize: 40
            color: "white"
            text: ".".repeat(root.dotCount)
        }
    }

    QQC2.Label {
        visible: root.displayLoadingText
        width: parent.width
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        horizontalAlignment: Qt.AlignHCenter
        font.pointSize: 14
        color: "white"
        text: bootLogInterface.bootLog
    }

    Connections {
        target: bootLogInterface
        function onPlayExtroAndExit(test) {
            videoPlayer.stop()
            root.displayLoadingText = false
            videoPlayer.source = "/usr/share/zynthbox-bootsplash/zynthbox-bootsplash-extro.mp4"
            videoPlayer.loops = 1
            videoPlayer.stopped.connect(function() {
                Qt.quit()
            })
            videoPlayer.play()
        }
    }
}
