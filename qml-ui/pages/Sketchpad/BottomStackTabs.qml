/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

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

import QtQuick 2.10
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Layouts 1.4
import io.zynthbox.ui 1.0 as ZUI
import org.kde.kirigami 2.6 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

QQC2.Control {
    id: root

    property bool displaySceneButtons: zynqtgui.sketchpad.displaySceneButtons
    property alias tracksButton : _tracksButton
    property alias clipsButton : _clipsButton
    property alias synthsButton : _synthsButton
    property alias samplesButton : _samplesButton
    property alias fxButton : _fxButton

    component TabButton :  ZUI.SectionButton {
        Layout.fillWidth: true
        Layout.fillHeight: true
        property int viewValue : -1
        checked: highlighted
        checkable: false
        highlighted: bottomStack.currentBarView === viewValue
        enabled: !root.displaySceneButtons
        onClicked: bottomStack.setView(viewValue)
    }

    QQC2.ButtonGroup {
        buttons: [_tracksButton, _clipsButton,_synthsButton, _samplesButton, _fxButton ]
    }

    contentItem: ColumnLayout {
        spacing: ZUI.Theme.sectionSpacing
    
        ZUI.SectionGroup {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.fill: parent
                spacing: ZUI.Theme.spacing

                TabButton {
                    id: _tracksButton
                    viewValue: Main.BarView.TracksBar
                    text: qsTr("Track")
                }

                TabButton {
                    id: _clipsButton
                    viewValue: Main.BarView.ClipsBar
                    text: qsTr("Clips")
                }
            }
        }

        ZUI.SectionGroup {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.fill: parent
                spacing: ZUI.Theme.spacing

                TabButton {
                    id: _synthsButton
                    viewValue: Main.BarView.SynthsBar
                    text: qsTr("Synths")
                }

                TabButton {
                    id: _samplesButton
                    viewValue: Main.BarView.SamplesBar
                    text: qsTr("Samples")
                }

                TabButton {
                    id: _fxButton
                    viewValue: Main.BarView.FXBar
                    text: qsTr("FX")
                }

            }
        }
    }
}
