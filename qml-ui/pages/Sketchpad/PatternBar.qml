/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Zynthian Loopgrid Page

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Marco MArtin <mart@kde.org>

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
import io.zynthbox.components 1.0 as Zynthbox

import Zynthian 1.0 as Zynthian

// GridLayout so TabbedControlView knows how to navigate it
GridLayout {
    id: root
    rows: 1
    Layout.fillWidth: true

    property QtObject controlObj: zynqtgui.bottomBarControlObj
    property QtObject sequence: controlObj.clipChannel ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName) : null
    property QtObject pattern: root.sequence && controlObj.clipChannel ? root.sequence.getByClipId(controlObj.clipChannel.id, controlObj.clipChannel.selectedClip) : null

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.channelButton.checked = true
                return true;
        }
        
        return false;
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: Kirigami.Units.gridUnit * 0.5
        spacing: Kirigami.Units.gridUnit * 0.5

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false

            Kirigami.Heading {
                Layout.fillWidth: false
                Layout.fillHeight: false
                text: qsTr("PATTERN: %1").arg(root.pattern ? root.pattern.objectName : "")
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            SidebarButton {
                icon.name: "edit-clear-all"
                active: true

                onClicked: {
                    if (root.pattern) {
                        root.pattern.clear();
                    }
                }
            }
        }

        Image {
            id: patternVisualiser
            Layout.fillWidth: true
            Layout.fillHeight: true
            smooth: false

            visible: controlObj != null && controlObj.clipChannel != null && root.pattern != null
            source: root.pattern && controlObj.clipChannel ? root.pattern.thumbnailUrl : ""
            Rectangle { // Progress
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                visible: root.sequence &&
                         root.sequence.isPlaying &&
                         root.pattern &&
                         root.pattern.enabled &&
                         ((controlObj.col === 0 && root.pattern.bank === "I") || (controlObj.col === 1 && root.pattern.bank === "II"))
                color: Kirigami.Theme.highlightColor
                width: widthFactor // this way the progress rect is the same width as a step
                property double widthFactor: root.pattern ? parent.width / (root.pattern.width * root.pattern.bankLength) : 1
                x: root.pattern ? root.pattern.bankPlaybackPosition * widthFactor : 0
            }
            MouseArea {
                anchors.fill:parent
                onClicked: {
                    var screenBack = zynqtgui.current_screen_id;
                    zynqtgui.current_modal_screen_id = "playgrid";
                    zynqtgui.forced_screen_back = "sketchpad";
                    Zynthbox.PlayGridManager.setCurrentPlaygrid("playgrid", Zynthbox.PlayGridManager.sequenceEditorIndex);
                    var sequence = Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName);
                    sequence.setActiveChannel(controlObj.clipChannel.id, controlObj.clipChannel.selectedClip);
                }
            }
        }
    }
}

