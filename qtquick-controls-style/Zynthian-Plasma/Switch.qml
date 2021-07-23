/*
    SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.6
import QtQuick.Templates 2.4 as T
import QtQuick.Controls 2.4
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.4 as Kirigami

T.Switch {
    id: control

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Kirigami.Units.gridUnit * 1.6
    baselineOffset: contentItem.y + contentItem.baselineOffset

    padding: 1
    spacing: Math.round(Kirigami.Units.gridUnit / 8)

    hoverEnabled: true

    indicator: SwitchIndicator {
        control: control
        LayoutMirroring.enabled: control.mirrored
        LayoutMirroring.childrenInherit: true
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        width: control.text.length > 0 ? implicitWidth : parent.width
        height: control.text.length > 0 ? implicitHeight : parent.height
    }

    contentItem: Label {
        leftPadding: control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0
        opacity: control.enabled ? 1 : 0.6
        text: control.text
        font: control.font
        color: PlasmaCore.ColorScope.textColor
        elide: Text.ElideRight
        visible: control.text
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }
}
