import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import io.zynthbox.ui 1.0 as ZUI
import org.kde.plasma.core 2.0 as PlasmaCore

Rectangle {
    id: control
    property bool highlight: false
    property alias headerText: headerLabel.text
    property alias headerTextVisible: headerLabel.visible
    property alias footerText: footerLabel.text
    property alias audioLeveldB: audioGauge.value
    property alias audioGaugeItem: audioGauge
    property var inputAudioLeveldB: null
    property alias inputAudioLevelVisible: inputAudioLevelGauge.visible
    property alias slider: slider
    property bool enabled: true
    property alias mouseArea: mouseArea
    property alias value : slider.value

    signal clicked();
    signal doubleClicked();
    
    border.color: Kirigami.Theme.highlightColor
    border.width: highlight ? 1 : 0
    color: "transparent"
    radius: 2

    property var tickLabelSet : ({"-40":"-40", "0":"0", "20":"+20"})

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: 4

        QQC2.Label {
            id: headerLabel
            Layout.fillWidth: true
            visible: text.length > 0
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 8
            // font.pointSize: 8
        }

        Item{
            Layout.fillHeight: true
            Layout.fillWidth: true

            Extras.Gauge {
                id: audioGauge
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -8
                height: parent.height

                property var tickLabelSet : control.tickLabelSet

                minimumValue: slider.from
                maximumValue: slider.to
                value: control.inputAudioLeveldB ? control.inputAudioLeveldB : minimumValue

                font.pointSize: 8
                style: GaugeStyle {
                    valueBar: Item {
                        implicitWidth: 8

                        Rectangle {
                            color: Kirigami.Theme.highlightColor
                            radius: ZUI.Theme.radius    
                            anchors.fill: parent
                            anchors.margins: 1                    
                        }
                    }

                    foreground: Item {}

                    background: Item {
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        Rectangle{
                            anchors.fill: parent
                            radius: ZUI.Theme.radius
                            color: Kirigami.Theme.backgroundColor
                            border.color: Qt.darker(Kirigami.Theme.backgroundColor, 3)

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.margins: 1
                                anchors.left: parent.left
                                anchors.right: parent.right
                                radius: ZUI.Theme.radius
                                color: Kirigami.Theme.textColor 
                                opacity: 0.2
                                height: slider.position*parent.height 
                            }
                        }
                    }

                    minorTickmark: Item {
                        implicitWidth: 8
                        implicitHeight: 1

                        Rectangle {
                            color: Kirigami.Theme.textColor
                            opacity: 0.2
                            anchors.fill: parent
                            anchors.leftMargin: 2
                            anchors.rightMargin: 4
                        }
                    }
                    tickmark: Item {
                        implicitWidth: 12
                        implicitHeight: 1

                        Rectangle {
                            color: Kirigami.Theme.textColor
                            opacity: 0.5
                            anchors.fill: parent
                            anchors.leftMargin: 3
                            anchors.rightMargin: 3
                        }
                    }
                    tickmarkLabel: QQC2.Label {
                        id: _tickLabel
                        text: {
                            return  audioGauge.tickLabelSet[styleData.value]
                        }
                        font: audioGauge.font
                    }
                }
            }

            QQC2.Slider {
                id: slider
                anchors.top: audioGauge.top
                anchors.bottom: audioGauge.bottom
                anchors.margins: 6

                anchors {
                    left: audioGauge.right
                    leftMargin: 4
                }

                enabled: control.enabled
                orientation: Qt.Vertical
                from: -40
                to: 20
                stepSize: 1
                handle: null

                background:  Item {
                    Item {
                        id: inputAudioLevelGauge
                        height: slider.availableHeight * slider.position
                        width: 2
                        anchors.bottom: parent.bottom

                        Kirigami.Icon {
                            anchors.verticalCenter: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitHeight: 22
                            implicitWidth: 22
                            source: Qt.resolvedUrl("../../../img/left-arrow.svg")
                            color: Kirigami.Theme.textColor
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    property real initialMouseY
                    property bool dragHappened: false
                    // A workaround to be able to handle pressed signal as MouseArea has a property and a signal named pressed causing conflict
                    signal handlePressed(var mouse)

                    anchors.fill: parent
                    enabled: control.enabled
                    onHandlePressed: {
                        mouseArea.initialMouseY = mouse.y
                    }
                    onPressed: handlePressed(mouse)
                    onReleased: {
                        dragHappenedResetTimer.restart()
                        if (dblTimer.running) {
                            dblTimer.stop();
                            control.doubleClicked();
                        } else {
                            dblTimer.restart();
                        }
                    }
                    onMouseYChanged: {
                        if (mouse.y - mouseArea.initialMouseY != 0) {
                            var newVal = ZUI.CommonUtils.clamp((mouseArea.height - mouse.y) / mouseArea.height, 0, 1)
                            mouseArea.dragHappened = true
                            slider.value = ZUI.CommonUtils.interp(newVal * (slider.to - slider.from), 0, (slider.to - slider.from), slider.from, slider.to)
                        }
                    }
                    Timer {
                        id: dblTimer
                        interval: zynqtgui.ui_settings.doubleClickThreshold
                        onTriggered: {
                            if (!mouseArea.dragHappened) {
                                control.clicked();
                            }
                        }
                    }
                    Timer {
                        id: dragHappenedResetTimer
                        interval: dblTimer.interval
                        repeat: false
                        onTriggered: {
                            mouseArea.dragHappened = false
                        }
                    }
                }
            }
        }

        QQC2.Label {
            id: footerLabel
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            visible: text && text.length>0
            // font.pointSize: 8
        }
    }
}
