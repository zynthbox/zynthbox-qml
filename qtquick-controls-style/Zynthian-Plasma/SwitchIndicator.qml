/*
    SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.6
import org.kde.plasma.core 2.0 as PlasmaCore
import "private" as Private
import org.kde.kirigami 2.4 as Kirigami

Item {
	id: root
    property Item control
    implicitWidth: Math.round(Kirigami.Units.gridUnit * 1.5)
    implicitHeight : Kirigami.Units.gridUnit

    opacity: control.enabled ? 1 : 0.6

    Rectangle {
        anchors.fill: parent
        radius: height
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Button
        color: control.checked ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.4)
    }

    PlasmaCore.SvgItem {
        x: control.mirrored ? (control.checked ? 0 : parent.width - width) : (control.checked ? parent.width - width : 0)
        anchors.verticalCenter: parent.verticalCenter
        svg: PlasmaCore.Svg {
            id: buttonSvg
            imagePath: "widgets/actionbutton"
        }
        elementId: "normal"

        height: parent.height
        width: height

        Private.RoundShadow {
            anchors.fill: parent
            z: -1
            state: control.activeFocus ? "focus" : (control.hovered ? "hover" : "shadow")
        }
        //Behavior on x {
            //XAnimator {
                //duration: Kirigami.Units.longDuration
                //easing.type: Easing.InOutQuad
            //}
        //}
    }
}

