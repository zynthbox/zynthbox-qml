
import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

Rectangle {
    id: rectId
    property alias imgSrc: imageId.source
    property alias text: heading.text
    property bool highlighted: false

    color: highlighted ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.3) : "transparent"

    Rectangle {
        id: buttonId
        z: -1
        anchors.fill: parent
        anchors.margins: 2
        radius: 2
        Kirigami.Theme.colorSet: Kirigami.Theme.Button
        color: Kirigami.Theme.backgroundColor

        Kirigami.Icon {
            id:imageId
            anchors.centerIn: parent
            width:90;height:90
            source: imgSrc
        }

        Kirigami.Heading {
            id:heading
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: Kirigami.Units.smallSpacing
            }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: "Layers"
            font.pointSize: 12
        }
    }
}
