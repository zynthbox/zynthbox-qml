/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>

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
import QtQuick.Controls 2.2 as QQC2
import org.zynthbox.norns.qmlshield 1.0 as Norns

QQC2.Control {
    id: component
    palette {
        alternateBase: "#091010"
        base: "silver"
        brightText: "white"
        button: "#091010"
        buttonText: "white"
        dark: "#091010"
        highlight: "#091010"
        highlightedText: "silver"
        light: "silver"
        link: "darkblue"
        linkVisited: "blue"
        mid: "gray"
        midlight: "silver"
        shadow: "#091010"
        text: "#091010"
        toolTipBase: "#091010"
        toolTipText: "white"
        window: "silver"
        windowText: "#091010"
    }
    background: Rectangle {
        width: component.width
        height: component.height
        color: component.palette.base
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            clip: true
            source: Qt.resolvedUrl("../../img/brushed-steel.png")
            asynchronous: true
        }
    }
    contentItem: Norns.Shield {
        anchors.fill: parent
        palette: component.palette
    }
}
