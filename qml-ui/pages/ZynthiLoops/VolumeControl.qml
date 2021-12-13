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
    property alias slider: slider

    signal doubleClicked();

    id: control
    border.color: Kirigami.Theme.highlightColor
    border.width: highlight ? 1 : 0
    color: Kirigami.Theme.backgroundColor
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

            Extras.Gauge {
                id: audioGauge

                Layout.fillHeight: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.leftMargin: 4

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

            QQC2.Slider {
                id: slider

                Layout.fillHeight: true
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: parent.width/2
                Layout.topMargin: 6
                Layout.bottomMargin: 6

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

                    Canvas {
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
                    }

                    Rectangle {
                        id: valueBox
                        width: parent.width
                        height: parent.height * (1 - slider.visualPosition)
                        color: Kirigami.Theme.highlightColor
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

    MouseArea {
        property real startY
        property real startValue

        id: mouseArea
        anchors.fill: parent

        onPressed: {
            startY = mouse.y
            startValue = slider.value
        }
        onPositionChanged: {
            let delta = mouse.y - startY;
            let value = Math.max(slider.from, Math.min(slider.to, startValue - (slider.to / slider.stepSize) * (delta*slider.stepSize/(Kirigami.Units.gridUnit*10))));
            let floored = Math.floor(value/slider.stepSize) * slider.stepSize;

            slider.value = value;
        }
        onDoubleClicked: {
            control.doubleClicked();
        }
    }
}
