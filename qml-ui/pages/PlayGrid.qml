/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Play Grid Page 

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>

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

import "../components" as ZComponents

ZComponents.ScreenPage {
    screenId: "playgrid"
    leftPadding: 0
    rightPadding: 0
    topPadding: 5
    bottomPadding: 5
    
    ListModel {
        id: gridModel
        
        ListElement { row: 3; column: 3; text: "3x3" }
        ListElement { row: 4; column: 4; text: "4x4" }
        ListElement { row: 5; column: 8; text: "5x8" }
        ListElement { row: 0; column: 0; text: "Custom" }
    }
    
    
    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                anchors.margins: 5

                Repeater {
                    model: zynthian.playgrid.model
                    delegate: RowLayout {
                        property var row: index

                        Layout.margins: 2.5

                        Repeater {
                            model: zynthian.playgrid.model.columnCount(zynthian.playgrid.model.index(index, 0))
                            delegate: QQC2.Button {
                                property var column: index
                                property var note: zynthian.playgrid.model.data(zynthian.playgrid.model.index(row, column), zynthian.playgrid.model.roles['note'])

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                background: Rectangle {
                                    radius: 2
                                    border {
                                        width: 1
                                        color: parent.focus ? Kirigami.Theme.highlightColor : "#e5e5e5"
                                    }
                                    color: note.name === "C" ? Kirigami.Theme.focusColor : "white"

                                    Text {
                                        anchors.centerIn: parent
                                        text: note.name + note.octave
                                    }
                                }
                                
                                onPressed: {
                                    focus = true;
                                    note.on();
                                }
                                onReleased: {
                                    focus = false;
                                    note.off();
                                }
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            property var textSize: 10
            property var textElementWidth: 80
            property var cellSize: 30
            
            id: rightPanel
          
            Layout.preferredWidth: 160
            Layout.maximumWidth: Layout.preferredWidth
            Layout.fillHeight: true
            Layout.margins: 8

            RowLayout {
                QQC2.Label {
                    Layout.preferredWidth: rightPanel.textElementWidth
                    text: "Transpose"
                    font.pointSize: rightPanel.textSize
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: rightPanel.cellSize
                    
                    text: "-"
                    onClicked: {         
                        if (zynthian.playgrid.startingNote - 1 > 0) {
                            zynthian.playgrid.startingNote--;
                        } else {
                            zynthian.playgrid.startingNote = 0;
                        }
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: rightPanel.cellSize
                    text: "+"
                    onClicked: {                               
                        zynthian.playgrid.startingNote++;
                    }
                }
            }
            
            RowLayout {
                QQC2.Label {
                    Layout.preferredWidth: rightPanel.textElementWidth
                    text: "Octave"
                    font.pointSize: rightPanel.textSize
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: rightPanel.cellSize
                    text: "-"
                    onClicked: {
                        if (zynthian.playgrid.startingNote - 12 > 0) {
                            zynthian.playgrid.startingNote = zynthian.playgrid.startingNote - 12;
                        } else {
                            zynthian.playgrid.startingNote = 0;
                        }
                    }
                }
                QQC2.Button {                    
                    Layout.fillWidth: true
                    Layout.preferredHeight: rightPanel.cellSize
                    text: "+"
                    onClicked: {
                        zynthian.playgrid.startingNote = zynthian.playgrid.startingNote + 12;
                    }
                }
            }
            
            
            RowLayout {
                QQC2.Label {
                    Layout.preferredWidth: rightPanel.textElementWidth
                    text: "Grid"
                    font.pointSize: rightPanel.textSize
                }
                QQC2.ComboBox {
                    Layout.fillWidth: true
                    Layout.preferredHeight: rightPanel.cellSize
                    model: gridModel
                    textRole: "text"
                    displayText: currentText
                    currentIndex: 2

                    onActivated: {
                        var data = gridModel.get(currentIndex)

                        if (data.row === 0 && data.column === 0) {
                            customGrid.visible = true
                            zynthian.playgrid.rows = customRows.currentText;
                            zynthian.playgrid.columns = customColumns.currentText;
                        } else {
                            customGrid.visible = false;
                            zynthian.playgrid.rows = data.row;
                            zynthian.playgrid.columns = data.column;
                        }
                    }
                }
            }

            RowLayout {
                id: customGrid
                visible: false

                QQC2.Label {
                    Layout.preferredWidth: rightPanel.textElementWidth
                    text: "Custom Grid"
                    font.pointSize: rightPanel.textSize
                }
                QQC2.ComboBox {
                    id: customRows
                    Layout.fillWidth: true
                    Layout.preferredHeight: rightPanel.cellSize
                    model: [3,4,5,6,7,8,9]
                    displayText: currentText
                    currentIndex: 0
                    onActivated: {
                        zynthian.playgrid.rows = currentText;
                    }
                }
                QQC2.ComboBox {
                    id: customColumns
                    Layout.fillWidth: true
                    Layout.preferredHeight: rightPanel.cellSize
                    model: [3,4,5,6,7,8,9]
                    displayText: currentText
                    currentIndex: 0
                    onActivated: {
                        zynthian.playgrid.columns = currentText;
                    }
                }
            }
        }
    }
}
