import QtQuick 2.10
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

Extras.Gauge {
    id: control

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
                    case 6:
                        return "6"
                    default:
                        return ""
                }
            }

            font: control.font
        }
    }
}
