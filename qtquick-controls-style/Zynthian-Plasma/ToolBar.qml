/*
    SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.6
import QtQuick.Templates 2.2 as T
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.5 as Kirigami

T.ToolBar {
    id: control

    implicitWidth: Math.max(background.implicitWidth,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background.implicitHeight,
                             contentItem.implicitHeight + topPadding + bottomPadding)

    leftPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    rightPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.smallSpacing

    contentItem: Item { }

    background: PlasmaCore.FrameSvgItem {
        anchors {
            fill: parent
            topMargin: -margins.top
            bottomMargin: -margins.bottom
        }
        implicitHeight: Kirigami.Units.gridUnit * 3
        imagePath: "widgets/background"
        colorGroup: PlasmaCore.ColorScope.colorGroup
        enabledBorders: control.position == T.ToolBar.Footer ? PlasmaCore.FrameSvg.TopBorder : PlasmaCore.FrameSvg.BottomBorder
    }
}
