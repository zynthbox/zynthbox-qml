import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4 as Extras
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import Zynthian 1.0 as Zynthian
import org.kde.plasma.core 2.0 as PlasmaCore

Rectangle {
    id: control
    property bool highlight: false
    property alias headerText: headerLabel.text
    property alias headerTextVisible: headerLabel.visible
    property alias footerText: footerLabel.text
    property alias audioLeveldB: audioGauge.value
    property var inputAudioLeveldB: null
    property alias inputAudioLevelVisible: inputAudioLevelGauge.visible
    property alias slider: slider
    property bool enabled: true
    property alias mouseArea: mouseArea

    signal clicked();
    signal doubleClicked();
    signal valueChanged();

    border.color: Kirigami.Theme.highlightColor
    border.width: highlight ? 1 : 0
    color: "transparent"
    radius: 2

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

                //Layout.fillHeight: true
                //Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                //Layout.leftMargin: 4
                minimumValue: -40
                maximumValue: 20
                value: control.inputAudioLeveldB ? control.inputAudioLeveldB : minimumValue

                // Rectangle {
                //     anchors.fill: parent
                //     color: "blue"
                // }

                font.pointSize: 8
                style: GaugeStyle {
                    valueBar: PlasmaCore.FrameSvgItem {
                        visible: audioGauge.value > audioGauge.minimumValue
                        id: grooveFill
                        imagePath: "widgets/slider"
                        prefix: "groove-highlight"
                        colorGroup: PlasmaCore.ColorScope.colorGroup
                        implicitWidth: 8
                    }

                    background: PlasmaCore.FrameSvgItem {
                        id: svgBg
                        // visible: fromCurrentTheme
                        imagePath: "widgets/slider"
                        prefix: "groove"
                    }

                    minorTickmark: Item {
                        implicitWidth: 8
                        implicitHeight: 1

                        Rectangle {
                            color: "#cccccc"
                            anchors.fill: parent
                            anchors.leftMargin: 2
                            anchors.rightMargin: 4
                        }
                    }
                    tickmark: Item {
                        implicitWidth: 12
                        implicitHeight: 1

                        Rectangle {
                            color: "#dfdfdf"
                            anchors.fill: parent
                            anchors.leftMargin: 3
                            anchors.rightMargin: 3
                        }
                    }
                    tickmarkLabel: QQC2.Label {
                        text: {
                            switch (styleData.value) {
                            case -40:
                                return "-40"
                            case 0:
                                return "0"
                            case 20:
                                return "+20"
                            default:
                                return ""
                            }
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
                        // color: "yellow"

                        // Rectangle {
                        //     height: 5
                        //     width: height
                        //     color: "orange"
                        //     anchors.top: parent.top
                        //     anchors.horizontalCenter: parent.horizontalCenter
                        // }

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

                // background: Item {
                //     visible: false
                //     implicitWidth: svgBg.implicitWidth
                //     implicitHeight: svgBg.implicitHeight

                //     PlasmaCore.FrameSvgItem {
                //         id: svgBg
                //         // visible: fromCurrentTheme
                //         imagePath: "widgets/slider"
                //         prefix: "groove"
                //         anchors.horizontalCenter: parent.horizontalCenter
                //         colorGroup: PlasmaCore.ColorScope.colorGroup
                //         implicitWidth: slider.horizontal ? PlasmaCore.Units.gridUnit * 12 : fixedMargins.left + fixedMargins.right
                //         implicitHeight: slider.vertical ? PlasmaCore.Units.gridUnit * 12 : fixedMargins.top + fixedMargins.bottom

                //         width: slider.horizontal ? Math.max(fixedMargins.left + fixedMargins.right, slider.availableWidth) : implicitWidth
                //         height: slider.vertical ? Math.max(fixedMargins.top + fixedMargins.bottom, slider.availableHeight) : implicitHeight
                //         x: slider.leftPadding + (slider.horizontal ? 0 : Math.round((slider.availableWidth - width) / 2))
                //         y: slider.topPadding + (slider.vertical ? 0 : Math.round((slider.availableHeight - height) / 2))

                //         Extras.Gauge {
                //             id: inputAudioLevelGauge
                //             anchors.bottom: parent.bottom
                //             anchors.left: parent.left
                //             anchors.right: parent.right
                //             width: parent.width
                //             visible: control.inputAudioLeveldB != null

                //             minimumValue: -40
                //             maximumValue: 20
                //             // value: control.inputAudioLeveldB ? control.inputAudioLeveldB : minimumValue

                //             font.pointSize: 8

                //             style: GaugeStyle {
                //                 valueBar: Item {
                //                     // color: Qt.lighter(Kirigami.Theme.highlightColor, 1.6)
                //                     PlasmaCore.FrameSvgItem {

                //                         imagePath: "widgets/slider"
                //                         prefix: "groove-highlight"
                //                         colorGroup: PlasmaCore.ColorScope.colorGroup
                //                         anchors.fill: parent
                //                     }
                //                 }
                //                 minorTickmark: null
                //                 tickmark: null
                //                 tickmarkLabel: null
                //             }
                //         }
                //     }


                // }

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
                            var newVal = Zynthian.CommonUtils.clamp((mouseArea.height - mouse.y) / mouseArea.height, 0, 1)
                            mouseArea.dragHappened = true
                            slider.value = Zynthian.CommonUtils.interp(newVal * (slider.to - slider.from), 0, (slider.to - slider.from), slider.from, slider.to)
                            control.valueChanged()
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
