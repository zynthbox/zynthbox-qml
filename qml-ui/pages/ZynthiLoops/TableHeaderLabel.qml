import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

ColumnLayout {
    property alias text: label1.text
    property alias text2: label2.text
    property alias text3: label3.text

    property alias text1Size: label1.font.pointSize
    property alias text2Size: label2.font.pointSize
    property alias text3Size: label3.font.pointSize

    QQC2.Label {
        id: label1
        visible: text && text.length > 0
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: parent.width
//        elide: "ElideRight"
        color: Kirigami.Theme.textColor
        font.pointSize: 12
        wrapMode: "WrapAnywhere"
    }

    QQC2.Label {
        id: label2
        visible: text && text.length > 0
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: parent.width
        elide: "ElideRight"
        color: Kirigami.Theme.textColor
        font.pointSize: 10
    }

    QQC2.Label {
        id: label3
        visible: text && text.length > 0
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: parent.width
        elide: "ElideRight"
        color: Kirigami.Theme.textColor
        font.pointSize: 10
    }
}
