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

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        QQC2.Label {
            id: headerLabel
            Layout.alignment: Qt.AlignCenter
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            Extras.Gauge {
                id: audioGauge

                Layout.fillHeight: true
                Layout.alignment: Qt.AlignCenter

                minimumValue: -40
                maximumValue: 10

                style: GaugeStyle {
                    valueBar: Rectangle {
                        color: Kirigami.Theme.highlightColor
                        implicitWidth: 8
                    }
                }
            }

            QQC2.Slider {
                id: slider

                Layout.fillHeight: true
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 14

                orientation: Qt.Vertical
                from: 0
                to: 100
                stepSize: 1
            }
        }

        QQC2.Label {
            id: footerLabel
            Layout.alignment: Qt.AlignCenter
        }
    }
}
