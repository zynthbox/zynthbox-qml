
import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

Rectangle {
    id:rectId
    property alias rectX: rectId.x
    property alias rectY: rectId.y
    property alias rectWidth: rectId.width
    property alias rectHeight: rectId.height 
    property alias imgSrc: imageId.source
    property alias text: heading.text
    signal clicked

    width:rectWidth
    height:rectHeight
    x:rectX
    y:rectY
    color:"transparent"

    QQC2.Button {
        id:buttonId
        anchors.fill: parent
        onClicked: rectId.clicked();
    
        Image {
            id:imageId
            anchors.centerIn: parent
            width:90;height:90
            source: imgSrc
        }

        Kirigami.Heading {
            id:heading
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: Kirigami.Units.smallSpacing
            }
            text: "Layers"
            font.pointSize: 12
        }
    }
}
