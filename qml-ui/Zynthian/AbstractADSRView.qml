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
import org.kde.kirigami 2.4 as Kirigami

Card {
    id: component
    property double attackValue: 1
    property double attackMax: 1
    property double decayValue: 1
    property double decayMax: 1
    property double sustainValue: 1
    property double sustainMax: 1
    property double releaseValue: 1
    property double releaseMax: 1
    function requestPaint() {
        canvas.requestPaint();
    }

    contentItem: Canvas {
        id: canvas
        onPaint: {
            var ctx = getContext("2d");
            ctx.lineWidth = 3;
            ctx.strokeStyle = Kirigami.Theme.highlightColor
            var grd = ctx.createLinearGradient(0, 0, 0, height)
            grd.addColorStop(0, Qt.rgba(Kirigami.Theme.highlightColor.r,
                                        Kirigami.Theme.highlightColor.g,
                                        Kirigami.Theme.highlightColor.b,
                                        0.4))
            grd.addColorStop(0.8, Qt.rgba(Kirigami.Theme.highlightColor.r,
                                        Kirigami.Theme.highlightColor.g,
                                        Kirigami.Theme.highlightColor.b,
                                        0))
            ctx.fillStyle = grd;
            let piece = width / 4;
            let top = Kirigami.Units.gridUnit
            let bottom = height - Kirigami.Units.gridUnit * 2

            ctx.clearRect(0, 0, width, height);
            ctx.beginPath();
            ctx.moveTo(piece * (1 - component.attackValue/component.attackMax), top + bottom);
            ctx.lineTo(piece, top);

            ctx.lineTo(piece + piece * (component.decayValue/component.decayMax),
                        top + bottom * (1 - component.sustainValue/component.sustainMax));
            ctx.lineTo(piece * 3,
                        top + bottom * (1 - component.sustainValue/component.sustainMax));
            ctx.lineTo(piece * 3 + piece * (component.releaseValue/component.releaseMax),
                        top + bottom);
            //ctx.closePath();
            ctx.stroke();
            ctx.fill();
        }
    }
}
