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
import io.zynthbox.components 1.0 as Zynthbox

MouseArea {
    id: root
    property Item patternConnections
    property Item secondColumn
    property int targetMinY: 0
    property int targetMaxY: patternConnections.height
    property Item temporarySecondColumnChild
    signal requestConnect(Item child)

    Rectangle {
        anchors {
            horizontalCenter: parent.right
            verticalCenter: parent.verticalCenter
        }
        visible: root.pressed
        width: Kirigami.Units.gridUnit
        height: width
        radius: width
        color: Kirigami.Theme.highlightColor
    }
    onPressed: {
        root.temporarySecondColumnChild = null;
        print(mouse.y)
    }
    onPositionChanged: {
        let column2Pos = secondColumn.mapFromItem(this, mouse.x, mouse.y);
        let minYSecondColumn = secondColumn.mapFromItem(patternConnections, 0, root.targetMinY).y;
        let maxYSecondColumn = secondColumn.mapFromItem(patternConnections, 0, root.targetMaxY).y;
        column2Pos.y = Math.max(minYSecondColumn, Math.min(maxYSecondColumn, column2Pos.y));

        patternConnections.temporaryEndPos = patternConnections.mapFromItem(this, mouse.x, mouse.y);
        patternConnections.temporaryEndPos.x = Math.min(patternConnections.width, patternConnections.temporaryEndPos.x);
        patternConnections.temporaryEndPos.y = Math.max(root.targetMinY, Math.min(root.targetMaxY, patternConnections.temporaryEndPos.y));
        let child = secondColumn.childAt(10, column2Pos.y);

        if (!child || !child.visible || child.height === 0 || !child.hasOwnProperty("row")) {
            return;
        }

        patternConnections.temporaryStartPos = patternConnections.mapFromItem(this, 0, height / 2);

        if (patternConnections.temporaryEndPos.x > patternConnections.width / 2) {
            patternConnections.temporaryEndPos2 = patternConnections.mapFromItem(child, 0, child.height / 2);
            patternConnections.temporaryEndPos2.y = Math.max(root.targetMinY, Math.min(root.targetMaxY, patternConnections.temporaryEndPos2.y));
            root.temporarySecondColumnChild = child;
        } else {
            patternConnections.temporaryEndPos2 = null;
            root.temporarySecondColumnChild = null;
        }
        for (var i in patternConnections.connections) {
            if (patternConnections.connections[i][0] == index) {
                patternConnections.connections.splice(i, 1);
                break;
            }
        }
        patternConnections.requestPaint();
    }
    onCanceled: {
        patternConnections.temporaryStartPos = null;
        patternConnections.temporaryEndPos = null;
        patternConnections.temporaryEndPos2 = null;
            patternConnections.requestPaint();
    }
    onReleased: {
        patternConnections.temporaryStartPos = null;
        patternConnections.temporaryEndPos = null;

        let column2Pos = secondColumn.mapFromItem(this, mouse.x, mouse.y);

        let minYSecondColumn = secondColumn.mapFromItem(patternConnections, 0, root.targetMinY).y;
        let maxYSecondColumn = secondColumn.mapFromItem(patternConnections, 0, root.targetMaxY).y;
        column2Pos.y = Math.max(minYSecondColumn, Math.min(maxYSecondColumn, column2Pos.y));

        let child = root.temporarySecondColumnChild;

        if (!child) {
            patternConnections.temporaryEndPos2 = null;
            patternConnections.requestPaint();
            root.requestConnect(null);
            return;
        }
        print(patternConnections.connections.indexOf([index, child.row]))
        if (patternConnections.temporaryEndPos2 && patternConnections.connections.indexOf([index, child.row]) === -1) {
            patternConnections.connections.push([index, child.row]);
        }
        patternConnections.temporaryEndPos2 = null;
        patternConnections.requestPaint();
        root.requestConnect(child)
    }
}

