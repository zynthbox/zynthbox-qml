/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Base Play Grid Component 

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
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
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import io.zynthbox.ui 1.0 as ZUI

ZUI.BasePlayGrid {
    id: component
    name: "AmazeGrid"
    grid: amazeGrid
    settings: amazeSettings

    defaults: {
        "startingNote": 60,
        "rows": 3,
        "columns": 3,
    }

    QtObject {
        id: _private
        property QtObject model
        property int startingNote
        property int rows
        property int columns
    }

    function fillModel(model, startingNote, rows, columns) {
        var col = startingNote;
        model.clear();
        for (var row = 0; row < rows; ++row){
            var notes = [];
            for (var i = 0; i < columns; ++i) {
                var note = component.getNote(col);
                col++
                notes.push(note);
            }
            model.addRow(notes);
        }
    }

    function populateGrid(){
        fillModel(_private.model, _private.startingNote, _private.scale, _private.rows, _private.columns, _private.positionalVelocity)
    }

    onInitialize: {
        _private.startingNote = component.getProperty("startingNote")
        _private.rows = component.getProperty("rows")
        _private.columns = component.getProperty("columns")

        _private.model = component.getModel("main")
        if (_private.model.rows == 0) {
            populateGridTimer.restart()
        }
    }

    onPropertyChanged: {
        var changed = true;
        if (property === "startingNote") {
            component.startingNote = value;
        } else if (property === "rows") {
            component.rows = value;
        } else if (property === "columns") {
            component.columns = value;
        } else {
            changed = false;
        }
        if (changed) {
            populateGridTimer.restart()
        }
    }

    Timer {
        id: populateGridTimer
        interval: 1
        repeat: false
        onTriggered: {
            component.populateGrid();
        }
    }

    onOctaveChanged: {
        component.setProperty("startingNote", component.octave * 12);
    }

    Component {
        id: amazeGrid
        ColumnLayout {
            Repeater {
                id: amazeMainGridRepeater
                model: _private.model
                delegate: RowLayout {
                    id: amazeMainGridRow
                    property var row: index
                    Repeater {
                        model: amazeMainGridRepeater.model.columnCount(amazeMainGridRepeater.model.index(index, 0))
                        delegate: QQC2.Button {
                            id: playDelegate
                            property var column: index
                            property var note: amazeMainGridRepeater.model.data(amazeMainGridRepeater.model.index(row, column), amazeMainGridRepeater.model.roles['note'])
                            MultiPointTouchArea {
                                anchors.fill: parent
                                touchPoints: [
                                    TouchPoint {
                                        property var playingNote;
                                        onPressedChanged: {
                                            if (pressed) {
                                                playDelegate.down = true;
                                                playDelegate.focus = true;
                                                playingNote = note;
                                                component.setNoteOn(playingNote, 64);
                                            } else {
                                                playDelegate.down = false;
                                                playDelegate.focus = false;
                                                component.setNoteOff(playingNote);
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: amazeSettings
        Kirigami.FormLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            QQC2.ComboBox {
                id: customRows
                Layout.fillWidth: true
                visible: optionGrid.currentIndex === 0
                Kirigami.FormData.label: "Grid Rows"
                model: [3,4,5,6,7,8,9]
                displayText: currentText
                currentIndex: 0
                onActivated: {
                    component.setProperty("rows", currentText);
                }
            }
            QQC2.ComboBox {
                id: customColumns
                Layout.fillWidth: true
                visible: optionGrid.currentIndex === 0
                Kirigami.FormData.label: "Grid Columns"
                model: [3,4,5,6,7,8,9]
                displayText: currentText
                currentIndex: 0
                onActivated: {
                    component.setProperty("columns", currentText);
                }
            }
        }
    }
}
