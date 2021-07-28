/*
    SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.6
import QtQuick.Templates 2.4 as T
import org.kde.plasma.core 2.0 as PlasmaCore
import "private" as Private

T.Slider {
    id: control

    implicitWidth: control.orientation === Qt.Horizontal ? PlasmaCore.Units.gridUnit * 12 : PlasmaCore.Units.gridUnit * 1.6
    implicitHeight: control.orientation === Qt.Horizontal ? PlasmaCore.Units.gridUnit * 1.6 : PlasmaCore.Units.gridUnit * 12

    wheelEnabled: true
    snapMode: T.Slider.SnapOnRelease

    PlasmaCore.Svg {
        id: grooveSvg
        imagePath: "widgets/slider"
        colorGroup: PlasmaCore.ColorScope.colorGroup

    }
    handle: Item {
        property bool horizontal: control.orientation === Qt.Horizontal
        x: Math.round(control.leftPadding + (horizontal ? control.visualPosition * (control.availableWidth - width) : (control.availableWidth - width) / 2))
        y: Math.round(control.topPadding + (horizontal ? (control.availableHeight - height) / 2 : control.visualPosition * (control.availableHeight) - height/2))

        width: grooveSvg.hasElement("hint-handle-size") ? grooveSvg.elementSize("hint-handle-size").width : firstHandle.width
        height: grooveSvg.hasElement("hint-handle-size") ? grooveSvg.elementSize("hint-handle-size").height : firstHandle.height

        Private.RoundShadow {
            anchors.fill: firstHandle
            imagePath: "widgets/slider"
            focusElement: parent.horizontal ? "horizontal-slider-focus" : "vertical-slider-focus"
            hoverElement: parent.horizontal ? "horizontal-slider-hover" : "vertical-slider-hover"
            shadowElement: parent.horizontal ? "horizontal-slider-shadow" : "vertical-slider-shadow"
            state: control.activeFocus ? "focus" : (control.hovered ? "hover" : "shadow")
        }
        PlasmaCore.SvgItem {
            id: firstHandle
            anchors.centerIn: parent
            width: naturalSize.width
            height: naturalSize.height
            svg: grooveSvg
            elementId: parent.horizontal ? "horizontal-slider-handle" : "vertical-slider-handle"
        }
    }

    background: PlasmaCore.FrameSvgItem {
        imagePath: "widgets/slider"
        prefix: "groove"
        colorGroup: PlasmaCore.ColorScope.colorGroup
        readonly property bool horizontal: control.orientation === Qt.Horizontal
        implicitWidth: horizontal ? PlasmaCore.Units.gridUnit * 8 : margins.left + margins.right
        implicitHeight: horizontal ? margins.top + margins.bottom : PlasmaCore.Units.gridUnit * 8
        width: horizontal ? control.availableWidth : implicitWidth
        height: horizontal ? implicitHeight : control.availableHeight
        anchors.centerIn: parent
        scale: horizontal && control.mirrored ? -1 : 1
        opacity: control.enabled ? 1 : 0.6

        PlasmaCore.FrameSvgItem {
            imagePath: "widgets/slider"
            prefix: "groove-highlight"
            colorGroup: PlasmaCore.ColorScope.colorGroup
            x: parent.horizontal ? 0 : (parent.width - width) / 2
            y: parent.horizontal ? (parent.height - height) / 2 : parent.height - height
            width: Math.max(margins.left + margins.right,
                            parent.horizontal 
                            ? (Qt.application.layoutDirection === Qt.LeftToRight
                                ? control.visualPosition * (parent.width - control.handle.width) + control.handle.width/2
                                : parent.width - control.visualPosition * (parent.width - control.handle.width) - control.handle.width/2)
                            : parent.width)
            height: Math.max(margins.top + margins.bottom,
                             parent.horizontal
                             ? parent.height
                             : parent.height - control.visualPosition * parent.height)
        }

        Repeater {
            id: repeater
            readonly property int stepCount: (control.to - control.from) / control.stepSize
            model: control.stepSize && stepCount < 20 ? 1 + stepCount : 0
            anchors.fill: parent

            Rectangle {
                color: PlasmaCore.ColorScope.textColor
                opacity: 0.3
                width: background.horizontal ? PlasmaCore.Units.devicePixelRatio : PlasmaCore.Units.gridUnit/2
                height: background.horizontal ? PlasmaCore.Units.gridUnit/2 : PlasmaCore.Units.devicePixelRatio
                y: background.horizontal ? background.height + PlasmaCore.Units.devicePixelRatio : handle.height / 2 + index * ((repeater.height - handle.height) / (repeater.count > 1 ? repeater.count - 1 : 1))
                x: background.horizontal ? handle.width / 2 + index * ((repeater.width - handle.width) / (repeater.count > 1 ? repeater.count - 1 : 1)) : background.width
            }
        }
    }
}
