import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

Item {
    property alias stepSize: dial.stepSize
    property alias value: dial.value
    property alias from: dial.from
    property alias to: dial.to

    QQC2.Dial {
        id: dial
        anchors.fill: parent

        // HACK for default style
        Binding {
            target: dial.background
            property: "color"
            value: Kirigami.Theme.highlightColor
        }
        Binding {
            target: dial.handle
            property: "color"
            value: Kirigami.Theme.highlightColor
        }
        TableHeaderLabel {
            id: valueLabel
            anchors.centerIn: dial
            text: dial.value
        }

        //TODO: with Qt >= 5.12 replace this with inputMode: Dial.Vertical
        MouseArea {
            id: dialMouse
            anchors.fill: parent
            preventStealing: true
            property real startY
            property real startValue
            onPressed: {
                startY = mouse.y;
                startValue = dial.value
                dial.forceActiveFocus()
            }
            onPositionChanged: {
                let delta = mouse.y - startY;
                let value = Math.max(dial.from, Math.min(dial.to, startValue - (dial.to / dial.stepSize) * (delta*dial.stepSize/(Kirigami.Units.gridUnit*10))));

                dial.value = Math.round(value);
            }
        }
    }
}
