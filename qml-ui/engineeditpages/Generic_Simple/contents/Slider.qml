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

QQC2.Slider {
    id: slider
    implicitWidth: horizontal ? 300 : 28
    implicitHeight: horizontal ? 28 : 300

    property color highlightColor : "#5765f2"
    property color backgroundColor: "#333"
    property color foregroundColor: "#fafafa"
    property color alternativeColor :  "#16171C"

    orientation: Qt.Vertical

    padding: 4

    handle: Rectangle {
        x: slider.orientation === Qt.Horizontal ? slider.leftPadding + slider.visualPosition * (slider.availableWidth - width) :
                                                  slider.leftPadding + slider.availableWidth / 2 - width / 2

        y: slider.orientation === Qt.Horizontal ?  slider.topPadding + slider.availableHeight / 2 - height / 2 :
                                                  slider.topPadding + slider.visualPosition * (slider.availableHeight - height)

        implicitWidth: slider.orientation === Qt.Horizontal ? 36 : _bgBox.width -4
        implicitHeight: slider.orientation === Qt.Horizontal  ? _bgBox.height -4 :  36
        radius: 6
        color: slider.backgroundColor
        border.color: Qt.darker(slider.alternativeColor, 2)

        Rectangle {
            color: "transparent"
            border.color: Qt.lighter(slider.alternativeColor, 2)
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

            color: slider.highlightColor
            border.color: Qt.darker(color, 1.8)
        }
    }

    background: Rectangle {

        border.color: slider.pressed ? slider.highlightColor : slider.backgroundColor
        color: "transparent"
        radius: 6


        Rectangle {
            id: _bgBox
            visible: false
            anchors.fill: parent
            anchors.margins: 1
            color: slider.backgroundColor
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
            color: slider.alternativeColor
            height: 8
            radius: 5

            Rectangle {
                height: parent.height
                width: slider.position * parent.width
                color: slider.highlightColor
                radius: parent.radius
                border.color: parent.border.color
                RadialGradient {
                    anchors.fill: parent
                    opacity: 0.7
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.lighter(slider.highlightColor, 2) }
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
            color: slider.alternativeColor
            width: 8
            radius: 5

            Rectangle {
                width: parent.width
                height: (slider.position * parent.height)
                anchors.bottom: parent.bottom
                color: slider.highlightColor
                radius: parent.radius
                border.color: parent.border.color
                RadialGradient {
                    anchors.fill: parent
                    opacity: 0.7
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.lighter(slider.highlightColor, 2) }
                        GradientStop { position: 0.5; color: "transparent" }
                    }
                }
            }
        }
    }
}


