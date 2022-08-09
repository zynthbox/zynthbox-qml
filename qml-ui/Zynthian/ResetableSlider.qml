import QtQuick 2.10
import QtQuick.Controls 2.2 as QQC2

QQC2.Slider {
    id: root

    property var controlObj
    property var controlProp
    property var initialValue

    value: controlObj[controlProp]

    MouseArea {
        property real xValPerPixel: Math.abs(root.to - root.from) / root.width

        anchors.fill: root
        onPositionChanged: {
            var positionX = Math.max(0, Math.min(mapToItem(root, mouse.x, mouse.y).x, root.x + root.width))

            if (root.orientation == Qt.Horizontal) {
                root.controlObj[root.controlProp] = root.from - positionX * xValPerPixel
            } else if (root.orientation == Qt.Vertical) {
                // TODO : Implement vertical slider drag
            }
        }

        onDoubleClicked: {
            if (root.initialValue != null) {
                root.controlObj[root.controlProp] = root.initialValue
            }
        }
    }
}
