/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Entry point for QML UI

Copyright (C) 2021 Marco Martin <mart@kde.org>
Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>

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

import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1

Window {
    id: splashWindow
    visible: true
    color: "#000000"
    flags: Qt.SplashScreen
    x: 0
    y: 0
    width: Screen.width
    height: Screen.height

    Timer {
        id: startupTimer
        interval: 1
        repeat: false
        onTriggered: {
            var mainPageComponent = Qt.createComponent("MainPage.qml");

            if (mainPageComponent.status === Component.Ready) {
                var obj = mainPageComponent.createObject(splashWindow, {visible: true});
                if (obj == null) {
                    // Error Handling
                    console.log("Error creating object");
                } else {
                    splashWindow.visible = false;
                }
            } else if (mainPageComponent.status === Component.Error) {
                // Error Handling
                console.log("Error loading component:", mainPageComponent.errorString());
            }
        }
    }

    Image {
        anchors.centerIn: parent
        source: Qt.resolvedUrl("../img/zynthian_gui_loading.gif")
        Component.onCompleted: {
            startupTimer.start();
        }
    }
}
