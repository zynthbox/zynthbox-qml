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

    // KeyFollow
    Zynthian.DialController {
        controller {
            category: "Obxd#12"
            index: 0
        }
    }
    // Resonance
    Zynthian.DialController {
        controller {
            category: "Obxd#12"
            index: 1
        }
    }
    // Cutoff
    Zynthian.DialController {
        controller {
            category: "Obxd#12"
            index: 2
        }
    }
    // MultiMode
    Zynthian.DialController {
        controller {
            category: "Obxd#12"
            index: 3
        }
    }

    // Warm
    Zynthian.DialController {
        controller {
            category: "Obxd#13"
            index: 0
        }
    }

    // Bandpassblend
    Zynthian.SwitchController {
        title: qsTr("Filtertype")
        controller {
            category: "Obxd#13"
            index: 1
        }
        valueLabel: controller.ctrl.value > 100 ? qsTr("Notch") : qsTr("Bandpass")
    }

    // FourPole
    Zynthian.SwitchController {
        title: qsTr("Lowpass")
        controller {
            category: "Obxd#13"
            index: 2
        }
        valueLabel: controller.ctrl.value > 100 ? qsTr("24db") : qsTr("12db")
    }
    
    // Filter env amount
    Zynthian.DialController {
        controller {
            category: "Obxd#13"
            index: 3
        }
    }
}

