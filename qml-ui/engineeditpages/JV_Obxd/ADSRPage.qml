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

import "../../components" as ZComponents


GridLayout {
    rows: 2
    columns: 4
    ZComponents.Card {
        Layout.columnSpan: 4
        implicitWidth: 1
        implicitHeight: 1
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentItem: Canvas {
            id: canvas
            onPaint: {
                var ctx = getContext("2d");
                ctx.lineWidth = 3;
                ctx.strokeStyle = Kirigami.Theme.highlightColor
                let piece = width / 4;
                let top = Kirigami.Units.gridUnit
                let bottom = height - Kirigami.Units.gridUnit * 2

                ctx.clearRect(0, 0, width, height);
                ctx.beginPath();
                ctx.moveTo(piece * (1 - attackController.slider.value/attackController.slider.to), top + bottom);
                ctx.lineTo(piece, top);

                ctx.lineTo(piece + piece * (decayController.slider.value/decayController.slider.to),
                           top + bottom * (1 - sustainController.slider.value/sustainController.slider.to));
                ctx.lineTo(piece * 3,
                           top + bottom * (1 - sustainController.slider.value/sustainController.slider.to));
                ctx.lineTo(piece * 3 + piece * (releaseController.slider.value/releaseController.slider.to),
                           top + bottom);
                ctx.stroke();
            }
        }
    }

    ZComponents.SliderController {
        id: attackController
        implicitHeight: 1
        controller {
            category: "Obxd#14"
            index: 0
        }
        onValueChanged: canvas.requestPaint()
    }
    ZComponents.SliderController {
        id: decayController
        implicitHeight: 1
        controller {
            category: "Obxd#14"
            index: 1
        }
        onValueChanged: canvas.requestPaint()
    }
    ZComponents.SliderController {
        id: sustainController
        implicitHeight: 1
        controller {
            category: "Obxd#14"
            index: 2
        }
        onValueChanged: canvas.requestPaint()
    }
    ZComponents.SliderController {
        id: releaseController
        implicitHeight: 1
        controller {
            category: "Obxd#14"
            index: 3
        }
        onValueChanged: canvas.requestPaint()
    }
}

