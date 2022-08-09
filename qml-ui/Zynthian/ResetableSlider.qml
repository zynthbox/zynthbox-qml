import QtQuick 2.10
import QtQuick.Controls 2.2 as QQC2

QQC2.Slider {
    id: root

    property var controlObj
    property var controlProp
    property var initialValue

    value: controlObj[controlProp]

    MouseArea {
        property real valPerPixel: Math.abs(root.to - root.from) / root.width

        anchors.fill: root
        onPositionChanged: {
            var positionX = Math.max(0, Math.min(mapToItem(root, mouse.x, mouse.y).x, root.x + root.width))

            if (root.orientation == Qt.Horizontal) {
                controlObj[controlProp] = root.from - positionX * valPerPixel
            } else if (parent.orientation == Qt.Vertical) {
                // TODO : Implement vertical slider drag
            }
        }

        onDoubleClicked: {
            if (initialValue) {
                controlObj[controlProp] = initialValue
            }
        }
    }
}
