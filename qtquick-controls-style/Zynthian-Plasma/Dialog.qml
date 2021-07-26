/*
    SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.6
import QtQuick.Templates 2.4 as T
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.4 as Kirigami

T.Dialog {
    id: control

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentWidth > 0 ? contentWidth + leftPadding + rightPadding : 0)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             contentWidth > 0 ? contentHeight + topPadding + bottomPadding : 0)

    contentWidth: contentItem.implicitWidth || (contentChildren.length === 1 ? contentChildren[0].implicitWidth : 0)
    contentHeight: contentItem.implicitHeight || (contentChildren.length === 1 ? contentChildren[0].implicitHeight : 0)

    leftPadding: background.margins.left
    topPadding: background.margins.top
    rightPadding: background.margins.right
    bottomPadding: background.margins.bottom

    T.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.8)
		opacity: control.visible
		Behavior on opacity {
            OpacityAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutQuad
            }
        }
    }

    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            easing.type: Easing.OutCubic
            duration: Kirigami.Units.shortDuration
        }
        NumberAnimation {
            property: "scale"
            from: 0.8
            to: 1
            easing.type: Easing.OutQuad
            duration: Kirigami.Units.shortDuration
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            easing.type: Easing.InCubic
            duration: Kirigami.Units.shortDuration
        }
        NumberAnimation {
            property: "scale"
            from: 1
            to: 0.8
            easing.type: Easing.InQuad
            duration: Kirigami.Units.shortDuration
        }
    }

    contentItem: Item { }

    background: PlasmaCore.FrameSvgItem {
        implicitWidth: Kirigami.Units.gridUnit * 12
        imagePath: "widgets/background"
    }

    footer: DialogButtonBox {
        position: DialogButtonBox.Footer
    }
}
