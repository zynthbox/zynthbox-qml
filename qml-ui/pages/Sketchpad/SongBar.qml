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
    columnSpacing: Kirigami.Units.gridUnit*3

    property QtObject bottomBar: null

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.channelButton.checked = true
                return true;
        }
        
        return false;
    }

    Zynthian.SketchpadDial {
        id: bpmDial
        text: qsTr("BPM")
        controlObj: zynqtgui.bottomBarControlObj
        controlProperty: "bpm"

        dial {
            stepSize: 1
            from: 50
            to: 200
        }
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8

        QQC2.Label {
            Layout.alignment: Qt.AlignCenter
            text: qsTr("Scale")
        }

        QQC2.ComboBox {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            model: zynqtgui.bottomBarControlObj.scaleModel
            currentIndex: root.bottomBar &&
                          zynqtgui.bottomBarControlObj &&
                          zynqtgui.bottomBarControlObj.selectedScaleIndex
                            ? zynqtgui.bottomBarControlObj.selectedScaleIndex
                            : 0
            onActivated: {
                zynqtgui.bottomBarControlObj.selectedScaleIndex = index;
            }
        }
    }

    Item {
        Layout.fillWidth: true
    }
}

