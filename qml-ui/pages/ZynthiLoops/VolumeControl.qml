import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

Rectangle {
    property bool highlight: false
    property alias headerText: headerLabel.text
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

        QQC2.Slider {
            id: slider

            Layout.fillWidth: true
            Layout.fillHeight: true

            orientation: Qt.Vertical
            from: 0
            to: 100
            stepSize: 1
        }
    }
}
