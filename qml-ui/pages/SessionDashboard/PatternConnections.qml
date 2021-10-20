/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Session Dashboard page for Zynthian GUI

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
import org.zynthian.quick 1.0 as ZynQuick

Canvas {
    id: canvas
    Layout.fillWidth: true
    Layout.fillHeight: true
    property var temporaryStartPos
    property var temporaryEndPos
    property var temporaryEndPos2
    property var connections: []

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Timer {
        running: true
        interval: 500
        onTriggered: canvas.requestPaint();
    }
    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.beginPath();
        ctx.lineWidth = 2;
        ctx.strokeStyle = Kirigami.Theme.highlightColor;
        for (var i in connections) {
            var conn = connections [i];
            var x1 = 0;
            var y1 = conn[0].mapToItem(this, 0, conn[0].height/2).y;
            var x2 = width;
            var y2 = conn[1].mapToItem(this, 0, conn[1].height/2).y;
            var cp1x = width / 2;
            var cp1y = y1;
            var cp2x = width / 2
            var cp2y = y2

            ctx.moveTo(x1, y1);
            ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x2, y2);
        }
        print(temporaryStartPos, temporaryEndPos)
        if (temporaryStartPos && temporaryEndPos) {
            var x1 = 0;
            var y1 = temporaryStartPos.y;
            var x2 = temporaryEndPos.x;
            var y2 = temporaryEndPos.y;
            var cp1x = temporaryEndPos.x / 2;
            var cp1y = y1;
            var cp2x = temporaryEndPos.x / 2
            var cp2y = y2

            ctx.moveTo(x1, y1);
            ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x2, y2);
        }
        ctx.stroke();
        ctx.strokeStyle = Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2);
        if (temporaryStartPos && temporaryEndPos) {
            var x1 = 0;
            var y1 = temporaryStartPos.y;
            var x2 = temporaryEndPos2.x;
            var y2 = temporaryEndPos2.y;
            var cp1x = temporaryEndPos2.x / 2;
            var cp1y = y1;
            var cp2x = temporaryEndPos2.x / 2
            var cp2y = y2

            ctx.moveTo(x1, y1);
            ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x2, y2);
        }
        ctx.stroke();
    }
}
