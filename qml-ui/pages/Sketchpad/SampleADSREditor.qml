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

import io.zynthbox.components 1.0 as Zynthbox
import Zynthian 1.0 as Zynthian

// GridLayout so TabbedControlView knows how to navigate it
GridLayout {
    id: component
    rows: 1
    Layout.fillWidth: true
    Layout.maximumWidth: parent.width

    property QtObject bottomBar: null
    property string controlType: zynqtgui.bottomBarControlType
    property QtObject controlObj: (component.controlType === "bottombar-controltype-clip" || component.controlType === "bottombar-controltype-pattern")
                                    ? zynqtgui.bottomBarControlObj // selected bottomBar object is clip/pattern
                                    : zynqtgui.bottomBarControlObj != null && zynqtgui.bottomBarControlObj.samples != null
                                        ? zynqtgui.bottomBarControlObj.samples[zynqtgui.bottomBarControlObj.selectedSlotRow] // selected bottomBar object is not clip/pattern and hence it is a channel
                                        : null
    property bool showCopyPasteButtons: true

    function cuiaCallback(cuia) {
        var returnValue = false;
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.channelButton.checked = true
                returnValue = true;
                break;
            case "SELECT_UP":
                _private.goUp();
                returnValue = true;
                break;
            case "SELECT_DOWN":
                _private.goDown();
                returnValue = true;
                break;
            case "NAVIGATE_LEFT":
                _private.goLeft();
                returnValue = true;
                break;
            case "NAVIGATE_RIGHT":
                _private.goRight();
                returnValue = true;
                break;
        }
        return returnValue;
    }
    QtObject {
        id: _private
        function goLeft() {
            clipSettingsADSR.previousADSRElement();
        }
        function goRight() {
            clipSettingsADSR.nextADSRElement();
        }
        function goUp() {
            if (zynqtgui.altButtonPressed) {
                for (var i = 0; i < 10; ++i) {
                    clipSettingsADSR.increaseCurrentValue();
                }
            } else {
                clipSettingsADSR.increaseCurrentValue();
            }
        }
        function goDown() {
            if (zynqtgui.altButtonPressed) {
                for (var i = 0; i < 10; ++i) {
                    clipSettingsADSR.decreaseCurrentValue();
                }
            } else {
                clipSettingsADSR.decreaseCurrentValue();
            }
        }
        function knob1Up() {
            clipSettingsADSR.nextADSRElement();
        }
        function knob1Down() {
            clipSettingsADSR.previousADSRElement();
        }
        function knob2Up() {
            clipSettingsADSR.increaseCurrentValue();
        }
        function knob2Down() {
        }
        function knob3Up() {
        }
        function knob3Down() {
        }
    }

    Zynthian.ADSRClipView {
        id: clipSettingsADSR
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: Kirigami.Units.largeSpacing
        clip: component.controlObj
            ? Zynthbox.PlayGridManager.getClipById(component.controlObj.cppObjId)
            : null
        onSaveMetadata: component.controlObj.saveMetadata();
    }
}
