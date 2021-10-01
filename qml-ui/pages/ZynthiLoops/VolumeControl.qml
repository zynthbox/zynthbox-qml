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

    id: control
    border.color: Kirigami.Theme.highlightColor
    border.width: highlight ? 1 : 0
    color: Kirigami.Theme.backgroundColor
    radius: 2
    anchors.leftMargin: 8
    anchors.rightMargin: 8

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        QQC2.Label {
            id: headerLabel
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 8
        }

        RowLayout {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignLeft
            spacing: 8

            Extras.Gauge {
                id: audioGauge

                Layout.fillHeight: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.leftMargin: 2

                minimumValue: -40
                maximumValue: 10

                font.pointSize: 8

                style: GaugeStyle {
                    background: Rectangle {
                        color: "#ff888888"
                        implicitWidth: 6
                    }                    
                    valueBar: Rectangle {
                        color: "#ff81d4fa"
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
                from: 0
                to: 100
                stepSize: 1

                background: Rectangle {
                    x: slider.leftPadding
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    implicitWidth: 8
                    implicitHeight: parent.height
                    width: implicitWidth
                    height: slider.availableHeight
                    radius: 2
                    color: "#ff888888"

                    Rectangle {
                        id: valueBox
                        width: parent.width
                        height: parent.height * (1 - slider.visualPosition)
                        color: Kirigami.Theme.highlightColor
                        radius: 2
                        anchors.bottom: parent.bottom
                    }

                    Rectangle {
                        width: parent.width
                        height: 2

                        anchors.top: valueBox.top
                        anchors.left: valueBox.right
                        color: "white"
                        opacity: 0.7
                    }
                }
            }
        }

        QQC2.Label {
            id: footerLabel
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            font.pointSize: 9
        }
    }

    MouseArea {
        property real startY
        property real startValue
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
    }
}
