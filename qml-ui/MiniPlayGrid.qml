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

import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import "pages" as Pages

QQC2.StackView {
    id: component
    clip: true
    initialItem: playGridsRepeater.count === 0 ? null : playGridsRepeater.itemAt(zynthian.miniplaygrid.playGridIndex).item.miniGrid

    Repeater {
        id:playGridsRepeater
        model: zynthian.miniplaygrid.playgrids
        property Item currentItem: playGridsRepeater.count === 0 ? null : playGridsRepeater.itemAt(zynthian.miniplaygrid.playGridIndex).item
        Loader {
            id:playGridLoader
            source: modelData + "/main.qml"
            Binding {
                target: playGridLoader.item
                property: 'currentNoteName'
                value: component.currentNoteName
            }
        }
    }

    property string currentNoteName: keyModel.getName(zynthian.miniplaygrid.startingNote)
    ListModel {
        id: keyModel
        function getName(note) {
            for(var i = 0; i < keyModel.rowCount(); ++i) {
                var le = keyModel.get(i);
                if (le.note = note) {
                    return le.text;
                }
            }
            return "C";
        }

        ListElement { note: 36; text: "C" }
        ListElement { note: 37; text: "C#" }
        ListElement { note: 38; text: "D" }
        ListElement { note: 39; text: "D#" }
        ListElement { note: 40; text: "E" }
        ListElement { note: 41; text: "F" }
        ListElement { note: 42; text: "F#" }
        ListElement { note: 43; text: "G" }
        ListElement { note: 44; text: "G#" }
        ListElement { note: 45; text: "A" }
        ListElement { note: 46; text: "A#" }
        ListElement { note: 47; text: "B" }
    }
}
