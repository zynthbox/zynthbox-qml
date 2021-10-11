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
    id: root
    columns: 4

    // mod-wheel
    Zynthian.DialController {
        controller {
            category: "MIDI Controllers"
            index: 1
        }
    }
    // Glide
    Zynthian.DialController {
        controller {
            category: "Ungroup#1"
            index: 3
        }
    }
    // gld rate
    Zynthian.DialController {
        controller {
            category: "Ungroup#2"
            index: 0
        }
    }
    // gld blend
    Zynthian.DialController {
        controller {
            category: "Ungroup#2"
            index: 1
        }
    }
    // vibrato
    Zynthian.DialController {
        controller {
            category: "Ungroup#4"
            index: 0
        }
    }
    // octave
    Zynthian.MultiSwitchController {
        controller {
            category: "Ungroup#4"
            index: 2
        }
        stepSize: 50
        valueLabel: {
            let val = Math.round((multiSwitch.value - 100) / 50)
            return (val > 0 ? "+" : "") + val
        }
    }
    // tuning
    Zynthian.DialController {
        controller {
            category: "Ungroup#4"
            index: 3
        }
        valueLabel: (value > 100 ? "+" : "") + Math.round(value - 100) + "%"
    }

    // VOLUME
    Zynthian.SliderController {
        title: qsTr("Volume")
        controller {
            category: "MIDI Controllers"
            index: 0
        }
        valueLabel: Math.round((slider.value / (slider.to - slider.from)) * 100)
    }
}

