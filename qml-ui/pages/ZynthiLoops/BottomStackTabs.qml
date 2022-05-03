/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

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
import org.kde.kirigami 2.6 as Kirigami

ColumnLayout {
    QQC2.Button {
        Layout.fillWidth: true
        Layout.fillHeight: true
        checkable: true
        checked: bottomStack.slotsBar ? bottomStack.slotsBar.trackButton.checked : false
        text: qsTr("Track")
        onClicked: {
            bottomStack.slotsBar.trackButton.checked = true
        }
    }

    QQC2.Button {
        Layout.fillWidth: true
        Layout.fillHeight: true
        checkable: true
        checked: bottomStack.slotsBar ? bottomStack.slotsBar.partButton.checked : false
        text: qsTr("Part")
        onClicked: {
            bottomStack.slotsBar.partButton.checked = true
        }
    }

    QQC2.Button {
        Layout.fillWidth: true
        Layout.fillHeight: true
        checkable: true
        checked: bottomStack.slotsBar ? bottomStack.slotsBar.synthsButton.checked : false
        text: qsTr("Synths")
        onClicked: {
            bottomStack.slotsBar.synthsButton.checked = true
        }
    }

    QQC2.Button {
        Layout.fillWidth: true
        Layout.fillHeight: true
        checkable: true
        checked: bottomStack.slotsBar ? bottomStack.slotsBar.samplesButton.checked : false
        text: qsTr("Samples")
        onClicked: {
            bottomStack.slotsBar.samplesButton.checked = true
        }
    }

    QQC2.Button {
        Layout.fillWidth: true
        Layout.fillHeight: true
        checkable: true
        checked: bottomStack.slotsBar ? bottomStack.slotsBar.fxButton.checked : false
        text: qsTr("FX")
        onClicked: {
            bottomStack.slotsBar.fxButton.checked = true
        }
    }
}
