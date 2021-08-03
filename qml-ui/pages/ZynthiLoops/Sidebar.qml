import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

ColumnLayout {
    spacing: 8

    QQC2.Dial {
        id: dial

        Layout.preferredWidth: 80
        Layout.preferredHeight: 80
        Layout.alignment: Qt.AlignHCenter

        stepSize: 1
        value: 120
        from: 0
        to: 200

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
            anchors.centerIn: parent
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
