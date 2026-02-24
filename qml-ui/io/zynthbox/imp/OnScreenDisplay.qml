/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

On Screen Display component, used by the main zynthbox UI

Copyright (C) 2022 Dan Leinir Turthra Jensen <admin@leinir.dk>

******************************************************************************

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of
the License, or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

For a full copy of the GNU General Public License see the LICENSE.txt file.

******************************************************************************
*/

import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.4 as QQC2
import QtQuick.Window 2.1
import org.kde.kirigami 2.6 as Kirigami


import io.zynthbox.ui 1.0 as ZUI

ZUI.Popup {
    id: component
    parent: QQC2.Overlay.overlay
    x: Math.round(parent.width- width) + 10
    y: 0
    modal: true

    background:  null

    height: parent.height
    width: parent.width * 0.5

    property var cuiaCallback: function(cuia) {
        // Do not handle any cuia callbacks in OSD
        return false
    }

    Timer {
        id: hideTimer
        running: false; repeat: false; interval: 1500;
        onTriggered: {
            if (component.opened) {
                component.close();
            }
        }
        property bool isHeld: false;
        function pressed() {
            isHeld = true;
            stop();
        }
        function released() {
            restart();
            isHeld = false;
        }
    }
    property bool anyKnobTouched: zynqtgui.anyKnobTouched
    onAnyKnobTouchedChanged: {
        if (component.anyKnobTouched == false && hideTimer.running === false) {
            hideTimer.stop();
            if (component.opened) {
                component.close();
            }
        }
    }
    Connections {
        target: zynqtgui.osd
        onUpdate: {
            if (hideTimer.isHeld === false && component.anyKnobTouched === false) {
                hideTimer.restart();
            }
            component.open();
        }
    }

    readonly property bool invertedScale: zynqtgui.osd.start > zynqtgui.osd.stop

    component BarControl : QQC2.Pane {
        id: _barControl
        width: discret ? implicitWidth: parent.width
        height: Kirigami.Units.gridUnit * 6
        x: discret ? component.width-width : 0
        
        padding: 10
        rightPadding: 20

        property alias text : _label1.text
        property alias minVal: _label2.text
        property alias maxVal: _label3.text
        property alias val: _label4.text
        // property alias slider: _slider
        property alias dial : _dial

        property bool discret : true

        background: Rectangle {
            color: Kirigami.Theme.backgroundColor
            radius: 4
        }

        contentItem: ColumnLayout {
            spacing : ZUI.Theme.sectionSpacing

            QQC2.Label {
                id: _label1
                Layout.fillWidth: true
                text: "Volume"
                horizontalAlignment: Qt.AlignHCenter
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitWidth: Kirigami.Units.gridUnit * 8 
                QQC2.Dial {
                    id: _dial
                    visible: _barControl.discret
                    height: parent.height
                    width: height
                    anchors.centerIn: parent
                    from: 0
                    to: 1
                    value : 0.5
                    handle: null
                }
                RowLayout {
                    spacing: ZUI.Theme.sectionSpacing
                    height: Kirigami.Units.gridUnit*1.5
                    width: parent.width
                    anchors.centerIn: parent
                    visible: !_barControl.discret
                    Item {
                        id: sliderItem
                       
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                        Layout.alignment: Qt.AlignVCenter
                        
                        MultiPointTouchArea {
                            anchors {
                                fill: parent
                                topMargin: -sliderItem.height // Let's allow for some sloppy interaction here, why not
                            }
                            touchPoints: [
                                TouchPoint {
                                    id: slidePoint;
                                    property var currentValue: undefined
                                    onPressedChanged: {
                                        if (pressed) {
                                            currentValue = zynqtgui.osd.value;
                                            hideTimer.pressed();
                                        } else {
                                            currentValue = undefined;
                                            hideTimer.released();
                                        }
                                    }
                                    onXChanged: {
                                        if (pressed && currentValue !== undefined) {
                                            var delta = (zynqtgui.osd.stop - zynqtgui.osd.start) * ((slidePoint.x - slidePoint.startX) / sliderItem.width);
                                            if (component.invertedScale) {
                                                zynqtgui.osd.setValue(zynqtgui.osd.name, Math.min(Math.max(currentValue + delta, zynqtgui.osd.stop), zynqtgui.osd.start));
                                            } else {
                                                zynqtgui.osd.setValue(zynqtgui.osd.name, Math.min(Math.max(currentValue + delta, zynqtgui.osd.start), zynqtgui.osd.stop));
                                            }
                                        }
                                    }
                                }
                            ]
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: Kirigami.Theme.backgroundColor
                            border {
                                width: 2
                                color: Kirigami.Theme.textColor
                            }
                            radius: height / 2
                        }
                        Item {
                            id: barContainer
                            anchors {
                                fill: parent
                                margins: 4
                                leftMargin: (height / 2) + 4
                                rightMargin: (height / 2) + 3 // This is uneven, but otherwise the visual ends up weird
                            }
                            property double zeroOffset: (zynqtgui.osd.visualZero - zynqtgui.osd.start) / (zynqtgui.osd.stop - zynqtgui.osd.start)
                            Rectangle {
                                anchors {
                                    left: parent.left
                                    leftMargin: parent.width * barContainer.zeroOffset
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                color: Kirigami.Theme.textColor
                                width: (component.invertedScale ? zynqtgui.osd.value < zynqtgui.osd.visualZero : zynqtgui.osd.value > zynqtgui.osd.visualZero) ? parent.width * ((zynqtgui.osd.value - zynqtgui.osd.visualZero) / (zynqtgui.osd.stop - zynqtgui.osd.start)) : 0
                                Rectangle {
                                    anchors {
                                        top: parent.top
                                        bottom: parent.bottom
                                        horizontalCenter: parent.right
                                    }
                                    radius: (height - 1)  / 2
                                    width: height
                                    color: Kirigami.Theme.textColor
                                }
                            }
                            Rectangle {
                                anchors {
                                    left: parent.left
                                    leftMargin: parent.width * barContainer.zeroOffset
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: 1
                                color: Kirigami.Theme.textColor
                            }
                            Rectangle {
                                anchors {
                                    right: parent.left
                                    rightMargin: -parent.width * barContainer.zeroOffset
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                color: Kirigami.Theme.textColor
                                width: (component.invertedScale ? zynqtgui.osd.value > zynqtgui.osd.visualZero : zynqtgui.osd.value < zynqtgui.osd.visualZero) ? (parent.width * barContainer.zeroOffset) - parent.width * ((zynqtgui.osd.value - zynqtgui.osd.start) / (zynqtgui.osd.stop - zynqtgui.osd.start)) : 0
                                Rectangle {
                                    anchors {
                                        top: parent.top
                                        bottom: parent.bottom
                                        horizontalCenter: parent.left
                                    }
                                    radius: (height - 1) / 2
                                    width: height
                                    color: Kirigami.Theme.textColor
                                }
                            }
                        }
                        Item {
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                bottomMargin: -5
                                left: parent.left
                                leftMargin: (parent.width * ((zynqtgui.osd.defaultValue - zynqtgui.osd.start) / (zynqtgui.osd.stop - zynqtgui.osd.start))) - 3
                            }
                            visible: zynqtgui.osd.showVisualZero
                            width: 5
                            clip: true
                            Rectangle {
                                anchors {
                                    verticalCenter: parent.bottom
                                    horizontalCenter: parent.horizontalCenter
                                }
                                height: 3
                                width: 3
                                rotation: 45
                                color: Kirigami.Theme.textColor
                            }
                        }
                    }

                    QQC2.Button {
                        Layout.fillHeight: true
                        visible: zynqtgui.osd.showResetToDefault
                        text: qsTr("Reset")
                        onPressed: hideTimer.pressed();
                        onReleased: hideTimer.released();
                        enabled: zynqtgui.osd.value !== zynqtgui.osd.defaultValue
                        onClicked: {
                            zynqtgui.osd.setValue(zynqtgui.osd.name, zynqtgui.osd.defaultValue);
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight:_rowLabels.implicitHeight
                implicitWidth: Kirigami.Units.gridUnit * 8 

                RowLayout {
                    id: _rowLabels
                    anchors.fill: parent
                    QQC2.Label {
                        id: _label2
                        visible: !_barControl.discret 
                        horizontalAlignment: Qt.AlignLeft
                        text: "-24dB"
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        implicitWidth: 6
                    }

                    QQC2.Label {
                        id: _label4
                        horizontalAlignment: Qt.AlignHCenter
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        implicitWidth: 6
                    }

                    QQC2.Label {
                        id: _label3
                        visible: !_barControl.discret
                        horizontalAlignment: Qt.AlignRight
                        text: "+24dB"
                    }
                }
            }
        }            
    }

    function setAuxKbobPosition(index) {
        switch(index) {
            default:
            case 0: return Kirigami.Units.gridUnit * 6
            case 1: return Kirigami.Units.gridUnit * 16   
            case 2: return Kirigami.Units.gridUnit * 26   
        }
    }

    Rectangle {
        anchors.fill: parent

        color: "transparent"

        BarControl {
            id: _mainKnob
            y: setAuxKbobPosition(zynqtgui.osd.knobPositionIndex)
            text: zynqtgui.osd.description
            minVal: zynqtgui.osd.startLabel === "" ? zynqtgui.osd.start : zynqtgui.osd.startLabel
            maxVal: zynqtgui.osd.stopLabel === "" ? zynqtgui.osd.stop : zynqtgui.osd.stopLabel
            val:  zynqtgui.osd.showValueLabel ? zynqtgui.osd.valueLabel : " "
            discret: false
        }       

        BarControl {
            id: _auxKnob1
            y: setAuxKbobPosition(zynqtgui.osd.auxValue1.knobPositionIndex)  
            text: zynqtgui.osd.auxValue1.name   
            val: zynqtgui.osd.auxValue1.display
            discret: true
            dial {
                from: zynqtgui.osd.auxValue1.from
                to: zynqtgui.osd.auxValue1.to
                value: zynqtgui.osd.auxValue1.value
            }
        }

        BarControl{
            id: _auxKnob2
            y: setAuxKbobPosition(zynqtgui.osd.auxValue2.knobPositionIndex) 
            text: zynqtgui.osd.auxValue2.name   
            val: zynqtgui.osd.auxValue2.display
            discret: true
            dial {
                from: zynqtgui.osd.auxValue2.from
                to: zynqtgui.osd.auxValue2.to
                value: zynqtgui.osd.auxValue2.value
            }                      
        }
    }

    // Item {
    //     implicitWidth: parent.width
    //     implicitHeight: Kirigami.Units.gridUnit * 20
    //     Kirigami.Theme.inherit: false
    //     Kirigami.Theme.colorSet: Kirigami.Theme.View
    //     MouseArea {
    //         anchors.fill: parent
    //         onPressed: hideTimer.pressed();
    //         onReleased: hideTimer.released();
    //     }
    //     ColumnLayout {
    //         anchors.fill: parent
    //         // QQC2.Label {
    //         //     Layout.preferredHeight: Kirigami.Units.gridUnit * 2
    //         //     Layout.fillWidth: true
    //         //     Layout.fillHeight: true
    //         //     horizontalAlignment: Text.AlignHCenter
    //         //     verticalAlignment: Text.AlignVCenter
    //         //     elide: Text.ElideMiddle
    //         //     text: zynqtgui.osd.description
    //         // }
    //         RowLayout {
    //             Layout.fillWidth: true
    //             Layout.preferredHeight: Kirigami.Units.gridUnit * 2
    //             ColumnLayout {
    //                 Layout.fillWidth: true
    //                 // RowLayout {
    //                 //     Layout.fillWidth: true
    //                 //     Layout.preferredHeight: Kirigami.Units.gridUnit
    //                 //     Item {
    //                 //         Layout.preferredWidth: Kirigami.Units.gridUnit * 2
    //                 //     }
    //                 //     QQC2.Label {
    //                 //         text: zynqtgui.osd.startLabel === "" ? zynqtgui.osd.start : zynqtgui.osd.startLabel
    //                 //     }
    //                 //     Item {
    //                 //         Layout.fillWidth: true
    //                 //     }
    //                 //     QQC2.Label {
    //                 //         visible: zynqtgui.osd.showValueLabel
    //                 //         text: zynqtgui.osd.valueLabel
    //                 //     }
    //                 //     Item {
    //                 //         Layout.fillWidth: true
    //                 //     }
    //                 //     QQC2.Label {
    //                 //         text: zynqtgui.osd.stopLabel === "" ? zynqtgui.osd.stop : zynqtgui.osd.stopLabel
    //                 //     }
    //                 //     Item {
    //                 //         Layout.preferredWidth: Kirigami.Units.gridUnit * 2
    //                 //     }
    //                 // }
    //                 // RowLayout {
    //                 //     Layout.fillWidth: true
    //                 //     Layout.fillHeight: true
    //                 //     QQC2.ToolButton {
    //                 //         Layout.fillHeight: true
    //                 //         icon.name: "arrow-left"
    //                 //         onPressed: hideTimer.pressed();
    //                 //         onReleased: hideTimer.released();
    //                 //         enabled: component.invertedScale ? zynqtgui.osd.value < zynqtgui.osd.start : zynqtgui.osd.value > zynqtgui.osd.start
    //                 //         onClicked: {
    //                 //             zynqtgui.osd.setValue(zynqtgui.osd.name, component.invertedScale ? zynqtgui.osd.value + zynqtgui.osd.step : zynqtgui.osd.value - zynqtgui.osd.step);
    //                 //         }
    //                 //     }
                        
    //                 //     QQC2.ToolButton {
    //                 //         Layout.fillHeight: true
    //                 //         icon.name: "arrow-right"
    //                 //         onPressed: hideTimer.pressed();
    //                 //         onReleased: hideTimer.released();
    //                 //         enabled: component.invertedScale ? zynqtgui.osd.value > zynqtgui.osd.stop : zynqtgui.osd.value < zynqtgui.osd.stop
    //                 //         onClicked: {
    //                 //             zynqtgui.osd.setValue(zynqtgui.osd.name, component.invertedScale ? zynqtgui.osd.value - zynqtgui.osd.step : zynqtgui.osd.value + zynqtgui.osd.step);
    //                 //         }
    //                 //     }
    //                 // }
    //             }
    //         }
    //         // RowLayout {
    //         //     Layout.fillWidth: true
    //         //     Layout.preferredHeight: Kirigami.Units.gridUnit * 2
    //         //     Item {
    //         //         Layout.fillWidth: true
    //         //     }
    //         //     QQC2.Button {
    //         //         visible: zynqtgui.osd.showResetToDefault
    //         //         text: qsTr("Reset to default")
    //         //         onPressed: hideTimer.pressed();
    //         //         onReleased: hideTimer.released();
    //         //         enabled: zynqtgui.osd.value !== zynqtgui.osd.defaultValue
    //         //         onClicked: {
    //         //             zynqtgui.osd.setValue(zynqtgui.osd.name, zynqtgui.osd.defaultValue);
    //         //         }
    //         //     }
    //         //     Item {
    //         //         Layout.fillWidth: true
    //         //     }
    //         // }
    //     }
    // }

   
}
