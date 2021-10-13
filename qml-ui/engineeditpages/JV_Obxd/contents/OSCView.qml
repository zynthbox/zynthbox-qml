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

    /* Row 1 */

    // Osc1Pitch
    Zynthian.DialController {
        title: qsTr("OSC1 Tuning")
        controller {
            category: "Ctrls#8"
            index: 3
        }
    }


    // PitchQuant
    Zynthian.SwitchController {
        title: qsTr("Step Quantize")
        controller {
            category: "Ctrls#9"
            index: 1
        }
    }

    // Osc2HardSync
    Zynthian.SwitchController {
        title: qsTr("SYNC")
        controller {
            category: "Ctrls#8"
            index: 1
        }
    }

    // Osc2Pitch
    Zynthian.DialController {
        title: qsTr("OSC2 Tuning")
        controller {
            category: "Ctrls#9"
            index: 0
        }
    }


    /* Row 2 */

    // Osc1Saw
    Zynthian.SwitchController {
        title: qsTr("OSC1 Saw")
        controller {
            category: "Ctrls#9"
            index: 2
        }
    }

    // XMod
    Zynthian.DialController {
        title: qsTr("Cross Modulation")
        controller {
            category: "Ctrls#8"
            index: 2
        }
    }

    // Oscillator2detune
    Zynthian.DialController {
        title: qsTr("OSC 2 Detune")
        controller {
            category: "Ctrls#5"
            index: 1
        }
    }

    // Osc2Saw
    Zynthian.SwitchController {
        title: qsTr("OSC2 Saw")
        controller {
            category: "Ctrls#10"
            index: 0
        }
    }


    /* Row 3 */

    // Osc1Pulse
    Zynthian.SwitchController {
        title: qsTr("OSC1 Pulse")
        controller {
            category: "Ctrls#9"
            index: 3
        }
    }

    // PulseWidth
    Zynthian.DialController {
        title: qsTr("Pulse Width")
        controller {
            category: "Ctrls#10"
            index: 2
        }
    }

    // EnvelopeToPitch
    Zynthian.DialController {
        title: qsTr("Pitch Envelope")
        controller {
            category: "Ctrls#11"
            index: 0
        }
    }

    // Osc2Pulse
    Zynthian.SwitchController {
        title: qsTr("OSC2 Pulse")
        controller {
            category: "Ctrls#10"
            index: 1
        }
    }
}

