/*
    SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.6
import QtQuick.Templates 2.4 as T
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.4 as Kirigami

T.DialogButtonBox {
    id: control

    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding

    spacing: Kirigami.Units.smallSpacing
    leftPadding: parent ? parent.leftPadding : 0
    topPadding: parent ? parent.topPadding : 0
    rightPadding: parent ? parent.rightPadding : 0
    bottomPadding: parent ? parent.bottomPadding : 0
    alignment: Qt.AlignRight

    delegate: Button {
        width: Math.min(implicitWidth, control.width / control.count - control.rightPadding - control.spacing * (control.count-1))
    }

    contentItem: ListView {
        implicitWidth: contentWidth
        implicitHeight: Kirigami.Units.gridUnit * 3

        model: control.contentModel
        spacing: control.spacing
        orientation: ListView.Horizontal
        boundsBehavior: Flickable.StopAtBounds
        snapMode: ListView.SnapToItem
    }

    background: Item {}
}
