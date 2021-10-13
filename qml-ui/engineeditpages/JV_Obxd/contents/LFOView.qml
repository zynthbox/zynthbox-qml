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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

GridLayout {
    columns: 4

    // LFO Frequency
    Zynthian.DialController {
        title: qsTr("LFO Speed")
        controller {
            category: "Ctrls#5"
            index: 2
        }
    }
    // LFOSineWave
    Zynthian.SwitchController {
        title: qsTr("Sine")
        controller {
            category: "Ctrls#5"
            index: 3
        }
        valueLabel: controller.ctrl.value > 100 ? qsTr("on") : qsTr("off")
    }
    // LFOSquareWave
    Zynthian.SwitchController {
        title: qsTr("Square")
        controller {
            category: "Ctrls#6"
            index: 0
        }
        valueLabel: controller.ctrl.value > 100 ? qsTr("on") : qsTr("off")
    }
    // LFOSampleHoldWave
    Zynthian.SwitchController {
        title: qsTr("Sample & Hold")
        controller {
            category: "Ctrls#6"
            index: 1
        }
        valueLabel: controller.ctrl.value > 100 ? qsTr("on") : qsTr("off")
    }


    // LFOAmount1
    Zynthian.DialController {
        title: qsTr("Pitch")
        controller {
            category: "Ctrls#6"
            index: 2
        }
    }
    // LFOOsc1
    Zynthian.SwitchController {
        title: qsTr("OSC1 Pitch")
        controller {
            category: "Ctrls#7"
            index: 0
        }
        valueLabel: controller.ctrl.value > 100 ? qsTr("on") : qsTr("off")
    }
    // LFOOsc2
    Zynthian.SwitchController {
        title: qsTr("OSC2 Pitch")
        controller {
            category: "Ctrls#7"
            index: 1
        }
        valueLabel: controller.ctrl.value > 100 ? qsTr("on") : qsTr("off")
    }
    // LFOFilter
    Zynthian.SwitchController {
        title: qsTr("Filter")
        controller {
            category: "Ctrls#7"
            index: 2
        }
        valueLabel: controller.ctrl.value > 100 ? qsTr("on") : qsTr("off")
    }


    // LFOAmount2
    Zynthian.DialController {
        title: qsTr("Pulse Width")
        controller {
            category: "Ctrls#6"
            index: 3
        }
    }
    // LFOPw1
    Zynthian.SwitchController {
        title: qsTr("OSC1 PWM")
        controller {
            category: "Ctrls#7"
            index: 3
        }
        valueLabel: controller.ctrl.value > 100 ? qsTr("on") : qsTr("off")
    }
    // LFOPw2
    Zynthian.SwitchController {
        title: qsTr("OSC2 PWM")
        controller {
            category: "Ctrls#8"
            index: 0
        }
        valueLabel: controller.ctrl.value > 100 ? qsTr("on") : qsTr("off")
    }

    Zynthian.AbstractController { // Filler
        visible: true
    }
}

