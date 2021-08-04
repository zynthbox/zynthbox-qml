import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

ColumnLayout {
    property alias text: label1.text
    property alias text2: label2.text

    anchors.centerIn: parent

    QQC2.Label {
        id: label1
        Layout.alignment: Qt.AlignHCenter
        color: Kirigami.Theme.textColor
        font.pointSize: 12
    }

    QQC2.Label {
        id: label2
        Layout.alignment: Qt.AlignHCenter
        color: Kirigami.Theme.textColor
        font.pointSize: 10
    }
}
