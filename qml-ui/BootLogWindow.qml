import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1
import QtMultimedia 5.15
import Qt.labs.settings 1.0


QQC2.ApplicationWindow {
    id: root

    property int dotCount: 0
    property bool playingExtroVideo: false
    property bool displayLoadingText: bootLogInterface.bootLog !== "" && !root.playingExtroVideo

    flags: Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "#00000000"
    visible: true
    width: Screen.width
    height: Screen.height
    maximumWidth: width
    maximumHeight: height

    Settings {
        id: settings
        category: "Bootsplash"
        fileName: "/root/.config/zynthbox/zynthbox-qml.conf"
        property url extroVideo: Qt.resolvedUrl("/usr/share/zynthbox-bootsplash/zynthbox-extro.mp4")
        property url startupBackgroundVideo: Qt.resolvedUrl("/usr/share/zynthbox-bootsplash/zynthbox-startup-background.mp4")
    }

    Rectangle {
        anchors.fill: parent;
        color: "black"
    }

    Timer {
        id: dotTimer
        interval: 1000
        repeat: true
        running: root.visible
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
        source: settings.startupBackgroundVideo
        visible: videoPlayer.playbackState == MediaPlayer.PlayingState
    }

    RowLayout {
        visible: root.displayLoadingText
        anchors.centerIn: parent

        QQC2.Label {
            font.pointSize: 40
            color: "white"
            text: bootLogInterface.bootCompleted ? qsTr("Please Wait") : qsTr("Loading")
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
        anchors.top: parent.bottom
        anchors.topMargin: -80
        horizontalAlignment: Qt.AlignHCenter
        font.pointSize: 14
        color: "white"
        text: bootLogInterface.bootLog
    }

    Connections {
        target: bootLogInterface
        function onPlayExtroAndHide() {
            videoPlayer.stop()
            root.playingExtroVideo = true
            videoPlayer.source = settings.extroVideo
            videoPlayer.loops = 1
            videoPlayer.stopped.connect(function() {
                root.visible = false;
                videoPlayer.source = "";
                bootLogInterface.bootCompleted = true;
            })
            videoPlayer.play()
        }
        function onShowBootlog() {
            root.visible = true;
        }
        function onHideBootlog() {
            root.visible = false;
        }
    }
}
