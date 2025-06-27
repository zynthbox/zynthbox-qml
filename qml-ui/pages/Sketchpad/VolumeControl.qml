import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import Zynthian 1.0 as Zynthian

Rectangle {
    id: control
    property bool highlight: false
    property alias headerText: headerLabel.text
    property alias headerTextVisible: headerLabel.visible
    property alias footerText: footerLabel.text
    property alias audioLeveldB: audioGauge.value
    property var inputAudioLeveldB: null
    property alias inputAudioLevelVisible: inputAudioLevelGauge.visible
    property alias slider: slider
    property bool enabled: true

    signal clicked();
    signal doubleClicked();
    signal valueChanged();

    border.color: Kirigami.Theme.highlightColor
    border.width: highlight ? 1 : 0
    color: "transparent"
    radius: 2

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: 4

        QQC2.Label {
            id: headerLabel
            Layout.fillWidth: true
            visible: text.length > 0
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 8
            font.pointSize: 8
        }

        Item{
            Layout.fillHeight: true
            Layout.fillWidth: true

            QQC2.Slider {
                id: slider

                anchors.centerIn: parent
                height: parent.height

                enabled: control.enabled
                orientation: Qt.Vertical
                from: -40
                to: 20
                stepSize: 1

                background: Item {

                    Rectangle {
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        Kirigami.Theme.inherit: false
                        width: 8
                        height: parent.height
                        anchors.centerIn: parent
                        radius: 4
                        border.pixelAligned: false
                        antialiasing: true
                        border.color: Qt.darker(color, 1.5)
                        color: Kirigami.Theme.backgroundColor

                        /*Canvas {
                        readonly property real xCenter: width / 2
                        readonly property real yCenter: height / 2
                        property real shineLength: height * 0.95

                        anchors.fill: parent
                        z: 5

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();

                            ctx.beginPath();
                            ctx.rect(0, 0, width, height);

                            var gradient = ctx.createLinearGradient(0, yCenter, width, yCenter);

                            gradient.addColorStop(0, Qt.rgba(1, 1, 1, 0.08));
                            gradient.addColorStop(1, Qt.rgba(1, 1, 1, 0.20));
                            ctx.fillStyle = gradient;
                            ctx.fill();
                        }
                    }*/

                        Rectangle {
                            id: valueBox

                            height: parent.height * (1 - slider.visualPosition)
                            color: Kirigami.Theme.highlightColor
                            opacity: slider.enabled ? 1 : 0.5
                            border.color: Qt.darker(color, 1.5)

                            radius: parent.radius
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            // anchors.margins: 2
                        }

                        Rectangle {
                            width: parent.width + 6
                            height: width
                            radius: width/2
                            visible: enabled
                            anchors.top: valueBox.top
                            anchors.topMargin: -height/2
                            anchors.horizontalCenter: valueBox.horizontalCenter
                            color: Kirigami.Theme.textColor
                            border.color: parent.border.color
                        }
                        Extras.Gauge {
                            id: audioGauge
                            z: -1

                            anchors {
                                top: parent.top
                                bottom:parent.bottom
                                right: parent.right
                            }
                            //Layout.fillHeight: true
                            //Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            //Layout.leftMargin: 4
                            minimumValue: -40
                            maximumValue: 20

                            font.pointSize: 8
                            style: GaugeStyle {
                                valueBar: Rectangle {
                                    color: Qt.lighter(Kirigami.Theme.highlightColor, 1.6)
                                    implicitWidth: 6
                                }
                                minorTickmark: Item {
                                    implicitWidth: 8
                                    implicitHeight: 1

                                    Rectangle {
                                        color: "#cccccc"
                                        anchors.fill: parent
                                        anchors.leftMargin: 2
                                        anchors.rightMargin: 4
                                    }
                                }
                                tickmark: Item {
                                    implicitWidth: 12
                                    implicitHeight: 1

                                    Rectangle {
                                        color: "#dfdfdf"
                                        anchors.fill: parent
                                        anchors.leftMargin: 3
                                        anchors.rightMargin: 3
                                    }
                                }
                                tickmarkLabel: QQC2.Label {
                                    text: {
                                        switch (styleData.value) {
                                        case -40:
                                            return "-40"
                                        case 0:
                                            return "0"
                                        case 20:
                                            return "+20"
                                        default:
                                            return ""
                                        }
                                    }

                                    font: audioGauge.font
                                }
                            }
                        }

                        Extras.Gauge {
                            id: inputAudioLevelGauge
                            anchors.top: audioGauge.top
                            anchors.bottom: audioGauge.bottom
                            anchors.right: audioGauge.right
                            anchors.rightMargin: -8
                            visible: control.inputAudioLeveldB != null

                            minimumValue: -100
                            maximumValue: 20
                            value: control.inputAudioLeveldB ? control.inputAudioLeveldB : minimumValue

                            font.pointSize: 8

                            style: GaugeStyle {
                                valueBar: Rectangle {
                                    color: Qt.lighter(Kirigami.Theme.highlightColor, 1.6)
                                    implicitWidth: 3
                                }
                                minorTickmark: null
                                tickmark: null
                                tickmarkLabel: null
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    property real initialMouseY
                    property bool dragHappened: false

                    anchors.fill: parent
                    enabled: control.enabled
                    onPressed: {
                        mouseArea.initialMouseY = mouse.y
                    }
                    onReleased: {
                        dragHappenedResetTimer.restart()
                    }
                    onMouseYChanged: {
                        if (mouse.y - mouseArea.initialMouseY != 0) {
                            var newVal = Zynthian.CommonUtils.clamp((mouseArea.height - mouse.y) / mouseArea.height, 0, 1)
                            mouseArea.dragHappened = true
                            slider.value = Zynthian.CommonUtils.interp(newVal * (slider.to - slider.from), 0, (slider.to - slider.from), slider.from, slider.to)
                            control.valueChanged()
                        }
                    }
                    onClicked: {
                        if (dblTimer.running) {
                            control.doubleClicked();
                            dblTimer.stop();
                        } else {
                            dblTimer.restart();
                        }
                    }
                    Timer {
                        id: dblTimer
                        interval: 150
                        onTriggered: {
                            if (!mouseArea.dragHappened) {
                                control.clicked();
                            }
                        }
                    }
                    Timer {
                        id: dragHappenedResetTimer
                        interval: dblTimer.interval
                        repeat: false
                        onTriggered: {
                            mouseArea.dragHappened = false
                        }
                    }
                }
            }
        }

        QQC2.Label {
            id: footerLabel
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            visible: text && text.length>0
            font.pointSize: 8
        }
    }
}
