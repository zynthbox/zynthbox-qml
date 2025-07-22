/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

Copyright (C) 2021 Marco Martin <mart@kde.org>

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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import Zynthian 1.0 as Zynthian
import "." as Here
import QtGraphicalEffects 1.15

Zynthian.AbstractController {
    id: root
    // property alias valueLabel: valueLabel.text

    property alias value: slider.value
    property alias from: slider.from
    property alias to: slider.to
    property alias stepSize: slider.stepSize
    property alias snapMode: slider.snapMode
    property alias slider: slider
    highlighted: slider.activeFocus

    property color highlightColor : "#5765f2"
    property color backgroundColor: "#333"
    property color foregroundColor: "#fafafa"
    property color alternativeColor :  "#16171C"

    padding: 5

    background: null
    title: ""

    control: ColumnLayout {
        onActiveFocusChanged: {
            if (activeFocus) {
                slider.forceActiveFocus();
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.controller.ctrl ? root.controller.ctrl.title : ""
            font.capitalization: Font.AllUppercase
            font.weight: Font.DemiBold
            font.family: "Hack"
            font.pointSize: 9
            color: root.foregroundColor
        }

        QQC2.Slider {
            id: slider
            implicitWidth: horizontal ? 300 : 28
            implicitHeight: horizontal ? 28 : 300
            Layout.fillWidth: horizontal ? true : false
            Layout.fillHeight: horizontal ? false : true
            Layout.alignment: Qt.AlignCenter

            orientation: Qt.Vertical
            stepSize: root.controller.ctrl ? (root.controller.ctrl.step_size === 0 ? 1 : root.controller.ctrl.step_size) : 0
            value: root.controller.ctrl ? root.controller.ctrl.value : 0
            from: root.controller.ctrl ? root.controller.ctrl.value0 : 0
            to: root.controller.ctrl ? root.controller.ctrl.max_value : 0
            onMoved: root.controller.ctrl.value = value

            padding: 4

            handle: Rectangle {
                x: slider.orientation === Qt.Horizontal ? slider.leftPadding + slider.visualPosition * (slider.availableWidth - width) :
                                                          slider.leftPadding + slider.availableWidth / 2 - width / 2

                y: slider.orientation === Qt.Horizontal ?  slider.topPadding + slider.availableHeight / 2 - height / 2 :
                                                          slider.topPadding + slider.visualPosition * (slider.availableHeight - height)

                implicitWidth: slider.orientation === Qt.Horizontal ? 36 : _bgBox.width -4
                implicitHeight: slider.orientation === Qt.Horizontal  ? _bgBox.height -4 :  36
                radius: 6
                color: root.backgroundColor
                border.color: Qt.darker(root.alternativeColor, 2)

                    Rectangle {
                        color: "transparent"
                        border.color: Qt.lighter(root.alternativeColor, 2)
                        border.width :2
                        radius: parent.radius
                        anchors.fill: parent
                        anchors.margins: 1
                    }

                    Rectangle {
                        height: slider.horizontal ? 8 : 16
                        width: slider.horizontal ?  16 : 8
                        radius: slider.horizontal ? 4 : 8
                        anchors.centerIn: parent

                        color: root.highlightColor
                        border.color: Qt.darker(color, 1.8)
                    }
                }

            background: Rectangle {

                border.color: slider.pressed ? root.highlightColor : root.backgroundColor
                color: "transparent"
                radius: 6


                Rectangle {
                    id: _bgBox
                    visible: false
                    anchors.fill: parent
                    anchors.margins: 1
                    color: root.backgroundColor
                    radius: parent.radius
                    border.color: Qt.darker(color, 1.8)
                }

                InnerShadow {
                    anchors.fill: _bgBox
                    radius: 8.0
                    samples: 16
                    horizontalOffset: 1
                    verticalOffset: 3
                    color: "#b0000000"
                    source: _bgBox
                }

                Rectangle {
                    visible: slider.orientation === Qt.Horizontal

                     anchors.verticalCenter: parent.verticalCenter
                     anchors.left: parent.left
                     anchors.right: parent.right
                     anchors.margins: 5
                     border.color: Qt.darker(color, 2)
                     color: root.alternativeColor
                     height: 8
                     radius: 5

                    Rectangle {
                        height: parent.height
                        width: slider.position * parent.width
                        color: root.highlightColor
                        radius: parent.radius
                        border.color: parent.border.color
                        RadialGradient {
                            anchors.fill: parent
                            opacity: 0.7
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.lighter(root.highlightColor, 2) }
                                GradientStop { position: 0.5; color: "transparent" }
                            }
                        }
                    }
                }


                Rectangle {
                    visible: slider.orientation === Qt.Vertical
                     anchors.horizontalCenter: parent.horizontalCenter
                     anchors.top: parent.top
                     anchors.bottom: parent.bottom
                     anchors.margins: 5
                     border.color: Qt.darker(color, 2)
                     color: root.alternativeColor
                     width: 8
                     radius: 5

                    Rectangle {
                        width: parent.width
                        height: (slider.position * parent.height)
                        anchors.bottom: parent.bottom
                        color: root.highlightColor
                        radius: parent.radius
                        border.color: parent.border.color
                        RadialGradient {
                            anchors.fill: parent
                            opacity: 0.7
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.lighter(root.highlightColor, 2) }
                                GradientStop { position: 0.5; color: "transparent" }
                            }
                        }
                    }
                }
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.controller.ctrl ? root.controller.ctrl.value_print : ""
            font.capitalization: Font.AllUppercase
            font.weight: Font.DemiBold
            font.family: "Hack"
            font.pointSize: 9
            fontSizeMode: Text.Fit
            minimumPointSize: 6
            wrapMode: Text.NoWrap

            font.letterSpacing: 2
            color: root.foregroundColor
            padding: 4

            background: Rectangle {

                border.width: 2
                border.color: root.backgroundColor
                color: root.alternativeColor
                radius: 4

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1

                    visible: false
                    id: _recLabel
                    color:  slider.pressed ? root.highlightColor : root.alternativeColor
                    border.color: Qt.darker(color, 2)
                    radius: 4

                }

                InnerShadow {
                    anchors.fill: _recLabel
                    radius: 8.0
                    samples: 16
                    horizontalOffset: -3
                    verticalOffset: 1
                    color: "#b0000000"
                    source: _recLabel
                }
            }
        }
    }
}


