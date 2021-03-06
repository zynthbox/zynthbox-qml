/*
    SPDX-FileCopyrightText: 2018 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.6
import QtQuick.Layouts 1.2
import QtQuick.Templates 2.2 as T
import QtQuick.Templates 2.2 as QQC2
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.5 as Kirigami
import "private" as Private

T.RoundButton {
    id: control

    implicitWidth: Math.max(Kirigami.Units.gridUnit, contentItem.implicitWidth)
                            + leftPadding + rightPadding
    implicitHeight: Math.max(Kirigami.Units.gridUnit, contentItem.implicitHeight)
                            + topPadding + bottomPadding

    radius: Math.min(width, height) / 2
    // The 0 padding when text exists used to be surfaceNormal.margins.left, but that element no longer exists
    leftPadding: text.length > 0 ? 0 : contentItem.extraSpace
    topPadding: text.length > 0 ? 0 : contentItem.extraSpace
    rightPadding: text.length > 0 ? 0 : contentItem.extraSpace
    bottomPadding: text.length > 0 ? 0 : contentItem.extraSpace

    hoverEnabled: !Kirigami.Settings.tabletMode

    contentItem: RowLayout {
        // This is the spacing which will make the icon a square inscribed in the circle with an extra smallspacing of margins
        readonly property int extraSpace: implicitWidth/2 - implicitWidth/2*Math.sqrt(2)/2 + Kirigami.Units.smallSpacing
        PlasmaCore.IconItem {
            id: iconItem
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: source.length > 0
            source: control.icon ? (control.icon.name || control.icon.source) : ""
            opacity: control.enabled ? 1 : 0.5
        }
        QQC2.Label {
            Layout.fillWidth: !iconItem.visible
            visible: text.length > 0
            text: control.text
            font: control.font
            opacity: enabled || control.highlighted || control.checked ? 1 : 0.4
            color: Kirigami.Theme.textColor
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Button
        color: control.checked || control.highlighted
                ? Kirigami.Theme.highlightColor
                : Kirigami.Theme.backgroundColor
        radius: control.radius
        border {
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.4)
        }
        opacity: control.enabled ? 1 : 0.5

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0; color: control.pressed ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.05)}
                GradientStop { position: 1; color: control.pressed ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.05)}
            }
        }
    }
}
