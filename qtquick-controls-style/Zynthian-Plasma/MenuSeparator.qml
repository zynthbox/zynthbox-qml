/*
    SPDX-FileCopyrightText: 2019 Alexander Stippich <a.stippich2.4gmx.net>
    SPDX-FileCopyrightText: 2017 The Qt Company Ltd.

    SPDX-License-Identifier: LGPL-3.0-only OR GPL-2.0-or-later
*/


import QtQuick 2.6
import QtQuick.Templates 2.4 as T
import org.kde.kirigami 2.4 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

T.MenuSeparator {
    id: controlRoot

    implicitHeight: topPadding + bottomPadding + separator.implicitHeight
    width: parent.width
    topPadding: Math.floor(Kirigami.Units.smallSpacing / 2)
    bottomPadding: Math.floor(Kirigami.Units.smallSpacing / 2)

    contentItem: Rectangle {
        id: separator
        color: PlasmaCore.ColorScope.textColor
        opacity: 0.2
        anchors.centerIn: controlRoot
        width: controlRoot.width
        implicitHeight: Kirigami.Units.devicePixelRatio
    }
}
