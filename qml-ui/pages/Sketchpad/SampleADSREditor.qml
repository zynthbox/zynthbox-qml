/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthbox Sketchpad Sample ADSR editor component

Copyright (C) 2023 Dan Leinir Turthra Jensen

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

// GridLayout so TabbedControlView knows how to navigate it
GridLayout {
    id: root
    rows: 1
    Layout.fillWidth: true
    Layout.maximumWidth: parent.width

    property QtObject bottomBar: null
    property string controlType: zynqtgui.bottomBarControlType
    property QtObject controlObj: (root.controlType === "bottombar-controltype-clip" || root.controlType === "bottombar-controltype-pattern")
                                    ? zynqtgui.bottomBarControlObj // selected bottomBar object is clip/pattern
                                    : zynqtgui.bottomBarControlObj && zynqtgui.bottomBarControlObj.hasOwnProperty("samples") && zynqtgui.bottomBarControlObj.hasOwnProperty("selectedSlotRow") // selected bottomBar object is not clip/pattern and hence it is a channel
                                        ? zynqtgui.bottomBarControlObj.samples[zynqtgui.bottomBarControlObj.selectedSlotRow]
                                        : null
    property bool showCopyPasteButtons: true

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.channelButton.checked = true
                return true;
        }
        return false;
    }

    Zynthian.ADSRClipView {
        anchors.fill: parent
        clip: root.controlObj
    }
}
