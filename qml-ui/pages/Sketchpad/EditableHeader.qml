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

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian

Item {
    id: titleStack

    property alias text: heading.text
    property QtObject controlObj
    property var controlType

    RowLayout {
        anchors.fill: parent

        Kirigami.Heading {
            id: heading
            Layout.fillWidth: true
            Layout.fillHeight: false
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            level: 3
        }
        QQC2.Button {
            Layout.fillWidth: false
            Layout.fillHeight: true
            icon.name: "document-edit"
            visible: controlObj &&
                        controlType !== "bottombar-controltype-song" &&
                        controlObj.nameEditable
            onClicked: {
                editDialog.open()
                objNameEdit.text = root.controlObj ? root.controlObj.name : "";
                // objNameEdit.forceActiveFocus();
            }
            Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.medium*1.3)
            Layout.preferredHeight: Layout.preferredWidth
        }
    }

    Zynthian.Dialog {
        id: editDialog
        parent: QQC2.Overlay.overlay
        x: parent.width/2 - width/2
        y: parent.height/2 - height/2
        width: Kirigami.Units.gridUnit * 15
        height: Kirigami.Units.gridUnit * 8
        header: Kirigami.Heading {
            padding: 4
            font.pointSize: 16
            text: qsTr("Set channel name")
        }
        contentItem: ColumnLayout {
            QQC2.TextField {
                id: objNameEdit
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.6)
            }
        }
        footer: QQC2.Control {
            leftPadding: editDialog.leftPadding
            topPadding: Kirigami.Units.smallSpacing
            rightPadding: editDialog.rightPadding
            bottomPadding: editDialog.bottomPadding
            contentItem: RowLayout {
                Layout.fillWidth: true
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    text: qsTr("Cancel")
                    onClicked: {
                        editDialog.reject();
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    text: qsTr("Ok")
                    onClicked: {
                        editDialog.accept();
                    }
                }
            }
        }
        onAccepted: {
            controlObj.name = text
            editDialog.close()
        }
    }
}
