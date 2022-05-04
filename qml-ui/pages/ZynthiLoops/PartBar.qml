/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Marco MArtin <mart@kde.org>

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

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian

// GridLayout so TabbedControlView knows how to navigate it
GridLayout {
    id: root
    rows: 1
    Layout.fillWidth: true

    property QtObject bottomBar: null

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.trackButton.checked = true
                return true;
        }
        
        return false;
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        spacing: 1

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 1

            QQC2.ButtonGroup {
                buttons: buttonsColumn.children
            }

            BottomStackTabs {
                id: buttonsColumn
                Layout.preferredWidth: privateProps.cellWidth + 6
                Layout.maximumWidth: privateProps.cellWidth + 6
                Layout.bottomMargin: 5
                Layout.fillHeight: true
            }

            RowLayout {
                id: contentColumn
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.bottomMargin: 5

                spacing: 1

                // Spacer
                Item {
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                }

                Repeater {
                    model: 10
                    delegate: ColumnLayout {
                        id: gridColumns
                        property int colIndex: index

                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        Layout.preferredWidth: privateProps.cellWidth

                        spacing: 1

                        Repeater {
                            model: 5
                            delegate: Rectangle {
                                id: gridRows
                                property int rowIndex: index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#000000"
                                border.color: Kirigami.Theme.highlightColor
                                border.width: gridColumns.colIndex === 2 &&
                                              gridRows.rowIndex === 3
                                                ? 1
                                                : 0
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.preferredWidth: privateProps.cellWidth*2
                }
            }
        }
    }
}

