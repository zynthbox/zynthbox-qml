import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

Rectangle {
    property bool highlight: false
    property alias headerText: headerLabel.text
    property alias footerText: footerLabel.text
    property alias audioLeveldB: audioGauge.value
    property var inputAudioLeveldB: null
    property alias inputAudioLevelVisible: inputAudioLevelGauge.visible
    property alias slider: slider
    property bool enabled: true

    signal clicked();
    signal doubleClicked();
    signal valueChanged();

    id: control
    border.color: Kirigami.Theme.highlightColor
    border.width: highlight ? 1 : 0
    color: "transparent"
    radius: 2
    anchors.leftMargin: 2
    anchors.rightMargin: 2

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        QQC2.Label {
            id: headerLabel
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 8
            font.pointSize: 9
        }

        RowLayout {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignLeft
            spacing: 8

            QQC2.Slider {
                id: slider

                Layout.fillHeight: true
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: parent.width/2
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                Layout.leftMargin: 30

                enabled: control.enabled
                orientation: Qt.Vertical
                from: -40
                to: 20
                stepSize: 1

                background: Rectangle {
                    x: slider.leftPadding
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    implicitWidth: 8
                    implicitHeight: parent.height
                    width: implicitWidth
                    height: slider.availableHeight
                    radius: 2
                    color: "transparent"

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
                        width: parent.width
                        height: parent.height * (1 - slider.visualPosition)
                        color: "transparent"//Kirigami.Theme.highlightColor
                        radius: 2
                        anchors.bottom: parent.bottom
                    }

                    Rectangle {
                        width: parent.width + 6
                        height: width
                        radius: width

                        anchors.top: valueBox.top
                        anchors.topMargin: -height/2
                        anchors.horizontalCenter: valueBox.horizontalCenter
                        color: "white"
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
                                            return "+6"
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
        }

        QQC2.Label {
            id: footerLabel
            Layout.alignment: Qt.AlignCenter
            Layout.maximumWidth: parent.width
            horizontalAlignment: "AlignHCenter"
            elide: "ElideRight"
            visible: text && text.length>0
        }
    }

    Timer {
        id: dblTimer
        interval: 150
        onTriggered: {
            if (!mouseArea.valueChanged) {
                control.clicked();
            }
        }
    }

    MouseArea {
        property real startY
        property real startValue
        property bool valueChanged: false

        id: mouseArea
        anchors.fill: parent
        enabled: control.enabled

        onPressed: {
            startY = mouse.y
            startValue = slider.value
            valueChanged = false
        }
        onPositionChanged: {
            let delta = mouse.y - startY;
            let value = Math.max(slider.from, Math.min(slider.to, startValue - (slider.to / slider.stepSize) * (delta*slider.stepSize/(Kirigami.Units.gridUnit*8))));
            let floored = Math.floor(value/slider.stepSize) * slider.stepSize;

            slider.value = value;
            valueChanged = true
            control.valueChanged()
        }
        onClicked: {
            if (dblTimer.running) {
                valueChanged = true;
                control.doubleClicked();
            }
            dblTimer.restart();
        }
    }
}
