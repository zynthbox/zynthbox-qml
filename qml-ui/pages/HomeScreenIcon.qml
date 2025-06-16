
import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

QQC2.Control {
    id: root
    property alias imgSrc: imageId.source
    property alias text: heading.text
    property bool highlighted: false
    padding: Kirigami.Units.smallSpacing

    background: Rectangle {
        id: buttonId
        radius: 4
        Kirigami.Theme.colorSet: Kirigami.Theme.Button
        color: root.highlighted ? Kirigami.Theme.highlightColor : "transparent"
    }

    contentItem: ColumnLayout {

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Kirigami.Icon {
                id:imageId
                anchors.centerIn: parent
                implicitHeight: 90
                implicitWidth:90
                source: imgSrc
            }
        }

        Kirigami.Heading {
            id:heading
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: "Layers"
            font.pointSize: 12
            color: highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
        }
    }
}
