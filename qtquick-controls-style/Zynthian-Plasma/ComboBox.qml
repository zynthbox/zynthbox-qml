/*
    SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.6
import QtQuick.Window 2.2
import QtQuick.Templates 2.4 as T
import QtQuick.Controls 2.4 as Controls
import QtGraphicalEffects 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.5 as Kirigami
import "private" as Private

T.ComboBox {
    id: control

    implicitWidth: Math.max(units.gridUnit, contentItem.implicitWidth)
                             + leftPadding + rightPadding + indicator.implicitWidth + rightPadding
    implicitHeight: Math.max(units.gridUnit, contentItem.implicitHeight)
                            + topPadding + bottomPadding
    baselineOffset: contentItem.y + contentItem.baselineOffset

    hoverEnabled: true
    topPadding: surfaceNormal.margins.top
    leftPadding: surfaceNormal.margins.left
    rightPadding: surfaceNormal.margins.right + units.gridUnit * 2
    bottomPadding: surfaceNormal.margins.bottom

    delegate: ItemDelegate {
        width: control.popup.width
        text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData
        highlighted: control.highlightedIndex == index
        property bool separatorVisible: false
    }

    indicator: PlasmaCore.SvgItem {
        implicitWidth: units.iconSizes.small
        implicitHeight: implicitWidth
        anchors {
            right: parent.right
            rightMargin: surfaceNormal.margins.right
            verticalCenter: parent.verticalCenter
        }
        svg: PlasmaCore.Svg {
            imagePath: "widgets/arrows"
            colorGroup: theme.ButtonColorGroup ? theme.ButtonColorGroup : 0
        }
        elementId: "down-arrow"
    }

    contentItem: T.TextField {
        id: textField
        padding: 0
        text: control.editable ? control.editText : control.displayText

        enabled: control.editable
        autoScroll: control.editable
        
        readOnly: control.down || !control.hasOwnProperty("editable") || !control.editable
        inputMethodHints: control.inputMethodHints
        validator: control.validator

        // Work around Qt bug where NativeRendering breaks for non-integer scale factors
        // https://bugreports.qt.io/browse/QTBUG-70481
        renderType: Screen.devicePixelRatio % 1 !== 0 ? Text.QtRendering : Text.NativeRendering
        color: PlasmaCore.ColorScope.textColor
        selectionColor: Kirigami.Theme.highlightColor
        selectedTextColor: Kirigami.Theme.highlightedTextColor

        selectByMouse: !Kirigami.Settings.tabletMode
        cursorDelegate: Kirigami.Settings.tabletMode && typeof(mobileCursor) !== "undefined" ? mobileCursor : null

        font: control.font
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        opacity: control.enabled ? 1 : 0.3

        onPressAndHold: {
            if (!Kirigami.Settings.tabletMode) {
                return;
            }
            forceActiveFocus();
            cursorPosition = positionAt(event.x, event.y);
            selectWord();
        }
    }

    background: PlasmaCore.FrameSvgItem {
        id: surfaceNormal
        anchors.fill: parent
        readonly property bool editable: control.hasOwnProperty("editable") && control.editable
        imagePath: editable ? "widgets/lineedit" : "widgets/button"
        prefix: editable
                ? "base"
                : (control.pressed ? "pressed" : "normal")

        Private.ButtonShadow {
            anchors.fill: parent
            showShadow: !parent.editable && !control.pressed
        }

        Private.TextFieldFocus {
            visible: parent.editable
            z: -1
            state: control.activeFocus ? "focus" : (control.hovered ? "hover" : "hidden")
            anchors.fill: parent
        }

        Private.ButtonFocus {
            anchors.fill: parent
            showFocus: control.activeFocus && !control.pressed
        }

        Private.ButtonHover {
            anchors.fill: parent
            showHover: control.hovered && !control.pressed
        }

        MouseArea {
            anchors {
                fill: parent
                leftMargin: control.leftPadding
                rightMargin: control.rightPadding
            }
            acceptedButtons: Qt.NoButton
            onWheel: {
                if (wheel.pixelDelta.y < 0 || wheel.angleDelta.y < 0) {
                    control.currentIndex = Math.min(control.currentIndex + 1, delegateModel.count -1);
                } else {
                    control.currentIndex = Math.max(control.currentIndex - 1, 0);
                }
                control.activated(control.currentIndex);
            }
        }
    }

    popup: T.Popup {
        x: control.mirrored ? control.width - width : 0
        y: control.height
        width: Math.max(control.width, 150)
        implicitHeight: contentItem.implicitHeight
        topMargin: 6
        bottomMargin: 6

        contentItem: ListView {
            id: listView
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            highlightRangeMode: ListView.ApplyRange
            highlightMoveDuration: 0
            // HACK: When the ComboBox is not inside a top-level Window, it's Popup does not inherit
            // the LayoutMirroring options. This is a workaround to fix this by enforcing
            // the LayoutMirroring options properly.
            // QTBUG: https://bugreports.qt.io/browse/QTBUG-66446
            LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
            LayoutMirroring.childrenInherit: true
            T.ScrollBar.vertical: Controls.ScrollBar { }
        }
        background: Rectangle {
            anchors {
                fill: parent
                margins: -1
            }
            radius: 2
            color: theme.viewBackgroundColor
            border.color: Qt.rgba(PlasmaCore.ColorScope.textColor.r, PlasmaCore.ColorScope.textColor.g, PlasmaCore.ColorScope.textColor.b, 0.3)
            layer.enabled: true

            layer.effect: DropShadow {
                transparentBorder: true
                radius: 4
                samples: 8
                horizontalOffset: 2
                verticalOffset: 2
                color: Qt.rgba(0, 0, 0, 0.3)
            }
        }
    }
}
