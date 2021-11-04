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

ColumnLayout {
    id: component
    anchors {
        fill: parent
    }
    Kirigami.Heading {
        Layout.fillWidth: true
        text: qsTr("Save Recordings To A File");
    }
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        QQC2.Label {
            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing
            }
            wrap: Text.Wrap
            text: qsTr("Recordings from this module will be stored in the sounds/capture section of your data store. They will be given the name of the module, with a timestamp so you can tell your recordings apart by when you made them.")
        }
    }
}
