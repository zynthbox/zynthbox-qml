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

    // Cutoff
    Zynthian.DialController {
        controller {
            category: "Ctrls#12"
            index: 1
        }
    }

    // Resonance
    Zynthian.DialController {
        controller {
            category: "Ctrls#12"
            index: 2
        }
    }


    // KeyFollow
    Zynthian.DialController {
        controller {
            category: "Ctrls#12"
            index: 0
        }
    }

    // Filter env amount
    Zynthian.DialController {
        controller {
            category: "Ctrls#13"
            index: 3
        }
    }

    // Warm
    Zynthian.DialController {
        controller {
            category: "Ctrls#13"
            index: 0
        }
    }

    // Bandpassblend
    Zynthian.SwitchController {
        id: filtertypeId
        
        property int ctrlval: controller.ctrl.value
        onCtrlvalChanged: {
            let newTitle;
            if (lowpassId.ctrlval > 100){
                newTitle = "24db-6db LowPass";
            } else {
                if (ctrlval < 100) newTitle = "12db Low-Notch-HiPass";
                else newTitle = "12db Low-Band-HiPass";
            }
            multimodeId.title = qsTr(newTitle)
        }

        title: qsTr("Filtertype")
        controller {
            category: "Ctrls#13"
            index: 1
        }
        valueLabel: controller.ctrl.value < 100 ? qsTr("Notch") : qsTr("Bandpass")
    }

    // FourPole
    Zynthian.SwitchController {
        id: lowpassId
        title: qsTr("Lowpass")
        property int ctrlval: controller.ctrl.value
        onCtrlvalChanged: {
            let newTitle;
            if (ctrlval > 100){
                newTitle = "24db-6db LowPass";
            } else {
                if (filtertypeId.ctrlval < 100) newTitle = "12db Low-Notch-HiPass";
                else newTitle = "12db Low-Band-HiPass";
            }
            multimodeId.title = qsTr(newTitle)
        }
        controller {
            category: "Ctrls#13"
            index: 2
        }
        valueLabel: controller.ctrl.value > 100 ? qsTr("24db") : qsTr("12db")
    }
    
    // MultiMode
    Zynthian.DialController {
        id:multimodeId
        title: qsTr("MultiMode")
        property int filtertypeVal: 0
        property int lowpassVal: 0
        controller {
            category: "Ctrls#12"
            index: 3
        }
        Component.onCompleted: {
            let newTitle;
            if (lowpassId.ctrlval > 100){
                newTitle = "24db-6db LowPass";
            } else {
                if (filtertypeId.ctrlval < 100) newTitle = "12db Low-Notch-HiPass";
                else newTitle = "12db Low-Band-HiPass";
            }
            title = qsTr(newTitle);
        }
    }
}

