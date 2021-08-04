import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

ColumnLayout {
    property alias heading: heading.text
    property alias bpm: bpmDial.value

    spacing: 8

    QQC2.Label {
        id: heading

        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        color: Kirigami.Theme.textColor
        font.pointSize: 12
    }

    QQC2.Dial {
        id: bpmDial

        Layout.preferredWidth: 80
        Layout.preferredHeight: 80
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        stepSize: 1
        value: 120
        from: 0
        to: 200

        // HACK for default style
        Binding {
            target: bpmDial.background
            property: "color"
            value: Kirigami.Theme.highlightColor
        }
        Binding {
            target: bpmDial.handle
            property: "color"
            value: Kirigami.Theme.highlightColor
        }
        TableHeaderLabel {
            id: valueLabel
            anchors.centerIn: parent
            text: bpmDial.value
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
                startValue = bpmDial.value
                bpmDial.forceActiveFocus()
            }
            onPositionChanged: {
                let delta = mouse.y - startY;
                let value = Math.max(bpmDial.from, Math.min(bpmDial.to, startValue - (bpmDial.to / bpmDial.stepSize) * (delta*bpmDial.stepSize/(Kirigami.Units.gridUnit*10))));

                bpmDial.value = Math.round(value);
            }
        }
    }

    TableHeaderLabel {
        Layout.alignment: Qt.AlignHCenter
        text: "BPM"
    }

    Kirigami.Separator {
        Layout.fillWidth: true
        Layout.preferredHeight: 0
        Layout.margins: 8
    }

    SidebarButton {
        icon.name: "media-playback-start"
    }

    SidebarButton {
        icon.name: "media-playback-stop"
    }
}
