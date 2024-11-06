import QtQuick 2.15
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.4 as Kirigami

//TODO: Use Zynthian.DialController?
ColumnLayout {
    id: root
    property alias dial: dial
    property alias text: label.text
    property alias valueString: valueLabel.text
    property alias fineTuneButtonsVisible: fineTuneButtons.visible

    property QtObject controlObj
    property string controlProperty
    property real buttonStepSize

    property bool showDecimalsAtInteger: false
    property int fixedPointTrail: 9 // How many decimal point values do you want to display on this value when a decimal point is required (this should be small enough that the resulting string fits inside the dial's ring)

    property bool selected: false

    // Set this explicitly to false if you want to hide the indicator
    property bool showKnobIndicator: true
    property alias knobId: knobIndicator.knobId

    signal pressed(var mouse)
    signal clicked()
    signal doubleClicked()
    property alias action: actionButton.action
    onControlObjChanged: {
        if (controlObj && controlObj[controlProperty]) {
            dial.value = controlObj[controlProperty]
        }
    }

    //visible: controlObj && controlObj.hasOwnProperty(root.controlProperty) ? true : false

    Layout.fillHeight: true
    Layout.fillWidth: false
    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
    //Layout.maximumHeight: 100

    Binding {
        target: dial
        property: "value"
        value: enabled
                ? controlObj && controlObj.hasOwnProperty(root.controlProperty) ? root.controlObj[root.controlProperty] : 1
                : dial.from
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        QQC2.Dial {
            id: dial
            anchors.centerIn: parent
            inputMode: QQC2.Dial.Vertical
            width: Math.min(parent.height, parent.width)
            height: Math.min(parent.height, parent.width)

            value: root.controlObj && root.controlObj.hasOwnProperty(root.controlProperty) ? root.controlObj[root.controlProperty] : 0

            property bool shouldClick: false
            property var mostRecentClickTime: 0
            onMoved: {
                shouldClick = false;
                if (!root.controlObj || !root.controlObj.hasOwnProperty(root.controlProperty)) {
                    return;
                }
                root.controlObj[root.controlProperty] = value
            }
            onPressedChanged: {
                if (pressed) {
                    shouldClick = true;
                    root.pressed(null);
                } else {
                    shouldClick = false;
                    let thisClickTime = Date.now();
                    if (thisClickTime - mostRecentClickTime < 300) {
                        root.doubleClicked();
                    } else {
                        root.clicked();
                    }
                    mostRecentClickTime = thisClickTime;
                }
            }

            QQC2.Label {
                id: valueLabel
                anchors.centerIn: parent
                text: root.showDecimalsAtInteger
                    ? dial.value.toFixed(root.fixedPointTrail)
                    : Math.floor(dial.value) == dial.value
                        ? Math.floor(dial.value)
                        : dial.value.toFixed(root.fixedPointTrail)
            }
        }
    }

    RowLayout {
        id: fineTuneButtons
        Layout.fillWidth: parent

        QQC2.Button {
            Layout.fillWidth: parent
            text: "-"
            onClicked: {
                dial.value = Math.max(dial.from, dial.value - (buttonStepSize ? buttonStepSize : dial.stepSize))
                dial.moved()
            }
        }
        QQC2.Button {
            Layout.fillWidth: parent
            text: "+"
            onClicked: {
                dial.value = Math.min(dial.to, dial.value + (buttonStepSize ? buttonStepSize : dial.stepSize))
                dial.moved()
            }
        }
    }

    QQC2.Button {
        id: actionButton
        Layout.fillWidth: true
        visible: action !== null
    }

    QQC2.Label {
        id: label
        visible: text !== ""
        Layout.fillWidth: parent
        horizontalAlignment: Text.AlignHCenter
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.bottom
            }
            height: 2
            color: root.selected ? Kirigami.Theme.highlightedTextColor : "transparent"
        }
        KnobIndicator {
            id: knobIndicator
            anchors {
                top: parent.top
                bottom: parent.bottom
                topMargin: -Kirigami.Units.smallSpacing
                bottomMargin: -Kirigami.Units.smallSpacing
                right: parent.horizontalCenter
                rightMargin: parent.paintedWidth / 2
            }
            width: Kirigami.Units.iconSizes.small
            visible: root.showKnobIndicator && -1 < knobId && knobId < 4
            knobId: -1
        }
    }
}
