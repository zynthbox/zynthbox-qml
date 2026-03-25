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

import io.zynthbox.ui 1.0 as ZUI
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
    readonly property var noteColors: zynqtgui.theme_chooser.noteColors
    Repeater {
        id: rowRepeater
        model: 10 // Arbitrary number is arbitrary. Too many, really, but then we'll have the rows to work with if we want it
        delegate: RowLayout {
            id: rowLayout
            property var row: index
            visible: (row > 0 || component.showFirstRow) && row < component.model.rowCount()
            Repeater {
                id: columnRepeater
                model: 16 // Arbitrary number is arbitrary, but it will do for us for the moment
                readonly property int columnCount: component.model.columnCount(component.model.index(index, 0))
                delegate: ZUI.NotePad {
                    visible: component.visible && index < columnRepeater.columnCount
                    positionalVelocity: component.positionalVelocity
                    note: visible && component.model.lastModified > 0 ? component.model.data(component.model.index(row, index), component.model.roles['note']) : null
                    property var metadata: visible && component.model.lastModified > 0 ? component.model.data(component.model.index(row, index), component.model.roles['metadata']) : undefined
                    text: metadata !== undefined && metadata["displayText"] !== undefined ? metadata["displayText"] : ""
                    property color noteColor: note ? component.noteColors[note.midiNote] : ""
                    property color tintedNoteColor: Qt.lighter(noteColor, 1.2)
                    property bool weAreChosen: applicationWindow().globalSequencer.noteListeningNotes.length > 0
                        ? applicationWindow().globalSequencer.heardNotes.indexOf(note) > -1
                        : component.playgrid.selectedStep > -1 && applicationWindow().globalSequencer.heardNotes.length > 0
                            ? applicationWindow().globalSequencer.heardNotes.indexOf(note) > -1
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
