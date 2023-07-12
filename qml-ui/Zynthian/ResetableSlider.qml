import QtQuick 2.10
import QtQuick.Controls 2.4 as QQC2
import Zynthian 1.0 as Zynthian

QQC2.Slider {
    id: root

    property var controlObj
    property var controlProp
    property var initialValue

    signal pressed(var mouse)
    signal released(var mouse)

    value: controlObj[controlProp]
    // Set inset values explicitly to calculate height correctly
    topInset: 0
    bottomInset: 0

    MouseArea {
        id: mouseArea
        property real xValPerPixel: Math.abs(root.to - root.from) / root.width

        anchors.fill: root

        onPressed: root.pressed(mouse)
        onReleased: root.released(mouse)

        onPositionChanged: {
            var positionX = Math.max(0, Math.min(mapToItem(root, mouse.x, mouse.y).x, root.x + root.width))
            if (root.orientation == Qt.Horizontal) {
                root.controlObj[root.controlProp] = parseFloat(Zynthian.CommonUtils.interp(positionX * xValPerPixel, 0, root.to - root.from, root.from, root.to).toFixed(2))
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
