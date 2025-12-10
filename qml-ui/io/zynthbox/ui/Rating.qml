/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Basic star based ratings component (based on the KNewStuff Rating component)

Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import QtQuick.Controls 2.2 as QtControls

import org.kde.kirigami 2.0 as Kirigami

RowLayout
{
    id: view
    property int max: 100
    property int rating: 0
    property real starSize: Kirigami.Units.gridUnit

    clip: true
    spacing: 0

    readonly property var ratingIndex: Math.floor((theRepeater.count*view.rating)/view.max)
    readonly property var ratingHalf: (theRepeater.count*view.rating)%view.max >= view.max / 2

    Repeater {
        id: theRepeater
        model: 5
        delegate: Kirigami.Icon {
            Layout.minimumWidth: view.starSize
            Layout.minimumHeight: view.starSize
            Layout.preferredWidth: view.starSize
            Layout.preferredHeight: view.starSize

            source: index < view.ratingIndex
                ? "rating"
                : (view.ratingHalf && index == view.ratingIndex
                    ? "rating-half"
                    : "rating-unrated")
            opacity: 1
        }
    }
    Item {
        Layout.minimumHeight: view.starSize;
        Layout.minimumWidth: Kirigami.Units.smallSpacing;
        Layout.maximumWidth: Kirigami.Units.smallSpacing;
    }
    QtControls.Label {
        id: ratingAsText
        Layout.minimumWidth: view.starSize
        Layout.minimumHeight: view.starSize
        text: i18ndc("knewstuff5", "A text representation of the rating, shown as a fraction of the max value", "(%1/%2)", view.rating / 10, view.max / 10)
    }
}
