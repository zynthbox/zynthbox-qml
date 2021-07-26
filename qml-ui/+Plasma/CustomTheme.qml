/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

Copyright (C) 2021 Marco Martin <mart@kde.org>

******************************************************************************

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of
the License, or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

For a full copy of the GNU General Public License see the LICENSE.txt file.

******************************************************************************
*/

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
// HACK for old kirigami theme implementation that can be globally set
import org.kde.kirigami 2.0 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore


QtObject {
    id: root

    function syncColors() {
        Kirigami.Theme.textColor = theme.textColor
        Kirigami.Theme.disabledTextColor = "#a1a9b1"

        Kirigami.Theme.highlightColor = theme.highlightColor
        Kirigami.Theme.highlightedTextColor = theme.highlightedTextColor
        Kirigami.Theme.backgroundColor = theme.backgroundColor
        Kirigami.Theme.activeTextColor = theme.highlightColor
        Kirigami.Theme.linkColor = theme.linkColor
        Kirigami.Theme.visitedLinkColor = theme.visitedLinkColor

        Kirigami.Theme.negativeTextColor = theme.negativeTextColor
        Kirigami.Theme.neutralTextColor = theme.neutralTextColor
        Kirigami.Theme.positiveTextColor = theme.positiveTextColor

        Kirigami.Theme.buttonTextColor = theme.buttonTextColor
        Kirigami.Theme.buttonBackgroundColor = theme.buttonBackgroundColor
        Kirigami.Theme.buttonHoverColor = theme.buttonHoverColor
        Kirigami.Theme.buttonFocusColor = theme.buttonFocusColor
        Kirigami.Theme.buttonNegativeTextColor = theme.buttonNegativeTextColor
        Kirigami.Theme.buttonNeutralTextColor = theme.buttonNeutralTextColor
        Kirigami.Theme.buttonPositiveTextColor = theme.buttonPositiveTextColor

        Kirigami.Theme.viewTextColor = theme.viewTextColor
        Kirigami.Theme.viewBackgroundColor = theme.viewBackgroundColor
        Kirigami.Theme.viewHoverColor = theme.viewHoverColor
        Kirigami.Theme.viewFocusColor = theme.viewFocusColor
        Kirigami.Theme.viewNegativeTextColor = theme.viewNegativeTextColor
        Kirigami.Theme.viewNeutralTextColor = theme.viewNeutralTextColor
        Kirigami.Theme.viewPositiveTextColor = theme.viewPositiveTextColor

        Kirigami.Theme.selectionTextColor = theme.highlightedTextColor
        Kirigami.Theme.selectionBackgroundColor = theme.highlightColor
        Kirigami.Theme.selectionHoverColor = theme.selectionHoverColor
        Kirigami.Theme.selectionFocusColor = theme.selectionFocusColor
        Kirigami.Theme.selectionNegativeTextColor = theme.selectionNegativeTextColor
        Kirigami.Theme.selectionNeutralTextColor = theme.selectionNeutralTextColor
        Kirigami.Theme.selectionPositiveTextColor = theme.selectionPositiveTextColor

        Kirigami.Theme.tooltipTextColor = theme.tooltipTextColor
        Kirigami.Theme.tooltipBackgroundColor = theme.tooltipBackgroundColor
        Kirigami.Theme.tooltipHoverColor = theme.tooltipHoverColor
        Kirigami.Theme.tooltipFocusColor = theme.tooltipFocusColor
        Kirigami.Theme.tooltipNegativeTextColor = theme.tooltipNegativeTextColor
        Kirigami.Theme.tooltipNeutralTextColor = theme.tooltipNeutralTextColor
        Kirigami.Theme.tooltipPositiveTextColor = theme.tooltipPositiveTextColor

        Kirigami.Theme.complementaryTextColor = theme.complementaryTextColor
        Kirigami.Theme.complementaryBackgroundColor = theme.complementaryBackgroundColor
        Kirigami.Theme.complementaryHoverColor = theme.complementaryHoverColor
        Kirigami.Theme.complementaryFocusColor = theme.complementaryFocusColor
        Kirigami.Theme.complementaryNegativeTextColor = theme.complementaryNegativeTextColor
        Kirigami.Theme.complementaryNeutralTextColor = theme.complementaryNeutralTextColor
        Kirigami.Theme.complementaryPositiveTextColor = theme.complementaryPositiveTextColor
    }

    Component.onCompleted: {
        root.syncColors()
    }
    property Connections __connections: Connections {
        target: theme
        onThemeChangedProxy: root.syncColors()
    }
}
