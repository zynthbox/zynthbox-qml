/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Dialog Component

Copyright (C) 2023 Anupam Basak <anupam.basak27@gmail.com>

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
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

QQC2.Dialog {
    id: root
    exit: null; enter: null;
    modal: true
    focus: true

    property var cuiaCallback: function(cuia) {
        var result = component.opened;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                root.close()
                result = true;
                break;
            case "KNOB0_UP":
            case "KNOB0_DOWN":
            case "KNOB1_UP":
            case "KNOB1_DOWN":
            case "KNOB2_UP":
            case "KNOB2_DOWN":
            case "KNOB3_UP":
            case "KNOB3_DOWN":
            default:
                result = true;
                break;
        }
        return result;
    }

    /** Handle opened changed to push/pop dialog to zynqtgui dialog stack
      * This will allow main program to pass CUIA events to the dialog stack
      *
      * Since this is a signal handler it is okay if one of the derived components
      * overrides the same signal. In that case both the handlers will be called
      */
    onOpenedChanged: {
        if (root.opened) {
            zynqtgui.pushDialog(root)
        } else {
            zynqtgui.popDialog(root)
        }
    }
}
