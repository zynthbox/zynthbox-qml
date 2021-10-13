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
    columns: 2

    // VoiceCount
    Zynthian.MultiSwitchController {
        title: qsTr("Voices")
        controller.category: "Ctrls#2"
        controller.index: 0
        stepSize: Math.round(multiSwitch.to / 7)
        valueLabel: Math.round(multiSwitch.value / (200 / 7)) + 1
    }
    // Octave
    Zynthian.MultiSwitchController {
        title: qsTr("Transpose")
        controller.category: "Ctrls#2"
        controller.index: 2
        stepSize: 50
        valueLabel: {
            let val = Math.round((multiSwitch.value - 100) / 50)
            return (val > 0 ? "+" : "") + val
        }
    }
    // Tune
    Zynthian.DialController {
        title: qsTr("Tune")
        controller.category: "Ctrls#2"
        controller.index: 1
        valueLabel: (value > 100 ? "+" : "") + Math.round(value - 100) + "%"
    }
    // VOLUME
    Zynthian.SliderController {
        title: qsTr("Volume")
        controller.category: "Ctrls#1"
        controller.index: 3
        valueLabel: Math.round(value / 2)
    }
}

