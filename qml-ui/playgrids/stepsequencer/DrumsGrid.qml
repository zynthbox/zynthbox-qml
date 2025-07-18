/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Base Grid Component 

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>
Copyright (C) 2021 David Nelvand <dnelband@gmail.com>

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
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

ColumnLayout {
    id: component
    property QtObject model
    property bool positionalVelocity
    property bool showChosenPads: true
    property bool showFirstRow: false
    property Item playgrid
    signal removeNote(QtObject note)
    signal notePressAndHold(QtObject note)
    Repeater {
        model: visible ? component.model : null
        delegate: RowLayout {
            property var row: index
            visible: row > 0 || component.showFirstRow
            Repeater {
                model: component.model.columnCount(component.model.index(index, 0))
                delegate: Zynthian.NotePad {
                    positionalVelocity: component.positionalVelocity
                    note: component.model.data(component.model.index(row, index), component.model.roles['note'])
                    property var metadata: component.model.data(component.model.index(row, index), component.model.roles['metadata'])
                    text: metadata != undefined && metadata["displayText"] != undefined ? metadata["displayText"] : ""
                    property color noteColor: note ? zynqtgui.theme_chooser.noteColors[note.midiNote] : ""
                    property color tintedNoteColor: Qt.lighter(noteColor, 1.2)
                    property bool weAreChosen: component.playgrid.noteListeningNotes.length > 0
                        ? component.playgrid.heardNotes.indexOf(note) > -1
                        : component.playgrid.heardNotes.length > 0
                            ? component.playgrid.heardNotes.indexOf(note) > -1
                            : component.playgrid.currentRowUniqueNotes.indexOf(note) > -1
                    backgroundColor: component.showChosenPads && weAreChosen ? noteColor : Kirigami.Theme.textColor
                    playingBackgroundColor: component.showChosenPads && weAreChosen ? tintedNoteColor : noteColor
                    highlightOctaveStart: false
                    onNotePlayed: {
                        if (zynqtgui.backButtonPressed) {
                            component.removeNote(note);
                        }
                    }
                }
            }
        }
    }
}
