import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

//TODO: Use Zynthian.DialController?
ColumnLayout {
    id: root
    property alias dial: dial
    property alias text: label.text
    property alias valueString: valueLabel.text

    property QtObject controlObj
    property string controlProperty
    onControlObjChanged: dial.value = controlObj[controlProperty]

    visible: controlObj && controlObj.hasOwnProperty(root.controlProperty) ? true : false

    Layout.fillHeight: true
    Layout.fillWidth: false
    Layout.preferredWidth: Kirigami.Units.gridUnit * 9
    //Layout.maximumHeight: 100

    Binding {
        target: dial
        property: "value"
        value: controlObj && controlObj.hasOwnProperty(root.controlProperty) ? root.controlObj[root.controlProperty] : 1
    }

    QQC2.Dial {
        id: dial
        Layout.fillWidth: true
        Layout.fillHeight: true

        value: root.controlObj && root.controlObj.hasOwnProperty(root.controlProperty) ? root.controlObj[root.controlProperty] : 0

        onValueChanged: {
            if (!root.controlObj || !root.controlObj.hasOwnProperty(root.controlProperty)) {
                return;
            }
            root.controlObj[root.controlProperty] = value
        }

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
        QQC2.Label {
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

                dial.value = value;
            }
        }
    }
    QQC2.Label {
        id: label
        Layout.fillWidth: parent
        horizontalAlignment: Text.AlignHCenter
    }
}
