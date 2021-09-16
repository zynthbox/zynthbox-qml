/*
 * SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>
 * SPDX-FileCopyrightText: 2020 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.11
import QtQuick.Layouts 1.11
import QtQuick.Templates 2.2 as T
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.5 as Kirigami
import "../" as PlasmaComponents

GridLayout {
    id: root

    property string labelText: ""

    readonly property bool usingFocusBackground: !parent.flat && buttonSvg.hasElement("hint-focus-highlighted-background") && parent.visualFocus && !(parent.pressed || parent.checked)
    
    PlasmaCore.ColorScope.inherit: true

    columns: parent.display == T.Button.TextBesideIcon ? 2 : 1
    
    rowSpacing: parent.spacing
    columnSpacing: rowSpacing

    Kirigami.Icon { //NOTE: use this to not have blue icons on pressed buttons
        id: icon

        readonly property int defaultIconSize: root.parent.flat ? Kirigami.Units.iconSizes.smallMedium : Kirigami.Units.iconSizes.small

        Layout.alignment: Qt.AlignCenter

        Layout.fillWidth: true
        Layout.fillHeight: true

        Layout.minimumWidth: Math.min(parent.width, parent.height, Layout.preferredWidth)
        Layout.minimumHeight: Math.min(parent.width, parent.height, Layout.preferredHeight)

        Layout.maximumWidth: root.parent.icon.width > 0 ? root.parent.icon.width : Number.POSITIVE_INFINITY
        Layout.maximumHeight: root.parent.icon.height > 0 ? root.parent.icon.height : Number.POSITIVE_INFINITY

        Layout.preferredWidth: root.parent.icon.width > 0 ? root.parent.icon.width : defaultIconSize
        Layout.preferredHeight: root.parent.icon.height > 0 ? root.parent.icon.height : defaultIconSize
        //colorGroup: parent.PlasmaCore.ColorScope.colorGroup
        color:  parent.PlasmaCore.ColorScope.textColor
        visible: source.length > 0 && root.parent.display !== T.Button.TextOnly
        source: root.parent.icon ? (root.parent.icon.name || root.parent.icon.source) : ""
    }
    PlasmaComponents.Label {
        id: label
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: text.length > 0 && root.parent.display !== T.Button.IconOnly
        text: labelText
        font: root.parent.font
        color: usingFocusBackground ? PlasmaCore.ColorScope.highlightedTextColor : PlasmaCore.ColorScope.textColor
        horizontalAlignment: root.parent.display !== T.Button.TextUnderIcon && icon.visible ? Text.AlignLeft : Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    PlasmaCore.Svg {
        id: buttonSvg
        imagePath: "widgets/button"
    }
}
