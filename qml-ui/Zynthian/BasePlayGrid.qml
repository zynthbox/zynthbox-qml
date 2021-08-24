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

import Zynthian 1.0 as Zynthian

Item {
    id: root
    property QtObject notesGrid: baseNotesGrid.notesGrid
    property QtObject notesGridSettings: baseNotesGrid.notesGridSettings
    property QtObject chordsGrid: baseChordsGrid.chordsGrid
    property QtObject chordsGridSettings: baseChordsGridSettings.chordsGridSettings

    Zynthian.BaseNotesGrid {
        id:baseNotesGrid
    }

    Zynthian.BaseNotesGrid {
        id:baseNotesGridSettings
    }

    Zynthian.BaseChordsGrid {
        id:baseChordsGrid
    }

    Zynthian.BaseChordsGrid {
        id:baseChordsGridSettings
    }

}
