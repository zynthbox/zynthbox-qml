import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

//TODO: Use Zynthian.SliderController?
ColumnLayout {
    id: root
    property alias slider: slider
    property alias text: label.text
    property alias valueString: valueLabel.text

    property QtObject controlObj
    property string controlProperty
    property real buttonStepSize
    signal doubleClicked()
    onControlObjChanged: slider.value = controlObj[controlProperty]

    //visible: controlObj && controlObj.hasOwnProperty(root.controlProperty) ? true : false

    Layout.fillHeight: true
    Layout.fillWidth: false
    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
    //Layout.maximumHeight: 100

    Binding {
        target: slider
        property: "value"
        value: controlObj && controlObj.hasOwnProperty(root.controlProperty) ? root.controlObj[root.controlProperty] : 1
    }

    QQC2.Slider {
        id: slider
        Layout.fillWidth: true

        value: root.controlObj && root.controlObj.hasOwnProperty(root.controlProperty) ? root.controlObj[root.controlProperty] : 0

        onMoved: {
            if (!root.controlObj || !root.controlObj.hasOwnProperty(root.controlProperty)) {
                return;
            }
            root.controlObj[root.controlProperty] = value
        }

        // HACK for default style
        Binding {
            target: slider.background
            property: "color"
            value: Kirigami.Theme.highlightColor
        }
        Binding {
            target: slider.handle
            property: "color"
            value: Kirigami.Theme.highlightColor
        }
    }

    QQC2.Label {
        id: valueLabel
        anchors.centerIn: slider
        text: slider.value
    }


    RowLayout {
        id: controlButtons
        Layout.fillWidth: parent

        QQC2.Button {
            Layout.fillWidth: parent
            text: "-"
            onClicked: {
                slider.value = Math.max(slider.from, slider.value - (buttonStepSize ? buttonStepSize : slider.stepSize))
                slider.moved()
            }
        }
        QQC2.Button {
            Layout.fillWidth: parent
            text: "+"
            onClicked: {
                slider.value = Math.min(slider.to, slider.value + (buttonStepSize ? buttonStepSize : slider.stepSize))
                slider.moved()
            }
        }
    }

    QQC2.Label {
        id: label
        Layout.fillWidth: parent
        horizontalAlignment: Text.AlignHCenter
    }
}
