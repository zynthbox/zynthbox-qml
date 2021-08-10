/*
 * SPDX-FileCopyrightText: 2017 Marco Martin <notmart@gmail.com>
 * SPDX-FileCopyrightText: 2020 Nate Graham <nate@kde.org>
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Templates 2.4 as T
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import "private" as Private

T.SpinBox {
    id: control

    implicitWidth: Math.max(units.gridUnit * 6, contentItem.implicitWidth + 2 * padding + up.indicator.implicitWidth + down.indicator.implicitWidth)
    implicitHeight: units.gridUnit * 1.6

    padding: 6
    leftPadding: padding + height
    rightPadding: padding + height

    validator: IntValidator {
        locale: control.locale.name
        bottom: Math.min(control.from, control.to)
        top: Math.max(control.from, control.to)
    }

    contentItem: TextInput {
        id: textField
        property int originalValue

        text: control.textFromValue(control.value, control.locale)
        opacity: control.enabled ? 1 : 0.6

        font: control.font
        color: theme.viewTextColor
        selectionColor: theme.highlightColor
        selectedTextColor: theme.highlightedTextColor
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter

        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly

        // Allow adjusting the value by scrolling over it
        MouseArea {
            anchors.fill: parent

            // Because we're stomping the Text Input's own mouse handling
            cursorShape: Qt.IBeamCursor

            // Have to cache the original value for the drag handler
            onPressed: {
                textField.originalValue = control.value
                // Because we're stomping the Text Input's own mouse handling
                mouse.accepted = false
            }
            onWheel: {
                if (wheel.angleDelta.y > 0 && control.value <= control.to) {
                    control.value += control.stepSize
                    control.valueModified()
                } else if (wheel.angleDelta.y < 0 && control.value >= control.from) {
                    control.value -= control.stepSize
                    control.valueModified()
                }
            }
        }
    }

    up.indicator: Item {
        x: control.mirrored ? 0 : parent.width - width
        implicitHeight: parent.height
        implicitWidth: implicitHeight
        PlasmaCore.FrameSvgItem {
            anchors {
                fill: parent
                margins: base.margins.right
            }
            imagePath: "widgets/button"
            prefix: up.pressed ? "pressed" : "normal"
            PlasmaComponents3.Label {
                anchors.centerIn: parent
                font: control.font
                text: "+"
            }
        }
    }

    down.indicator:Item {
        x: control.mirrored ? parent.width - width : 0
        implicitHeight: parent.height
        implicitWidth: implicitHeight
        PlasmaCore.FrameSvgItem {
            anchors {
                fill: parent
                margins: base.margins.left
            }
            imagePath: "widgets/button"
            prefix: down.pressed ? "pressed" : "normal"
            PlasmaComponents3.Label {
                anchors.centerIn: parent
                font: control.font
                text: "-"
            }
        }
    }

    background: Item {
        Private.TextFieldFocus {
            state: control.activeFocus ? "focus" : (control.hovered ? "hover" : "hidden")
            anchors.fill: parent
        }
        PlasmaCore.FrameSvgItem {
            id: base
            anchors.fill: parent
            imagePath: "widgets/lineedit"
            prefix: "base"
        }
    }
}
