/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
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

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian

StackLayout {
    id: titleStack
    property alias text: heading.text
    property QtObject controlObj
    property var controlType

    RowLayout {
        Kirigami.Heading {
            id: heading
            //Layout.fillWidth: true
            wrapMode: Text.NoWrap
        }
        QQC2.Button {
            icon.name: "document-edit"
            visible: controlObj &&
                        controlType !== "bottombar-controltype-song" &&
                        controlObj.nameEditable
            onClicked: {
                titleStack.currentIndex = 1;
                objNameEdit.text = root.controlObj ? root.controlObj.name : "";
                objNameEdit.forceActiveFocus();
            }
            Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.medium*1.3)
            Layout.preferredHeight: Layout.preferredWidth
        }
        Connections {
            target: Qt.inputMethod
            onVisibleChanged: {
                if (!Qt.inputMethod.visible) {
                    titleStack.currentIndex = 0;
                }
            }
        }
    }
    QQC2.TextField {
        id: objNameEdit
        onAccepted: {
            controlObj.name = text
            titleStack.currentIndex = 0;
        }
    }
}

